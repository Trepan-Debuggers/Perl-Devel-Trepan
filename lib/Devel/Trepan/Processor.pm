# -*- coding: utf-8 -*-
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>

use rlib '../..';

# A debugger command processor. This includes the debugger commands
# and ties together the debugger core and I/O interface.
package Devel::Trepan::Processor;

use vars qw(@EXPORT @ISA);
@EXPORT    = qw( adjust_frame running_initialize);
@ISA       = qw( Exporter );

use English qw( -no_match_vars );
use Exporter;
use warnings; no warnings 'redefine';

eval "require Devel::Trepan::DB::Display";
use Devel::Trepan::Processor::Frame;
use Devel::Trepan::Processor::Running;
use strict;

# attr_reader :settings
sub new($$;$) {
    my ($class, $interfaces, $settings) = @_;
    $settings ||= {};
    my $self = {
        class      => $class,
        interfaces => $interfaces,
        settings   => $settings,
	gave_stack_trunc_warning => 0,
    };
    bless ($self, $class);
    return $self;
}

unless (caller) {
    require Devel::Trepan::Interface::User;
    my $intf = Devel::Trepan::Interface::User->new;
    my $proc  = __PACKAGE__->new([$intf]);
    print $proc->{class}, "\n";
    require Data::Dumper;
    print Data::Dumper::Dumper($proc->{interfaces});;
}


1;
