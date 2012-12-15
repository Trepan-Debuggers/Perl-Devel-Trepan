# -*- coding: utf-8 -*-
# This line is for testing purposes \
# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>

# Module for reading debugger scripts

use warnings; no warnings 'redefine';
use Exporter;
use IO::File;

use rlib '../../..';

package Devel::Trepan::Interface::Script;
our (@ISA);
use if !@ISA, Devel::Trepan::Interface;
use if !@ISA, Devel::Trepan::Interface::ComCodes;
use Devel::Trepan::IO::Input;
use Devel::Trepan::IO::StringArray;
use Devel::Trepan::Util qw(hash_merge);
use strict; 
use vars qw(@EXPORT @ISA);
@ISA = qw(Devel::Trepan::Interface Exporter);

use constant DEFAULT_OPTS => {
    abort_on_error => 1,
    confirm_val    => 0,
    verbose        => 0
};
  
sub new
{
    my ($class, $script_name, $out, $opts) = @_;
    $opts = {} unless defined $opts;

    $opts = hash_merge($opts, DEFAULT_OPTS);

    my $self = {};
    #  FIXME if $script_name is invalid, we get undef $fh and then
    # Interface->new uses STDIN. 
    my $fh = IO::File->new($script_name, 'r');
    $self = Devel::Trepan::Interface->new($fh, $out, $opts);
    $self->{script_name}   = $script_name;
    $self->{input_lineno}  = 0;
    $self->{buffer_output} = [];
    unless ($opts->{verbose} or $out) {
        $self->{output} = Devel::Trepan::IO::StringArrayOutput->new($self->{buffer_output});
    }    
    bless $self, $class;
    $self;
}


# Closes input only.
sub close($)
{
    my $self = shift;
    $self->{input}->close;
}

# Called when a dangerous action is about to be done, to make
# sure it's okay.
#
# Could look also look for interactive input and
# use that. For now, though we'll simplify.
sub confirm($$$)
{
    my ($self, $prompt, $default) = @_;
    $self->{opts}{default_confirm};
}

# Common routine for reporting debugger error messages.
# 
sub errmsg($$;$)
{
    my ($self, $msg, $prefix) = @_;
    $prefix = '*** ' unless defined $prefix;
    #  self.verbose shows lines so we don't have to duplicate info
    #  here. Perhaps there should be a 'terse' mode to never show
    #  position info.
    my $mess = sprintf "%s%s", $prefix, $msg;

    if ($self->{opts}{verbose}) {
        my $location = sprintf("%s:%s: Error in source command file",
                               $self->{script_name}, 
                               $self->{input_lineno});
        $mess = sprintf("%s:\n%s%s", $prefix, $location, $prefix, $msg);
    }
    
    $self->msg($mess);
    # FIXME: should we just set a flag and report eof? to be more
    # consistent with File and IO?
    die if $self->{opts}{abort_on_error};
}

sub msg($$)
{
    my ($self, $msg) = @_;
    ## FIXME: there must be a better way to do this...
    if ($self->{output}->isa('Devel::Trepan::IO::TCPServer')) {
        $self->{output}->writeline(PRINT . $msg);
    } else {
        $self->{output}->writeline($msg);
    }
}

sub is_interactive() { 0; }

sub is_closed($) 
{
    my($self)  = shift;
    $self->{input}->eof;
}

sub has_completion() { 0; }
sub has_term_readline($) { 0; }

# Script interface to read a command. `prompt' is a parameter for 
# compatibilty and is ignored.
sub read_command($;$)
{
    my ($self, $prompt)=@_;
    $prompt = '' unless defined $prompt;
    $self->{input_lineno} += 1;
    my $last = $self->readline();
    my $line = '';
    while ('\\' eq substr($last, -1)) { 
        $line .= substr($last, 0, -1) . "\n";
        $last = $self->readline();
    }
    $line .= $last;

    if ($self->{opts}{verbose}) {
        my $location = sprintf("%s line %s",
                               $self->{script_name}, 
                               $self->{input_lineno});
        my $mess = sprintf '+ %s: %s', $location, $line;
        $self->msg($mess);
    }
    # Do something with history?
    return $line;
}

# Script interface to read a line. `prompt' is a parameter for 
# compatibilty and is ignored.
#
# Could decide make this look for interactive input?
sub readline($;$)
{
    my ($self, $prompt) = @_;
    $prompt = '' unless defined $prompt;
    my $line = $self->{input}->getline;
    chomp $line;
    return $line;
}

sub remove_history($;$)
{
}

# sub DESTROY($) 
# {
#     my $self = shift;
#     Devel::Trepan::Interface::DESTROY($self);
# }

# Demo
unless (caller) {
    my $intf = __PACKAGE__->new(__FILE__);
    my $line = $intf->readline();
    print "Line read: ${line}\n";
    $line = $intf->read_command();
    print "Second Line read: ${line}\n";
}

1;
