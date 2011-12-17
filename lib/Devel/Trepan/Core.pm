use rlib '../..';
use Devel::Trepan::DB;
use Devel::Trepan::CmdProcessor;
use Devel::Trepan::WatchMgr;
use Devel::Trepan::IO::Output;
use Devel::Trepan::Interface::Script;
use Devel::Trepan::Interface::Server;
use Devel::Trepan::Util;

package Devel::Trepan::Core;
use vars qw(@ISA $dbgr);
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

sub new {
    my $class = shift;
    my $self = {
	watch => Devel::Trepan::WatchMgr->new(), # List of watch expressions
    };
    bless $self, $class;
}

# Called by DB to initialize us.
sub init() {
    print "init called\n";
}

# Called when debugger is ready for reading commands. Main
# entry point.
sub idle($$$) 
{
    my ($self, $event, $args) = @_;
    my $proc = $self->{proc};
    $proc->process_commands($DB::caller, $event, $args);
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
    my %cmdproc_opts = ();
    for my $field (qw(basename highlight readline traceprint)) {
	# print "field $field $opts->{$field}\n";
	$cmdproc_opts{$field} = $opts->{$field};
    }

    if (my $batch_filename = $opts->{testing} // $opts->{batchfile}) {
	my $result = Devel::Trepan::Util::invalid_filename($batch_filename);
	if (defined $result) {
	    print STDERR "$result\n" 
	} else {
	    my $output  = Devel::Trepan::IO::Output->new;
	    my $script_opts = 
		$opts->{testing} ? {abort_on_error => 0} : {};
	    my $script_intf = 
		Devel::Trepan::Interface::Script->new($batch_filename, 
						      $output, 
						      $script_opts);
	    my $cmdproc = Devel::Trepan::CmdProcessor->new([$script_intf], 
							   $self, 
							   \%cmdproc_opts);
	    $self->{proc} = $cmdproc;
	    $main::TREPAN_CMDPROC = $self->{proc};
        }
    } else {
	my $intf = undef;
	if ($opts->{server}) {
	    $server_opts = {
		host   => $opts->{host},
		port   => $opts->{port},
		logger => *STDOUT
	    };
	    $intf = [
		Devel::Trepan::Interface::Server->new(undef, undef,
						      $server_opts)
		];
	}
	my $cmdproc = Devel::Trepan::CmdProcessor->new($intf, $self, 
						       \%cmdproc_opts);
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
}

sub display_lists ($)
{
    my $self = shift;
    return $self->{proc}{displays}{list};
}
    
$dbgr = __PACKAGE__->new();
$dbgr->awaken();
$dbgr->register();
$dbgr->ready();

1;
