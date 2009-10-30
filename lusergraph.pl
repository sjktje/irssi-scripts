use strict;
use vars qw($VERSION %IRSSI);

use Irssi;
use Irssi::Irc;

$VERSION = '0.1.1';
%IRSSI   = (
    authors => 'Svante Kvarnström',
    contact => 'sjk@ankeborg.nu',
    name    => 'lusergraph',
    description =>
      'Grabs local/global user count from server and writes mrtg-friendly file',
    license => 'BSD',
    url     => 'http://www.ankeborg.nu',
    changed => 'Mon Apr  7 01:03:32 2008',
);

# Use pod2man to read the documentation:
# pod2man lusergraph.pl |nroff -man |less

=pod

=head1 NAME

lusergraph

=head1 DESCRIPTION

This script issues /LUSERS at a given interval and writes local/global user 
counts to a specified file. 

=head1 GETTING STARTED

Place the script in ~/.irssi/scripts and load it in irssi with /script load
lusergraph.pl. If you want to have the script load automatically upon startup,
create a symlink to the script in ~/.irssi/scripts/autorun. 

=head1 COMMANDS

=head2 /lusergraph start

This starts the lusergraph timer.

=head2 /lusergraph stop

This stops the lusergraph timer.

=head1 OUTPUT

The script outputs data to whatever file set in lusergraph_file (see SETTINGS 
section.) The file will look something like this:

	10
	40
	138 days, 22:57:44
	ambernet

Where the first row contains number of local users, second row number of global
users, third row the uptime of the IRC server, and fourth the name of the IRC
network. 

=head1 SETTINGS

=head2 /set lusergraph_file (string)

File to write data to. Default /tmp/lusergraph.txt

=head2 /set lusergraph_timer (int)

Number of seconds between /LUSERS queries. Default 300 (five minutes)

=head2 /set lusergraph_tag (string)

Network the script should be active on. Multiple networks are NOT supported.

=head2 /set lusergraph_onconnect (boolean)

Whether lusergraph should start upon connecting to the network specified in 
lusergraph_tag or not.

=head1 CHANGES

7 April 2008 - version 0.1.1

* Event 219 (u :End of /STATS report) is now discarded if called by 
  lusergraph.

* /LUSERGRAPH START will not start lusergraph on the server of the active
  window anymore, use the lusergraph_tag setting instead.

* Lusergraph will start on connect if lusergraph_onconnect is true.

?? March 2008 - version 0.1
	
Initial release.

=head1 AUTHOR

Svante Kvarnström <sjk@ankeborg.nu>

=cut

my $local_users  = 0;
my $global_users = 0;
my $uptime;
my $timer;

sub cmd_lusergraph {
    my ( $data, $server, $item ) = @_;

    if ( $data =~ /^start$/i ) {

        add_timer();
        Irssi::print("Started timer");
        return;
    }

    if ( $data =~ /^stop$/i ) {
        Irssi::print("Stopped timer");
        Irssi::timeout_remove($timer);
        return;
    }

    Irssi::print("USAGE: /lusergraph <start|stop>");
}

sub add_timer {

    # timeout_add expects milliseconds, lusergraph_timer is in seconds.
    my $timeout_msecs = Irssi::settings_get_int('lusergraph_timer') * 1000;
    $timer = Irssi::timeout_add( $timeout_msecs, 'do_lusers', undef );
}

sub do_lusers {
    my $server =
      Irssi::server_find_tag( Irssi::settings_get_str('lusergraph_tag') );

    # Don't do anything if we're not connected.
    if ( !$server ) {
        Irssi::timeout_remove($timer);
        return;
    }

    $server->redirect_event(
        'command do_lusers',
        0, undef, 0, undef,
        {
            'event 242' => 'redir event_server_uptime',
            'event 250' => 'redir event_stop',
        }
    );

    $server->send_raw_now("STATS u");

    $server->redirect_event(
        'command do_lusers',
        0, undef, 0, undef,
        {
            'event 265' => 'redir event_local_users',
            'event 266' => 'redir event_global_users',
            'event 219' => 'redir event_stop',
            'event 251' => 'redir event_stop',
            'event 252' => 'redir event_stop',
            'event 253' => 'redir event_stop',
            'event 254' => 'redir event_stop',
            'event 255' => 'redir event_stop',
            'event 250' => 'redir event_stop',
        }
    );

    $server->send_raw_now("LUSERS");

}

#	>> :irc.pte.hu 242 sjk :Server Up 138 days, 22:57:44
sub event_server_uptime {
    my ( $server, $data, $nick, $address ) = @_;
    $data =~ /:Server Up (.*)/;
    $uptime = $1;
}

sub event_local_users {
    my ( $server, $data, $nick, $address ) = @_;
    $data =~ /(\d+) \d+ :Current local users \d+, max \d+/;

    $local_users = $1;
}

sub event_global_users {
    my ( $server, $data, $nick, $address ) = @_;
    $data =~ /(\d+) \d+ :Current global users \d+, max \d+/;

    $global_users = $1;

    write_file();
}

sub event_connect {
    my ($server) = @_;

    return unless Irssi::settings_get_bool('lusergraph_onconnect');

    if (
        lc( $server->{'tag'} ) eq
        lc( Irssi::settings_get_str('lusergraph_tag') ) )
    {
        add_timer();
    }
}

sub write_file {
    my $outfile = Irssi::settings_get_str('lusergraph_file');
    open OUT, ">$outfile" or die "Could not open $outfile for writing: $!";
    print OUT "$local_users\n";
    print OUT "$global_users\n";
    print OUT "$uptime\n";
    print OUT Irssi::settings_get_str('lusergraph_tag') . "\n";
    close OUT;
}

sub event_stop {
    Irssi::signal_stop();
}

#>> :irc.ankeborg.nu 251 tulle :There are 14 users and 30 invisible on 9 servers
#>> :irc.ankeborg.nu 252 tulle 10 :IRC Operators online
#>> :irc.ankeborg.nu 254 tulle 36 :channels formed
#>> :irc.ankeborg.nu 255 tulle :I have 8 clients and 1 servers
#>> :irc.ankeborg.nu 265 tulle 8 11 :Current local users 8, max 11
#>> :irc.ankeborg.nu 266 tulle 44 48 :Current global users 44, max 48
#>> :irc.ankeborg.nu 250 tulle :Highest connection count: 12 (11 clients) (120 connections received)

Irssi::Irc::Server::redirect_register(
    'command do_lusers',
    0, 0,
    {
        'event 265' => 1,
        'event 251' => 1,
        'event 252' => 1,
        'event 253' => 1,
        'event 254' => 1,
        'event 255' => 1,
        'event 266' => 1,
        'event 242' => 1,
        'event 219' => 1,
    },
    { 'event 250' => 1, },
    undef
);

Irssi::settings_add_str( 'lusergraph', 'lusergraph_file',
    '/tmp/lusergraph.txt' );
Irssi::settings_add_str( 'lusergraph', 'lusergraph_tag', 'ambernet' );
Irssi::settings_add_int( 'lusergraph', 'lusergraph_timer', 300 );
Irssi::settings_add_bool( 'lusergraph', 'lusergraph_onconnect', 0 );

Irssi::signal_add( 'redir event_local_users',   'event_local_users' );
Irssi::signal_add( 'redir event_global_users',  'event_global_users' );
Irssi::signal_add( 'redir event_server_uptime', 'event_server_uptime' );
Irssi::signal_add( 'redir event_stop',          'event_stop' );
Irssi::signal_add( 'event connected',           'event_connect' );
Irssi::command_bind( 'lusergraph', 'cmd_lusergraph' );
