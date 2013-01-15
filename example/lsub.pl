#!/usr/bin/perl
# From Chris Marshall perl #116358
#
# Illustrate lvalue sub debug problem
# The n command steps into the lvalue sub
#

my $data = '';

sub lslice :lvalue {
    my ($arg1, $val1) = @_;
    # print ".. in lslice now\n";
    # print ".. $arg1 + $val1 = ", $arg1+$val1, "\n";
    $data;
}

my $x = "Start test, \$data=$data\n";
lslice(3,5) = 4;
print "Stop  test, \$data=$data\n";
