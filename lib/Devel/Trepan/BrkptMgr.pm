# -*- coding: utf-8 -*-
# Copyright (C) 2011-2013 Rocky Bernstein <rocky@cpan.org>
use strict; use warnings; no warnings 'redefine';
use English qw( -no_match_vars );

BEGIN {
    my @OLD_INC = @INC;
    use rlib '../..';
    use Devel::Trepan::DB::Breakpoint;
    @INC = @OLD_INC;
}

package Devel::Trepan::BrkptMgr;


sub new($$)
{
    my ($class,$dbgr) = @_;
    my $self = {};
    $self->{dbgr} = $dbgr;
    bless $self, $class;
    $self->clear();
    $self;
}

sub clear($)
{
    my $self = shift;
    $self->{list} = [];
    $self->{next_id} = 1;
}

sub inspect($)
{
    my $self = shift;
    my $str = '';
    for my $brkpt ($self->list) {
        next unless defined $brkpt;
        $str .= $brkpt->inspect . "\n";
    }
    $str;
}

sub ids($)
{
    my $self = shift;
    map $_->id, @{$self->compact()};
}

sub list($)
{
    my $self = shift;
    map defined($_) ? $_ : (),  @{$self->{list}}
}

# Remove all breakpoints that we have recorded
sub DESTROY() {
    my $self = shift;
    for my $bp ($self->list) {
        $self->delete_by_brkpt($bp);
    }
    $self->{clear};
}

sub find($$)
{
    my ($self, $index) = @_;
    return undef unless $index =~ /^\d+$/;
    for my $bp (@{$self->{list}}) {
        next unless $bp;
        return $bp if $bp->id eq $index;
    }
    return undef;
}

sub delete($$)
{
    my ($self, $index) = @_;
    my $bp = $self->find($index);
    if (defined ($bp)) {
        $self->delete_by_brkpt($bp);
        return $bp;
    } else {
        return undef;
    }
}

sub delete_by_brkpt($$)
{
    my ($self, $delete_bp) = @_;
    for my $candidate (@{$self->{list}}) {
        next unless defined $candidate;
        if ($candidate eq $delete_bp) {
            $candidate = undef;
            $self->{dbgr} && $self->{dbgr}->delete_bp($delete_bp);
            return $delete_bp;
        }
    }
    return undef;
}

sub add($$)
{
    my ($self, $brkpt) = @_;
    push @{$self->{list}}, $brkpt;
    return $brkpt;
}

sub compact($)
{
    my $self = shift;
    my @new_list = ();
    for my $brkpt (@{$self->{list}}) {
        next unless defined $brkpt;
        push @new_list, $brkpt;
    }
    $self->{list} = \@new_list;
    return $self->{list};
}

sub is_empty($)
{
    my $self = shift;
    $self->compact();
    return scalar(0 == @{$self->{list}});
}

sub max($)
{
    my $self = shift;
    my $max = 0;
    for my $brkpt (@{$self->{list}}) {
        $max = $brkpt->id if $brkpt->id > $max;
    }
    return $max;
}

sub size($)
{
    my $self = shift;
    $self->compact();
    return scalar @{$self->{list}};
}

sub reset($)
{
    my $self = shift;
    for my $bp (@{$self->{list}}) {
        $self->{dbgr}->delete_bp($bp);
     }
    $self->{list} = [];
}


unless (caller) {

    eval <<'EOE';
    sub bp_status($$)
    {
        my ($brkpts, $i) = @_;
        printf "list size: %s\n", $brkpts->size();
        printf "max: %d\n", $brkpts->max() // -1;
        print $brkpts->inspect();
        print "--- ${i} ---\n";
    }
EOE

    require Devel::Trepan::Core;
    my $dbgr = Devel::Trepan::Core->new;
    my $brkpts = Devel::Trepan::BrkptMgr->new($dbgr);
    bp_status($brkpts, 0);
    my $brkpt1 = DBBreak->new(
      type=>'brkpt', condition=>'1', id=>1, hits => 0, enabled => 1,
      negate => 0, filename => __FILE__, line_num => __LINE__
     );

    $brkpts->add($brkpt1);
    bp_status($brkpts, 1);

    my $brkpt2 = DBBreak->new(
    type=>'brkpt', condition=>'x>5', id=>2, hits => 0, enabled => 0,
    Negate => 0, filename => __FILE__, line_num => __LINE__
    );
    $brkpts->add($brkpt2);
    bp_status($brkpts, 2);

    $brkpts->delete_by_brkpt($brkpt1);
    bp_status($brkpts, 3);

    my $brkpt3 = DBBreak->new(
        type=>'brkpt', condition=>'y eq x', id=>3, hits => 0, enabled => 1,
        negate => 1, filename => __FILE__, line_num => __LINE__
        );
    $brkpts->add($brkpt3);
    bp_status($brkpts, 4);
    print "id 3 found is", $brkpts->find(3), "\n";
    print "id 4 is undef\n" unless defined $brkpts->find(4);
    print "id 'a' is undef\n" unless defined $brkpts->find('a');

    # p brkpts.delete(2)
    # p brkpts[2]
    # bp_status(brkpts, 3)

    # # Two of the same breakpoints but delete 1 and see that the
    # # other still stays
    # offset = frame.pc_offset
    # b2 = Trepan::Breakpoint.new(iseq, offset)
    # brkpts << b2
    # bp_status(brkpts, 4)
    # b3 = Trepan::Breakpoint.new(iseq, offset)
    # brkpts << b3
    # bp_status(brkpts, 5)
    # brkpts.delete_by_brkpt(b2)
    # bp_status(brkpts, 6)
    # brkpts.delete_by_brkpt(b3)
    # bp_status(brkpts, 7)
}

1;
