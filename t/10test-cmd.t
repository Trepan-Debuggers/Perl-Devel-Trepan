#!/usr/bin/env perl
use strict; use warnings;
no warnings 'redefine'; no warnings 'once';
use rlib '../lib';

use Test::More;
note( "Testing Devel::CmdProcessor::Command" );

BEGIN {
    use_ok( 'Devel::Trepan::CmdProcessor::Command' );
}

require Devel::Trepan::CmdProcessor;

my @msgs = ();
my $cmdproc = Devel::Trepan::CmdProcessor->new;
# Check that each command has required fields and constants initialized
foreach my $key (keys %{$cmdproc->{commands}}) {
    my $cmd = $cmdproc->{commands}{$key};
    foreach my $field (qw(name short_help)) {
	ok($cmd->{$field}, "command $key should have field ${field}");
    }
    foreach my $field (qw(Category)) {
	ok($cmd->$field, "command $key should have constant ${field}");
    }
}

done_testing();
