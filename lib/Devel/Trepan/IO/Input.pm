# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>

# Debugger user/command-oriented input possibly attached to IO-style
# input or GNU Readline.
# 

use warnings; use strict;
use Exporter;
use Term::ReadLine;

package Devel::Trepan::IO::Input;

use lib '../../..';
use Devel::Trepan::Util qw(hash_merge);
use Devel::Trepan::IO;

use vars qw(@EXPORT @ISA $HAVE_GNU_READLINE);
@ISA = qw(Devel::Trepan::IO::InputBase Exporter);
@EXPORT = qw($HAVE_GNU_READLINE);

BEGIN {
    $ENV{'PERL_RL'} ||= 'Gnu';
    my $term = Term::ReadLine->new('testing');
    if ($term->ReadLine eq 'Term::ReadLine::Gnu') {
      $HAVE_GNU_READLINE=1;
    } else {
      $HAVE_GNU_READLINE=0;
    }
    # Don't know how to close $term
    $term = undef;
}

my $readline_finalized = 0;
sub new($;$$) {
    my ($class, $inp, $opts) = @_;
    $inp ||= *STDIN;
    my $self = Devel::Trepan::IO::InputBase->new($inp, $opts);
    if ($opts->{readline} && $HAVE_GNU_READLINE) {
	$self->{readline} = Term::ReadLine->new('trepanpl');
	$self->{gnu_readline} = 1;
    } else {
	$self->{readline} = undef;
	$self->{gnu_readline} = 0;
    }
    bless ($self, $class);
    return $self;
}

sub have_gnu_readline($) 
{
    my $self = shift;
    $self->{gnu_readline};
}

sub is_interactive($)  {
    my $self = shift;
    return -t $self->{input};
}

# Read a line of input. EOFError will be raised on EOF.  
# Prompt is ignored if we don't have GNU readline. In that
# case, it should have been handled prior to this call.
sub readline($;$) {
    my ($self, $prompt) = @_;
    my $line;
    if (defined $self->{readline}) {
	$line = $self->{readline}->readline($prompt);
    } else {
	$self->{eof} = eof($self->{input});
	return '' if $self->{eof};
	$line = CORE::readline $self->{input};
    }
    return $line;
}
    
#     class << self
#       # Use this to set where to read from. 
#       #
#       # Set opts[:line_edit] if you want this input to interact with
#       # GNU-like readline library. By default, we will assume to try
#       # using readline. 
#       def open(inp=nil, opts={})
#         inp ||= STDIN
#         inp = File.new(inp, 'r') if inp.is_a?(String)
#         opts[:line_edit] = @line_edit = 
#           inp.respond_to?(:isatty) && inp.isatty && Trepan::GNU_readline?
#         self.new(inp, opts)
#       end

# # finalize
# END {
#     if (defined(RbReadline) && !@@readline_finalized) {
# 	begin 
#             RbReadline.rl_cleanup_after_signal();
# 	rescue
# 	end
#         begin 
# 	  RbReadline.rl_deprep_terminal();
# 	rescue
#         end
#         @@readline_finalized = 1;
#     }

#   end
# end

# package Trepan
# def Trepan::GNU_readline?
#   @have_readline ||= nil
#   begin
#     return @have_readline unless @have_readline.nil?
#     @have_readline = require 'readline'
#     at_exit { Trepan::UserInput::finalize }
#     return true
#   rescue LoadError
#     return false
#   end
# end
    
# Demo
unless (caller) {
    my $in = __PACKAGE__->new(*main::STDIN, {line_edit => 1});
    require Data::Dumper; import Data::Dumper; 
    print Dumper($in), "\n";
    printf "Is interactive: %s\n", ($in->is_interactive ? "yes" : "no");
    printf "Have GNU Readline: %s\n", ($HAVE_GNU_READLINE ? "yes" : "no");
    if (scalar(@ARGV) > 0) {
	print "Enter some text: ";
	my $line = $in->readline;
	if ($in->is_eof) {
	    print "EOF seen\n";
	} else {
	    print "You entered ${line}";
	}
    }
    my $inp = __PACKAGE__->new(undef, {readline => 0});
    printf "Input open has GNU Readline: %s\n", ($inp->have_gnu_readline ? "yes" : "no");
    $inp = __PACKAGE__->new(undef, {readline => 1});
    printf "Input open now has GNU Readline: %s\n", ($inp->have_gnu_readline ? "yes" : "no");
}
1;
