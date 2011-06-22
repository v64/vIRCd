package vIRCd::User;
use strict; use warnings;

use vIRCd::Constant qw(%const %numeric_str %stats $RPL_WELCOME $RPL_YOURHOST $RPL_CREATED $RPL_WHOISCHANNELS);
use vIRCd::Channel;
use Socket;

my %fh_to_user;
my %nicks_in_use;

# Creates a new user, @_ is fh => $fh.
sub new {
    my $class = shift;
    my $user = { @_ };
    bless($user, $class);
    $stats{unknown}++;
    $user->{hostname} = look_up_host($user->{fh});
    $user->{connected} = 0;
    $user->{recv_buf} = '';
    $fh_to_user{$user->{fh}} = $user;
}

# Routine that's done after the server has received USER and NICK from the client.
sub logon {
    my ($user) = @_;
    # Increase user count.
    $stats{users}++;
    $stats{non_invisible_users}++;
    $stats{record_users} = $stats{users} > $stats{record_users} ? $stats{users} : $stats{record_users};
    $stats{unknown}--;

    print "Client connected: $user->{hostname} ($user->{nick})\n";
    $user->{connected} = 1;
    $user->send_server_msg("NOTICE AUTH :*** Hostname resolved: $user->{hostname}");
    $user->send_server_msg("NOTICE AUTH :*** Connection accepted.");
    $user->send_numeric_msg($RPL_WELCOME, $user->{nick}, $user->{username}, $user->{hostname});
    $user->send_numeric_msg($RPL_YOURHOST);
    $user->send_numeric_msg($RPL_CREATED);
    # Kludge, whatever, it works. This is how you make a client join chans, say things, etc.
    # Forcing a command, you have to make the arguments into an array ref.
    $user->vIRCd::Command::serv_lusers();
    $user->vIRCd::Command::serv_motd();
    my $join_chans = [ '#V64net' ];
    $user->vIRCd::Command::serv_join($join_chans);
}

# Done after someone quits or gets disconnected from the server.
sub logoff {
    my ($user) = @_;

    print "Client disconnected: $user->{hostname}\n";

    # Not a typo. QUIT sets connected to 2 to indicate the connection was cut cleanly.
    # Can't just unset it or it screws up the usercount code.
    if ($user->{connected} == 2) {
        my $write = syswrite($user->{fh}, $user->{recv_buf});
        if ($user->{nick} && $const{debug}) { print "Sending to $user->{hostname} ($user->{nick}): $user->{recv_buf}\n" }
        elsif ($const{debug}) { print "Sending to $user->{hostname}: $user->{recv_buf}\n" }
        if (!$write) { warn "Could not flush $user->{hostname}'s data.\n" }
    }

    $main::global{reader}->remove($user->{fh});
    $main::global{sender}->remove($user->{fh});
    $user->{fh}->close; # Oddly enough, if I do this any sooner, it screws up.

    if ($user->{connected}) {
        $stats{users}--;
        $stats{non_invisible_users}--;
    } else { $stats{unknown}-- }

    delete $fh_to_user{$user->{fh}};
    delete $nicks_in_use{lc $user->{nick}};
    for my $channel ($user->chan_list()) {
        delete $channel->{users}{$user->{nick}};
        if (!$channel->users_list($user->{nick})) { $channel->empty() }
    }
    
    undef $user;
} sub DESTROY { print "User memory successfully freed after destruction.\n" }

# Returns the User object that belongs to a given filehandle.
sub from_fh {
    my (undef, $fh) = @_;
    return $fh_to_user{$fh};
}

# Returns User object of nick if nick is in use.
sub used_nick {
    my (undef, $nick) = @_;
    $nick = lc $nick;
    if ($nicks_in_use{$nick}) {
        return $nicks_in_use{$nick};
    } else { return undef }
}

# Returns a list of Channel objects for each chan a nick is on.
sub chan_list {
    my ($user) = @_;
    my @chans;
    for (keys %{$user->{chans}}) {
        push(@chans, vIRCd::Channel->used_chan($_));
    }
    return @chans;
}

# Sends the invoking user a list of chans the argument is on,
# proper formatted, including the @ and + when appropriate.
# Used for /whois.
sub whois_chans {
    my ($user, $whoised) = @_;

    my $chan_str;
    for my $channel ($whoised->chan_list()) { $chan_str .= "$channel->{users}{$whoised->{nick}}$channel->{name} " }

    if ($chan_str) { $user->send_numeric_msg($RPL_WHOISCHANNELS, $whoised->{nick}, $chan_str) }
}

# Uniquely notifies everyone on the channels that $user is on.
# It's used for NICK changes and QUIT messages.
# It makes a unique list of users to avoid multiple messages to people
# who share multiple channels.
sub notify_chans {
    my ($user, $output) = @_;

    my %seen = ();
    my @unique = ();
    for my $channel ($user->chan_list()) {
        my @results = grep { !$seen{$_}++ } $channel->users_list($user->{nick});
        push @unique, @results;
    }

    for my $nick (@unique) {
        my $nickobj = vIRCd::User->used_nick($nick);
        $user->send_msg_to($nickobj, $output); 
    }
}

# Returns true if nick is on the chan. It returns one instead of the value
# of $user->{chans}{$channel} because it usually equals '' if the person has
# no voice or ops and the falseness of that causes trouble.
sub ison_chan {
    my ($user, $channel) = @_;
    $channel = vIRCd::Channel->used_chan($channel);
    $channel = $channel->{name};
    if (exists $user->{chans}{$channel}) {
        return 1;
    } else { return undef }
}

# Updates nickname records.
sub update_nicks {
    my ($user, $nick) = @_;

    if ($user->{nick}) { delete $nicks_in_use{lc $user->{nick}} }
    $nicks_in_use{lc $nick} = $user;

    for my $channel ($user->chan_list()) {
        $channel->{users}{$nick} = $channel->{users}{$user->{nick}};
        delete $channel->{users}{$user->{nick}};
    }
}

# Sends data prefixed with the server name. Used for data that doesn't have a numeric, like server notices.
sub send_server_msg {
    my ($user, $output) = @_;

    my $message = ":$const{server} ";
    $message .= "$output\n";
    $user->{recv_buf} .= $message;
    $main::global{sender}->add($user->{fh});
}

# Send a message with the address of the referent user to the user in the first param.
# $user == $to is used for nick and join messages to the user.
sub send_msg_to {
    my ($user, $to, $output) = @_;

    my $message = ":$user->{nick}!$user->{username}\@$user->{hostname} ";
    $message .= "$output\n";
    $to->{recv_buf} .= $message;
    $main::global{sender}->add($to->{fh});
}

# Sends data prefixed with the server name and the supplied numeric. Used for server numerics.
sub send_numeric_msg {
    my ($user, $numeric, @args) = @_;
    my $message;
    if ($user->{connected}) { $message = ":$const{server} $numeric $user->{nick} " }
    else { $message = ":$const{server} $numeric * " }

    $message .= sprintf "$numeric_str{$numeric}\n", @args;
    $user->{recv_buf} .= $message;
    $main::global{sender}->add($user->{fh});
}

# Does DNS and reverse DNS to find socket's full and real host.
sub look_up_host {
    my ($fh) = @_;
    my $iaddr = (unpack_sockaddr_in(getpeername($fh)))[1];
    my $actual_ip = inet_ntoa($iaddr);
    my $reverse_dns = gethostbyaddr($iaddr, AF_INET);

    if ($reverse_dns) {
        return $reverse_dns;
    } else { return $actual_ip }
}

1;