#!C:\Perl\bin\perl -w
no warnings qw(uninitialized);
use CAM::PDF;

my $boxLimit = 750; # This is the limit of boxes accepted on a page.
my $page_cnt;
my @files = <*>;
foreach $file (@files) {
 if ($file =~ m/(\.pdf|\.PDF)/) {
  $page_cnt = "";
#  print uc($file)." checking, ";
  my $pdf = CAM::PDF->new($file);
  $page_cnt    .= sprintf (" %-12s ", uc($file));
  my $pageCount = $pdf->numPages();
  my $total     = 0;
  for (my $pageNumber = 1; $pageNumber <= $pageCount; $pageNumber++) {
   my $pageContent = $pdf->getPageContent($pageNumber);
   $pageContent =~ s/\n//g;
   my @matches = $pageContent =~ /BT.*?ET/g;
   my $count = @matches;
#   print "    count $count on page $pageNumber, ";
   if ($count > $boxLimit) {
	 $page_cnt .= sprintf ("|%1i: %4i ## ", $pageNumber, $count);
   } else {
	 $page_cnt .= sprintf ("|%1i: %4i    ", $pageNumber, $count);
   }
   $total += $count;
  }
  $page_cnt .= sprintf ("|total: %5i\n", $total);
#  print "done.\n";
  print $page_cnt;
 }
}