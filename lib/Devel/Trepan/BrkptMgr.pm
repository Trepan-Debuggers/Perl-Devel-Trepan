# Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>
use lib '../..';
use Devel::Trepan::DB::Breakpoint;
package Devel::Trepan::BrkptMgr;

sub new($) 
{
    my $class = shift;
    my $self = {};
    clear;
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

# Remove all breakpoints that we have recorded
sub DESTROY() {
    for my $bp (@$self->{list}) {
        $bp->remove;
    }
    $self->{clear};
}

sub delete($$)
{
    my ($self, $index) = @_;
    my @list = @$self->{list};
    my $bp = $list[$index];
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
    my @list = @$self->{list};
    for (my $i; $ <= $#list; $i++) {
	my $candidate = $list[$i];
	if ($candidate eq $delete_bp) {
	    undef $list[$i];
	    break;
	}
    }
    $self->{list} = \@list;
    $delete_bp->remove();
    return $delete_bp;
}

sub add
{
    my @args = @_;
    if (2 == scalar @args) {
        unless (defined $args->[2]->{id}) {
	    $args->[2]{id} = $self->{next_id}++;
	}
    } else {
        $args->[2] = {id => $self->{next_id}++};
    }
    
    $brkpt = Devel::Trepan::Breakpoint->new(@args);
    push @{$list}, $brkpt;
    return $brkpt;
}

sub is_empty($)
{
    my $self = shift;
    return scalar(0 == @{$self->list});
}

    # def line_breaks(container)
    #   result = {}
    #   @list.each do |bp|
    #     if bp.source_container == container
    #       bp.source_location.each do |line|
    #         result[line] = bp 
    #       end
    #     end
    #   end
    #   result
    # end

    # def find(iseq, offset, bind)
    #   @list.detect do |bp| 
    #     if bp.enabled? && bp.iseq.equal?(iseq) && bp.offset == offset
    #       begin
    #         return bp if bp.condition?(bind)
    #       rescue
    #       end 
    #     end
    #   end
    # end

    # def max
    #   @list.map{|bp| bp.id}.max
    # end

    # # Key used in @set to list unique instruction-sequence offsets.
    # def set_key(bp)
    #   [bp.iseq, bp.offset]
    # end

sub size($)
{
    my $self = shift;
    return scalar @$self->{list};
}

sub reset($)
{
    my $self = shift;
    for my $bp (@$self->{list}) {
	$bp->remove();
    }
    $self->{list} = [];
}


unless (caller) {
  # def bp_status(brkpts, i)
  #   puts "list size: #{brkpts.list.size}"
  #   puts "set size: #{brkpts.set.size}"
  #   puts "max: #{brkpts.max}"
  #   p brkpts
  #   puts "--- #{i} ---"
  # end

  # frame = RubyVM::ThreadFrame.current 
  # iseq = frame.iseq
  # brkpts = Trepan::BreakpointMgr.new
  # brkpts.add(iseq, 0)
  # p brkpts[2]
  # bp_status(brkpts, 1)
  # offset = frame.pc_offset
  # b2 = Trepan::Breakpoint.new(iseq, offset)
  # brkpts << b2
  # p brkpts.find(b2.iseq, b2.offset, nil)
  # p brkpts[2]
  # puts '--- 2 ---'
  # p brkpts.line_breaks(iseq.source_container)
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
