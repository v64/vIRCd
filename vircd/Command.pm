package vIRCd::Command;
use strict; use warnings;

use vIRCd::User;
use vIRCd::Channel;
use vIRCd::Constant qw(:numerics %const %stats);

my %commhash;
$commhash{user}     = \&serv_user;
$commhash{nick}     = \&serv_nick;
$commhash{privmsg}  = \&serv_privmsg;
$commhash{whois}    = \&serv_whois;
$commhash{lusers}   = \&serv_lusers;
$commhash{motd}     = \&serv_motd;
$commhash{notice}   = \&serv_privmsg;
$commhash{join}     = \&serv_join;
$commhash{part}     = \&serv_part;
$commhash{quit}     = \&serv_quit;
$commhash{chghost}  = \&serv_chghost;
$commhash{userhost} = \&serv_userhost;
$commhash{topic}    = \&serv_topic;

# Used to get a command and redirect it to the proper subroutine to handle the command.
# Also returns an error for unknown commands.
sub process_command {
    my ($user, $command, $args) = @_;

    # That's to catch anyone trying to send any other commands when they're not registered.
    if (!$user->{connected} && ($command ne 'nick' && $command ne 'user')) {
        $user->send_numeric_msg($ERR_NOTREGISTERED, $command);
        return;
    }

    if (exists $commhash{$command}) {
        # This is a huge kludge. It might be worth it to just write two commands or something.
        unless ($command eq 'privmsg' || $command eq 'notice') {
            $commhash{$command}->($user, $args);
        } else {
            $commhash{$command}->($user, $args, $command);
        }
    } else { $user->send_numeric_msg($ERR_UNKNOWNCOMMAND, $command) }
}

# Handles the user command. If NICK has already been issued, logs on.
sub serv_user {
    my ($user, $args) = @_;
    my @user_info = split / /, "@$args";

    if (!$user->{connected}) {
        if (@user_info < 4) {
            $user->send_numeric_msg($ERR_NEEDMOREPARAMS, 'USER');
            return;
        }
        $user->{username} = "$user_info[0]";
        $user->{realname} = "@user_info[3..$#user_info]";

        if ($user->{nick_done}) {
            delete $user->{nick_done};
            $user->logon();
        } else { $user->{user_done} = 1 }
    } else { $user->send_numeric_msg($ERR_ALREADYREGISTRED) }
}

# Handles the nick command. If NICK has already been issued, logs on.
# Also handles nick changes.
sub serv_nick {
    my ($user, $args) = @_;
    my $nick = $args->[0];
    if (!$nick) {
        $user->send_numeric_msg($ERR_NONICKNAMEGIVEN);
        return;
    }

    $nick =~ s/^\://;
    $nick = substr($nick, 0, 30);

    if ($user->{connected}) {
        if ($nick eq $user->{nick}) { return }
     
        # a-z A-Z 0-9 ^ _ - ` \ [ ] { } | are the valid characters. Nick can't start with a digit or a -.
        elsif (($nick =~ /^[0-9\-]/) || ($nick =~ /[^a-zA-Z0-9\^_\-\`\\\[\]\{\}\|]/)) {
            $user->send_numeric_msg($ERR_ERRONEUSNICKNAME, $nick, 'Illegal characters');
        }
        elsif (lc $nick eq 'nickserv') {
            $user->send_numeric_msg($ERR_ERRONEUSNICKNAME, 'NickServ', 'No password stealing. Thanks.');
        }
        elsif (vIRCd::User->used_nick($nick)) {
            $user->send_numeric_msg($ERR_NICKNAMEINUSE, $nick);
        }
        else {
            # We have to send the message to ourself first so that the nick message comes out with the proper address:
            $user->send_msg_to($user, "NICK :$nick");
            $user->notify_chans("NICK :$nick");
            $user->update_nicks($nick);
            $user->{nick} = $nick;
        }

    }
    else {
        if (($nick =~ /^[0-9\-]/) || ($nick =~ /[^a-zA-Z0-9\^_\-\`\\\[\]\{\}\|]/)) {
            $user->send_numeric_msg($ERR_ERRONEUSNICKNAME, $nick, 'Illegal characters');
        }
        elsif (lc $nick eq 'nickserv') {
            $user->send_numeric_msg($ERR_ERRONEUSNICKNAME, 'NickServ', 'No password stealing. Thanks.');
        }
        elsif (vIRCd::User->used_nick($nick)) {
            $user->send_numeric_msg($ERR_NICKNAMEINUSE, $nick);
        }
        else {
            $user->{nick} = $nick;
            $user->update_nicks($nick);
            if ($user->{user_done}) {
                delete $user->{user_done};
                $user->logon();
            } else { $user->{nick_done} = 1 }
        }

    }
}

# Sends off NOTICEs and PRIVMSGs.
sub serv_privmsg {
    my ($user, $args, $command) = @_;
    my ($to, @message_text) = (split / /, "@$args");
    if (!@message_text) {
        $user->send_numeric_msg($ERR_NOTEXTTOSEND);
        return;
    }

    if (substr($to, 0, 1) eq '#') {
        # Assume +n, will put code in later as /mode is written.
        my $channel = vIRCd::Channel->used_chan($to);
        if ($channel && $user->ison_chan($to)) {
            $channel->sendchan_msg_from($user, "$command $channel->{name} @message_text");
        } elsif ($channel) {
            $user->send_numeric_msg($ERR_NOTONCHANNEL, $channel->{name})
        } else { $user->send_numeric_msg($ERR_NOSUCHCHANNEL, $to) }
    } else {
        my $receiver = $user->used_nick($to);
        if ($receiver) {
            $user->send_msg_to($receiver, "$command $receiver->{nick} @message_text");
        } else { $user->send_numeric_msg($ERR_NOSUCHNICK, $to) }
    }
}

# Returns whois data about a nick.
sub serv_whois {
    my ($user, $args) = @_;
    my $nick = $args->[0];
    if (!$nick) {
        $user->send_numeric_msg($ERR_NONICKNAMEGIVEN);
        return;
    }

    my $whoised = vIRCd::User->used_nick($nick);
    if ($whoised) {
        $user->send_numeric_msg($RPL_WHOISUSER, $whoised->{nick}, $whoised->{username}, $whoised->{hostname}, $whoised->{realname});
        $user->whois_chans($whoised);
        $user->send_numeric_msg($RPL_WHOISSERVER, $whoised->{nick});
        $user->send_numeric_msg($RPL_ENDOFWHOIS, $whoised->{nick});
    } else {
        $user->send_numeric_msg($ERR_NOSUCHNICK, $nick);
        $user->send_numeric_msg($RPL_ENDOFWHOIS, $nick);
    }
}

# Returns server connection data.
sub serv_lusers {
    my ($user) = @_;
    $user->send_numeric_msg($RPL_LUSERCLIENT, $stats{non_invisible_users}, $stats{invisible_users}, $stats{servers});
    $user->send_numeric_msg($RPL_LUSEROP, $stats{operators});
    $user->send_numeric_msg($RPL_LUSERUNKNOWN, $stats{unknown});
    $user->send_numeric_msg($RPL_LUSERCHANNELS, $stats{channels});
    $user->send_numeric_msg($RPL_LUSERME, $stats{users}, $stats{servers});
    $user->send_numeric_msg($RPL_LOCALUSERS, $stats{users}, $stats{record_users});
    $user->send_numeric_msg($RPL_GLOBALUSERS, $stats{users}, $stats{record_users});
}

# Returns the message of the day.
sub serv_motd {
    my ($user) = @_;
    if (open MOTD, $const{motd_file}) {
        $user->send_numeric_msg($RPL_MOTDSTART, $const{server});
        while (<MOTD>) { $user->send_numeric_msg($RPL_MOTD, $_) }
        $user->send_numeric_msg($RPL_ENDOFMOTD);
        close MOTD;
    } else {
        $user->send_numeric_msg($ERR_NOMOTD);
        warn "MOTD could not be opened: $!\n";
    }
}

# Handles the join command.
sub serv_join {
    my ($user, $args) = @_;
    my $chanlist = $args->[0];
    my @channels = split ',', $chanlist;
    unless (@channels) {
        $user->send_numeric_msg($ERR_NEEDMOREPARAMS, 'JOIN');
        return;
    }

    for my $chan (@channels) {
        my $channel = vIRCd::Channel->used_chan($chan);
        if ($channel && $user->ison_chan($channel->{name})) {
            return;
        } elsif ($channel) {
            $channel->{users}{$user->{nick}} = '';
            $user->{chans}{$channel->{name}} = '';

            $user->send_msg_to($user, "JOIN :$channel->{name}");
            $channel->sendchan_msg_from($user, "JOIN :$channel->{name}");
            if ($channel->{topic}) {
                $user->send_numeric_msg($RPL_TOPIC, $channel->{name}, $channel->{topic});
                $user->send_numeric_msg($RPL_TOPICWHOTIME, $channel->{name}, $channel->{topicauthor}, $channel->{topictime});
            }
            $channel->names_list($user);
            $user->send_numeric_msg($RPL_CHANNELMODEIS, $channel->{name}, $channel->{mode});
            $user->send_numeric_msg($RPL_CREATIONTIME, $channel->{name}, $channel->{creation});
        } else {
            $channel = vIRCd::Channel->new(name => $chan);
            $channel->{users}{$user->{nick}} = '@';
            $user->{chans}{$channel->{name}} = '@';

            $user->send_msg_to($user, "JOIN :$channel->{name}");
            $channel->names_list($user);
            $user->send_numeric_msg($RPL_CHANNELMODEIS, $channel->{name}, $channel->{mode});
            $user->send_numeric_msg($RPL_CREATIONTIME, $channel->{name}, $channel->{creation});
        }
    }
}

sub serv_part {
    my ($user, $args) = @_;
    my $chanlist = $args->[0];
    my $part_msg = "@$args[1..$#{$args}]" || '';
    my @channels = split ',', $chanlist;
    unless (@channels) {
        $user->send_numeric_msg($ERR_NEEDMOREPARAMS, 'PART');
        return;
    }

    for my $chan (@channels) {
        my $channel = vIRCd::Channel->used_chan($chan);
        if ($channel && $user->ison_chan($channel->{name})) {
            $user->send_msg_to($user, "PART $channel->{name} $part_msg");
            $channel->sendchan_msg_from($user, "PART $channel->{name} $part_msg");
            delete $user->{chans}{$channel->{name}};
            delete $channel->{users}{$user->{nick}};
            if (!$channel->users_list($user->{nick})) { $channel->empty() }
        } elsif ($channel) {
            $user->send_numeric_msg($ERR_NOTONCHANNEL, $channel->{name});
        } else {
            $user->send_numeric_msg($ERR_NOSUCHCHANNEL, $chan);
        }
    }
}

sub serv_quit {
    my ($user, $args, $command) = @_;
    my $quit_msg = "@$args[0..$#{$args}]" || 'Client Disconnected';
    $quit_msg =~ s/^\://;
    if (!$command) { $user->{connected} = 2 }
    $command = $command ? 'Error' : 'Quit';
    $user->send_msg_to($user, "QUIT :$command: $quit_msg");
    $user->notify_chans("QUIT :$command: $quit_msg");
    $user->logoff();
}

sub serv_chghost {
    my ($user, $args) = @_;
    if (@$args != 2) {
        $user->send_numeric_msg($ERR_NEEDMOREPARAMS, 'CHGHOST');
        return;
    }
    $user->{username} = $args->[0];
    $user->{hostname} = $args->[1];
    $user->send_server_msg("NOTICE AUTH :*** User address changed to $args->[0]\@$args->[1].");
}

sub serv_userhost {
    my ($user, $args) = @_;
    my $nick = $args->[0];
    if (!$nick) {
        $user->send_numeric_msg($ERR_NEEDMOREPARAMS, 'USERHOST');
        return;
    }
    my $nickobj = vIRCd::User->used_nick($nick);
    if (!$nickobj) {
        $user->send_numeric_msg($RPL_USERHOST, '');
        return;
    }
    my $host = "$nickobj->{nick}=+$nickobj->{username}\@$nickobj->{hostname}";
    $user->send_numeric_msg($RPL_USERHOST, $host);
}

sub serv_topic {
    my ($user, $args) = @_;
    if (@$args == 0) {
        $user->send_numeric_msg($ERR_NEEDMOREPARAMS, 'TOPIC');
        return;
    }

    my $chan_name = $args->[0];
    my $channel = vIRCd::Channel->used_chan($chan_name);
    my $topic = "@$args[1..$#{$args}]" if $args->[1];
    $topic =~ s/^\:// if $topic;

    # Logic headache ahead.
    if ($user->ison_chan($chan_name)) {
        if (!defined($topic)) {
            if ($channel->{topic}) {
                $user->send_numeric_msg($RPL_TOPIC, $channel->{name}, $channel->{topic});
                $user->send_numeric_msg($RPL_TOPICWHOTIME, $channel->{name}, $channel->{topicauthor}, $channel->{topictime});
            } else {
                $user->send_numeric_msg($RPL_NOTOPIC);
            }
        } else {
            if ($channel->{users}{$user->{nick}} eq '@') { # Assume +t.
                if ($topic) {
                    if ($topic eq $channel->{topic}) { return }
                    $channel->{topicauthor} = $user->{nick};
                    $channel->{topictime} = time;
                    $channel->{topic} = $topic;
                    $user->send_msg_to($user, "TOPIC $channel->{name} :$channel->{topic}");
                    $channel->sendchan_msg_from($user, "TOPIC $channel->{name} :$channel->{topic}");
                } else {
                    delete $channel->{topicauthor};
                    delete $channel->{topictime};
                    $channel->{topic} = '';
                    $user->send_msg_to($user, "TOPIC $channel->{name} :");
                    $channel->sendchan_msg_from($user, "TOPIC $channel->{name} :");
                }
            } else {
                $user->send_numeric_msg($ERR_CHANOPRIVSNEEDED, $channel->{name});
            }
        }
    } else {
        $user->send_numeric_msg($ERR_NOTONCHANNEL, $channel->{name});
    }
}

1;