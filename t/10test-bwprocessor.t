#!/usr/bin/env perl
use strict; use warnings;
use English qw( -no_match_vars );
use rlib '../lib';
use Devel::Trepan::BWProcessor;
use Config;

use Test::More;
plan;

ok(!Devel::Trepan::BWProcessor::valid_cmd_hash(1));
ok(!Devel::Trepan::BWProcessor::valid_cmd_hash({}));
ok(Devel::Trepan::BWProcessor::valid_cmd_hash({command => 'info_program'}));
done_testing;
