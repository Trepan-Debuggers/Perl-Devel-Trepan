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
    $opts->{namespace_package} = "package main;";
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

my %hash = ('foo' => 'bar', 'a' => 1);
$opts->{return_type} = '%';
DB::eval('%hash', $opts);
is($DB::eval_result{'foo'}, 'bar');
my @keys = keys(%DB::eval_result);
is(scalar @keys, 2);

sub test_code($$) 
{
    my ($code, $is_good) = @_;
    my $msg = DB::eval_not_ok($code);
    ok (!$msg == $is_good, "${code}" . ($msg ? ": $msg" : ''));
}

$DB::namespace_package = 'package main;';
test_code 'test_code(1,2)', 1;
test_code 'test_code(1)', 0;
test_code '$x+2', 1;
test_code "foo(", 0;
test_code '$foo =', 0;
test_code 'BEGIN  { $x = 1;', 0;
test_code 'package foo; 1', 1;


done_testing;
