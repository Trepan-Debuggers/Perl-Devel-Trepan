#!/usr/bin/env perl
use 5.010;
use strict; use warnings;
use English qw( -no_match_vars );
no warnings 'redefine'; no warnings 'once';
use rlib '../lib';

use Test::More;
note( "Testing Devel::CmdProcessor::Parse::BPLocation" );

use Devel::Trepan::CmdProcessor::Parse::BPLocation;

my @test = (
	[ 'List.pm:1', 'OK',
	  {
	      filename => "List.pm",
	      is_conditional =>  0,
	      line_num => 1
	  }],
	[ 'abc()', 'OK',
	  {
	      funcname => "abc()",
	      is_conditional => 0,
	  },
	],
	[ 'abs() if 1',   'OK',
	  {
	      funcname => "abs()",
	      is_conditional => 1,
	  }
	],
	[ 'List.pm:10 if y > 3', 'OK',
	  {
	      filename => "List.pm",
	      is_conditional => 1,
	      line_num => 10
	  }
	]
	);

for my $ix (0 .. $#test) {
    my ($input, $expected_result, $expected_value) = @{$test[$ix]};
    my $i = $ix + 1;
    say "\n** Test #$i: ", $input;

    my $value_ref;
    my $result = 'OK';

    # Parse input and build tree
    my $eval_ok = eval { $value_ref = parse_bp_location( \$input ); 1; };
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

    # say Data::Dumper::Dumper($value_ref);
    my %bp_location = %{bp_location_build($value_ref)};
    # use Data::Printer;
    # p $bp_location;
    my %expected_value = %$expected_value;
    if (%bp_location ne %expected_value) {
	Test::More::fail(qq{Test of "$input" value was "%bp_location"; expected "%expected_value"});
    } else {
	Test::More::pass(qq{Parsed Value of "$input" matches});
    }
}
done_testing();
