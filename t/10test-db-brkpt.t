#!/usr/bin/env perl
use strict;
use warnings;
use rlib '../lib';

use Test::More;
note( "Testing Devel::Trepan::DB::Breakpoint" );

BEGIN {
    use English qw( -no_match_vars );
    $PERLDB |= 0x400;
    use_ok( 'Devel::Trepan::DB::Breakpoint' );
}

sub new() {
    my $class = shift;
    my $self = {};
    bless $self, $class;
}

my @warnings = ();
sub warning($) 
{
    my ($self, $msg) = @_;
    push @warnings, $msg;
}


my @output = ();
sub output($) 
{
    my ($self, $msg) = @_;
    push @output, $msg;
}


use vars qw(@ISA);
@ISA = qw(DB);

our $self = __PACKAGE__->new;
package main;
$DB::filename = __FILE__;
no warnings 'once';
$DB::dbline = [] unless defined($DB::line); 
$DB::dbline[__LINE__+1] = 1;
my $brkpt = DB::set_break($self, __FILE__, __LINE__, '1', undef, 'brkpt');
ok ($brkpt);
ok ($brkpt);
is($brkpt->type, 'brkpt');

$DB::filename = __FILE__;
my $msg = DB::break_invalid(undef, __FILE__, __LINE__ - 1);
ok($msg);

done_testing;
