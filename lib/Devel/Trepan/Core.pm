package Devel::Trepan::Core;
use lib '../..';
use Devel::Trepan::DB;
use Devel::Trepan::CmdProcessor;
use vars qw(@ISA);
@ISA = qw(DB);

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
    my $proc = $self->{proc};
    $proc->process_commands($DB::caller, $after_eval, $DB::event);
}

sub output($) 
{
    my ($self, $msg) = @_;
    $proc = $self->{proc};
    chomp($msg);
    $proc->msg($msg);
}

sub warning($) 
{
    my ($self, $msg) = @_;
    $proc = $self->{proc};
    chomp($msg);
    $proc->errmsg($msg);
}

sub awaken($;$) {
    my ($self, $opts) = @_;
    no warnings 'once';
    # Process options
    if (!defined($opts) && $ENV{'TREPANPL_OPTS'}) {
	$opts = eval "$ENV{'TREPANPL_OPTS'}";
    }
    my $cmdproc_opts = {
	basename  =>  $opts->{basename},
	highlight =>  $opts->{highlight},
	traceprint => $opts->{traceprint}
    };
    my $cmdproc = Devel::Trepan::CmdProcessor->new(undef, __PACKAGE__, 
						$cmdproc_opts);
    $self->{proc} = $cmdproc;
    $main::TREPAN_CMDPROC = $self->{proc};
    $opts //= {};

    for my $startup_file (@{$opts->{cmdfiles}}) {
	add_startup_files($cmdproc, $startup_file);
    }
    if (!$opts->{nx} && exists $opts->{initfile}) {
	add_startup_files($cmdproc, $opts->{initfile});
    }
}

sub display_lists ($)
{
    my $self = shift;
    return $self->{proc}->{displays}->{list};
}
    
my $dbgr = __PACKAGE__->new();
$dbgr->awaken();
$dbgr->register();
$dbgr->ready();

1;
