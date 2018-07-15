#!/usr/bin/perl
# A Marpa2 parser for gdb list range hs
# Many thanks to Jeffrey Kegler

use 5.010;
use strict;
use warnings;
use Marpa::R2 4.000;

use Exporter;

my $grammar_rules = <<'END_OF_GRAMMAR';

# Use longest acceptable token match
lexeme default = latm => 1
:default ::= action => [name,values]

# ======== productions ===========

location_if ::= location 'if' tokens
              | location
location    ::= FILE_LINE | FUNCNAME

# If location is just a number is given, the filename is implied
location    ::= NUMBER
FILE_LINE   ::= FILENAME ':' NUMBER

# "tokens" is used to gobble up stuff after the "if"
tokens      ::= token+
token       ::= ':' | FILENAME | FUNCNAME | NUMBER | SYMBOL

# ======== tokens ===========
:discard ~ whitespace

# Note no space is allowed between FILENAME, COLON, and number
NUMBER ~ number
number ~ digits
digits ~ [\d]+
whitespace ~ [\s]+
FILENAME ~ [^:\s]+
FUNCNAME ~ name '()'
name ~ name_first_char name_later_chars
name_first_char ~ [A-Za-z_]
name_later_chars ~ name_later_char*
name_later_char ~ [\w]
SYMBOL ~ [^:\d]

END_OF_GRAMMAR

my $range_grammar = Marpa::R2::Scanless::G->new(
    { source => \$grammar_rules } );

package Devel::Trepan::CmdProcessor::Parse::BPLocation;
use English qw( -no_match_vars );

use vars qw(@EXPORT @ISA);
@ISA = qw(Exporter);
@EXPORT = qw(bp_location_build parse_bp_location);
sub parse_bp_location
{
    my ( $input ) = @_;
    my $recce = Marpa::R2::Scanless::R->new( { grammar => $range_grammar } );
    my $input_length = length ${$input};
    my $pos = $recce->read($input);
    if ( $pos < $input_length ) {
	die sprintf qq{Unfinished parse: remainder="%" }, substr(${$input}, $pos);
    }
    my $value_ref = $recce->value();
    if ( !$value_ref ) {
	die "input read, but there was no parse";
    }
    return $value_ref;
}

#===== info-building routines ================
sub ref2hash
{
    my %h = @_;
    return \%h;
}

sub bp_location_build
{
    my $loc = shift;
    my $result = {};
    if (ref $$loc eq 'ARRAY') {
	my @ary = @$$loc;

	if ($ary[0] eq 'location_if') {
	    $result = location_build($ary[1]);
	    if (@ary > 2 && $ary[2] eq 'if') {
		$result->{is_conditional} = 1;
	    } else {
		$result->{is_conditional} = 0;
	    }
	}
    }
    return $result;
}

sub location_build
{
    my $loc = shift;
    if (ref $loc eq 'ARRAY') {
	# FIXME: handle offset or number $start
	my @loc_ary = @$loc;
	my $kind = $loc_ary[0];
	if ($kind eq 'location') {
	    my $func_or_ary = $loc_ary[1];
	    if (ref $func_or_ary) {
		$kind = $func_or_ary->[0];
		if ($kind eq 'FILE_LINE') {
		    return {
			filename => $func_or_ary->[1],
			line_num => $func_or_ary->[3]
		    }
		}
	    } else {
		return {
		    funcname => $func_or_ary
		}
	    }
	}
    }
}

# # Demo/test
# unless (caller()) {
#     eval {use Test::More};
#     eval {use Data::Dumper};

#     my @test = (
# 	[ 'List.pm:1', 'OK',
# 	  {
# 	      filename => "List.pm",
# 	      is_conditional =>  0,
# 	      line_num => 1
# 	  }],
# 	[ 'abc()', 'OK',
# 	  {
# 	      funcname => "abc()",
# 	      is_conditional => 0,
# 	  },
# 	],
# 	[ 'abs() if 1',   'OK',
# 	  {
# 	      funcname => "abs()",
# 	      is_conditional => 1,
# 	  }
# 	],
# 	[ 'List.pm:10 if y > 3', 'OK',
# 	  {
# 	      filename => "List.pm",
# 	      is_conditional => 1,
# 	      line_num => 10
# 	  }
# 	]
# 	);

#     for my $ix (0 .. $#test) {
# 	my ($input, $expected_result, $expected_value) = @{$test[$ix]};
# 	my $i = $ix + 1;
# 	say "\n** Test #$i: ", $input;

# 	my $value_ref;
# 	my $result = 'OK';

# 	# Parse input and build tree
# 	my $eval_ok = eval { $value_ref = parse_bp_location( \$input ); 1; };
# 	if ( !$eval_ok ) {
# 	    my $eval_error = $EVAL_ERROR;
# 	  PARSE_EVAL_ERROR: {
# 	      $result = "Error: $EVAL_ERROR";
# 	      Test::More::diag($result);
# 	    }
# 	    $result = "no parse";
# 	}
# 	if ($result ne $expected_result) {
# 	    Test::More::fail(qq{Parse of "$input" "$result"; expected "$expected_result"});
# 	} else {
# 	    Test::More::pass(qq{Parse of "$input" okay});
# 	}

# 	# say Data::Dumper::Dumper($value_ref);
# 	my %bp_location = %{bp_location_build($value_ref)};
# 	# use Data::Printer;
# 	# p $bp_location;
# 	my %expected_value = %$expected_value;
# 	if (%bp_location ne %expected_value) {
# 	    Test::More::fail(qq{Test of "$input" value was "%bp_location"; expected "%expected_value"});
# 	} else {
# 	    Test::More::pass(qq{Parsed Value of "$input" matches});
# 	}
#     }
#     done_testing();
# }
1;
