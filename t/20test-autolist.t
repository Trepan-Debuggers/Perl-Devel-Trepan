#!/usr/bin/env perl
use warnings; use strict; use English qw( -no_match_vars );
use Test::More;
use Config;

if (($OSNAME eq 'netbsd' or $OSNAME eq 'freebsd' or $OSNAME eq 'darwin')
    # and
    # $PERL_VERSION >= 5.014 and $Config{usemultiplicity} eq 'define'
    ) {
    plan skip_all => 
	"NetBSD and FreeBSD multi with PERL_PRESERVE_IVUV probably has a bug";
}

use rlib '.'; use Helper;
my $test_prog = prog_file('gcd.pl');
run_debugger("$test_prog 3 5");
done_testing();
