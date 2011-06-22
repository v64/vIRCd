package vIRCd::Channel;
use strict; use warnings;

use vIRCd::Constant qw($RPL_NAMREPLY $RPL_ENDOFNAMES %stats);

my %chans_in_use;

# Creates a new channel, receives name => #channel as input.
sub new {
    my $class = shift;
    my $channel = { @_ };
    bless($channel, $class);
    $stats{channels}++;
    $channel->{creation} = time;
    $channel->{mode} = '';
    $channel->{topic} = '';
    $chans_in_use{lc $channel->{name}} = $channel;
    return $channel;
}

# Frees a Channel object's memory when it's empty.
sub empty {
    my ($channel) = @_;
    $stats{channels}--;
    delete $chans_in_use{lc $channel->{name}};
    undef $channel;
} sub DESTROY { print "Channel memory successfully freed after destruction.\n" }

# Returns the Channel object for a chan if it exists.
sub used_chan {
    my (undef, $channel) = @_;
    $channel = lc $channel;
    if ($chans_in_use{$channel}) {
        return $chans_in_use{$channel};
    } else { return undef }
}

# Sends out a /names list, proper formatted, including the @ and + when appropriate.
sub names_list {
    my ($channel, $user) = @_;

    my $names;
    for (keys %{$channel->{users}}) { $names .= "$channel->{users}{$_}$_ " }

    $user->send_numeric_msg($RPL_NAMREPLY, $channel->{name}, $names);
    $user->send_numeric_msg($RPL_ENDOFNAMES, $channel->{name});
}

# Sends a message to everyone on the channel except the person giving the command.
# From $self->users_list() which returns a list of everyone on the chan but the
# sender.
sub sendchan_msg_from {
    my ($channel, $sender, $output) = @_;

    for my $nickname ($channel->users_list($sender->{nick})) {
        my $nickobj = vIRCd::User->used_nick($nickname);
        $sender->send_msg_to($nickobj, $output);
    }
}

# Returns a list of everyone on the channel but the person invoking the command.
sub users_list {
    my ($channel, $sender_nick) = @_;
    my @names = grep { $_ ne $sender_nick } keys %{$channel->{users}};
    return @names;
}

1;