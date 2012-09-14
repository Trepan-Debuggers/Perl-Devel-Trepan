use strict; use warnings;

use Class::Struct;
struct TrepanPosition => {pkg   => '$', filename => '$', line => '$',
                          event => '$'};

package TrepanPosition;
sub eq($$) 
{
    my ($self, $other) = @_;
    return 0 unless defined $self && defined $other;
    return (
            $self->filename eq $other->filename 
            && $self->line eq $other->line
            && $self->event eq $other->event)
}

sub inspect($) {
    my $self = shift;
    return sprintf("pkg: %s, file: %s, line: %s, event: %s", 
                   $self->pkg, $self->filename, $self->line, $self->event);
}

unless (caller) {
    my $line = __LINE__;
    my $pos1 = TrepanPosition->new(pkg=>__PACKAGE__, filename=>__FILE__, 
                                   line => $line, event=>'brkpt');
    my $pos2 = TrepanPosition->new(pkg=>__PACKAGE__,  filename=>__FILE__, 
                                   line => $line, event=>'brkpt');
    my $pos3 = TrepanPosition->new(pkg=>__PACKAGE__, filename=>__FILE__, 
                                   line => __LINE__, event=>'brkpt');
    printf "pos1 is%s pos2\n", $pos1->eq($pos2) ? '' : ' not';
    printf "pos1 is%s pos3\n", $pos1->eq($pos3) ? '' : ' not';
    print $pos1->inspect, "\n";
    
}
1;
