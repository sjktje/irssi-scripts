# Copyright (c) 2008 Svante J. Kvarnstrom <sjk@ankeborg.nu>
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

use Irssi;
use Irssi::Irc;

use strict;
use vars qw($VERSION %IRSSI);

# ----------------------------------------------------------------------

$VERSION = "0.0.2";
%IRSSI   = (
    authors     => 'Svante Kvarnström',
    contact     => 'sjk@ankeborg.nu',
    name        => 'lobby',
    description => 'Runs /LOBBY on connecting clients (with some exceptions)',
    license     => 'BSDL',
    url         => 'http://ankeborg.nu',
    changed     => 'Sun Feb 24 14:31:12 2008',
);

# ----------------------------------------------------------------------

sub process_snotice {
    my ( $server, $data, $nick, $host ) = @_;

    return unless Irssi::settings_get_bool('lobby_enabled');

    if ( $data !~ /^NOTICE/ || length($host) > 0 ) {
        return;
    }

    # We only want to process notices on tags in lobby_network_tags.
    my $active = 0;
    foreach my $tag (
        split( /\s+/, lc( Irssi::settings_get_str('lobby_network_tags') ) ) )
    {
        if ( lc($tag) eq lc( $server->{tag} ) ) {
            $active = 1;
            last;
        }
    }

    return unless $active;

    # Don't /LOBBY spoofed clients. Also ignore tunix and other search bots.
    if ( $data =~
/Client connecting: (?!tunix\d+)(?!Gogloom\d+)(?!scrawl\d+)(.*) \(.*@.*\) \[(?!255\.255\.255\.255)(?:\d{1,3}\.){3}\d{1,3}\] \{.*\} \[.*\]/
      )
    {
        $server->send_raw_now( "PRIVMSG "
              . Irssi::settings_get_str('lobby_report_chan')
              . " :Lobbying $1" )
          if Irssi::settings_get_bool('lobby_report_enable');
        $server->send_raw_now("LOBBY $1");
    }
}

# ----------------------------------------------------------------------

Irssi::theme_register(
    [ 'lobby_loaded', '%R>>%n %_Scriptinfo:%_ Loaded $0 version $1 by $2.', ] );

# ----------------------------------------------------------------------

Irssi::signal_add_first( "server event", "process_snotice" );

Irssi::settings_add_bool( 'lobby', 'lobby_enabled',       0 );
Irssi::settings_add_bool( 'lobby', 'lobby_report_enable', 1 );
Irssi::settings_add_str( 'lobby', 'lobby_network_tags', '' );
Irssi::settings_add_str( 'lobby', 'lobby_report_chan',  '#reports' );

Irssi::printformat( MSGLEVEL_CLIENTCRAP, 'lobby_loaded', $IRSSI{name}, $VERSION,
    $IRSSI{authors} );

