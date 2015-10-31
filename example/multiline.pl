#!/usr/bin/env perl
use rlib '../lib';

use B::Deparse;
use Data::Printer;
use B::Concise;

sub foo {
    my $a = 0; $a += 10; $a *= 20;
    for (my $i=1; $i < 2; $i++)  {
	for (my $j=1; $j < 2; $j++)  {
	    print $i, " ", $j, "\n";
	}
    }
    return $a if $a > 10;
    return 0;
}

my $walker = B::Concise::compile('-basic', '-src', 'foo', \&foo);
B::Concise::set_style_standard('debug');
B::Concise::walk_output(\my $buf);
$walker->();			# walks and renders into $buf;
print($buf);

my $deparse = B::Deparse->new("-p", "-l", "-c", "-sC");
foo();

my @exprs = $deparse->coderef2list(\&foo);
import Data::Printer colored => 0;
Data::Printer::p(@exprs);
print $deparse->coderef2text(\&foo);
print '-' x 30, "\n";
print $deparse->coderef2text_new(\&foo);
