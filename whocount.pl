# whocount.pl
# Newest version can always be found at http://github.com/sjktje/irssi-scripts 
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

# ----------------------------------------------------------------------

# Changelog:
# v0.0.1 - Svarre <svarre@svarre.net> - 2004-06-09
#	Initial release

# ----------------------------------------------------------------------

use strict;
use vars qw($VERSION %IRSSI);
use Irssi;

$VERSION = '0.0.1';
%IRSSI   = (
    authors     => 'Svarre',
#    contact     => 'svarre@svarre.net',
	contact		=> 'sjk@ankeborg.nu',
    name        => 'whocount.pl',
    description => 'Counts the number of matches a /who lists',
    license     => 'GPL',
    url         => 'http://www.svarre.net/code.php',
	url			=> 'http://sjk.ankeborg.nu',
);

# ----------------------------------------------------------------------

our $whocount;

sub count {
    $whocount++;
}

sub end_who {
    if ( $whocount == 1 ) {
        Irssi::printformat( MSGLEVEL_CLIENTCRAP, 'whocount', $whocount, 'user' );
    }
    else {
        Irssi::printformat( MSGLEVEL_CLIENTCRAP, 'whocount', $whocount, 'users' );
    }
    $whocount = '0';
}

# ----------------------------------------------------------------------

Irssi::signal_add( 'event 352', 'count' );
Irssi::signal_add( 'event 315', 'end_who' );

# ----------------------------------------------------------------------

Irssi::theme_register(
    [
        'whocount_loaded', '%R>>%n %_Scriptinfo:%_ Loaded $0 version $1 by $2.',
        'whocount', '%R>> %CWho:%n $0 $1'
    ]
);

# ----------------------------------------------------------------------

Irssi::printformat( MSGLEVEL_CLIENTCRAP, 'whocount_Loaded', $IRSSI{name},
    $VERSION, $IRSSI{authors} );

