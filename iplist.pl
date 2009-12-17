#
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
#
#
#
# This script writes channel members IP addresses to a file. This can be
# useful if you want to report abuse or if you want to block the IP
# addresses in your firewall.
#
# For example, if you found a drone channel and you wanted to block
# their IP addresses on your IRC server, you could:
#
# /iplist #dronechannel
# scp ~/iplist-#dronechannel.txt your.irc.server.com:.
# pfctl -t drones -T add -f iplist-#dronechannel.txt
# (You might also want to kill any states with pfctl -k)
#
# If you pass "--full" to /IPLIST "iplist-#channel-full.txt" will
# be written which will include user nicknames, usernames, gecos
# and so on.
#
# The script ignores spoofed users as well as server operators.
#
# Tested on ircd-ratbox 2.2.6

use strict;
use Irssi;
use Irssi::Irc;
use Getopt::Long;
use vars qw($VERSION %IRSSI);

$VERSION = "0.1.1";
%IRSSI   = (
    authors     => 'Svante Kvarnstrom',
    contact     => 'sjk@ankeborg.nu',
    name        => 'iplist',
    description => 'Writes channel members IPs to file',
    license     => 'BSDL',
    url         => 'http://sjk.ankeborg.nu',
    changed     => 'Fri Oct 30 18:24:41 2009',
);

my $opt;
my %ips;

sub print_help {
    Irssi::print("SYNTAX: /IPLIST [--full] #channel");
    Irssi::print("See source file for more information.");
}

sub cmd_iplist {
    my ( $data, $server, $witem ) = @_;

    local @ARGV = split( /\s+/, $data );

    if ( $data =~ /^help/i ) {
        return print_help();
    }

    my $res = GetOptions( 'full' => \$opt->{full} );

    if (@ARGV) {
        $opt->{channel} = shift @ARGV;
    }

    if ( !$opt->{channel} ) {
        Irssi::print("You must specify a channel");
        return 0;
    }

    $server->redirect_event(
        "chantrace",
        1, undef, 0, undef,
        {
            "event 709" => "redir chantrace_line",
            "event 262" => "redir chantrace_end"
        }
    );

    $server->send_raw_now(
        "CHANTRACE ". 
        (channel_joined($opt->{channel}) ? '' : '!').
        $opt->{channel}
    );
}

# channel_joined("#chan") returns true if we're on #chan, false if not.
sub channel_joined {
    my ($data) = @_;
    my $server = Irssi::active_server();
    for my $chan ($server->channels) {
        if (lc($data) eq lc($chan->{name})) {
            return 1;
        }
    }
    
    return 0;
}

# Add IPs to the %ips hash.
sub chantrace_line {
    my ( $server, $data ) = @_;

    $data =~ s/[^\s]* //;    # Remove our nick.
    $data =~ /([^\s]+) ([^\s]+) ([^\s]+) ([^\s]+) ([^\s]+) ([^\s]+) :(.*)/;
    my ( $status, $server, $nick, $username, $host, $ip, $gecos ) =
      ( $1, $2, $3, $4, $5, $6, $7 );

    return if !$ip;                   # Ignore spoofs.
    return if $status eq "Oper";      # Ignore server operators.
    return if defined( $ips{ip} );    # We do not want any duplicates.

    if ( $opt->{full} ) {
        $ips{$ip} = "$server $nick $username\@$host ($ip) :$gecos";
    }
    else {
        $ips{$ip} = 1;
    }
}

# Chantrace done, time to write to file.
sub chantrace_end {
    my $file = Irssi::settings_get_str("iplist_path");
    $file =~ /(.*)\//;
    if ( $opt->{full} ) {
        $file .= "/iplist-" . $opt->{channel} . "-full.txt";
        open( IPFILE, ">$file" ) or die("Could not open file $file: $!");
        foreach my $key ( sort { $a <=> $b } keys %ips ) {
            print IPFILE "$ips{$key}\n";
        }
    }
    else {
        $file .= "/iplist-" . $opt->{channel} . ".txt";
        open( IPFILE, ">$file" ) or die("Could not open file $file: $!");
        foreach my $key ( sort { $a <=> $b } keys %ips ) {
            print IPFILE "$key\n";
        }
    }
    close(IPFILE);
}

Irssi::command_bind( "iplist", "cmd_iplist" );
Irssi::signal_add( "redir chantrace_line", "chantrace_line" );
Irssi::signal_add( "redir chantrace_end",  "chantrace_end" );
Irssi::settings_add_str( "iplist", "iplist_path", "/Users/sjk" );
Irssi::Irc::Server::redirect_register(
    "chantrace",
    0, 0,
    {
        "event 709" => 1,    #chantrace data
    },
    {
        "event 262" => 1,    #End of TRACE
    },
    undef
);

Irssi::command_set_options('iplist', 'full');
