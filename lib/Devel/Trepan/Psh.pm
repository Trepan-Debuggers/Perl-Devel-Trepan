use Psh;
use warnings; no warnings 'redefine';
# use File::Basename;
# use File::Spec;
# unshift @INC, File::Spec->catfile(dirname(__FILE__), 'Psh');
# print "Inc is ${INC[0]}\n";
# eval "require Psh::Strategy::Built_in";
# shift @INC;

use lib '../..';

## package Psh;

# $Psh:quit provides a way to for a way to quit process() and return
# to the caller.  This is useful, for example, in the debugger
# Devel::Trepan (a debugger) to provide going into psh shell, but
# returning to the debugger afterwards.

use vars qw($Psh::quit); 

#
# void process(bool Q_PROMPT, subr GET)
#
# Process lines produced by the subroutine reference GET until it
# returns undef. GET must be a reference to a subroutine which takes a
# string argument (the prompt, which may be empty) and returns the
# next line of input, or undef if there is none.
#
# Any output generated is handled by the various print_xxx routines
#
# The prompt is printed only if the Q_PROMPT argument is true.  When
# sourcing files (like .pshrc), it is important to not print the
# prompt string, but for interactive use, it is important to print it.
#
# TODO: Undo any side effects, e.g. done by m//.
#
# Note: Monkeypatch by rocky to allow embedding psh inside Devel::Trepan
# (or any other Perl program that wants temporary psh shell access).

sub Psh::process
{
	my ($q_prompt, $get) = @_;
	local $Psh::cmd;

	my $last_result_array = '';
	my $result_array_ref = \@Psh::val;
	my $result_array_name = 'Psh::val';

	my $control_d_counter=0;

	if ($q_prompt) {
		require Psh::Prompt;
	}

	$Psh::quit = 0;
	until ($Psh::quit) {
		if ($q_prompt) {
			$input = &$get(Psh::Prompt::prompt_string(Psh::Prompt::normal_prompt()), 0, \&Psh::Prompt::pre_prompt_hook);
		} else {
			$input = &$get();
		}

		Psh::OS::reap_children(); # Check wether we have dead children
		Psh::OS::check_terminal_size() if $Psh::interactive;

		$Psh::cmd++;

		unless (defined($input)) {
			last unless $Psh::interactive;
			print STDOUT "\n";
			$control_d_counter++;
			my $control_d_max=$ENV{IGNOREEOF}||0;
			if ($control_d_max !~ /^\d$/) {
				$control_d_max=10;
			}
			Psh::OS::exit_psh() if ($control_d_counter>=$control_d_max);
			next;
		}
		$control_d_counter=0;

		next unless $input;
		next if $input=~ m/^\s*$/;

		if ($input =~ m/(.*)<<([a-zA-Z_0-9\-]*)(.*)/) {
			my $pre= $1;
			my $terminator = $2;
			my $post= $3;

			my $continuation = $q_prompt ? Psh::Prompt::continue_prompt() : '';
			$input = join('',$pre,'"',
						  read_until($continuation, $terminator, $get),
						  $terminator,'"',$post,"\n");
		} elsif (Psh::Parser::incomplete_expr($input) > 0) {
			my $continuation = $q_prompt ? Psh::Prompt::continue_prompt() : '';
			$input = read_until_complete($continuation, $input, $get);
		}

		chomp $input;

		my ($success,@result);
		my @elements= eval { Psh::Parser::parse_line($input) };
		Psh::Util::print_debug_class('e',"(evl) Error: $@") if $@;
		if (@elements) {
			my $result;
			($success,$result)= _evl(@elements);
			Psh::Util::print_debug_class('s',"Success: $success\n");
			$Psh::last_success_code= $success;
			if ($result) {
				@Psh::last_result= @result= @$result;
			} else {
				undef @Psh::last_result;
				undef @result;
			}
		} else {
			undef $Psh::last_success_code;
			undef @Psh::last_result;
		}

        next unless $Psh::interactive;

		my $qEcho = 0;
		my $echo= Psh::Options::get_option('echo');

		if (ref($echo) eq 'CODE') {
			$qEcho = &$echo(@result);
		} elsif (ref($echo)) {
			Psh::Util::print_warning_i18n('psh_echo_wrong',$Psh::bin);
		} else {
			if ($echo) { $qEcho = defined_and_nonempty(@result); }
		}

		if ($qEcho) {
		        # Figure out where we'll save the result:
			if ($last_result_array ne $Psh::result_array) {
				$last_result_array = $Psh::result_array;
				my $what = ref($last_result_array);
				if ($what eq 'ARRAY') {
					$result_array_ref = $last_result_array;
					$result_array_name =
						find_array_name($result_array_ref);
					if (!defined($result_array_name)) {
						$result_array_name = 'anonymous';
					}
				} elsif ($what) {
					Psh::Util::print_warning_i18n('psh_result_array_wrong',$Psh::bin);
					$result_array_ref = \@Psh::val;
					$result_array_name = 'Psh::val';
				} else { # Ordinary string
					$result_array_name = $last_result_array;
					$result_array_name =~ s/^\@//;
					$result_array_ref = (Psh::PerlEval::protected_eval("\\\@$result_array_name"))[0];
				}
			}
			if (scalar(@result) > 1) {
				my $n = scalar(@{$result_array_ref});
				push @{$result_array_ref}, \@result;
				if ($Psh::interactive) {
					my @printresult=();
					foreach my $val (@result) {
						if (defined $val) {
							push @printresult,qq['$val'];
						} else {
							push @printresult,qq[undef];
						}
					}
					Psh::Util::print_out("\$$result_array_name\[$n] = [", join(',',@printresult), "]\n");
				}
			} else {
				my $n = scalar(@{$result_array_ref});
				my $res = $result[0];
				push @{$result_array_ref}, $res;
				Psh::Util::print_out("\$$result_array_name\[$n] = \"$res\"\n");
			}
			if (@{$result_array_ref}>100) {
				shift @{$result_array_ref};
			}
		}
	}
}

1;
