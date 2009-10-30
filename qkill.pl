# Copyright (c) 2009 Svante J. Kvarnstrom <sjk@ankeborg.nu>
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
use Irssi::Irc;

$VERSION = '0.0.1';

%IRSSI = (
    authors => 'Svante Kvarnström',
    #	contact		=> 'svarre@undernet.org',
    contact => 'sjk@ankeborg.nu',
    name    => 'qkill',
    description =>
      '/qkill nick1,nick2,nick3 [reason]. Read script for further details',
    license => 'GPL',
);

sub cmd_qkill {
    my ( $data, $server, $witem ) = @_;

    return show_help() if ( $data =~ /^help/ );
    return show_help() if ( !$data );

    my ( $nicks, $reason ) = split( /\s+/, $data, 2 );

    my $sendraw = Irssi::settings_get_bool("qkill_sendraw");

    $reason = Irssi::settings_get_str("qkill_reason") unless $reason;

    my @killnicks = split( /\,/, $nicks );

    foreach my $knick (@killnicks) {
        if ($sendraw) {
            $server->send_raw_now("KILL $knick :$reason");
        }
        else {
            $server->command("KILL $knick $reason");
        }
    }
}

sub show_help {
    Irssi::print("USAGE: /qkill nick1,nick2,nick3,nick4 [reason]");
}

Irssi::command_bind( 'qkill', 'cmd_qkill' );
Irssi::settings_add_str( 'qkill', 'qkill_reason',
'You are violating Undernet rules. Please take a look at http://www.undernet.org/user-com/documents/aup.php before returning.'
);
Irssi::settings_add_bool( 'qkill', 'qkill_sendraw', 0 );
