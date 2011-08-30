package Devel::Trepan::Core;
use lib '../..';
use Devel::Trepan::DB;
use Devel::Trepan::CmdProcessor;
use vars qw(@ISA);
@ISA = qw(DB);

__PACKAGE__->register();
__PACKAGE__->ready();

my $cmdproc;

# Not used by debugger, but here for
# testing and OO completness.
sub new() {
    my $class = shift;
    my $self = {};
    bless $self, $class;
}

# Called by DB to initialize us.
sub init() {
    print "init called\n";
}

# Called when debugger is ready for reading commands. Main
# entry point.
sub idle($$) 
{
    my ($self, $after_eval) = @_;
    $cmdproc->process_commands($DB::caller, $after_eval, $DB::event);
}

sub output($) 
{
    my ($self, $msg) = @_;
    chomp($msg);
    $cmdproc->msg($msg);
}

sub warning($) 
{
    my ($self, $msg) = @_;
    chomp($msg);
    $cmdproc->errmsg($msg);
}

sub awaken($) {
    $cmdproc = Devel::Trepan::CmdProcessor->new(undef, __PACKAGE__);
    $main::TREPAN_CMDPROC = $cmdproc;
}
    
awaken('bogus');

1;
