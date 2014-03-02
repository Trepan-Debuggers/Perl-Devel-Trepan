#!/usr/bin/env perl
use warnings; use strict;
use Test::More;
use rlib '.';
use Helper; use English;
use Config;
if ($OSNAME eq 'MSWin32') {
    plan skip_all => "FIXME weirdness in Strawberry's starup display I/O order"
} else {
    plan;
}

my $test_prog = File::Spec->catfile(dirname(__FILE__),
				    qw(.. example action-bug.pl));
run_debugger("$test_prog");
done_testing();
