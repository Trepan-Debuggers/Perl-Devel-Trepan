package Devel::Trepan::Core;
use lib '../..';
use Devel::Trepan::DB;
use Devel::Trepan::CmdProcessor;
use vars qw(@ISA);
@ISA = qw(DB);

Devel::Trepan::Core->register();
Devel::Trepan::Core->ready();

my $cmdproc;

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
    $cmdproc = Devel::Trepan::CmdProcessor->new(undef, Devel::Trepan::Core);
    $main::TREPAN_CMDPROC = $cmdproc;
}
    
awaken('bogus');

1;
