#!perl -W
#   scan-keywords.pl    $Version 3.0      Volker RW Schaa
#   Script to generates keywords from pdf files for the JACoW collaboration 
#   (see documentation in readme-proceedings-script.pdf)
#   Copyright (C) 2003-2016 Gesellschaft fuer Schwerionenforschung mbH
#   <http://www.gsi.de> by Volker RW Schaa (v.r.w.schaa at gsi.de)
#
#   Utility for the JACoW SPMS
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#   You can also get a copy of the license through the web at
#   <http://www.gnu.org/licenses/gpl.html>
#-----
# this script 
#  = scan-keywords.pl =
# needs pdftotext.exe
#
#  v0.9   07-07-03   vrws   keyword list substituted by regular expressions in the following way:
#                             electromagnetic-fields=electromagnetic.{0,1}field.{0,1}, so
#                             now electromagnetic-fields,
#                                 electromagnetic fields
#                                 electromagnetic-field,
#                                 electromagnetic field
#                             are found (hit rate on DIPAC2003 more than 200% better)
#  v1.0   20-12-03   vrws   keyword list now loadable
#  v1.1              vrws   script is now independent of settings in the spms 
#                             script's config file
#  v1.2              vrws   acronym list generated
#  v1.3   07-12-04   vrws   read keyword list from current directory
#  v1.4   19-05-06   vrws   acronym file not generated anymore 
#  v1.5   12-07-06   vrws   GPL license
#  v1.6   20-10-08   vrws   length of paper_code [1,10] from [4,8]
#  v1.7   02-02-09   vrws   introduced "-raw" for stream aware conversion (important 
#                           for detection of Abstract and Reference section)
#  v1.8   05-03-09   vrws   search for accented characters (or part of UTF-8 byte sequences)
#                           in the author/institutes section before the 'Abstract'
#  v1.9   10-08-09   jp     Need to allow "-" in filenames (InDiCo)
#  v1.10  22-02-10   vrws   search for "Abstract" works now upper or mixed-case text
#  v1.11  27-06-13   vrws   output file "keyword-count.dbg" now has date and time in the filename
#                           like "keyword-count-20130326-1750.dbg"
#  v2.0   29-09-15   vrws   chomp doesn't remove CRLF on Linux from a Windows/DOS text file, therefore chomp replaced by "s/\s+$//"
#  v2.1   20-01-17   vrws   output file "broken-paper.txt"  now has date and time in the filename
#  v2.2   22-04-17   vrws   output file $paper_code.".txt"  now has for easier identification the name $paper_code."-k.txt"
#
#   - opens a keyword file <keywords.list> and stores the keywords and their regular expressions 
#     in an internal structure
#   - searches the current directory for pdf files (<paper_code>.pdf),
#   - checks whether there is an already converted text file for this pdf file (=> <paper_code>.txt),
#     if "no", converts the pdf file into text file (=> <paper_code>.txt) using pdftotext
#   - scans the text files, compares the keyword list to the file's contents
#   - writes an file (=> keyword-count.txt) with entries for the
#     five topmost used keywords, like
#     <paper_code>.pdf=keyword1;keyword2;keyword3;keyword4;keyword5;
#   - writes an file (=> accented.txt) with entries of <paper_code> to check for accented author names
#  v3.0   19-09-19   vrws   references of papers extracted
#
  use strict "vars";
  use File::Basename;
  use File::Find;
  use Time::HiRes  qw(gettimeofday);

  use vars qw (@list $list @entry $entry $direc);
  use vars qw ($fname $base);
  use vars qw ($out $dbg $ltim);
#  use vars qw ($ji);  #Acronym count?
  use vars qw ($paper_abs $i $j $status $acc $acl $refl);

  print "--> @ARGV\n";
  if ($ARGV[0]) {
    $direc = $ARGV[0];
  } else {
    $direc = "./";
  }
  print "reading pdfs from directory: $direc\n";
#
# open keyword file and read keys into
#
  print "reading keywords from: 'keywords.list'\n";
  open (KEYW, "<keywords.list") or die ("Cannot open 'keyword.list' -- $!\n");
  my $j=-1;
  while (<KEYW>) {
#      chomp;
	  s/\s+$//;
      $j++;
#      s/-//g;
      ($entry[$j], $list[$j]) = split (/=/);
      print " [$j] $entry[$j] --- $list[$j]\n";
  }
  close(KEYW);
#
# open keyword count file
#
  $out = "keyword-count.txt";
  open (KYCNT, ">$out") or die " cannot open '$out' -- error: $!\n";

#
# open log file for PDFs with accented characters
#
  $acl = "acc-char-list.txt";
  open (ACCT, ">$acl") or die " cannot open '$acl' -- error: $!\n";

#
# open log file for References
#
  $refl = "reference-list.txt";
  open (REFL, ">$refl") or die " cannot open '$refl' -- error: $!\n";

#
# open debug file
#
  (my $sec, my $min, my $hour, my $mday, my $mon, my $year, my $wday, my $yday, my $isdst) = localtime(time);
  $ltim = sprintf("%04d%02d%02d-%02d%02d", $year+1900, $mon+1, $mday, $hour, $min);
  $dbg = "keyword-count_".$ltim.".dbg";
  open (DBG, ">$dbg") or die " cannot open '$dbg' -- error: $!\n";

#
# open file for (probably) broken papers
#
    my $broken_file = "broken-papers_".$ltim.".txt";
    open (BROKN, ">:encoding(UTF-8)", $broken_file) or die " cannot open '$broken_file' -- error: $!\n";
	#
# open input file for whitelisted (non)broken papers
#
#i   my $white_listfile = "whitelist.txt";
#i   open (WHITE, "<:encoding(UTF-8)", $white_listfile) or die " cannot open '$white_listfile' -- error: $!\n";
#
# open acronym file
#
#@  $out = "acronyms.txt";
#@  open (ACRONYM, ">$out") or die " cannot open '$out' -- error: $!\n";

#?  $ji=0; #Acronym count?
  find (\&search_pdf_file, $direc);

#@  close (ACRONYM);
  close (KYCNT);
  close (ACCT);
  close (DBG);
  close (REFL);
  close (BROKN);

exit;

#
# find all pdf files and submit them to the keyword generator
#
sub search_pdf_file {
     $fname = $File::Find::name;
     ($base) = fileparse($fname);
#    print "File: $fname  -- Base: $base\n";
     if ($base =~ m/^([A-Z0-9\-]{1,10})\.pdf$/i) {   # v1.9
         print "File $base\n";
         generate_keywords ($base);
     }
}

#
# generate keywords:
#    a) convert pdf file to text using "pdftotext -raw"
#    b) read this text file into $paper_abs
#    c) compare paper abstract against list
#    d) store keywords
#
sub generate_keywords {

    use vars qw (%count @count $count $paper_txt);

    my $pdffile = $_[0];
    (my $paper_code) = $pdffile =~ m/^(.*?)\.pdf$/i;

    #
    # check existence of "<paper_code>.txt" to speed-up run time
    # remove all "<paper_code>.txt" for a complete rebuild of keywords
    #
    if (open (TXT, "<$paper_code.txt")) {
        #
        # nada mas => file already exists
        #
    } else {
        # 
        # generate new "<paper_code>-k.txt" for Keyword search
        #
        # "-raw" for stream aware conversion (important for
        #        detection of Abstract and Reference section)
        #
        $status = system ("pdftotext -nopgbrk $pdffile $paper_code-k.txt");
        die "pdftotext with errors: $? on \"$pdffile\"" unless $status == 0;
        open (TXT, "<$paper_code-k.txt") or die ("Cannot open '$paper_code-k.txt' -- $!\n");
    }

    $paper_txt = "";
    while (<TXT>) {
#        chomp;
		  s/\s+$//;
#@        if (m|\b([A-Z]+?)\b|g)  { # look for space surrounded CAPITAL letters
#@            $ji++; #Acronym count?
#@            print ACRONYM "$1\n";
#@        }
		if (m|[0-9]-$|) {
			$paper_txt .= $_;
		} elsif (m|-$|) {
			s/-$//;  	# remove hyphenation after word characters (alphanumeric + "_")
			$paper_txt .= $_;
		}  elsif (m|[0-9]$|) {
			$paper_txt .= $_;
		} else {
			$paper_txt .= $_." ";
		}

##        s/(\w)-$/$1/;  # remove hyphenation after word characters (alphanumeric + "_")
#??       $paper_txt .= $_." ";
#??        $paper_txt .= $_;
    }
    close (TXT);
#
# determine end of author/institute section and write string to
#   file if accented characters are detected
#
	my @ref_items;
    my $ref_sec_a	= index ($paper_txt, "REFERENCES");
	my $ref_sec_e	= length ($paper_txt);
    if ($ref_sec_a > 0 && $ref_sec_a < $ref_sec_e) {
		print REFL "--------$paper_code----------\n";
		@ref_items			= split (/\[/, substr ($paper_txt, $ref_sec_a+10, $ref_sec_e));
		my $ref_items_anz	= $#ref_items;
	    for ($i=1; $i<=$ref_items_anz; $i++) {
	        print REFL sprintf (" [%s\n", $ref_items[$i]);
	    }
	}
#
#
#
    my $authinst_end1 = index (uc $paper_txt, "ABSTRACT");
    my $authinst_end2 = index (uc $paper_txt, "INTRO");
    my $authinst_end  = $authinst_end1;
    if ($authinst_end < 0 && $authinst_end2 > 0) {
#        print " Abstract:Intro => 0:$authinst_end2\n";
        $authinst_end = $authinst_end2;
    }
    if ($authinst_end2 > 0 && $authinst_end > $authinst_end2) {
#        print " Abstract:Intro => $authinst_end:$authinst_end2\n";
        $authinst_end = $authinst_end2;
    }    
    my $authinst      = substr ($paper_txt, 0, $authinst_end - 1);
    $acc = () = $authinst =~ m/[\x80-\xff]/;#
#    print ACCT "$paper_code# $authinst_end\n";
#    print ACCT "$paper_code= $acc <==> $authinst\n";
    if ($acc) {
        #
        # write paper_code to file when accented chars are found
        #
        print ACCT "$paper_code=$authinst\n";
        $authinst =~ s/[\x80-\xff]/\#/g;
        print ACCT "$paper_code=$authinst\n";
    }

    print DBG   "$paper_code\n";
    print KYCNT "$paper_code=";

	my $sum_geo = 0;
	my $sum_gtt = 0;
	my $sum_all = 0;
    for ($i=0; $i<=$#list; $i++) {
	#
        my $clt = () = $paper_txt =~ /$list[$i]/gi;
        $count{$entry[$i]} = sprintf ("%4i", $clt);
        if ($clt > 0) {
			$sum_geo++;
            print DBG sprintf (" %4i %s\n", $clt, $entry[$i]);
		}
        if ($clt > 2) {
            $sum_gtt++;
			$sum_all += $clt;
		}
    }
    print DBG sprintf ("   %10s = %3i-%3i->%3i\n----------\n", $paper_code, $sum_geo, $sum_gtt, $sum_all);

    $j=-1;
    foreach my $keyw (sort { $count{$b} cmp $count{$a} } keys %count ) {
        $j++;
        my $acnt = $count{$keyw};
        if ($j < 5) {
            if ($acnt > 0) {
                print KYCNT "$keyw;"
            }
        }
        if ($acnt > 0) {
#            print DBG sprintf ("      (%i)%s ", $acnt, $keyw);
        } else {
            last;
        }
    }
    print KYCNT "\n";
#    print DBG   "\n";
#
# check length and numbers of words
#
	my %wc_count;
	my $cnt;
	my $wcnt;
	my $lct;
	my $end_pat = qr/[\]\)•,\.:*;'"´?]/;
#	$paper_txt  =~ s|(\w)[/,](\w)|$1 $2|g;
	$paper_txt  =~ s|,| |g;
	$paper_txt  =~ s|\xe2\x80\x93| |g;   #endash
	$paper_txt  =~ s|\xe2\x80\x94| |g;   #emdash
	$paper_txt  =~ s/-/ /g;
    foreach my $word (split /\s+/, $paper_txt) {
		if ($word =~ m/http/i) { next;}
		if ($word =~ m/www\./i) { next;}
		if ($word =~ m/@/) { next;}
		if ($word =~ m|[0-9]|) {
		} else {
			$word = lc $word;
			$word =~ s/_//g;
			$word =~ s|\xe2\x80\x98||g;   #<â€˜|‘>    
			$word =~ s|\xe2\x80\x99||g;   #<â€™|’>   
			$word =~ s|\xe2\x80\x9c||g;   #<â€œ|“>   
			$word =~ s|\xe2\x80\x9d||g;   #<â€|”> 
			$word =~ s|\xe2\x80\xa0||g;   #<†>
			$word =~ s|\xef\xac\x80|ff|g; 	
			$word =~ s|\xef\xac\x81|fi|g; 	
			$word =~ s|\xef\xac\x82|fl|g; 	
			$word =~ s|\xef\xac\x83|ffi|g; 	
			$word =~ s/^[\"\#*\(\[`']//g;
			while ($word =~ m/$end_pat$/) {
				$word =~ s/$end_pat$//g;
			}
			$lct = length ($word);				# length of string
			if ($lct > 0) {
				if ($word =~ m|/| && $lct > 9){	
#					print DBG " found / in $word\n";
					foreach my $subword (split /\//, $word) {
						$wc_count{$subword}{word_count}++;
						$wc_count{$subword}{word_length} = length ($subword);
#						print DBG " subword in $word is $subword\n";
					}
				} else {
					$wc_count{$word}{word_count}++;
					$wc_count{$word}{word_length} = $lct;
				}
			}
		}
    }

	print DBG   "----------$paper_code---------------------------------------\n";
	my @cnt_arr;
	my $cnt_max = 0;
	my $broken = 0;
	my @broken_line;
	for my $word (sort keys %wc_count) {
		$lct  = $wc_count{$word}{word_length};	
		$wcnt = $wc_count{$word}{word_count};
		$cnt_arr[$lct] += $wcnt;
		if ($lct > $cnt_max) { $cnt_max = $lct; }
		#
		# $cnt   number of characters
		# $lct   string length (may include control or UTF-8 chars)
		#
		$cnt  = $word =~ s/(\w)/$1/gi;		# number of characters
#		print DBG sprintf (" L:%3d  A:%3d  #:%3d  [%s]\n", $lct, $cnt, $wcnt, $word);
		if ($lct > 22 && $lct > $cnt) {
			print DBG   sprintf (" L:%3d  A:%3d  #:%3d  [%s]\n", $lct, $cnt, $wcnt, $word);
			$broken_line[$broken] = sprintf (" L:%3d  A:%3d  #:%3d  [%s]\n", $lct, $cnt, $wcnt, $word);
			$broken++;
#			print " broken",uc $paper_code,"# $broken\n";
		}
#---	$word =~ s/[\/\-\.&:'*,;\#@\)\(]//g;
		if ($lct > $cnt+3) {
			print DBG   sprintf (" L:%3d  A:%3d  #:%3d  [%s]\n", $lct, $cnt, $wcnt, $word);
		#	print BROKN sprintf (" L:%3d  A:%3d  #:%3d  [%s]\n", $lct, $cnt, $wcnt, $word);
		}
	}
#
# print broken lines when two or more are present
#
	if ($broken > 1) {
		print BROKN "\n--- ",uc $paper_code," ---\n";
		for ($i=0; $i<$broken; $i++) {
			print BROKN $broken_line[$i];
		}
	}
    for ($i=0; $i<=$cnt_max; $i++) {
		if (defined $cnt_arr[$i]) {
			print DBG sprintf (" %3d: %5d\n", $i, $cnt_arr[$i]);
		}
	}
	print DBG "==================================================================\n";
	return;
}
# use bytes;
# my $len = bytes::length($string);
#
# "’" => '
# "Ã¼" => ü
#
# mopb024
# mopb027
# mopb096
# thpb015
# $string =~ tr/!-\/:-@[-`{-~/ /;   # translate ASCII specials to space
#
# prep for whitelisting of papers removed for the moment
#
# use vars qw ($paper_white @paper_white_list $paper_white_list $paper_white_list_anz $white_paper $paper_whiteping);
#     $paper_white_list_anz = 0;
#} else {
#    (my $papki = $paper_white) =~ s/^\"\|(.*?)\|\"$/$1/s;
#    @paper_white_list = split (/\|/, $papki);
#    $paper_white_list_anz = $#paper_white_list + 1;
#
#				#
#				# do we have to skip a paper?
#				#
#				if ($paper_white_list_anz > 0) {
#					#
#					# there are papers to skip, is this paper in the list?
#					#
#					$white_paper = 0;
#					for ($i=0; $i<$paper_white_list_anz; $i++) {
#						if ($paper_white_list[$i] eq $prg_code[$paper_nr][$prg_idx]) {
#							$white_paper = 1;
#							last;
#						}
#					}
#					if ($white_paper) {
#						Deb_call_strucOut ();
#						return;
#					}
#				}
#