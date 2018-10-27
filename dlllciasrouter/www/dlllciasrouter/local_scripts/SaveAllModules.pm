#!/usr/bin/perl
use strict;
use warnings;

use EBox;
use EBox::Config;
use EBox::Global;
EBox::init();

print "Saving all modules\n";
my $global = EBox::Global->getInstance();
$global->saveAllModules();
print "Modules saved\n";