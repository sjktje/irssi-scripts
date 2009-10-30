# Copyright (c) 2007 Svante J. Kvarnstrom <sjk@ankeborg.nu>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# This script has been tested on Ambernet with atheme-services 4.0.1
# 
# Settings: 
# /set akill_duration duration (default 1w)
# /set akill_reason reason (default drones/flooding)
# /set akill_operserv nick (default OperServ)
# /toggle akill_host_only (default off)
# /toggle akill_tilde_to_star (default on)

use strict;
use vars qw($VERSION %IRSSI);

use Irssi qw(
	settings_get_str settings_get_bool 
	settings_add_str settings_add_bool 
	command_bind signal_add active_win
);

use Getopt::Long;

$VERSION = "0.2.0";

%IRSSI = (
    authors => 'Svante J. Kvarnstrom',
    contact => 'sjk@ankeborg.nu',
    name    => 'akill',
    description =>
      '/akill [-perm|-time <nm|h|d|w>] <nick|host> <reason>',
    changed => 'Fri Oct 30 19:16:47 2009',
    license => 'BSDL',
);

my $argv;

# {{{ sub cmd_akill
sub cmd_akill {
    my ( $data, $server, $witem ) = @_;

    # If first arg is "help", print usage
    if ( $data =~ /^help/i || !$data ) { print_usage(); return; }

    # Don't bother doing anything if we're not connected to the server.
    if ( !$server ) { Irssi::print("Not connected to server"); return; }

	# No point in trying to akill if we aren't opered.
	if ( !is_opered() ) { Irssi::print("Oper status is required to set akills."); return; }

    $argv = parse_args($data);

    if ( $argv->{nick} =~ /@/ ) {    # If nick contains a @, treat it as a host
        $argv->{host} = $argv->{nick};
        set_akill( $server, $argv );
        return;
    }

    my $nick;                        # Nick of user to akill

    # Start off by looping through channels and see if $nick's in any of em.
    # If so, grab nicks host and akill
    for my $chan ( $server->channels ) {
        if ( $nick = $chan->nick_find( $argv->{nick} ) ) {
			$nick->{host} =~ /([^@]+)@(.*)/;
			$argv->{user} = $1;
			$argv->{host} = $2;
            set_akill( $server, $argv );
            return;
        }
    }

    # Ok, didn't find nick in any channels, let's do a /USERHOST
    $server->redirect_event(
        "userhost",
        1,
        $argv->{nick},
        0, undef,
        {
            "event 302" => "redir redir_userhost",
            ""          => "event empty",
        }
    );

    $server->send_raw("USERHOST $argv->{nick}");
}    # }}}

# {{{ sub is_opered
sub is_opered {
	my ($umode) = active_win()->{'active_server'}->{'usermode'};
	if ($umode =~ /[oO]/) {
		return 1;
	} else {
		return 0;
	}
} # }}}

# {{{ sub redir_userhost
sub redir_userhost {
    my ( $server, $data ) = @_;
    if ( !$data ) { Irssi::print("Couldn't find nick."); }
	
    if ( $data =~ /^[^\s]+\s:(?:[^=]+)=\+?([^@]+)\@(.*)/ ) {

        # Let's not akill opers.
        if ( $2 =~ /\*$/ ) {
            Irssi::print("We don't akill opers, aye?");
            return;
        }
		$argv->{user} = $1;
        $argv->{host} = $2;
        set_akill( $server, $argv );
    }
}    # }}}

# {{{ sub set_akill
sub set_akill {
    my ( $server, $argv ) = @_;

	my $operserv = settings_get_str('akill_operserv');
	
	$argv->{user} = "*" if settings_get_bool('akill_host_only');
	$argv->{user} =~ s/^~/\*/ if settings_get_bool('akill_tilde_to_star');	

    # XXX: We should use send_raw_now here, really.
    if ( $argv->{perm} ) {
		$server->command("PRIVMSG $operserv :AKILL ADD $argv->{user}\@$argv->{host} !P $argv->{reason}");
    }
    else {
		$server->command(
			"PRIVMSG $operserv :AKILL ADD $argv->{user}\@$argv->{host} !T $argv->{duration} $argv->{reason}");
    }
}    # }}}

# {{{ sub parse_args
sub parse_args {
    my ($data) = @_;

    my $arg;

    local @ARGV = split( /\s+/, $data );

    my $res = GetOptions(
        'time=s'     => \$arg->{duration},
        'duration=s' => \$arg->{duration},
        'perm'       => \$arg->{perm},
    );

    if (@ARGV) { $arg->{nick} = shift @ARGV; }

    for my $n (@ARGV) { $arg->{reason} .= $n . " "; }

    if ( !defined( $arg->{reason} ) ) {
        $arg->{reason} = settings_get_str('akill_reason');
    }
    if ( !defined( $arg->{duration} ) ) {
        $arg->{duration} = settings_get_str('akill_duration');
    }

    return $arg;
}    # }}}

# {{{ sub print_usage
sub print_usage {
    Irssi::print(
"Usage: /AKILL [-duration | -time <nm|h|d|w> | -perm] <nick> [reason]"
    );
}    # }}}

command_bind( 'akill', 'cmd_akill' );
signal_add( 'redir redir_userhost', 'redir_userhost' );
settings_add_str( 'akill', 'akill_duration', '1w' );
settings_add_str( 'akill', 'akill_reason',   'drones/flooding' );
settings_add_str( 'akill', 'akill_operserv', 'OperServ' );
settings_add_bool( 'akill', 'akill_host_only', 0 );
settings_add_bool( 'akill', 'akill_tilde_to_star', 1 );
