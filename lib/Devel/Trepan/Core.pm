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

sub add_startup_files($$) {
    my ($cmdproc, $startup_file) = @_;
    if (-f $startup_file) {
	if (-r $startup_file)  {
	    push @{$cmdproc->{cmd_queue}}, "source $startup_file";
	} else {
	    print STDERR "Command file '$startup_file' is not readable.\n";
	}
    }
}

sub awaken($;$) {
    my ($self, $opts);
    $cmdproc = Devel::Trepan::CmdProcessor->new(undef, __PACKAGE__);
    no warnings 'once';
    $main::TREPAN_CMDPROC = $cmdproc;
    # Process options
    if (!defined($opts) && $ENV{'TREPANPL_OPTS'}) {
	$opts = eval "$ENV{'TREPANPL_OPTS'}";
    }
    $opts //= {};
    for my $startup_file (@{$opts->{cmdfiles}}) {
	add_startup_files($cmdproc, $startup_file);
    }
    if (!$opts->{nx} && exists $opts->{initfile}) {
	add_startup_files($cmdproc, $opts->{initfile});
    }
}
    
__PACKAGE__->awaken();

1;
