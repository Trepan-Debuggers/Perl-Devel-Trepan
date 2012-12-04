# -*- coding: utf-8 -*-
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org> 
use Exporter;
use warnings;
no warnings 'redefine';

use Carp ();
use File::Basename;

use rlib '../../..';
use if !defined Devel::Trepan::BWProcessor, Devel::Trepan::BWProcessor;
use strict;
package Devel::Trepan::BWProcessor::Command;

use vars qw(@CMD_VARS @EXPORT @ISA @CMD_ISA @ALIASES $HELP);
BEGIN {
    @CMD_VARS = qw($NAME $NEED_RUNNING $NEED_STACK @CMD_VARS);
}
use vars @CMD_VARS;
@ISA = qw(Exporter);

@CMD_ISA  = qw(Devel::Trepan::BWProcessor::Command);
@EXPORT = qw(&set_name @CMD_ISA $NEED_RUNNING 
             $NEED_STACK @CMD_VARS declared);


use constant NEED_STACK => 0; # We'll say that commands which need a stack
                              # to run have to declare that and those that
                              # don't don't have to mention it.

sub set_name() {
    my ($pkg, $file, $line) = caller;
    lc(File::Basename::basename($file, '.pm'));
}

# Command Command Object creation routine. This sets some class variables to defaults.
# For example whether a command needs the debugged program to be running or not.
# For "status": no. For "step": yes.
sub new($$) {
    my($class, $proc)  = @_;
    my $self = {
        proc     => $proc,
        class    => $class,
        dbgr     => $proc->{dbgr}
    };
    my $base_prefix="Devel::Trepan::BWProcessor::Command::";
    for my $field (@CMD_VARS) {
        my $sigil = substr($field, 0, 1);
        my $new_field = index('$@', $sigil) >= 0 ? substr($field, 1) : $field;
        if ($sigil eq '$') {
            $self->{lc $new_field} = 
                eval "\$${class}::${new_field} || \$${base_prefix}${new_field}";
        } elsif ($sigil eq '@') {
            $self->{lc $new_field} = eval "[\@${class}::${new_field}]";
        } else {
            die "Woah - bad sigil: $sigil";
        }
    }
    no strict 'refs';
    *{"${class}::name"} = eval "sub { \$${class}::NAME }";
    bless $self, $class;
    $self;
}

# FIXME: probably there is a way to do the delegation to proc methods
# without having type it all out.

sub confirm($$$) {
    my ($self, $message, $default) = @_;
    $self->{proc}->confirm($message, $default);
}

sub errmsg($$;$) {
    my ($self, $message, $opts) = @_;
    $opts ||= {};
    # FIXME
    # $self->{proc}->errmsg([$message], $opts);
    print STDERR "*** $message\n";
}

# sub obj_const($$$) {
#     my ($self, $obj, $name) = @_;
#     $obj->class.const_get($name) 
# }

# Convenience short-hand for $self->{proc}->msg
sub msg($$;$) {
    my ($self, $message, $opts) = @_;
    $opts ||= {};
    $self->{proc}->msg($message, $opts);
}

# Convenience short-hand for $self->{proc}->msg_nocr
sub msg_nocr($$;$) {
    my ($self, $message, $opts) = @_;
    $opts ||= {};
    $self->{proc}->msg_nocr($message, $opts);
}

# The method that implements the debugger command.
sub run {
    Carp::croak "RuntimeError: You need to define this method elsewhere";
}

sub section($$;$) {
    my ($self, $message, $opts) = @_;
    $opts ||={};
    $self->{proc}->section($message, $opts);
}

sub settings($) {
    my ($self) = @_;
    $self->{proc}{settings};
}

# Demo code
unless (caller) {
    require Devel::Trepan::BWProcessor;
    my $proc = Devel::Trepan::BWProcessor->new();
    my $cmd = Devel::Trepan::BWProcessor::Command->new($proc);
}

1;
