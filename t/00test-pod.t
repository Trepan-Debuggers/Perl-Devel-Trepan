#!/usr/bin/env perl
use Test::More;
eval "use Test::Pod 1.44";
plan skip_all => "Test::Pod 1.44 required for testing POD" if $@;
all_pod_files_ok();
