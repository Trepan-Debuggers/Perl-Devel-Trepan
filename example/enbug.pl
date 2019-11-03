#!/usr/bin/env perl
use strict; use warnings;
use File::Basename;

BEGIN {
    push @INC, File::Basename::dirname(__FILE__);
}

require 'test-module.pm';

# GCD. We assume positive numbers

print "Process is $$ \$0 is $0\n";
require Enbugger; Enbugger->load_debugger('trepan');
Enbugger->stop();

Test::Module::five();
Test::Moudle::six();

my ($a, $b) = @ARGV[0,1];
printf "The GCD of %d and %d is %d\n", $a, $b, gcd($a, $b);
printf "Again, The GCD of %d+2 and %d is %d\n", $a, $b, gcd($a+2, $b);
