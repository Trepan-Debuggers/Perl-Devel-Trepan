#!/usr/bin/env perl
use strict;
use warnings;
use lib '../lib';

use Test::More 'no_plan';
note( "Testing Devel::Trepan::DB::LineCache" );

BEGIN {
    use English;
    $PERLDB |= 0x400;
    use_ok( 'Devel::Trepan::DB::LineCache' );
}

note 'Test getlines';

my $file=__FILE__;
# my $line_count = scalar(@{"main::_<$file"});
my $lines = DB::LineCache::getlines(__FILE__);
my $line_count = scalar @$lines;
ok($line_count > __LINE__, "Compare getlines count to __LINE__");

## FIXME: doesn't work:
## use Cwd 'abs_path';
## my $full_file = abs_path(__FILE__);
## $lines = DB::LineCache::getlines($full_file);
## is(scalar @$lines, $line_count, "Compare linecount for full name $full_file");

my $expected_line = 'my $line = DB::LineCache::getline(__FILE__, __LINE__);';
my $line_number = __LINE__+1;
my $line = DB::LineCache::getline(__FILE__, __LINE__);
is($line, $expected_line, "Test getline");
DB::LineCache::remap_file('another_name', __FILE__);
my $another_line = DB::LineCache::getline('another_name', $line_number);
is($another_line, $expected_line, "Test getline via remap_file");

# printf "Files cached: %s\n", join(', ', DB::LineCache::cached_files);
# DB::LineCache::update_cache(__FILE__);
## DB::LineCache::checkcache(__FILE__);
# printf "I said %s has %d lines!\n", __FILE__, DB::LineCache::size(__FILE__);

my $sha1 = DB::LineCache::sha1(__FILE__);
ok($sha1, "Got some sort of SHA1");

