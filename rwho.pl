# rwho.pl
#
# !IMPORTANT! - This script is BROKEN and is only in the repository for 
# historical reasons only! Do not use this.
#
# Credits:
#
# coekie - coekie@undernet.org
# mauke  - unknown
#
# This program is free software, you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PERTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
# SYNTAX:
# /rwho
#
# Settings:
#
# /set rwho_server      - server to /who on. Wildcard is supported (*)
# /set rwho_min_Users   - If the number of users using the same realname is less than this value, don't bother printing.
#
# ChangeLog:
# 2005022301 - Svante Kvarnstrom <svarre@undernet.org>
# Made spaces into "?", colour codes, bold, italics,
# underline into "<c>1,0", "<b>", "<i>", "<u>" when
# listing the /rwho output. Will probably make an
# option to make these "*" and "?" later.
#
# 2004070601 - Svante Kvarnstrom <svarre@undernet.org>
# Initial release.
#
use strict;
use vars qw($VERSION %IRSSI);
use Irssi
  qw(settings_add_str settings_get_str signal_add command_bind printformat theme_register);

$VERSION = '2004070601';
%IRSSI   = (
    authors => 'Svarre',

    #    contact     =>  'svarre@undernet.org',
    contact => 'sjk@ankeborg.nu',
    name    => 'rwho.pl',
    description =>
'Lists commonly used realnames on the server/network. Tested on ircu. Oper privs are needed for this script to be efficient',
);

my %count;
my $rwho;

sub cmd_rwho {
    my ( $data, $server, $witem ) = @_;

    # Another /Rwho is already in progress
    if ($rwho) {
        printformat( MSGLEVEL_CLIENTCRAP, 'rwho_warn',
            'Another /RWHO is already in progress! Ignoring!' );
        return;
    }

    $server->redirect_event(
        "who", 1, "", 0, undef,
        {
            "event 352" => "redir rwhoitem",
            "event 315" => "redir rwhoitemend",
            ""          => "event empty"
        }
    );

    $server->send_raw(
        "WHO " . Irssi::settings_get_str('rwho_server') . " sx" );
    $rwho = 1;
    printformat( MSGLEVEL_CLIENTCRAP, 'rwho_start',
        Irssi::settings_get_str("rwho_server") );
}

sub event_rwhoitem {
    my ( $server, $data ) = @_;
    if ( $data =~ /(?:\S+\s+){8}(.*)$/ ) {
        my $item = $1;
        $item =~ s/\002/<b>/g;
        $item =~ s/\022/<i>/g;
        $item =~ s/\037/<u>/g;
        $item =~ s/\003([0-9]+)(,[0-9+])?/<c>\1,\2/g;
        $item =~ s/\s/?/g;
        $count{"$item"}++;
    }
}

# something is wrong in the following sub

sub event_rwhoitemend {
    foreach my $key ( keys %count ) {
        if ( $count{$key} >= Irssi::settings_get_str('rwho_min_users') ) {

            #   $key =~ s/\002/<b>/g;
            #   $key =~ s/\022/<i>/g;
            #   $key =~ s/\037/<u>/g;
            #   $key =~ s/\003([0-9]+)(,[0-9+])?/<c>\1,\2/g;
            printformat( MSGLEVEL_CLIENTCRAP, 'rwho_item',
                "$count{\"$key\"}", "$key"
            );
            $count{"$key"} = 0;
        }
        $count{"$key"} = 0;
    }
    $rwho = 0;
    printformat( MSGLEVEL_CLIENTCRAP, 'rwho_end' );
}

command_bind( 'rwho', 'cmd_rwho' );
signal_add( 'redir rwhoitem',    'event_rwhoitem' );
signal_add( 'redir rwhoitemend', 'event_rwhoitemend' );
settings_add_str( 'rwho', 'rwho_min_users', '5' );
settings_add_str( 'rwho', 'rwho_server',    'lidingo*' );

theme_register(
    [
        'rwho_start',  '%R>>%n /RWHO on $0',
        'rwho_item',   '%R>>%n $[-4]0: $1',
        'rwho_end',    '%R>>%n End of /RWHO',
        'rwho_warn',   '%R>> WARNING:%n $0',
        'rwho_loaded', '%R>>%n %_Scriptinfo:%_ Loaded $0 version $1 by $2.',
    ]
);

printformat( MSGLEVEL_CLIENTCRAP, 'rwho_loaded', $IRSSI{name}, $VERSION,
    $IRSSI{authors} );
