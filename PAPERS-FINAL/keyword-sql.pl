# perl -W
# this script
#  1) needs the following file
#     "keyword-count.txt" with entries for the
#     five topmost used keywords, like
#          <paper_code>.pdf=keyword1;keyword2;keyword3;keyword4;keyword5;
#
#  2) writes a procedure file for the SPMS system to load the keywords via
#     <paper_id> into the appropriate table (=> "keywords_plsql.txt").
#     Matt has written the procedure "spms.abstract_keywords" to do this.
#     Each line look like
#          exec spms.abstract_keywords ('<paper_code>', '<keyword>');
#
# ----------------------
#    v0.9   9. Dec 2005  volker rw schaa  first try
#    v0.92 12. Dec 2005  vrws  minor changes
#    v0.95 18. Dec 2005  vrws  changed from SQL file to SMPS procedure
#                              (from 'insert' to exec "spms.abstract_keywords")
#    v0.99 20. Mar 2006  vrws  some updates to documentation
#    v0.991 28 Aug 2007  JHP Changes to match new procedure
#                            ("spms.abstract_keywords" to "keywords.add")
#

  use strict "vars";

  use vars qw ($keyin $plsql $i $j $paper_id $keywords @keyword);

#
# open keyword count file
#
  $keyin = "keyword-count.txt";
  open (KEYIN, "<$keyin") or die " cannot open '$keyin' -- error: $!\n";

  $plsql = "keywords_plsql.txt";
  open (PLSQL, ">$plsql") or die " cannot open '$plsql' -- error: $!\n";

  my $j=-1;
  while (<KEYIN>) {

    chomp;
    $j++;
    ($paper_id, $keywords) = split (/=/);
    @keyword = split(/;/, $keywords);
    for ($i=0; $i<=$#keyword; $i++) {
        print PLSQL ("exec keywords.add ('$paper_id', '$keyword[$i]');\n");
    }
  }
  close(KEYIN);
  close (PLSQL);
