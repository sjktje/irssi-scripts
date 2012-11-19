# Irssi scripts

This repository contains a set of Irssi scripts. All, except
`warnkick.pl`, only make sense if your client is opered.

## akill

This script makes adding AKILL's to OperServ easy as pie. Available settings:

    /set akill_duration duration (default 1w)
    /set akill_reason reason (default drones/flooding)
    /set akill_operserv nick (default OperServ)
    /toggle akill_host_only (default off)
    /toggle akill_tilde_to_star (default on)


## iplist

Writes IP addresses of channel members to file. IP addresses are retrieved
using `chantrace`. Script may prove useful for adding drone IP addresses to a
firewall or similar:

    /iplist #dronechannel
    scp ~/iplist-#dronechannel.txt your.gateway:.
    ssh your.gateway pfctl -t drones -T add -f iplist-#dronechannel.txt

Passing `--full` to /IPLIST will generate iplist-#channel-full.txt which
includes nicknames, usernames, gecos and so on.

Spoofed users and server operators are recognised and are not added to lists.

## kline

Enhances the /kline command to simplify setting klines. Syntax:

    /kline [-on <server>] [-perm|-time <mins>] <nick|host> <reason>

If a nick is given, `kline` will automatically grab the users hostname and
kline that. The rest should be rather self explanatory.

## lobby
Issues /LOBBY on connecting clients. This requires that you are opered **and**
have access to a TARDIS which can take you to Ambernet. The /LOBBY command
ceased to be supported by Ambernet admins, thank god, and then the network
itself died a while later.

## lusergraph

This script was requested by someone in an EFnet Linux channel. It grabs the
local/global user count from the irc server and writes it to a file in a
mrtg-friendly format. Read the script documentation:

    $ pod2man lusergraph.pl |nroff -man |less

## qkill

Quick kill -- this is a simple script which takes a comma seperated list of
nicknames to KILL and optionally a kill message/reason:

    /qkill nick1,nick2,nick3 [reason]

The default reason is tuned for Undernet use: 'You are violating Undernet
rules. Please take a look at
http://www.undernet.org/user-com/documents/aup.php before returning'. The
default reason can be changed by changing `qkill_reason`:

    /set qkill_reason New reason goes here

It is possible to bypass irssi's sendqueue by toggling`qkill_sendraw`. Only do
this on ircds that permit oper flooding. The default is to use the send queue.

    /toggle qkill_sendraw

## rwho

This script is not really working anymore and is only in the repository for
historical reasons. It was used by me, sjk, on Undernet in 2006 or so to
detect "real name clones". I don't think this particular version of the script
is actually working.

## warnkick

This script will notify you if you're kicked out of a channel. A warning is
printed, and the channel refnum of the channel you were kicked out of is
hilighted. [This script is also available in the Irssi script
archive.](http://scripts.irssi.org/scripts/warnkick.pl)

## whocount

This script has no settings. It merely adds a total who count at the end of
/WHO replies.
