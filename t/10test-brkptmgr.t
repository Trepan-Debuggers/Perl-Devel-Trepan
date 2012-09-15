#!/usr/bin/env perl
use strict;
use rlib '../lib';

use Test::More;
use warnings; no warnings 'redefine';
note( "Testing Devel::Trepan::BrkptMgr" );

use Devel::Trepan::DB::Breakpoint;
use Devel::Trepan::Core;
my $dbgr = Devel::Trepan::Core->new;
my $brkpts = Devel::Trepan::BrkptMgr->new($dbgr);
ok($brkpts, 'Breakpoint manager creation');
my $brkpt1 = DBBreak->new(
    type=>'brkpt', condition=>'1', id=>1, hits => 0, enabled => 1,
    negate => 0, filename => __FILE__, line_num => __LINE__
    );

ok($brkpts->add($brkpt1), 'Add a breakpoint');
is($brkpts->find(1), $brkpt1, 'Should find breakpoint 1');
is($brkpts->find(2), undef, 'Should not find breakpoint 2');
is($brkpts->find('a'), undef, 'Should tolerate bad find value: a');


done_testing;
