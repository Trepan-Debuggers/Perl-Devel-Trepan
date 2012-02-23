#!/usr/bin/env perl
use strict; use warnings;
use vars qw($version $program);
sub init();
init();
my $y=3;
sub init() {
  use File::Basename;
  $program = basename($0); # Who am I today, anyway?
  $version='1.0';
}
