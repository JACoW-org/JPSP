 use Time::HiRes qw(gettimeofday);
 use strict;
 no strict 'refs';
 use vars qw ($start_tm $stop_tm $sec $min $hour $mday $mon $year $wday $yday $isdst);
#
# first determine stop time
#
$stop_tm = gettimeofday;
#
# then read start time
#
open (ST, "<start.tm") or die ("Cannot open 'start.tm' -- $!
");
while (<ST>) {
    chomp;                  # no newline
    s/Sec: //;              # no comments
    $start_tm = $_;
}
close (ST);

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($start_tm);
print sprintf ("
Start: %2.2i.%2.2i.%4.4i %2.2i:%2.2i:%2.2i
", $mday, $mon, $year+1900, $hour, $min, $sec);
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($stop_tm);
print sprintf ("Stop:  %2.2i.%2.2i.%4.4i %2.2i:%2.2i:%2.2i
", $mday, $mon, $year+1900, $hour, $min, $sec);
#
# time difference
#
print sprintf ("

 elapsed time: %.2f [s]
", $stop_tm-$start_tm);
exit;
