#!/usr/bin/env perl
use strict; use warnings; no warnings 'redefine';
use rlib '../lib';
use vars qw($response); 

use Test::More;

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
#   'set,  shell,  show,  source,  step', "Completing 's'");
   'server,  set,  show,  source,  step', "Completing 's'");

is(join(',  ', $cmdproc->complete("help ser", 'help ser', 0, 1)),
   'server', "Completing 'help ser'");

is(join(', ', $cmdproc->complete("help una", 'help una', 0, 1)),
   'unalias', 'completing "una"');

done_testing();
