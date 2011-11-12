# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>

# Debugger user/command-oriented input possibly attached to IO-style
# input or GNU Readline.
# 

use warnings; use strict;
use Exporter;

package Devel::Trepan::IO::Input;

use rlib '../../..';
use Devel::Trepan::Util qw(hash_merge);
use Devel::Trepan::IO;

use vars qw(@EXPORT @ISA $HAVE_GNU_READLINE);
@ISA = qw(Devel::Trepan::IO::InputBase Exporter);
@EXPORT = qw($HAVE_GNU_READLINE);

BEGIN {
    $ENV{'PERL_RL'} ||= 'Gnu';
    $HAVE_GNU_READLINE = 0 unless eval("use Term::ReadLine; 1");
    sub GLOBAL_have_gnu_readline {
        if (!defined($HAVE_GNU_READLINE)) {
            my $term = Term::ReadLine->new('testing');
            if ($term->ReadLine eq 'Term::ReadLine::Gnu') {
                $HAVE_GNU_READLINE = 'Gnu';
            } elsif ($term->ReadLine eq 'Term::ReadLine::Perl') {
                $HAVE_GNU_READLINE = 'Perl';
            } else {
                $HAVE_GNU_READLINE = 0;
            }
            # Don't know how to close $term
            $term = undef;
        }
	return $HAVE_GNU_READLINE;
    }
}

my $readline_finalized = 0;
sub new($;$$) {
    my ($class, $inp, $opts) = @_;
    $inp ||= *STDIN;
    my $self = Devel::Trepan::IO::InputBase->new($inp, $opts);
    if ($opts->{readline} && GLOBAL_have_gnu_readline()) {
	$self->{readline} = Term::ReadLine->new('trepanpl');
	$self->{gnu_readline} = 1;
    } else {
	$self->{readline} = undef;
	$self->{gnu_readline} = 0;
    }
    bless ($self, $class);
    return $self;
}

sub want_gnu_readline($) 
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
    printf "Input open has GNU Readline: %s\n", ($inp->want_gnu_readline ? "yes" : "no");
    $inp = __PACKAGE__->new(undef, {readline => 1});
    printf "Input open now has GNU Readline: %s\n", ($inp->want_gnu_readline ? "yes" : "no");
}
1;
