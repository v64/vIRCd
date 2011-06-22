#!/usr/bin/perl
# The Veachian Internet Relay Chat Daemon - Coded by Jahn Veach/Veachian64 - V64@V64.net - http://v64.net/

use strict; use warnings;

our %global;
use vIRCd::Constant qw(%const);
use vIRCd::User;
use vIRCd::Command;

use IO::Select;
use IO::Socket;

print "Starting $const{version}......";

$global{listen} = IO::Socket::INET->new(
                    LocalPort => $const{port},
                    Listen    => 10,
                    Proto     => 'tcp',
                    Reuse     => 1,
                  )
or die "Unable to creating listening socket: $!\n";

$global{reader} = IO::Select->new();
$global{reader}->add($global{listen});
$global{sender} = IO::Select->new();
$global{sender}->add($global{listen});

print "Server running.\n";

while (1) {
    my @queues = IO::Select->select($global{reader}, $global{sender}, undef, 0.1);

    foreach my $fh (@{ $queues[1] }) {
        my $user = vIRCd::User->from_fh($fh);
        if ($const{debug} && $user->{nick}) {
            print "Sending to $user->{nick} ($user->{hostname}): $user->{recv_buf}\n"
        } elsif ($const{debug}) { print "Sending to $user->{hostname}: $user->{recv_buf}\n" }

        my $write = syswrite($user->{fh}, $user->{recv_buf});
        if ($write) {
            $user->{recv_buf} = '';
            $global{sender}->remove($fh);
        } else { warn "Error sending data to $user->{hostname}: $!\nData saved.\n" }
    }

    foreach my $fh (@{ $queues[0] }) {
        if ($fh != $global{listen}) {
            my $sent_buf;
            my $read = sysread($fh, $sent_buf, $const{read_size});
            my $user = vIRCd::User->from_fh($fh);
            if ($read) {
                $sent_buf =~ s/\r\n/\n/; # If they used \r\n instead of \n, strip the \r out.
                my @bufs = split(/\n/, $sent_buf);
                foreach my $args (@bufs) {
                    if ($const{debug} && $user->{nick}) {
                        print "Received from $user->{nick} ($user->{hostname}): $args\n";
                    } elsif ($const{debug}) { print "Received from $user->{hostname}: $args\n" }

                    my ($command, @args) = split(/ /, $args);
                    $command = lc $command;
                    vIRCd::Command::process_command($user, $command, \@args);
                }
            } else {
                my $quit_msg = [ qw(Connection reset by peer) ];
                $user->vIRCd::Command::serv_quit($quit_msg, 1);
            }
            # ^ If data can't be read, the client either disconnected or there was an error. Either way, get rid of their data.
        } else {
            my $fh = $global{listen}->accept;
            vIRCd::User->new(fh => $fh);
            $global{reader}->add($fh);
        }
    }
}
