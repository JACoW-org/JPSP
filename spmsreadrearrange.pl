#!perl -W "JACoW Proceedings Script Package-JPSP"
#   spmsreadrearrange.pl    $Version 0.1 10-04-10  Volker RW Schaa
#
#   Script to read the session summary xml ("spms_summary.xml") for SPMS
#   sites where reading the full "spms.xml" poses a too big resources
#   problem (as it was experienced for PAC07 with 1800 abstracts).
#
#   Copyright (C) 2010 Gesellschaft fuer Schwerionenforschung mbH
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
# the script "spmsreadrearrange.pl"
# 0) needs the following inputs
#    "spms_summary.xml"  has to be already downloaded from the SPMS site
#                        with "wget http://<your SPMS site>/spms_summary.xml
#    "<session-id>.xml"  for each and every session which is named in
#                        "spms_summary.xml"
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
# 2) produces a full 'spms-rearrange.xml' file by reading "spms_summary.xml"
#    twice, in the first scan it will skip all sessions which contain "poster"
#    in the value of the <name> tag. All other session xml files from each single 
#    session with the name contained in the abbreviation <name abbr="MOXKI">...</name>
#    are copied into 'spms-rearrange.xml'. In the second reading only sessions
#    containing "poster" in the <name> tag will be added to 'spms-rearrange.xml'.
#
#    v0.1  10. Apr 2010  volker rw schaa
#
 use Carp;
 use File::Basename;
 use strict;
 no strict 'refs';

 use vars qw ($session_arg $session_xml $paper_arg $paper_xml);
 use vars qw ($spms_rear_xml $cp_spms_xml $mtime $tm $fm $ft $no_sessions $papers_only);
 use vars qw ($xml_directory $conference_xmlfile);

 $papers_only = 0;   # pre-session mode
 $no_sessions = 1;

#
# now read the config file
#
if (open (CONFIG, "<conference.config")) {
    print "\n config file 'conference.config' found!\n";
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
    croak " no config file 'conference.config' found on line $.\n";
}

#
# read command line argument for config file name (default = config.txt)
#
my $fmt = " %24s = %-40s\n";
#print DBG sprintf ("%s\n","-"x68);
#print DBG sprintf ($fmt,"conference_xmlfile", $conference_xmlfile);
#print DBG sprintf ("%s\n","-"x68);
if (!defined $xml_directory) {
    $xml_directory = "";
}
print "\n xml file from config is: '$conference_xmlfile'\n";

$spms_rear_xml = "$xml_directory$conference_xmlfile";
my $dot_pos    = index ($spms_rear_xml, '.xml');
print " $dot_pos, $spms_rear_xml\n";
if ($dot_pos == -1) {
    print " shouldn't happen: 'no .xml' in filename\n";
    exit;
} else {
    substr ($spms_rear_xml, $dot_pos, 1, "-rearrange.");
    print " output file: $spms_rear_xml\n";
}

#
# use basic xml file (spms_summary.xml)
#
my $summary_xml = "$xml_directory"."spms_summary.xml";
if ($? >> 8 == 1) {
    print " file not found: $!\n";
    exit;
}

#
# now read the basic xml file
#

open (SPMS, ">$spms_rear_xml") or croak " cannot open spms output file '$spms_rear_xml' on line $.\n";
open (DROP, ">droppedl-spms.txt") or croak ("Cannot open 'droppedl-spms.txt' -- $!\n");
print "---\n";

my $pass;
for ($pass=1; $pass<=2; $pass++) {
    open (BASE, "<$summary_xml") or croak " basic spms file '$summary_xml< not found on line $.\n";
    print "\n $pass -- basic spms file '$summary_xml' found!\n";

    while (<BASE>) {
        chomp ($_);
#        print "$_\n";
        #
        # tag "<?xml "
        #
        if ($pass == 1) {
            if (m|<?xml |) {
                print SPMS ("$_\n");
                next;
            }
        }
        #
        # tag "<conference" and "</conference>"
        #
        if ($pass == 1) {
            if (m|<conference |) {
                print SPMS ("$_\n");
                next;
            }
        } else {
            if (m|</conference>|) {
                print SPMS ("$_\n");
                next;
            }
        }
        #
        # tag "<session>"
        #
        if (m|<session>| or
            m|</session>|) {
            print DROP ("    $_\n");
            next;
        }
        #
        # tag: <name abbr="...">session name</name>
        #
        if (m|<name abbr="(.*?)">(.*?)</name>|) {
            $session_arg  = $1;
            $session_xml = "$xml_directory$session_arg.xml";
#            print "Session => '$session_arg'\n";
            my $post_sess;
            $post_sess    = index (lc $2, 'poster');
#            print "Poster  => '$post_sess'\n";
            if ($pass == 1) {
                if ($post_sess == -1) {
                    print " including '$_'\n";
                    if (!-e $session_xml) {
                        print (" xml file for session $session_arg does not exists\n");
                        exit;
                    }
                    add_session_xml ();
                    next;
                }
            } else {
                if ($post_sess >= 0) {
                    print " including '$_'\n";
                    if (!-e $session_xml) {
                        print (" xml file for session $session_arg does not exists\n");
                        exit;
                    }
                    add_session_xml ();
                    next;
                }
            }
        }
        #
        # unknown tag
        #
        print DROP ("?>> $_\n");
    }
    close (BASE);
}

close (DROP);
close (SPMS);

exit;

#-----------------------
sub add_session_xml {

    open (XML, "<$session_xml") or croak " session xml file '$session_xml' not found on line $.\n";

    while (<XML>) {
        chomp ($_);
        #
        # tag "<?xml "
        #
        if (m|<?xml |) {
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
        print SPMS ("$_\n");
    }
    close (XML);
    return;
}

