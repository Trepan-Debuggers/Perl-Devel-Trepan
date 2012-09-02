# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
# -*- coding: utf-8 -*-

=head1 C<Devel::Trepan::Pod2Text>

Devel::Trepan interface to convert POD into a string the debugger
and then present using its output mechanism

=cut

package Devel::Trepan::Pod2Text;

use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter); @EXPORT = qw(pod2text);

use warnings; use strict;

use vars qw($HAVE_TEXT_COLOR $HAVE_TEXT);

BEGIN {
    $HAVE_TEXT_COLOR = 
	eval { 
	       require Term::ANSIColor; 
	       require Pod::Text::Color;
    } ? 1 : 0;

    $HAVE_TEXT   = eval {
	require Pod::Text;
    } ? 1 : 0;
}

sub pod2text($;$$)
{
    my ($input_file, $color, $width) = @_;

    $width = ($ENV{'COLUMNS'} || 80) unless $width;
    $color = 0 unless $color;

    # Figure out what formatter we're going to use.
    my $formatter = 'Pod::Text';
    if ($color && $HAVE_TEXT_COLOR) {
	$formatter = 'Pod::Text::Color';
    } else {
	$formatter = 'Pod::Text';
    }

    my $p2t = $formatter->new(width => $width);
    my $output_string;
    open(my $out_fh, '>', \$output_string);
    $p2t->parse_from_file($input_file, $out_fh);
    return $output_string;
}

unless (caller) {
    print pod2text(__FILE__);
    print '-' x 30, "\n";
    print pod2text(__FILE__, 1);
    print '-' x 30, "\n";
    print pod2text(__FILE__, 1, 40);
    
}

1;
