#! perl -W
#   pdf-showfonts.pl    $Version 0.3      Volker RW Schaa
#   Script to list used fonts per page of a pdf file
#   (see documentation in readme-proceedings-script.pdf)
#   Copyright (C) 2004-2006 Gesellschaft fuer Schwerionenforschung mbH
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
#---
# this script
#  1) uses the following utilities: pdfinfo, pdffonts
#  2) accepts a pdf files as argument and writes out
#     all fonts used on each page
#
#    v0.3   3. Jun 2005  volker rw schaa  first try
#    v1.0  12. Jul 2006  volker rw schaa  GPL license

  use strict "vars";

  use vars qw ($pdffile $kin $keyword $value $numofpages $page $command $i $arg $file $name $type);

#
# open argument file or give help
#
  $i = 0;
  @ARGV = qw(.) unless @ARGV;

#  $arg = $ARGV[$i];
#  if ($arg =~ m/^-/) {
#        print " Found option: $arg\n";
#        if ($arg eq "-f") {
#            $i++;
#            $file = $ARGV[$i];
#            print " File output to : $file\n";
#            $i++;
#        }
#  }
  $pdffile = $ARGV[$i];
  ($name, $type) = split (/\./, $pdffile);

  if ($pdffile eq "") {
        print " Help ......\n";
        exit;
  }
  $kin = "pdfinfo-sf.txt";
  system ("pdfinfo $pdffile >$kin");
  open (KIN, "<$kin") or die " cannot open '$kin' -- error: $!\n";

  my $j=-1;
  while (<KIN>) {
    chomp;
    $j++;
    ($keyword, $value) = split (/:/);
    $value =~ s/^\s*//;
    $value =~ s/\s*$//;
    print sprintf (" %14s : %s\n", $keyword, $value);
    if ($keyword eq "Pages") {
        $numofpages = $value;
    }
  }
  close(KIN);
  system ("del $kin");

  for ($page = 1; $page <= $numofpages; $page++) {
    print sprintf  (" Seaching page: %4i\n", $page);
    $command = sprintf ("pdffonts -f %i -l %i %s >temp.%5.5i",$page, $page, $pdffile, $page);
#    print " $command\n";
    system ($command);
  }

  my $outfile = "$name.fonts";
  open (KOUT, ">$outfile") or die " cannot open '$outfile' -- error: $!\n";
  print KOUT "H      :  name                                 type         emb sub uni object ID\n";
  for ($page = 1; $page <= $numofpages; $page++) {
    $file = sprintf ("temp.%5.5i", $page);
    open (KIN, "$file") or die " cannot open '$file' -- error: $!\n";
    print sprintf  (" adding   page: %4i [", $page);
    $j = 0;
    while (<KIN>) {
        chomp;
        if ($_ =~ m/emb sub uni/) {
            next;
        }
        $j++;
        print KOUT sprintf ("P%5.5i :  %s\n", $page, $_);
        print sprintf  (" %2i ", $j);
    }
    close (KIN);
    print "]\n";
    $command = sprintf ("del temp.%5.5i",$page);
    system ($command);
  }
  close (KOUT);
  print " output written on $outfile\n";
