# Test "To see that we can break on a subroutine call"
# use with example/callbug.pl
c iamnotok
where
$_[0]
break 6
quit
