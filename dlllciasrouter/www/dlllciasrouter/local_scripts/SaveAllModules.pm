#!/usr/bin/perl
use strict;
use warnings;

use EBox;
use EBox::Config;
use EBox::Global;

my $file = "/tmp/SaveAllModules.pm.lock";

if (-f $base_path)
{ 
  print "SaveAllModules.pm is locked.";
  exit;
}

# Use the open() function to create the file.
unless(open FILE, '>'.$file) {
    # Die with error message 
    # if we can't open it.
    die "\nUnable to create $file\n";
}

# Write some text to the file.
print FILE "SaveAllModules.pm is locked.";

# close the file.
close FILE;

EBox::init();

print "Saving all modules\n";
my $global = EBox::Global->getInstance();
$global->saveAllModules();

unlink $file;

print "Modules saved\n";
