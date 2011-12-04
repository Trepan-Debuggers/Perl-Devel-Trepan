# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use rlib '../../../..';

# Our local modules
## use Devel::Trepan::Options; or is it default

package Devel::Trepan::CmdProcessor::Command::Disassemble;
use Getopt::Long qw(GetOptionsFromArray);
use B::Concise qw(set_style);

use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;

unless (defined @ISA) {
    eval <<"EOE";
use constant CATEGORY   => 'data';
use constant SHORT_HELP => 'Disassemble subroutine(s)';
use constant MIN_ARGS  => 0;  # Need at least this many
use constant MAX_ARGS  => undef;  # Need at most this many - undef -> unlimited.
use constant NEED_STACK => 0;
EOE
}

use strict;

use vars qw(@ISA); @ISA = qw(Devel::Trepan::CmdProcessor::Command);
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} [options] [SUBROUTINE ...]

options: 
    -concise
    -terse 
    -linenoise
    -debug
    -compact
    -exec
    -tree
    -loose
    -vt
    -ascii

Use B::Concise to disassemble a subroutine. SUBROUTINE is not specified,
use the subroutine where the program is currently stopped.
HELP

use constant DEFAULT_OPTIONS => {
    line_style => 'debug',
    order      => '-basic',
    tree_style => '-ascii',
};

sub complete($$) 
{
    no warnings 'once';
    my ($self, $prefix) = @_;
    my @subs = keys %DB::sub;
    my @opts = (qw(-concise -terse -linenoise -debug -basic -exec -tree -compact -loose -vt -ascii),
		@subs);
    Devel::Trepan::Complete::complete_token(\@opts, $prefix) ;
}
    
sub parse_options($$)
{
    my ($self, $args) = @_;
    my $opts = DEFAULT_OPTIONS;
    my $result = &GetOptionsFromArray($args,
          '-concise'    => sub { $opts->{line_style} = 'concise'},
          '-terse'      => sub { $opts->{line_style} = 'terse'},
          '-linenoise'  => sub { $opts->{line_style} = 'linenoise'},
          '-debug'      => sub { $opts->{line_style} = 'debug'},
	  # FIXME: would need to check that ENV vars B_CONCISE_FORMAT, B_CONCISE_TREE_FORMAT
	  # and B_CONCISE_GOTO_FORMAT are set
          # '-env'        => sub { $opts->{line_style} = 'env'},

          '-basic'      => sub { $opts->{order} = '-basic'; },
          '-exec'       => sub { $opts->{order} = '-exec'; },
          '-tree'       => sub { $opts->{order} = '-tree'; },

          '-compact'    => sub { $opts->{tree_style} = '-compact'; },
          '-loose'      => sub { $opts->{tree_style} = '-loose'; },
          '-vt'         => sub { $opts->{tree_style} = '-vt'; },
          '-ascii'      => sub { $opts->{tree_style} = '-ascii'; },
	);
    $opts;
}

sub run($$)
{
    my ($self, $args) = @_;
    my @args = @$args;
    shift @args;
    my $options = parse_options($self, \@args);
    my $proc = $self->{proc};
    unless (scalar(@args)) {
	if ($proc->funcname && $proc->funcname ne 'DB::DB') {
	    push @args, $proc->funcname;
	} else {
	    $proc->msg("No function currently recorded");
	}
    }

    for my $method_name (@args) {
	if ($proc->is_method($method_name)) {
	    $proc->section("Subroutine $method_name");
	    my $walker = B::Concise::compile($options->{order}, $method_name);
	    B::Concise::set_style_standard($options->{line_style});
	    B::Concise::walk_output(\my $buf);
	    $walker->();			# walks and renders into $buf;
	    ## FIXME: syntax highlight the output.
	    $proc->msg($buf);
	} else {
	    $proc->errmsg("Can't find subroutine $method_name");
	}
    }
}

  
# Demo it
unless (caller) {
}

1;
