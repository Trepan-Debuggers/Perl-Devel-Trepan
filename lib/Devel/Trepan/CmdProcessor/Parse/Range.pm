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

range ::= location
        | location COMMA NUMBER
        | location COMMA OFFSET
        | location COMMA
        | COMMA location
        | direction

direction ::= DIRECTION

location    ::= FILE_LINE | FUNCNAME

# If just a number is given, the filename is implied
location    ::= NUMBER | offset
offset      ::= OFFSET

#======== tokens ===============

:discard ~ whitespace

# Note no space is allowed between FILENAME, COLON, and number
FILE_LINE ~ FILENAME COLON number
COLON ~ ':'
COMMA ~ ','
NUMBER ~ number
OFFSET ~ [+-] digits
number ~ digits
digits ~ [\d]+
DIRECTION ~ '+' | '-' | '.'
whitespace ~ [\s]+
FILENAME ~ [^:\s]+
FUNCNAME ~ name '()'
name ~ name_first_char name_later_chars
name_first_char ~ [A-Za-z_]
name_later_chars ~ name_later_char*
name_later_char ~ [\w]

END_OF_GRAMMAR

my $range_grammar = Marpa::R2::Scanless::G->new( { source => \$grammar_rules } );

package Devel::Trepan::CmdProcessor::Parse::Range;
use English qw( -no_match_vars );

use vars qw(@EXPORT @ISA);
@ISA = qw(Exporter);
@EXPORT = qw(range_build parse_range);


sub parse_range
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

sub location_build
{
    my $loc = shift;
    if (ref $loc eq 'ARRAY') {
	# FIXME: handle offset or number $start
	my @ary = @$loc;
	my $ary = ref2hash(@ary);
	return {$ary[0] => $ary[1]}
    } else {
	if (substr($loc, -2, 2) eq '()') {
	    return {'funcname' => $loc }
	} elsif ($loc =~ /(\S+):(\d+)$/) {
	    return {location => {
		filename => $1,
		line_num => $2,
		    }};
	} else {
	    return $loc;
	}
    }
}

sub position_build
{
    my $pos = shift;
    if (ref $pos eq 'ARRAY') {
	die unless $pos->[0] eq 'location';
	$pos = $pos->[1];
    }
    if (substr($pos, 0, 1) =~ /^[+-]$/) {
	return {offset => $pos}
    } else {
	return {line_num => $pos};
    }
}

sub range_build
{
    my @rhs = @_;
    my %result;
    my @first = shift @rhs;
    my $first_name;
    my $first_val;
    if (ref $first[0]) {
	$first_name = $first[0]->[0];
	$first_val = $first[0]->[1];
    } else {
	$first_name = $first[0];
    }

    if ($first_name eq 'location') {
	$result{'start'} = location_build $first_val;
	return %result unless @rhs;
	my $second = shift @rhs;
	if ($second eq ',') {
	    if (@rhs) {
		$second = shift @rhs;
		$result{end} = position_build $second;
	    }
	}
	return %result unless @rhs;
	# FIXME: Handle end value number or offset
	return %result;
    } elsif ($first_name eq ',') {
	my $end_val = shift @rhs;
	$result{end} = position_build $end_val;
	return %result;

    } elsif ($first_name eq 'direction') {
	$result{direction} = $first_val;
	return %result;
    }
}

## Demo/test ###
# unless (caller()) {
#     eval {use Test::More};
#     eval {use Data::Dumper};

#     my @test = (
# 	[ 'List.pm:1', 'OK', [ 'range', [ 'location',  'List.pm:1' ] ] ],
# 	[ 'abc()', 'OK', [ 'range', [ 'location',  'abc()' ] ] ],
# 	[ '+',   'OK', [ 'range', [ 'direction', '+' ] ] ],
# 	[ '-',   'OK', [ 'range', [ 'direction', '-' ] ] ],
# 	[ '+9', 'OK', [ 'range', [ 'location', [ 'offset', '+9' ] ] ] ],
# 	[ '-2', 'OK', [ 'range', [ 'location', [ 'offset', '-2' ] ] ] ],
# 	[ 'xyz:3,9', 'OK', [ 'range', [ 'location', 'xyz:3' ], ',', '9' ] ],
# 	[ ',42',     'OK', [ 'range', ',', [ 'location', '42' ] ] ],
# 	[ ', 42',     'OK', [ 'range', ',', [ 'location', '42' ] ] ],
# 	[ '42,', 'OK', [ 'range', [ 'location', '42' ], ',' ] ],
# 	);

#     for my $ix (0 .. $#test) {
# 	my ($input, $expected_result, $expected_value) = @{$test[$ix]};
# 	my $i = $ix + 1;
# 	say "\n** Test #$i: ", $input;

# 	my $value_ref;
# 	my $result = 'OK';

# 	# Parse input and build tree
# 	my $eval_ok = eval { $value_ref = parse_range( \$input ); 1; };
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

# 	my $value = '[fail]';
# 	my $dump_expected = '[fail]';
# 	if ($value_ref) {
# 	    $value         = Data::Dumper::Dumper($value_ref);
# 	    $dump_expected = Data::Dumper::Dumper(\$expected_value);
# 	}
# 	if ($value ne $dump_expected) {
# 	    Test::More::fail(qq{Test of "$input" value was "$value"; expected "$dump_expected"});
# 	} else {
# 	    Test::More::pass(qq{Parsed Value of "$input" matches});
# 	}
#     }
#     done_testing();
# }
1;
