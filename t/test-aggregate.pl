#!/usr/bin/perl
use Test::Aggregate;
use strict; use warnings;
use File::Basename;
use Cwd 'abs_path';

my $aggregate_test_dir=dirname(abs_path(__FILE__));
print $aggregate_test_dir, "\n";
my $tests = Test::Aggregate->new( {
    dirs => $aggregate_test_dir,
} );
$tests->run;

ok 'Rocky here', 'Test::Aggregate also re-exports Test::More functions';
