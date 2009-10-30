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

use strict;
use vars qw($VERSION %IRSSI);

use Irssi;
use Getopt::Long;

$VERSION = "0.1.1";

%IRSSI = (
    authors => 'Svante J. Kvarnstrom',
    contact => 'sjk@ankeborg.nu',
    name    => 'kline',
    description =>
      '/kline [-on <server>] [-perm|-time <mins>] <nick|host> <reason>',
    changed => 'Tue Jan  6 12:42:47 2009',
    license => 'BSDL',
);

my $argv;

# {{{ sub cmd_kline
sub cmd_kline {
    my ( $data, $server, $witem ) = @_;

    # If first arg is "help", print usage
    if ( $data =~ /^help/i || !$data ) { print_usage(); return; }

    # Don't bother doing anything if we're not connected to the server.
    if ( !$server ) { Irssi::print("Not connected to server"); return; }

	# No point in trying to kline if we aren't opered.
	if ( !is_opered() ) { Irssi::print("Oper status is required to set klines."); return; }

    $argv = parse_args($data);

    if ( $argv->{nick} =~ /@/ ) {    # If nick contains a @, treat it as a host
        $argv->{host} = $argv->{nick};
        set_kline( $server, $argv );
        return;
    }

    my $nick;                        # Nick of user to kline

    # Start off by looping through channels and see if $nick's in any of em.
    # If so, grab nicks host and kline
    for my $chan ( $server->channels ) {
        if ( $nick = $chan->nick_find( $argv->{nick} ) ) {
            $argv->{host} = $nick->{host};
            $argv->{host} =~ s/^.*@/\*@/;
            set_kline( $server, $argv );
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
	my ($umode) = Irssi::active_win()->{'active_server'}->{'usermode'};
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

    if ( $data =~ /^[^\s]+\s:([^=]+)=[^@]+\@(.*)/ ) {

        # Let's not kline opers.
        if ( $1 =~ /\*$/ ) {
            Irssi::print("We don't kline opers, aye?");
            return;
        }
        $argv->{host} = "*\@$2";
        set_kline( $server, $argv );
    }
}    # }}}

# {{{ sub set_kline
sub set_kline {
    my ( $server, $argv ) = @_;

    my $on;
    $argv->{server} ? $on = "ON $argv->{server}" : "";

    # XXX: We should use send_raw_now here, really.
    if ( $argv->{perm} ) {
        $server->command("QUOTE KLINE $argv->{host} $on :$argv->{reason}");
    }
    else {
        $server->command(
            "QUOTE KLINE $argv->{duration} $argv->{host} $on :$argv->{reason}");
    }
}    # }}}

# {{{ sub parse_args
sub parse_args {
    my ($data) = @_;

    my $arg;

    local @ARGV = split( /\s+/, $data );

    my $res = GetOptions(
        'time=i'     => \$arg->{duration},
        'duration=i' => \$arg->{duration},
        'server=s'   => \$arg->{server},
        'on=s'       => \$arg->{server},
        'perm'       => \$arg->{perm},
    );

    if (@ARGV) { $arg->{nick} = shift @ARGV; }

    for my $n (@ARGV) { $arg->{reason} .= $n . " "; }

    if ( !defined( $arg->{reason} ) ) {
        $arg->{reason} = Irssi::settings_get_str('kline_reason');
    }
    if ( !defined( $arg->{duration} ) ) {
        $arg->{duration} = Irssi::settings_get_str('kline_duration');
    }

    return $arg;
}    # }}}

# {{{ sub print_usage
sub print_usage {
    Irssi::print(
"Usage: /KLINE [-on | -server <server>] [-duration | -time <minutes> | -perm] <nick> [reason]"
    );
}    # }}}

Irssi::command_bind( 'kline', 'cmd_kline' );
Irssi::signal_add( 'redir redir_userhost', 'redir_userhost' );
Irssi::settings_add_str( 'kline', 'kline_duration', '14400' );
Irssi::settings_add_str( 'kline', 'kline_reason',   'drones/flooding' );
