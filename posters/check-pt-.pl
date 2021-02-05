#! perl -W
#   check-pt.pl    $Version 0.6      Volker RW Schaa
#   Script to check whether authors have uploaded correct PDFs for their 
#   poster or talk contribution
#
#   Copyright (C) 2013-2014 Gesellschaft fuer Schwerionenforschung mbH
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
#   - scans the local directory searches for PDF
#     files (<paper_code>_poster.pdf or <paper_code>_talk.pdf)
#   - extracts information by running "pdfinfo" on the pdf file
#   - warns if the PDF
#        Posters: has more than one page and a page size below A3
#        Talks:   only few pages (<5) or a wrong page size
#
#  1) uses the following utility: pdfinfo
#  2) has to be started in the $poster_directory or $talk_directory
#
#    v0.1  14 Sep 2013  volker rw schaa  first try (not distributed)
#    v0.2  02 Feb 2014  volker rw schaa  check for number of pages
#    v0.3     May 2014  volker rw schaa  posters might be oriented horizontally (exchange h+v)
#    v0.4  12 Jul 2014  volker rw schaa  usable version (not yet distributed)
#    v0.5  15 Nov 2014  volker rw schaa  - extended to check poster and talk contributions
#                                        - name changed to check-pt.pl
#    v0.6  29 Sep 2015  volker rw schaa  - OS_platform is detect inside all scripts (therefore removed from config file)
#
  use strict "vars";
  use File::Basename;
  use File::Find;
  use Time::HiRes  qw(gettimeofday);

  use vars qw (@list $list @entry $entry $direc);
  use vars qw ($fname $base $err);
  use vars qw ($start_tm $stop_tm);
  use vars qw ($out $dbg);
  use vars qw ($pages $i $j);
  use vars qw ($pdffile $kin $outfile $command $page $arg $file $name $type);
  use vars qw ($WL_DelRM);

#
# determine OS on which we are running
#
my $os_platform  = "$^O";
if ($os_platform =~ m|mswin|i) { 
	$WL_DelRM       = "del ";
} else {
	$WL_DelRM       = "\\rm "; 
}

#
# start time
#
	$start_tm = gettimeofday;

	print "--> @ARGV\n";
#
# directory to read
#
	if ($ARGV[0]) {
		$direc = $ARGV[0];
	} else {
		$direc = "./";
	}
	print "reading PDFs from directory: $direc\n";
	#
	# record of Poster file checks
	#
    $out = "pt-check-results.txt";
    open (PAGCHK, ">$out") or die " cannot open '$out' -- error: $! (line __LINE__)\n";
	print PAGCHK sprintf  ("----------------------------\n");

	find (\&search_pt_pdf_file, $direc);

	if ($err == 0) {
		print PAGCHK sprintf  ("----------------------------\n");
	}
	close (PAGCHK);

	exit;
#------------------------------------------------------------
# find all poster/talk pdf files and check for correctness
#
sub search_pt_pdf_file {
#
    $fname = $File::Find::name;
    ($base) = fileparse($fname);
#   print "File: $fname  -- Base: $base\n";

	if ($base =~ m/^([A-Z0-9\-]{1,10})_talk|_poster\.pdf$/i) {   # v0.3
		print "File $base\n";
		check_params ($base);
    }
	return;
}

#------------------------------------------------------------
# check parameters
#    - number of pages for poster = 1!
#    - size is at least A3 (
#
sub check_params {

    use vars qw (%count @count $count $paper_txt);

    my $pdffile = $_[0];
    (my $pt_code) = $pdffile =~ m/^(.*?)(_poster|_talk)\.pdf$/i;
	print ">>> $pt_code <<< $1\n";
	$command = sprintf ("pdfinfo %s >ppp.tmp", $pdffile);
	system ($command);

	$err = 0;
	open (KIN, "<ppp.tmp") or die " cannot open 'ppp.tmp' -- error: $!\n";
	while (<KIN>) {
		chomp;
#---------Pages:          1
		if (m|Pages:\s*(.*?)$|) {
			$pages = int($1);
#			print "PostPag:",uc $pt_code," page: ",$pages,"\n";
			if ($pages > 1) {
				$err++;
				print PAGCHK sprintf  (" %-10s # Poster has %s pages\n", uc $pt_code, $pages);
			} 
		}
#---------Page size:      2383.94 x 3370.39 pts (A0)  for Poster
#---------Page size:      540-768 x 720-1024 pts (A0)  for Poster
		if (m|Page size:\s*(.*?)\s*x\s*(.*?)\s*pts\s*(.*?)$|) { #     595.000 x 791.221 pts
#			print ">>> $1 - $2 - $3\n";
			my $wid  = int($1);
			my $hgt  = int($2);
			my $form = $3;
			#
			# if horizontal orientation: swap height and width
			#
			if ($wid > $hgt) {
				my $mw = $wid;
				$wid   = $hgt;
				$hgt   = $mw;
			}
			#
			# check whether measures make sense for a poster (sizes > A3)   2383.94 x 3370.39
			#
#			print "PostSiz:",uc $pt_code," size: ",$wid," x ",$hgt,"\n";
			if ($wid > 1600 && $hgt > 1900) {
				# perfect
			} else {
				$err++;
				print PAGCHK sprintf  (" %-10s # possibly not a poster! Page size: '%i x %i' %s\n", uc $pt_code, $wid, $hgt, $form);
			}
		} 
	}
	close (KIN);
    $command = sprintf ("$WL_DelRM ppp.tmp");
    system ($command);

#	print "Poster:",uc $pt_code," Err: ",$err,"\n";
	if ($err == 0) {
#+		print PAGCHK sprintf  (" %-10s # OK\n", uc $pt_code);
	} else {
		print PAGCHK sprintf  ("----------------------------\n");
	}
	
	return;
}
