# perl -W
# this script is hacked from Volker Schaa's keyword-sql.pl script
#  The aim is to load the set of keywords used by a conference in the processing
#  The script produces a file with the necessary PL*SQL to fill the KEYWORD_CODES table
#
#  It needs the following file
#     "keywords.list" with entries for the keywords and the regular expression
#
# ----------------------
#    v0.9  15  Aug 2007  J. Poole modified Volker R.W. Schaa's other script
#    v0.91 28  Aug 2007  J. Poole modified to match changes in SPMS packages

#

  use strict "vars";

  use vars qw ($keyin $plsql $i $j $regexpr $keywords );

#
# open keyword count file
#
  $keyin = "keywords.list";
  open (KEYIN, "<$keyin") or die " cannot open '$keyin' -- error: $!\n";

  $plsql = "keyw_regexp_sql.txt";
  open (PLSQL, ">$plsql") or die " cannot open '$plsql' -- error: $!\n";

  my $j=-1;
  while (<KEYIN>) {

    chomp;
    $j++;
    ($keywords, $regexpr) = split (/=/);
        print PLSQL ("exec keywords.set_regexp ('$keywords', '$regexpr');\n");
  }
  close(KEYIN);
  close (PLSQL);
