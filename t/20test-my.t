#!/usr/bin/env perl
use warnings; use strict;
use Test::More;
use rlib '.';
use Helper;
my $test_prog = File::Spec->catfile(dirname(__FILE__), 
				    qw(.. example my.pl));
use vars qw($HAVE_EVAL_WITH_LEXICALS);                                          
BEGIN {                                                                         
    $HAVE_EVAL_WITH_LEXICALS = eval("use Eval::WithLexicals; 1") ? 1 : 0;     
}  
if ($HAVE_EVAL_WITH_LEXICALS) {
    plan 'no_plan';
    Helper::run_debugger("$test_prog", 'my.cmd');
} else {
    plan skip_all => "Need Eval::WithLexicals"
}
