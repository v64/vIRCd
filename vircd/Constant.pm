package vIRCd::Constant;
use strict; use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    $RPL_WELCOME
    $RPL_YOURHOST
    $RPL_CREATED
    $RPL_LUSERCLIENT
    $RPL_LUSEROP
    $RPL_LUSERUNKNOWN
    $RPL_LUSERCHANNELS
    $RPL_LUSERME
    $RPL_LOCALUSERS
    $RPL_GLOBALUSERS
    $RPL_USERHOST
    $RPL_WHOISUSER
    $RPL_WHOISSERVER
    $RPL_ENDOFWHOIS
    $RPL_WHOISCHANNELS
    $RPL_CHANNELMODEIS
    $RPL_CREATIONTIME
    $RPL_NOTOPIC
    $RPL_TOPIC
    $RPL_TOPICWHOTIME
    $RPL_NAMREPLY
    $RPL_ENDOFNAMES
    $RPL_MOTD
    $RPL_MOTDSTART
    $RPL_ENDOFMOTD
    $ERR_NOSUCHNICK
    $ERR_NOSUCHCHANNEL
    $ERR_NOTEXTTOSEND
    $ERR_UNKNOWNCOMMAND
    $ERR_NOMOTD
    $ERR_NONICKNAMEGIVEN
    $ERR_ERRONEUSNICKNAME
    $ERR_NICKNAMEINUSE
    $ERR_NOTONCHANNEL
    $ERR_NOTREGISTERED
    $ERR_NEEDMOREPARAMS
    $ERR_ALREADYREGISTRED
    $ERR_CHANOPRIVSNEEDED
    %const
    %numeric_str
    %stats
);
our %EXPORT_TAGS =
(numerics =>
    [qw(
    $RPL_WELCOME
    $RPL_YOURHOST
    $RPL_CREATED
    $RPL_LUSERCLIENT
    $RPL_LUSEROP
    $RPL_LUSERUNKNOWN
    $RPL_LUSERCHANNELS
    $RPL_LUSERME
    $RPL_LOCALUSERS
    $RPL_GLOBALUSERS
    $RPL_USERHOST
    $RPL_WHOISUSER
    $RPL_WHOISSERVER
    $RPL_ENDOFWHOIS
    $RPL_WHOISCHANNELS
    $RPL_CHANNELMODEIS
    $RPL_CREATIONTIME
    $RPL_NOTOPIC
    $RPL_TOPIC
    $RPL_TOPICWHOTIME
    $RPL_NAMREPLY
    $RPL_ENDOFNAMES
    $RPL_MOTD
    $RPL_MOTDSTART
    $RPL_ENDOFMOTD
    $ERR_NOSUCHNICK
    $ERR_NOSUCHCHANNEL
    $ERR_NOTEXTTOSEND
    $ERR_UNKNOWNCOMMAND
    $ERR_NOMOTD
    $ERR_NONICKNAMEGIVEN
    $ERR_ERRONEUSNICKNAME
    $ERR_NICKNAMEINUSE
    $ERR_NOTONCHANNEL
    $ERR_NOTREGISTERED
    $ERR_NEEDMOREPARAMS
    $ERR_ALREADYREGISTRED
    $ERR_CHANOPRIVSNEEDED
    )]
);

# Strings because they're really strings, not numbers.
# Preserves the zeroes in RPL_WELCOME, etc.
our $RPL_WELCOME           = '001';
our $RPL_YOURHOST          = '002';
our $RPL_CREATED           = '003';
our $RPL_LUSERCLIENT       = '251';
our $RPL_LUSEROP           = '252';
our $RPL_LUSERUNKNOWN      = '253';
our $RPL_LUSERCHANNELS     = '254';
our $RPL_LUSERME           = '255';
our $RPL_LOCALUSERS        = '265';
our $RPL_GLOBALUSERS       = '266';
our $RPL_USERHOST          = '302';
our $RPL_WHOISUSER         = '311';
our $RPL_WHOISSERVER       = '312';
our $RPL_ENDOFWHOIS        = '318';
our $RPL_WHOISCHANNELS     = '319';
our $RPL_CHANNELMODEIS     = '324';
our $RPL_CREATIONTIME      = '329';
our $RPL_NOTOPIC           = '331';
our $RPL_TOPIC             = '332';
our $RPL_TOPICWHOTIME      = '333';
our $RPL_NAMREPLY          = '353';
our $RPL_ENDOFNAMES        = '366';
our $RPL_MOTD              = '372';
our $RPL_MOTDSTART         = '375';
our $RPL_ENDOFMOTD         = '376';
our $ERR_NOSUCHNICK        = '401';
our $ERR_NOSUCHCHANNEL     = '403';
our $ERR_NOTEXTTOSEND      = '412';
our $ERR_UNKNOWNCOMMAND    = '421';
our $ERR_NOMOTD            = '422';
our $ERR_NONICKNAMEGIVEN   = '431';
our $ERR_ERRONEUSNICKNAME  = '432';
our $ERR_NICKNAMEINUSE     = '433';
our $ERR_NOTONCHANNEL      = '442';
our $ERR_NOTREGISTERED     = '451';
our $ERR_NEEDMOREPARAMS    = '461';
our $ERR_ALREADYREGISTRED  = '462';
our $ERR_CHANOPRIVSNEEDED  = '482';

our %const;
$const{version}     = 'Veachian-0.5';
$const{network}     = 'V64net';
$const{server}      = 'irc.V64.net';
$const{server_desc} = 'The Veachian IRCd - Written entirely in the Perl programming language.';
$const{started}     =  get_date();
$const{motd_file}   = 'vircd.motd';
$const{port}        = 4242;
$const{read_size}   = 1048576;
$const{debug}       = 1;

our %numeric_str;
$numeric_str{$RPL_WELCOME}           = ":Welcome to the $const{network} IRC Network %s!%s@%s";
$numeric_str{$RPL_YOURHOST}          = ":Your host is $const{server}, running version $const{version}";
$numeric_str{$RPL_CREATED}           = ":This server was created $const{started}";
$numeric_str{$RPL_LUSERCLIENT}       = ':There are %s users and %s invisible on %s servers';
$numeric_str{$RPL_LUSEROP}           = '%s :operator(s) online';
$numeric_str{$RPL_LUSERUNKNOWN}      = '%s :unknown connection(s)';
$numeric_str{$RPL_LUSERCHANNELS}     = '%s :channels formed';
$numeric_str{$RPL_LUSERME}           = ':I have %s clients and %s servers';
$numeric_str{$RPL_LOCALUSERS}        = ':Current Local Users: %s  Max: %s';
$numeric_str{$RPL_GLOBALUSERS}       = ':Current Global Users: %s  Max: %s';
$numeric_str{$RPL_USERHOST}          = ':%s';
$numeric_str{$RPL_WHOISUSER}         = '%s %s %s * %s';
$numeric_str{$RPL_WHOISSERVER}       = "%s $const{server} :$const{server_desc}";
$numeric_str{$RPL_ENDOFWHOIS}        = '%s :End of /WHOIS list.';
$numeric_str{$RPL_WHOISCHANNELS}     = '%s :%s';
$numeric_str{$RPL_CHANNELMODEIS}     = '%s +%s';
$numeric_str{$RPL_CREATIONTIME}      = '%s %s';
$numeric_str{$RPL_NOTOPIC}           = ':No topic is set.';
$numeric_str{$RPL_TOPIC}             = '%s :%s';
$numeric_str{$RPL_TOPICWHOTIME}      = '%s %s %s';
$numeric_str{$RPL_NAMREPLY}          = '= %s :%s'; # The equals sign is not a typo.
$numeric_str{$RPL_ENDOFNAMES}        = '%s :End of /NAMES list.';
$numeric_str{$RPL_MOTD}              = ':- %s';
$numeric_str{$RPL_MOTDSTART}         = ':- %s Message of the Day -';
$numeric_str{$RPL_ENDOFMOTD}         = ':End of /MOTD command.';
$numeric_str{$ERR_NOSUCHNICK}        = '%s :No such nickname';
$numeric_str{$ERR_NOSUCHCHANNEL}     = '%s :No such channel';
$numeric_str{$ERR_NOTEXTTOSEND}      = ':No text to send';
$numeric_str{$ERR_UNKNOWNCOMMAND}    = '%s :Unknown command or command not yet implemented';
$numeric_str{$ERR_NOMOTD}            = ':MOTD File is missing';
$numeric_str{$ERR_NONICKNAMEGIVEN}   = ':No nickname given';
$numeric_str{$ERR_ERRONEUSNICKNAME}  = '%s :Erroneus Nickname: %s';
$numeric_str{$ERR_NICKNAMEINUSE}     = '%s :Nickname is already in use.';
$numeric_str{$ERR_NOTONCHANNEL}      = '%s :You\'re not on that channel';
$numeric_str{$ERR_NOTREGISTERED}     = '%s :Register first';
$numeric_str{$ERR_NEEDMOREPARAMS}    = '%s :Not enough parameters';
$numeric_str{$ERR_ALREADYREGISTRED}  = ':You may not reregister';
$numeric_str{$ERR_CHANOPRIVSNEEDED}  = '%s :You don\'t have ops.';

our %stats;
$stats{users}               = 0;
$stats{record_users}        = 0;
$stats{invisible_users}     = 0;
$stats{non_invisible_users} = 0;
$stats{servers}             = 1;
$stats{operators}           = 0;
$stats{channels}            = 0;
$stats{unknown}             = 0;

# Supply a date to show when the server was started.
sub get_date {
    my @args = split / /, localtime $^T;
    "@args[0, 1, 2, 4] at $args[3] CST";
}

1;