#! perl -W
#   pagecheck.pl    $Version 6.2      Volker RW Schaa
#   Script to generates diagnostics about pdf files for the JACoW collaboration
#   (see documentation in readme-proceedings-script.pdf)
#   Copyright (C) 2004-2019 Gesellschaft fuer Schwerionenforschung mbH
#   <http://www.gsi.de> by Volker RW Schaa (v.r.w.schaa at gsi.de)
#
#   Utility for the JACoW SPMS (JPSP)
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
#---
# this script
#   - opens the file 'page_per_paper.txt' in the given directory
#     and reads the entries which list papers with the number of pages
#     stored in SPMS (extracted from the XML file)
#   - searches the '$raw_paper directory' for the mentioned pdf files
#     (<paper_code>.pdf),
#   - extracts information by running "pdfinfo" on the pdf file
#   - compares the number of pages given in SPMS to the ones in the file
#
#  1) uses the following utilities: pdfinfo + pdffonts
#
#    v0.3   3 Jun 2005  volker rw schaa  first try
#    v0.4  28 Apr 2006  volker rw schaa
#    v1.0     May 2006  volker rw schaa  small adjustments/final version
#    v1.1  12 Jul 2006  volker rw schaa  GPL license
#    v1.2  19 Jul 2006  john pool/vrws   adjustment to paper size, which is sometimes 791/792. Now
#                                        a ranges is accepted (592 > width > 597, 790 > height > 794)
#    v1.3  23 Jul 2006  vrws             pagecheck now reports wrong pdf version (version > 1.5)
#                                        and catches empty file errors
#    v2.0  17 Nov 2007  vrws             in addition font embedding and Type 3 fonts are reported (now
#                                        using PDFFonts)
#    v2.1  21 Nov 2007  vrws             elapsed time measurement
#    v2.2  02 Mar 2009  vrws             decesion at TM 2008 in Japan to switch to PDF 1.6
#    v2.3  10 Oct 2010  vrws             combining various enhancements into the official release
#    v2.4  09 Jul 2011  vrws             changed "Pages:" to "Pages:   " to detected lines like 
#                                        "Creator:        Pages: cgpdftops CUPS filter" which generate an error
#    v2.5  18 May 2012  vrws             added the paper Editor to the output
#    v2.6  25 May 2012  vrws             added the paper QA Editor to the output
#    v2.7  03 Oct 2012  vrws             added the paper Status to the output
#    v3.0  23 Mar 2013  vrws             introduced parameter "clean" for status list only showing papers with errors
#                                        for this all print lines are stored in @pr_lines before written to file
#    v3.1  26 Mar 2013  vrws             output file "pagecheck-result.txt" now has date and time in the filename
#                                        like "pagecheck-result-20130326-1750.txt"
#    v3.2  14 Sep 2013  vrws             additional parameter introduced following "clean": "noQA"
#
#    v3.3  14 Jun 2014  vrws             additional parameter introduced: "noRED" (red dotted papers shouldn't be shown
#    v3.4  16 Jun 2014  vrws             now a font warning is issued if there are more than xx fonts used in the PDF
#    v4.0  10 May 2015  vrws             now the correct page count is written to "spms_corr_pages.bat" using the
#                                      - new function "editor.set_page_count" with parameters "up_passphrase", "abs_id", "pcount"
#                                      - "clean" is now the default, and "noclean" is the parameter
#    v5.0  29 Sep 2015  vrws           - OS_platform is detect inside all scripts (therefore removed from config file)
#                                      - spms_corr
#    v5.1  29 Sep 2015  vrws           - wrong number of pages suppressed in output report (only written to spms_corr_pages)
#    v5.2  11 Sep 2016  vrws           - version which keeps the pdfinfo and pdffont files
#    v5.3  20 Jan 2017  vrws           - error messages due to not installed display font files disabled ("Config Error: No display font for 'Symbol'")
#										 errors are rewritten to $font_file, but checking of other errors postponed (...mismatch font...) as it is 
#										 not clear how to fix that
#    v5.4  05 Nov 2017  vrws           - some status messages removed due to output documentation which contained pass phrases
#    v6.0  09 Jan 2019  vrws           - in addition to checking the page sizes of the PDF, the PDF file itself is now searched for CropBox and MediaBox. This is due to incomplete 
#									     cropping of PDFs: before Dec 2018 Ivan's function 'Crop' in Acrobat only cropped the MediaBox without touching the CropBox,
#										 if PDFs had been saved using "save over" in Acrobat before cropping, the MediaBox would be correct but the CropBox stayed at the size of the
#										 previous MediaBox.
#    v6.1  16 Jan 2019  vrws           - version v6.0 didn't manage to extract MediaBox and CropBox from compressed PDFs, therefore the PDF utility PDFtk 
#									     (https://www.pdflabs.com/tools/pdftk-server/#download) is now used to get number of pages and xxxBox sizes. 
#									   - finally "wget" has been replaced by "curl"
#	 v6.2  25 Mar 2019	vrws		   - suddenly SPMS instance at KEK throws an error on curl updating pages (spms_corr_pages.bat)
#										 "curl: (35) schannel: next InitializeSecurityContext failed: Unknown error (0x80092012) - 
#													The revocation function was unable to check revocation for the certificate."
#										 introduced parameter "--ssl-no-revoke" to disable revocation checking
#
#-----------------------------------------
  use strict "vars";
  use Time::HiRes  qw(gettimeofday);

  use vars qw (@filepages $filepages @fileentry $fileentry @pages_fnd $pages_fnd $direc);
  use vars qw ($i $ltyp $num_of_papers $out);
  use vars qw (@abs_id $abs_id $conference_SPMS $PassUp);
  use vars qw ($pdffile $kin $paper $value $numofpages $outfile $command $page $arg $file $name $type);
  use vars qw ($f_name $f_type $f_emb $f_sub $f_uni $f_object $f_id $font_name $font_names @font_names);
  use vars qw (@paper_editor $paper_editor @paper_status $paper_status @qa_editor $qa_editor);
  use vars qw ($start_tm $stop_tm);
  use vars qw ($clean $is_clean $print_lines @pr_lines $pr_lines $iline $ignore_QA $no_red);
  use vars qw ($WL_DelRM $os_platform_id);
  use vars qw ($uryc $urym $llx $lly $urx $ury @cropboxlist @mediaboxlist $pdffiletext);
#
# determine OS on which we are running
#
my $os_platform  = "$^O";
if ($os_platform =~ m|mswin|i) { 
	$WL_DelRM       = "del ";
	$os_platform_id = 1;
} else {
	$WL_DelRM       = "\\rm "; 
	$os_platform_id = 0;
}

#
# start time
#
  $start_tm = gettimeofday;

  $clean     = 1;    # clean is now default
  $ignore_QA = 0;
  $no_red    = 0;
  $direc     = "./";
  $ltyp      = "";
 #
 # determine number of command line arguments
 #
  my $num_of_args = @ARGV;
  print "Num arg ($num_of_args)\n";
  if ($num_of_args > 0) {
	for ($i = 0; $i < $num_of_args; $i++) {
		if ($i == 0 && $ARGV[0] !~ m/(clean|noqa|nored)/i ) {
			$direc = $ARGV[0];
			print "--> direct  : $direc\n";
		}
		$clean = 1;
		if (lc $ARGV[$i] eq "noclean" && $clean) {
			$ltyp  .= "noclean-";
			$clean  = 0;
			print "--> noclean   : $clean\n";
		}
		if (lc $ARGV[$i] eq "noqa" && !$ignore_QA) {
			$ignore_QA = 1;
			$ltyp  .= "no_qa-";
			print "--> no QA   : $ignore_QA\n";
		}
		if (lc $ARGV[$i] eq "nored" && !$no_red) {
			$no_red = 1;
			$ltyp  .= "no_red-";
			print "--> no REDs : $no_red\n";
		}
	}
  }
  if (!$clean && !$no_red && !$ignore_QA) {
	$ltyp    = "all-";
  }
  print "reading pdfs from directory: $direc\n";
#  print " Type $ltyp\n";
#
# open 'page_per_paper.txt' and read pdf filenames and number of pages
#
  (my $pppfile = "$direc"."pages_per_paper.txt") =~ s|\.\.|\.|;
  open (PPPIN, "<$pppfile") or die ("Cannot open '$pppfile' -- $!\n");
  print "reading #pages from: '$pppfile'\n";
  my $j=0;
  my $fpen = "";
  while (<PPPIN>) {
	  chomp;
#	  print " $j: $_\n";
	  if (!m|#|) {
		  $j++;
		  ($abs_id[$j], $fileentry[$j], $fpen) = split (/=/);
		  ($filepages[$j], $paper_editor[$j], $qa_editor[$j],  $paper_status[$j]) = split (/;/, $fpen);
		  print sprintf (" [%4i] %4i=%10s ==> %2i (Edi: %s  QA: %s  Status: %s)\n", 
						 $j, $abs_id[$j], $fileentry[$j], $filepages[$j], $paper_editor[$j], $qa_editor[$j], $paper_status[$j]);
	  } else {
#		print "line $_\n";
		  #
		  # Read server name and Up Pass Phrase: #Serv=https://appora.fnal.gov/pls/ipac15/;Up=Uws5DCwFwvnwQJnJGSUevsNU;
		  #
		  if (m|Serv=(.*?);Up=(.*?);|) {
				print "Serv: $1\n";
#				print "Pass: $2\n";
			  $conference_SPMS  = $1;
			  $PassUp			= $2;
		  } else {
			  warn;
		  }
	  }
  }
  $num_of_papers = $j;
  close(PPPIN);

  print sprintf ("#### %6.2f [s] ### end of data file read\n", gettimeofday-$start_tm);
#
# prepare file 'spms_corr_pages.bat' for command line correction of the number of PDF pages
#
#  format   <..... SPMS URL ..................>editor.set_page_count?up_passphrase=<....Pass Phrase Up....>&abs_id0<id>&pcount0<p>
#  example  https://appora.fnal.gov/pls/ipac15/editor.set_page_count?up_passphrase=Uws5DCwFwvnwQJnJGSUevsNU&abs_id=2103&pcount=3
#
  (my $corr_pages = "$direc"."spms_corr_pages.bat") =~ s|\.\.|\.|;
  open (CORP, ">$corr_pages") or die ("Cannot open '$corr_pages' -- $!\n");
  print "writing page corrections to: '$corr_pages'\n";

#
  (my $sec, my $min, my $hour, my $mday, my $mon, my $year, my $wday, my $yday, my $isdst) = localtime(time);
  my $ltim = sprintf("%04d%02d%02d-%02d%02d", $year+1900, $mon+1, $mday, $hour, $min);
  $out = "pagecheck-result_".$ltyp.$ltim.".txt";
  open (PAGCHK, ">$out") or die " cannot open '$out' -- error: $!\n";

  for ($paper = 1; $paper <= $num_of_papers; $paper++) {

    $pdffile = $fileentry[$paper].".pdf";
	print sprintf  (" checking %10s", $pdffile);

	$print_lines = -1;  # reset number of lines to print
    if (-e $pdffile) {
		if (-z $pdffile) {
			$pr_lines[++$print_lines] = sprintf  (" %10s ======> empty pdf file\n", $fileentry[$paper]);
			next;
        }
#
# check PDF for number of pages/Page size/PDF version (new in v 6.1)
#
		my $info_file = $fileentry[$paper]."-t.txt";
		$command = sprintf ("pdftk %s dump_data output %s", $pdffile, $info_file);
		system ($command);

		open (KIN, "$info_file") or die " cannot open '$info_file' -- error: $!\n";
		undef @cropboxlist;
		undef @mediaboxlist;
		while (<KIN>) {
			chomp;
            if (m|NumberOfPages:\s*(.*?)$|) {
                $pages_fnd[$paper] = $1;
				$pr_lines[++$print_lines] = sprintf  (" %10s   Editor: %s\n", $fileentry[$paper], $paper_editor[$paper]);
				my $qa_stat = $qa_editor[$paper] ne "";
				if ($paper_status[$paper] ne "") {
					if ($paper_status[$paper] eq "Red") {
						$pr_lines[++$print_lines] = sprintf  ("            # Status  %s\n", $paper_status[$paper]);
					} else {
						 $pr_lines[++$print_lines] = sprintf  ("              Status  %s\n", $paper_status[$paper]);
					}
				} 
				if ($qa_stat) {
					$pr_lines[++$print_lines] = sprintf  ("              QA by   %s\n", $qa_editor[$paper]);
				} else {
					if ($paper_status[$paper] eq "Green") {
						 $pr_lines[++$print_lines] = sprintf  ("            # missing QA\n");
					}
				}
                if ($filepages[$paper] == $pages_fnd[$paper]) {
#					 $pr_lines[++$print_lines] = sprintf  ("              page count ok (%2i pages)\n", $pages_fnd[$paper]);
                } else {
					if ($qa_stat) {
#						 $pr_lines[++$print_lines] = sprintf  ("            # spms:%2i, file:%2i pages\n", $filepages[$paper], $pages_fnd[$paper]);
#> curl					 print CORP sprintf ("wget --spider --no-check-certificate \"%s%s%s%s%i%s%i\"\n", 
						 print CORP sprintf ("curl --ssl-no-revoke --head \"%s%s%s%s%i%s%i\"\n", 
									 $conference_SPMS, "editor.set_page_count?up_passphrase=", $PassUp, 
									 "&abs_id=", $abs_id[$paper], "&pcount=", $pages_fnd[$paper]);
					}
                }
            }
			#
			# PageMediaRect: 0 0 595 792
			# PageMediaCropRect: 0 0 595.22 842
			#
			if (m|PageMediaRect: (.*?)$|ig) { push @mediaboxlist, $1; } 
			if (m|PageMediaCropRect: (.*?)$|ig)  { push @cropboxlist,  $1; } 

			
			
            if (m|PDF version:\s*(.*?)$|) {
               my $version = $1;
                if ($version > 1.6) {
					 $pr_lines[++$print_lines] = sprintf  ("            # conflict with JACoW pdf version (v %3.1f)\n", $version);
                }
           }
        }
        close (KIN);
#
# check PDF for PDF version (rest of pre v6.0 versions)
#
		$info_file = $fileentry[$paper]."-i.txt";
		$command = sprintf ("pdfinfo -box %s >$info_file", $pdffile);
		system ($command);

		open (KIN, "$info_file") or die " cannot open '$info_file' -- error: $!\n";
		while (<KIN>) {
			chomp;
            if (m|PDF version:\s*(.*?)$|) {
               my $version = $1;
                if ($version > 1.6) {
					 $pr_lines[++$print_lines] = sprintf  ("            # conflict with JACoW pdf version (v %3.1f)\n", $version);
                }
           }
        }
        close (KIN);
#
# check the range of values for /Crop boxes (new in v. 6.0)
# 
		if (defined $cropboxlist[0] and $#cropboxlist ge 0) {
			my $minurxC = 1e10;
			my $maxurxC = 0;
			my $minuryC = 1e10;
			my $maxuryC = 0;
			for ($i=0; $i<$#cropboxlist+1; $i++) {
				($llx, $lly, $urx, $ury) = split (/ /, $cropboxlist[$i]);
				if ($minurxC > $urx) {$minurxC = $urx; }
				if ($maxurxC < $urx) {$maxurxC = $urx; }
				if ($minuryC > $ury) {$minuryC = $ury; }
				if ($maxuryC < $ury) {$maxuryC = $ury; }
			}
			my $pag_widC;
			my $pag_hgtC;
			if ($minurxC eq $maxurxC) {		# only one page width
				$pag_widC = int($minurxC);
			} else {						# page width range
				$pag_widC = -1;
			}
			if ($minuryC eq $maxuryC) { 	# only one page height
				$pag_hgtC = int($minuryC);
			} else {						# page height range
				$pag_hgtC = -1;
			}

			if ($pag_widC < 0 or $pag_hgtC < 0) {
				$pr_lines[++$print_lines] = sprintf  ("            # PDF not correctly cropped - %i CropBoxes with ranges: '%i x %i - %i x %i'\n",
	#			print sprintf  ("            # PDF not correctly cropped - %i CropBoxes with ranges: '%i x %i - %i x %i'\n",
													$#cropboxlist+1, int($minurxC), int($minuryC), int($maxurxC), int($maxuryC));
			} else {
				if (($pag_widC < 592 or $pag_widC > 597)  or 
					($pag_hgtC < 789 or $pag_hgtC > 794)) {
					$pr_lines[++$print_lines] = sprintf  ("            # PDF not correctly cropped: CropBox outside JACoW page size: '%i x %i'\n",
	#				print sprintf  ("            # PDF not correctly cropped: CropBox outside JACoW page size: '%i x %i'\n",
														$pag_widC, $pag_hgtC);
				}
			}
		}
#
# check the range of values for /Media boxes
#
		if ($#mediaboxlist ge 0) {
			my $minurxM = 1e10;
			my $maxurxM = 0;
			my $minuryM = 1e10;
			my $maxuryM = 0;
			for ($i=0; $i<$#mediaboxlist+1; $i++) {
				($llx, $lly, $urx, $ury) = split (/ /, $mediaboxlist[$i]);
#				print " >$mediaboxlist[$i]< lly:$llx:, lly:$lly:, urx:$urx:, ury:$ury:\n";
				if ($minurxM > $urx) {$minurxM = $urx; }
				if ($maxurxM < $urx) {$maxurxM = $urx; }
				if ($minuryM > $ury) {$minuryM = $ury; }
				if ($maxuryM < $ury) {$maxuryM = $ury; }
			}
			my $pag_widM;
			my $pag_hgtM;
			if ($minurxM eq $maxurxM) {		# only one page width
				$pag_widM = int($minurxM);
			} else {						# page width range
				$pag_widM = -1;
			}
			if ($minuryM eq $maxuryM) { 	# only one page height
				$pag_hgtM = int($minuryM);
			} else {						# page height range
				$pag_hgtM = -1;
			}

			if ($pag_widM < 0 or $pag_hgtM < 0) {
				$pr_lines[++$print_lines] = sprintf  ("            # PDF not correctly cropped - %i MediaBoxes with ranges: '%i x %i - %i x %i'\n",
		#		print sprintf  ("            # PDF not correctly cropped - %i MediaBoxes with ranges: '%i x %i - %i x %i'\n",
													$#mediaboxlist+1, int($minurxM), int($minuryM), int($maxurxM), int($maxuryM));
			} else {
				if (($pag_widM < 592 or $pag_widM > 597)  or 
					($pag_hgtM < 789 or $pag_hgtM > 794)) {
					$pr_lines[++$print_lines] = sprintf  ("            # PDF not correctly cropped: MediaBox outside JACoW page size: '%i x %i'\n",
		#			print sprintf  ("            # problem with MediaBox outside JACoW page size: '%i x %i'\n",
														$pag_widM, $pag_hgtM);
				}
			}
		}
#
# if both counts are <0 the PDF is probably compressed and doesn't allow checking
#
		if ($#mediaboxlist < 0 and $#mediaboxlist < 0) {
					$pr_lines[++$print_lines] = sprintf  ("            # problem to determine CropBox and MediaBox as PDF is obviously COMPRESSED. \n");
					$pr_lines[++$print_lines] = sprintf  ("            # Use Acrobat's \"save over\"/\"export\" as optimized PDF with \"Clean Up setting\" -> \"remove compression\" and try again.\n");
		}

#
# now check fonts: not embedded? (Type 3 not problematic anymore)
#					errors are rewritten to $font_file, but not checked
#
		my $font_file = $fileentry[$paper]."-f.txt";
        $command = sprintf ("pdffonts %s >$font_file 2>&1", $pdffile);
        my $sys_exi = system ($command);
		

        open (KIN, "<$font_file") or die " cannot open '$font_file' -- error: $!\n";
		my $first_Type3 = 1;
		my $numfnt      = 0;
        while (<KIN>) {
            chomp;
			#
			# ignore the error messages
			#
			if (index ($_, "Error:") > 0) { next; }
			if (index ($_, "Warning:") > 0) { next; }
			if (index ($_, "   ") eq 0) { next; } 		# wrapped lines due to inline error messages

            $f_name   = substr ($_,  0, 36);
            $f_name   =~ s/ //g;
            $f_type   = substr ($_, 37, 17);
            $f_type   =~ s/ //g;
            $f_emb    = substr ($_, 55,  3);
            $f_emb    =~ s/ //g;
            $f_sub    = substr ($_, 59,  3);
            $f_sub    =~ s/ //g;
            $f_uni    = substr ($_, 63,  3);
            $f_uni    =~ s/ //g;
            $f_object = substr ($_, 67,  6);
            $f_object =~ s/ //g;
            $f_id     = substr ($_, 74,  2);
            $f_id     =~ s/ //g;
			#
			# increment font counter (if not Type3)
			#
			if ($f_type ne "Type3" && $paper_status[$paper] ne "Red") {
				$numfnt++;
			}
			
            @font_names = split (/\+/, $f_name);
            if ($f_name =~ m|\+|) {
                $font_name = $font_names[1];
            } else {
                $font_name = $font_names[0];
            }
            $f_name = $font_name;

            if ($f_emb eq "emb" or
                $f_emb eq  "---") { next; }

#             print "-----\nname:   $f_name\ntype:   $f_type\nemb:    $f_emb\nsub:    $f_sub\n";

			if ($paper_status[$paper] ne "Red") {
				if ($f_emb eq "no" && $f_type ne "Type3") {
	#                 print " font \"$f_name\" type \"$f_type\" not embedded\n";
					 $pr_lines[++$print_lines] = sprintf  (" %8s # font \"%s\" type \"%s\" not embedded\n", "          ", $f_name, $f_type);
				}
				if ($first_Type3) {
					if ($f_type eq "Type3") {
						$first_Type3 = 0;
	#	#                 print "   font \"$f_name\" used as object with id \"$f_object\" is a \"$f_type\" font\n";
	#					print PAGCHK sprintf  (" %8s   font \"%s\" used as object with id \"%s\" is a \"%s\" font\n", 
	#										   "          ", $f_name, $f_object, $f_type);
#						 $pr_lines[++$print_lines] = sprintf   ("            o Type_3 font(s) detected\n");
					}
				}
			}
        }
		#
		# more than 70 fonts are probably problematic
		#
		if ($numfnt > 50) {
			$pr_lines[++$print_lines] = sprintf  ("            # #fonts  %i\n", $numfnt);
		}
        close (KIN);

#        $command = sprintf ("$WL_DelRM ppp.tmp");
#        system ($command);
    } else {
		 $pr_lines[++$print_lines] = sprintf  (" %10s   file not found\n", $fileentry[$paper]);
    }
	#
	# print "clean" or "complete" [Default] version of paper message
	#
	my $lsta  = "";
	if ($clean) {
		$iline    = -1;
		$is_clean =  1;
		while ($is_clean && ++$iline <= $print_lines) {
			if ($ignore_QA && $pr_lines[$iline] =~ m/# missing QA/ ||
			    $no_red    && $pr_lines[$iline] =~ m/# Status  Red/) {
				# skip it, still clean
				next;
			}
			if ($pr_lines[$iline] =~ m/#/) {
				$is_clean = 0;
			}
		}

		if ($is_clean) {
#			print " dropped $pr_lines[0]\n";
			print " => OK\n";
			next;
		} else {
			#
			# print
			#
			for ($iline = 0; $iline <= $print_lines; $iline++) {
				if ($ignore_QA && $pr_lines[$iline] =~ m/# missing QA/ ||
			        $no_red    && $pr_lines[$iline] =~ m/# Status  Red/) {
					#
					# skip the "missing QA" message
					#
				} else {
					print PAGCHK $pr_lines[$iline];
				}
			}
			print " => error\n";
		}
	} else {
		#
		# print
		#
		for ($iline = 0; $iline <= $print_lines; $iline++) {
			print PAGCHK $pr_lines[$iline];
		}
		print "\n";
	}
  }
  close (PAGCHK);
  print sprintf ("\n#### %6.2f [s] ### end of pdf file check\n", gettimeofday-$start_tm);
  close (CORP);
  if ($os_platform_id == 0) {
	# BAT
	system ("chmod a=r+w+x $direc"."spms_corr_pages.bat");
  }

exit;
sub read_pdf {
	use vars qw ($pdftext);
	if (open (PDF, "<", $pdffile)) {
#		print "pdf file $pdffile opened\n";
	} else {
		print "pdf Cannot open '$pdffile' -- $! (line ",__LINE__,")\n";
	}
	binmode (PDF);
	$pdffiletext = "";
	while (<PDF>) {
		$pdffiletext .= $_;
		next unless length;     # anything left?
	}
	close (PDF);
#		print "pdf ---> Länge: ".length($pdffiletext)."\n";
	return $pdftext;
}