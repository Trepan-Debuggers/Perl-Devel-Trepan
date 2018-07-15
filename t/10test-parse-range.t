#!/usr/bin/env perl
use 5.010;
use strict; use warnings;
use English qw( -no_match_vars );
no warnings 'redefine'; no warnings 'once';
use rlib '../lib';

use Test::More;
note( "Testing Devel::CmdProcessor::Parse::Range" );

use Devel::Trepan::CmdProcessor::Parse::Range;

my @test = (
    [ 'List.pm:1', 'OK',
      [ 'range', [ 'location',  'List.pm:1' ] ] ],
    [ '+',   'OK',
      [ 'range', [ 'direction', '+' ] ] ],
    [ '-',   'OK', [ 'range', [ 'direction', '-' ] ] ],
    [ '+9', 'OK',
      [ 'range', [ 'location', [ 'offset', '+9' ] ] ] ],
    [ '-2', 'OK',
      [ 'range', [ 'location', [ 'offset', '-2' ] ] ] ],
    [ 'xyz:3,9', 'OK',
      [ 'range', [ 'location', 'xyz:3' ], ',', '9' ] ],
    [ ',42',     'OK',
      [ 'range', ',', [ 'location', '42' ] ] ],
    [ ', 42',     'OK',
      [ 'range', ',', [ 'location', '42' ] ] ],
    [ '42,', 'OK',
      [ 'range', [ 'location', '42' ], ',' ] ],
    );

for my $ix (0 .. $#test) {
    my ($input, $expected_result, $expected_value) = @{$test[$ix]};
    my $i = $ix + 1;
    say "\n** Test #$i: ", $input;

    my $value_ref;
    my $result = 'OK';

    # Parse input and build tree
    my $eval_ok = eval { $value_ref = parse_range( \$input ); 1; };
    if ( !$eval_ok ) {
	my $eval_error = $EVAL_ERROR;
      PARSE_EVAL_ERROR: {
	  $result = "Error: $EVAL_ERROR";
	  Test::More::diag($result);
	}
	$result = "no parse";
    }
    if ($result ne $expected_result) {
	Test::More::fail(qq{Parse of "$input" "$result"; expected "$expected_result"});
    } else {
	Test::More::pass(qq{Parse of "$input" okay});
    }
    my $value = '[fail]';
    my $dump_expected = '[fail]';
    my %range;
    if ($value_ref) {
	$value         = Data::Dumper::Dumper($value_ref);
	$dump_expected = Data::Dumper::Dumper(\$expected_value);
	my @ary = @$$value_ref;
	my $start_symbol = shift @ary;
	is($start_symbol, 'range');
	%range = range_build(@ary);
	# use Data::Printer; p %range;
    }
    if ($value ne $dump_expected) {
	Test::More::fail(qq{Test of "$input" value was "$value"; expected "$dump_expected"});
    } else {
	Test::More::pass(qq{Value of "$input" matches});
    }
}
done_testing();
