# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>

# Nukes output. Used for example in sourcing where you don't want
# to see output.
# 

# require_relative 'base_io'

use warnings;
use strict;
use Exporter;

package Devel::Trepan::IO::NullOutput;
use rlib '../../..';
use Devel::Trepan::Util qw(hash_merge);
use Devel::Trepan::IO;

use vars qw(@EXPORT @ISA);
@ISA = qw(Devel::Trepan::IO::OutputBase Exporter);

sub new($;$$) {
    my ($class, $out, $opts) = @_;
    $opts ||= {};
    my $self = {closed => 0};
    Devel::Trepan::IO::OutputBase->new($out, $opts);
    bless ($self, $class);
    return $self;
}

sub close($) {
    my($self) = @_;
    $self->{closed} = 1;
}

sub is_closed($) {
    my($self) = @_;
    $self->{closed};
}

sub flush($) {;}

# Use this to set where to write to. output can be a 
# file object or a string. This code raises IOError on error.
sub write($) {;}

# used to write to a debugger that is connected to this
# `str' written will have a newline added to it
#
sub writeline($$) { ; }

# Demo it
if( __FILE__ eq $0)  {
    my $output = Devel::Trepan::IO::NullOutput->new(*STDOUT);
    require Data::Dumper;
    import Data::Dumper;
    print Dumper($output);
    $output->write("Invisible");
    $output->writeline("Invisible");
}

1;
