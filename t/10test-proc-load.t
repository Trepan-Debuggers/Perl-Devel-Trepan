#!/usr/bin/env perl
use strict; use warnings; no warnings 'redefine';
use lib '../lib';
use vars qw($response); 

use Test::More 'no_plan';

BEGIN {
note( "Testing Devel::Trepan::CmdProcessor::Load" );
use_ok( 'Devel::Trepan::CmdProcessor::Load' );
}

require Devel::Trepan::CmdProcessor;
my $cmdproc = Devel::Trepan::CmdProcessor->new;
my @cmds = keys(%{$cmdproc->{commands}});
is(1, scalar @cmds > 3, "We should have more than 1 command");
my @aliases = sort %{$cmdproc->{aliases}};
is(1, scalar @aliases > 3, "We should have more than 1 alias");
is(join(',  ', $cmdproc->complete("s", 's', 0, 1)),
   'set,  shell,  show,  source,  step', "Completing 's'");

is(join(',  ', $cmdproc->complete("help se", 'help se', 0, 1)),
   'set', "Completing 'help se'");

is(join(', ', $cmdproc->complete("help una", 'help una', 0, 1)),
   'unalias', 'completing "una"')

