# The class serves as the parent for Trepan::Processor which is
# quite large and spans over several files. By declaring "new"
# below, we have a consistent initialization routine and many of the
# others don't need to define "new".

use warnings;
use strict;
use Exporter;

package Devel::Trepan::Processor::Virtual;

use vars qw(@EXPORT @ISA);
@ISA = qw(Exporter);
@EXPORT = qw(new);

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

if (caller) {
    require Devel::Trepan::Interface::User;
    my $intf = Devel::Trepan::Interface::User->new;
    my $proc  = Devel::Trepan::Processor::Virtual->new([$intf]);
    print $proc->{class}, "\n";
    require Data::Dumper;
    print Data::Dumper::Dumper($proc->{interfaces});;
}

1;
