#!/usr/bin/perl
### BEGIN INIT INFO
# Provides:          zentyal
# Required-Start:    $network
# Required-Stop:     $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Zentyal (Small Business Server)
### END INIT INFO

use strict;
use warnings;

no warnings 'experimental::smartmatch';
use feature qw(switch);

use EBox;
use EBox::Util::Init;

EBox::init();

$SIG{PIPE} = 'IGNORE';

sub usage {
	print "Usage: $0 start|stop|restart\n";
	print "       $0 <module> start|stop|status|enabled|restart\n";
	exit 1;
}

sub main
{
    if (@ARGV == 1) {
        given($ARGV[0]) {
            when ('start') {
                EBox::Util::Init::start();
                EBox::Sudo::root('initctl emit zentyal-started');
            }
            when ('restart') {
                EBox::Util::Init::stop();
                EBox::Util::Init::start();
            }
            when ('force-reload') {
                EBox::Util::Init::stop();
                EBox::Util::Init::start();
            }
            when ('stop') {
                EBox::Sudo::root('initctl emit zentyal-stopped');
                EBox::Util::Init::stop();
            }
            default {
                usage();
            }
        }
    } elsif (@ARGV == 2) {
        # action upon one module mode
        my ($modName, $action) = @ARGV;

        given ($action) {
            when (['restart', 'start']) {
                EBox::Util::Init::moduleRestart($modName);
            }
            when ('stop') {
                EBox::Util::Init::moduleStop($modName);
            }
            when ('status') {
                EBox::Util::Init::status($modName);
            }
            when ('enabled') {
                EBox::Util::Init::enabled($modName);
            }
            default {
                usage();
            }
        }
    } else {
        usage();
    }
}

main();

1;
