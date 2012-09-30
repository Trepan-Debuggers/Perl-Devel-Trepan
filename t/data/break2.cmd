# Use with example/TCPPack.pm
# Test different forms of the break command.
break Exporter::import
break TCPPack.pm 20
break 20
break pack_msg 
break pack_msg if scalar(@_) == 1
info break
# We want to see that when we have
# an incomplete statement on a line
# we do the right thing. Stopping at:
#    unless(caller) {
# should list the next line: 
#      my $buf = "Hi there!";
# but not further lines since that "my" finishes
# a valid statement.
continue 34
quit!
