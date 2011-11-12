# The class serves as the parent for Trepan::Processor which is
# quite large and spans over several files. By declaring "new"
# below, we have a consistent initialization routine and many of the
# others don't need to define "new".

use warnings;
use strict;
use Exporter;

package Devel::Trepan::CmdProcessor::Virtual;

use vars qw(@EXPORT @ISA);
@ISA = qw(Exporter);

use rlib '../../..';

# attr_reader :settings
sub new($$;$) {
    my ($class, $interfaces, $settings) = @_;
    $settings ||= {};
    my $self = {
	class      => $class,
	interfaces => $interfaces,
	settings   => $settings,
    };
    bless ($self, $class);
    return $self;
}

if (__FILE__ eq $0) {
    require Devel::Trepan::Interface::User;
    my $intf = Devel::Trepan::Interface::User->new;
    my $proc  = Devel::Trepan::CmdProcessor::Virtual->new([$intf]);
    print $proc->{class}, "\n";
    print join(', ', @{$proc->{interfaces}}), "\n";
}

1;
