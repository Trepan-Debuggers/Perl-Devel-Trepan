#!/usr/bin/env perl
use strict; use warnings;
use rlib '../lib';

use Test::More;
note( "Testing Devel::Trepan::IO::Input" );

BEGIN {
use_ok( 'Devel::Trepan::IO::Input' );
}

note("term_readline_capability and priority");

my @TERMS = ('Perl5', 'Perl', 'Gnu', 'Stub');

my %HAVE_READLINE;

delete $ENV{PERL_RL} if $ENV{PERL_RL};
foreach my $ilk (@TERMS) {
    my $pkg_name = $ilk eq 'Stub' ?
	'Term::ReadLine' :
	"Term::ReadLine::$ilk" ;
    $HAVE_READLINE{$ilk} = eval "use $pkg_name; 1";
}

delete $ENV{PERL_RL} if $ENV{PERL_RL};

my @no_pkg = ();
my $have_some_readline = 0;
foreach my $ilk (@TERMS) {
    if ($HAVE_READLINE{$ilk}) {
	my $but_not = $ilk eq 'Perl5' ? '' :
	    ", but not ". join(", ", @no_pkg);
	is(term_readline_capability(), $ilk,
	   "prefer ${ilk}${but_not}");
	$have_some_readline = 1;
	last;
    }
    push @no_pkg, $ilk;
}

if ($have_some_readline) {
    ok($Devel::Trepan::IO::Input::HAVE_TERM_READLINE,
       "\$Devel::Trepan::IO::Input::HAVE_TERM_READLINE should be set");
}

foreach my $ilk (@TERMS) {
    next if $ilk eq 'Stub';
    if ($HAVE_READLINE{$ilk}) {
	$ENV{PERL_RL} = $ilk;
	ok(term_readline_capability(),
	   "Explicitly set \$ENV{PERL_RL} to ${ilk}");
    }
}

if (open(my $fh, "<", __FILE__)) {
    my $in = Devel::Trepan::IO::Input->new($fh);
    ok(!$in->is_interactive, "Input files are not interactive");
    close($fh);
}

my $inp = Devel::Trepan::IO::Input->new(undef, {readline => 0});
ok(!$inp->want_term_readline, 'Said we did not want readline');
ok(!$inp->have_term_readline, 'not want readline -> not have readline');

done_testing();
