 use Time::HiRes qw(gettimeofday);
 use strict;
 no strict 'refs';
 use vars qw ($start_tm $stop_tm $sec $min $hour $mday $mon $year $wday $yday $isdst);
#
# start time
#
$start_tm = gettimeofday;
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($start_tm);
print sprintf ("
Start: %2.2i.%2.2i.%4.4i %2.2i:%2.2i:%2.2i
", $mday, $mon, $year+1900, $hour, $min, $sec);
open (ST, ">start.tm") or die ("Cannot open 'start.tm' -- $!
");
print ST sprintf ("Sec: %f
", $start_tm);
close (ST);
exit;
