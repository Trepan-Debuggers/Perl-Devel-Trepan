#!/usr/bin/env perl
use strict; use warnings;
no warnings 'redefine'; no warnings 'once';
use rlib '../lib';

use Test::More;
note( "Testing Devel::CmdProcessor::Command::Subcmd" );

BEGIN {
    use_ok( 'Devel::Trepan::CmdProcessor::Command::Subcmd::Core' );
}

require Devel::Trepan::CmdProcessor;
require Devel::Trepan::CmdProcessor::Command::Set;

my @msgs = ();
my $cmdproc = Devel::Trepan::CmdProcessor->new(undef, 'bogus');
# Check that each command has required fields and constants initialized
my @cmds = ();
push @cmds, Devel::Trepan::CmdProcessor::Command::Set->new($cmdproc, 'set');
push @cmds, Devel::Trepan::CmdProcessor::Command::Show->new($cmdproc, 'show');
push @cmds, Devel::Trepan::CmdProcessor::Command::Load->new($cmdproc, 'load');
foreach my $cmd (@cmds) {
    foreach my $subcmd_name (keys %{$cmd->{subcmds}}) {
	my $subcmd = $cmd->{subcmds}{$subcmd_name};
	for my $field (qw(name prefix min_abbrev short_help)) {
	    ok($subcmd->{$field},
	       "Field $field of subcommand $subcmd_name of $cmd->{name}");
	}
    }
}
done_testing();
