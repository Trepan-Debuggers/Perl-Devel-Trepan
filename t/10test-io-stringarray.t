#!/usr/bin/env perl
use strict;
use warnings;
use rlib '../lib';

use Test::More;
note( "Testing Devel::Trepan::IO::StringArray" );

BEGIN {
use_ok( 'Devel::Trepan::IO::StringArray' );
}

note "Testing StringArrayOutput";
my $out = Devel::Trepan::IO::StringArrayOutput->new;
$out->writeline("Some output");
$out->writeline('Hello, World!');
is $out->{output}[0], 'Some output';
is $out->{output}[1], '';
is $out->{output}[2], 'Hello, World!';
is $out->{output}[3], '';
done_testing();
