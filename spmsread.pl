#!perl -W
#   spmsread.pl    $Version 6.0 of 05 November 2017 - Volker RW Schaa
#
#   Script to read the session summary xml ("spms_summary.xml") for SPMS
#   sites where reading the full "spms.xml" poses a too big resources
#   problem (as it was experienced for PAC07 with 1800 abstracts).
#
#   Copyright (C) 2007-2016 Gesellschaft fuer Schwerionenforschung mbH
#   <http://www.gsi.de> by Volker RW Schaa (v.r.w.schaa at gsi.de)
#
#   Utility for the JACoW SPMS/JPSP
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
# the script "spmsread.pl"
# 0) needs the following inputs
#    "spms_summary.xml"  has to be already downloaded from the SPMS site
#                        with "wget http://<your SPMS site>/spms_summary.xml
#    and the SPMS site address
#    "http://<your SPMS site>/"
#                        from where to download the session xml files
#
# 1) reads the file "spms_summary.xml"
#    which contains a list of sessions in the form
#      <conference xmlns:xsi="....
#        <session>
#           <name abbr="MOXKI">Plenary Opening</name>
#        </session>
#        <session>
#           <name abbr="MOYKI">Plenary Opening</name>
#        </session>
#        <session>
#           <name abbr="MOZAKI">LEAC:  Lepton Accelerators and Colliders</name>
#        </session>
#        <more sessions>
#      </conference>
#
# 2) produces a full 'spms.xml' file by reading the corresponding session
#    xml files from each single session with the name contained in the
#    abbreviation <name abbr="MOXKI">...</name>. For each single session
#    the function "wget http://<your SPMS site>/xml2.session_data?sid=<session-id>"
#    is called, the file loaded, read, and added to the file 'spms.xml'
#
#
#    v0.1  14. May 2007  volker rw schaa
#    v0.5  17. May 2007  volker rw schaa   put all xml files into xml subdirectory
#    v0.6  
#    v1.0   5. Apr 2009  volker rw schaa   code added for an XML file for pre-session run of spmsbatch.pl 
#    v1.1  25. May 2009  volker rw schaa   changes to wget due to CERN's security policy (--no-check-certificate)
#    v1.2  14. Aug 2009  volker rw schaa   adapted to configuration file changes (protocol/debug file)
#    v1.3  11  Apr 2011  volker rw schaa   - identification string built in
#                                          - try to resolve SPMS base address
#          12 Apr 2011   volker rw schaa   - version of 11 Apr distributed to Thomas Thuillier didn't include the 
#    v1.4  10 May 2011   volker rw schaa   - version v1.3 failed for some url in function lastindex, now fixed using regex
#    v1.5  15 Jun 2011   volker rw schaa   - <session> string generated for Pre-Session setup corrected and <location> adapted to color setting
#    v1.6   1 Dec 2011   volker rw schaa   - one <abstract> line is missing in final spms.xml, reason seems to be unescaped "?" in m|<?xml| as abstract line contains "xml"
#    v2.0  30 Jul 2012   volker rw schaa   - url of SPMS now in config file
#    v3.0  11 Aug 2012   volker rw schaa   - introduced all Secret Phase Phrases in config file after discussions with Matt and Ivan ($PassPhraseExtract is used here)
#    v3.1                                  # pass phrase "$PassPhraseExtract" commented out
#    v3.2  18 Jun 2013   volker rw schaa   - parameter "no_summary" introduced to skip the download of a new spms_summary.xml to be
#                                            able to reuse the old (or edited) one
#    v3.3  14 Sep 2013   volker rw schaa   - protocol of dropped lines now in directory "$protocol_directory", file name droppedl-spmsread.txt
#    v3.4  01 Feb 2014   volker rw schaa   - problems with RE for SPMS url as Matt's TM2013 is just named pls/tm/
#    v3.5  25 Mar 2014   volker rw schaa   - extended RE for SPMS urls which are used for debug (pls/jacow_...) so it has not to be pasted as argument
#    v3.6  08 Apr 2016   volker rw schaa   - download session XMLs when "clean" is defined as argument
#    v4.0  05 May 2016   volker rw schaa   - inclusion of status file (pages_per_paper.txt) and whitelist for papers checked for not being corructed
#										   - now the name of the editor, the status (RED, YELLOW, GREEN) and WHITELISTED will be output in the broken paper list
#    v4.1  21 Aug 2016   volker rw schaa   - change in procedure name (Matt had to rename "SESSION" to "SESSION_DATA" as "SESSION" is now a reserved word by Oracle and may not be used)
#    v5.0  15 Apr 2017   volker rw schaa   - first check whether there are page counts to be updated (spms_corr_pages.bat has them) then read the (updated) XML
#    v6.0  05 Nov 2017   volker rw schaa   - cURL introduced; all wget calls are now serviced by curl as it is less chatty while working (see edit key #curl)
#
 use Carp;
 use Time::HiRes  qw(gettimeofday);
 use File::Basename;
 use Time::localtime;
 use strict;
 no strict 'refs';

 use vars qw ($start_tm $stop_tm $session_arg $url $conference_spms_url $session_xml $paper_arg $paper_xml);
 use vars qw ($spms_xml $cp_spms_xml $mtime $tm $fm $ft $no_sessions $papers_only);
 use vars qw ($xml_directory $conference_xmlfile $content_directory $paper_directory $raw_paper_directory $protocol_directory $conference_SPMS);
 use vars qw ($PassPhraseDown $PassPhraseUp $PassPhraseExtract);
 use vars qw ($VersionStr $pc $abslen $numArgs $argnum $no_summary_read $clean);
 
 $no_sessions		= 1;
 $clean				= 0;
 $no_summary_read	= 0;
 $VersionStr		= " 6.0 of 05 Nov 2017 - vrws";
#
# start time
#
$start_tm = gettimeofday;
#
# test for command lines arguments
#
$numArgs = $#ARGV + 1;
print "I found $numArgs command-line argument(s).\n";
foreach $argnum (0 .. $#ARGV) {
	if (lc $ARGV[$argnum] eq "no_summary") {
		$no_summary_read = 1;
    } elsif (lc $ARGV[$argnum] eq "clean") {
		$clean	= 1;
	}
	print "$ARGV[$argnum]\n";
}
#
# now read the config file
#
if (open (CONFIG, "<conference.config")) {
    print "\n This is version $VersionStr\n";
    print " config file 'conference.config' found!\n";
    while (<CONFIG>) {
        chomp;                  # no newline
        s/(^#|[^&]#).*//;       # no comments
        s/^\s+//;               # no leading white
        s/\s+$//;               # no trailing white
        next unless length;     # anything left?
        my ($var, $value) = split(/\s*=\s*/, $_, 2);
        $$var = $value;
    }
} else {
    croak " no config file \"conference.config\" found on line $.\n";
}
if (!defined $conference_SPMS) {
	#
	# script should abbreviate standard url arguments from Oracle PLS sites (as of v1.3)
	#
	#     http://appora.fnal.gov/pls/pac07_debug                          => http://appora.fnal.gov/pls/pac07
	#     https://oraweb.cern.ch/pls/dipac2011/rpt_user_dot_reassign.html => https://oraweb.cern.ch/pls/dipac2011
	#
	$url = $ARGV[0];
} else {
	$url = $conference_SPMS;
}
#
# distinguish between funny named Team Meetings (/tm), debug instances (/jacow) and normal conferences
#
if ($url =~ m|pls\/tm.*?|i) {
	$url =~ m|(.*pls\/.*?)\/|i;
	$url = $1;
} elsif ($url =~ m|pls\/jacow.*?|i) {
	$url =~ m|(.*pls\/.*?)\/|i;
	$url = $1;
} else {
	$url =~ m|(.*pls\/.*?(:?\d{2,4})).*|i;
	$url = $1;
}
$conference_spms_url = $url;

if (!$conference_spms_url || $conference_spms_url eq "") {
    croak "\n>>\n>> missing 'http://your_pls_server/' address as argument\n>>\n";
} else {
    print "\n>>\n>> reading from URL: $conference_spms_url\n>>\n\n";
}

if (!defined $protocol_directory) { $protocol_directory = ""; }
#
# read command line argument for config file name (default = config.txt)
#
my $debug_file = $protocol_directory."protocol_spmsread.txt";
open (DBG, ">$debug_file") or die ("Cannot open '$debug_file' -- $!\n");

my $fmt = " %24s = %-40s\n";
print DBG sprintf ("%s\n","-"x68);
print DBG sprintf ($fmt,"conference_xmlfile", $conference_xmlfile);
print DBG sprintf ($fmt,"content_directory", $content_directory);
$paper_directory = uc $paper_directory;
print DBG sprintf ($fmt,"paper_directory", $paper_directory);
print DBG sprintf ($fmt,"raw_paper_directory", $raw_paper_directory);
print DBG sprintf ("%s\n","-"x68);
if (!defined $xml_directory) {
    $xml_directory = "";
}
print "\n xml file from config is: '$conference_xmlfile'\n";
#
# Security
#
if (!defined $PassPhraseDown) { $PassPhraseDown = ""; }
print DBG sprintf ($fmt,"Pass Phrase Down    ", $PassPhraseDown);
if (!defined $PassPhraseUp) { $PassPhraseUp = ""; }
print DBG sprintf ($fmt,"Pass Phrase Up      ", $PassPhraseUp);
if (!defined $PassPhraseExtract) { $PassPhraseExtract = ""; }
print DBG sprintf ($fmt,"Pass Phrase Extract ", $PassPhraseExtract);

$spms_xml = "$xml_directory$conference_xmlfile";
if (-e $spms_xml) {
    print " File ->$spms_xml<- already exists!\n";
    $mtime    = (stat($spms_xml))[9];
    $tm       = localtime($mtime);
    my($filename, $directories, $suffix) = fileparse($spms_xml);
    ($fm, $ft) = split (/\./, $filename);

    $cp_spms_xml = sprintf ("%-s%-s-%04d%02d%02d-%02d%02d%02d.%-s",
                            $xml_directory,
                            $fm, ($tm->year)+1900, ($tm->mon)+1, $tm->mday,
                                  $tm->hour, $tm->min, $tm->sec,
                            $ft);

    if (-e $cp_spms_xml) {
        croak " Save file ->$cp_spms_xml<- already exist!\n";
    }
    print " File ->$spms_xml<- will be saved as ->$cp_spms_xml<-\n";

    my $command =  sprintf ("copy %-s %-s", $spms_xml, $cp_spms_xml);
       $command =~ s|\/|\\|g;
    system ($command);
} else {
    print " File ->$spms_xml<- is new!\n";
}
#
# read existing or download basic xml file (spms_summary.xml)
#
my $summary_xml = "$xml_directory"."spms_summary.xml";
if ($no_summary_read) {
	print " Summary will not be read\n";
} else {
	#
	# download basic xml file (spms_summary.xml)
	#
	#system ("wget --no-check-certificate -O $summary_xml $conference_spms_url/spms_summary.xml&hcheck=$PassPhraseExtract");
#curl	system ("wget --no-check-certificate -O $summary_xml $conference_spms_url/spms_summary.xml");
	system ("curl -k -o $summary_xml $conference_spms_url/spms_summary.xml");
	if ($? >> 8 == 1) {
		print " file not found: $!\n";
		exit;
	}
}
#
# now read the basic xml file
#
#print "line 243\n";
open (BASE, "<$summary_xml") or croak " basic spms file '$summary_xml< not found on line $.\n";
#print "line 245\n";
print "\n basic spms file '$summary_xml' found!\n";

open (SPMS, ">$spms_xml") or croak " cannot open spms output file '$spms_xml' on line $.\n";
my $prot = $protocol_directory."dropped-spmsread.txt";
open (DROP, ">$prot") or croak ("Cannot open '$prot' -- $!\n");

$papers_only     = 0;

while (<BASE>) {
#    chomp ($_);
    #
    # tag "<?xml "
    #
    if (m|<?xml |) {
        print SPMS ("$_");
        next;
    }
    #
    # tag "<conference" and "</conference>"
    #
    if (m|<conference | or
        m|</conference>|) {
        if (m|</conference>|) {
            if ($papers_only) {
                print SPMS ("</session>\n");
                $papers_only = 0;
            }
        }
        print SPMS ("$_\n");
        next;
    }
    #
    # tag "<session>" from "spms_summary.xml" will be dropped
    #
    if (m|<session>| or
        m|</session>|) {
        print DROP ("    $_");
        next;
    }
    #
    # tag: <name abbr="...">session name</name>
    #
    if (m|<name abbr="(.*?)">|) {
        $session_arg = $1;
        $session_xml = "$xml_directory$session_arg.xml";
        if (-e $session_xml && !$clean) {   # read session with present XML only when clean is defined
            print (" xml file for session $session_arg already exists\n");
        } else {
            print (" -----------> loading xml file for session $session_arg\n");
#           system ("wget --no-check-certificate -O $session_xml \"$conference_spms_url/xml2.session_data?sid=$session_arg&hcheck=$PassPhraseExtract\"");
#>curl		system ("wget --no-check-certificate -O $session_xml \"$conference_spms_url/xml2.session_data?sid=$session_arg\"");
            system ("curl -k -o $session_xml \"$conference_spms_url/xml2.session_data?sid=$session_arg\"");
        }
        add_session_xml ();
        next;
    }
    #
    # tag "<paper" and "</paper>"
    #
    if (m|<paper>|) {
        if ($no_sessions) {
            print SPMS ("<session>\n  <name abbr=\"Pre-Session\">Conference Pre-Session Setup</name>\n  <location type=\"Poster\">everywhere</location>\n");
            $no_sessions = 0;
            $papers_only = 1;
        }            
        print DROP ("+>> $_\n");
        next;
    }
    #
    # tag: <abstract_id>1182</abstract_id>
    #
    if (m|<abstract_id>(.*?)</abstract_id>|) {
        $paper_arg = $1;
        $paper_xml = "$xml_directory$paper_arg.xml";
        if (-e $paper_xml) {
            print (" xml file for paper $paper_arg already exists\n");
        } else {
            print (" loading xml file for paper $paper_arg\n");
#           system ("wget --no-check-certificate -O $paper_xml \"$conference_spms_url/xml2.paper?aid=$paper_arg&hcheck=$PassPhraseExtract\"");
#>curl		system ("wget --no-check-certificate -O $paper_xml \"$conference_spms_url/xml2.paper?aid=$paper_arg\"");
            system ("curl -k -o $paper_xml \"$conference_spms_url/xml2.paper?aid=$paper_arg\"");
        }
        add_paper_xml ();
        next;
    }
    #
    # unknown tag
    #
    print DROP ("?>> $_\n");
}
close (DROP);
close (SPMS);
close (BASE);

#
# stop time
#
$stop_tm = gettimeofday;
print sprintf ("\n\n elapsed time: %.2f [s]\n", $stop_tm-$start_tm);

exit;

#-----------------------
sub add_session_xml {

    open (XML, "<$session_xml") or croak " session xml file '$session_xml' not found on line $.\n";
    
#    my $ctr = 0;
    $pc = "";
    while (<XML>) {
#        chomp ($_);
#        $ctr++;
#        print DROP sprintf ("[%6.0d]=> %s", $ctr, $_);
        #
        # tag "<?xml "
        #
        if (m|<\?xml |) {
            next;
        }
        #
        # tag "<conference" and "</conference>"
        #
#        print DROP sprintf ("[%6.0d]=> %s", $ctr, $_);
        if (m|<conference | or
            m|</conference>|) {
            next;
        }
        #
        # tag "<code>MOPxxxxx</code>"
        #
#        print DROP sprintf ("[%6.0d]=> %s", $ctr, $_);
        if (m|<code>\s*(.*?)</code>|) {
            $pc = uc $1;
            print DROP sprintf ("[%-s]\n", $pc);
        }
        #
        # tag "<abstract>" and "</abstract>"
        #
        if (m|<abstract>|) {
            $abslen = length($_) - 21;
            print DROP sprintf ("[%-s]=%4.0d> %s", $pc, $abslen, $_);
        }
        #
        # write line to spms.xml
        #
        print SPMS ("$_");
    }
    close (XML);
    return;
}
#-----------------------
sub add_paper_xml {

    open (XML, "<$paper_xml") or croak " paper xml file '$paper_xml' not found on line $.\n";

    while (<XML>) {
#        chomp ($_);
        #
        # tag "<?xml "
        #
        if (m|<\?xml |) {
            next;
        }
        #
        # tag "<conference" and "</conference>"
        #
        if (m|<conference | or
            m|</conference>|) {
            next;
        }
        #
        # write line to spms.xml
        #
        print SPMS ("$_");
    }
    close (XML);
    return;
}
