# Use with example/TCPPack.pm
# Test different forms of the break command.
break Exporter::import
break TCPPack.pm 20
break 20
break pack_msg 
break pack_msg if scalar(@_) == 1
info break
quit!
