#!/usr/bin/env perl
use warnings; use strict; use English;
use File::Basename; use File::Spec;
use Test::More;
use Config;

if (($OSNAME eq 'netbsd' or $OSNAME eq 'freebsd' or $OSNAME eq 'darwin')
    # and
    # $PERL_VERSION >= 5.014 and $Config{usemultiplicity} eq 'define'
    ) {
    plan skip_all => 
	"NetBSD and FreeBSD multi with PERL_PRESERVE_IVUV probably has a bug";
} else {
    plan 'no_plan';
}

use rlib '.';
use Helper;
my $test_prog = File::Spec->catfile(dirname(__FILE__), 
				    qw(.. example gcd.pl));
Helper::run_debugger("$test_prog 3 5", 'autolist.cmd');
