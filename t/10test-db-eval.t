#!/usr/bin/env perl
use strict; use warnings;
use Test::More;
use rlib '../lib/Devel/Trepan';
use DB::Eval;

package DB;
use vars qw(@saved);

sub save() {
  @saved = ( $EVAL_ERROR, $ERRNO, $EXTENDED_OS_ERROR, 
             $OUTPUT_FIELD_SEPARATOR, 
	     $INPUT_RECORD_SEPARATOR, 
	     $OUTPUT_RECORD_SEPARATOR, $WARNING );

  $OUTPUT_FIELD_SEPARATOR  = ""; 
  $INPUT_RECORD_SEPARATOR  = "\n";
  $OUTPUT_RECORD_SEPARATOR = "";  
  $WARNING = 0;       # warnings off
}

sub _warnall($) {
    print shift, "\n";
}


sub eval($$) {
    my ($eval_str, $opts) = @_;
    $opts->{user_context} = "package main;";
    save();
    &DB::eval_with_return($eval_str, $opts, @saved);
}

package main;

my $a = 'hi';
my $opts = {return_type => '$'};
DB::eval('$a', $opts);
is($DB::eval_result, 'hi');

my @ary = (1..5);
$opts->{return_type} = '@';
DB::eval('@ary', $opts);
is(scalar @DB::eval_result, 5);

done_testing;
