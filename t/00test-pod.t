#!/usr/bin/env perl
use strict; use warnings;
use Test::More;
use File::Spec;
use File::Basename;

eval "use Test::Pod 1.44";
plan skip_all => "Test::Pod 1.44 required for testing POD" if $@;

my $helpdir=File::Spec->catfile(dirname(__FILE__),
				'../lib/Devel/Trepan/CmdProcessor/Command/Help');
my $blib=File::Spec->catfile(dirname(__FILE__), '../blib');

my @poddirs = qw( ../blib );
all_pod_files_ok($blib, $helpdir);
