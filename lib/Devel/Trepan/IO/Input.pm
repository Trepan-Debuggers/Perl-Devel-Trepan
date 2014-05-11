# -*- coding: utf-8 -*-
# Copyright (C) 2011-2014 Rocky Bernstein <rocky@cpan.org>

# Debugger user/command-oriented input possibly attached to IO-style
# input or GNU Readline.
#

use warnings; use strict;
use Exporter;

package Devel::Trepan::IO::Input;

BEGIN {
    my @OLD_INC = @INC;
    use rlib '../../..';
    use Devel::Trepan::Util qw(hash_merge);
    use Devel::Trepan::IO;
    @INC = @OLD_INC;
}

use vars qw(@EXPORT @ISA $HAVE_TERM_READLINE);
@ISA = qw(Devel::Trepan::IO::InputBase Exporter);
@EXPORT = qw($HAVE_TERM_READLINE term_readline_capability);

sub term_readline_capability() {
    # Prefer Term::ReadLine::Perl5 if we have it
    return 'Perl5' if
	(!$ENV{PERL_RL} || $ENV{PERL_RL} =~ /\bperl5\b/i) &&
	eval q(use Term::ReadLine::Perl5; 1);

    if ($ENV{PERL_RL}) {
	return eval q(use Term::ReadLine; 1);
    } else {
	# Prefer Term::ReadLine::Perl for Term::ReadLine
	foreach my $ilk (qw(Perl Gnu)) {
	    return $ilk if eval qq(use Term::ReadLine::$ilk; 1);
	}
	return 'Stub' if eval q(use Term::ReadLine; 1);
    }
    return 0;
}

$HAVE_TERM_READLINE = term_readline_capability();

sub new($;$$) {
    my ($class, $inp, $opts) = @_;
    $inp ||= *STDIN;
    my $self = Devel::Trepan::IO::InputBase->new($inp, $opts);
    if ($opts->{readline} && $HAVE_TERM_READLINE) {
        my $rc = 0;
        $rc = eval {
	    ## FIXME: Simplify after Term::ReadLine::Perl5 is in Term::ReadLine
	    if ($HAVE_TERM_READLINE eq 'Perl5') {
		$self->{readline} = Term::ReadLine::Perl5->new('trepan.pl');
	    } else {
		$self->{readline} = Term::ReadLine->new('trepan.pl');
	    }
            1 ;
        };
        if ($rc) {
            $self->{term_readline} = 1;
        } else {
            $self->{readline} = undef;
            $self->{term_readline} = 0;
        }
    } else {
        $self->{readline} = undef;
        $self->{term_readline} = 0;
    }
    bless ($self, $class);
    return $self;
}

sub have_term_readline($)
{
    my $self = shift;
    $self->{term_readline} && (exists($ENV{'TERM'}) && $ENV{'TERM'} ne 'dumb');
}

sub want_term_readline($)
{
    my $self = shift;
    $self->{term_readline};
}

sub is_interactive($)  {
    my $self = shift;
    return -t $self->{input};
}

sub rl_filename_list($$)  {
    my ($self, $prefix) = @_;
    if ($HAVE_TERM_READLINE eq 'Perl5') {
	Term::ReadLine::Perl5::readline::rl_filename_list($prefix);
    } elsif ($HAVE_TERM_READLINE eq 'Gnu') {
	Term::ReadLine::Gnu::XS::rl_filename_list($prefix);
    # } elsif ($HAVE_TERM_READLINE eq 'Perl') {
	# FIXME: how does one do this for Perl?
    }
}

# Read a line of input. EOFError will be raised on EOF.
# Prompt is ignored if we don't have GNU readline. In that
# case, it should have been handled prior to this call.
sub readline($;$) {
    my ($self, $prompt) = @_;
    $prompt = '' unless defined($prompt);
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
    printf "term_readline_capability: %s\n", term_readline_capability();
    printf "Have Term::ReadLine: %s\n", ($HAVE_TERM_READLINE ? "yes" : "no");
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
    printf "Input open has Term::ReadLine: %s\n", ($inp->want_term_readline ? "yes" : "no");
    $inp = __PACKAGE__->new(undef, {readline => 1});
    printf "Input open now has Term::ReadLine: %s\n", ($inp->want_term_readline ? "yes" : "no");
    foreach my $term (qw(Gnu Perl5)) {
	$HAVE_TERM_READLINE = $term;
	my $path='./';
	my @files = $inp->rl_filename_list($path);
	printf "term: %s, path: %s\n", $term, $path;
	foreach my $file (@files) {
    	    print "\t$file\n";
	}
    }
}
1;
