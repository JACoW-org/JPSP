#!/usr/bin/env perl -W
#   spmsbatch.pl    $Version 32.4      Volker RW Schaa
#
#   Script to generate a web site, CD-ROM, and proceedings for the JACoW
#   collaboration from XML exports from SPMS system (see documentation in
#   readme-proceedings-script.pdf)
#   Copyright (C) 2002-2020 Gesellschaft fuer Schwerionenforschung mbH
#   <https://www.gsi.de> by Volker RW Schaa (v.r.w.schaa at gsi.de)
#
#   Utility for the JACoW SPMS
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published byconvert_spec_chars
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
#   <https://www.gnu.org/licenses/gpl.html>
#-----
# the script "spmsbatch.pl"
# 0) needs the following packages
#
#    Data::Dumper  just for debug purposes (can be commented out)
#
# 1) reads a file named according to the config file "conference_xmlfile"
#    which contains a list of conference papers with conforming xml tagging
#    like the following example
#!-
#!- deleted .... xml structures changed too much
#!-
# 2) produces from above list a number of TeX-files (">papercode<.tex"),
#    which can be processed by pdfTeX to generate new pdf-files from
#    the old, but containing information about "Title", "Author(s)",
#    and "Keywords", the "Subject" field receives the "Conference name",
#    because there are no other known information to be placed. In addition
#    header and footer information are printed on each page:
#    - header/centered  "name of conference"
#    - footer/out       "page number from proceedings volume"
#    - footer/center    "paper code"
#    - footer/in        "group of paper (invited/contributed/poster/...)"
# 3) produces a Win batch file
#    - "gen_texpdf.bat" to generate all "final" pdf-files
#
#
#    v0.6  22. Apr 2003  volker rw schaa
#    v0.8  28. Apr 2003  volker rw schaa
#    v0.9  08. May 2003  volker rw schaa
#    v0.92 07. Jun 2003  volker rw schaa  sort order corrected by using ArbBiLex
#    v0.95 05. Oct 2003  volker rw schaa  coloring of authors' index, convertion of writing authors, abstracts,
#                                         and institutes using Unicode (&names; + &#entity;)
#    v0.96 03. Nov 2003  volker rw schaa  config file definitions refined, xml schema definition adapted
#    v1.0  15. Nov 2003  volker rw schaa  some minor nuisances taken care of (mailto, &# in config file, ...)
#    v1.1  21. Jan 2004  volker rw schaa  read additional file with production notes
#    v1.2  03. Feb 2004  volker rw schaa  abstracts will now be embedded into keyword and author list
#                                         (in addition to session list)
#    v1.21 09. Feb 2004  volker rw schaa  change of some block related TeX commands into environments (\raggedright
#                                         into flushleft)
#    v2.0  10. Apr 2004  volker rw schaa  adaption to matt's xml structure
#    v2.1  22. Apr 2004  volker rw schaa  nearly full adaption to matt's xml,
#                                         start of documentation, beautifying script after wild changes...
#    v2.2  29. Apr 2004  volker rw schaa  second stage of docu,
#                                         abstracts now internal instead of external,
#                                         script runs with Matt's test set (after some remedies: one line <keyword>-entries,
#                                         supplying missing fields, etc.)
#    v3.0  06. Jun 2004  volker rw schaa  restart with very old version after disk crash, backup from old notebook not usable (???!),
#                                         files on new notebook weren't synchronized due to harddisk swap after initial tests,
#                                         status: loss of all adapted scripts
#                                         history: retyped from printed version's first and only page :-(
#    v3.1  10. Jun 2004  vrws             everything adapted, docu missing, scripts ugly, this is not a distributable version!!
#                                         authors are listed one per line in all displays (no combined entry per institute,
#                                         tags <footnote> and <agency> are not honored
#    v3.2  20. Jul 2004  vrws             extending the script for abstract booklet production with ConTeXt
#    v3.3  30. Aug 2004  vrws             change of hard-coded style info into style sheet for author/paper title, etc.
#    v3.8  24. Sep 2004  vrws             changed for CD production all file names to UPPERCASE
#    v3.9   4. Okt 2004  vrws             bugs fixed from introduction of UPPERCASE file names
#    v3.91 11. Okt 2004  vrws             all talks (the ones with a video = coupling) got transparencies to patch for missing files (#‰)
#    v3.92 13. Okt 2004  vrws             affiliation (contrib_abb/presenter_abb) is now composed of
#                                            a) Affiliation + Town, if "Affiliation_abbrev" exists, or
#                                            b) Affiliation.Name1 + Affiliation.Name2 + Town, if no "Affiliation_abbrev" is given
#    v3.93 17. Nov 2004  vrws             keyword generation (search) from pdf files now in script "scan-keywords.pl"
#                                            - output file will be read to get keywords ($raw_paper_directory/keyword-count.txt)
#                                            - keyword generation from abstract text commented out (edit key: #ﬂﬂ)
#    v3.94 -- v4.03                       lost
#    v4.04 10. Oct 2005  vrws             classification/subclassification
#                                            - PAC conferences have a different way of using class/subclass: a classification may
#                                              not have a subclass, or may have entries under the classification and subclassification.
#                                              This should be fixed now!
#    v4.05 19. Oct 2005  vrws             - checking whether a slides file (<file_type abbrev="TRAN">Transparencies</file_type>)
#                                           mentioned in XML is really there. A slides entry will only be written, when a file
#                                           entry exists in $slides_directory
#    v4.06 24. Oct 2005  vrws             - this version finally includes the (not so)special last name translation routine,
#                                           which was already used in v 3.98/9, but somehow discarded. The translation
#                                           to ISO-Latin 1 is surely not an good idea, we should decide on UTF-8!
#    v4.07 09. Nov 2005  vrws             - a bit more ISO 9660 in the scripts :-)
#                                           all files now with .HTM
#                                         - clean-up of unused code
#    v4.08     Nov 2005  vrws             - some new UTF-8 code fragments added to translation table which are produced when
#                                           file is stored directly (xml save, without cut/paste to file or wget)
#    v4.09 10. Jan 2006  vrws             - lead/trailing spaces in all <xname> tags deleted
#                                         - all code and comments deleted for keyword generation (now scan-keyword.pl)
#    v4.10 11. Jan 2006  vrws             - more lead/trailing spaces in tags deleted,
#                                         - sub classification string is now initialized (to " ") when classification is read
#                                         - now a local default startup file "INDEXLOC.HTM" is created
#    v4.11 14. Feb 2006  vrws             - Version 4.10 brought a new error by initialized sub classification string to " ", the
#                                           test still was on =""!!
#                                         - id for @ (&#64) changed to (&#65131)
#    v4.12 29. Apr 2006  vrws             - Reintroduction of provisions for page count checking
#                                           (output file "pages_per_paper.txt")
#                                         - the new version of SPMS has a new tag structure "<coordinators>...</coordinators>"
#                                           which contains an inconsistent use of the <institute> tag structure. The
#                                           <coordinators>-code is skipped in reading
#    v4.13 17. May 2006  vrws             - error corrected in transparency detection (uppercase/lowercase ".pdf")
#                                         - output of xml lines in debug log with "||"
#                                         - clean-up of config file (all unused variables deleted)
#                                         - clean-up of debug lines
#    v5.0  22. May 2006  vrws             - now optimized pdfs (Fast Web View) will be produced by gen_texpdf.bat
#    v5.1  28. May 2006  vrws             - some more variables initialized, so the number of error lines when processing non
#                                           finalized xml files has been drastically reduced
#                                         - in early stages of a conference 'New Affiliation Request Pending' might cause lots of
#                                           error messages which are now reported
#                                         - substitution of "$" and "%" were not line global but local, fixed now
#    v5.2  12. Jun 2006  vrws             - in an early stage of a conference, "paper_code"s are not present in the XML file
#                                           while "abstract_id"s are. Code revised so that first "abstract_id" is taken for $paper
#                                           in the next stage "paper_code" overwrites this setting, if present. Now test output
#                                           can be generated without "paper_code" setting
#                                         - the XML file is now opened as assumed UTF-8 input. So now the 2 and 3 byte UTF-8 codes
#                                           (hopefully) are converted to the correct glyphs (still in test)
#    v5.3  17. Jun 2006  vrws             - opening the XML as UTF-8 helps in cases (FEL'06) but generates lots of errors in
#                                           others (FLS'06); in addition the code is much slower using the utf-8 option:
#                                           (0:10m compared to 2:07m for FEL'06). Now back to pre-version v5.2, code must be
#                                           changed to handle more utf-8 2 byte and 3 byte sequences
#    v5.4  25. Jun 2006  vrws             - Matt has repaired the "<coordinators>...</coordinators>" tag structure, so now
#                                           everything is read again
#    v5.5  12. Jul 2006  vrws             - fixing error in xml when chair has no email (error in generated XML)
#                                         - fixed problem with ConTeXt output not being converted to TeX chars (some instances
#                                           of author names and title lines escaped my notice)
#                                         - changed substitution of "&amp;" to "\&"
#                                         - title entries in KEYW*.HTM and AUTH*.HTM extended to contain actual keyword and
#                                           author. For KEYW*.HTM the actual keyword is added to the meta data "keywords" too.
#                                           This is not directly visible on the web due to the framed setting, but indexing
#                                           robots (Google, etc) which link them directly can show infos now.
#                                         - GPL license added
#    v5.6  26. Jul 2006  vrws             - email address field initialized (we really do not need the email address
#                                           for anything useful - and in PNP12 there is no email at all)
#                                         - more initializations: $session_startp/session_endp for sessions without papers (FEL2006)
#                                         - problems with "e-" substitution when something like "one- or two-fold" comes up,
#                                           now corrected
#                                         - recognition of writing exponentiations (e9/10**9/10-9/etc) improved
#    v5.7  29. Jul 2006  vrws             - list environment formatting doesn't really work the way as intended, formatting fixed now
#                                         - special symbols or LaTeX notations with $....$ are hard to convert, so if the $s
#                                           (dolares) come in pairs they will be deleted otherwise we have to deal with them directly...
#                                         - special LaTeX commands converted to ConTeXt for Abstract booklet processing
#    v5.8  14. Aug 2006  vrws             - pdfopt 'destroys' some of the pdf files (error 110). The code is commented out now
#                                         - addition of special symbols or LaTeX notations (Ohm, cm^+-x, \bf{xx})
#                                         - conversion of 10xx to power corrected (some zip codes appeared in power notation)
#                                         - output of elapsed time to ease run-time measurements
#    v5.9  16. Aug 2006  vrws             - when there is no PDF file present in $paper_directory (./PAPERS) no link will be
#                                           generated anymore from "Authors list", "Session list", and "Classification list",
#                                           Instead the <papercode> is given without link and a non-breakable (&nbsp;) space is
#                                           output instead of the page number. This is due to conferences where either no
#                                           papers will be uploaded (PNP12@GSI), or for workshops with only transparencies
#                                           shown (FLS2006@DESY)
#                                         - initialization error corrected in when writing 'SCRTYPE' with document types other
#                                           then 'DOC' or 'TeX' (in this case Open Office 'ODT')
#    v5.10 26. Aug 2006  vrws             - number of papers per line per author in TeX and ConTeXt output corrected
#                                           (error: first line one, next lines wanted number of papers, due to wrong initialization)
#                                         - listed page numbers as long as there are no <toc> values changed from "0" to "1"
#                                         - list formatting ([+ ... +]) has been extended to [+ -) text +] for unordered lists
#    v5.11 21. Sep 2006  vrws             - BESSY enhancements: sound (MP3) files for talks now with link in web pages
#                                           (thanks to Roland M¸ller!)
#                                         - script adapted to Acrobat 7's way of writing Media- and Crop-Boxes
#                                         - code for 'itemize lists' produced a wrong list if text contained closing braces "x)"
#                                           without preceeding space character
#                                         - 'Missing Papers' are now generated directly in the way as needed for LINAC04 and DIPAC03/05:
#                                           whole page with title, authors, institutes, and abstract (column one) and 'Missing Note'
#                                           in column two (now you need the additional file "jacowscript-vrws" in ./PAPERS).
#    v5.12 06. Oct 2006  vrws             - introduced "revert_from_context" for pure LaTeX output of string converted by
#                                           "convert_spec_chars2TeX"
#    v6.0  09. Oct 2006  vrws             - changes due to LINAC 2006 and November meeting at DESY
#                                         - corrected wrong html generation (missing ">" in several <\td> elements)
#    v6.1  18. Dec 2006  vrws             - changes frameset to allow scrolling of banner and list content
#                                         - detected that since the TOC values are generating by SPMS, only non-numbered session sheets are
#                                           supported (whether this is a standard in book printing is open)
#                                         - \cleardoublepage reintroduced for non-numbered session sheets (otherwise the whole counting
#                                           is completely off)
#                                         - scaling in pdf-inclusion changed from "scale=1.0" to "noautoscale", because "scale=1.0" will recognize
#                                           cropbox measures and the included pdf will shrink
#                                         - process of uppercasing started due to problems experienced with EPAC2006 and MAC-OS: now all
#                                           generated HTML and PDF files have uppercase filenames
#    v6.2  04. Jan 2007  vrws             - html-generating code for keyword/author correct: loop produced invisible code for non-existing
#                                           local link (href="KEYW1.HTM#"/"AUTH1.HTM#"). So 50 byte per keyword and 47 per author saved.
#                                         - complete code of sub "inclsession_in_proctex" removed (see editmark #070109) due to page offset
#                                           introduced by \cleardoublepage (v6.1)
#                                         - removed notice generation in PROCEEDINGS-PAGES1.TEX for missing pdf files
#    v6.3  16. Jan 2007  vrws             - due to problems in uppercasing (V6.1) using pdfpages pages which can not cope with the uppercase
#                                           PDF extension (unknown graphics extension .PDF.) the extension is now left out.
#    v6.4   2. Mar 2007  vrws             - $santitle globally used because sanitizing the title isn't enough, it's also needed for
#                                           for the "\contentsline" macro
#    v6.5 ~23. Mar 2007  vrws             - pdfopt which was commented out, is now dropped due to Acrobat's Optimize features
#    v7.0  28. Apr 2007  vrws             - started with "fileURL" functionality
#                                         - id for @ (&#65131/FE6B) changed to (&#65312/FF20)
#    v7.1  07. May 2007  vrws             - major code changes due to reading of XML files produced by InDiCo
#    v7.2  28. May 2007  vrws             - <chair> tag now inside <chairs> tags due to InDiCo's possibility to have more than one chair
#                                           per session
#                                         - fallback code for JACoW conferences without <chairs> tags
#    v7.3  17. Jul 2007  vrws             - the proceedings TeX file doesn't use the sanitized version of classification/subclassification and
#                                           stumbles over "&amp;"
#                                         - base setting for footers/headers now PAC style
#                                         - <chairs> tag code for JACoW conferences remove, SPMS now has the same structure
#    v7.4  19. Jul 2007  vrws             - search for error putting accents atop on accents (\`'), found code but no idea what it does
#                                           commented out: #070719>
#                                         - statistics about used document type extended to show Open Office documents (.odt)
#    v7.5  24. Jul 2007  vrws             - additional file output for posted files to determine which papers have to be withdrawn
#                                         - corrections for &#322; (polish l-slash) and &#380; z-dot
#    v7.6   2. Aug 2007  vrws             - changes to the footer section due to IEEE requirements, main- and subclassification on-top of
#                                           IEEE copyright notice, page number outside instead of centered
#                                         - 'List of Sessions' changed to 'Table of Sessions'
#                                         - button 'Home' in "banner.htm" changed from "$base_url" to "../INDEX.HTM"
#    v7.7  26. Aug 2007  vrws             - TeX file generated for InDiCo produces error (no line to end here) when Main- and Subclassifications
#                                           are empty (\mbox{ } introduced when strings are empty)
#    v7.8  18. Sep 2007  vrws             - due to changes to the XML by Matt, the check now is "Primary Author" instead of "Author", This has to
#                                           be added, otherwise InDiCo-Main Authors are not found anymore
#    v7.9  23. Sep 2007  vrws             - error in primary author high-lighting found and corrected. Only the authors index showed a correct
#                                           high-lighting, session, keyword, and classification didn't, this error showed up when Matt changed
#                                           the sequence in which "Co-Author", "Primary Author", "Owner" and "Speaker" are output in the XML.
#                                         - checking whether a poster file (upload under <file_type abbrev="OTHER">Other Supporting Files</file_type>)
#                                           with "<paper_code>_poster.PDF" has been uploaded (or more correctly: downloaded into the ./POSTERS directory
#                                         - file download with "pdfwget.bat" made safe for file names containing spaces
#                                         - optional argument switch introduce with "Getopt:Long", at the moment only an alternative XML file location
#                                           is implemented using "--xml=<file-spec>".
#                                         - discrepancy between "sound" and "audio" directory and treatment adjusted
#                                         - write to file "pdfwget.bat" now selects only <paper_code><extent>.PDF files where extent can be
#                                           "", "_talk" or "_poster". So only directly usable files are download. The file "allwget.bat" gets
#                                           all from the server downloadable files. The batch file now copies the files into the corresponding
#                                           directories defined by "conference.config" (raw_paper_directory, slides_directory, poster_directory).
#    v 8.0  28. Sep 2007 vrws             - Final version for Team Meeting
#    v 8.0a  7. Oct 2007 vrws             >> check for changes made to # why $clsMline="" and $clsSline=" " ???
#    v 8.0b 14. Oct 2007 vrws             - out of a sudden en-dash (&#150;) causes problems in TeX. Reconversion not ok due to wrong placement of
#                                           1 byte/2 byte and 3 byte UTF-8 character sequences. Substitutions reordered.
#    v 8.1  14. Jan 2008 vrws             - sort order for main authors has been changed by Matt to last in sequence(why?), try to re-sort main
#                                           author to first
#    v 8.2  27. Feb 2008 vrws             - new version id introduced to identify html pages by $sc_version of spms_batch.pl script
#    v 8.20  1. Mar 2008 vrws             - some code for LaTeX proceedings index and institute generation corrected
#    v 8.2a 15. May 2008 vrws             - code now less greedy to produce superscripts from numbers with embedded tens, like ZIP codes etc.
#    v 8.2b 23. Mar 2008 vrws             - for consistency all character code with &#0xxx were changed to &#xxx
#    v 8.2c 30. Jun 2008 vrws             - uc for filenames changed to lc (decision taken at TM in Knoxville, Oct 07).
#    v 8.2d 10. Aug 2008 vrws             - added full support for img_directory which was introduced last year but near used
#    v 9.0  15. Aug 2008 vrws             - finished extensions for generating SPIRES records directly
#    v 9.0a 23. Aug 2008 vrws             - error in TeX $\alpha$ (verb|\alpha$|) corrected, "Ü" added
#    v 9.1  28. Aug 2008 vrws             - problems in session name with "/" (will request a subdirectory) -- this occurs in InDiCo (ERL07)
#    v 9.2  20. Oct 2008 vrws             - name translation table in UTF-8 introduced
#    v 9.3   3. Dec 2008 vrws             - now file open with UTF-8 encoding
#                                         - fixed error when author's paper link was not found in institutes list due to UTF-8 name encoding
#                                         - main and subclassification is now used in pdfsubject
#    v 9.4  12. Dec 2008 vrws             - UTF-8 encoding now in additional XML header (<?xml version="1.0" encoding="utf-8" ?>)
#                                         - fixed error when author's paper link was not found in institutes list due to UTF-8 name encoding
#                                         - start with an auto-fill option for abstract texts (when <abstract></abstract> is encountered and the config file switch
#                                           "insert_abstract" is set to 'yes'.
#                                         - paper_code set in BLUE on PDF for better visibility (color must be printable/recognizable on B/W)
#    v 9.5  30. Dec 2008 vrws             - removing 'trailing -1' in InDiCo's session names is now an option in the config file ("indico_cut_of_trailing_ho=yes")
#                                         - auto-fill option for abstract texts moved to scan_keywords.pl which writes an separate <paper_code>.abs into
#                                           the directory ABSREF. This script reads it from there.
#    v 9.6   2. Feb 2009 vrws             - two new config file parameters are checked and displayed: "version_config" and "version_script_bt"
#                                         - empty institute name and institute abbreviation now taken care of
#                                         - names with all uppercase characters are now changed with "ucfirst(lc(name))", a warning is given
#    v 9.7  12. Mar 2009 vrws             - InDiCo's XML with two sessions named "sess1" and "sess2" screwed up the generation of session subframes with the same name
#                                           name changed to "sessi0n.htm", "sessi0n1.htm", and "sessi0n2.htm".
#                                         - for InDiCo conferences "paper_code" id will not be displayed a) on TeX printout b) on session/author page
#                                           when paper not downloadable
#    v 9.8  16. Mar 2009 vrws             - for each missing submission a TeX file will be generated in "$raw_paper_directory/MISSING/" with a
#                                           setting usable for direct production of 'missing submission' PDFs
#                                         - "jacowscript-vrws.sty" modified to mimic "jac2003.cls" for "Abstract" section and renamed to "jacowscript-jpsp"
#                                         - auto-fill option for abstract texts from <paper_code>.abs now fully functional, no manual editing of XML necessary
#                                         - the config variable "abstract_omission_text" is now the substitution string when a abstract
#                                           is missing (default = "no abstract available", if set to "" no text is output)
#                                         - the config file parameter "session_skip" is now used to exclude specific sessions from being processed for papers 
#											and web generation the skip list should contain the session name, each session name must be embedded in "|" characters,
#											when defining several sessions it should be written as "|SESS-A|SESS-B|COFFEE|LUNCH|"
#                                         - solved problems with empty Abstract when auto-fill option for abstract is, no abstract file is found and
#                                           the "abstract_omission_text" is empty too
#    v 9.9  21. Mar 2009 vrws             - incompatibilities between session exclusion in SPMS and InDiCo removed
#    v10.0   7. Apr 2009 vrws             - started to include E/PAC like abstract booklet generation
#                                         - somehow the text written to the abstract booklet files is completely "ISO-Latin1" and not "UTF-8", the
#                                           re-encoding has to be checked and all coding procedures should deliver "UTF-8"
#                                         - information about session location is missing from the XML
#                                         - unknown effect on clsMSline (!!)
#                                         - H^3+ added / ^0 or ^00 still a mystery
#                                         - lots and lots of new funny Unicode (entity encoded) characters are showing up at PAC'09
#                                         - unidentified Microsoft characters &#61548 substituted by " =???= "!
#    v10.1  14. Apr 2009 vrws             - version with character additions for DIPAC'09 (fi-ligature, Omega outside math-mode, s-1 and sec-1 changed to superscript)
#                                         - get_session_locread/get_session_location as temporary fix by reading it from external file
#    v10.2  19. Apr 2009 vrws             - more Unicode characters from PAC'09 (∞Celsius, hyphen surrounded space, ideographic comma)
#                                         - correction for SQRT with argument in math mode
#                                         - correction in check for $s in math mode environment
#    v10.3  18. May 2009 vrws             - more Word characters from DIPAC'09 (Ohm, overline, beta, full width {right/left parenthesis, comma})
#                                         - re-sync of independent changed versions
#    v10.4 -20. Jul 2009 vrws             - re-synching all above version after disk crash
#    v10.5  25. Jul 2009 vrws             - fixing problems with Windows-1252 character set (x80-x9F)
#                                         - reorganized and removed duplicates from character substitution for apostrophes, spacing and some special characters
#                                         - fixing problems clsMSline for DIPAC'09, no sub-classifications (broken by v10.0 for booklet generation)
#                                         - fixing html generating with wrong <ul>...</ul> lists for keyword pages
#                                         - fixed error in closing of classification file (my $cls_open)
#                                         - update in title and subject for classification web pages when there is no sub-classification
#                                         - fixed problem with empty paragraphs (<p />), now clean <p>...</p> environments
#                                         - fixed unwanted superscripts with s-1 and sec-1 in text mode
#                                         - new rule for sub/superscript with argument in ()
#                                         - fixed problem with empty sub-classification line for LaTeX run
#                                         - try to circumvent the problem with differences between author name and utf-8 equivalent (while only lastname and firstname
#                                           appear in different sequence) see "<+circ 090727" (but still no RED highlighting of author name in Author Index
#                                         - more test with conference infos on PDF in color (still BLUE), must be used with a flag for switching color of when 
#											printing proceedings?!
#                                         - banner file changed from "banner.htm" to "b0nner.htm" due to firewalls with advertisement blocker suppressing files named "banner"
#                                         - image directory in config file renamed "images" to "im0ges" due to firewalls with advertisement blocker suppressing files 
#											from directories named "images"
#                                         - documentation update
#    v10.6  28. Jul 2009 vrws             - error found in UTF-8 name tagging having the side-effect of non high-lighted names in author list 
#											(reason: institute's name contained split pattern ";")
#                                         - corrected (restricted) lowercasing of file and directory names from config file (some entries are unclear => 
#											see # "what to do here? 090728")
#                                         - switch for changing the color of header/footer lines now in config file (TeXhighlite [default:black], two defined colors:
#											blue/black)
#    v10.7  08. Aug 2009 vrws             - corrections to last version found by Martin (forgotten banner.htm => b0nner, abbreviated proceedings* to proceed, ...)
#                                         - regular expression for 10**xx/10exx/10^xx only found one digit due to "\d?" (corrected to "\d+")
#                                         - regular expression for " micro" peculated the leading space
#                                         - text size for classifications set to normal, header included in highlighting, all headers/footers in bold face
#                                         - missing undefined (= !defined) for $clsMline/$clsSline supplied
#                                         - default for pdfTeX changed to "\pdfminorversion=6" (=> PDF 1.6)
#                                         - corrected a glyph disappearing bug (glyph 'xxx' undefined => see http://www.ntg.nl/pipermail/ntg-pdftex/2009-April/003771.html
#                                           for one possible reason) which has appeared in LINAC'08, PAC'09, and DIPAC'09 by inserting "\pdfinclusioncopyfonts=1"
#                                         - regular expression extended for \beta/\nu/\lambda and alike when used outside of math math
#                                         - wrong (or missing) quantifier in regular expression converted double initials to spaced initials (&nbsp; for HTML + "~" for LaTeX)
#                                           which broke the label mechanism in hyperlink/hypertarget for proceeding mode
#                                         - new keyword list (from Martin) and new scan_keywords.pl (change by John)
#                                         - sorting algorithm left a sequence of "Kim, S.-H.", "Kim, S.H.", "Kim, S.-H." without connecting first and third into one entry.
#                                           leading to compile errors and dropped links, problem solved by regrouping the institute as second sort criteria 
#											(paper number now third)
#                                         - some unicode characters are not supported in [utf-8]{inputenc}, therefore a problem with Aring wasn't detected earlier. 
#											This problem has to be checked in more detail. If necessary an additional string (re?)conversion has to be supplied for  
#											embedding these strings in the hidden fields in PDFs files which understand Unicode
#    v10.8  12. Aug 2009 vrws             - forgot to check whether "proceed1.tex" includes "jacowscript-jpsp". It doesn't so the first page inclusion run 
#											stops after 5xx pdf files.
#                                           code now directly in preamble of "proceed1.tex".
#                                         - multiple downloads for the same PDF file now minimized (i.e. 709 PDF files for PAC'09)
#                                         - "names-utf.txt" moved to "$content_directory"
#                                         - new directory specification for all protocol, log, and debug files (protocol_directory [Default: ./PROTOCOL])
#    v10.9  18. Aug 2009 vrws             - all distances new adjusted, paragraph <p> for abstracts modified to <p style="margin-bottom:1em;margin-top:-5px">
#                                         - icons for video, audio, slides, and poster shifted vertically (<margin-top:-1.5em>), whole line shifted with <margin-top:-1em>
#                                         - footnotes shifted vertically (<margin-top:-1.5em>)
#                                         - placement of paper_code centered for keyword display
#   v10.9.1 16. Sep 2009 vrws             - a hash is now used for the identification of author names in the UTF-8 table
#   v10.9.2 18. Sep 2009 vrws             - sessi0n.htm had a wrong sequence of "</html></table>" tags
#                                         - class1.htm contained a superfluous "<body>" tag
#                                         - keyw1.htm contained a superfluous "</table>" tag
#   v10.9.3 22. Sep 2009 vrws             - missing copy statement for posters added
#                                         - version/date string updated
#   v10.9.4 27. Sep 2009 vrws             - small improvements on character substitution (TeX/char entities instead of ISOLatin1 strings)
#                                         - debugging in character substitution enabled
#   v10.9.5 12. Oct 2009 vrws             - removed the \large for Participants/Institutes/Authors/Vendors List (page number, footer title of 'list')
#   v10.9.6 14. Dec 2009 vrws             - vertical space adjustments made in banner and indexloc
#   v10.9.7 01. Mar 2010 vrws             - thanks to Martin Comyn the unidentified Microsoft characters &#61548 now has a real substitution (&Bull;)
#   v11.0   29. Mar 2010 vrws             - new start on releasing v10.xx.yy
#                                         - added an "shortcut icon" and an "animated JACoW gif" for identifying JACoW in each generated web page
#   v11.1   03. Apr 2010 vrws             - new start on generating a command file for a full source file snapshot (WGETOUT) with ./source/ dir and
#                                           all ./<paper_code/ sub dirs with uploaded files
#                                         - session type for (Invited/Contributed/Poster/...) introduced for booklet
#                                         - \textbf for Authors changed to macro \bold so it can be treated in booklet context
#   v11.2   02. May 2010 vrws             - some new chars from IPAC'10 added ([&#378;=z-acute], &#281; [LATIN SMALL LETTER E WITH OGONEK  U+0119 &#281;],
#											[&#1040;=cyrillic A], [&#324;=n-acute],
#                                         - found meaning of [&#8206;=Left to right mark] which can be removed
#                                         - change of the class of CSS formatting of abstract texts (class="hyphenate text" lang="en")
#   v11.3   06. Jun 2010 vrws             - found and corrected problems with session names containing spaces or characters which are treated
#                                           differently on different platforms (Linux/Windows/OpenVMS)
#                                         - adding INSPIRE XML output to the script
#                                         - changed internal codes for &ldquo;, &rdquo;, &lsquo;, and &rsquo;. Character entity references won't work in SGML or XML in
#                                           general, because they aren't a predefined entity in SGML or XML
#                                         - m/\^[-+]{0,1}\d+?/g) corrected to contain the missing "\D" used in the substitute path.
#                                           Message was "Use of uninitialized value $1 in string.."
#                                         - this version was used for IPAC'10
#   v11.4   18. Jun 2010 vrws             - $base_url removed (was already substituted by "index.htm" in version 7.6
#                                         - $conference_url used as indicated for JACoW base directory for specific conference (e.g. http://jacow.org/IPAC10/)
#   v11.5   17. Jul 2010 vrws             - small corrections (entity values)
#                                         - stronger parametrization of argument for \SessionHeader and \SectionBody
#                                         - \frac embedded in $ for mathmode
#                                         - error fixed in \NewDay generation
#                                         - all (Xe)LaTeX files for Abstract or booklet moved to $content_directory
#   v11.6   03. Aug 2010 vrws             - complete substitution of utf-8 to ISO-8859-1 (1-byte-equivalence) conversion by just the
#                                           opposite (8859-1 to utf-8 2 byte sequences) in LaTeX (therefore XeLaTeX is needed)
#                                         - extension of all booklet generation macros (more parameters)
#                                         - start_time and duration of Oral is now stored and used for \PaperAbs
#                                         - unclear effect for char \xc2\xbf (should be inverted question mark) is shown as \Pound,
#                                           needed is an apostrophe ("'")
#   v11.7   11. Aug 2010 vrws             - rewrite of data written out to "auth-shortprg" to achieve a better way to customize
#                                           "Programme overviews" using macros
#                                         - Affiliation string in print for Chair is now "C.~Hair (Inst.Abbr)" => "C.~Hair (Inst.Name)" => "C.~Hair"
#                                         - anomaly found with "<sglChar1>&amp;<sglChar2>" being substituted to "<sglChar1>&" (for LaTeX)
#   v11.8   30. Aug 2010 vrws             - new detection of "Oral" or "Invited" sessions (for LaTeX)
#                                         - corrected nasty error in delimiter for 'CodeLocation' set. Changed ":" to "#"
#   v12.0   10. Sep 2010 vrws             - new version of output for Author/Affiliation check
#   v12.1   15. Sep 2010 vrws             - added a batch file version for ATC actions
#   v12.2   10. Okt 2010 vrws             - when testing an old conference with v12.1 I found that the changes made in v11.6 using utf-8 only led to
#                                           a non acceptable mixture between Abstract/Programme booklet generation (utf-8 => XeLaTeX) and the 
#											standard Proceedings volume (ISO-8859-1) in LaTeX. Trying to cure this by running proceed.tex in XeLaTeX 
#											didn't work out. Therefore re-establishing of the old code for Author index
#                                           in proceed.tex and separation of all booklet generation macros
#   v12.3   28. Oct 2010 vrws             - still some issues with LTXAidx/XETAidx files (do not compile cleanly)
#                                         - utf-8 comment entries (for searching) unified
#   v12.4  -05. Dec 2010 vrws             - substitution of &nbsp; in combined authors list changed from " " to "~" for missing papers
#                                         - added configurable number of "P"aper numbers "P"er "L"ine (PPL) for index purposes
#                                           ($PPL_ltx, $PPL_ctx, $PPL_xtx). Defaults set when not defined in config file.
#   v12.5   15. Jan 2011 vrws             - untangle XeTeX and LaTeX needed index files by writing required macro definitions (\def) in
#                                           proceed-p1.sty
#                                         - character mapping extended (includes now "LATIN SMALL LETTER O WITH STROKE" (00D8),
#                                           "LATIN SMALL LETTER I WITH ACUTE" (00ED), "LATIN SMALL LETTER O WITH GRAVE" (00F2)
#                                           see code table on "http://www.utf8-zeichentabelle.de/unicode-utf8-table.pl"
#                                         - generation and reading of Authors, Institute and Participants Index for Proceedings production now read direct
#                                           from TeX file, and not generated and read from file in the next loop
#                                         - special treatment for "÷" only for UTF-8 output
#                                         - browser target added for "Slides" and "Poster" display
#                                         - page footer unified in font, size, and placement
#   v12.6   20. Jan 2011 vrws/jc          - Jan Chrin submitted a change for the depth of "Papers" in the index, should be section (not subsection) => proceed-p2.tex
#                                         - placement of all Information (Main- and sub-classification) now at the same location for Proceedings,
#                                           Proceedings-Pages_1, and single papers
#                                         - character mapping extended ("LATIN SMALL LETTER C WITH ACUTE" (0107), "LATIN CAPITAL LETTER C WITH CARON" (010C),
#                                           "LATIN SMALL LETTER C WITH CARON" (010D), "LATIN SMALL LETTER S WITH CARON" (0161))
#   v12.7   26. Jan 2011 vrws             - Author sorting map corrected for accented characters (¡, ¿, ¬)
#                                         - comments for edit key #U# removed to clear-up code
#                                         - > it should be documented in the manual to look for "wide character in ..." messages (and to report them)
#   v12.8   09. Feb 2011 vrws             - introduced subroutine "get_wday" to deliver the day of the week for use in Abstract booklets
#                                         - additional macro parameter in \NewDay for day of the week
#   v12.9 14-17 Feb 2011 vrws             - PAC2011 wants to use the prelimenary web pages but do not want to have the strike-through paper-codes, made
#                                           strike-through an option in the config file (paper_strike_thru)
#                                         - writing ATC and paper_directory TeX files as UTF-8 may screw-up the encoding ("ˆ" which has the same glyph slot in
#                                           ISO-8859-1 and UNICODE [\xf6] will be re-encode by UTF-8 writing to [\xc3\xb2]) see editmark #>110217
#                                         - \MainClass to mark the Main Classification in Conference Guide introduced
#   v12.10  29. Mar 2011 vrws             - for the slides file sizes are now given in MB (due to the first talk with 286 MB)
#                                         - Copyright notes updated
#   v12.20   1. Apr 2011 vrws             - rebuild functionality for publishing onle <publishable>Yes</publishable> papers
#   v13.0   10. Apr 2011 vrws             - first try to substitute all style information into CSS classes
#   v13.1    4. May 2011 vrws             - CSS classes for all Session related items created
#   v13.2   18. May 2011 vrws             - CSS classes extended for all type of Icons (Slides/Talks, Posters, Video, ...)
#                                         - Reencoding for U+0096 as en-dash for within white space or numbers, to hyphen for mid-word hyphens
#                                         - table-summary introduced, description text for posters made unique, page number not a link anymore
#                                         - problem with Keyword list for non-publishable papers fixed (only keywords of publishable papers are used)
#                                         - duplicate entry for poster download in pdfwget fixed
#                                         - regex for H^+/H^- added
#                                         - institutes were sorted case-sensitive therefore "iThema" ended up as last institute in the list (fixed)
#                                         - all superscript "-" substituted by "endash" sized minus sign
#   v13.3    6. Jun 2011 vrws             - all source statics were off when for one document a DOC and a DOCX file were uploaded (counted twice)
#                                         - missing LaTeX translation for "LATIN SMALL LETTER R WITH CARON" (U+x0159) as "\v{r}"
#                                         - Author-Institute string with Latin (SPMS) and UTF-8 name now stored for later usage while computing Keyword information
#   v13.4   10. Jun 2011 vrws             - superfluous array "$combinedauthors" removed, precedure "combine_authors_institutes" fixed for generation of $inst_author
#                                         - missing LaTeX translation for "LATIN SMALL LETTER Z WITH DOT ABOVE" (U+017c) as "\.{z}",
#                                           for "LATIN SMALL LETTER L WITH STROKE" (U+0142) as "{\l}",
#                                           for "LATIN SMALL LETTER N WITH ACUTE" (U+0144) as "\'{n}"
#                                         - again issues concerning version 12.9: Accented characters in PDF-Author field need UTF-8 as file encoding,
#                                           therefore for TeXOut new header without inputput encoding and PDF generation using LuaLaTeX
#   v13.5   20. Jun 2011 vrws             - missing translation UTF-8 to Latin1 for "LATIN SMALL LETTER E WITH DIARESIS" (U+00eb "Î")
#                                         - fixed UTF-8 string in "participants.tex" ftom "participants.pl" (by including "convert_spec_chars2TeX" in script)
#                                         - reintroduced missing highlighting for paper_code
#                                      !! + fix name encoding by seperate procedure from "convert_spec_chars" and "convert_spec_chars2TeX"!!
#   v13.6   30. Jun 2011 vrws             - inclusion of <author_id> as unique SPMS_author identification (for data exchange with INSPIRE)
#                                         - new character code for translation Ä, ..., etc. which appear in Windows-1252
#   v13.7   08. Jul 2011 vrws             - wrong placement of session name translation corrected ("Table of Sessions" got untranslated session name)
#                                         - &amp;<named_unity>; have to be taken into account (not covered by &amp;# translation)
#                                         - fixed the LaTeX issue with empty paper lists (missing item for sessions without papers)
#   v13.8   10. Jul 2011 vrws             - added some more missing codes (experimental: \x80 as \textgreek{\euro}, \x86 Dagger, \x87 Double Dagger
#           14. Jul                       - fixed a issue in ConTeXt file generation (ctxt-shortprg.tex) putting an "StopSession" text as divider after a session
#                                         - corrected some too strong ConTeXt hyphenation helps by resubstituting "-||-" with "--"
#   v13.9   18. Jul 2011 vrws             - complete JACoW unique author information (identifier, email) written to INSPIRE record
#                                         - missing LaTeX translation for "EM SPACE" (U+2003 = &#8195;), "LINE SEPARATOR" (U+2028 = &#8232;), 
#											"LATIN SMALL LETTER L WITH A STROKE"
#                                           (U+0141 = &#321;), "&#1051;&#1071;&#1056;" is the FLNR of JINR, Dubna, "HORIZONTAL BAR" [longer than "EM DASH" (U+2015 = &#8213;),
#                                           "FULLWIDTH TILDE" (U+FF5E = &#65374;), Pierce parameter (U+F072 = &#61554) => \rho,  "SQUARE MU M" (U+339B = &#13211;) => µm,
#                                           character identified via comment in paper U+F06E = &#61550;) => \nu = nu/v
#                                         - there is no character mapping for (U+FF5E = &#61537;) which is not a valid Unicode character (=> alpha?)
#                                         - added Bullet/centered dot of Windows 1252 page (&#95 = U+0095)
#   v14.0   24. Jul 2011 vrws             - changed method to ensure Math Mode setting when singular TeX commands appear in Abstracts (\ensuremath{<argument>})
#   v14.1   02. Aug 2011 vrws             - missing LaTeX translation for "LATIN SMALL LETTER K WITH ACUTE" (U+1E31 -> \'{k}
#   v14.2   08. Aug 2011 vrws             - new version due to new format of separators in "names-utf.txt" which will not work with old scripts.
#                                         - changed separator to "ß"
#                                         - Thumbnail generation for PDF switch off as thumbpdf produces strings which are not accepted by LuaLaTeX
#                                           ("String contains an invalid utf-8 sequence")
#   v14.3   05. Sep 2011 vrws             - ATC generated files contained LuaLaTeX instead of PDFLaTeX, and these died on non valid UTF8 character sequences
#   v14.4   11. Sep 2011 vrws             - session type detection of Oral presentations has now to search "Oral" or "Plenary" or "Tutorial" to cover ICALEPCS 2011
#           14. Sep 2011 vrws             - above extended to "Workshop", "Parallel", "Opening", "Closing" and "Report"
#   v14.5   20. Sep 2011 vrws             - formatting changed for footer to embed the copyright/license: "CopyrightÅõc 2011 by the respective authors, cc Creative Commons
#                                           Attribution 3.0 (CC BY 3.0)"
#   v14.6   29. Sep 2011 vrws             - error concerning the generation of Keyword HTML files found: Check whether PDF exists is using the wrong directory
#											($paper_directory instead of $raw_paper_directory). Error fixed (temporarily by duplication the code for 
#											"$paper_with_pdf" for "$paper_with_raw_pdf")
#                                         - Copyright sign introduced in TeX to compile copyright/license note compiler independent
#                                         - copyright note needs to be positioned relative to the end of the even page number with a varying negative distance to 
#                                           compensate for the current writing position ($x_pos_off)
#   v14.7   04. Oct 2011 vrws             - Ronny spotted an error which is in the scripts at least since mid 2008 (EPAC'08 has it, earlier not checked): the Authors in the
#                                           Institutes Index is non sorted alphabetically
#                                         - modified license string for PAC'11 OC/IEEE
#   v14.8   09. Oct 2011 vrws             - license string now read from config file (variable "$conference_pub_copyr")
#   v14.9   20. Oct 2011 vrws             - introduced mapping for LaTeX (U+0160 = \v{S}, U+017d = \v{Z})
#                                         - problem with gobbling the character in front of a "&quot;" solved by changing the substitution of "&quot:" from '"' to '\{"'
#                                           which resolves to '{"}' in the final substitution (solved but not understood, where does the second closing "}" comes from?)
#   v15.0   03. Nov 2011 vrws             - differences between Proceed(ings).tex [TeXLGOut] and single PDF wrappers [TeXOut] concerning Main/Subclassification removed.
#                                         - license string "$conference_pub_copyr" printout added to Proceed(ings).tex [TeXLGOut] and Proceed(ings)1.tex [TeXP1Out]
#                                         - placement calculation for Copyright note a procedure as it is used by TeXLGOut and TeXOut
#   v15.1   22. Nov 2011 vrws             - changes made to subroutine "correct_names_UTF8" which delivered only one argument (lastname), now firstname is returned too
#   v15.2   07. Dec 2011 vrws             - comparison for author names didn't take utf-8 first names into account (compare extended to first name)
#                                         - valid range for character conversion as hypertarget label reduced to (0-9,A-Z,a-z), all other characters are converted to "_"
#                                         - wide characters above 0x0100 to 0x059f (Cyrillic) converted to "-"
#                                         - removed "/" divider in subject, when there is no Sub-Classification
#   v15.3   08. Mar 2012 vrws             - table "summary" tag (v13.2) changed to "title" tag, as "summary" is obsolete in HTML 5
#                                         - $contrib_aid added to the list of entities sorted during main author placement on top of list
#                                         - author names in ATC PDFs now with unbreakable space between Initials and Lastname
#                                         - changed PDF opening mode for ATC PDFs to pdfpagemode=None, pdfstartview=FitH
#   v15.4   10. Apr 2012 vrws             - \beta* introduced (\beta had been removed in version ??)
#                                         - \beta fixed for expressions following ^/_
#                                         - changed Daf/phne detection from "Character Class" to "Grouping" regex (and got the expected result)
#                                         - fixed wrong exponentiation of Exx when no argument for E was given
#                                         - µ+/µ-, e-/e+, p+, H0 introduced
#                                         - special treatment for CLIC_DDS
#                                         - fixed single digit recognition for 1eXX formats
#                                         - fixed special character (single) exponentiation (Li^+)
#                                         - fixed Unicode character translation in pdfLaTeX for some characters which were troubling us at ICALEPCS'11
#                                           (U+1E31 LATIN SMALL LETTER K WITH ACUTE, U+1D9C MODIFIER LETTER SMALL C)
#                                         - missing LaTeX translation added for "HYPHENATION POINT" (U+2027 = &#8231;), "FULLWIDTH LESS-THAN SIGN" (U+FF1C = &#65308;)
#                                           "COMBINING RING ABOVE" (U+030A = &#778;)
#                                         - special treatment for DAEdALUS
#                                         - title comments in HTML like <table title="Classification: xyz"> removed as they overlay with box info size tc.
#   v15.5   17. May 2012 vrws             - some more language specific conversions (Swierk, Krakow)
#                                         - new feature for more security: hcheck-code introduced by Ivan now implemented in JPSP
#                                         - the new tags <editor> and <final_qa>, introduced in the XML by Matt, used in the script for reporting
#   v15.6   21. May 2012 vrws             - since the "IPAC'12 Conference Guide" didn't show the Abstract for the "Industry Session", "Awards Session", "Special Presentation"
#                                           due to the problematic detection of a "Session Type", Matt has introduced the session type as in
#                                           '<session type="Oral">'. The script now honors this.
#                                         - IPAC'12 introduced a with Ogonek (&#261;)
#   v15.7   30. May 2012 vrws             - conditional generation of ATC files: if a PDF file is present in the ATC subdirectory /CHECKED no new PDF is generated
#                                         - remove "protected blanks" from LateX and substituting them by " "
#                                         - introduced logo for SCKïCEN, SwissFEL, BERLinPro, sFLASH
#   v15.8   04. Jul 2012 vrws             - Hyphenator interface changed, new version 4.0.0 is used now
#                                         - ISBN imprint on papers
#   v15.9   09. Jul 2012 vrws             - missing LaTeX translation found in HB2012: "FULLWIDTH CIRCUMFLEX ACCENT" (U+FF3E = &#65342; = "^")
#                                         - ISBN imprint on papers suppressed when no ISBN is given (i.e. Team Meetings)
#                                         - special treatment for CesrTA
#                                         - check for delimiters (ß) in utf-names.txt
#   v15.10  07. Aug 2012 vrws             - fixed Unicode translation of Private Use Area U+F0B0 (&#61616;) => ∞ and U+F0B1 (&#61617;) => ± (found in LINAC2012/Korean)
#   v15.11  11. Aug 2012 vrws             - pre V16 release for Todd (BIW)
#                                         - introduced all Secret Phase Phrases in config file after discussions with Matt and Ivan
#                                         - missing LaTeX translation found in LINAC2012: "THREE-PER-EM SPACE" (U+2004  = &#8196; => "\,")
#   v15.12  30. Aug 2012 vrws             - leftover code from the session type detection from session_location removed
#                                         - change in LaTeX substitution (for U+1D9C MODIFIER LETTER SMALL C) from mathmode (\high) to textmode (\textsuperscript)
#   v15.13  19. Sep 2012 vrws             - added dot status to information in ATC
#                                         - the title shown in ATC is now again what comes from SPMS (not UPPERcased as requested
#                                         - color "violet" added for "Assigned to Editor"
#   v15.14  01. Oct 2012 vrws             - now Paper Editor and QA Editor are printed on the ATC sheets
#                                         - the paper Status is now added to the output for page_check.pl
#                                         - string for $conference_site was not sanitized therefore "|-|" appeared in the (LaTeX) output
#   v15.15  17. Nov 2012 vrws             - for SSL access to the fileserver a "--no-check-certificate" is needed, this is added by default now
#                                         - coding error in TeX files with author list: command for highlighting was a TeX command without grouping, code changed
#   v15.16  05. Dec 2012 vrws             - --no-check-certificate missing in "wget"
#                                         - --no-check-certificate wrongly enter in "move"
#   v16.0   17. Dec 2012 vrws             - problem with sorting author names to get unique entries for Author Index 
#											(detected by Tanushyam Bhattacharjee) [Abhay Kumar, BARC] and [Abhay Kumar, IUAC]
#                                         - additional data fields for INSPIRE added:
#                                           o   245_a="conference name (long name) place"
#                                           o   020_a="ISBN"
#                                           o   260_a=publisher =>"JACoW" 260_b=place of publication=>"Geneva, Switzerland" 260_c=date of publication=>"yyyy-mm"
#                                           o   100_a=editor 100_e="ed." further editors in 700_a=last,firstname 700_u=institute 700_e=email address
#                                           o   540_a="Open Access" 540_a="CC-BY-3.0" 540_u="http://creativecommons.org/licenses/by/3.0/"
#                                           o   8564_u="URL of conference proceedings"
#   v16.1   10. Mar 2013 vrws             - PAPEROUT, TALKOUT, POSTEROUT populated, so that all types of PDF can now be downloaded separately
#                                         - problems with sorting Authors (Sort/ArbBiLex problem??), code for the moment substituted by standard sorting
#   v16.1a  30. Mar 2013 vrws             - follow up on additional datafields of version v 16.0
#                                         - preparations for multiple paper_ids for one abstract_id
#                                         - new procedure "InspireHeader"
#   v16.2   08. Apr 2013 vrws             - copyright statement changed (2011 -> 2013)
#                                         - due to the new fields in the INSPIRE dataset, the following new parameters for the config file have been defined:
#                                           o  $conference_site, $conference_title, $conference_date (all these fields have been before part of 
#											   $conference_longname <= "$conference_title, $conference_site, $conference_date"
#                                           o  $conference_editor as a string with "lastname, firstname (ed.);lastname, firstname; ..."
#                                           o  $conference_pub_date has (now) the format "yyyy-mm", i.e. "2012-10"
#                                         - bug fixes/corrections made to Inspire data fields
#   v16.3   20. Apr 2013 vrws             - correcting design flaw (putting the institute behind the main author for abstract brochure/booklet, 
#											even if the group of co-authors following the main author are from
#                                           the same institute) due to its high cost (approximately 4-5 pages for the IPAC'13 booklet)
#                                         - data fields for INSPIRE updated:
#                                           o   690_c="Conference Paper" removed
#                                           o   980_a="Conference Paper" introduced
#                                           o   269_c="publication date" removed
#                                           o   260_c="publication date" introduced (date of publication <year>-<month> as "aaaa-mm")
#   v16.4   26. Apr 2013 vrws             - ENTITY record extended for &Oslash;
#                                         - file name for INSPIRE data set now contains the $conference_name
#   v16.5   01. May 2013 vrws             # found &#776; (U+0308 COMBINING DIAERESIS) after vowel
#                                         # &#8243; cursive double apostrophe "¥¥"
#                                         # &#61540; (20140131: Delta
#                                         # &#215; => \times
#                                         # &#8544;    U+2160 ROMAN NUMERAL ONE
#   v16.6   03. May 2013 vrws             - Akihiro found that some of the talks do not show up in the proceedings. Searching for a reason for this behavior showed, that
#                                           o Session and Classification generation made the inclusion of slides, poster, etc. dependent of the presence of an Abstract
#                                           o Author and Keyword generation picked up slides and posters
#                                         # report on authors with same email address and different author_ids
#   v16.7   18. Jun 2013 vrws             - added \x{011f} for "ƒü"
#                                         - change of "micro" regex from "ig" to "g" due to wrong substition of " Micro "
#                                         - more vertical space in auth1.htm for identifying institute and JACoW-Id
#   v16.8   28. Jun 2013 vrws             - multiple defined label (in authtexidx) when <lastname>+<initials> were the same, now the JACoW Id is added 
#											to the label to make it unique
#                                         - $paper_not_received_link = 0 set as default
#   v17.0   20. Jul 2013 vrws             - first try to straighten the coding of Abstracts into Unicode and LaTeX specifics (in the end it should only be UTF-8 coded)
#                                         - Sort/ArbBiLex.pm removed as is was the culprit for the problems encountered often, but finally solved in v16.1/10Mar13
#   v17.1   24. Jul 2013 vrws             - intensive debugging for call tree structure
#   v17.2   25. Jul 2013 vrws             - removed lowercase letters in "straighten_name" as there is an "/i"
#                                         - optimized "straighten_name" as most calls are without accented characters
#                                         - optimized "read_and_interpret_tags" as the following tags are now ignored and skipped at the beginning
#                                           <files>, <file>, <postal_code>, <address1>, <address2>, <address3>, <URL>, <po_box>, <zip_code>, <department>
#   v17.3   25. Jul 2013 vrws             - code reorganization
#                                         - power substitution (<sub6>) made less greedy (see comments with #!!)
#                                           o no more substitutions in Footnotes
#                                           o only for power of -1 < n > 1
#                                           o missing rescan due to removed /g
#   v17.4
#   v17.5   10. Aug 2013 vrws			  - introduced the following Unicode CJK Symbols to LaTeX conversion
#	                                        o &#12310;/U+3016 LEFT WHITE LENTICULAR BRACKET
#	                                        o &#12311;/U+3017 RIGHT WHITE LENTICULAR BRACKET
#   v18.0   18. Aug 2013 vrws             - entry of country "$contrib_cab" not needed as it is added to affiliation ("$contrib_ins" etc)
#                                         - tag <contributor type="Owner">...</contributor> will now be skipped as the "Owner" of papers have their complete <institutes>
#                                           profile embedded, not only the one(s) selected
#   v18.0a  20. Aug 2013 vrws             - more bad new: G¸nther Rehm detects bold entries in the Author-Paper list, where author is not primary. 
#											The TeX code looks OK, but...
#                                         - changed default for $bf from "" to "\mdseries"
#                                         - fixed missing closing brace for XETAidx box commands
#   v18.0d  22. Aug 2013 gr+vrws          - Worked around double special case treatment for ëmain author' in lines 2059, 2205. This replaces my patch sent earlier today, 
#                                           which only worked partially (only for single first author with multi-affil, not for first author with multi affil plus other 
#                                           authors with multi affil)
#                                         - Activated production of \FootNote lines in 2301
#                                         - Introduced new list of papers @paplist in 6514, 6551, 6596 (the essential!), 6630 to check whether a paper already appears 
#                                           in the list of papers for an author. This fixed the author index.
#   v18.0e  02. Sep 2013 vrws             - &#8201;/U+2009  THIN SPACE added
#                                         - &#65290;/U+FF0A FULLWIDTH ASTERISK added
#                                         - &#8208;/
#                                         - changed package from "txfonts" to "newtxtext"+"newtxmath" to get default upright Greek letters (\mu, etc.)
#   v18.0f  05. Sep 2013 vrws             - re-introduced different handling of CONTRIBUTORs and PRESENTERs
#                                         - changed package from "txfonts" to "newtxtext"+"newtxmath" to get default upright Greek letters (\mu, etc.)
#   v18.0g  12. Sep 2013 vrws             - wrong entry for Delta (U+25B3/&#9651;) => WHITE UP-POINTING TRIANGLE recoded as U+0394|&#916; => GREEK CAPITAL LETTER DELTA
#                                         - wrong re-encoding of (U+2206/&#8710;) => INCREMENT should be (U+0394|&#916;) => GREEK CAPITAL LETTER DELTA
#	                                      - new entry: Gaelic letter (U+0175|&#373;)  LATIN SMALL LETTER W WITH CIRCUMFLEX
#   v18.0h  16. Sep 2013 vrws             - corrected the problem of not including talks. Was caused by moved code which should have been checked 
#											for "$conference_type_indico"
#                                         - ?
#   v18.1   06. Oct 2013 vrws             - new version as 18.0h looks pretty stable now as is
#                                         - for ATC print Red/Black and "Assigned to an editor" now filtered out
#   v18.2   15. Nov 2013 vrws             - minor corrections: \acute changed \'{}
#                                         - introduced ISBN string for Proceedings Volume
#   v18.3   18. Nov 2013 vrws             - print-out of all config parameters
#                                         - code fixed for empty pass phrase ($PassPhraseDown = "")
#                                         - reduced debug output when matching authors for Author Index list
#   v18.4   11. Dec 2013 vrws             - changed shebang to be usable in *nix
#                                         - all download batch files (*wget.bat) are now renamed and moved to the PROTOCOL directory for easier checks later on
#   v18.5   25. Jan 2014 vrws             - problems with Inspire XML as the following has to be done
#                                           o  replace all non ASCII valued entities (but leave &amp; &lt; &quot; &apos; &gt; alone) 
#                                              in marcxml files with their utf-8 encoded byte values.
#                                           o  do not use inlined HTML in PCDATA fields (abstract, title, ...) -- there should be no 
#                                              '<' or other unescaped reserved XML characters in PCDATA
#                                         - first action: entity encoded strings in PCDATA removed
#                                         - new script "inspire-clean.pl" will handle the above exchange of HTML entities
#                                         - Copyright extended to 2014
#                                         - while working on the cleanup script for Inspire XML datasets the unidentified Microsoft characters 
#                                           &#61540 now has a real substitution (&Delta;)
#                                         - Gaelic letter (U+0175|&#373;) for UTF-8 substitution added
#   v19.0   12. Mar 2014 vrws             - problems with INSPIRE datasets: the first author of _each (new) affiliation_ a main_author tag is generated 
#                                           (tag="100"). The real main_author only gets the tag being the first one in the affiliation list.
#                                         - batch file generation now depends on "os_platform", valid argument are "Windows", "Linux", "MACOS"
#   v19.1   20. Mar 2014 vrws             - Win->Lunix: all "echo." changed to "echo "
#                                         - Win->Lunix: "del" substituted by "$WL_DelRM" which will expand to Win:del, Lunix:rm
#                                         - Win->Lunix: "REM" substituted by "$WL_Rem" which will expand to Win:REM, Lunix:#
#                                         - Win->Lunix: "move /Y" substituted by "$WL_Move" which will expand to Win:"move /Y", Lunix:"mv -f"
#   v19.2   05. Apr 2014 vrws, Thorsten Schwander
#                                         - conversion of INSPIRE datasets to HTML entity free XML (exceptions: &amp; &lt; &gt;) => decode_entities
#   v19.3   16. May 2014 vrws             - first test with real multiple program_codes in XML (IPAC2014)
#                                         - somehow the use of "use Time::localtime;" screws up the detection of weekdays (sub get_wday), line now commented out
#										  - &#12539;/U+30FB  KATAKANA MIDDLE DOT added
#                                         - bug fix: \MainClass didn't provide LaTeX converted text strings as it was using $paper_mcls[$pap] directly
#                                         - U+0162 added
#                                         - &#1084;| U+F061     &#347; => \'{s}           
#                                           &#305;   U+0131   (LATIN SMALL LETTER DOTLESS i)     
#                                           &#1094;  U+0446  (CYRILLIC SMALL LETTER TSE)
#                                         - unknown character U+F07E = &#61554;
#   v19.4   10. Jun 2014 vrws             - disable some LaTeX commands which play havoc on the Abstract booklet etc. if used inside abstract text 
#                                           (e.g. \author{} swallowed several pages of input)
#                                         - &#304; CAPTITAL I WITH DOT 
#   v19.5   12. Jul 2014 vrws             - MD5 hash now used as key for utf8_name entries (old version had duplicate entries when using just one letter of first name)
#                                         - aux file of LuaTeX run in gen_texpdf.bat not deleted anymore to suppress re-run message
#                                         - some authors (e.g. A.-S. Mueller) appear several times for one affiliation acronym [KIT] as this acronym is 
#                                           shared by 8 institutes/departments/...:
#                                             1   <full_name abbrev="KIT" type="Institute">Karlsruhe Institute of Technology Laboratory for Application of 
#																							Synchrotron Radiation (LAS)</full_name>
#                                             2   <full_name abbrev="KIT" type="Research Centre">Karlsruhe Institute of Technology Institute for Synchrotron
#																								 Radiation</full_name>
#                                             3   <full_name abbrev="KIT" type="Research Centre">Karlsruhe Institute of Technology</full_name>
#                                             4   <full_name abbrev="KIT" type="University Department">Karlsruhe Institute of Technology Steinbuch Centre
#																										for Computing</full_name>
#                                             5   <full_name abbrev="KIT" type="University Institute">Karlsruhe Instutute of Technology</full_name>
#                                             6   <full_name abbrev="KIT" type="University">Karlsruhe Institute of Technology Institute for Data Processing 
#																							and Electronics</full_name>
#                                             7   <full_name abbrev="KIT">Karlsruhe Institute of Technology ANKA Synchrotron Radiation Facility</full_name>
#                                             8   <full_name abbrev="KIT">Karlsruhe Institute of Technology Institute for Photon Science and Synchrotron 
#																			Radiation (IPS/ANKA)</full_name>
#                                           author/affiliation has to be reduced to one appearance per acronym: how so => different acronyms for different institutes or 
#                                           sorting out duplicate authors per acronym?!?
#   v19.6   20. Jul 2014 vrws             - MD5 hash for utf8_name entries is now based on last name + first name-initials minus all characters 
#											outside ".", "-", "a-zA-Z" group
#                                         - the problems with lowercasing ÷ have been treated by hardwiring "÷"zt¸rk in procedure "helpsort_acc_chars"
#                                         - added comment "#140724" for all appearances of "$paper_struc" which was indented to detect needed structures of one and the 
#                                           same paper but had never been reset to false
#                                           therefore probably useless (might have to be combined with "$paper_open"?)
#                                         - error in Matt's <fileURL> lines where the "paper_id" is one of a secondary code (PRIMARY="N")
#                                           e.g. <fileURL>....editor.zipdownload.pl?paper_id=WEPRO046&amp;wanted_file=SUSPSNE013_poster.pdf</fileURL>
#                                           the "paper_id" is not the same as the "wanted_file" for paper_codes which are PRIMARY="N"
#                                           temporary fix for these paper_codes by checking/exchanging the "paper_id=" part to match "wanted_file="
#                                         - all paper_code lines now have an anchor id (id="paper_code") 
#                                         - on secondary entries (MPC) the primary code is shown (text: use link for more material under primary paper code)
#                                         - secondary entries in MPC without PDFs will show hover-text "Check primary paper code for contribution" 
#                                         - secondary paper codes are shown with their primary entry (text: link to different session where 
#											this contribution was presented too)
#                                         - secondary paper codes are skipped in "Authors Index" main build, but are added as alternate paper_codes under main entry
#                                         - INSPIRE datasets finished using LaTeX for all none numeric super- & subscripts
#   v19.7   10. Aug 2014 vrws             - (v15.4) translation for "HYPHENATION POINT" (U+2027 = &#8231;) changed as it is used in IPAC'2014 as centered dot, 
#                                           therefore translation corrected to U+00B7 &#183; "Middle Dot"
#                                         - fixed Author HTML for secondary papers which got lost due to a crash
#                                         - added the same support for Classification HTML as for Author as the secondary codes from the Sunday Student Session 
#                                           appeared before all other (primary) codes
#   v20.0   12. Aug 2014 vrws             - export of citation/reference files started
#                                         - new main version as the SCS file has now the subdirectory "export_directory"
#                                         - new CSS file (confproc.css) with comment and export tags
#                                         - output of Papercode/Publishable/keywords changed: now only "not publishable" and papers with "<5 keywords" 
#											are output on the screen
#                                         - citation links have a "/" in the config specification, no additional "/" may appear in html    
#   v20.1   22. Aug 2014 vrws             - corrections to the INSPIRE data export after mail from Annette
#                                           o email-Adresse der Autoren gehoert ins $$m Unterfeld, nicht in $$e  (100/700__m statt 100/700__w)
#                                           o Konferenz-Akronym gehoert in 773__q, nicht 773__w.
#                                           o Zwei 980-Felder: 980__aConferencePaper
#                                                              980__aHEP
#                                           o Titel:  245__$$a:IPAC2014 (5th International Particle Accelerator Conference) Dresden, Germany 
#                                              new -> 245__$$a:Proceedings, 5th International Particle Accelerator Conference, IPAC2014 
#                                                     245__$$b:Dresden, Germany, 15-20 June 2014  
#                                                980 Feld:
#                                                     980__a:HEP 
#                                                     980__a:Proceedings
#                                                Editoren: 
#                                                     100__a:"Christine Petit-Jean-Genaz, Gianluigi Arduini (CERN), Peter Michel (HZDR), Volker RW Schaa (GSI)" 
#                                                  -> 100/700 mit affiliation in $$u und "ed." in $$e
#                                                        __$$u:CERN
#                                                        __$$e:ed.  
#	                                      - &#8203;/U+200B ZERO WIDTH SPACE from IBIC'14
#   v20.2   25. Aug 2014 vrws             - changed the "$\ensuremath{\muup}$" to "{\textmu}" to cover the upright "µ" problem (TeX package needed is "textcomp")
#                                         - usepackage{textcomp} added to $intro
#                                         - additional fields in config file introduced: "$conference_series", "$conference_number"
#   v20.3   09. Sep 2014 vrws             - changed the "$\ensuremath{\muup}$" to "{\textmu}" to cover the upright "µ" problem (TeX package needed is "textcomp")
#                                         - usepackage{textcomp} added to $intro
#                                         - additional fields in config file introduced: "$conference_series", "$conference_number"
#   v20.4   04. Oct 2014 vrws             - added the missing "chmod"s for all *wget.bat" scripts
#   v20.5   14. Oct 2014 vrws             - SPMS.XML now has a leading spacing in all "fileURL" tags which causes an "Unsupported scheme" in wget commands
#                                           white space removed now
#                                         - changed PDF opening mode for ATC PDFs from pdfpagemode=None to pdfpagemode=UseNone as hyperref v6.83 flags "None" as error
#   v20.6   15. Nov 2014 vrws             - added output of script line number when OPEN crashes (introduced when Maksim had problems with PuPAC'14)
#   v20.7   28. Nov 2014 vrws             - completed RIS dataset generation
#                                         - correction to INSPIRE dataset for editor's affiliation
#                                         - conference Editor removed from bibliography export format "text" and "LaTeX"
#										  - file extension for RIS data export changed from "<paper_code>.ris" to "<paper_code>-ris.txt"
#   v21.0   05. Dec 2014 vrws             - bibliographic data export can now be enabled via config file (citation_export = 1)
#                                         - page numbers for bib and LaTeX export moved after "in Proc."
#   v21.1   11. Jan 2015 vrws             - bibliographic data doesn't provide anymore commented out data fields
#   v21.2   05  Feb 2015 vrws             - corrections to the INSPIRE data export after mail from Annette
#                                           o <datafield tag="980" ind1=" " ind2=" ">
#                                               <subfield code="a">ConferencePaper</subfield>
#                                               <subfield code="a">HEP</subfield>
#                                             </datafield>
#                                             ist in jedem record auch noch 2-mal drin
#                                           o <subfield code="u">SLAC, Menlo Park, California, USA</subfield>
#                                             <subfield code="v">SLAC</subfield>
#                                             u<->v muss ich tauschen.
#											o Richtig ist aber dies - und zwar f¸r jeden record:
#												<datafield tag="980" ind1=" " ind2=" ">
#													<subfield code="a">ConferencePaper</subfield>
#												</datafield>
#												<datafield tag="980" ind1=" " ind2=" ">
#													<subfield code="a">HEP</subfield>
#												</datafield>
#											  Das heisst: zwei 980 Felder mit jeweils einem Unterfeld a. Nur der proceedings record 
#                                             muss Proceedings statt ConferencePaperhaben.
#                                         - Copyright notes updated
#   v21.3   21. Mar 2015 vrws             - additional characters encountered (ECRIS2014)
#                                           o U+0106 &#262; Latin Capital Letter C with Acute (Latin Extended-A)
#                                           o U+0171 &#369; Latin Small Letter U with Double Acute (Latin Extended-A)
#   v22.0   08. Apr 2015 vrws             - due to changes in packages newtxtext/newtxmath a TeX run stops with "Option clash for package textcomp. 
#                                           \DeclareRobustCommand {\sustyle}{%" sequence of package load changed ("textcomp" after "newtx...")
#                                         - WARNING: the MiKTeX distribution fails to compile using LuaLaTeX. It finishes without warning
#                                           Rebuilding the formats under Admin (1.) and User (2.) helps
#                                         - incorporating the clean_up scripts "clean_pdf_metadata" for removing unwanted entries in Talk_PDF and Poster_PDF.
#                                           now for each Talk_PDF a command is written (using "exiftool") which sets "Author", "Creator", "Subject" and "Title" of the file.
#											The same is true for Poster_PDFs, but as only the main author is mentioned, it is subject to revision
#   v22.1   17. May 2015 vrws             - Matt's new page correction procedure in SPMS "editor.set_page_count" is functioning and can now be used, 
#                                           to ease the job of "page_check.pl", all parameters needed for writing a batch file are now communicated via 
#                                           "pages_per_paper.txt" (Server name, Pass_up, Abstract_ids)
#                                         # Compatibility: page_check.pl v4.0 with spmsbatch.pl v22.1 and higher
#                                         - NO SPIRES records generation anymore
#   v22.2   22. May 2015 vrws             - INSPIRE records for authors with several affiliations are now combined into one $100/$700 record:
#                                           Annette: Wir verwenden das $$u Feld mehrfach, f¸r jeden Autor nur ein 100/700Feld, aber mit mehrfachen affiliations.
#											subroutines "INSPIRE_write_data_record" for combined author records and "INSPIRE_Keywords" for keyword records
#										  - small clean-up	
#                                         - all two-argument "open" statements changed to three arguments (perl:critic)
#   v22.3   18. Jun 2015 vrws             -
#   v22.4   02. Jul 2015 vrws             - new character translation of utf8 glyphs to LaTeX ^(
#                                           o Latin Small Letter T with Comma Below U+021B => no LaTeX equivalent
#											o Latin Capital Letter R with Caron U+0158 => \v{R}
#											o Latin Small Letter Z with Caron U+017e   => \v{z}
#											o Latin Small Letter a with Breve U+0103   => \u{a}
#                                         - vertical offset in Author, Participant and Institute list corrected
#                                         => to be checked, probably not true anymore => - procedure "CopyrightOffset" now called before list generation 
#                                            (Author, Institute, Participants) using the last know page count
#										  - new problem spotted: the institutes list collects authors only to the first lastname+initial agreement 
#                                           (R. Mueller/H. Shang) appears with wrong institute (HZB instead of GSI/ANL instead of INEST) 
#                                           => solved by introducing the JACoW Author Id for comparision. 
#                                         o Has to be checked: is $aaid[] the same sort order as $sorted_auth_id[]?
#                                         - obviously the multicols environment moves the footer lines up by 11pt, this has been compensated by linefeed entries in the 
#                                           list generation of Authors, Institutes and Participants 
#                                         - data format TXT for citations modified: "~" between initials and lastname changed to " "; always write out the full name
#                                           string (no: "et al."); "\url{}" removed
#   v22.4a   10. Aug 2015 vrws            - a number of missing escapes in regular expressions for LaTeX command brackets {} added
#   v22.4b   22. Aug 2015 vrws            - if a name contains an html-entity, the reg-exp screwed up the original string, fixed now. 
#											Problem still open: html entity character
#                                           as first character for sorting is not re-instituted and therefore doesn't show in print-out or web page
#   v23.0    28. Sep 2015 vrws            - corrections done when testing with Todd for MacOS
#                                           o error message for missing "names-utf.txt" was wrongly concatenated showing "." after the directory name
#                                           o OS_platform is detect inside all scripts (therefore removed from config file)
#   v23.1    11. Jan 2016 vrws            - JACoW.org => accelconf.web.cern.ch/AccelConf in INSPIRE records
#                                         - ^{&}#xxxx; error
#                                         - substitute ^{-1} and ^{-} in INSPIRE records
#                                         - additional escaped braces due to error message "Unescaped left brace in regex is deprecated, passed through in regex"
#                                         - button 'Home' in "b0nner.htm" changed from "../index.htm" to "../index.html"
#   v23.2    04. Feb 2016 vrws            - new definitions for citations (JACoW template 201602xx) 
#            30. Jan 2016 vrws            - script needs now a DOI directory for the generation of DOI XML metadata files and mds-suite records
#   v24.0    24. Feb 2016 vrws			  - DOI data set entered into INSPIRE record. Format information by mail from Kirsten Sachs
#                                         - more additions for DOI handling
#                                         - conference_url now points to the real URL where the conference proceedings appear,
#											e.g. "https://accelconf.web.cern.ch/AccelConf/IPAC2016"
#   v24.1    28. Feb 2016 vrws            - several new config specifiers introduced 
#                                           o DOI_prefix: either 10.5072 (test domain) or 10.18429 (real JACoW DOIs)
#											o DOI_site  : https://jacow.org/DOI/<conference_name>/ is site of DOI landing page
#														  (which points to https://accelconf.web.cern.ch/AccelConf/DOI/)
#											o data_generation_date: signifies the date when the data were originally available
#                                         - DOI landing page design/realization 
#                                         - generation of MDS records for registering the DOIs with DataCite (doesn't work...)
#                                         - generation for registering the DOIs with DataCite now using curl records, as this works out of the box
#										  - ???
#   v24.2    01. Mar 2016 vrws            - changes to existing config variables:
#											o conference_editor is now a list of editors containing a JACoW or ORCID Id: 
#												Volker RW Schaa (GSI, Darmstadt, Germany)[ORCID:0000-0003-1866-8570]
#											  > is has to follow the affiliation and be placed inside [JACoW:xxxx] or [ORCID:0000-xxxx-xxxx-xxxx]
#											  > each editor has to be sperarated using a ";"
#										  - new directories for XML (DOI metadata) and HTML (DOI landing page) will be automatically created below the 
#											DOI directory if not existing
#                                         - 50% run time speed up ($doi_landing_str controls now data generation in first pass only - stupid error!)
#                                         - proceed1.tex now with pdf-fields filled (hypersetup), $introhyp removed as commands are included in both setups
#                                         - DOI_useraccount introduced to shortend account and password entry for each command
#                                         - finally html error "anchor occurs multiple times" in author html files corrected. 
#											The assumption that duplication of anchors only happens due to author appearance in consecutive papers was wrong.
#										  - error fixed for authors with two (or more) affiliation at the same institute (same acronym or none) and has already appeared
#											in the first institute file (opening/closing corrected on same author, works probably only on last author in the list)
#										  - test on IPAC2014 revealed problems on conferences using secondary paper codes. $DOI_land variables are determined 
#											for paper code wwhere PDF files but secondary papercodes have their PDF under primary code. Therefore hack to set 
#											$citdoi from primary code when $DOI_land{doi} undefined
#										  - file uploads for secondary codes are flagged as mismatching files. Now these messages are suppressed when the 
#											secondary code matches
#   v24.3    10. Mar 2016 vrws            - adding "Highwire Press tags" to DOI landing and citation export pages
#										  - BiBTeX export (re)added following examples from DESY/CERN/GSI (used latest additions made for biblatex: "venue")
#										  - citation export pages converted from TXT to HTML to not confuse web server settings (.ltx desaster) and to enable 
#											correct enocding (UTF8)
#										  - missing style for @unpublished added for BiBTeX, other citation exports adapted to deliver baic data for unpublished papers
#                                         - modifications to all citation styles
#											o BiBTeX @unpublished style for unpublished papers
#											o ccc
#											o
#   v24.4    16 Mar 2016 vrws             - started addon for Institutes Page (Authors + Papers/DOIs)
#            21 Mar 2016 vrws			  - Ronny detected that no message were given for not received submissions: 
#											string for "paper_not_received_text" was quoted and screwed up the HTML for the tooltip
#											(Error: Quote ì"î in attribute name. Probable cause: Matching quote missing somewhere earlier.)
#											text will now be 'unquoted' after reading from config file
#			 23 Mar 2016 vrws			  - error in citation export for Text and LaTeX when American date writing occurs: "Sept. 13-17, 2015" maps "Sept." 
#											to day range and "13-17" to month
#   v24.5    06 Apr 2016 vrws             - problem with ",," due to missing space solved. Regular expression had for a "thin space" a "\," instead of "\\,".
#										  - changed regex for missing space after comma (the following text starts probably with a lowercase letter), 
#											also missing in the regex are braces "(" and ")"
#            10 Apr 2016 vrws             - dangling </td> in instdoi files removed
#										  - map "Dot Operator" U+22C5 to "Middle Dot" U+00B7 / \cdot ["Dot Operator" is placed higher in most fonts, ...]
#										  - unknown character &#61624; U+F0B8 converted to "ndash" as it was used as a 'to sign' in "1&#61624;4.5 GeV/u".
#										  - &#9702; U+25E6 (White Bullet) used as degree sign
#            17 Apr 2016 vrws			  - fixed empty reference to DOI-landing page in case of Secondary paper code for Endnote-XML 
#											($citdoi instead of $DOI_land{$pap_nr}{doi})
#										  - comment for INPSIRE record with JPSP version and date/time
#										  - in addition to the JPSP version (sc_version) the generation date and time is written to all HTML files
#	v24.6	05 May 2016 vrws			  - introduced "conference_sh_name": for (IBIC2015) one gets (IBIC'15)
#										  - 'but unpublished' corrected to 'unpublished' in citation export
#        a  09 May 2016 vrws			  - introduced \NoCaseChange as empty command for ATC generation
#	v25.0	01 Jun 2016 vrws			  - built in support for LuaLaTeX version >0.85
#										  - the redirection from "jacow.org/<conference_name>" to "https://accelconf.web.cern.ch/AccelConf/<conference_name>" works now, 
#											but "<conference_name>" was defined to be lowercase
#										  - sanitize INSPIRE/DOI xml from html like <strong>
#										  - finally the video directory is needed as now a video file turned up at IPAC2016 (videos had been  external links before [EPAC'04])
#											code rewritten and adapted to the handling of talks/slides
#										  - code for export of bibliographic data for text (Word) changed to HTML with italics and curly apostrophes
#	v25.1	 04 Jul 2016 vrws			  - ATC generation run with LaTeX and doesn't understand the LuaLaTeX version >0.85 fix; introduced $introbase without this fix
#	v25.2	 03 Aug 2016 vrws			  - $introbase now used for "proceed.tex" and "proceed1.tex" as they are produced using pdfLaTeX
#										  - the DOI is added to the web page before the bibliographic export
#			 06 Aug 2016 vrws			  - Jan Chrin noticed that procedure "title_short" is not used for export of bibliographic data (Int./Conf.), corrected
#										  - all instances of "$conference_site" checked and changed where necessary to _UTF or _lat
#										  - formatting for Word bib export corrected (Unicode apostrophes, no linebreaks, no typewriter)
#                                         - Creative Commons moved to "https://creativecommons.org/licenses/by/3.0/" from "http:"
#            09 Aug 2016 vrws             - new symbol in LINAC'16 &#61619; from Private Use Area - no idea what it means
#   v25.3	 21 Aug 2016 vrws			  - all greek upright commands (e.g. \muup) in LaTeX changed as it possible to use the package option 
#											\usepackage[upright]{fourier} for these cases (not checked for other font combinations)
#   v25.4    22 Aug 2016 vrws			  - due to problems with new meaningless characters in MEDSI and IBIC, a number of codes have been (re-)introduced
#											(mostly \xc2-combinations, but not all make sense)
#	v25.5	 23 Aug 2016 vrws			  - out of a sudden we have different XML tags depending on ???what??? (detected in SPMS v10.4.10)
#											MEDSI'16 has Poster session papers with <start_time> and <duration>, IBIC'16 only has <duration>, therefore many error messages
#											=> <start_time> and <duration> only checked for "Oral" now
#	v25.6	 10 Sep 2016 vrws			  - DOI reference has to go with data export flag (for Pre-Releases!!)
#	v25.7	 15 Sep 2016 vrws			  - merged branch topic #generate_index_basefile of version v24.0-exp into main.
#										  - merged branch topic #conference_longname of version v24.0-exp into main.
#   v25.8    09 Nov 2016 john poole/vrws - the abbreviated month for the publication picked up the wrong month due to wrong usage of substr 
#											(third argument is length not position)
#   v25.9        Dec 2016 vrws			  - improvements for directory structure: to be able to use the redirection from JACoW.org to CERN, the subdirs for
#											DOI metadata and html files have to follow the sequence of "<conference><doi>" and can't be a directory of its own.
#										  -	changes to the generation of bibliographic data and their presentation on the web page (/export): 
#											the BibTeX, LaTeX, Text/Word, RIS, EndNote (xml) so that the web page shows a 'code formatting' of the 
#											exported data file as text: e.g. MOXAA01-bib.html shows MOXAA01-bib.txt, which gets an additional download link.
#										  - config flags for "download_papers", "download_posters", "download_talks", download_sources", and "download_new_only" have
#											been removed as now all download batch files are generated by default.
#										  - editors must carry a unique id, either ORCID or JACoW [<id-origin:id>], to get the correct JACoWId, 
#											use https://oraweb.cern.ch/pls/jacow/xml2.author?ln=<lastname>&fn=<firstname> and search for "exact" match
#	v26.0        Jan 2017 vrws			  - new major release number as the directory structure is not compatible with the v24 configuration file anymore.
#											New (+), removed (-), prepared (~) or changed (o) configuration options:
#											- "conference_longname" is gone from the parameter list as it can be genrated from other parameters (_title, _site, _date)
#											~ "conference_pre"	signals whether it is a production run (=0) or a Pre-Release run (=1)
#											~ "conference_pre_text" carries the pre-release text to be embedded in the web pages and on each page of the papers
#												e.g. "- Pre-Release Snapshot 07-Oct-2016 18:00"
#											o "DOI_site" is only used when defined. It is now assumed that the standard directory of the proceedings will 
#												be used: http://jacow.org/<conference>/doi/ => http://accelconf.web.cern.ch/AccelConf/<conference>/doi/
#											o "doi_directory" is now the name of a single level subdirectory which is the DOI landing page (containing the DOI HTML files)
#											+ "doixml_directory" is the directory for XML and DOI registration batch files
#	v26.0a								  - modifications to the generation of Pre-releases: now the configuration option "conference_pre" flags whether it's a production
#											run or a pre-release (now the page numbers from the SPMS XML are ignored to be able to run a pre-release even when the
#											"Generate TOC values" procedure has already been applied -> like at MEDSI2016)
#	v26.0b								 => errors NOT fixed yet:
#											o unescaped "&" in exported references for EndNote (xml)
#											x (see v26.1) correct sort sequence for "ARing" in lastname as first letter
#											o wrong syntax in \high with LaTeX commands in brackets (e.g. $60\high{\}circ$ => 60\high{$\circ$})
#											o substitution of closing apostrophes not prevent wrong accent commands (e.g. " => "{}{} =>! "{} or doublequote)
#											o substitution of UTF8 sequences which let to the 'same' character (e.g. ¬-- => -- ; ¬'' => '' ; ¬'  => ')
#	v26.0c								 => missing in this release is v25.9's change of bibliographic data as there are browser issues (depending on 
#											filetype of to embedded file)
#										 => the JSON code for bibliographic data is commented out as it was not linked to on the export page 
#											(Jan doesn't see a necessity for JSON)
#	v26.0d								 => the code for automatic concatenation of paper PDFs for Author/Title Check (ATC binders) has been removed 
#											from this version (additional tools to be tested as pdfTK doesn't belong actually to the list) 
#   v26.0d      Jan 2017 vrws			  - this version published
#										  - reformatting of editor id and documentation extended
#										  - corrections for the reencoding of U+0096 (en-dash) from v13.2: some cases were not covered as U+0096 appears 
#											in UTF8 as xC5 x96. Now added.
#   v26.0e      Feb 2017 vrws			  - all parts for a the conference pre-press handling implemented and tested
#   v26.1 	 04 Feb 2017 vrws			  - problem for invalid session links for secondary paper codes solved. Procedure "find_lc_session" now find the correct
#											session name when the papercodes are not consisting of session_abbr + sequence number, but have addition characteristics
#											as Invited/Contributed/etc. E.g. NA-PAC had session "WEA1" containing papers "WEA1IO01" or "WEA1CO04"
#										  - procedure "helpsort_acc_chars" changed: as in the current locale not all characters gets lowercased using "lc", now the
#											corresponding capital letters have been entered into the substitution list. This fixes the issue of v26.0b (correct sort
#											sequence for "ARing")
#             							  - new character translation of utf8 glyphs to LaTeX 
#                                           o Latin Capital Letter D with Stroke U+0110 => –
#											o Latin Small Letter E with Circumflex and Grave U+1EC1 => \`{\^{e}}
#											o Latin Small Letter E with Circumflex and Tilde U+1EC5 => \~{\^{e}}
#										  - now the generation of bibliographic export and DOI data is suppressed when pre-press is requested ("conference_pre" = 1)
#										  - bibliographic export for Text/Word had wrong zMonth/Year 
#   v26.2 	 24 Feb 2017 vrws			  - diagnostic output for not included PDF files in "proceed1.tex"
#										  - title in InstDOI was missing UTF_convert_spec_chars and UTF_supb
#										  - trial to get "ÿ small" fixed
#										  - &#95; (underscore) was missing in convert_spec_chars2TeX
#   v26.3 	 23 Mar 2017 vrws			  - trial to fix the DOI export line in classification, author, and keyword index (pre-lim)
#										  - no tooltips ("xbt.js") in landing page HTML, entry removed
#										  - Inspire dataset moved to HTML directory 
#   v26.4	 30 Mar 2017 vrws			  - link to bibliographic data added to DOI landing page
#										  - contrary to the statement in v24.3, "Highwire Press tags" are not added to DOI landing pages
#											done now
#										  - the index for DOI per institute lists multiple entries for papers with primary and secondary codes.
#											Has to be restricted to primary
# 				                          - link to bibliographic data added to DOI landing page
#   v26.5	 10 Apr 2017 vrws	          - changed separator in "names-utf.txt" to "∞"
#             							  - new character translation of utf8 glyphs to LaTeX 
#											o \x{0131} => {\i}	Latin Small Letter Dotless I
#											o \x{015f} => \c{s} Latin Small Letter S with Cedilla
#											o \x{017b} => \.{Z} Latin Capital Letter Z with Dot Above
#										  - encoding for the units "LXAF", "LXSP", and "LTXAidx" changed to explicit "encoding(iso-8859-1)"
#											to prevent wrong encoding issues when opening with LaTeX editors (an additional line is written 
#											to ensure this "% !TeX encoding = ISO-8859-1")
#										  - introduced missing "revert_from_context" on "LXAF"/"LXSP" for the session location 
#										  - "doi:" substituted by "https://doi.org/" due to
#												 https://www.crossref.org/blog/revised-crossref-doi-display-guidelines-are-now-active/
#            18 May 2017 vrws	          - changed placement of "Pre-Release" text from [CE, CO] to [RE, LO] so it doesn't bump into the papercode
#   v26.6	 10 Jun 2017 vrws	          - changed detection of pdfLaTeX/LuaLaTeX for wrapper TeX file
#										  - introduced positioning of ISBN number if text of main classification is too long and overwrites ISBN 
#											($conference_isbn_pos  0=lower, 1=upper (standard = lower)
#                                         - TeXLGOut (proceedings.tex): all print positions of footer corrected: removed [11pt] offset in footer string
#                                           and replaced it with [-10pt] for Authors/Institutes/Participants in TeXLGOut
#										  - all print statements for "IEEE copyright notice" removed
#   v26.6a	 10 Aug 2017 vrws	          - made the banner "nowrap" to let the "Pre-Release" string take an own line 
#   v27.0    06 Sep 2017 vrws			  - new version due to change in config file: "pdf_update_only" for just downloading missing paper, talk or poster files
#            20 Sep 2017 vrws	          - Latin Capital Letter S with Acute [U+015A|&#346;]
#            15 Oct 2017 vrws	          - again a problem: &#373; Latin Small Letter W with Circumflex U+0175 utf8: "c5 b5", 
#											but as it is in "pdfauthor" we need therefore reencoding in >print TeXOut "\\hypersetup{<
#   v27.1    05 Nov 2017 vrws	          - finalizing some earlier developments
#                                         - cURL introduced; all wget calls are now serviced by curl as it is less chatty while working (see edit key #>curl)
#   v27.2    05 Dec 2017 vrws			  - concatenation of PDFs removed (temp editkey "#*?") as it wasn't fully supported 
#										  - change of imprint information of the wrapping process. 
#											o Now topline contains: conference_title, conference_name, "JACoW Publishing"
#											o line below: ISBN, DOI
#											o side line: <cc-by-image>, "Content from this work may be used under the terms of the CC BY 3.0 licence. 
#											  Any further distribution of this work must maintain attribution to the author(s), title of the work, publisher, and DOI."
#										  - $conference_isbn_pos not needed anymore as the nw header/footer information has the ISBN always in the header
#										  - position of copyright notice on even pages corrected to use the last page of the paper (instead of first)
#										  - introduced package "hyperxmp" to provide more internal fields in PDF
#											o pdflang={en}
#											o pdfcaptionwriter={JPSP (Volker RW Schaa)}
#											o pdfcopyright={Copyright (C) $year CC-BY-3.0 and by the respective authors}
#											o pdflicenseurl={http://creativecommons.org/licenses/by/3.0/}
#											o pdfmetalang={en}
#
#										  - change of positioning parameters in LaTeX due to warning from fancyheadings package: head=20.7pt (was 18pt), 
#											headsep=12pt (was 15pt)
#										  - package "bookmark" introduced to get rid of the error message "Rerun to get outlines right" when compiling the wrapper
#   v27.3    11 Jan 2018 vrws			  - ICALEPCS2017 entered video streaming links using "<fileURL type="Streaming Video">https://youtu.be/xyz</fileURL>"
#											this causes errors as the URL is not a file on the file server. For the moment disabled by skipping these entries
#										  - \nat{} produced an error as it is only allowed in math-mode
# 										  - pdf compile switch "\pdfsuppresswarningpagegroup=1" introduced to suppress messages about "PDF inclusion: multiple pdfs with page
#											group included in a single page"
#										  - "<paper_id>.out" is not produced anymore using "bookmark", therefore no need deleting it in "gen_texpdf.bat"
#										  - in Pre-Press mode with TOC already produced, the wrapper TeX files have page number "0", but the web pages show real numbers. 
#											This is now corrected
#		3a	05 Feb 2018 vrws			  - &#8210; "Figure Dash" (U+2012 = &#8210;) # used in FLS'18 as emdash 
#										  - &#8729; substition changed from "\\cdot\$" to "\\cdot"
#										  - in authindx paper_codes without PDFs do not get a link anymore but will be crossed-out
#										  - new header and footer of v27.2 introduced in "proceed.tex" + in Author, Institute, and Participants list
#										  - placement of page numbers in Author, Institute, and Participants list corrected
#										  - caveat: the changes above are not tested with alternate placement of ISBN using "$conference_isbn_pos"
#		3b	08 Feb 2018 vrws			  - $paper_not_received_text is now automatically assigned depending on $conference_pre = Pre-Press Release
#										  - $citation_export is set according to $conference_pre (no bibliographic data during Pre-Press)
#		3c	19 Feb 2018 vrws			  - new characters found in FLS2018:
#											o  &#8725;		U+2215	Division Slash
#											o  &#119864;	U+1D438	Mathematical Italic Capital E
#											o  &#120549;	U+1D6E5	Mathematical Italic Capital Delta
#
#   v27.4   25 Jun 2018 vrws			  - all TeX bib exports have been adapted to the template version Feb 2018
#										  - BibTeX record corrected (doi: without http:...; publisher: JACoW Publishing)
#										  - change of positioning parameters in LaTeX due to warning from fancyheadings package: head=22pt (was 20.7pt) [HB2018]
#	v28.0	15 Jul 2018 vrws			  - re-introduced branch code of v26.5a-c for watermarking papers from IOP's light peer review
#										  - the referee status change can appear (for SPMS 11.1.05) 
#											in a     <log_status code="REF">Referee</log_status>
#											or in a  <log_status code="DR">Dot Reassignment</log_status> line
#											therefore only the line using 
#												<referee_status code="?">status</referee_status>
#											is checked now. Default setting for all conferences is "n" (not set) as there mostly non-refereered conferences,
#											The referee watermark ($ref_watermark) will only be set when "a" (approved) is stored in $referee_stat[$paper_nr] and 
#											the string is defined in the config file
#										  - hot fix introduced for two authors in LaTeX citation output
#										  - what does "=~ s|, $||" do??? 5 times present in code?!
#										  - due to placement problems for the peer-review watermark using "fancyfoot", code removed and implemented
#											using eso-pic and ifoddpage inside of "pagecommand" of includepdf
#		0a	21 Aug 2018 vrws			  - new characters found in LINAC2018:
#										  	o  &#120590;	U+1D70E	Mathematical Italic Small Sigma
#											o  µ			all $\mu$ substituted with "µ" to get upright µ in LaTeX text
#		0b  30 Aug 2018 vrws			  - introduced a correction by Suitbert Ramberger <suitbert.ramberger@cern.ch> for timing scripts (first line shebang: "#!$^X\n")
#										  - change of positioning parameters again due to warning from fancyheadings package: head=22pt (was 20.7pt)
#                                         - \pdfsuppresswarningpagegroup now split from \ifluatex as there doesn't seem to be a corresponding \pdfvariable setting
#	v28.1   26 Nov 2018 vrws			  - Text/Word adapted to shortened LaTeX bibligraphy string (now just "in <i>Proc. $conference_sh_name</i>)
#										  - introduced web font for "Liberation Mono", so now the bibliographic data have the correct font and size (8pt)
#										  - changed file: expcit.css - containing the load of web font "Liberation Mono"
#										  - change of positioning parameters in LaTeX due to warning from fancyheadings package: head=23pt (was 22.0pt) 
#                                           [IBIC2018 could it be the 7^th? - needed 22.80183pt]
#										  - JSON now generated again to let Jan check its usibiity
#										  - removed "." after months abbreviation (see THE CHICAGO MANUAL OF STYLE, 16th EDITION (10.40, 1041) [14th EDITION (14.28, 468)])
#                                         - due to MEDSI2018, the $conference_title had to be shortend to stay on one line, now $conference_title_shrt is used (abbrevs. by "conference_title_shrt")
#
#   v28.2    05 Dec 2018 vrws			  - changed copyright notice in PDF file
#											o pdfcopyright={Copyright (C)$year Content from this work may be used under the terms of the CC BY 3.0 licence. 
#											  Any further distribution of this work must maintain attribution to the author(s), title of the work, publisher, and DOI."}
#   v28.3	 20 Feb 2019 vrws			  - all RIS records were wrong in the sense that didn't followin the RIS format definition
#											"<upper-case letter><upper-case letter or number><space><space><dash><space" as the second consecutive <space> was missing
#										  - RIS data export tag "DO  - <doi-url>" corrected to "DO  - DOI: <doi-url>"
#										  - RIS data export tag "C1  - <place published>" modified to "CY  - <conference location>"
#										  - typo "Proccedings" twice in "instDOI-html" generation
#										  - "$debug_restricted" extended to text output from/for abstract and conversion procedures
#   v29.0	 15 Mar 2019 vrws			  - error fixed which cause wrongly sorted Institute lists
#											o CEA/DAM-CEA with CEA shortest ended as last in list
#										  - only ISO 8601 date format accepted for conference dates and is reformatted for the use in the scripts
#										  - the abbreviated date format now uses 3-letter with period (e.g. Apr.-May 2014)
#										  - the RIS records are now in agreement with Wikiperdia "https://en.wikipedia.org/wiki/RIS_(file_format)" and 
#											"http://www.researcherid.com/resources/html/help_upload.htm" all links to the "RIS Format Specification" on 
#											"http://www.refman.com/support/risformat_intro.asp" are now dead ends on "www.clarivate.com/Endnote/"
#										  - all RIS datasets are now written to "$protocol_directory:<paper_id>.ris" and then used to be copied into the exported
#											"<paper_id>-ris.htm" or copied together for the download via the institute DOI page link to "<instDOIxxxx>.ris"
#										  - no idea why "UTF_convert_spec_chars" leaves out "&,>,<" *[see v32.2] ("decode_entities" added for abstract export)
#                                         - ISSN imprint on papers
#										  - ISSN in data exports; unclear for MARC export whether subfield codes ($2 - Source ISSN Center responsible for assigning 
#											and maintaining ISSNs and related data) has to be coded for different ISSNs 
#										  - record <log_status code="FUP"> is now read and the corresponding timestamp is stored as "Paper received"
#   v29.1	 03 Apr 2019 vrws			  - implementation of more PDF metadata using "hyperxmp" version 4.1 (when using v29.1 make sure that at least v 4.1 is installed)
#											options provided "o" and implemented "#", all option with "x" are not set (at the moment or do not make sense for JACoW papers)
#											options with "!" are set by the TeX compiler during runtime of the wrapper
#											o  x pdfapart			conformance with PDF/A-xy  i.e. pdfapart=1
#											o  x pdfaconformance	conformance with PDF/A-xy  i.e. pdfaconformance=B ~>  PDF/A-1B
#											o  x pdfauthortitle		<prim author's title>
#											o  x pdfbookedition		names the edition of the book
#											o  x pdfbytes			<size> not set as the size is always the size from the last run
#											o  # pdfcaptionwriter	{JPSP (Volker RW Schaa)}
#											o  # pdfcontactaddress	{Planckstr. 1}
#											o  # pdfcontactcity		{Darmstadt}
#											o  # pdfcontactcountry	{Germany}
#											o  # pdfcontactemail	{v.r.w.schaa@gsi.de}
# 											o  # pdfcontactphone	{49 6151 71 2340}
# 											o  # pdfcontactpostcode	{64291}
#											o  x pdfcontactregion	--
#											o  # pdfcontacturl		{https://jacow.org}
#											o  # pdfcopyright		CC by 3.0 ......
#											o  ! pdfdate			<!TeX>
#											o  # pdfdocumentid		--
#											o  # pdfdoi				<DOI>		pdfdoi={10.18429/JACoW-<conference>-<paper code>} without http or doi
#											o  # pdfeissn			<ISSN>
#											o  ! pdfinstanceid		--
#											o  # pdfisbn			<ISBN>
#											o  # pdfissn			<ISSN>
#											o  ! pdfissuenum		the issue number within the volume -> pdfvolumenum
#											o  # pdflicenseurl		<cc-by-3.0>
#											o  ! pdfmetadate		<!TeX>		
#											o  # pdfmetalang		{en}	<en-US, en-GB, de, ..> if not defined same as "pdflang"
#											o  # pdfnumpages		<SP+#Pages-1>
#											o  # pdfpagerange		<SP-EP>
#											o  # pdfpublisher		{JACoW Publishing}
#											o  # pdfpublication		Proceedings of $conference_name
#											o  # pdfpubtype			<journal> if
#											o  ! pdfsource			--
#											o  x pdfsubtitle		--
#											o  ! pdftype			default text
#											o  # pdfurl				https://jacow.org/IPAC2018/   "pdfurl" points to the complete url for the document.
#											o  ! pdfversionid		--
# 											o  ! pdfvolumenum		--
#										  - the author string before version v29.1 was wrongly implemented as it contained the institute in "[...]". The institute string had commas
#											between acronym, city and country which led to wrong author names in the metadata as names are expected to be separated by commas
#										  - corrected: author string should have each name only once, due to the implementation with institute they appeared multiple times
#										  - modified the Copyright statement on the DOI landing page
#   v29.2	 13 Apr 2019 vrws			  - some corrections are done to "confproc.css" to achieve closer W3C validation
#										  - added missing ALT tag for Creative Commons CC logo on DOI page 
#										  - "type" attributes for style sheets (CSS) and scripts (JavaScript) removed as they are standard in HTML5
#										  - new diagnostic output for Initials which seem too long (> 6 chars)
#										  - tag "asynch" in <script> has not been applied as hyphenation (en.js) will stop
#										  - update to the landing page with removing part of the 'conference specific data' (Session (name, date), Main/Sub Classification, Keywords)
#										  - changes alignment for authors field on DOI landing page to "left"
#										  - removed link to full conference on JACoW now placed under "Conference"
#   v29.3	 26 Apr 2019 vrws			  - record <log_status code="FQ"> is now read and the corresponding timestamp is stored as "Paper accepted"
#   v29.4	 01 May 2019 vrws			  - problems with versions since spmsbatch-190315 (v20.0)  
#										  - to ease searching for starting page number in TeX files, the name of the paper is now placed after \setcounter{page}
#										  - for the generation of "proceed1.pdf" one pdfLaTeX run should be sufficient as there are no toc/tof/or else
#										  - correction of an error which was introduced in version 28.1 (2018-11-25) for ATC generation (\\fancyhead[CE,CO] had "\\small[CE,CO])" 
#											as text output with not closing brackets
#   v29.5	 15 May 2019 vrws			  - generation of REFDB file for inclusion of new datasets of conferences in "Reference Search Tool" 
#										  - # Latin Small Letter R with Caron [U+0159|&#345;]
#   v29.6    10 Jun 2019 vrws			  - a number of automatic conversions added 
#											* Nb3Sn, Nb2N, Nb2O5, Nb+, BBr3, SiO2, SnCl2, N2, H2, MgB2, H2SO4, HNO3
#											* nanoohm, nOhm
#											* Eacc, Q0
#											* Qext
#											? [0-9]\.∞C (not yet)
#										  - REM delete statements removed from gen_texpdf (smaller file)
#										  - for all "lower" or "UPPER" names, print key and index now
#											==> remark "# presenter should have utf8"
#											*
#   v29.7    10 Jul 2019 vrws			  - additional XMP records written with v29.1 of 03 Apr 2019 cause problems with CERN search engine.
#											after debugging with Ismael Posada Trobo <ismael.posada.trobo@cern.ch> the decision is to get back to pre v29.1 settings
#											and especially no XMP records introduced by the xmp package for AIIM and PDF/A with empty arguments ("[]"). For the time
#											being there is no solution for this as the CERN search engine will be phased out beginning 2020, meaning there isn't and
#											won't be any new development on it. A colleague of Ismael is developing the new CERN Search based on a technology totally
#											different, so they are completely focused on it. To deal with XMP in the current CERN Search, to install a new IFilter is
#                                           needed, configure it, and so on, so it can take months to make it work because it will require lot of testing. From the
#                                           technical and resources point of view, it's worth focusing in the new system and adapt this new one to this specific case.
#											So all XMP additions of v29.1 are commented out in the TeX file generation and it's tested for IPAC2019 
#   v29.8    16 Aug 2019 vrws             - TiO2, CH4, CO2
#                                         - Michaela found out that PDFs with embedded videos are not displayed by browser internal PDF viewers; therefore a test
#											is made about videos in PDF (function "check_video_in_talk") and a warning is displayed as hover element on the link.
#											The warning reads "This PDF contains x videos which might not run in browser mode - download PDF". 
#   v29.9    29 Aug 2019 vrws               &#305;   U+0131   (LATIN SMALL LETTER DOTLESS i)
#   v30.0    30 Sep 2019 vrws			  - new line for authors who do not provide material for publication 
#											($no_material_mark = 1 and $no_material_text = "... no material provided ...")
#										  - page number box hidden for papers without paper
#										  - introduced "$" (end of string compare) for all PDF downloads ($wget_fullfilename) to prevent problems with files like ".pdf.pdf"
#   v30.1    28 Oct 2019 vrws             - "NoMat"	is inactive for now (until problems with oral/poster detection is solved)
#										  - JSON production for references/bibliography switch off again as the main function to be used for
#											an indexing database (-> Jan Chrin) is now solved by "ref.ipac19.org"
#                                         x problems detected in COOL2019 with accented character names in session display when author is a presenter
#											compared to other ways of displays:
#											* accented character names are shown in lists of author, keyword, classification, institutes, but the presenter mark is missing
#											* session shows the presenter mark but does not have accented characters
#										  - DOI format changed in RIS record: "DO  - doi:$citdoi" (lowercase doi, no space)
#										  - LaTeX export format changed (check edit mark: #') 
#                                         - BibTeX export format changed
#											* "booktitle" contains now only "Proc. conference"
#											* "month" now lowercase without "." (see change of $pub_month_abbr below)
#											* "publisher" has now {JACoW Publishing, Geneva, Switzerland} without "address"
#											* "issn" newly introduced 
#										  - Text/Word export now with font type setting for "Times New Roman" to ensure correct copy and
#											paste in Word
#										  - $pub_month_abbr (only used in BibTeX) definition changed to lowercase without "."
#										  - file name check: "^" and "$" introduced to make sure only correctly named files are downloaded
#   v30.2    06 Nov 2019 vrws             - again back to modification marked as #110217 in v12.9 of 14-17 Feb 2011 that TeX files to be 
#											compiled with LuaLaTeX are written with the encoding tag UTF-8, but the encoding of the TeX file 
#											has no encoding marked for writing
#	v31.0	 10 Nov 2019 vrws			  - problem with UTF-8 name handling, decoding SPMS names with UTF-8 bytes or HTML entities, or Windows-1252
#											strings, makes encoding too complicated. Therefore "names-utf.txt" changed to carry the JACoW Id as
#											entry for name transcoding. Now the SPMS name entry will not be used anymore but substituted by
#											the name in "modnames-utf.txt"
#										  - warning text for PDF videos run in browser 
#										  - new fields/changes for Kirsten Sachs
#										  - new output in HTML headers to identify JPSP script name and modification date 
#                                         - changed/additional data fields for INSPIRE (email with Kirsten Sachs)
#											o~	<dataset>  =>  <collection>
#											o~ 	ISBN ohne hyphen:	020__a:978-3-95450-218-9   =>   020__a:9783954502189
#											o-	100/700__u  deleted (in "u" kommt die INSPIRE Kurz-Form, das uebersetzen wir automatisch beim laden)
#											o~	7/100_a="Schaa, Volker RW"  =>  "Schaa, Volker R.W."
#											o-	540__a:Open Access
#											o+	980__a:HEP
#											o+	980__a:Proceedings
#                                           o   8564_y="JACoW"
#											o~	8564_u:https://jacow.org/cool2019/papers/mox01.pdf   change to
#											o+	FFT__a:https://jacow.org/cool2019/papers/mox01.pdf
#											o+	     y:Fulltext
#											o+	     t:INSPIRE-PUBLIC
#											o+	773__y:2018   (year of publication)
#										 !!! optimization needed for file operation like checking for slides, size, video, ...
#
#	v31.1	 10 Feb 2020 vrws			  - check of all changes of v 31.0 to find missing HighwirePress_Tags
#
#	v31.2	 Apr/May 2020 vrws			  # implementation of security features found using <webbkoll.dataskydd.net>
#											o Content Security Policy (CSP) header
#										  ~ currently removed as they conflicted with local (!!) script execution (hyphenation, xbt)
#										  - strings [˘˙˚Ÿ⁄€] and [¸‹] were missing there "[]" in helpsort_acc_chars
#										  - cite key for BibTeX/LaTeX may not include "'"
#
#	v31.3    16 Jun 2020 vrws			  - instdoi.htm wasn't displayed correctly due to wrong escaping of strings in "DHTM qq(<frameset rows"
#										  - "DC.issued" in DOI HTML record had ªcontent="$meta_cit_date"´ without ª$´
#										  - "√£" -> „ added to helpsort_acc_chars"
#										  - removed "$utf8_mode" as it was set to "true" without alternate code
#
#   v31.4    30 Jun 2020 vrws             - reacting on the mail from "Artemis Lavasa <artemis.lavasa@cern.ch>" concerning the update
#											of DOI XML records from Datacite Metadata Schema 3.1 to the now required 4.3
#											First action was to just increment the kernel number "https://datacite.org/schema/kernel-3"
#											to "kernel-4". Further adaptions are needed (e.g. affiliation should be easy as long as
#											no ROR or ISNI is required; same for funding)
#
#   v31.5    23 Aug 2020 vrws   		  - &#65285;   U+FF05  % (Fullwidth Percent Sign)
#										  - LaTeX package "ulem" changed to "soul" as it allows hyphenation in underlined words;
#											in addition \uline has been changed to \ul for "soul"
#										  - removed duplicate "alt" in "b0nner.htm"
#										  - Cs2Te, CaF2 added
#
#† v31.6     30 Sep 2020 vrws             - missing strikethrough command (\sout) after switching from LaTeX package "ulem" to "soul"
#                                           changed "\sout{}" to "\st{}"
#										  - update of "http" to "https" for all currently used addresses (not historic or documented URLs nor
#                                           xsi resource like "xsi:schemaLocation", "xmlns", "xmlns:xsi")
#
#† v32.0     15 Oct 2020 vrws             - exporting abstract content to new directory /ABS for keyword search (Kazuro wants this for ICALEPCS),
#											this is an extend to the option of reading abstracts from files when missing.
#										  - directory setting for "abstract_insert" has been changed from "raw_paper_directory" to "abstract_directory"
#
#  v32.1     22 Oct 2020 vrws	          - new code for display of videos tested
#										  - new symbol/icon introduced for slides and videos
#                                         - separate download command file (videoget.bat) for talk videos (actually only mp4 enabled currently) 
#                                         - loading the package "ifluatex" throws errors in the "LaTeX2e <2020-10-01> patch level 1" version, 
#											therefore changed to "iftex"
#
#  v32.2     19 Nov 2020 vrws	          - Slide and Poster show wrong (paper_code[pap]) when upload to multiple codes is allowed in SPMS,
#											now only the primary papercode is checked and displayed (prg_code[pap][prg_code_p[pap]])
#
#  v32.3     10 Dec 2020 vrws             - comment for the remark on v29.0 15 Mar 2019: no idea why "UTF_convert_spec_chars" leaves out "&,>,<"
#											the procedure used in this routine (decode_entities) is defined this way (but the solution is 
#											exactly mimics this behaviour)
#											if the opposite is wanted "encode_entities" with filter for invalid characters should be used
#     									  - introduced the following Unicode CJK Symbols for web conversion (UTF8 byte representation)
#											these sy,bols were already introduced with v17.5 on 10. Aug 2013 for the LaTeX conversion
#	                                        o &#12310;/U+3016 LEFT WHITE LENTICULAR BRACKET 
#	                                        o &#12311;/U+3017 RIGHT WHITE LENTICULAR BRACKET
#     									  - changed \xc2\xbf from "Inverted question mark" to "Single quote" (was done already in LaTeX conversion (04.08.10))
#										  - major change is the restructuring of calls to the following procedures:
#											* convert_spec_chars_TXT
#											  -> UTF_convert_spec_chars
#												 -> convert_spec_chars
#												 -> UTF_supb
#												 -> decode_entities
#											* encode_entities ('<>&"') is only employed where material is written to XML files (Endnotes, INSPIRE)
#										  - addded missing XML header (<?xml version="1.0" encoding="UTF-8"?>) to all Endnote XML files (CITEXP)
#                                         - https://jacow.org/ changed to https://www.jacow.org/ to save one redirection 
#											(first conference with new setting is IBIC2020)
#										  - to prevent rejection bei datacite.org when DOI site contain a subdomain like "www." this string is therefore removed
#										  - the Endnotes record has 2 entries for <pages>; one with the page numbers, the other with the paper code
#										  ? is there no entry type for editor in Endnotes?
#										  - as safe measure, text string in BibTeX export are put in double curly braces to ensure correct capitalization
#
#  v32.4     05 Feb 2021 vrws             - extended "<conf_id>-refdb.csv" to contain DOI and PubStatus for inclusion in "refs.jacow.org"
#
# todo
# -----
# unsolved issue:
#  o  Presenter-NameSubstitution-AuthorList  see/compare COOL2019 Joergensen in session (TUPS) and author list
#  o  some of Kirsten's change wishes are missing in versions >31.0
#  o  !!! optimization needed for file operation like checking for slides, size, video, ...
#  o  full Datacite Metadata Schema 4.3 "adaption"
#  o  LaTeX skeleton for Copyright page which has been introduced with NAPAC2019
#  o  sanitizing XML (Endnotes) when not allowed characters appear [&, < and > (as well as " or ' in attributes)]
#  o  if funding (<agency>) only contains Space or U+3000 IDEOGRAPHIC SPACE/&#12288; it should be skipped
############################################################################
 use Data::Dumper;		#not needed any more

 use utf8;
 no utf8;

 use Carp;
# use Text::Capitalize;	# not available anymore in ActivePerl 
 use Digest::MD5   'md5_hex';
 use File::stat;
 use File::Basename;
 use File::Path qw(make_path);
 use Getopt::Long;
 use HTML::Entities;
 use Time::HiRes  'gettimeofday';
 use Time::Local  'timelocal_nocheck';
# use Time::localtime;
 use Unicode::Normalize;
 use strict;
 no strict 'refs';

 use vars qw ($jpsp_script $jpsp_script_date);
 use vars qw ($conference_SPMS);
 use vars qw ($conf_close $confhead $conference_type_indico);
 use vars qw ($session_open $session_start $session_nr $session_struc $abbr_prefix $sess_name);
 use vars qw (@session_name @session_startp @session_endp @session_abbr @session_date @session_btime @session_etime);
 use vars qw ($session_name $session_startp $session_endp $session_abbr $session_date $session_btime $session_etime $session_newday);
 use vars qw (@session_location @session_type @sess_loc @sess_color @sess_abb @sess_class @sess_mod);
 use vars qw ($session_location $session_type $sess_loc $sess_color $sess_abb $sess_class $sess_mod $session_locrd $session_codes);
 use vars qw ($presentation_type);
 use vars qw (@talk_btime @talk_duration @talk_etime);
 use vars qw ($talk_btime $talk_duration $talk_etime);
 use vars qw (@inst_author @sorted_institutes);
 use vars qw ($inst_author $inst_author_nr $institute_nr $num_of_institutes $inst $institute_open $sorted_institutes);
 use vars qw ($act_inst $act_abr $inst2file $ris2file $ini_from_firstname $ctr_abb);
 use vars qw (@authors $author_nr $act_auth $author_max_nr);
 use vars qw (@chair_ini @chair_lst @chair_fst @chair_mna @chair_ema @chair_inst_name @chair_inst_abb @chair_aid);
 use vars qw ($chair_ini $chair_lst $chair_fst $chair_mna $chair_ema $chair_inst_name $chair_inst_abb $chair_aid);
 use vars qw (@chairs $chair_open $chair_nr $chair_i $contrib_nr $person_mode $OTHER $CONTRIBUTOR $CHAIR $PRESENTER);
 use vars qw (@contrib_typ @contrib_ini @contrib_lst @contrib_fst @contrib_mna @contrib_ema @contrib_aid @contrib_ins @contrib_abb);
 use vars qw ($contrib_typ $contrib_ini $contrib_lst $contrib_fst $contrib_mna $contrib_ema $contrib_aid $contrib_ins $contrib_abb);
#¸ use vars qw (@contrib_cab $contrib_cab);
 use vars qw (@jacowid $jacowid);
 use vars qw (@contrib_ln8 @lastname_8 @contrib_in8 @lastname @firstname_8 @firstname @firstini_8 @firstini @aaid);  # utf-8
 use vars qw ($contrib_ln8 $lastname_8 @contrib_in8 $lastname $firstname_8 $firstname $firstini_8 $firstini $last_aid $aaid);  # utf-8
 use vars qw ($num_utf8_names %utf8_names $utf8_names $auth8 );  # utf8
 use vars qw (@lastname_new $lastname_new @firstname_new $firstname_new);
 use vars qw (@presenter_typ @presenter_ini @presenter_lst @presenter_fst @presenter_mna @presenter_ema @presenter_aid @presenter_ins @presenter_abb);
 use vars qw ($presenter_typ $presenter_ini $presenter_lst $presenter_fst $presenter_mna $presenter_ema $presenter_aid $presenter_ins $presenter_abb);
 use vars qw (@main_author $main_author $main_author_key $main_author_indx);
 use vars qw (@sorted_all_idx_authors @sorted_authors @sorted_auth_id @sorted_all_idx_inst);
 use vars qw ($sorted_all_idx_authors $sorted_authors $sorted_auth_id $sorted_all_idx_inst $act_aid);
 use vars qw ($authname $auth $ale_auth @auth_list_pdf $auth_list_pdf @auth_list_pdf_tex $auth_list_pdf_tex);
 use vars qw (@paper_code @paper_mcls $paper_mcls_last @paper_scls $clsMline $clsSline @page_start $page_start_toc @paper_pages @paper_editor $paper_editor @qa_editor $qa_editor);
 use vars qw (@paper_abs @paper_abs_utf @paper_abs_ltx @paper_agy $paper_agy_switch @paper_ftn $paper_ftn_switch);
 use vars qw ($paper_open $paper_nr $paper_nr_max $pap_num $paper_struc $pap @paper_with_pdf $paper_with_pdf);
 use vars qw (@paper_with_raw_pdf $paper_with_raw_pdf @paper_pdf_size $paper_pdf_size @paper_pub $paper_pub $paper_publishable);
 use vars qw (@paper_dotc $paper_dotc @paper_recv $paper_recv @paper_acpt $paper_acpt);
 use vars qw (@video $video @stream $stream $slide_name @slides $slides $slide_open $src_open $src_nr $src_docname $src_doc $src_tex $src_odt $src_type_ctr $src_platform_last);
 use vars qw (@title $title_text $title_open);
 use vars qw ($keyw_open $keyw_text $abstract_open $abstract_text $abs_nyr $footnote_open $footnote_text $agency_open $agency_text);
 use vars qw (%set $set $PPL_ltx $PPL_ctx $PPL_xtx);
 use vars qw (@keywords $keyword_open $num_of_keywords @keywords_sorted $keywords_sorted %keywjoin @keywjoin $keywjoin);
 use vars qw (@referee_stat $referee_stat $ref_watermark $ref_watermark_prt);
 use vars qw ($name $key $i $j $k $icl $CropBoxY);
 use vars qw ($html_content_type $ahtmlfile $num_authindex $alph_authindex $alph_authchar $alph_letters $ialentry);
 use vars qw ($keyw_letters $act_keyword $introbase $intro $intromis $introdoc $introdoc8 $introdocATC $pg_idx $sess_idx $num_of_sessions);
 use vars qw ($conference_xmlfile $conference_logo $conference_logo_size $logo_width $logo_height $logo_image $banner_height);
 use vars qw (@editor_list $editor_list $editor_affil $citation_export $debug_restricted);
 use vars qw ($conference_url $conference_respm $conference_longname $conference_name $conference_sh_name $conference_site_lat $conference_site_UTF $conference_series $conference_number $pdf_update_only);
 use vars qw ($conference_site $conference_title $conference_title_shrt $conference_date $conference_editor $conference_isbn $conference_isbn_pos $isbn_str $issn_str $conference_pub_date );
 use vars qw ($conference_pub_by $conference_pub_copyr $series_issn);
 use vars qw ($debug_file $debauthfile $content_directory $html_directory $img_directory $image $paper_directory $xml_directory $poster_directory $protocol_directory $abstract_directory $abstract_export);
 use vars qw ($raw_paper_directory $atc_directory $atc_print $lexical_sort $paper_not_received_text $paper_not_received_link $export_directory);
 use vars qw ($doi_directory $doixml_directory $DOI_prefix $DOI_site $DOI_useraccount $DOI_xmlfile $DOI_address $DOI_landing_page $num_of_doipl $DOI_landing_str %DOI_land %DOI_xml @paper_fss $paper_fss);
 use vars qw ($PassPhraseDown $PassPhraseUp $PassPhraseExtract);
 use vars qw ($hyperl);
 use vars qw ($session_intro_pages $session_intro_toc $session_div_pages);
 use vars qw ($slides_directory $substitude_blank_with);
 use vars qw ($audio_directory $video_directory);
 use vars qw ($proceedings_volume_switch $context_switch $abslatex_switch $affil_abbr);
 use vars qw ($cls_fl $num_of_classifications $cls_fl_str $cls_open $mcls $scls);
 use vars qw ($ZeHn $no_pdf_switch $no_pdfs $no_raw_pdfs $start_tm $stop_tm $santitle $abbinsthtml);
 use vars qw ($wget_filetype $wget_type $wget_filename $wget_fullfilename $wrt_dir $spms_xml_file $external_xml $test_flg $filename_last_used);
 use vars qw ($sc_version $version_script_bt);
 use vars qw ($session_skip @sess_skip_list  $sess_skip_list  $sess_skip_list_anz  $skip_this_session $sess_skipping);
 use vars qw ($paper_skip   @paper_skip_list $paper_skip_list $paper_skip_list_anz $skip_this_paper   $paper_skipping);
 use vars qw ($Ignore_this_part);
 use vars qw ($insert_abstract $indico_cut_of_trailing_ho $indico_uppercase_session $indico_code_prefix $abstract_omission_text $abstract_insert);
 use vars qw ($TeXhighlite $paper_strike_thru);
 use vars qw ($favicon $favicon_ani $ccby_logo $jacow_hdr $snapshot);
 use vars qw (@weekday @month @monthab $conf_month_abbr $pub_month_abbr $Wday $Wsday $Smonth);
 use vars qw (%id_abstract @abs_id @prg_code @prg_code_p @prg_pres @prg_dura @prg_btim @prg_etim);
 use vars qw ($id_abstract $abs_id $prg_code $prg_code_p $prg_pres $prg_dura $prg_btim $prg_etim $prg_idx $prog_codes $abstr_id $xml_program_codes);
 use vars qw ($os_platform $os_platform_id $WL_DelRM $WL_Rem $WL_Move);
 use vars qw ($code_link_prim_text $code_link_altern_text);
 use vars qw ($conference_pre $conference_pre_text $copyr_prepress $page_count_set);
 use vars qw ($outcat);
 use vars qw ($deb_sub_cnt $deb_cnt $deb_calltree $pubyear_nr $pubmonth_nr $pubday_nr $pubmonth_alf);

 use vars qw ($cpx_pos_off);
 use vars qw ($filesize $fss);
 use vars qw ($uplow);
 use vars qw ($data_generation_date $generation_date $generation_time $actual_year);
 use vars qw ($no_material_mark $no_material_text);
#
# arrays to hold the names of each day of the week and
#                    name of the months (starting with 0)
#
@weekday = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
@month   = qw(January February March April May June July August September October November December);
#@monthab = qw(Jan. Feb. Mar. Apr. May June July Aug. Sep. Oct. Nov. Dec.);
@monthab = qw(Jan. Feb. Mar. Apr. May Jun. Jul. Aug. Sep. Oct. Nov. Dec.);
#
# data generation date from actual date/time
#
my ($igs, $igm, $igh, $mday, $mon, $year) = localtime();
$actual_year	 = sprintf ("%4d", $year+1900);
$generation_date = sprintf ("%d-%02d-%02d", $actual_year, $mon+1, $mday);
$generation_time = sprintf ("%02d:%02d", $igh, $igm);
#
# file name for concatenation PDF for all wrapped PDFs
#
$outcat	= "proc_concat_".$generation_date.$generation_time.".pdf";
#
# find full script name and last modification date (for print out in HTML headers)
#
JPSP_Script_ND ();
#
# version id
#
$sc_version = "v=32.3=c 16 Dec 2020 vrws";
print "\nyou are using ---> >$sc_version<\n";
print "  script name ---> >$jpsp_script<\n";
print "  script date ---> >$jpsp_script_date<\n";
#
# just to make sure the HTML files follow a defined "html_content_type"
#		structure/definition, the HTML type is set here
#
$html_content_type 	= "<!DOCTYPE html>";
#
# start time
#
$start_tm = gettimeofday;
#
# alternative options for testing independent from config file definitions
#
 GetOptions ("xml:s"   => \$external_xml,
             "test!"   => \$test_flg);
#
# different classes of type related substructures
#
 $OTHER             = 0;     # Owner
 $CONTRIBUTOR       = 1;     # Author, Co-Author, Primary Author
 $CHAIR             = 2;     # Chair
 $PRESENTER         = 3;     # Presenter, Speaker
 $person_mode  = $OTHER;     # Owner

  %utf8_names = ();           # empty utf-8 name hash
#
# special constant
#
 $ZeHn = "10";
#
# text for links for primary/alternate paper code
#
 $code_link_prim_text    = "&nbsp;&nbsp;use link to access more material from this paper's primary paper code";
#$code_link_altern_text  = "&nbsp;&nbsp;use link to see this paper's listing at this alternate paper code";
 $code_link_altern_text  = "&nbsp;&nbsp;use link to see paper's listing under its alternate paper code";
#
# intro strings for TeX files
#
#   $introbase   basic (without LaTeX85 fix) for the wrapper
#   $intro       for the wrapper
#   $intromis    to produce TeX files as substitute for missing (contribution not received) papers
#   $introdoc    complete proceedings volume
#   $introdoc8   single files without input encoding using LuaLaTeX
#   $introdocATC single files for Author/Title Correction with Pagemode and Startview
#
$introbase = "\\pdfminorversion=6\n".
             "\\pdfinclusioncopyfonts=1\n".
			 "%\n".
			 "% Generated by JPSP version $sc_version on $generation_date at $generation_time\n".
			 "%\n".
             "\\documentclass[twoside]{book}\n".
             "\\usepackage{luatex85}\n".
             "\\usepackage{cmap}\n".
             "\\usepackage[T1]{fontenc}\n".
			 "\\usepackage[english]{babel}\n".
             "\\usepackage{newtxtext, newtxmath}\n".
			 "\\usepackage{textcomp}\n".
             "\\usepackage[scaled=0.9]{beramono}\n".
#             "\\usepackage{thumbpdf}\n".
             "\\usepackage{setspace}\n".
             "\\usepackage{color}\n".
             "\\usepackage[papersize={595pt,792pt}, body={483pt, 680pt},\n".
             "            top=54pt, left=56pt, head=23pt, headsep=12pt, footskip=17pt]{geometry}\n".
             "\\definecolor{blue}{rgb}{0.2, 0.2, 1.0}\n".
             "\\definecolor{black}{gray}{0.0}\n".
             "\n";

 $intro    = "% !TeX program = lualatex\n% !TeX encoding = utf8\n".
			 "\\input iftex.sty\n".
			 "\\ifluatex\n\\edef\\pdfinclusioncopyfonts {\\pdfvariable inclusioncopyfonts}\n".
			 "\\edef\\pdfminorversion {\\pdfvariable minorversion}\n".
			 "\\else\n".
			 "\\pdfsuppresswarningpagegroup=1\n".
			 "\\fi\n".
             $introbase;

 $intromis = $intro.
             "\\usepackage[latin1]{inputenc}\n".
             "\\pagestyle{empty}\n".
             "\\thispagestyle{empty}\n".
             "\\setlength\\emergencystretch{.5em}\n";

 $introdoc = $intro.
             "\\usepackage[latin1]{inputenc}\n".
             "\\usepackage[final]{pdfpages}\n".
             "\\includepdfset{pages=-, noautoscale, offset=0pt 0pt}\n".
#IPT			 "\\usepackage{hyperxmp}\n".
             "\\usepackage[pdfencoding=unicode, hidelinks]{hyperref}\n".
			 "\\usepackage{bookmark}\n".
             "\n".
             "\\usepackage{fancyhdr}\n".
             "\\pagestyle{fancy}\n".
			 "\\fancyhead[RE,LO]{}\n".
			 "\\fancyhead[RO,LE]{}\n".
			 "\\renewcommand{\\headrulewidth}{0pt}\n".
             "\n";

 $introdocATC = $introbase.
             "\\definecolor{violet}{rgb}{0.8,0,0.9}\n\n".
             "\\usepackage[latin1]{inputenc}\n".
             "\\usepackage[final]{pdfpages}\n".
             "\\includepdfset{pages=-, noautoscale, offset=0pt 0pt}\n".
#IPT			 "\\usepackage{hyperxmp}\n".
             "\\usepackage[pdfencoding=unicode, pdfpagemode=UseNone, pdfstartview=FitH]{hyperref}\n".
			 "\\usepackage{bookmark}\n".
             "\n".
             "\\usepackage{textpos}\n".
             "\\usepackage[code=Code39,X=.3mm,ratio=2.25,H=1cm]{makebarcode}\n".
             "\\usepackage{fancyhdr}\n".
             "\\pagestyle{fancy}\n".
			 "\\fancyhead[RE,LO]{}\n".
			 "\\fancyhead[RO,LE]{}\n".
			 "\\renewcommand{\\headrulewidth}{0pt}\n".
             "\n\n".
             "\\newcommand\\NoCaseChange[1]{{\#1}}".
             "\n";

 $introdoc8 = $intro.
             "\\usepackage[final]{pdfpages}\n".
             "\\includepdfset{pages=-, noautoscale, offset=0pt 0pt}\n".
#IPT			 "\\usepackage{hyperxmp}\n".
             "\\usepackage[pdfencoding=unicode, hidelinks]{hyperref}\n".
			 "\\usepackage{bookmark}\n".
             "\n".
             "\\usepackage{fancyhdr}\n".
             "\\pagestyle{fancy}\n".
			 "\\fancyhead[RE,LO]{}\n".
			 "\\fancyhead[RO,LE]{}\n".
			 "\\renewcommand{\\headrulewidth}{0pt}\n".
             "\n";

$introbase .="\\usepackage[latin1]{inputenc}\n".
             "\\usepackage[final]{pdfpages}\n".
             "\\includepdfset{pages=-, noautoscale, offset=0pt 0pt}\n".
             "\n".
#IPT			 "\\usepackage{hyperxmp}\n".
			 "\\usepackage[pdfencoding=unicode, hidelinks]{hyperref}\n".
			 "\\usepackage{bookmark}\n".
             "\n".
             "\\usepackage{fancyhdr}\n".
             "\\pagestyle{fancy}\n".
             "\n";
			 
#$Data::Dumper::Indent = 1;
#
# now read the config file
#
if (open (CONFIG, "<:encoding(UTF-8)", "conference.config")) {
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
    croak "\n no config file 'conference.config' found on line $.\n\n";
}
#
# read command line argument for config file name (default = config.txt)
#
if (!defined $protocol_directory) { $protocol_directory = ""; }
open (DBG, ">:encoding(UTF-8)", $protocol_directory.$debug_file) or die ("Cannot open '".$protocol_directory."$debug_file' -- $! (line ",__LINE__,")\n");
open (DBA, ">:encoding(UTF-8)", $protocol_directory."auth-deb.txt") or die ("Cannot open '".$protocol_directory."auth-deb.txt' -- $! (line ",__LINE__,")\n");
open (DBE, ">:encoding(UTF-8)", $protocol_directory."enc_dec.txt") or die ("Cannot open '".$protocol_directory."enc_dec.txt' -- $! (line ",__LINE__,")\n");
#
# writing debug call tree file wanted?
#
if (!defined $deb_calltree) { $deb_calltree = 0; }
#
#
# Call Tree Debug start
#
$deb_sub_cnt        =  0;       # debug call depth counter
$deb_cnt            =  0;       # debug call counter
if ($deb_calltree) {
	open (CDEB, ">:encoding(UTF-8)", $protocol_directory."calltree.txt")  or die ("Cannot open '".$protocol_directory."calltree.txt' -- $! (line ",__LINE__,")\n");
	print CDEB sprintf ("%6i: %2.2i %-s\n", $deb_cnt, $deb_sub_cnt, "main [$sc_version on $generation_date at $generation_time]");
}
#
my $fmt = " %25s = %-40s\n";
print DBG sprintf ("%s\n","-"x68);
print DBG sprintf ($fmt,"conference_SPMS", $conference_SPMS);
print DBG sprintf ($fmt,"conference_xmlfile", $conference_xmlfile);
#
# determine OS on which we are running
#
my $os_platform  = "$^O";
if ($os_platform =~ m|mswin|i) { 
	$os_platform_id = 1;
	$WL_DelRM       = "del ";
	$WL_Rem         = "REM ";
	$WL_Move        = "move /Y ";
} else {
	$os_platform_id = 0;
	$WL_DelRM       = "\\rm "; 
	$WL_Rem         = "# ";
	$WL_Move        = "mv -f ";
}
print     sprintf ($fmt,"OS platform    ", $os_platform);
print     sprintf ($fmt,"OS platform id ", $os_platform_id);
print DBG sprintf ($fmt,"OS platform    ", $os_platform);
print DBG sprintf ($fmt,"conference_logo", $conference_logo);
print DBG sprintf ($fmt,"conference_logo_size", $conference_logo_size);
print DBG sprintf ($fmt,"conference_url", $conference_url);
print DBG sprintf ($fmt,"conference_respm", $conference_respm);
print DBG sprintf ($fmt,"debug_file", $debug_file);
if (!defined $debug_restricted) { $debug_restricted = 1; }
print DBG sprintf ($fmt,"debug_restricted", $debug_restricted);
print DBG sprintf ($fmt,"deb_calltree", $deb_calltree);
print DBG sprintf ($fmt,"content_directory", $content_directory);
print DBG sprintf ($fmt,"html_directory", $html_directory);
print DBG sprintf ($fmt,"img_directory", $img_directory);
print DBG sprintf ($fmt,"paper_directory", $paper_directory);
print DBG sprintf ($fmt,"atc_directory", $atc_directory);
#
# Abstract related settings
#
if (!defined $abstract_directory) {
	$abstract_export = 0;
	$abstract_insert = 0;
	print DBG sprintf ($fmt,"abstract_directory", "undefined");
} else {
	print DBG sprintf ($fmt,"abstract_directory", $abstract_directory);
}
#
# Default for not defined Message if Abstract is missing.
#         Standard text is "no abstract available"
#
if (!defined $abstract_omission_text) {
    $abstract_omission_text = "no abstract available";
}
#
# Default for not defined inclusion of external Abstract
#         it's a semi-InDiCo specific switch because InDiCo's papers mostly/very often do not have abstracts,
#         but 'old' reprocessed conferences don't either. ("yes" means get Abstract for paper <paper_code>.abs)
#
if (!defined $abstract_insert) {
    $abstract_insert = 0;
}
if ($abstract_insert && $abstract_export) {
	croak "\n Abstract INSERT and EXPORT cannot be true at the same time\n\n";
} else {
	print DBG sprintf ($fmt,"abstract_insert", $abstract_insert);
	print DBG sprintf ($fmt,"abstract_export", $abstract_export);
}
#
print DBG sprintf ($fmt,"audio_directory", $audio_directory);
if (!defined $video_directory) {$video_directory = $slides_directory};
print DBG sprintf ($fmt,"video_directory", $video_directory);
print DBG sprintf ($fmt,"raw_paper_directory", $raw_paper_directory);
## print DBG sprintf ($fmt,"paper_not_received_link", $paper_not_received_link);
#
# automatic text assignment
#print DBG sprintf ($fmt,"paper_not_received_text", $paper_not_received_text);
#
# remove quotes
#
#$paper_not_received_text =~ s/"//g;
#
#print DBG sprintf ($fmt,"session_div_pages", $session_div_pages);
print DBG sprintf ($fmt,"slides_directory", $slides_directory);
if (!defined $export_directory) { $export_directory = $html_directory; }
print DBG sprintf ($fmt,"export_directory", $export_directory);
#
# "doi_directory" is the landing page for DOIs and contains only the DOI HTML files
#
if (!defined $doi_directory) {
	croak "\n required DOI directory not defined in 'conference.config'\n\n";
}
print DBG sprintf ($fmt,"doi_directory", $doi_directory);
#
# "doixml_directory" is for the XML files and the DOI registration batch file only
#
if (!defined $doixml_directory) {
	croak "\n required DOI HTML directory not defined in 'conference.config'\n\n";
}
print DBG sprintf ($fmt,"doixml_directory", $doixml_directory);
#
# DOI_site
#
if (!defined $DOI_site) {
	warn "\n DOI site not defined in 'conference.config' - will assume it's a subdir of conference\n\n";
	$DOI_site = $conference_url."doi/";
}
if ($DOI_site =~ m|www.|i) {
	$DOI_site =~ s|www.||i;
	warn "\n DOI site may not contain subdomains, \"www.\" therefore removed\n DOI_site => '".$DOI_site."'\n\n";
}

print DBG sprintf ($fmt,"DOI_site (comp)", $DOI_site);
#
# if no DOI prefix defined, use the TEST prefix and sleep 10 seconds to signal
#
if (!defined $DOI_prefix) { 
	$DOI_prefix = "10.5072"; 
	warn "\n DOI prefix not defined, using TEST DOI 10.5072 \n Contents and DOIs will be deleted after 1-4 month \n\n";
	sleep (10);
}
print DBG sprintf ($fmt,"DOI_prefix", $DOI_prefix);
if (!defined $DOI_useraccount) { $DOI_useraccount = ""; }
print DBG sprintf ($fmt,"DOI_useraccount", $DOI_useraccount);
#
# check whether the DOI landing page directory exists
#		if not create it
#
my $DOI_lpd = $doi_directory;
if (-e $DOI_lpd) {
	print " DOI Landing Directory exists.\n";
} else {
	make_path ($DOI_lpd, { verbose => 1 }) or die "Error creating DOI Landing Directory: $DOI_lpd";
}
#
# check whether the directory for the DOI XML metadata exists
#		if not create it
#
my $DOI_mdd = $doixml_directory;
if (-e $DOI_mdd) {
	print " XML directory for the DOI metadata exists.\n";
} else {
	make_path ($DOI_mdd, { verbose => 1 }) or die "Error creating DOI Landing Directory: $DOI_mdd";
}
#
# Pre-Press Release?
#
if (!defined $conference_pre_text) { 
	$conference_pre = 0; 
	$conference_pre_text = ""
} 
if (!defined $conference_pre || $conference_pre_text eq "") { 
	$conference_pre = 0; 
	$conference_pre_text = ""
} 
#
# set "citation_export" to 0 when "conference_pre" = 1
# Assign text for missing PDF
#
if ($conference_pre) { 
	$citation_export 			= 0;
	$paper_not_received_text 	= "Contribution not yet Edited, QAed, or Received";
} else {
	$citation_export 			= 1;
	$paper_not_received_text	= "CONTRIBUTION NOT RECEIVED";
}
print DBG sprintf ($fmt,"citation_export", $citation_export);
print DBG sprintf ($fmt,"conference_pre", $conference_pre);
print DBG sprintf ($fmt,"conference_pre_text", $conference_pre_text);
#
# if data generation date is not given, use actual date
#
if (!defined $data_generation_date) { 
	$data_generation_date = $generation_date;
}
print DBG sprintf ($fmt,"data_generation_date", $data_generation_date);
print DBG sprintf ($fmt,"     generation_date", $generation_date);
print DBG sprintf ($fmt,"     generation_time", $generation_time);
#
# should the full lot of files be downloaded or update only?
#        if not defined it is set to "0" = download all files 
#
if (!defined $pdf_update_only) { 
	$pdf_update_only = 0;
}
print DBG sprintf ($fmt,"pdf_update_only", $pdf_update_only);

print DBG sprintf ($fmt,"paper_ftn_switch", $paper_ftn_switch);
print DBG sprintf ($fmt,"paper_agy_switch", $paper_agy_switch);
print DBG sprintf ($fmt,"proceedings_volume_switch", $proceedings_volume_switch);
print DBG sprintf ($fmt,"context_switch", $context_switch);
if (!defined $abslatex_switch) { $abslatex_switch = 1; }
print DBG sprintf ($fmt,"abslatex_switch", $abslatex_switch);
if (!defined $paper_strike_thru) { $paper_strike_thru = 1; }
print DBG sprintf ($fmt,"paper_strike_thru", $paper_strike_thru);
if (!defined $paper_not_received_link) { $paper_not_received_link = 0; }  # changed as default 20130629
print DBG sprintf ($fmt,"paper_not_received_link", $paper_not_received_link);
if (!defined $xml_directory) { $xml_directory = ""; }
print DBG sprintf ($fmt,"xml_directory", $xml_directory);
if (!defined $conference_name) { $conference_name = ""; }
print DBG sprintf ($fmt,"conference_name", $conference_name);
#
# in case of Pre-Press Release the Pre-Press text will be added to the site
#
if (!defined $conference_pre) { 
	$conference_pre = 0; 
	$conference_pre_text = "";
}
#
# is this conference a peer-reviewed one?
# is a referee watermark string defined?
#
if (!defined $ref_watermark) { 
	$ref_watermark_prt = ""; 
} else {
	$ref_watermark_prt = "$ref_watermark"; 
}
print DBG sprintf ($fmt,"ref_watermark_prt", $ref_watermark_prt);
#
#
if (!defined $conference_site) { $conference_site = ""; }
$conference_site_lat = revert_from_context (convert_spec_chars2TeX ($conference_site, "Read"));
$conference_site_UTF = decode_entities ($conference_site);
print DBG sprintf ($fmt,"conference_site", $conference_site);
if (!defined $conference_title) { $conference_title = ""; }
print DBG sprintf ($fmt,"conference_title", $conference_title);
if (!defined $conference_title_shrt) { $conference_title_shrt = $conference_title; }
$conference_title_shrt = title_short ($conference_title_shrt);
print DBG sprintf ($fmt,"conference_titleshrt", $conference_title_shrt);
if (!defined $conference_date) { $conference_date = "2100-01-01/2100-01-05"; }
print DBG sprintf ($fmt,"conference_date", $conference_date);
conference_month_name();
$conference_longname = $conference_title." ".$conference_site." ".$conference_date; 
print DBG sprintf ($fmt,"conference_longname", $conference_longname);
if (!defined $conference_editor) { $conference_editor = ""; }
print DBG sprintf ($fmt,"conference_editor", $conference_editor);
if (!defined $conference_isbn) { $conference_isbn = ""; }
print DBG sprintf ($fmt,"conference_isbn", $conference_isbn);
if (!defined $series_issn) { $series_issn = ""; }
print DBG sprintf ($fmt,"series_issn", $series_issn);
if (!defined $conference_isbn_pos) { $conference_isbn_pos = 0; }
print DBG sprintf ($fmt,"conference_isbn_pos", $conference_isbn_pos);
if (!defined $conference_series) { $conference_series = ""; }
print DBG sprintf ($fmt,"conference_series", $conference_series);
if (!defined $conference_number) { $conference_number = ""; }
print DBG sprintf ($fmt,"conference_number", $conference_number);
if (!defined $conference_pub_copyr) { $conference_pub_copyr = "Copyright \copyright{} $actual_year by JACoW --- cc Creative Commons Attribution 3.0 (CC BY 3.0)"; }
print DBG sprintf ($fmt,"conference_pub_copyr", $conference_pub_copyr);
print DBG sprintf ($fmt,"conference_pub_date", $conference_pub_date);
	#
#	# publication month and year
	# data generation month and year
	#
#	($pubyear_nr, $pubmonth_nr, $pubday_nr) = split (/-/, $conference_pub_date);
	($pubyear_nr, $pubmonth_nr, $pubday_nr) = split (/-/, $data_generation_date);
	$pubmonth_alf	= $month[$pubmonth_nr-1];
	$pub_month_abbr	= lc $monthab[$pubmonth_nr-1];
	$pub_month_abbr	=~ s|\.||;

if (!defined $TeXhighlite) { $TeXhighlite = "black"; }
print DBG sprintf ($fmt,"TeXhighlite", $TeXhighlite);
if (!defined $PassPhraseDown) { $PassPhraseDown = ""; }
print DBG sprintf ($fmt,"Pass Phrase Down    ", $PassPhraseDown);
if (!defined $PassPhraseUp) { $PassPhraseUp = ""; }
print DBG sprintf ($fmt,"Pass Phrase Up      ", $PassPhraseUp);
if (!defined $PassPhraseExtract) { $PassPhraseExtract = ""; }
print DBG sprintf ($fmt,"Pass Phrase Extract ", $PassPhraseExtract);
#
# No Material Mark
#
if (!defined $no_material_mark) { $no_material_mark = 0; }
if (!defined $no_material_text) { $no_material_mark = 0; }
if ($no_material_mark) {
	if ($no_material_text eq "") { $no_material_mark = 0; }
}
print DBG sprintf ($fmt,"no_material_mark", $no_material_mark);
print DBG sprintf ($fmt,"no_material_text", $no_material_text);
#
# correct config file?
#  
check_config_version ();
#
# Default for not defined PPL variables:
#     configurable number of paper codes listed for an author
#
if (!defined $PPL_ltx) { $PPL_ltx = 3; }  # number for LaTeX Author index in Proceedings
if (!defined $PPL_ctx) { $PPL_ctx = 3; }  # number for ConTeXt Author index in Abstract booklet
if (!defined $PPL_xtx) { $PPL_xtx = 3; }  # number for XeTeX Author index in Abstract booklet
#
# Default for not defined InDiCo variable "indico_cut_of_trailing_ho"
#
if (!defined $indico_cut_of_trailing_ho) {
    $indico_cut_of_trailing_ho = 1;
} else {
    $indico_cut_of_trailing_ho =~ /yes/gi;
}
#
# Default for not defined InDiCo variable "indico_uppercase_session"
#
if (!defined $indico_uppercase_session) {
    $indico_uppercase_session = 1;
} else {
    $indico_uppercase_session =~ /yes/gi;
}
#
# Default for not defined InDiCo variable "indico_code_prefix"
#
#∞#if (!defined $indico_code_prefix) {
#∞#    $indico_code_prefix = "QQ-";
#∞#}
#
# Default for not defined "session_skip" parameter
#         standard is to not skip any sessions :-)
#
if (!defined $session_skip) {
    $session_skip = "";
    $sess_skip_list_anz = 0;
} else {
    (my $seski = $session_skip) =~ s/^\"\|(.*?)\|\"$/$1/s;
    @sess_skip_list = split (/\|/, $seski);
	$sess_skip_list_anz = $#sess_skip_list + 1;
#~    for ($i=0; $i<$sess_skip_list_anz; $i++) {
#~        print sprintf (" -> Skip session #%2i# >%s<\n", $i, $sess_skip_list[$i]);
#~    }
}
#
# new !!!!!!!!!!!!!!!!!!
#
#
# Default for not defined "paper_skip" parameter
#         standard is to not skip any papers :-)
#
if (!defined $paper_skip) {
    $paper_skip = "";
    $paper_skip_list_anz = 0;
} else {
    (my $papki = $paper_skip) =~ s/^\"\|(.*?)\|\"$/$1/s;
    @paper_skip_list = split (/\|/, $papki);
    $paper_skip_list_anz = $#paper_skip_list + 1;
#~    for ($i=0; $i<$paper_skip_list_anz; $i++) {
#~        print sprintf (" -> Skip paper #%2i# >%s<\n", $i, $paper_skip_list[$i]);
#~    }
}
#
print DBG sprintf ($fmt,"xml_directory", $xml_directory);
print DBG sprintf ("%s\n","-"x68);
print (" conference_pub_by $conference_pub_by");
#
# setting up the favicon and animated JACoW gif
#
   $favicon     = $img_directory."favicon.ico";
   $favicon_ani = $img_directory."favicon_ani.gif";
   $ccby_logo	= $img_directory."ccby-88x31.png";
   $jacow_hdr	= $img_directory."jacowheader.jpg";
#
# test for external defined xml file
#
 if ($external_xml) {
     $spms_xml_file = $external_xml;
     print "\n option points to '$spms_xml_file'\n";
 } else {
     $spms_xml_file = "$xml_directory$conference_xmlfile";
     print "\n config file points to '$spms_xml_file'\n";
 }
 ($logo_width, $logo_height) = split (/x/, $conference_logo_size);
 print " logo: $logo_width x $logo_height\n";
 $banner_height = $logo_height*1.2;
#
# open xml file and initialize values before reading it
#
      # try with UTF-8  ###open (PLIN, "<:utf8", "$conference_xmlfile") or die ("Cannot open '$conference_xmlfile' -- $! (line ",__LINE__,")\n");
open (PLIN, "<", "$spms_xml_file") or die ("Cannot open '$spms_xml_file' -- $! (line ",__LINE__,")\n");
$paper_open         =  0;
$conf_close         =  0;
$abstract_open      =  0;
$agency_open        =  0;
$footnote_open      =  0;
$slide_open         =  0;
$session_open       =  0;
$session_start      =  0;
$session_nr         = -1;
$paper_nr           = -1;
$src_doc            =  0;
$src_tex            =  0;
$src_odt            =  0;
$src_type_ctr       = "";
$inst_author_nr     = -1;
$session_locrd      =  0;
$session_newday     = "";
$keyw_letters       = "";
$prg_idx            = -1;       # reset index for program_code

get_session_locread ();
$filename_last_used = "";      	# reset filename so that duplicate download is minimized

open (SRCTYPE, ">".$protocol_directory."srctype.txt")  or die ("Cannot open '".$protocol_directory."srctype.txt' -- $! (line ",__LINE__,")\n");
$src_docname  = "";
open (DROP, ">" , $protocol_directory."dropped-lines.txt") or die ("Cannot open '".$protocol_directory."dropped-lines.txt' -- $! (line ",__LINE__,")\n");
open (DROPCS, ">", $protocol_directory."dropped-coorcon.txt") or die ("Cannot open '".$protocol_directory."dropped-coorcon.txt' -- $! (line ",__LINE__,")\n");
#
# open file later page count checks
#     prepare for page correction in SPMS
#     => write now Server name, Pass_up, Abstract_ids
#
(my $pppfile = "$raw_paper_directory/pages_per_paper.txt") =~ s|\.\.|\.|;
open (PPPOUT, ">", "$pppfile") or die ("Cannot open '$pppfile' -- $! (line ",__LINE__,")\n");
print PPPOUT sprintf ("#Serv=%s;Up=%s;\n", $conference_SPMS, $PassPhraseUp);
#
# before opening 
#     - new output files for direct file load with wget
#     - save/rename the old ones for later checks (*wget.bat => $protocol_directory./*wget-<aaaa-mm-dd-hhmmss.bat) 
#
#  >>> has to be fixed <<< Batch_RenameMove ();
#
# open new
#
open (WGETPDF,  ">", "pdfwget.bat") or die ("Cannot open 'pdfwget.bat' -- $! (line ",__LINE__,")\n");
open (PAPEROUT,  ">", "paperwget.bat") or die ("Cannot open 'paperwget.bat' -- $! (line ",__LINE__,")\n");
open (POSTEROUT, ">", "posterwget.bat") or die ("Cannot open 'posterwget.bat' -- $! (line ",__LINE__,")\n");
(my $wdir = $poster_directory) =~ s/\.\./\./;
open (POSTERCLN, ">", $wdir."posterclean.bat") or die ("Cannot open 'posterclean.bat' -- $! (line ",__LINE__,")\n");
open (TALKSOUT,  ">", "talkswget.bat") or die ("Cannot open 'talkswget.bat' -- $! (line ",__LINE__,")\n");
(   $wdir = $slides_directory) =~ s/\.\./\./;
open (TALKSCLN,  ">", $wdir."talksclean.bat") or die ("Cannot open 'talksclean.bat' -- $! (line ",__LINE__,")\n");
open (VIDEOOUT,  ">", "videowget.bat") or die ("Cannot open 'videowget.bat' -- $! (line ",__LINE__,")\n");
#
# add Shebang if Lunix
#
 if ($os_platform_id == 0) {
	# WGETPDF
	print WGETPDF   "#!/bin/bash\n";
	# PAPEROUT
	print PAPEROUT  "#!/bin/bash\n";
	# POSTEROUT
	print POSTEROUT "#!/bin/bash\n";
	# POSTERCLN
	print POSTERCLN "#!/bin/bash\n";
	# TALKSOUT
	print TALKSOUT  "#!/bin/bash\n";
	# TALKSCLN
	print TALKSCLN  "#!/bin/bash\n";
	# VIDEOOUT
	print VIDEOOUT  "#!/bin/bash\n";
 }

open (POSTOUT, ">", $protocol_directory."files-uploaded.txt") or die ("Cannot open '".$protocol_directory."files-uploaded.txt' -- $! (line ",__LINE__,")\n");
open (TXTEXP, ">:encoding(UTF-8)", $protocol_directory."txtexp.txt") or die ("Cannot open '".$protocol_directory."txtexp.txt' -- $! (line ",__LINE__,")\n");
my $inspire_file = $html_directory."inspire-".$conference_name.".xml";
open (INSPIRE, ">:encoding(UTF-8)", $inspire_file) or die ("Cannot open '".$inspire_file."' -- $! (line ",__LINE__,")\n");
InspireHeader ();
#
# open Code&Location for write if non found
#
if (!$session_locrd) {
    open (CODLOC, ">", $content_directory."codelocation.txt") or die ("Cannot open '".$content_directory."codelocation.txt' -- $! (line ",__LINE__,")\n");
}
#
# prepare snapshot directory "./source/" for all files
#
open (WGETOUT, ">", "allwget.bat") or die ("Cannot open 'allwget.bat' -- $! (line ",__LINE__,")\n");
	if ($os_platform_id == 0) { # add Shebang for Lunix
		# WGETOUT
		print WGETOUT   "#!/bin/bash\n";
	}
	$snapshot = -1;
      if (!-d "source") {
          #
          # directory ./source/ does not exists, create it first before cding into it
          #
          print WGETOUT "mkdir source\n";
      }
      #
      # cd into sub directory ./source/
      #
      print WGETOUT "cd source\n";
#
# read file with name corrections
#
read_names_UTF8 ();
###################
###################
##
##   main loop
##
###################
###################
my $skip_coord_flag=0;
while (<PLIN>) {
    chomp ($_);
    if (/^(\s*|#.*)$/) { next; }  # empty
#++++++++++++++++++++++++++++
    #
    # skipping selected record wrapped in <IGNORE>...</IGNORE>
    #
	if (m|<IGNORE>|) {
	   $Ignore_this_part = 1;
	}
    if ($Ignore_this_part) {
        if (m|</IGNORE>|) {
            #
            # end of IGNORE section found, reset flag
            #
            $Ignore_this_part = 0;
        }
        print DROP   sprintf ("<IGN> text ignored in line %5i: ª%s´\n", $., $_);
        next;
    }
#++++++++++++++++++++++++++++
    #
    # skipping selected session
    #
    if ($skip_this_session) {
        if (m|</session>|) {
            #
            # session end found, reset flag
            #
            $skip_this_session = 0;
        }
        print DROP   sprintf ("skip> text of session \"%s\" dropped in line %5i: ª%s´\n", $sess_skipping, $., $_);
        next;
    }
    #
    # skipping selected paper
    #
    if ($skip_this_paper) {
        if (m|</paper>|) {
            print " ∞∞∞∞∞∞∞∞∞∞∞> paper '$prg_code[$paper_nr][$prg_idx]' is skipped!\n";
            #
            # end of paper found, reset flag and decrement Paper count.+
            #
            $skip_this_paper = 0;
			$paper_open = 0;
			$paper_nr--;
        }
        print DROP   sprintf ("skip> text of paper \"%s\" dropped in line %5i: ª%s´\n", $prg_code[$paper_nr][$prg_idx], $., $_);
        next;
    }

    #
    # tag <coordinators>...</coordinators>
    #  problems gone with version spms >5.4 (comment out lines between #+++++)
    #
    if (m|coordinator|) {
        if (m|<coordinators>|) {
           $skip_coord_flag = 1;
           print DROP sprintf ("?1?> text dropped in line %5i: ª%s´\n", $., $_);
           print DROPCS sprintf ("%s\n", $_);
           next;
        }
        if (m|</coordinators>|) {
            $skip_coord_flag = 0;
            print DROP   sprintf ("?2?> text dropped in line %5i: ª%s´\n", $., $_);
            print DROPCS sprintf ("%s\n", $_);
            next;
        }
    }
    #
    # tag <contributor type="Owner">...</contributor>
    #  Owners of papers have their complete <institutes> profile embedded, not only the one(s) selected
	#                                      (so they are ignored as they appear as Co-Author too)
    #
    # if (m|contributor|) {
		# print sprintf ("?0?> text dropped in line %5i: ª%s´\n", $., $_);
		# print DROP sprintf ("?0?> text dropped in line %5i: ª%s´\n", $., $_);
        # if (m|<contributor type="Owner">|) {
           # $skip_coord_flag = 1;
           # print DROP sprintf ("?4?> text dropped in line %5i: ª%s´\n", $., $_);
           # print DROPCS sprintf ("%s\n", $_);
           # next;
        # }
        # if (m|</contributor>|) {
			# $skip_coord_flag = 0;
			# print DROP   sprintf ("?5?> text dropped in line %5i: ª%s´\n", $., $_);
			# print DROPCS sprintf ("%s\n", $_);
			# next;
        # }
    # }
    if ($skip_coord_flag) {
        print DROP   sprintf ("?-?> text dropped in line %5i: ª%s´\n", $., $_);
        print DROPCS sprintf ("%s\n", $_);
        next;
    }
#++++++++++++++++++++++++++++
    read_and_interpret_tags ();
    if ($conf_close) { last; }
} #-- end of main loop
#
# maximum number of papers
#
$paper_nr_max = $paper_nr;
#
#---- calculate the number of publishable files
#     (check for primary code to ensure false duplicates)
#
$paper_publishable  =  0;
for ($i = 0; $i <= $paper_nr_max; $i++) {
	if ($paper_pub[$i] == 1 && $prg_code[$i][$prg_code_p[$i]] eq $paper_code[$i]) {
		$paper_publishable++;
	}
}
print "\n\n Number of publishable papers: $paper_publishable\n\n\n";
# 
#----
if (!$session_locrd) { close (CODLOC); }
close (DROPCS);
close (DROP);
close (PLIN);
close (SRCTYPE);
close (WGETOUT);
close (WGETPDF);
close (POSTOUT);
close (PAPEROUT);
close (POSTEROUT);
close (POSTERCLN);
close (TALKSOUT);
close (TALKSCLN);
close (VIDEOOUT);
 #
 # make the script file Executable on Lunix
 #
 if ($os_platform_id == 0) {
	# WGETOUT
	system ("chmod a=r+w+x allwget.bat");
	# WGETPDF
	system ("chmod a=r+w+x pdfwget.bat");
	# PAPEROUT
	system ("chmod a=r+w+x paperwget.bat");
	# POSTEROUT
	system ("chmod a=r+w+x posterwget.bat");
    (my $wdir = $poster_directory) =~ s/\.\./\./;
	# POSTERCLN
	system ("chmod a=r+w+x $wdir"."posterclean.bat");
	# TALKSOUT
	system ("chmod a=r+w+x talkswget.bat");
	# TALKSCLN
	($wdir = $slides_directory) =~ s/\.\./\./;
	system ("chmod a=r+w+x $wdir"."talksclean.bat");
	# VIDEOOUT
	system ("chmod a=r+w+x videowget.bat");
 }


if (0) {
	#
	# test output for primary and secondary codes and assignment
	#
	print DBG " ----total: $paper_nr ---------\n";
	print     " ----total: $paper_nr ---------\n";
	for ($pap=0; $pap<=$paper_nr; $pap++) {
		my $p_cnt = $#{$prg_code[$pap]};
		print DBG " -----$prg_code_p[$pap] --\n";
		print     " ---- $prg_code_p[$pap] --\n";
		for ($i = 0; $i <= $p_cnt; $i++) {
			if ($i == $prg_code_p[$pap]) {
				# is primary
				print DBG " P:$i--$prg_code[$pap][$i]\n";
				print     " P:$i--$prg_code[$pap][$i]\n";
			} else {
				# is secondary
				print DBG " S:$i--$prg_code[$pap][$i]\n";
				print     " S:$i--$prg_code[$pap][$i]\n";
			}
		}
	}
}
#---------
#
# check for existence of PDF files in $paper_directory
#       if no PDF: no link and no page number will be generated
#       if PDF is there, check for publishable status
#       determine the size of the PDF and store it in $paper_pdf_size[$pap]
#
for ($pap=0; $pap<=$paper_nr; $pap++) {
   ($no_pdfs     = $paper_directory.lc($paper_code[$pap]).".pdf") =~ s|\.\./||;
   if (-e $no_pdfs) {
		$paper_with_pdf[$pap] = 1;
		$filesize = stat($no_pdfs)->size;
		$paper_pdf_size[$pap]	= sprintf ("\xa0Size of PDF file: %.3f MB\xa0", $filesize/1000000);
		$paper_fss[$pap]		= sprintf ("[%.3f MB]", $filesize/1000000);
		$DOI_land{$pap}{fsspg}	= sprintf ("[%.3f MB / %i pages]", $filesize/1000000, $paper_pages[$pap]);
	} else {
		$paper_with_pdf[$pap] = 0;
		$paper_pdf_size[$pap] = "\xa0".$paper_not_received_text."\xa0";
   }
   ($no_raw_pdfs = $raw_paper_directory.lc($paper_code[$pap]).".pdf") =~ s|\.\./||;
   if (-e $no_raw_pdfs) {
		$paper_with_raw_pdf[$pap] = 1;
   } else {
		$paper_with_raw_pdf[$pap] = 0;
   }
   #
   # check for publishable flag
   #
   if ($paper_with_pdf[$pap]) {
		$paper_with_pdf[$pap] = $paper_pub[$pap];
   }
   if ($paper_with_raw_pdf[$pap]) {
		$paper_with_raw_pdf[$pap] = $paper_pub[$pap];
   }
}
	print sprintf ("#### %6.2f [s] ### end checking PDF file presence\n", gettimeofday-$start_tm);
#
# read keyword-count list file <$raw_paper_directory/keyword-count.txt>
#      add only papers with are publishable (when flag is set)
#
    (my $keyword_file = "$raw_paper_directory/keyword-count.txt") =~ s|\.\.|\.|;
    $keyword_file =~ s|//|/|;
    open (KEYW, "<", $keyword_file) or die ("Cannot open '$keyword_file' -- $! (line ",__LINE__,")\n");
    my $j=-1;
	print DBG " KeyI PapI PaperCod Pub  Keywords\n",
	          " ---- ---- -------- ---  --------\n";
	print     "\n KeyI PapI PaperCod Pub  Keywords\n",
	          " ---- ---- -------- ---  --------\n";
	#  KeyI PapI PaperCod Pub  Keywords  
	#  ...1:1409 FRXAA01. =>1 [plasma;ion;experiment;resonance;focusing;]
	my $kw_str = "";
    while (<KEYW>) {
        chomp;
        $j++;
#        print     sprintf ("> %4i [%s]\n", $j+1, $_);
        # FRXBCH01=proton;target;factory;electron;storage-ring;
        (my $paper_id, my $key_comp) = split (/=/);
#        print DBG sprintf (" %4i %-8s\n", $j+1, $paper_id);
#        print     sprintf (" %4i %-8s\n", $j+1, $paper_id);
        for ($i=0; $i<=$paper_nr; $i++) {
            if ($paper_code[$i] eq uc $paper_id) {
				my $kwcount = @{$keywords[$i]} = split (/;/, $key_comp);
                if ($paper_with_raw_pdf[$i]) {
					$kw_str = "  ";
					if ($kwcount < 5) {
						$kw_str = sprintf ("=%1i", $kwcount);
						print DBG " problem: keywords \n";
						print     sprintf (" %4i:%4i %-9s =>%1i %2s [%s]\n", $j+1, $i, $paper_code[$i], $paper_with_raw_pdf[$i], $kw_str, $key_comp);
						
					}
                    print DBG sprintf (" %4i:%4i %-9s =>%1i %2s [%s]\n", $j+1, $i, $paper_code[$i], $paper_with_raw_pdf[$i], $kw_str, $key_comp);
                    last;
                } else {
					$kw_str = "  ";
					if ($kwcount < 5) {
						$kw_str = sprintf ("=%1i", $kwcount);
						print DBG " problem: keywords and publication status\n";
					}
                    print DBG sprintf (" %4i:%4i %-9s ~>%1i %2s [%s]\n", $j+1, $i, $paper_code[$i], $paper_with_raw_pdf[$i], $kw_str, $key_comp);
                    print     sprintf (" %4i:%4i %-9s ~>%1i %2s [%s]\n", $j+1, $i, $paper_code[$i], $paper_with_raw_pdf[$i], $kw_str, $key_comp);
                }
            }
        }
    }
	print     "\n\n",
	close(KEYW);
#
# now we have
#
#   $conference_name                              name of the conference
#   $session_startp[]          [0..$session_nr]   starting paper number of session
#   $session_endp[]            [0..$session_nr]   ending paper number of session
#   $session_abbr[]            [0..$session_nr]   abbreviation of session's name
#   $session_btime[]           [0..$session_nr]   begin time of session
#   $session_etime[]           [0..$session_nr]   end time of session
#   $session_date[]            [0..$session_nr]   scheduled date for session
#   $paper_code[]              [0..$paper_nr]     papercode (i.e. MOxx, TUxx, WExx, ITxx, CTxx, PSxx, PMxx, PTxx, ...)
#   $paper_mcls[]              [0..$paper_nr]     main classification for paper
#   $paper_scls[]              [0..$paper_nr]     sub classification for paper
#   $paper_abs[]               [0..$paper_nr]     text of paper's abstract
#   $paper_abs_utf[]           [0..$paper_nr]     text of paper's abstract in pure UTF-8 encoding
#   $paper_abs_ltx[]           [0..$paper_nr]     text of paper's abstract in LaTeX encoding
#   $paper_pages[]             [0..$paper_nr]     number of pages in the paper
#   $page_start[]              [0..$paper_nr]     number of "Page -1-" of pdf document with "$paper_nr" (only for
#                                                 proceedings rework)
#   $paper_dotc[]              [0..$paper_nr]     dot color ("GREEN", "YELLOW", "RED", "Assigned to an Editor", ...)
#   $title[]                   [0..$paper_nr]     title of paper with "$paper_nr"
#   $keywords[]                [0..$paper_nr]     keyword list for paper with "$paper_nr"
#   $main_author[]             [0..$paper_nr]     main author's name for "$paper_nr" (notation "<I.> <Lastname>")
#   $auth_list_pdf[]           [0..$paper_nr]     names and institutes for paper with "$paper_nr"
#   $authors[]                 [0..$paper_nr]     number of authors for "$paper_nr"
#
#   $chair_ini                 [0..$session_nr][] chair's initials (numbered by $session_nr) for "$chair_nr"
#   $chair_lst                 [0..$session_nr][] chair's last name (numbered by $session_nr) for "$chair_nr"
#   $chair_fst                 [0..$session_nr][] chair's first name (numbered by $session_nr) for "$chair_nr"
#   $chair_mna                 [0..$session_nr][] chair's middle name (numbered by $session_nr) for "$chair_nr"
#   $chair_ema                 [0..$session_nr][] chair's email address (numbered by $session_nr) for "$chair_nr"
#?  $chair_inst_name           [0..$session_nr][] chair's institute (numbered by $session_nr) for "$chair_nr"
#?  $chair_inst_abb            [0..$session_nr][] chair's institute abbr (numbered by $session_nr) for "$chair_nr"
#   $chair_aid;                [0..$session_nr][] chair's initials (numbered by $session_nr) for "$chair_nr"
#
#   $contrib_ini[$pap][]       [0..$contrib_nr]   authors' initials (numbered by $contrib_nr) for "$paper_nr"
#   $contrib_in8[$pap][]       [0..$contrib_nr]   authors' initials in UTF-8 notation (numbered by $contrib_nr) for "$paper_nr"
#   $contrib_lst[$pap][]       [0..$contrib_nr]   authors' last name (numbered by $contrib_nr) for "$paper_nr"
#   $contrib_ln8[$pap][]       [0..$contrib_nr]   authors' last name in UTF-8 notation (numbered by $contrib_nr) for "$paper_nr"
#   $contrib_fst[$pap][]       [0..$contrib_nr]   authors' first name (numbered by $contrib_nr) for "$paper_nr"
#   $contrib_mna[$pap][]       [0..$contrib_nr]   authors' middle name (numbered by $contrib_nr) for "$paper_nr"
#!  $contrib_ema[$pap][]       [0..$contrib_nr] ! authors' email address (numbered by $contrib_nr) for "$paper_nr"
#   $contrib_aid[$pap][]       [0..$contrib_nr]   authors' unique JACoW identifier (numbered by $contrib_nr) for "$paper_nr"
#   $contrib_ins[$pap][]       [0..$contrib_nr]   authors' institute (numbered by $ins) ($contrib_nr) for "$paper_nr"
#   $contrib_abb[$pap][]       [0..$contrib_nr]   authors' (numbered by $contrib_nr) institute abbr (numbered by $ins) ($contrib_nr) for "$paper_nr"
#¸   $contrib_cab[$pap][]       [0..$contrib_nr]   authors' (numbered by $contrib_nr) country of institute abbr (numbered by $ins) ($contrib_nr) for "$paper_nr"
#   $contrib_typ[$pap][]       [0..$contrib_nr]   authors' type of person_mode (Primary Author/Co-Author)
#
#  #¸ superflous at the moment as 'country code' is added to affiliation ("$contrib_ins" etc)
#  #! $contrib_ema should be indexed by #emails
#  #? should be indexed by #institute_nr
#  #~ should be indexed by #institute_nr
#
#   $presenter_ini[]           [0..$paper_nr]     presenter's initials for "$paper_nr"
#   $presenter_lst[]           [0..$paper_nr]     presenter's last name for "$paper_nr"
#   $presenter_fst[]           [0..$paper_nr]     presenter's first name for "$paper_nr"
# *-  $presenter_mna[]           [0..$paper_nr]     presenter's middle name for "$paper_nr"
#   $presenter_aid[]           [0..$paper_nr]     presenter's unique JACoW identifier (numbered by $contrib_nr) for "$paper_nr"
#   $presenter_ema[]           [0..$paper_nr]     presenter's email address for "$paper_nr"
#~  $presenter_ins[]           [0..$paper_nr]     presenter's institute for "$paper_nr"
#~  $presenter_abb[]           [0..$paper_nr]     presenter's institute abbr for "$paper_nr"
#
#-----------------------------------------------------
	#
	# open file for Title Capitalization (Iitle Case)
	#
	#<#> open (TITCAP, ">:encoding(UTF-8)", $protocol_directory."titcap.txt") or die ("Cannot open '".$protocol_directory."titcap.txt' -- $! (line ",__LINE__,")\n");

    my @keywordlist = ();
    my $k;
	#<#> my $titcap;
	%keywjoin = ();
    for ($i=0; $i<=$paper_nr; $i++) {
        print DBG "--For Papers----$i of $paper_nr---------------\n";
        print DBG "  Code:     $paper_code[$i]\n";
        print DBG "  Start:    $page_start[$i]\n";
        print DBG "  Title:    $title[$i]\n";
		#<#> $titcap = capitalize_title ($title[$i],
#                  NOT_CAPITALIZED => \@exceptions,
#                  PRESERVE_ALLCAPS => 1,
        #<#>            PRESERVE_ANYCAPS => 1);
        #<#> print TITCAP  "--For Papers----$i of $paper_nr---------------\n",
        #<#>               "  Code:     $paper_code[$i]\n",
		#<#> 	          "  Title:    $title[$i]\n";
		#<#> if ($titcap ne $title[$i]) {
		#<#> 	print DBG "  TitleCap: $titcap\n";
		#<#> }
#
#?        print DBG sprintf ("  Keywords:%2i  %s\n", scalar @{$keywords[$i]}, join(", ",@{$keywords[$i]}));
        for ($k=0; $k<=$#{$keywords[$i]}; $k++) {
            print DBG sprintf ("  Key       %s\n", $keywords[$i][$k]);
            push (@keywordlist, $keywords[$i][$k]);
        }
		$keywjoin{$paper_code[$i]} = join (", ", @{$keywords[$i]});
        foreach my $elem (@keywordlist) {
            $set{$elem} = 0;
        }
    }
	#<#> close (TITCAP);
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# store all Author/Institute combination in the form
#   <main_author>, co-author, co-author [institute_1] co-author, co-author, ... [institute_2], ....
# if one of the Authors has a UTF-8 name, it is attached to the Latin(ized) name
#   <main_author>, co-author (co-author UTF-8), co-author [institute_1] co-author (co-author UTF-8), co-author, ... [institute_2], ....
#
# This list is mostly used for the Author-Institute string in the "Author" field of PDF metadata (pdfauthor=)
#
	for ($pap=0; $pap<=$paper_nr; $pap++) {
        my $auth_list_complete = "";
        my @contrib_seq;
        undef @contrib_seq;
        my $i1;
        my $act_ins_abb;     # author's institute abbreviation
        my $act_idx;
        $j = 0;
        my $numele = $authors[$pap];
        while ($j <= $numele) {
            for ($auth=0; $auth<=$numele; $auth++) {
                if (!defined $contrib_seq[$auth]) {
                    $act_ins_abb = $contrib_abb[$pap][$auth];   # author's institute abbreviation
                    $act_idx   = $auth;
                    #
                    # combine all into one list
                    #
                    if ($contrib_ln8[$pap][$auth] eq $contrib_lst[$pap][$auth] &&
                        $contrib_in8[$pap][$auth] eq $contrib_ini[$pap][$auth]) {
                        $auth_list_complete .= "$contrib_ini[$pap][$auth] $contrib_lst[$pap][$auth]";
                    } else {
                        $auth_list_complete .= "$contrib_ini[$pap][$auth] $contrib_lst[$pap][$auth] ($contrib_in8[$pap][$auth] $contrib_ln8[$pap][$auth])";
                    }
                    $auth_list_complete .= ", ";
                    $contrib_seq[$auth]++;
                    $i1 = $auth + 1;
                    last;
                }
            }
            for ($auth=$i1; $auth<=$numele; $auth++) {
               if (!defined $contrib_seq[$auth] &&
			       $act_ins_abb eq $contrib_abb[$pap][$auth]) {    # author's institute abbreviation
                    $contrib_seq[$auth]++;
                    if ($contrib_ln8[$pap][$auth] eq $contrib_lst[$pap][$auth] &&
                        $contrib_in8[$pap][$auth] eq $contrib_ini[$pap][$auth]) {
                        $auth_list_complete .= "$contrib_ini[$pap][$auth] $contrib_lst[$pap][$auth]";
                    } else {
                        $auth_list_complete .= "$contrib_ini[$pap][$auth] $contrib_lst[$pap][$auth] ($contrib_in8[$pap][$auth] $contrib_ln8[$pap][$auth])";
                    }
                    $auth_list_complete .= ", ";
                }
            }
            #
            # special InDiCo case: Abbreviation == Institute's name
            #
            my $contrib_absins = "$contrib_abb[$pap][$act_idx], ";
            if ($contrib_abb[$pap][$act_idx] eq $contrib_ins[$pap][$act_idx] or
                $contrib_ins[$pap][$act_idx] eq "") {
                # nada mas
            } else {
                $contrib_absins .= $contrib_ins[$pap][$act_idx];
            }
            convert_spec_chars ($contrib_absins, "contrin_abbins-KH");
            $auth_list_complete = substr ($auth_list_complete, 0, -2)." [$contrib_absins] ";
            $j = $numele + 1;
            for ($i=0; $i<=$numele; $i++) {
                if (!defined $contrib_seq[$i]) {
                    $j = $i;
                    last;
                }
            }
        }
        $auth_list_pdf[$pap]     = $auth_list_complete;
        $auth_list_pdf_tex[$pap] = revert_from_context (convert_spec_chars2TeX ($auth_list_complete, "auth_list_pdf_tex"));

        print DBG "#>all<$pap># $paper_code[$pap] # $auth_list_pdf[$pap]\n";
	}
##############################################################
# do not generate KEYWord HTML files when in Pre-Release mode 
##############################################################
if (!$conference_pre) {
 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 #
 # Keyword index file
 #
 my $khtmlfile   = $html_directory."keyw1.htm";
 open (KHTM, ">:encoding(UTF-8)", $khtmlfile) or die ("Cannot open '$khtmlfile' -- $! (line ",__LINE__,")\n");
 print KHTM  $html_content_type."\n",
             "<html lang=\"en\">\n",
             "<head>\n",
             "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#			 "  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\">\n",
             "  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
             "  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
             "  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
             "  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
             "  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
             "  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
             "  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
             "  <title>$conference_name - List of Keywords</title>\n",
             "</head>\n\n",
             "<body class=\"debug\">\n",
             "<p class=\"list-title\">Keyword Index</span></p>\n";
 #
 # determine characters for keyword index link
 #
 my $l=-1;
 my $alph_lstchar = "";
 my $elem;
 $act_keyword     = "";
 foreach $elem (sort { uc($a) cmp uc($b) } keys %set) {
     if ($act_keyword ne $elem) {
         $l++;
         $keywords_sorted[$l] = $elem;
         $act_keyword = $elem;
     }
     my $act_letter = uc(substr($elem,0,1));
     if ($alph_lstchar ne $act_letter) {
         $alph_lstchar = $act_letter;
         $keyw_letters .= $act_letter;
         if ($act_letter eq "-") {
            $elem = "no keyword given";
         }
#         print KHTM "<br /><span class=\"list-item\"><a id=\"$alph_lstchar\">$alph_lstchar</a></span><br />\n";
         print KHTM "<br /><a class=\"list-item\" id=\"$alph_lstchar\">$alph_lstchar</a><br />\n";
     }
     $khtmlfile   = sprintf ("keyw%04i.htm", $l);
     print KHTM "<a class=\"keyw-item\" href=\"$khtmlfile\" target=\"right\">$elem</a><br />\n";
 }
 $num_of_keywords = $l;
 print KHTM "</body>\n\n",
            "</html>\n";
 close (KHTM);
 for ($l=0; $l<=$num_of_keywords; $l++) {
    $khtmlfile   = sprintf ("%skeyw%04i.htm", $html_directory, $l);
    open (KHTM, ">:encoding(UTF-8)", $khtmlfile) or die ("Cannot open '$khtmlfile' -- $! (line ",__LINE__,")\n");
    print DBG sprintf (" opening %3i. Key:%-15s\n", $l, $khtmlfile);
    $act_keyword = $keywords_sorted[$l];
    generate_keyword_head ();
    print DBG sprintf (" %3i. Key: %s\n", $l, $act_keyword);
    for ($pap=0; $pap<=$paper_nr; $pap++) {
        for ($k=0; $k<=$#{$keywords[$pap]}; $k++) {
            if ($act_keyword eq $keywords[$pap][$k]) {
                print DBG sprintf (" Key:%-15s Paper:(%4s) '%-40s'\n", $act_keyword, $pap, $title[$pap]);
                generate_keyword_entry ();
            }
        }
    }
    generate_keyword_end ();
    close (KHTM);
 }
 print sprintf ("\n#### %6.2f [s] ### end of keyword generation        (%4d keyword files)\n", gettimeofday-$start_tm, $num_of_keywords+1);
}
 print DBG "----------------------------->--\n";
 for ($i=0; $i<=$session_nr; $i++) {
     print DBG "--For Sessions----<$i of $session_nr>---------------\n";
     print DBG "Name   $session_name[$i]\n";
     print DBG "Start  $session_startp[$i]\n";
     print DBG "End    $session_endp[$i]\n";
     print DBG "Date   $session_date[$i]\n";
     print DBG "BeginT $session_btime[$i]\n";
     print DBG "EndT   $session_etime[$i]\n";
     print DBG "Prefix $session_abbr[$i]\n";
     print DBG "Loc    $session_location[$i]\n";
 }
 generate_session_html_files ();
 print INSPIRE "</collection>\n";
 close (INSPIRE);
 generate_tex_and_bat_files ();
 print sprintf ("#### %6.2f [s] ### end of session generation        (%4d session files)\n", gettimeofday-$start_tm, $num_of_sessions);
 sort_authors_and_generate_html_files ();
 print sprintf ("#### %6.2f [s] ### end of author generation         (%4d author files)\n", gettimeofday-$start_tm, $num_authindex);
 sort_institutes ();
 print sprintf ("#### %6.2f [s] ### end of institute generation      (%4d institute files)\n", gettimeofday-$start_tm, $num_of_institutes+1);
 generate_class_info ();
 print sprintf ("#### %6.2f [s] ### end of classification generation (%4d class files)\n", gettimeofday-$start_tm, $num_of_classifications+1);
 close (PPPOUT);
 close (TXTEXP);
 #~~ generate_default_html ();
 #
 # generate DOI landing pages
 #
 DOI_landing_html ();
 print sprintf ("#### %6.2f [s] ### end of DOI landing pg generation (%4d DOI files)\n", gettimeofday-$start_tm, $num_of_doipl);
 ##############################################################
 # do not generate INSTDOI HTML files when in Pre-Release mode 
 ##############################################################
 if (!$conference_pre) {
	 sort_instDOI ();
	 print sprintf ("#### %6.2f [s] ### end of institute DOI generation  (%4d DOI inst files)\n", gettimeofday-$start_tm, $num_of_institutes+1);
 }
 #
 # stop time
 #
 $stop_tm = gettimeofday;
 print sprintf ("\n\n elapsed time: %.2f [s]\n", $stop_tm-$start_tm);

 if ($deb_calltree) {
	 print CDEB sprintf ("%6i: %2.2i %-s\n", $deb_cnt, $deb_sub_cnt, "main_end");
	 close (CDEB);
 }
 close (DBA);
 close (DBG);
 
 
# print "#1### DOI_xml ###\n";
# print Dumper \%DOI_xml;
# print "#2### contrib_ini, contrib_in8 ###\n";
# print Dumper (\@contrib_ini, \@contrib_in8);
# print "#3### contrib_lst, contrib_ln8 ###\n";
# print Dumper (\@contrib_lst, \@contrib_ln8);
# print "#4### contrib_fst, contrib_mna ###\n";
# print Dumper (\@contrib_fst, \@contrib_mna);
# print "#5### contrib_aid ###\n";
# print Dumper \@contrib_aid;
# print "#6### contrib_abb ###\n";
# print Dumper \@contrib_abb;
 
exit;
##
#
#
#
#
################################
#-------------------------------
sub generate_tex_and_bat_files {
	Deb_call_strucIn ("generate_tex_and_bat_files");
	generate_tm_uti ();
	#
	# Open command file to generate final PDFs from raw PDFs
	#
	open (BAT, ">", $paper_directory."gen_texpdf.bat") or die ("Cannot open '$paper_directory"."gen_texpdf.bat' -- $! (line ",__LINE__,")\n");
	#
	# Open command file to concatenate all final (wrapped) PDFs into one file (it's huge!)
	#
#+*	open (CCP, ">", $paper_directory."gen_xconcatpdf.bat") or die ("Cannot open '$paper_directory"."gen_xconcatpdf.bat' -- $! (line ",__LINE__,")\n");
	#
	# @echo off only for Windows ($os_platform_id = 1) / Lunix gets Shebang
	#
	if ($os_platform_id) {
		print BAT "\@echo off\n";
#+*		print CCP "\@echo off\n";
	} else {
		print BAT "#!/bin/bash\n";
#+*		print CCP "#!/bin/bash\n";
	}
	print BAT "$WL_Rem Command file to generate final PDFs from raw PDFs\n",
		   "$WL_Rem (raw i.e. without Title, Author, Keyword fields)\n",
		   "$WL_Rem ------------------------------ \n",
		   "$WL_Rem Generated by JPSP version $sc_version on $generation_date at $generation_time vrwSchaa\n",
		   "$WL_Rem mailto:$conference_respm\n",
		   "$WL_Rem ------------------------------ \n",
		   "start_tm.pl\n";
#+*	print CCP "$WL_Rem Command file to concatenate all final PDFs into one huge PDF\n",
#+*		   "$WL_Rem (raw i.e. without Title, Author, Keyword fields)\n",
#+*		   "$WL_Rem ------------------------------ \n",
#+*		   "$WL_Rem Generated by JPSP version $sc_version on $generation_date at $generation_time vrwSchaa\n",
#+*		   "$WL_Rem mailto:$conference_respm\n",
#+*		   "$WL_Rem ------------------------------ \n",
#+*		   "start_tm.pl\n";
#+*	print CCP "echo ---------------------------------------\n",
#+*			 "echo linearizing  \"$outcat\"\n",
#+*			 "echo ---------------------------------------\n",
#+*			 " \n";
	#
	# Open Author-Title-Check batch file
	#
	open (BATATC, ">", $atc_directory."gen_texpdf.bat") or die ("Cannot open '$atc_directory"."gen_texpdf.bat' -- $! (line ",__LINE__,")\n");
	#
	# @echo off only for Windows ($os_platform_id = 1) / Lunix gets Shebang
	#
	if ($os_platform_id) {
		print BATATC "\@echo off\n";
	} else {
		print BATATC "#!/bin/bash\n";
	}

	print BATATC "$WL_Rem Command file to generate PDFs for Author-Title-Checks\n",
			  "$WL_Rem ------------------------------ \n",
			  "$WL_Rem Generated by JPSP version $sc_version on $generation_date at $generation_time vrwSchaa\n",
			  "$WL_Rem mailto:$conference_respm\n",
			  "$WL_Rem ------------------------------ \n";
#
# proctex_file: for proceedings volume with all papers
#               prepare_*  opens file and writes preamble
#               write_*    write a single entry into this file
#               finish_*   writes postamble and closes file
#
# tex_file    : single TeX-files with pdfTeX instructions to generate new pdf file with keywords/authors/etc.
#               write_*    writes a complete self contained TeX file
#
	if ($proceedings_volume_switch) {
		prepare_proctex_file ();
	}
	for ($sess_idx=0; $sess_idx<=$session_nr; $sess_idx++) {
		print DBG sprintf " TeX for <%2i of %2i>----------\n", $sess_idx, $session_nr;
		print DBG "Name   $session_name[$sess_idx] Paper: $session_startp[$sess_idx]--$session_endp[$sess_idx] ($session_abbr[$sess_idx])\n";
#070109    if ($proceedings_volume_switch) {
#070109        inclsession_in_proctex ();
#070109    }
		for ($pg_idx=$session_startp[$sess_idx]; $pg_idx<=$session_endp[$sess_idx]; $pg_idx++) {
			if ($page_start[$pg_idx] == -1) { next; }
			write_tex_and_bat_file ();
			if ($proceedings_volume_switch) {
			   write_proctex_file ();
		   }
		}
	 }
	if ($proceedings_volume_switch) {
		finish_proctex_file ();
		finish_procbat_file ();
	}
	print BAT "stop_tm.pl\n";
#+*	print CCP "stop_tm.pl\n";
	close (BAT);
#+*	close (CCP);
	close (BATATC);
	#
	# make the script file Executable on Lunix
	#
	if ($os_platform_id == 0) {
		# BAT
		system ("chmod a=r+w+x $paper_directory"."gen_texpdf.bat");
#+*		system ("chmod a=r+w+x $paper_directory"."gen_xconcatpdf.bat");
		# BATATC
		system ("chmod a=r+w+x $atc_directory"."gen_texpdf.bat");
	}
	Deb_call_strucOut ();
	return;
}
#-----------------------------
sub generate_session_html_files {
   Deb_call_strucIn ("generate_session_html_files");
 #
 # header of session listing
 #
	my $sess1file = $html_directory."sessi0n1.htm";
	open (SBF1, ">:encoding(UTF-8)", $sess1file) or die ("Cannot open '$sess1file' -- $! (line ",__LINE__,")\n");
	print SBF1 $html_content_type."\n",
               "<html lang=\"en\">\n",
               "<head>\n",
               "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#			   "  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
               "  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
               "  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
               "  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
               "  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
               "  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
			   "  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
               "  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
               "  <title>$conference_name - Table of Sessions</title>\n",
               "</head>\n\n",
               "<body class=\"debug\">\n",
#~#               "<table class=\"session-table\" title=\"List with all Sessions\">\n",
               "<table class=\"session-table\">\n",
               "   <tr class=\"session-entry\">\n",
               "       <td colspan=\"2\" class=\"list-title\">   Table of Sessions   </td>\n",
               "   </tr>\n";
 #
 # open ConTeXt output file for PaperId, Titel, Author, Abstract infos
 #
	if ($context_switch) {
		my $ctxt_abstract_file = $content_directory."ctxt-info.tex";
		open (CTAF, ">:encoding(UTF-8)", $ctxt_abstract_file) or die ("Cannot open '$ctxt_abstract_file' -- $! (line ",__LINE__,")\n");
		my $ctxt_shortprg_file = $content_directory."ctxt-shortprg.tex";
		open (CTSP, ">", $ctxt_shortprg_file) or die ("Cannot open '$ctxt_shortprg_file' -- $! (line ",__LINE__,")\n");
	}
 #
 # open Abstract LaTeX output file for PaperId, Titel, Author, Abstract infos
 #
	if ($abslatex_switch) {
		my $ltx_abstract_file = $content_directory."abstr-info.tex";
#		open (LXAF, ">:encoding(iso-8859-1)", $ltx_abstract_file) or die ("Cannot open '$ltx_abstract_file' -- $! (line ",__LINE__,")\n");
		open (LXAF, ">:encoding(UTF-8)", $ltx_abstract_file) or die ("Cannot open '$ltx_abstract_file' -- $! (line ",__LINE__,")\n");
		print LXAF "% !TeX encoding = UTF-8\n";
		my $ltx_shortprg_file = $content_directory."abstr-shortprg.tex";
#		open (LXAF, ">:encoding(iso-8859-1)", $ltx_abstract_file) or die ("Cannot open '$ltx_abstract_file' -- $! (line ",__LINE__,")\n");
		open (LXSP, ">:encoding(UTF-8)", $ltx_shortprg_file) or die ("Cannot open '$ltx_shortprg_file' -- $! (line ",__LINE__,")\n");
		print LXSP "% !TeX encoding = UTF-8\n";
	}
 #
 # check for existence of PDF files in $paper_directory
 #       if no PDF: no link and no page number will be generated
 #       if PDF is there, check for publishable status
 #
	for ($pap=0; $pap<=$paper_nr; $pap++) {
		($no_pdfs = $paper_directory.lc($paper_code[$pap]).".pdf") =~ s|\.\./||;
		if (-e $no_pdfs) {
			$paper_with_pdf[$pap] = 1;
		} else {
			$paper_with_pdf[$pap] = 0;
		}
		#
		# check for publishable flag
		#
		if ($paper_with_pdf[$pap]) {
			$paper_with_pdf[$pap] = $paper_pub[$pap];
		}
	}
 #
 #
 #
	my $sess;
	#
	# Session Contents (papers) into HTML
	#
	for ($sess = 0; $sess <= $session_nr; $sess++) {   # end ~3446
		($sess_name   = $session_name[$sess]) =~ m/.*?\s(.)/;
		($abbr_prefix = $session_abbr[$sess]) =~ m/.*?\s(.)/;
		#
		# header for each session
		#
#deb		print " --> working on session \"$abbr_prefix\"\n";
		(my $htmlfile = $html_directory.lc($abbr_prefix).".htm") =~ s/ /_/g;  # 06.06.10 correction for spaces in session names
		open (SHTM, ">:encoding(UTF-8)", $htmlfile) or die ("Cannot open '$htmlfile' -- $! (line ",__LINE__,")\n");
		print DBG  " prefix: $abbr_prefix -- $sess_name\n";
		(my $lc_abbr_prefix = lc($abbr_prefix).".htm") =~ s/ /_/g;  # 06.06.10 correction for spaces in session names
		$sess_name = convert_spec_chars ($session_name[$sess], "sess");
		print SBF1  "<tr class=\"session-row\">\n",
					"   <td class=\"session-entry\"><a class=\"session-link\" href=\"$lc_abbr_prefix\" target=\"right\">$abbr_prefix</a></td>\n",
					"   <td class=\"session-name\">$sess_name</td>\n",
					"</tr>\n";
		#
		# session string will be build when $session_date[] contains info
		#
		my $session_info = " ";
		if ($session_date[$sess] ne " ") {
			$session_info = "($session_date[$sess] &nbsp; $session_btime[$sess]&mdash;$session_etime[$sess])";
		}
		print SHTM  $html_content_type."\n",
					"<html lang=\"en\">\n",
					"<head>\n",
					"  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#					"  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
					"  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
					"  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
					"  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
					"  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
					"  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
					"  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
					"  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
					"  <script src=\"xbt.js\"></script>\n",
					"  <script src=\"Hyphenator.js\"></script>\n",
					"  <script src=\"en.js\"></script>\n",
					"  <script type=\"text/javascript\">Hyphenator.config({remoteloading : false}); Hyphenator.run();</script>\n",
					"  <title>$conference_name - Table of Session: $abbr_prefix ($sess_name)</title>\n",
					"</head>\n\n",
					"<body class=\"debug\">\n",
					"<span class=\"sessionheader\">$abbr_prefix&nbsp;&mdash;&nbsp; $sess_name &nbsp; $session_info<br />\n";
		if ($context_switch) {
			 convert_spec_chars2TeX ("$abbr_prefix --- $session_name[$sess]", "sess");
			 print CTAF " \\StartSession\n  \\StartSessionData\n   \\StartSessionTitle\n        $_\n   \\StopSessionTitle\n";
			 if ($session_info ne " ") {
				print CTAF "   \\StartSessionDate\n        $session_date[$sess]\\quad $session_btime[$sess] - $session_etime[$sess]\n   \\StopSessionDate\n";
			 }
			 print CTSP "  \\NC $session_date[$sess]\\quad $session_btime[$sess] -- $session_etime[$sess] \\NC \\NC \\SR\n",
						"  \\NC $session_btime[$sess] -- $session_etime[$sess]   \\NC $_  \\NC \\SR\n";
		}
		#
		# Generate Session header with Date and location info
		#   \SessionHeader [6]
		#        {session-color}
		#        {date}
		#        {start-time}
		#        {end-time}
		#        {presentation-type}
		#        {location-string}
		#   \SessionBody [5]
		#        {session-color}                   [! here !]
		#        {session-abbr-string}             [! here !]
		#        {session-name-string}             [! here !]
		#        {session-classification-string}   [empty]
		#        {session-chair-string}            [later]
		#
		if ($abslatex_switch) {
			if ($session_info ne " ") {
				if ($session_newday eq "" || $session_newday ne $session_date[$sess]) {
					my ($Sday, $Smon, $Syear) = split (/-/, $session_date[$sess]);
					$Wday = get_wday ($session_date[$sess]);
					# $Wsday is the abbreviated day (first three chars)
					$Wsday = substr($Wday, 0, 3);
					# $Smon is the abbreviated month, $Smonth the full name of the month (delivered by get_wday)
					print LXAF "   \\NewDay{$Sday}{$Smonth}{$Syear}{$Wsday}{$Smon}\n\n";
					print LXSP "   \\NewDayCont{$Sday}{$Smonth}{$Syear}\n\n";
					$session_newday = $session_date[$sess];
				}
				my $sess_loc = convert_spec_chars2TeX ($session_location[$sess], "sess-loc");
				$sess_loc	 = revert_from_context ($sess_loc);
				print LXAF "   \\SessionHeader{$sess_color[$sess]}{$session_date[$sess]}{$session_btime[$sess]}{$session_etime[$sess]}{$session_type[$sess]}{$sess_loc}\n";
				print LXSP "   \\SessionHeaderCont{$sess_color[$sess]}{$session_date[$sess]}{$session_btime[$sess]}{$session_etime[$sess]}{$session_type[$sess]}{$sess_loc}\n";
			 }
			convert_spec_chars2TeX ("$session_name[$sess]", "sess-body");
			revert_from_context ($_);
			print LXAF "   \\SessionBody{$sess_color[$sess]}{$abbr_prefix}{$_}{$session_type[$sess]}";
			print LXSP "   \\SessionBodyCont{$sess_color[$sess]}{$abbr_prefix}{$_}{$session_type[$sess]}";
		}
		print TXTEXP "ST: $abbr_prefix - $sess_name\n";
		print TXTEXP "SD: $session_date[$sess], $session_btime[$sess] - $session_etime[$sess]\n";
		#
		# Session Chair info
		#
		if ($chairs[$sess] > -1) {
			my $mpt_inst;
			my $chair_str;
			my $tchair_st;
			#
			# "$mpt_inst" for InDiCo specialty: empty Institute name
			#
			$chair_str = "";
			$tchair_st = "";
			for ($chair_i=0; $chair_i<=$chairs[$sess]; $chair_i++) {
				 $mpt_inst = ($chair_inst_name[$sess][$chair_i] eq "") || ($chair_inst_abb[$sess][$chair_i] eq $chair_inst_name[$sess][$chair_i]);
				 $chair_str .= "$chair_ini[$sess][$chair_i]&nbsp;$chair_lst[$sess][$chair_i]";
				 #
				 # institute abbreviation empty too?
				 #
				 if ($chair_inst_abb[$sess][$chair_i] ne "") {
					$chair_str .= ",&nbsp;$chair_inst_abb[$sess][$chair_i]";
				 }
				 $tchair_st .= "$chair_ini[$sess][$chair_i] $chair_lst[$sess][$chair_i], $chair_inst_abb[$sess][$chair_i]";
				 print DBG "#>c>> $sess:$chair_i <<-->> $chair_str \n";
				 if (!$mpt_inst) {
	#                 print DBG "#>+> not empty: $chair_inst_name[$sess][$chair_i] \n";
					 $chair_str .= ",&nbsp;$chair_inst_name[$sess][$chair_i]";
					 $tchair_st .=  ", $chair_inst_name[$sess][$chair_i]";
				 }
				 if ($chair_i < $chairs[$sess]) {
					$chair_str .= " / ";
					$tchair_st .=  " / ";
				 }
			}
			#
			# Session Chair info into HTML
			#
			convert_spec_chars ($chair_str, "chair");
			if ($chairs[$sess] == 0) {
			   print SHTM  "Chair: <span class=\"sessionchair\">$_</span></span>\n\n";
			} else {
			   print SHTM  "Chairs: <span class=\"sessionchair\">$_</span></span>\n\n";
			}
			print TXTEXP "SC: $tchair_st\n";
			#
			# Session Chair info into TeX
			#
			if ($context_switch) {
				$mpt_inst = ($chair_inst_name[$sess][0] eq "") || ($chair_inst_abb[$sess][0] eq $chair_inst_name[$sess][0]);
				$chair_str = "$chair_ini[$sess][0] $chair_lst[$sess][0], $chair_inst_abb[$sess][0]";
				if (!$mpt_inst) {
					$chair_str .= " ($chair_inst_name[$sess][0])";
				}
				convert_spec_chars2TeX ($chair_str, "chair-ctx");
				print CTAF "   \\StartSessionChair\n        {\\bf Chair: }$_\n",
						   "   \\StopSessionChair\n  \\StopSessionData\n  \\StartEntries\n";
				print CTSP "  \\NC                      \\NC Session Chair: $_ \\NC \\SR\n";
			}
			#   \SessionBody
			#        {session-color}                   [^^^^]
			#        {session-name-string}             [^^^^]
			#        {session-classification-string}   [empty]
			#        {session-chair-string}            [! here !]
			#
			#  \begin{PaperList}                     [! here !]
			#
			if ($abslatex_switch) {
				#
				# Affiliation string for Chair: "C.~Hair (Inst.Abbr)" => "C.~Hair (Inst.Name)" => "C.~Hair"
				#
				if ($chair_inst_abb[$sess][0] ne "") {
					#
					# Acronym is present
					#
					$chair_str = "$chair_ini[$sess][0]~$chair_lst[$sess][0] ($chair_inst_abb[$sess][0])";
				} else {
					#
					# no Acronym
					#
					if ($chair_inst_name[$sess][0] ne "") {
						#
						# Institute's name is present
						#
						$chair_str = "$chair_ini[$sess][0]~$chair_lst[$sess][0] ($chair_inst_name[$sess][0])";
					} else {
						#
						# no info, leave it out
						#
						$chair_str = "$chair_ini[$sess][0]~$chair_lst[$sess][0]";
					}
				}
				convert_spec_chars2TeX ($chair_str, "chair-lxaf");
				revert_from_context ($_);
				print LXAF "{$_}\n\n",
						   "   %%\\renewcommand\\MainClass{\\MainClassDefineEmpty}\n\n\n",
						   "   \\begin{PaperList}\n";
				print LXSP "{$_}\n\n",
						   "   \\begin{PaperListCont}\n";
			}
		} else {
			#
			# no session Chair
			#
			print SHTM  "</span>\n\n";

			if ($context_switch) {
				print CTAF "   \\StartSessionChair\n        \\mbox{ }\n",
						   "   \\StopSessionChair\n  \\StopSessionData\n  \\StartEntries\n";
				print CTSP "  \\NC                      \\NC                                                   \\NC \\SR\n";
			}
			#
			#  \begin{PaperList}                 [! here !]
			#
			if ($abslatex_switch) {
				print LXAF "   {}\n\n",
						   "   %%\\renewcommand\\MainClass{\\MainClassDefineEmpty}\n\n\n",
						   "   \\begin{PaperList}\n";
				print LXSP "   {}\n\n",
						   "   \\begin{PaperListCont}\n";
			}
		}
		#
		# patch for <session>s without papers
		#
		if ($session_startp[$sess] > $session_endp[$sess]) {
			print SHTM "<p>\n",
					   "<strong>No papers in this session</strong>\n",
					   "</p>\n";
			if ($abslatex_switch) {
				print LXAF "     \\item \\mbox{ }\n";
				print LXSP "     \\item \\mbox{ }\n";
			}
		} else {
			print SHTM "<table class=\"tabledef\">\n",
		#                   "<tbody>\n",
					   "    <tr class=\"tablerow\">\n",
					   "        <th class=\"papercodehead\">Paper</th>\n",
					   "        <th class=\"papertitlehead\">Title</th>\n",
					   "        <th class=\"papernumberhead\">Page</th>\n",
					   "    </tr>\n";
		}
	#
	# Session Contents (papers) into HTML
	#   we are inside session loop
	#
		#
		# $pap from first paper_nr in session($sess) till last [$pap = paper_nr]
		#
		$paper_mcls_last = "";
		for ($pap = $session_startp[$sess]; $pap <= $session_endp[$sess]; $pap++) {
#deb			print "      --> working on paper \"$paper_code[$pap]\"\n";
			#
			# check for PDF existence (and change code if not) and for publishable flag
			#
			my $lc_paper_pdf = ".".$paper_directory.lc($paper_code[$pap]).".pdf";
			my $pdf_file_exists = $paper_with_pdf[$pap] && $paper_pub[$pap];

			print SHTM "<!-- ################.-->\n";
			print SHTM "    <tr class=\"tablerow\" id=\"$paper_code[$pap]\">\n";
			my $INSP_Tit	= UTF_convert_spec_chars ($title[$pap], "pap-in-sess_title");
			$DOI_land{$pap}{title} 		= $INSP_Tit;
			$DOI_land{$pap}{titleXML}	= encode_entities ($INSP_Tit, '<>&"');

			my $INSP_Abs  = UTF_convert_spec_chars ($paper_abs[$pap], "INSP_Abs");
			$DOI_land{$pap}{abstract}	 = $INSP_Abs;
			$DOI_land{$pap}{abstractXML} = encode_entities ($INSP_Abs, '<>&"');
			if ($abstract_export) {
				write_internal_abs ($paper_code[$pap], $INSP_Abs);
			}
			#
			# PDF for this paper?
			#
			if ($pdf_file_exists) {
				print INSPIRE "  <record>\n",
							  "    <datafield tag=\"650\" ind1=\"1\" ind2=\"7\">\n",
							  "       <subfield code=\"a\">Accelerators</subfield>\n",      	# Inspire subject area, should always be "Accelerators" for JACoW
							  "       <subfield code=\"2\">INSPIRE</subfield>\n",
							  "    </datafield>\n",
							  "    <datafield tag=\"980\" ind1=\" \" ind2=\" \">\n",
							  "       <subfield code=\"a\">ConferencePaper</subfield>\n",  	 	# Inspire collection, always "Conference Paper" for JACoW
							  "    </datafield>\n",												# change 2014-08-22 Annette: Zwei 980-Felder: 980__aConferencePaper + 980__aHEP
							  "    <datafield tag=\"980\" ind1=\" \" ind2=\" \">\n",			# change 2015-02-05 Annette: Das heisst: zwei 980 Felder mit jeweils einem Unterfeld a. 
							  "       <subfield code=\"a\">HEP</subfield>\n",               	#                                             
							  "    </datafield>\n";
				#
				#
				# entries for DOI landing page: Abstract & DOI key
				#
				$DOI_land{$pap}{session}	= $session_name[$sess];
				$DOI_land{$pap}{date}		= $session_date[$sess]." &nbsp; ".$session_btime[$sess]."&ndash;".$session_etime[$sess];
				$DOI_land{$pap}{main}		= $paper_mcls[$pap];
				$DOI_land{$pap}{sub}		= $paper_scls[$pap];
				$DOI_land{$pap}{session}	= $session_name[$sess];
				$DOI_land{$pap}{doi_jcp}	= "JACoW-".$conference_name."-".$prg_code[$pap][$prg_code_p[$pap]];	#$paper_code[$pap];	# is already primary
				$DOI_land{$pap}{doi}		= $DOI_prefix."/".$DOI_land{$pap}{doi_jcp};							# complete DOI key 
				(my $paper_url = $conference_url.$lc_paper_pdf) =~ s|\.\./||;;
				$DOI_land{$pap}{papertextlnk} = sprintf ("download <a href=\"%s\" target=\"pdf\">%s</a> %s", $paper_url, uc ($paper_code[$pap].".pdf"), $DOI_land{$pap}{fsspg});
				$DOI_land{$pap}{paperlink}	= $paper_url;
				$DOI_land{$pap}{firstpage}	= $page_start[$pap];
				$DOI_land{$pap}{lastpage}	= $page_start[$pap] + $paper_pages[$pap] - 1;
				$DOI_land{$pap}{pages}		= $paper_pages[$pap];
				#
				print INSPIRE "    <datafield tag=\"245\" ind1=\" \" ind2=\" \">\n",           	# title
							  "       <subfield code=\"a\">$DOI_land{$pap}{titleXML}</subfield>\n",
							  "    </datafield>\n",
							  "    <datafield tag=\"520\" ind1=\" \" ind2=\" \">\n",           	# abstract
							  "       <subfield code=\"a\">$DOI_land{$pap}{abstractXML}</subfield>\n",
							  "       <subfield code=\"9\">JACoW</subfield>\n",
							  "    </datafield>\n",
							  "    <datafield tag=\"773\" ind1=\" \" ind2=\" \">\n",
							  "       <subfield code=\"q\">$conference_name</subfield>\n",     	# conf code, could be the full JACoW code (e.g. DIPAC2007)
							  "       <subfield code=\"c\">$paper_code[$pap]</subfield>\n",    	# first-last page or article id
							  "       <subfield code=\"y\">$pubyear_nr</subfield>\n",    		# first-last page or article id
							  "    </datafield>\n",
							  "    <datafield tag=\"856\" ind1=\"4\" ind2=\" \">\n",           	# put the best URL
							  "       <subfield code=\"a\">$paper_url</subfield>\n",			# changed 21.11.19	was:  "u"=$paper_url
							  "       <subfield code=\"y\">Fulltext</subfield>\n",				# changed 21.11.19  was:  "y"=JACoW
							  "       <subfield code=\"t\">INSPIRE-PUBLIC</subfield>\n",		# added   21.11.19  
							  "    </datafield>\n",
							  "    <datafield tag=\"300\" ind1=\" \" ind2=\" \">\n",			# nr of pages
							  "       <subfield code=\"a\">$paper_pages[$pap]</subfield>\n",
							  "    </datafield>\n",
							  "    <datafield tag=\"024\" ind1=\"7\" ind2=\" \">\n",			# DOI key 
							  "       <subfield code=\"a\">$DOI_land{$pap}{doi}</subfield>\n",	# mail with format: Kirsten 24-Feb-2016
							  "       <subfield code=\"2\">DOI</subfield>>\n",
							  "    </datafield>\n";
				#
				# give link (and size as tooltip)
				#
				print SHTM "        <td class=\"papkey\"><a class=\"papkey-hov\" href=\"$lc_paper_pdf\" onmouseover=\"XBT(this, {text: '$paper_pdf_size[$pap]', className: 'xbtooltip'})\"",
						   " target=\"pdf\">$paper_code[$pap]</a></td>\n";
			} else {
				#
				# no DOI record because paper is missing
				#
				$DOI_land{$pap}{paperlink}	= "";
				if ($conference_type_indico) {
					#
					# for InDiCo conferences the paper_code name is not shown (pure numeric)
					#
					print SHTM "        <td class=\"papkey\"></td>\n";
				} else {
					my $class_c = "papkey";
					if ($paper_strike_thru) {
						$class_c = "papkeystr";
					}
					#
					# Multiple Program Codes additions (do not stroke out and change tooltip text)
					#
					if ($paper_code[$pap] ne $prg_code[$pap][$prg_code_p[$pap]]) {
						$paper_pdf_size[$pap] = "&nbsp;Check primary paper code below for contribution&nbsp;";
						$class_c = "papkey";
					}
					print SHTM "        <td class=\"$class_c\"><div class=\"xbtooltipstr\" onmouseover=\"XBT(this, {text: '$paper_pdf_size[$pap]', className: 'xbtooltipstrc'})\">$paper_code[$pap]</div></td>\n";
				}
			}
			#---
			# SHTM output Paper Title and Page number in proceedings
			#
			print SHTM "        <td class=\"paptitle\">$DOI_land{$pap}{title}</td>\n";
			if ($paper_with_pdf[$pap]) {
				$page_start_toc = $page_start[$pap];
				if ($page_start_toc == 0) {
					$page_start_toc = 1;
				}
				if ($conference_pre) {
					# Pre-Press Release
					$page_start_toc = -1;
				}
				print SHTM "        <td class=\"pappage\">$page_start_toc</td>\n";
			} else {
				print SHTM "        <td>&nbsp;</td>\n";
			}
			#
			# SHTM for multiple program codes output additional infos (primary paper code)
			#
			if ($#{$prg_code[$pap]} > 0) {
				#
				# there is (at least) one secondary code
				#  => easy: $prg_code[$pap][$prg_code_p[$pap]] => give primary code e.g. TUPRO023
				#
				for ($i = 0; $i <= $#{$prg_code[$pap]}; $i++) {
					my $sesslink	= find_lc_session ($prg_code[$pap][$i]); 
					if ($prg_code[$pap][$i] ne $paper_code[$pap]) {
						print SHTM "    </tr>\n";
						print SHTM "    <tr class=\"tablerow\">\n";
						print SHTM "        <td class=\"papkey\"><a class=\"papkey-hov\" href=\"$sesslink.htm#$prg_code[$pap][$i]\" target=\"_self\">$prg_code[$pap][$i]</a></td>\n";
						if ($prg_code[$pap][$prg_code_p[$pap]] eq $paper_code[$pap]) {
							print SHTM "        <td class=\"comment\">$code_link_altern_text</td>\n";
						} else {
							print SHTM "        <td class=\"comment\">$code_link_prim_text</td>\n";
						}
						print SHTM "        <td>&nbsp;</td>\n";
					}
				}
			}
			#
			# NOMAT? 
			#		are there paper and/or slides, or does the author provide nothing for publication?
			#
#InAc	    NoMat (*SHTM, $pap, $sess);
			#---
			# SHTM <ul> prepare Author list
			#
			print SHTM "    </tr>\n",
					   "    <tr class=\"tablerow\">\n",
					   "        <td>&nbsp;</td>\n",
					   "        <td><ul>\n";
			$DOI_land{$pap}{authors} = "";
			#
			# Session Contents (papers) into TeX
			#
			if ($context_switch) {
				convert_spec_chars2TeX ($title[$pap], "title-CT");
				print CTAF "   \\StartEntry\n     \\StartPapercode\n        $paper_code[$pap]\n     \\StopPapercode\n",
						   "     \\StartTitle\n        $_\n     \\StopTitle\n     \\StartAuthors\n";
				print CTSP "  \\NC $paper_code[$pap]  \\NC  $_            \\NC \\SR\n";
			}
			#
			#  \begin{PaperList}
			#     \Paper       same parameters, but \PaperAbs is generated when
			#     \Paperabs    the <paper_code> signals an Oral
			#
			#     \Paper<Abs>                      [! here !]
			#         {paper_code}                 [! here !]
			#         {main classification}        [! here !]
			#         {sub classification}         [! here !]
			#         {start_time}                 [! here !] <PaperAbs> only
			#         {end_time}                   [! here !] <PaperAbs> only
			#         {duration}                   [! here !] <PaperAbs> only
			#         {title}                      [! here !]
			#         {authors + affiliation}      [later]
			#         {abstract}                   [later]
			#  \end{PaperList}
			#
			if ($abslatex_switch) {
				my $main_cls = convert_spec_chars2TeX ($paper_mcls[$pap], "mcls-LX");
				if ($paper_mcls[$pap] ne $paper_mcls_last) {
					print LXAF "     \\MainClass{$main_cls}\n";
					$paper_mcls_last = $paper_mcls[$pap];
				}
				convert_spec_chars2TeX ($title[$pap], "title-LX");
				revert_from_context ($_);
				if ($xml_program_codes) {
					if ($#{$prg_code_p[$pap]} eq 1) {
						print DBG "prg_codes1 ($pap) PapCod:$paper_code[$pap]: Prg_p:$prg_code_p[$pap]: (0:$prg_code[$pap][0] 1:$prg_code[$pap][1])\n";
					} else {
						print DBG "prg_codes0 ($pap) PapCod:$paper_code[$pap]: Prg_p:$prg_code_p[$pap]: (0:$prg_code[$pap][0])\n";
					}
					if ($paper_code[$pap] eq $prg_code[$pap][$prg_code_p[$pap]]) {
						print LXAF "     \\Primary{$paper_code[$pap]}%\n",
								   "              {=}\n";
					} else {
						print LXAF "     \\Primary{$paper_code[$pap]}%\n",
								   "              {$prg_code[$pap][$prg_code_p[$pap]]}\n";
					}
				}
				if ($session_type[$sess] =~ m/Oral/i) {
					if (!defined $talk_btime[$pap] |
						!defined $talk_etime[$pap] |
						!defined $talk_duration[$pap]) {
						print " ======> Missing 'time' values in $paper_code[$pap]\n";
					}
					print DBG  "Sess/Type: ->$sess/$session_type[$sess]<- ($paper_code[$pap]) => PaperAbs\n";
					print LXAF "     \\PaperAbs{$paper_code[$pap]}%\n",
							   "              {$main_cls}{$paper_scls[$pap]}%\n",
							   "              {$talk_btime[$pap]}{$talk_etime[$pap]}{$talk_duration[$pap]}%\n",
							   "              {$_}%\n";
					print LXSP "     \\PaperAbsCont{$paper_code[$pap]}%\n",
							   "              {$main_cls}{$paper_scls[$pap]}%\n",
							   "              {$talk_btime[$pap]}{$talk_etime[$pap]}{$talk_duration[$pap]}%\n",
							   "              {$_}%\n";
				} else {
					print DBG  "Sess/Type: ->$sess/$session_type[$sess]<- ($paper_code[$pap]) => Paper\n";
					print LXAF "     \\Paper{$paper_code[$pap]}%\n",
							   "              {$main_cls}{$paper_scls[$pap]}%\n",
							   "              {}{}{}%\n",
							   "              {$_}%\n";
					print LXSP "     \\PaperCont{$paper_code[$pap]}%\n",
							   "              {$main_cls}{$paper_scls[$pap]}%\n",
							   "              {}{}{}%\n",
							   "              {$_}%\n";
				}
			}
			print TXTEXP "PC: $paper_code[$pap]\n";
			print TXTEXP "PT: $title[$pap]\n";
			#
			# list with authors over institutes
			#
			my $authorlist  = "";
			my $tauthorlst  = "";
			my @contrib_seq;
			undef @contrib_seq;
		#
			my $author_ac;      # check for Author
			my $lxauthor_ac;    # LaTeX: Author string (utf8 name)
			my $presenter;      # check for Presenter
			my $lxpresenter;    # LaTeX: Presenter string
		#
			my $i1;
			my $act_ins_abb;    # author's institute abbreviation
			my $act_idx;
			$j = 0;
			if ($context_switch) { print CTSP "  \\NC                    \\NC  "; }
			my $ltx_bf_set = 0;

			my $numele = $authors[$pap];
			while ($j <= $numele) {
				for ($auth=0; $auth<=$numele; $auth++) {

					$act_ins_abb = $contrib_abb[$pap][$auth];   # author's institute abbreviation
					$act_idx     = $auth;                       #
					$author_ac   = "$contrib_ini[$pap][$auth] $contrib_lst[$pap][$auth]";
					$lxauthor_ac = "$contrib_in8[$pap][$auth]~$contrib_ln8[$pap][$auth]";
					$presenter   = "$presenter_ini[$pap] $presenter_lst[$pap]";
					$lxpresenter = "$presenter_ini[$pap]~$presenter_lst[$pap]";
					#print "presnter: $presenter\n";
					if (!defined $contrib_seq[$auth]) {
						print DBG "Sess1: act.author: ª$author_ac´ #paper: ª$pap´  main.author: ª$main_author[$pap]´\n";
						#
						# check for main author who gets a 'highlighted' name
						#
						if ($author_ac eq $main_author[$pap]) {
							#
							# main author for Author list, ConTeXt and LaTeX
							#
							$authorlist = "<strong>$contrib_in8[$pap][$auth]&nbsp;$contrib_ln8[$pap][$auth]</strong>";  # utf-8
							$tauthorlst .=       "{$contrib_in8[$pap][$auth] $contrib_ln8[$pap][$auth]}";                     # utf-8
							if ($context_switch) {
								convert_spec_chars2TeX ($author_ac, "main-author-CTAF");
								print CTAF " {\\bf $_}";
							}
							if ($abslatex_switch) {
								convert_spec_chars2TeX ($lxauthor_ac, "main-author-LX");
								revert_from_context ($_);
								my $loc_authname = $_;
								if ($ltx_bf_set) {
									print LXAF "              \\bold{$loc_authname}";
									# print LXSP "              {\\boldCont{$loc_authname} \\bInstCont{($_)}}% <1>\n";
								} else {
									convert_spec_chars2TeX ($contrib_abb[$pap][$auth], "contrib-abb-ins");
									revert_from_context ($_);
									my $loc_authname_inst = $_;
									#
									# only one author (main author gets his institute attached later)
									#
									print LXAF "              {\\bold{$loc_authname}";
									print LXSP "              {\\boldCont{$loc_authname} \\bInstCont{$loc_authname_inst}}% <2>\n";
									$ltx_bf_set = 1;
								}
							}
						} elsif ($author_ac eq $presenter) {
							#
							# markup (underline) for Presenter/Speaker
							#
							$authorlist = "<span class=\"tooltip presenter\">$presenter_ini[$pap]&nbsp;$presenter_lst[$pap]<span class=\"pr-text presentertxt\">presenter</span></span>";  # ??? utf-8
							$tauthorlst .= "{presenter}";                                                      # ??? utf-8
							if ($context_switch) {
								convert_spec_chars2TeX ($author_ac, "presenter-CTAF");
								print CTAF ", {\\uline $_}";
							}
							if ($abslatex_switch) {
								#
								# presenter
								#
								convert_spec_chars2TeX ($lxpresenter, "presenter-LXAF");
								revert_from_context ($_);
								if ($ltx_bf_set) {
									#
									# presenter 
									#
									print LXAF ", \\ul{$_}";
									#  print LXSP ", \\boldCont{$_}";
								} else {
									#
									# co-author with more than one affiliation
									#
									print LXAF ", {\\ul{$_}";
									$ltx_bf_set = 1;
								}
							}
						} else {
							#
							# just a co-author
							#
							$authorlist = "$contrib_in8[$pap][$auth]&nbsp;$contrib_ln8[$pap][$auth]";                   # utf-8
							$tauthorlst .= "$contrib_in8[$pap][$auth] $contrib_ln8[$pap][$auth]";                       # utf-8
							if ($context_switch) {
								convert_spec_chars2TeX ($author_ac, "co-author-CTAF");
								print CTAF " $_";
							}
							if ($abslatex_switch) {
								convert_spec_chars2TeX ($lxauthor_ac, "co-author-LXAF");
								revert_from_context ($_);
								print LXAF "$_";
								#  print LXSP "$_";
							}
						}
						if ($context_switch) {
							convert_spec_chars2TeX ($author_ac, "author-CTSP");
							print CTSP "  $_";
						}
						$contrib_seq[$auth]++;
						$i1 = $auth + 1;
						last;
					} # end <!defined $contrib_seq[$auth]>
				} # end <for $auth>
				#
				#  
				#
				for ($auth=$i1; $auth<=$numele; $auth++) {  # act_ins_abb  => author's institute abbreviation
					if (!defined $contrib_seq[$auth] && $act_ins_abb eq $contrib_abb[$pap][$auth]) {
						$contrib_seq[$auth]++;
						$author_ac   = "$contrib_ini[$pap][$auth] $contrib_lst[$pap][$auth]";
						$presenter   = "$presenter_ini[$pap] $presenter_lst[$pap]";
		#               $lxauthor_ac = "$contrib_ini[$pap][$auth]~$contrib_lst[$pap][$auth]";
						$lxauthor_ac = "$contrib_in8[$pap][$auth]~$contrib_ln8[$pap][$auth]";
						$lxpresenter = "$presenter_ini[$pap]~$presenter_lst[$pap]";
						#
						# markup for Main Author
						#
						if ($author_ac eq $main_author[$pap]) {
							$authorlist .= ", <strong>$contrib_in8[$pap][$auth]&nbsp;$contrib_ln8[$pap][$auth]</strong>"; # utf-8
							$tauthorlst .= ", {$contrib_in8[$pap][$auth] $contrib_ln8[$pap][$auth]}";                     # utf-8
							if ($context_switch) {
								convert_spec_chars2TeX ($author_ac, "author-CTAF");
								print CTAF ", {\\bf $_}";
							}
							if ($abslatex_switch) {
								#
								# author with second (...) affiliation
								#
								convert_spec_chars2TeX ($lxauthor_ac, "author-LXAF");
								revert_from_context ($_);
								if ($ltx_bf_set) {
									#
									# primary author with more than one affiliation
									#
									print LXAF ", \\bold{$_}";
									#  print LXSP ", \\boldCont{$_}";
								} else {
									#
									# co-author with more than one affiliation
									#
									print LXAF ", {\\bold{$_}";
									$ltx_bf_set = 1;
								}
							}
						} elsif ($author_ac eq $presenter) {
							#
							# markup (underline) for Presenter/Speaker
							#
							$authorlist .= ", <span class=\"tooltip presenter\">$presenter_ini[$pap]&nbsp;$presenter_lst[$pap]<span class=\"pr-text presentertxt\">presenter</span></span>";  # ??? utf-8
							$tauthorlst .= ", {presenter}";                                           # ??? utf-8
							if ($context_switch) {
								convert_spec_chars2TeX ($author_ac, "presenter-CTAF");
								print CTAF ", {\\uline $_}";
							}
							if ($abslatex_switch) {
								#
								# presenter
								#
								convert_spec_chars2TeX ($lxpresenter, "presenter-LXAF");
								revert_from_context ($_);
								if ($ltx_bf_set) {
									#
									# presenter 
									#
									print LXAF ", \\ul{$_}";
									#  print LXSP ", \\boldCont{$_}";
								} else {
									#
									# co-author with more than one affiliation
									#
									print LXAF ", {\\ul{$_}";
									$ltx_bf_set = 1;
								}
							}
						} else {
							#
							# just a co-author
							#
							$authorlist .= ", $contrib_in8[$pap][$auth]&nbsp;$contrib_ln8[$pap][$auth]";                  # utf-8
							$tauthorlst .= ", $contrib_in8[$pap][$auth] $contrib_ln8[$pap][$auth]";                       # utf-8
							if ($context_switch) {
								convert_spec_chars2TeX ($author_ac, "author-CTAF");
								print CTAF ", $_";
							}
							if ($abslatex_switch) {
								convert_spec_chars2TeX ($lxauthor_ac, "author-LXAF");
								revert_from_context ($_);
								print LXAF ", $_";
								if ($auth > 1) {
									# print LXSP " (+ $auth +), $_";
								} else {
									# print LXSP "   \\otherAuthorCont{, $_";
								}
							} # <if ($abslatex_switch)>
						} # <if else ($author_ac eq $main_author[$pap]) >
					} # <if (!defined $contrib_seq[$auth]>
				} # end <for ($auth=$i1;>
				#
				# SHTM <li> enter Author into list
				#
				convert_spec_chars ($authorlist, "authorlist-SHTM");
				my $acstr = "                <li><span class=\"author_cl\">$_</span><br />\n";
				print SHTM $acstr;
				$DOI_land{$pap}{authors} .= $acstr;
				#
				# special InDiCo case: Abbreviation == Institute's name
				#
				if ($contrib_abb[$pap][$act_idx] eq $contrib_ins[$pap][$act_idx] or
					$contrib_ins[$pap][$act_idx] eq "") {
					convert_spec_chars ($contrib_abb[$pap][$act_idx], "contrib-abb");
				} else {
					convert_spec_chars ("$contrib_abb[$pap][$act_idx], $contrib_ins[$pap][$act_idx]", "contrib-abb-ins");
				}
				#
				# for text export the authors and affiliations are in one line, so add institute
				#
				$tauthorlst .= ", $_; ";
		#            s/,\s$//g;
				#
				# SHTM </li> end Author list
				#
				print SHTM "                       $_</li>\n";
				$DOI_land{$pap}{authors} .= "                       $_</li>\n";
				if ($context_switch) {
					convert_spec_chars2TeX ($contrib_abb[$pap][$act_idx], "contrib-abb-CT");
					print CTAF " ($_)\n";
					print CTSP " ($_)";
				}
				if ($abslatex_switch) {
					convert_spec_chars2TeX ($contrib_abb[$pap][$act_idx], "contrib-abb-LX");
					revert_from_context ($_);
					#
					# decision when to attach the institute to an author's name
					#
					print DBG ">>> <$paper_code[$pap]> <j:$j> <auth:$auth> <inst: ($_)  <auth_ec=main:$author_ac=$main_author[$pap]> \n";
		#           if ($author_ac eq $main_author[$pap]) 
					if (1 == 0) {
						#
						# actual Author is the Main Author and might already have
						# his Institute attached to his name (see above "% <3>"
						#
						if ($j == 0 && $auth == 1) {
							#
							# Author is a singleton (only one from this Institute)
							#s
							print LXAF " ($_) ";   #does it happen??
						} else {
							#
							# Author has already got his Institute attached,
							# but is not a single Author on this paper
							#
							print LXAF " ";   #does it happen??
						}
					} else {   # always true
						#
						# actual Author is last of his team and here comes the Institute
						#
						print LXAF " ($_) ";
					}
					if ($authors[$pap] != 0) {
						# print LXSP " +<- ($_) ";
					}
				} # $abslatex_switch
				$j = $numele + 1;
				for ($i=0; $i<=$numele; $i++) {
					if (!defined $contrib_seq[$i]) {
						$j = $i;
						last;
					}
				}
			} # end <while ($j <= $numele) {>
			#
			# generate INSPIRE data only when Paper exists
			#
			if ($pdf_file_exists) {
				INSPIRE_write_data_record ();
				INSPIRE_Keywords ();
			}
			if ($context_switch) {
				print CTAF "     \\StopAuthors\n";
				print CTSP "     \\NC \\SR\n";
			}
			if ($abslatex_switch) {
				print LXAF "}%\n";
				if ($authors[$pap] == 0) {
					# print LXSP "}%\n";
				} else {
					# print LXSP "+} }%\n";
				}
				$ltx_bf_set = 0;
			}
			#
			# SHTM </ul> end of Author list
			#      <tr>  additional entry to keep distance to next Paper (vertical spacing)
			#
			print SHTM "        </ul></td>\n",
					   "        <td>&nbsp;</td>\n",
					   "    </tr>\n";
			print TXTEXP "PL: $tauthorlst\n";
			print DBG " 1817 --> $tauthorlst\n";
			#
			# include "abstract", "funding note", "foot note" 
			#         restrict DOI data store to one instants only (this one: Session)
			#
			$DOI_landing_str = 1;
			include_abstract_etc (*SHTM);
			$DOI_landing_str = 0;
			if ($paper_abs[$pap]) {
				print TXTEXP "PA: $paper_abs[$pap]\n";
				#
				# TeX directly
				#
				if ($context_switch) {
					if ($paper_agy_switch && $paper_agy[$pap]) {
						convert_spec_chars2TeX ($paper_agy[$pap], "paper_agy-CT");
						print CTAF "     \\StartFunding\n        $_\n     \\StopFunding\n";
					}
					convert_spec_chars2TeX ($paper_abs[$pap], "paper_abs-CT");
					print CTAF "     \\StartAbstract\n        $_\n     \\StopAbstract\n";
					#
					# is there an footnote to include?
					#
					if ($paper_ftn_switch && $paper_ftn[$pap]) {
						convert_spec_chars2TeX ($paper_ftn[$pap], "paper_foot-CT");
						print CTAF "     \\StartFootnote\n        $_\n     \\StopFootnote\n";
					}
				}
				if ($abslatex_switch) {
		#            if ($paper_agy_switch && $paper_agy[$pap]) {
		#                convert_spec_chars2TeX ($paper_agy[$pap], "paper_agy-LX");
		#                print LXAF "     \\Funding{$_}\n";
		#                print LXSP "     \\FundingCont{$_}\n";
		#            }
					convert_spec_chars2TeX ($paper_abs[$pap], "paper_abs-LX");
					revert_from_context ($_);
					print LXAF "              {$_}\n\n";
					print LXSP "              {$_}\n\n";
					#
					# is there an footnote to include?
					#
					if ($paper_ftn_switch && $paper_ftn[$pap]) {
						convert_spec_chars2TeX ($paper_ftn[$pap], "paper_ftn-LX");
						revert_from_context ($_);
						print LXAF "     \\Footnote{$_}\n\n\n";
					}
				}
			} # if paper_abs[$pap]
			if ($context_switch) { print CTAF "   \\StopEntry\n"; }
		} # paper of session
		print SHTM "</table>\n",
				   "</body>\n\n",
				   "</html>\n";
		close (SHTM);
		if ($context_switch) {
			print CTAF "  \\StopEntries\n \\StopSession\n\n\n";
			print CTSP "  \\NC   \\NC    \\NC \\SR\n\n\n";
		}
		if ($abslatex_switch) {
			print LXAF "   \\end{PaperList}\n\n\n";
			print LXSP "   \\end{PaperListCont}\n\n";
		}
	} # session
	$num_of_sessions = $sess;
	print SBF1 "</table>\n</body>\n\n</html>\n";
	close (SBF1);
	if ($context_switch) {
		close (CTAF);
		close (CTSP);
	}
	if ($abslatex_switch) {
		close (LXAF);
		close (LXSP);
	}
	Deb_call_strucOut ();
	return
}
#-----------------------------
sub include_abstract_etc {
  	Deb_call_strucIn ("include_abstract_etc");

	#
	# is there an "funding note"/"abstract"/"foot note" to include?
	#
	my $fh      = shift;
	my $fh_writ = 0;
	if ($paper_abs[$pap] ||
		$paper_agy_switch && $paper_agy[$pap] ||
		$paper_ftn_switch && $paper_ftn[$pap]) {
		print $fh	"    <tr class=\"tablerow\">\n",
					"        <td>&nbsp;</td>\n",
					"        <td>\n";
		$fh_writ = 1;
	}	
	#
	# Funding Note inclusion
	#
	if ($paper_agy_switch && $paper_agy[$pap]) {
		convert_spec_chars ($paper_agy[$pap], "paper_agy-web");
		print $fh "        <span class=\"abstract jtext\"><strong>Funding:</strong> <em>$_</em></span><br />\n";
		$fh_writ = 1;
		if ($DOI_landing_str) { $DOI_land{$pap}{funding} = "$_"; }
	} else {
		if ($DOI_landing_str) { $DOI_land{$pap}{funding} = ""; }
	}
	#
	# Abstract inclusion
	#
	if ($paper_abs[$pap]) {
		convert_spec_chars ($paper_abs[$pap], "paper_abs-web");
		print $fh sprintf ("        <span class=\"abstract hyphenate jtext\" lang=\"en\">%s</span>\n", $_);
		$fh_writ = 1;
	}
	#
	# Footnote to include?
	#
	if ($paper_ftn_switch && $paper_ftn[$pap]) {
		convert_spec_chars ($paper_ftn[$pap], "paper_ftn-web");
		print $fh "      <br /><span class=\"abstract jtext\"><em>$_</em></span>\n";
		$fh_writ = 1;
		if ($DOI_landing_str) { $DOI_land{$pap}{footnote} = "$_"; }
	} else {
		if ($DOI_landing_str) { $DOI_land{$pap}{footnote} = ""; }
	}
	#
	# have we written anything to $fh? If "yes" we have to close the <tr>
	#
	if ($fh_writ) {
		print $fh 	"        </td>\n",
					"        <td>&nbsp;</td>\n",
					"    </tr>\n";
	}
	#
	# is there a "video" to include?
	#
	if ($video[$pap]) {
		print DBG "Video: $video[$pap]\n";
		#
		# video tag in XML, but does this file really exist?
		#
		$image = $img_directory."video-icon.jpg";
		my $video_file = $video_directory.$video[$pap];
		(my $video_exi  = $video_file) =~ s|\.\./||;
		if (-e $video_exi) {
			#
			# embed video in page
			#
			#  to check for run time: "exiftool -S -n <p_id>_talk.mp4 | grep ^Duration"
			#                         with "preload=metadata" the duration is visible
			#
						#	<tr>
						#	  <td><table>
						#		 <tr>
						#			<td>column1 - video</td>
						#			<td>column2 - comment</td>
						#		 </tr>
						#	  </table></td>
						#	</tr>
			print $fh	"    <tr class=\"tablerow\">\n",
						"        <td class=\"talkicon\">\n",
			#			"		   <p style=\"color:blue;font-size:28px;\">&#127910;</p>\n",
						"          <img alt=\"video icon\" src=\"$image\" />\n",
						"        </td>\n",
						"        <td><table>\n",
						"          <tr><td>\n";
			(my $video_still = $video_file) =~ s|\_talk\.mp4|-poster\.jpg|i;
			(my $video_still_exi = $video_still) =~ s|\.\./||;
			if (-e $video_still_exi) {
				print $fh	"		     <video preload=metadata muted width=400px poster=\"$video_still\" controls>\n";
			} else {
				print $fh	"		     <video preload=metadata muted width=400px controls>\n";
			}
			my $moz = $img_directory."pic-in-pic.jpg";
			my $chr = $img_directory."pic-in-pic-chrome.jpg";
			print $fh	"			   <source src=\"$video_file\" type=\"video/mp4\" />\n",
						"				  Your browser cannot play the video.<br/>\n",
						"			      Consider download from <a href=\"$video_file\">Link Address</a>.\n",
						"		     </video>\n",
						"          </td>\n",
						"          <td>\n",
						"             &nbsp; &nbsp; &nbsp; &nbsp; \n",
						"          </td>\n",
						"          <td>\n",
						"             <b>Right click on video for<br/><i>Picture-in-Picture</i> mode<br/>or <i>Full screen</i> display.<b><br/><br/>At start the sound is muted!\n",
						"          </td>\n",
						"         </tr>\n",
						"         </table></td>\n",
						"        <td>&nbsp;</td>\n",
						"    </tr>\n";
			#
			# DOI landing page entries (if Session HTML)
			#
#>			if ($DOI_landing_str) {
#>				my $abs_video_link = $conference_url.$video_exi;
#>				$DOI_land{$pap}{videolink} = sprintf ("download <a href=\"%s\" target=\"pdf\">%s</a> %s", $abs_video_link, uc $video[$pap], $fss);
#>			}
		} else {
			print DBG "video: does not exist for $paper_code[$pap] ($video_exi)\n";
		}
	}
	#
	# is there a "video stream link"?
	#
	if ($stream[$pap]) {
		print DBG "VideoStream: $stream[$pap]\n";
		#
		# video stream tag in XML
		#
		$image = $img_directory."video-icon.jpg";
		print $fh	"    <tr class=\"tablerow\">\n",
					"        <td class=\"talkicon\">\n",
		#			"		   <p style=\"color:blue;font-size:28px;\">&#127910;</p>\n",
					"          <img alt=\"video icon\" src=\"$image\" />\n",
					"        </td>\n",
					"        <td>\n",
					"           <span>Talk as video stream: $stream[$pap]\n",
					"        </td>\n",
					"        <td>&nbsp;</td>\n",
					"    </tr>\n";
	}
#
#
	if ($DOI_landing_str) { $DOI_land{$pap}{slideslink} = ""; }
	if ($slides[$pap]) {
		#
		# Slides tag in XML, but does this file really exist?
		#
		my $slides_file = $slides_directory.$slides[$pap];
		print DBG "Slides: written to> $slides_file     ($fh)\n";
		(my $slides_exi  = $slides_file) =~ s|\.\./||;
		if (-e $slides_exi) {
			$filesize = stat($slides_exi)->size;
			print DBG "Slides: size> $slides_file     ($filesize)\n";
			$fss      = sprintf ("[%.3f MB]", $filesize/1000000);
			$image = $img_directory."slides-icon.jpg";			# &#10064;  # Upper Right Drop-Shadowed White Square
			my $num_of_videos = check_video_in_talk ($slides_exi);
#			print     "Slides: $slides_file with $num_of_videos videos\n";
			print DBG "Slides: $slides_file with $num_of_videos videos\n";
			print $fh	"    <tr class=\"tablerow\">\n",
						"        <td class=\"talkicon\">\n",
						"           <img alt=\"slides icon\" src=\"$image\" />\n",
						"        </td>\n",
						"        <td>\n";
			if ($num_of_videos) {
				my $vid_plural = "s ";
				if ($num_of_videos eq 1) { $vid_plural = " "; }
				my $vid_str = sprintf ("This PDF contains %i video%swhich might not run in browser mode &#8658; download PDF", $num_of_videos, $vid_plural);
			
#				print $fh	"           <a class=\"posterslide-wb\" href=\"$slides_file\" onmouseover=\"XBT(this, {text: ' $vid_str ', className: 'xbtooltipstrc'})\" target=\"pdf\">Slides $paper_code[$pap]</a> $fss\n";
				print $fh	"           <a class=\"posterslide-wb\" href=\"$slides_file\" onmouseover=\"XBT(this, {text: ' $vid_str ', className: 'xbtooltipstrc'})\" target=\"pdf\">Slides $prg_code[$pap][$prg_code_p[$pap]]</a> $fss\n";
			} else {  # $prg_code[$pap][$prg_code_p[$pap]]
#				print $fh	"           <a class=\"posterslide-wb\" href=\"$slides_file\" target=\"pdf\">Slides $paper_code[$pap]</a> $fss\n";
				print $fh	"           <a class=\"posterslide-wb\" href=\"$slides_file\" target=\"pdf\">Slides $prg_code[$pap][$prg_code_p[$pap]]</a> $fss\n";
			} 
			print $fh	"        </td>\n",
						"        <td>&nbsp;</td>\n",
						"    </tr>\n";
			# 
			# DOI landing page entries (if Session HTML)
			#
			if ($DOI_landing_str) {
				my $abs_slides_link = $conference_url.$slides_exi;
				$DOI_land{$pap}{slideslink} = sprintf ("download <a href=\"%s\" target=\"pdf\">%s</a> %s", $abs_slides_link, uc $slides[$pap], $fss);
			}
		} else {
			print DBG "Slides: do not exist for $paper_code[$pap] ($slides_exi)\n";
			$slides[$pap] = "";
		}
		#
		# "Audio" is there a "Sound File" in the Sounds_Directory or somewhere else?
		#
		if (!defined $audio_directory) {
			$audio_directory = $slides_directory;
		}
		$image = $img_directory."sound-icon.jpg";
		my $sound_file = $audio_directory.lc($paper_code[$pap]).".mp3";
		(my $sound_exi = $sound_file) =~ s|\.\./||;
		if (-e $sound_exi) {
			print DBG "Sound: $sound_file\n";
			print $fh	"    <tr class=\"tablerow\">\n",
						"        <td class=\"soundicon\">\n",
						"           <img alt=\"sound icon\" src=\"$image\" />\n",
						"        </td>\n",
						"        <td>\n",
						"           <a href=\"$sound_file\">Talk $paper_code[$pap]</a>\n",
						"        </td>\n",
						"        <td>&nbsp;</td>\n",
						"     </tr>\n";
		} else {
			print DBG "Sound does not exist: $sound_file\n";
		}
	} else {
		print DBG "Slides: nothing for $paper_code[$pap]\n";
	}
#
# is there a "Poster" to be included?
#
#	my $poster_file = $poster_directory.lc($paper_code[$pap])."_poster.pdf";
	my $poster_main_id =  $prg_code[$pap][$prg_code_p[$pap]];
	my $poster_file = $poster_directory.lc($poster_main_id)."_poster.pdf";
	(my $poster_exi = $poster_file) =~ s|\.\./||;
	if (-e $poster_exi) {
		$filesize = stat($poster_exi)->size;
#     	print "> $slides_file     ($filesize)\n";
		$fss      = sprintf ("[%.3f MB]", $filesize/1000000);
		$image    = $img_directory."poster-icon.jpg";
		print DBG "poster: $poster_file\n";
		print $fh 	"    <tr class=\"tablerow\">\n",
					"        <td class=\"postericon\">\n",
					"           <img alt=\"poster icon\" src=\"$image\" />\n",
					"        </td>\n",
					"        <td>\n",
#					"           <a class=\"posterslide-wb\" href=\"$poster_file\" target=\"pdf\">Poster $paper_code[$pap]</a> $fss\n",
					"           <a class=\"posterslide-wb\" href=\"$poster_file\" target=\"pdf\">Poster $poster_main_id</a> $fss\n",
					"        </td>\n",
					"        <td>&nbsp;</td>\n",
					"    </tr>\n";
		#
		# DOI landing page entries (if Session HTML)
		#
		if ($DOI_landing_str) {
			my $abs_poster_link = $conference_url.$poster_exi;
			$DOI_land{$pap}{posterlink} = sprintf ("download <a href=\"%s\" target=\"pdf\">%s</a> %s", $abs_poster_link, uc ($paper_code[$pap]."_poster.pdf"), $fss);
		}
	} else {
		print DBG "poster: does not exist: $poster_exi\n";
		if ($DOI_landing_str) { $DOI_land{$pap}{posterlink} = ""; }
	}
	if ($citation_export) {
		#
		# DOI exists
		#
		my $publshd		= $page_start[$pap] > 0;
		if ($publshd) {
			my $doi_jcw  = "JACoW-".$conference_name."-".$prg_code[$pap][$prg_code_p[$pap]];
			my $doi_urlb = $DOI_prefix."/".$doi_jcw;
			my $doi_urle = "https://doi.org/".$doi_urlb;
			my $doi_inti = ".".$doi_directory.$doi_jcw.".html";
			my $issuedt  = sprintf ("%s %s %s", $pubday_nr, $pubmonth_alf, $pubyear_nr);
			print $fh 	"    <tr class=\"tablerow\">\n",
						"    	  <td class=\"exp\">DOI &bull;</td>\n",
						"        <td>reference for this paper \n",
#						"              &#8251; <a class=\"exp\" href=\"$doi_urle\" target=\"exp\">$doi_urlb</a>\n",
						"              &#8251; <a class=\"exp\" href=\"$doi_urle\" target=\"exp\">$doi_urle</a>\n",
						"        </td>\n",
						"        <td>&nbsp;</td>\n",
						"    </tr>\n",
						"    <tr class=\"tablerow\">\n",
						"    	  <td class=\"exp\">About &bull;</td>\n",
						"        <td>paper received &#8251; <i>", PubDate ($paper_recv[$pap]), "</i> &nbsp; &nbsp; &nbsp; paper accepted &#8251; <i>", PubDate ($paper_acpt[$pap]), "</i> &nbsp;  &nbsp; &nbsp; issue date &#8251; <i>", $issuedt, "</i></td>\n",
						"        <td>&nbsp;</td>\n",
						"    </tr>\n";		
		} else {
#			print "#>>>1 $fh # $pap -- $paper_code[$pap] \n";
#			print "#>>>2 publish $publshd \n";
		}
		#
		# citation export links
		#
		my $citdir = ".$export_directory$paper_code[$pap]";
		print $fh 	"    <tr class=\"tablerow\">\n",
					"    	  <td class=\"exp\">Export &bull;</td>\n",
					"        <td>reference for this paper using \n",
				 	"              <a class=\"exp-wb\" href=\"$citdir-bib.htm\" target=\"exp\">&#8251; BibTeX</a>, \n",
					"              <a class=\"exp-wb\" href=\"$citdir-tex.htm\" target=\"exp\">&#8251; LaTeX</a>, \n",
					"              <a class=\"exp-wb\" href=\"$citdir-txt.htm\" target=\"exp\">&#8251; Text/Word</a>, \n",
					"              <a class=\"exp-wb\" href=\"$citdir-ris.htm\" target=\"exp\">&#8251; RIS</a>, \n",
					"              <a class=\"exp-wb\" href=\"$citdir.xml\" target=\"exp\">&#8251; EndNote (xml)</a>\n",
					"        </td>\n",
					"        <td>&nbsp;</td>\n",
					"    </tr>\n";
	}
	#
	#   <tr>  additional entry to keep distance to next Paper (vertical spacing until css is fixed)
	#
	print $fh 	"    <tr class=\"sprr\">\n",
				"        <td colspan=\"3\">&nbsp;</td>\n",
				"    </tr>\n";			

	Deb_call_strucOut ();
	return;
}
#-----------------------------
sub sort_authors_and_generate_html_files {
  	Deb_call_strucIn ("sort_authors_and_generate_html_files");

#   $author[$pap][]            [0..$author_nr]    author's name ($author_nr) for "$paper_nr"
#   $authors[$pap]                                number of authors for "$paper_nr"
## open (TMP, ">", "auth.tmp") or die ("Cannot open 'auth.tmp': $! (line ",__LINE__,")\n");
 my @idx_authors;
 my $idx_authors;
 my @idx_inst;
 my $authlf;
 my $authhs;
 my $alph_actchar;
 my $idx = -1;
 print DBG "----- start dumping authors ---------------\n";
 for ($pap=0; $pap<=$paper_nr; $pap++) {
#    print "####++++++ $pap--$paper_code[$pap]--$authors[$pap]\n";
     print DBG " #pap:$pap #auth:",$authors[$pap]+1," ($paper_code[$pap])\n";
     for ($auth=0; $auth<=$authors[$pap]; $auth++) {
         $idx++;
		 $authlf = $contrib_lst[$pap][$auth].", ".$contrib_ini[$pap][$auth];                             # Froehlich, G.
		 $authhs = helpsort_acc_chars ($authlf, "dumping authors");                                                         # froehlich, g.
		 #                            ∞ l+f s|L+F N|AiD | Inst|pap|aut|idx|F+L N|L+F N utf8
         $idx_authors[$idx] = sprintf ("%-40s∞%-0s∞%14s∞%-50s∞%4i∞%4i∞%5i∞%-30s∞%-30s",
                                              $authhs,                                                   # -40s  froehlich, g.
                                              $authlf,                                                   # Froehlich, G.
                                              $contrib_aid[$pap][$auth],                                 # unique JACoW Author Id
                                              $contrib_abb[$pap][$auth],                                 # GSI      ## changed sequence of: number
                                              $pap,                                                      # 1        ##                      and institute
                                              $auth,                                                     # 1
                                              $idx,                                                      # 6
                                              $contrib_ini[$pap][$auth]." ".$contrib_lst[$pap][$auth],   # G. Froehlich
                                              $contrib_ln8[$pap][$auth].", ".$contrib_in8[$pap][$auth]); # Frˆhlich, G.  (utf-8)
        print DBG sprintf (" >> [%4i] %s\n", $idx, $idx_authors[$idx]);
		#
        $idx_inst[$idx] = sprintf ("%-40s∞%4i∞",
                                              $contrib_abb[$pap][$auth],                                 # GSI      ## institute
                                              $pap);													 # 1        ## paper number
     }
 }
 print DBG "----- end dumping authors/institutes ---------------\n";
 $author_max_nr = $idx;
 @sorted_all_idx_authors 	= sort { uc($a) cmp uc($b) } @idx_authors;
 @sorted_all_idx_inst		= sort { uc($a) cmp uc($b) } @idx_inst;
#
#
#----------- sort authors/institutes done -------------------------------------------
#
#
 $debauthfile = $protocol_directory."debug_auth.txt";
 open (DEBAUTH, ">:encoding(UTF-8)", $debauthfile) or die ("Cannot open '$debauthfile' -- $! (line ",__LINE__,")\n");
 print DEBAUTH ("  nr  | lowercase lastname, initials            | normal case, lastname, initials         | JACoW-Id       | Institute abb                                      | pap       |pap_nr|#AinP |#Auth | Name Initials+Lastname         | Name in UTF8 Lastname, Initials\n");
 print DEBAUTH ("------+-----------------------------------------+-----------------------------------------+----------------+----------------------------------------------------+-----------+------+------+------+--------------------------------+--------------------------------\n");
 for ($i=0; $i<=$author_max_nr; $i++) {
     (my $ctr_namna, my $ctr_name, my $ctr_aid, my $ctr_abb, my $ctr_pap, my $ctr_auth, my $ctr_idx, my $ctr_namfl, my $ctr_fl8) = split (/∞/, $sorted_all_idx_authors[$i]);
     print DEBAUTH sprintf ("%5i | %-40s| %-40s| %14s | %-50s | %-9s | %4i | %3i | %5i | %-30s | %-30s\n",
	                         $i,
                                   substr($ctr_namna, 0, 40),
                                          substr($ctr_name, 0, 40),
											     $ctr_aid,
											            substr($ctr_abb, 0, 50),
											                    $paper_code[$ctr_pap], 
																       $ctr_pap,
											                                 $ctr_auth,
											                                       $ctr_idx,
											                                             substr($ctr_namfl, 0, 30),
											                                                     substr($ctr_fl8, 0, 30));
 }
 print DEBAUTH ("------+---------------------------------------------------+---------------------------------------------------+----------------+----------------------------------------------------+------+------+------+--------------------------------+--------------------------------\n");
 print DEBAUTH ("\n\n");
 close (DEBAUTH);
#
# record all index letters from authors' names
#
 my $alph_lstchar = "";
    $alph_letters = "";
 for ($i=0; $i<=$author_max_nr; $i++) {
     my $act_actchar = uc substr($sorted_all_idx_authors[$i], 0, 1);   # element 0 (first letter)
     straighten_name ($act_actchar);
     if ($alph_lstchar ne $act_actchar) {
         $alph_letters .= $act_actchar;
         $alph_lstchar  = $act_actchar;
     }
 }
 my $last_author = "";
 my $ahtm_open   = 0;
    $last_aid    = "";
	
 print DBG sprintf ("%s\n", "-"x30);
 print DBG sprintf (" Anzahl %i\n", $author_max_nr);
#
# open Author Index file: "html/auth1.htm"
# open Author Files:      "html/auth####.htm" (#### -> 0001..9999)
#
 authorindex_open_file ();
 generate_index_basefile ();
 generate_session_basefile ();
##############################################################
# do not generate KEYWord HTML files when in Pre-Release mode 
##############################################################
 if (!$conference_pre) {
	generate_keyword_basefile ();
 }
 generate_banner_file ();
 generate_author_basefile ();
 generate_author_TeXindex ();
 $num_authindex = 0;
 my %paper_seen = ();
 for ($ialentry=0; $ialentry<=$author_max_nr; $ialentry++) {
     (my $authna, $authname, my $aid, $inst, $pap, $ale_auth, my $e, my $fmy, $auth8) = split (/∞/, $sorted_all_idx_authors[$ialentry]);
     $authname =~ s/\s*$//o;
     $auth8    =~ s/\s*$//o;

     if ($authname ne $last_author || $aid ne $last_aid) {
         if ($ahtm_open) {
             generate_author_end ();
             $ahtm_open = 0;
			 %paper_seen = ();    # reset seen papers for new author
         }
         $num_authindex++;
         $last_author = $authname;
		 $last_aid    = $aid;
         $sorted_auth_id[$num_authindex] = $aid;
         $sorted_authors[$num_authindex] = $authname;
         $ahtmlfile   = sprintf ("%sauth%04i.htm", $html_directory, $num_authindex);
         open (AHTM, ">:encoding(UTF-8)", $ahtmlfile) or die ("Cannot open '$ahtmlfile' -- $! (line ",__LINE__,")\n");
		 print DBG " Autor: $authname- File: $ahtmlfile\n";
         $ahtm_open = 1;
         authorindex_add_entry ();
         print DBG " --> $ahtmlfile <> $authname\n";
         generate_author_head ();
         # print DBG sprintf ("\n #<%4i># %s\n #Pap:<%4s>=<%s> Inst:%50s\n", $ialentry, $sorted_all_idx_authors[$ialentry], $pap, $paper_code[$pap], $inst);
         generate_author_entry ();
		 $paper_seen{$pap} = 1;
     } else {
         print DBG sprintf (" *%4i* %s [already seen]\n", $ialentry, $authname);
         if ($paper_seen{$pap}) {
             # print DBG sprintf (" *%4i* %i [paper already seen]\n", $ialentry, $pap);
             next;
         } else {
			# print DBG sprintf ("\n #<%4i>? %s\n ?Pap:<%4s> Inst:%50s\n", $ialentry, $sorted_all_idx_authors[$ialentry], $pap, $inst);
			generate_author_entry ();
			$paper_seen{$pap} = 1;
		 }
     }
 }
 authorindex_close_file ();
 Deb_call_strucOut ();
}
#-----------------------
# Author sorting is done on a separate entry in "@idx_authors"
#        which has the last name converted using this function
#		 all in lowercase
#
#        all accented and 'foreign' characters are
#        converted to the closest latin equivalent
#
sub helpsort_acc_chars {
    $_    = lc $_[0];
 my $wohe = $_[1];
#	if ($_ !~ m|[·‡Â„‰Ê\x{010D}Á\x{0107}\x{1D9C}ÈËÎ\x{0131}ÌÌÓ\x{0142}\x{0144}ÒÛÚˆ¯\x{0151}\x{015B}ö\x{021B}˙¸˝\x{017C}ûﬂ]|) {
#		return $_;
#	}
 	Deb_call_strucIn ("helpsort_acc_chars ($_)");

	s|√º|ue|g;
	s|√∂|oe|g;
	s|√£|a|g;		#„
	s|√©|e|g;
	s|√±|n|g;
	s|\xC3\x85|a|g;
# U+00FC LATIN SMALL LETTER U WITH TWO DOTS
	s|[·‡Â„]|a|g;
	s|[‰Ê]|ae|g;
# U+010D LATIN SMALL LETTER C WITH CARON
# U+0107 LATIN SMALL LETTER C WITH ACUTE
# U+1D9C MODIFIER LETTER SMALL C
	s|[\x{010D}Á\x{0107}\x{1D9C}]|c|g;
	s|[ÈËÎ]|e|g;
# U+0131 LATIN SMALL LETTER DOTLESS I
# U+00ef LATIN SMALL LETTER I with Diaeresis
	s|[\x{0131}ÔÏÌÓ]|i|g;
# U+0142 LATIN -- LETTER L WITH STROKE
	s|\x{0141}\x{0142}|l|g;
# U+0144 LATIN SMALL LETTER N WITH ACUTE
	s|[\x{0144}Ò]|n|g;
	s|[ÛÚÙı]|o|g;
# U+0151 LATIN SMALL LETTER O WITH DOUBLE ACUTE
	s|[ˆ¯\x{0151}]|oe|g;
# U+015B LATIN SMALL LETTER S WITH ACUTE
	s|[\x{015B}ö]|s|g;
# U+021B LATIN SMALL LETTER T WITH COMMA BELOW
	s|\x{021B}|t|g;
	s|[˘˙˚]|u|g;
	s|[¸]|ue|g;
	s|˝|y|g;
# U+017B LATIN CAPITAL LETTER Z WITH DOT ABOVE
# U+017C LATIN SMALL LETTER Z WITH DOT ABOVE
# U+017D LATIN CAPITAL LETTER Z WITH CARON
# U+017E LATIN SMALL LETTER Z WITH CARON
	s|[\x{017E}\x{017D}\x{017C}\x{017B}û]|z|g;
	s|ﬂ|ss|g;
#	remove ' when sorting
	s|'||g;

	Deb_call_strucOut ();
	return $_;
}
#-----------------------
sub generate_banner_file {
  	Deb_call_strucIn ("generate_banner_file");
	

#
# banner html file
#
 print DBG "Conference Site : $conference_site_lat\n";
 convert_spec_chars ($conference_site, "conf_site");
 $conference_site = $_;
 print DBG "Conference Site : $_\n";
 $logo_image      = $img_directory.$conference_logo;
 my $bannerfile   = $html_directory."b0nner.htm";
 open (BFHTM, ">:encoding(UTF-8)", $bannerfile) or die ("Cannot open '$bannerfile' -- $! (line ",__LINE__,")\n");
#+ open (BFHTM, ">", $bannerfile) or die ("Cannot open '$bannerfile' -- $! (line ",__LINE__,")\n");
 print BFHTM $html_content_type."\n",
             "<html lang=\"en\">\n",
             "<head>\n",
             "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#			 "  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
             "  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
             "  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
             "  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
             "  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
             "  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
             "  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
             "  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
             "  <title>$conference_name - Conference</title>\n",
             "  <script src=\"xbt.js\"></script>\n",
             "  <script src=\"Hyphenator.js\"></script>\n",
             "  <script src=\"en.js\"></script>\n",
             "  <script type=\"text/javascript\">Hyphenator.config({remoteloading : false}); Hyphenator.run();</script>\n",
             "</head>\n",
             "<body>\n",
             "<table>\n",
             "   <tr>\n",
             "      <td class=\"mainmenu-logo\">\n",
             "          <a href=\"../index.html\" target=\"_parent\">\n",
             "          <img src=\"$logo_image\" alt=\"conference logo icon\" width=\"$logo_width\" height=\"$logo_height\"\n",
             "               alt=\"$conference_name Proceedings &mdash; $conference_site_UTF logo\" /></a>\n",
             "      </td>\n",
             "      <td class=\"mainmenu-name\" nowrap>\n",
             "          $conference_name - Proceedings<br />\n",
             "          $conference_site_UTF<br />\n";
 if ($conference_pre) {
	print BFHTM "          <i>$conference_pre_text</i>\n"; 
 }
 print BFHTM "      </td>\n",
             "      <td class=\"mainmenu-idx\">\n",
             "          <a class=\"mainmenu-item\" target=\"_parent\" href=\"../index.html\">Home</a>&nbsp;|&nbsp;\n",
             "          <a class=\"mainmenu-item\" target=\"_parent\" href=\"sessi0n.htm\">Session&nbsp;Index</a>&nbsp;|&nbsp;\n",
             "          <a class=\"mainmenu-item\" target=\"_parent\" href=\"class.htm\">Classification&nbsp;Index</a>&nbsp;|&nbsp;\n",
             "          <a class=\"mainmenu-item\" target=\"_parent\" href=\"author.htm\">Authors&nbsp;Index</a>&nbsp;|&nbsp;\n";
 if (!$conference_pre) {
	print BFHTM "          <a class=\"mainmenu-item\" target=\"_parent\" href=\"keyword.htm\">Keyword&nbsp;Index</a>&nbsp;|&nbsp;\n",
 }
 print BFHTM "          <a class=\"mainmenu-item\" target=\"_parent\" href=\"inst.htm\">List&nbsp;of&nbsp;Institutes</a>&nbsp;|&nbsp;\n";
 if (!$conference_pre) {
	print BFHTM "          <a class=\"mainmenu-item\" target=\"_parent\" href=\"instdoi.htm\">DOI&nbsp;of&nbsp;Institutes</a>&nbsp;|&nbsp;\n";
 }
 print BFHTM "      </td>\n",
             "   </tr>\n",
             "</table>\n",
             "</body>\n",
             "</html>\n";
 close (BFHTM);
 Deb_call_strucOut ();
}
#-----------------------
sub authorindex_open_file {
  	Deb_call_strucIn ("authorindex_open_file");

#
# base html file for author list
#
 my $authorfile   = $html_directory."author.htm";
 print DBG "== List of Authors' Index letters $alph_letters in Framefile\n";
 open (AFHTM, ">:encoding(UTF-8)", $authorfile) or die ("Cannot open '$authorfile' -- $! (line ",__LINE__,")\n");
 print AFHTM $html_content_type."\n",
             "<html lang=\"en\">\n",
             "<head>\n",
             "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#			 "  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
             "  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
             "  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
             "  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
             "  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
             "  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
             "  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
             "  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
             "  <title>$conference_name - List of Authors</title>\n",
             "  <script src=\"xbt.js\"></script>\n",
             "  <script src=\"Hyphenator.js\"></script>\n",
             "  <script src=\"en.js\"></script>\n",
             "  <script type=\"text/javascript\">Hyphenator.config({remoteloading : false}); Hyphenator.run();</script>\n",
             "</head>\n\n",
             "<frameset rows=\"",$banner_height,"px, *\">\n",
             "  <frame src=\"b0nner.htm\" name=\"b0nner\" frameborder=\"1\" />\n",
             "  <frameset cols=\"17%,*\">\n",
             "    <frame src=\"auth1.htm\" name=\"left\"  frameborder=\"1\" />\n",
             "    <frame src=\"auth2.htm\" name=\"right\" frameborder=\"1\" />\n",
             "  </frameset>\n",
             "  <noframes>\n",
             "    <body class=\"debug\">\n",
             "    <p>This page uses frames, but your browser doesn't support them.</p>\n",
             "    </body>\n",
             "  </noframes>\n",
             "</frameset>\n",
             "</html>\n";
 close (AFHTM);
#
# Authors' index file
#
 my $autidxfile   = $html_directory."auth1.htm";
 open (AXHTM, ">:encoding(UTF-8)", $autidxfile) or die ("Cannot open '$autidxfile' -- $! (line ",__LINE__,")\n");
# open (AXHTM, ">", $autidxfile) or die ("Cannot open '$autidxfile' -- $! (line ",__LINE__,")\n");
 print AXHTM $html_content_type."\n",
             "<html lang=\"en\">\n",
             "<head>\n",
             "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#			 "  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
             "  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
             "  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
             "  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
             "  <script src=\"xbt.js\"></script>\n",
             "  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
             "  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
             "  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
             "  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
             "  <title>$conference_name - List of Authors</title>\n",
             "</head>\n\n",
             "<body class=\"debug\">\n",
             "<p class=\"list-title\">List of Authors</p>\n";
  $alph_authindex = "";
  Deb_call_strucOut ();
}
#-----------------------
sub authorindex_add_entry {
  	Deb_call_strucIn ("authorindex_add_entry ($authname)");
#
# entries in the left frame
#
     my $act_letter = uc ( substr ($authname,0,1) );
     straighten_name ($act_letter);
     if ($_ ne uc ( substr ($authname,0,1) ) ) { print DBG "====> Straintn: $_:uc ( substr ($authname,0,1) )\n"; }
     print DBG "--|> $authname  <|> $act_letter\n";
     if ($alph_authindex ne $act_letter) {
         $alph_authchar .= $act_letter;
         $alph_authindex = $act_letter;
#         print AXHTM "<br /><span class=\"list-item\"><a id=\"$alph_authindex\">$alph_authindex</a></span><br />\n";
         print AXHTM "<br /><a class=\"list-item\" id=\"$alph_authindex\">$alph_authindex</a><br />\n";
     }
 #
     my ($authfile) = $ahtmlfile =~ m/\/(auth.*?)$/;
 #
 # write reference for author
 #
    my $last_ini = convert_spec_chars ($authname, "authname-AX");
	my $auth_id = $last_aid;
		$auth_id =~ s|JACoW-0*(\d+)|$1|;
	print DBG	"-21y--> $pap # $ale_auth\n";
	my $ale_inst = "$contrib_abb[$pap][$ale_auth], $contrib_ins[$pap][$ale_auth]";
	$ale_inst = convert_spec_chars ($ale_inst, "authname-3-AX");
 	my $auth_extra_info = "<strong>$ale_inst</strong> ($auth_id)";
	my $ale_id   = $authfile;
	   $ale_id   =~ s|\.htm||i;
	print DBG " > additional infos:($last_ini) $ale_inst ($auth_id)\n";
	print AXHTM "<div>\n";
	if ($authname eq $auth8) {
		print DBG " ==> [!utf8] $authname:$auth8\n";
		print AXHTM "<a class=\"auth-item\" href=\"$authfile\"  onmouseover=\"XBT(this, {id: '$ale_id'})\" target=\"right\">$last_ini</a><br />\n";
	} else {
		print DBG " --> [=utf8] $authname:$auth8\n";
		my $auth8_loc .= convert_spec_chars ($auth8, "auth8-cmp");
		convert_spec_chars ($authname, "authname-2-AX");
		if ($last_ini eq $auth8_loc) {$auth8_loc = "";} else { $auth8_loc = "[$auth8_loc]" ;}
		print AXHTM "<a class=\"auth-item\" href=\"$authfile\"  onmouseover=\"XBT(this, {id: '$ale_id'})\" target=\"right\">$last_ini&nbsp; &nbsp;&nbsp;$auth8_loc</a><br />\n";
	}
 	print AXHTM "<div style=\"position: relative; width: 130px; background-color: #e4e4e4;\" id=\"$ale_id\" class=\"xbtooltip\">$auth_extra_info</div>\n</div>\n";
	Deb_call_strucOut ();
}
#-----------------------
sub authorindex_close_file {
  	Deb_call_strucIn ("authorindex_close_file");
     #
     # noframe part now
     #
     print AXHTM "<br />\n<div>&nbsp;</div><br />\n",
	             "<div>&nbsp;</div><br />\n",
				 "<div>&nbsp;</div><br />\n",
                 "</body>\n\n",
                 "</html>\n";
    close (AXHTM);
	Deb_call_strucOut ();
}
#-----------------------
sub generate_author_basefile {
  	Deb_call_strucIn ("generate_author_basefile");

    my $act_letter;
    my $ial;
    my $auth2file   = $html_directory."auth2.htm";
    open (ABHTM, ">:encoding(UTF-8)", $auth2file) or die ("Cannot open '$auth2file' -- $! (line ",__LINE__,")\n");
#+    open (ABHTM, ">", $auth2file) or die ("Cannot open '$auth2file' -- $! (line ",__LINE__,")\n");
    print ABHTM $html_content_type."\n",
                "<html lang=\"en\">\n",
                "<head>\n",
                "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#			    "  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
                "  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
                "  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
                "  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
                "  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
                "  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
				"  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
                "  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
                "  <title>$conference_name - List of Authors</title>\n",
                "</head>\n\n",
                "<body>\n",                 # bgcolor=\"\#ffffff\">\n",
                "<br />\n",
                "<div id=\"Menu\">\n",
                "  <ul>\n";
     for ($ial=0; $ial<length($alph_letters);$ial++ ) {
         $act_letter = uc ( substr($alph_letters, $ial, 1) );
         print DBG "ABHTM $act_letter ";
         print ABHTM "    <li><a href=\"auth1.htm\#$act_letter\" target=\"left\"><span>$act_letter</span></a></li>\n";
     }
     print ABHTM " </ul>\n",
                 "</div>\n",
                 "<br />\n",
                 "<span class=\"list-item\">Click on an Author to display a list of papers.</span>\n",
                 "<br />\n",
                 "</body>\n",
                 "</html>\n";
    close (ABHTM);
	Deb_call_strucOut ();
}
#-----------------------
#
# Session base files
#
sub generate_session_basefile {
  	Deb_call_strucIn ("generate_session_basefile");
#
# base html file for session list
#
    my $sessionfile   = $html_directory."sessi0n.htm";
    open (SBHTM, ">:encoding(UTF-8)", $sessionfile) or die ("Cannot open '$sessionfile' -- $! (line ",__LINE__,")\n");
    print SBHTM $html_content_type."\n",
                "<html lang=\"en\">\n",
                "<head>\n",
                "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#			    "  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
                "  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
                "  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
                "  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
                "  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
                "  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
				"  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
                "  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
                "  <title>$conference_name - Table of Sessions</title>\n",
                "</head>\n\n",
                "<frameset rows=\"",$banner_height,"px, *\">\n",
                "  <frame src=\"b0nner.htm\" name=\"b0nner\" frameborder=\"1\" />\n",
                "  <frameset cols=\"20%,*\">\n",
                "    <frame src=\"sessi0n1.htm\" name=\"left\"  frameborder=\"1\" />\n",
                "    <frame src=\"sessi0n2.htm\" name=\"right\" frameborder=\"1\" />\n",
                "  </frameset>\n",
                "  <noframes>\n",
                "    <body class=\"debug\">\n",
                "    <p>This page uses frames, but your browser doesn't support them.</p>\n",
                "    </body>\n",
                "  </noframes>\n",
                "</frameset>\n",
                "</html>\n";
    close (SBHTM);
#
# html file for base session (click to select)
#
    my $sess2file   = $html_directory."sessi0n2.htm";
    open (SBHTM, ">:encoding(UTF-8)", $sess2file) or die ("Cannot open '$sess2file' -- $! (line ",__LINE__,")\n");
    print SBHTM $html_content_type."\n",
                "<html lang=\"en\">\n",
                "<head>\n",
                "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#			    "  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
                "  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
                "  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
                "  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
                "  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
                "  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
				"  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
                "  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
                "  <title>$conference_name - Table of Sessions </title>\n",
                "</head>\n\n",
                "<body>\n",                 # bgcolor=\"\#ffffff\">\n",
                "  <span class=\"list-item\">Click on an Session to display a list of papers.</span>\n",
                "<br />\n",
                "</body>\n",
                "</html>\n";
    close (SBHTM);
	Deb_call_strucOut ();
}
#-----------------------
sub generate_keyword_basefile {
  	Deb_call_strucIn ("generate_keyword_basefile");
#
# base html file for keyword list
#
    my $keywordfile   = $html_directory."keyword.htm";
    open (KBHTM, ">:encoding(UTF-8)", $keywordfile) or die ("Cannot open '$keywordfile' -- $! (line ",__LINE__,")\n");
    print KBHTM $html_content_type."\n",
                "<html lang=\"en\">\n",
                "<head>\n",
                "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#			    "  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
                "  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
                "  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
                "  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
                "  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
                "  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
				"  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
                "  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
                "  <title>$conference_name - List of Keywords</title>\n",
                "</head>\n\n",
                "<frameset rows=\"",$banner_height,"px, *\">\n",
                "  <frame src=\"b0nner.htm\" name=\"b0nner\" frameborder=\"1\" />\n",
                "  <frameset cols=\"200,*\">\n",
                "    <frame src=\"keyw1.htm\" name=\"left\"  frameborder=\"1\" />\n",
                "    <frame src=\"keyw2.htm\" name=\"right\" frameborder=\"1\" />\n",
                "  </frameset>\n",
                "  <noframes>\n",
                "    <body class=\"debug\">\n",
                "    <p>This page uses frames, but your browser doesn't support them.</p>\n",
                "    </body>\n",
                "  </noframes>\n",
                "</frameset>\n",
                "</html>\n";
    close (KBHTM);
#
# html file for base keyword (click to select)
#
    my $keyw2file   = $html_directory."keyw2.htm";
    open (KBHTM, ">:encoding(UTF-8)", $keyw2file) or die ("Cannot open '$keyw2file' -- $! (line ",__LINE__,")\n");
    print KBHTM $html_content_type."\n",
                "<html lang=\"en\">\n",
                "<head>\n",
                "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#			    "  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
				"  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
                "  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
                "  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
                "  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
                "  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
				"  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
                "  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
                "  <title>$conference_name - List of Keywords</title>\n",
                "</head>\n\n",
                "<body>\n",                 # bgcolor=\"\#ffffff\">\n",
                "<br />\n",
                "<div id=\"Menu\">\n",
                "  <ul>\n";
    my $act_letter;
    my $ial;
    for ($ial=0; $ial<length($keyw_letters);$ial++ ) {
        $act_letter = uc ( substr($keyw_letters, $ial, 1) );
        print DBG "$act_letter ";
        print KBHTM "    <li><a href=\"keyw1.htm\#$act_letter\" target=\"left\"><span>$act_letter</span></a></li>\n";
    }
    print KBHTM " </ul>\n",
                "</div>\n",
                "<br />\n",
                "<span class=\"list-item\">Click on a Keyword to display a list of papers.</span>\n",
                "<br />\n",
                "</body>\n",
                "</html>\n";
    close (KBHTM);
	Deb_call_strucOut ();
}
#-----------------------
sub generate_keyword_head {
  	Deb_call_strucIn ("generate_keyword_head");

     my $act_letter;
     my $ial;
     print KHTM $html_content_type."\n",
                "<html lang=\"en\">\n",
                "<head>\n",
                "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#			    "  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
                "  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
                "  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
				"  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
                "  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
                "  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
                "  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
                "  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
                "  <script src=\"xbt.js\"></script>\n",
                "  <script src=\"Hyphenator.js\"></script>\n",
                "  <script src=\"en.js\"></script>\n",
                "  <script type=\"text/javascript\">Hyphenator.config({remoteloading : false}); Hyphenator.run();</script>\n",
                "  <title>$conference_name - List of Keywords ($act_keyword)</title>\n",
                "</head>\n\n",
                "<body class=\"debug\">\n",
                "<br />\n",
                "<div id=\"Menu\">\n",
                "  <ul>\n";
     for ($ial=0; $ial<length($keyw_letters);$ial++ ) {
         $act_letter = uc ( substr($keyw_letters, $ial, 1) );
         print DBG "$act_letter ";
         print KHTM "    <li><a href=\"keyw1.htm\#$act_letter\" target=\"left\"><span>$act_letter</span></a></li>\n";
     }
     print KHTM " </ul>\n",
                "</div>\n",
                "<br />\n",
                "<span class=\"sessionheader\">Keyword: <span class=\"highlight_topic\">$act_keyword</span></span>\n",
#~#                "<table class=\"tabledef\" title=\"All papers for Keyword ($act_keyword)\">\n",
                "<table class=\"tabledef\">\n",
#                "<tbody>\n",
                "    <tr class=\"tablerow\">\n",
                "        <th class=\"papercodehead\">Paper</th>\n",
                "        <th class=\"papertitlehead\">Title</th>\n",
                "        <th class=\"paperotherkeyw\">Other Keywords</th>\n",
                "        <th class=\"papernumberhead\">Page</th>\n",
                "    </tr>\n";
	Deb_call_strucOut ();
}
#-----------------------
sub generate_keyword_entry {
  	Deb_call_strucIn ("generate_keyword_entry ($act_keyword)");

        convert_spec_chars ($title[$pap], "title_keyw-KH");
        my $lc_paper = ".".$paper_directory.lc($paper_code[$pap]).".pdf";
        #
        # give link (and size as tooltip)
        #
        print KHTM "    <tr class=\"tablerow\" id=\"$paper_code[$pap]\">\n",
                   "        <td class=\"papkey\"><a class=\"papkey-hov\" href=\"$lc_paper\" onmouseover=\"XBT(this, {text: '$paper_pdf_size[$pap]', className: 'xbtooltip'})\"",
#                  " title=\"$paper_pdf_size[$pap]\"",
                   " target=\"pdf\">$paper_code[$pap]</a></td>\n",
                   "        <td class=\"paptitle\">$_</td>\n";
        my $k;
        my $keyw = "";
        my $keylast = $#{$keywords[$pap]};
        my $keyscn;
        for ($k=0; $k<=$keylast; $k++) {
            $keyscn = $keywords[$pap][$k];
            if ($act_keyword ne $keyscn) {
                for (my $lt=0; $lt<=$num_of_keywords; $lt++) {
                    if ($keywords_sorted[$lt] eq $keyscn) {
                        $keyw .= sprintf ("<a class=\"papkeyword-hov\" href=\"keyw%04i.htm\" target=\"right\">$keyscn</a>, ", $lt);
                        $lt = $num_of_keywords + 1;
                    }
                }
            }
        }
        $keyw = substr($keyw, 0, length($keyw)-2);
        print KHTM "        <td class=\"papkeyword\">$keyw</td>\n";
        $page_start_toc = $page_start[$pap];
        if ($page_start_toc == 0) {
            $page_start_toc = 1;
        }
        print KHTM "        <td class=\"pappage\">$page_start_toc</td>\n",
                   "    </tr>\n",
                   "    <tr class=\"tablerow\">\n",
                   "        <td>&nbsp;</td>\n",
                   "        <td><ul>\n";
        #
        # list with <ol> <authors>
        #
        my $auth_list_complete = "";
        my $authorlist = "";
        my $author_ac;
        my @contrib_seq;
        undef @contrib_seq;
        my $i1;
        my $act_ins_abb;    # author's institute abbreviation
        my $act_idx;
        $j = 0;
        my $numele = $authors[$pap];
        while ($j <= $numele) {
            for ($auth=0; $auth<=$numele; $auth++) {
                if (!defined $contrib_seq[$auth]) {
                    $act_ins_abb = $contrib_abb[$pap][$auth];   # author's institute abbreviation
                    $act_idx     = $auth;
                    $author_ac   = "$contrib_ini[$pap][$auth] $contrib_lst[$pap][$auth]";
                    print DBG "Key1: act.author: ª$author_ac´ #paper: ª$pap´  main.author: ª$main_author[$pap]´\n";
                    if ($author_ac eq $main_author[$pap]) {
                        $authorlist = "<strong>$contrib_in8[$pap][$auth]&nbsp;$contrib_ln8[$pap][$auth]</strong>";  # utf-8
                    } else {
                        $authorlist =         "$contrib_in8[$pap][$auth]&nbsp;$contrib_ln8[$pap][$auth]";                    # utf-8
                    }
                    #
                    # combine all into one list
                    #
                    if ($contrib_ln8[$pap][$auth] eq $contrib_lst[$pap][$auth] &&
                        $contrib_in8[$pap][$auth] eq $contrib_ini[$pap][$auth]) {
                        $auth_list_complete .= "$contrib_ini[$pap][$auth] $contrib_lst[$pap][$auth]";
                    } else {
                        $auth_list_complete .= "$contrib_ini[$pap][$auth] $contrib_lst[$pap][$auth] ($contrib_in8[$pap][$auth] $contrib_ln8[$pap][$auth])";
                    }
                    $auth_list_complete .= ", ";
                    $contrib_seq[$auth]++;
                    $i1 = $auth + 1;
                    last;
                }
            }
            for ($auth=$i1; $auth<=$numele; $auth++) {
               if (!defined $contrib_seq[$auth] && $act_ins_abb eq $contrib_abb[$pap][$auth]) {
                    $contrib_seq[$auth]++;
                    $author_ac = "$contrib_ini[$pap][$auth] $contrib_lst[$pap][$auth]";
                    if ($author_ac eq $main_author[$pap]) {
                        $authorlist .= ", <strong>$contrib_in8[$pap][$auth]&nbsp;$contrib_ln8[$pap][$auth]</strong>"; # utf-8
                    } else {
                        $authorlist .= ", $contrib_ini[$pap][$auth]&nbsp;$contrib_ln8[$pap][$auth]";                  # utf-8
                    }
                    if ($contrib_ln8[$pap][$auth] eq $contrib_lst[$pap][$auth] &&
                        $contrib_in8[$pap][$auth] eq $contrib_ini[$pap][$auth]) {
                        $auth_list_complete .= "$contrib_ini[$pap][$auth] $contrib_lst[$pap][$auth]";
                    } else {
                        $auth_list_complete .= "$contrib_in8[$pap][$auth] $contrib_lst[$pap][$auth] ($contrib_ln8[$pap][$auth])";
                    }
                    $auth_list_complete .= ", ";
                }
            }
            convert_spec_chars ($authorlist, "authorlist-KH");
            print KHTM "                <li><span class=\"author_cl\">$_</span><br />\n";
            #
            # special InDiCo case: Abbreviation == Institute's name
            #
            my $contrib_absins = "$contrib_abb[$pap][$act_idx], ";
            if ($contrib_abb[$pap][$act_idx] eq $contrib_ins[$pap][$act_idx] or
                $contrib_ins[$pap][$act_idx] eq "") {
                # nada mas
            } else {
                $contrib_absins .= $contrib_ins[$pap][$act_idx];
            }
            convert_spec_chars ($contrib_absins, "contrin_abbins-KH");
            $auth_list_complete = substr ($auth_list_complete, 0, -2)." [$contrib_absins] ";
            print KHTM "                       $_</li>\n";
            $j = $numele + 1;
            for ($i=0; $i<=$numele; $i++) {
                if (!defined $contrib_seq[$i]) {
                    $j = $i;
                    last;
                }
            }
        }
        print KHTM "        </ul></td>\n",
                   "        <td>&nbsp;</td>\n",
                   "    </tr>\n";
        include_abstract_etc (*KHTM);
	    Deb_call_strucOut ();
}
#-----------------------
sub generate_keyword_end {
  	Deb_call_strucIn ("generate_keyword_end");

    print KHTM 	"</table>\n",
                "</body>\n\n",
				"</html>\n";
    close (KHTM);
	Deb_call_strucOut ();
}
#-----------------------
sub generate_author_head {
  	Deb_call_strucIn ("generate_author_head");

     my $act_letter;
     my $ial;
     print DBG " ## working on $authname ";
     convert_spec_chars ($authname, "authname-AH");
     print AHTM $html_content_type."\n",
                "<html lang=\"en\">\n",
                "<head>\n",
                "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#			    "  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
                "  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
                "  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
				"  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
                "  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
                "  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
                "  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
                "  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
                "  <script src=\"xbt.js\"></script>\n",
                "  <script src=\"Hyphenator.js\"></script>\n",
                "  <script src=\"en.js\"></script>\n",
                "  <script type=\"text/javascript\">Hyphenator.config({remoteloading : false}); Hyphenator.run();</script>\n",
                "  <title>$conference_name - List of Authors ($_)</title>\n",
                "</head>\n\n",
                "<body class=\"debug\">\n",
                "<br />\n",
                "<div id=\"Menu\">\n",
                "  <ul>\n";
     for ($ial=0; $ial<length($alph_letters);$ial++ ) {
         $act_letter = uc ( substr($alph_letters, $ial, 1) );
         print DBG "$act_letter ";
         print AHTM "    <li><a href=\"auth1.htm\#$act_letter\" target=\"left\"><span>$act_letter</span></a></li>\n";
     }
     print AHTM " </ul>\n",
                 "</div>\n";

     my $auth8_loc = "";
     my $auth_tmp  = convert_spec_chars ($authname, "authtmp-AH");
	 if ($authname ne $auth8) {
		print DBG " --> [utf8] $authname:$auth8\n";
		$auth8_loc  = "&nbsp;&nbsp;&nbsp;[".convert_spec_chars ($auth8, "auth8-AH")."]";
	 }
	 if ($auth_tmp eq $auth8) {
		$auth8_loc  = "";
     }
     print AHTM "<br />\n",
                "<span class=\"sessionheader\">Author: <span class=\"author_se\">$auth_tmp $auth8_loc</span></span>\n",
#~#                "<table class=\"tabledef\" title=\"All papers for Author ($auth_tmp $auth8_loc)\">\n",
                "<table class=\"tabledef\">\n",
#                "<tbody>\n",
                "    <tr class=\"tablerow\">\n",
                "        <th class=\"papercodehead\">Paper</th>\n",
                "        <th class=\"papertitlehead\">Title</th>\n",
                "        <th class=\"papernumberhead\">Page</th>\n",
                "    </tr>\n";
	Deb_call_strucOut ();
}
#-----------------------
sub generate_author_entry {
  	Deb_call_strucIn ("generate_author_entry");
	#	
	# AHTM for multiple program codes, the secondary paper codes are skipped as main entry
	#
	if ($prg_code[$pap][$prg_code_p[$pap]] eq $paper_code[$pap]) {
        print DBG "*generate_author_entry: Paper ª$pap´ Title ª$_´\n";
        convert_spec_chars ($title[$pap], "title-AH");
        print AHTM "    <tr class=\"tablerow\" id=\"$paper_code[$pap]\">\n";
        my $lc_paper = ".".$paper_directory.lc($paper_code[$pap]).".pdf";
        if ($paper_with_pdf[$pap]) {
            #
            # give link (and size as tooltip)
            #
            print AHTM "        <td class=\"papkey\"><a class=\"papkey-hov\" href=\"$lc_paper\" onmouseover=\"XBT(this, {text: '$paper_pdf_size[$pap]', className: 'xbtooltip'})\"",
                       " target=\"pdf\">$paper_code[$pap]</a></td>\n";
        } else {
            if ($conference_type_indico) {
                #
                # for InDiCo conferences the paper_code name is not shown (pure numeric)
                #
                print AHTM "        <td class=\"papkey\"></td>\n";
            } else {
				my $class_c = "papkey";
                if ($paper_strike_thru) {
					$class_c = "papkeystr";
                }
				print AHTM "        <td class=\"$class_c\"><div class=\"xbtooltipstr\" onmouseover=\"XBT(this, {text: '$paper_pdf_size[$pap]', className: 'xbtooltipstrc'})\">$paper_code[$pap]</div></td>\n";
            }
        }
        print AHTM "        <td class=\"paptitle\">$_</td>\n";
        if ($paper_with_pdf[$pap]) {
            $page_start_toc = $page_start[$pap];
            if ($page_start_toc == 0) {
                $page_start_toc = 1;
            }
			if ($conference_pre) {
				# Pre-Press Release
				$page_start_toc = -1;
			}
			print AHTM "        <td class=\"pappage\">$page_start_toc</td>\n";
				   
		} else {
			print AHTM "        <td>&nbsp;</td>\n";
		}
		#
		# NOMAT? 
		#		are there paper and/or slides, or does the author provide nothing for publication?
		#
#InAc	NoMat (*AHTM, $pap, $sess);
		#
		# AHTM for multiple program codes output additional infos (secondary paper codes)
		#
#!#		print " AuSC:($pap)pap:($paper_code[$pap] =$#{$prg_code[$pap]}, $prg_code_p[$pap]\n";
		if ($#{$prg_code[$pap]} > 0) {
			#
			# there is (at least) one secondary code
			#  => easy: $prg_code[$pap][$prg_code_p[$pap]] => give primary code e.g. TUPRO023
			#
			for ($i = 0; $i <= $#{$prg_code[$pap]}; $i++) {
#!#				print " AuSC~($i)pap:($paper_code[$pap] =$prg_code[$pap][$i]\n";
				my $sesslink	= find_lc_session ($prg_code[$pap][$i]); 
				if ($prg_code[$pap][$i] ne $paper_code[$pap]) {
#!#					print " AuSC??($pap)pap:($paper_code[$pap] +:$prg_code[$pap][$i]\n";
					print AHTM "    </tr>\n";
					print AHTM "    <tr class=\"tablerow\">\n";
					print AHTM "        <td class=\"papkey\"><a class=\"papkey-hov\" href=\"$sesslink.htm#$prg_code[$pap][$i]\" target=\"_self\">$prg_code[$pap][$i]</a></td>\n";
					print AHTM "        <td class=\"comment\">$code_link_altern_text</td>\n";
					print AHTM "        <td>&nbsp;</td>\n";
				}
			}
		}
        #
        # AHTM <ul> prepare Author list
        #
        print AHTM "    </tr>\n",
                   "    <tr class=\"tablerow\">\n",
                   "        <td>&nbsp;</td>\n",
                   "        <td><ul>\n";
        #
        # $author_fl is actual author for author index entry (in forward notation while $authname is backward)
        #
        (my $z, my $a, my $aid, my $b, my $c, my $d, my $e, my $author_fl, $auth8) = split (/∞/, $sorted_all_idx_authors[$ialentry]);
		$a   =~ s/\s+$//;
		$aid =~ s/\s+$//;
        print DBG sprintf ("\n 0:%-s (%-s)\n 1:%-s\n 2:%-s\n 3:%-s\n 4:%-s\n 5:%-s\n\n", $a, $aid, $b, $c, $d, $e, $author_fl);
        $author_fl =~ s/\s*$//o;
        #
        # list with <ol> authors
        #
        my $authorlist = "";
        my $numele = $authors[$pap];
        my @contrib_seq;
        undef @contrib_seq;
        my $i1;
        my $act_ins_abb;    # author's institute abbreviation
        my $act_idx;
        my $author_ac;
		my $author_aid;
        my $author_fs;
        my $author_concat;
        $j = 0;
        while ($j <= $numele) {
            for ($auth=0; $auth<=$numele; $auth++) {
                if (!defined $contrib_seq[$auth]) {
                    $act_ins_abb   = $contrib_abb[$pap][$auth];
                    $author_ac     = "$contrib_ini[$pap][$auth] $contrib_lst[$pap][$auth]";
                    $author_aid    = $contrib_aid[$pap][$auth];
                    $author_concat = "$contrib_in8[$pap][$auth]&nbsp;$contrib_ln8[$pap][$auth]";    # utf-8;
                    $author_fs     = $author_concat;
                    $act_idx       = $auth;
                    print DBG "Auth1: ac|fs.author: ª$author_ac ($author_aid)´ fl.author: ª$author_fl ($aid)´ #paper: ª$pap´  main.author: ª$main_author[$pap]´";
 #<                 if ($author_fl eq $author_ac) {
                    if ($aid eq $author_aid) {
                        $author_fs = "<span class=\"author_se\">$author_fs</span>";
                        print DBG " 1==\n";
                    } else {
                        print DBG " 1<>\n";
                    }
                    if ($author_ac eq $main_author[$pap]) {
                        $authorlist = "<strong>$author_fs</strong>";
                    } else {
                        $authorlist = $author_fs;
                    }
                    $contrib_seq[$auth]++;
                    $i1 = $auth + 1;
                    last;
                }
            }
            print DBG "**2a: $i1:ª$contrib_seq[$auth]´\n";
            for ($auth=$i1; $auth<=$numele; $auth++) {
                if (!defined $contrib_seq[$auth] && $act_ins_abb eq $contrib_abb[$pap][$auth]) {
                    $contrib_seq[$auth]++;
                    my $author_nx  = "$contrib_ini[$pap][$auth] $contrib_lst[$pap][$auth]";
                    $author_aid    = $contrib_aid[$pap][$auth];
                    $author_concat = "$contrib_in8[$pap][$auth]&nbsp;$contrib_ln8[$pap][$auth]";    # utf-8
                    $author_fs     = $author_concat;
                    $act_idx       = $auth;
#<                  if ($author_fl eq $author_nx) {
                    if ($aid eq $author_aid) {
                        $author_fs = "<span class=\"author_se\">$author_fs</span>";
                    }
                    if ($author_nx eq $main_author[$pap]) {
                        $author_fs = "<strong>$author_fs</strong>";
                    }
                    $authorlist .= ", $author_fs";
                }
            }
            convert_spec_chars ($authorlist, "authorlist-AH");
            print AHTM "                <li><span class=\"author_cl\">$_</span><br />\n";
            #
            # special InDiCo case: Abbreviation == Institute's name
            #
            if ($contrib_abb[$pap][$act_idx] eq $contrib_ins[$pap][$act_idx] ||
                $contrib_ins[$pap][$act_idx] eq "") {
                convert_spec_chars ($contrib_abb[$pap][$act_idx], "contrin_abb-AH");
            } else {
                convert_spec_chars ("$contrib_abb[$pap][$act_idx], $contrib_ins[$pap][$act_idx]", "contrin_abb-ins-AH");
            }
            print AHTM "                       $_</li>\n";
            $j = $numele + 1;
            for ($i=0; $i<=$numele; $i++) {
                if (!defined $contrib_seq[$i]) {
                    $j = $i;
                    last;
                }
            }
        }
        print AHTM "        </ul></td>\n",
                   "        <td>&nbsp;</td>\n",
                   "    </tr>\n";
        include_abstract_etc (*AHTM);
	} else {
		#
		# skipped records for secondary paper_codes
		#
		print DBG "AHTM-skip $paper_code[$pap] <act--prim> $prg_code[$pap][$prg_code_p[$pap]]\n";
	} # end skip (secondary) paper
	Deb_call_strucOut ();
}
#-----------------------
sub generate_author_end {
  	Deb_call_strucIn ("generate_author_end");

    print AHTM "</table>\n",
               "</body>\n\n",
               "</html>\n";
    close (AHTM);
    Deb_call_strucOut ();
}
#-----------------------------
#
# as each Author with an additional affiliation has a copy of the basic record + the new Institute set (incl Abbreviation)
#    Author of the same institute are combined into one record, before being stored in "$inst_author[]"
#
sub combine_authors_institutes {
  	Deb_call_strucIn ("combine_authors_institutes");
    #
    # create a new string for sort with "Institute + Author (last+initials)[ASCII+UTF8], Institute complete name, JACoW Author Id"
    # 		the institute's abbreviation is extended by 4 spaces to ensure that the separator (∞) doesn't influence the sort order
    for ($i=0; $i<=$authors[$paper_nr]; $i++) {
        $inst_author_nr++;
        $inst_author[$inst_author_nr] = "$contrib_abb[$paper_nr][$i]    ∞".								# author's institute abbr
                                        "$contrib_lst[$paper_nr][$i], $contrib_ini[$paper_nr][$i]∞".	# last name + initials
                                        "$contrib_ln8[$paper_nr][$i], $contrib_in8[$paper_nr][$i]∞".	# last name (utf-8) + # initials
                                        "$contrib_ins[$paper_nr][$i]∞".									# Institute's name
                                        "$contrib_aid[$paper_nr][$i]∞".									# JACoW Author Id
										"$paper_nr";        											# paper number (test)
        print DBG " #inst_auth#$inst_author_nr=$inst_author[$inst_author_nr]\n";
    }
    Deb_call_strucOut ();
    return;
}
#-----------------------------
sub write_tex_and_bat_file {
  	Deb_call_strucIn ("write_tex_and_bat_file (".uc($paper_code[$pg_idx]).".tex)");

    print DBG "wtf   ----------------------[$sess_idx:$pg_idx]\n";
    print DBG "wtf Code :  $paper_code[$pg_idx]\n";
    print DBG "wtf Start:  $page_start[$pg_idx]\n";
    print DBG "wtf Pages:  $paper_pages[$pg_idx]\n";
    print DBG sprintf ("wtf Nxfre:  %-4i\n",$paper_pages[$pg_idx]+$page_start[$pg_idx]);
    print DBG "wtf Title:  $title[$pg_idx]\n";
    #--------------------
    # log pages per paper
    #
    print DBG sprintf ("%s=%i\n", $paper_code[$pg_idx], $paper_pages[$pg_idx]);
	my $editor;
	if (!defined $paper_editor[$pg_idx]) {
		$editor = "";
	} else {
		$editor = $paper_editor[$pg_idx];
	}
	$paper_editor[$pg_idx] = $editor;
	my $qaeditor;
	if (!defined $qa_editor[$pg_idx]) {
		$qaeditor = "";
	} else {
		$qaeditor = $qa_editor[$pg_idx];
	}
	$qa_editor[$pg_idx] = $qaeditor;
	print PPPOUT sprintf ("%i=%s=%i;%s;%s;%s;\n", $abs_id[$pg_idx], $paper_code[$pg_idx], $paper_pages[$pg_idx], $editor, $qaeditor, $paper_dotc[$pg_idx]);
#    my $keyw = join (", ", @{$keywords[$pg_idx]});
#	 $keywjoin{$i} = join (", ", @{$keywords[$i]});

    print DBG "wtf Keywd:  $keywjoin{$paper_code[$pg_idx]}\n";
    #--------------------
    # get paper title corrections here because it might be used in "create_missing_tex_file"
    #
    $santitle    = convert_spec_chars2TeX ($title[$pg_idx], "title-TeX");
    $santitle    = revert_from_context ($santitle);
    #--------------------
    # if no TeX/PDF file should be generated for missing papers,
    #    we have to check for a valid raw PDF file in $raw_paper_directory
    #
    my $pdffile = $raw_paper_directory.lc($paper_code[$pg_idx]).".pdf";
    (my $chkpdffile = $pdffile) =~ s/\.\./\./;
    if (!$paper_not_received_link) {
        #
        if (-e "$chkpdffile") {
            # file exists
        } else {
			Deb_call_strucOut ();
            return;
        }
    } else {
        #
        # generate missing TeX file if PDF is not present
        #
        if (-e "$chkpdffile") {
            # file exists
        } else {
			print "###############>> generate missing TeX file for: $paper_code[$pg_idx]\n";
			print DBG "###############>> generate missing TeX file for: $paper_code[$pg_idx]\n";
            create_missing_tex_file ();
			Deb_call_strucOut ();
            return;
        }
    }
#
# open wrapper TeX file
#
    my $file =  $paper_directory.lc($paper_code[$pg_idx]).".tex";
#>110217+191106 doesn't work
    open (TeXOut, ">:encoding(UTF-8)", $file) or die ("Cannot open '$file' -- $! (line ",__LINE__,")\n");
#    open (TeXOut, ">", $file) or die ("Cannot open '$file' -- $! (line ",__LINE__,")\n");
#<    print TeXOut "% !TeX program = lualatex\n";
#<    print TeXOut "% !TeX encoding = utf8\n\n";
    print TeXOut $introdoc8;
    print TeXOut "\\usepackage{eso-pic, ifoddpage}\n\n",
				 "\\input{jacowscript-jpsp}\n\n";
#
# open AuthorAffiliationTitleCheck file
#      check PDF files in /CHECKED directory to leave out
#      files which already have been worked on
#
    my $checked_file =  $atc_directory."CHECKED/".lc($paper_code[$pg_idx]).".pdf";
	#
	# check for file
	#
	my $gen_atc = 1;
	if (-e "$checked_file") {
		# file exists
		$gen_atc = 0;  # PDF file exists therefore do not generate again
	}
	$file            =  $atc_directory.lc($paper_code[$pg_idx]).".tex";
	if ($gen_atc) {
		open (TeXATC, ">", $file) or die ("Cannot open '$file' -- $! (line ",__LINE__,")\n");  # >110217  ">:encoding(UTF-8)" removed
		print TeXATC $introdocATC;
		print TeXATC "\\input{jacowscript-jpsp}\n\n",
					 "\\usepackage{graphicx}\n",
					 "\\usepackage{ulem}\n\n",
					 "\\begin{document}\n\n";
	}
#
# why $clsMline="" and $clsSline=" " ???
#
    my $pdf_clsMline = "";
    if ($paper_mcls[$pg_idx] eq "") {
        $clsMline = "\\mbox{ }";
    } else {
      $clsMline = convert_spec_chars2TeX ($paper_mcls[$pg_idx], "pap_mcls-TeX");
      $clsMline = revert_from_context ($clsMline);
      $pdf_clsMline = $clsMline;
    }
    $clsSline = convert_spec_chars2TeX ($paper_scls[$pg_idx], "pap_scls-TeX");
    $clsSline = revert_from_context ($clsSline);
    my $pdf_clsSline = $clsSline;
# (!!)
    if ($clsSline eq "" || $clsSline eq " ") {
        $clsSline = "\\mbox{ }";
        $pdf_clsSline = "";
    }
    my $pdf_subject = $pdf_clsMline;
    if ($pdf_clsSline ne "") {
        $pdf_subject .= "/".$pdf_clsSline;
    }
    if ($pdf_subject eq "") {
        $pdf_subject = "Proceedings of $conference_name";
    }
    print DBG "*-=-* <$pg_idx> $auth_list_pdf[$pg_idx]\n";
#D  print     "***** <$pg_idx>\n";
#+    if ($auth_list_pdf[$pg_idx] =~ m|&#(\d+?);|) {
    if ($auth_list_pdf[$pg_idx] =~ m|&\#263;|)    { $auth_list_pdf[$pg_idx] =~ s|&#263;|\x{0107}|g; }
    if ($auth_list_pdf[$pg_idx] =~ m|&amp;#263;|) { $auth_list_pdf[$pg_idx] =~ s|&amp;#263;|\x{0107}|g; }
    if ($auth_list_pdf[$pg_idx] =~ m|&\#269;|)    { $auth_list_pdf[$pg_idx] =~ s|&#269;|\x{010d}|g; }
    if ($auth_list_pdf[$pg_idx] =~ m|&amp;#269;|) { $auth_list_pdf[$pg_idx] =~ s|&amp;#269;|\x{010d}|g; }
    if ($auth_list_pdf[$pg_idx] =~ m|&amp;#321;|) { $auth_list_pdf[$pg_idx] =~ s|&amp;#321;|\x{0141}|g; }
    if ($auth_list_pdf[$pg_idx] =~ m|&amp;#373;|) { $auth_list_pdf[$pg_idx] =~ s|&amp;#373;|\x{0175}|g; }  # Latin Small Letter W with Circumflex U+0175   utf8: c5 b5 
    if ($auth_list_pdf[$pg_idx] =~ m| &amp; |)    { $auth_list_pdf[$pg_idx] =~ s| &amp; | & |g; }
    if ($auth_list_pdf[$pg_idx] =~ m|&\#347;|)    { $auth_list_pdf[$pg_idx] =~ s|&#347;|\x{015b}|g; }
#        print "######## Problems!! ###\n",
#              "   -$1-      $auth_list_pdf[$pg_idx]\n",
#              "########\n";
#    }
#
# HyperREF and HyperXMP data embedded in PDF
# ------------------------------------------
#
#   x  not supported
#   !  automatically set by TeX
#   o  supported by JPSP script
#
# hyperref
# x baseurl				baseurl points points one level up and is used to resolve relative urls
# o pdfauthor			{<list of authors with comma but without institute>}
# ! pdfcreationdate		<!TeX>
# o pdfkeywords			{@keywords}	=> instead of ";" the keywords can be separated by ","
# o pdflang				{en}
# ! pdfmoddate			<!TeX>
# ! pdfproducer			<!TeX>
# o pdfsubject			{<main classification, sub classification>}
# o pdftitle			{<title of paper>}
#
# hyperxmp 4.1
# x pdfapart			-- conformance with PDF/A-xy  i.e. pdfapart=1
# x pdfaconformance		-- conformance with PDF/A-xy  i.e. pdfaconformance=B ~>  PDF/A-1B
# x pdfauthortitle		-- <prim author's title>
# x pdfbookedition		-- names the edition of the book
# x pdfbytes			<size> not set as the size is always the size from the last run
# o pdfcaptionwriter	{JPSP (Volker RW Schaa)}
# o pdfcontactaddress	{Planckstr. 1}
# o pdfcontactcity		{Darmstadt}
# o pdfcontactcountry	{Germany}
# o pdfcontactemail		{v.r.w.schaa@gsi.de}
# o pdfcontactphone		{49 6151 71 2340}
# o pdfcontactpostcode	{64291}
# x pdfcontactregion	--
# o pdfcontacturl		{https://www.jacow.org}
# o pdfcopyright		{CC by 3.0 ......}
# ! pdfdate				<!TeX>
# o pdfdocumentid		--
# o pdfdoi				{10.18429/JACoW-<conference>-<paper code>} without http or doi
# o pdfeissn			{<ISSN>}
# ! pdfinstanceid		--
# o pdfisbn				{<ISBN>}
# o pdfissn				{<ISSN>}
# ! pdfissuenum			-- the issue number within the volume -> pdfvolumenum
# o pdflicenseurl		{<cc-by-3.0>}
# ! pdfmetadate			<!TeX>		
# o pdfmetalang			{en}	<en-US, en-GB, de, ..> if not defined same as "pdflang"
# o pdfnumpages			{<SP+#Pages-1>}
# o pdfpagerange		{<SP-EP>}
# o pdfpublisher		{JACoW Publishing}
# o pdfpublication		{Proceedings of $conference_name}
# o pdfpubtype			<journal> if
# ! pdfsource			--
# x pdfsubtitle			--
# ! pdftype				default text
# o pdfurl				{https://www.jacow.org/<$conference_name>/papers/<paper code>.pdf}   "pdfurl" points to the complete url for the document.
# ! pdfversionid		-- version id
# ! pdfvolumenum		-- volume number
# 
# remove institute from author list
#
	my %seen;
	my $comp_auth_list	= convert_spec_chars2TeX ($auth_list_pdf[$pg_idx], "Prin TeXOut");
	$comp_auth_list		=~ s| \[.*?\]|,|g;
	$comp_auth_list		= trim($comp_auth_list);
	$comp_auth_list		=~ s|,$||;
	$comp_auth_list		=~ s/\|-\|/-/g;	# ConTeXt hyphens
	my @auts 			= split (/,/, $comp_auth_list);
	my @au 				= grep { !$seen{$_}++ } @auts;
	$comp_auth_list		= join (",", @au);

    print TeXOut "\\hypersetup{pdfpagemode=UseThumbs,%\n",
                 "            pdfstartview=FitBH,\n",
                 "            pdftitle={$santitle},\n",
                 "            pdfauthor={$comp_auth_list},\n",
                 "            pdfsubject={$pdf_subject},\n",
                 "            pdfkeywords={$keywjoin{$paper_code[$pg_idx]}},\n",
				 "			  }\n";
#IPT
#IPT                 "            pdflang={en},\n",
#IPT                 "            pdfmetalang={en},\n",
#IPT                 "            pdfcaptionwriter={JPSP (Volker RW Schaa)},\n",
#IPT				 "            pdfcontactaddress={Planckstr. 1},\n",
#IPT				 "            pdfcontactcity={Darmstadt},\n",
#IPT				 "            pdfcontactcountry={Germany},\n",
#IPT				 "            pdfcontactemail={v.r.w.schaa\@gsi.de},\n",
#IPT				 "            pdfcontactphone={49 6151 71 2340},\n",
#IPT				 "            pdfcontactpostcode={64291},\n",
#IPT				 "            pdfcontacturl={https://www.jacow.org},\n",
#IPT                 "            pdfcopyright={Copyright (C) $actual_year Content from this work may be used under the terms of the CC BY 3.0 licence. Any further distribution of this work must maintain attribution to the author(s), title of the work, publisher, and DOI},\n",
#IPT                 "            pdflicenseurl={https://creativecommons.org/licenses/by/3.0/},\n",
#IPT                 "            pdfdoi={10.18429/JACoW-$conference_name-$paper_code[$pg_idx]},\n",
#IPT                 "            pdfisbn={$conference_isbn},\n";
#IPT	if ($series_issn ne "") {
#IPT		print TeXOut "            pdfeissn={$series_issn},\n",
#IPT					 "            pdfissn={$series_issn},\n";
#IPT	}
	my $pgrange	= sprintf ("%i-%i", $page_start[$pg_idx], $page_start[$pg_idx]+$paper_pages[$pg_idx]-1);
#	($no_pdfs	= $paper_directory.lc($paper_code[$pg_idx]).".pdf") =~ s|\.\.\./||;
#	if (-e $no_pdfs) {
#		$filesize	= stat($no_pdfs)->size;
#		print TeXOut "            pdfbytes={$filesize},\n";
#	}
#???	(my $pdfurl	= "https://www.jacow.org/IPAC2018/".$no_pdfs) =~ s|\./||; 

#IPT    print TeXOut "            pdfnumpages={$paper_pages[$pg_idx]},\n",
#IPT                 "            pdfpagerange={$pgrange},\n",
#IPT#                 "            pdfbytes={$filesize},\n",
#IPT                 "            pdfpublisher={JACoW Publishing},\n",	
#IPT                 "            pdfpublication={Proceedings of $conference_name},\n",	
#IPT                 "            pdfpubtype={journal},\n",
#IPT                 "            pdfurl={$pdfurl},\n",
#IPT				 "            }\n\n",
        print TeXOut "\\begin{document}\n\n";
#
# Pre-Press release?   page_number => 0...
#
	if ($conference_pre) {
		print TeXOut "\\setcounter{page}{0}  % $paper_code[$pg_idx]\n";
	} else {
		# print " set page counter $paper_code[$pg_idx] => $page_start[$pg_idx]\n";
		if ($page_start[$pg_idx]) {
			print TeXOut "\\setcounter{page}{$page_start[$pg_idx]}  % $paper_code[$pg_idx]\n";
		}
	}

	if ($gen_atc) {
		my $act_symbol = "\\textbullet";
		my $act_color  = lc $paper_dotc[$pg_idx];
		$atc_print  = 1;
		if ($act_color eq "") {
			$act_color = "black";
			$atc_print = 0;
		} elsif ($act_color eq "assigned to an editor") {
			$act_color = "violet";
			$atc_print = 0;
		}
		#
		# filter out REDs
		#
		if ($act_color eq "red") {
			$atc_print = 0;
		}
		my $act_pap_edi = $paper_editor[$pg_idx];
		if ($act_pap_edi eq "") {
			$act_pap_edi = "not yet assigned to an editor";
		}
		my $act_qa_edi = $qa_editor[$pg_idx];
		if ($act_qa_edi eq "") {
			$act_qa_edi = "paper not yet QAed";
		}
		if ($atc_print) {
			#
			# suppress writing for "atc_print" (so it will not be found when searching for Red)
			#
			print TeXATC "\\setcounter{page}{0}   % $paper_code[$pg_idx]\n",
						 "\\begin{textblock*}{100mm}(\\textwidth,-1.3cm)\n",
						 "   \\Huge\\textcolor{$act_color}{$act_symbol}\n",
						 "\\end{textblock*}\n",
						 "\\begin{textblock*}{100mm}(\\textwidth,-0.5cm)\n",
						 "	\\rotatebox{-90}{%\n",
						 "     \\begin{tabular}{ll}\n",
						 "       Editor:  & \\textbf{$act_pap_edi}\\\\\n",
						 "       QA:      & \\textbf{$act_qa_edi}\\\\\n",
						 "     \\end{tabular}\n",
						 "  }%\n",
						 "\\end{textblock*}\n",
						 "\n",
						 "\\fancyhead[CE,CO]{\\bfseries\\textcolor{$TeXhighlite}{Proceedings of $conference_name, $conference_site_lat}}%\n",
						 "\\fancyfoot[CE,CO]{}\n",
						 "\\fancyfoot[LE,RO]{\\bfseries\\mbox{ }\\\\[5pt]\\normalsize\\textcolor{$TeXhighlite}{\\thepage}}\n";
						 if ($pdf_clsSline eq "") {
							print TeXATC "\\fancyfoot[LO,RE]{\\bfseries\\mbox{ }\\\\[5pt]\\textcolor{$TeXhighlite}{$clsMline}}\n";
						 } else {
							print TeXATC "\\fancyfoot[LO,RE]{\\bfseries\\textcolor{$TeXhighlite}{$clsMline}\\\\[5pt]\\textcolor{$TeXhighlite}{$clsSline}}\n";
						 }
			if (!$conference_type_indico) {
				print TeXATC "\\fancyhead[RE,RO]{\\bfseries\\textcolor{$TeXhighlite}{$paper_code[$pg_idx]}}\n";
				print TeXATC "\\fancyhead[LE,LO]{\\barcode{$paper_code[$pg_idx]}}\n";
			}
		}
		print TeXATC "\\begin{center}\n",
					 "\\fontsize{14.0}{17.0}\\selectfont\n",
# Chris!			 "\\bfseries\\uppercase{";
					 "\\bfseries{";
	}
#------
    #
    # printing header and footer
    #
	# ISBN if defined
	#
	$isbn_str = "";
	if ($conference_isbn ne "") {
		$isbn_str = "ISBN $conference_isbn";
	}
    #
	# ISSN if defined
	#
	$issn_str = "";
	if ($series_issn ne "") {
		$issn_str = "ISSN: \\texttt{$series_issn}";
	}
#	print "##################>>>>>>>>>>>>>>>>> isbn = $isbn_str\n";
    # copyright note needs to be positioned relative to the even page
    #   number (end) with a varying negative distance to compensate for
    #   current writing position
    #
	my $copyr_endpage	= $page_start[$pg_idx] + $paper_pages[$pg_idx];
    CopyrightOffset ($copyr_endpage);
	if ($conference_pre) {
		print TeXOut "\\fancyhead[CE,CO]{}\n";
	    print TeXOut "\\fancyhead[RE,LO]{\\bfseries\\textcolor{$TeXhighlite}{~Proceedings of $conference_name, $conference_site_lat \\qquad \\textcolor{red}{$conference_pre_text}}}\n";
		$copyr_prepress = "$conference_pub_copyr";	#‰ \\qquad \\textcolor{red}{$conference_pre_text}";
	} else {
		print TeXOut "\\fancyhead[RE,LO]{}\n";
		print TeXOut "\\fancyhead[CE,CO]{\\small $conference_title_shrt\\hfill $conference_name, $conference_site_lat\\hfill $conference_pub_by\\\\".
										 "ISBN: \\texttt{$conference_isbn}{\\hfill}{$issn_str\\hfill}\\texttt{doi:10.18429/JACoW-$conference_name-$paper_code[$pg_idx]}}\n";
		$copyr_prepress = "$conference_pub_copyr";
	}
	#
	# print Main- and when present Sub-Classification
	#
	if ($pdf_clsSline eq "") {
		print TeXOut "\\fancyfoot[LO,RE]{\\bfseries\\mbox{ }\\\\[5pt]\\textcolor{$TeXhighlite}{$clsMline}}\n";
	} else {
		print TeXOut "\\fancyfoot[LO,RE]{\\bfseries\\textcolor{$TeXhighlite}{$clsMline}\\\\[5pt]\\textcolor{$TeXhighlite}{$clsSline}}\n";
	}
	#
	# ISBN string placement for Pre-Press: footer is default  header selectable using "$conference_isbn_pos = 1"
	#
	my $texout_str;
	$texout_str = "\\fancyfoot[RO]{{\\bfseries\\textcolor{$TeXhighlite}{$paper_code[$pg_idx]}\\\\[5pt]\\normalsize\\textcolor{$TeXhighlite}{\\thepage}}%\n".
				  "                    \\begin{picture}(0,0)\\put(5,0){\\small%\n".
				  "                          \\rotatebox{90}{\\includegraphics[width=20pt]{$ccby_logo} $copyr_prepress}}%\n".
				  "                    \\end{picture}}\n";
	print TeXOut "$texout_str\n";
	$texout_str = "\\fancyfoot[LE]{{\\bfseries\\textcolor{$TeXhighlite}{$paper_code[$pg_idx]}\\\\[5pt]\\normalsize\\textcolor{$TeXhighlite}{\\thepage}}%\n".
				  "                    \\begin{picture}(0,0)\\put($cpx_pos_off,0){\\small%\n".
				  "                          \\rotatebox{90}{\\includegraphics[width=20pt]{$ccby_logo} $copyr_prepress}}%\n".
				  "                    \\end{picture}}\n";
	print TeXOut "$texout_str\n";

#‰    if (!$conference_type_indico) {
#‰        print TeXOut "\\fancyhead[LE,RO]{\\bfseries\\textcolor{$TeXhighlite}{$paper_code[$pg_idx]}}\n";
#‰    }
	print TeXOut "\\fancyfoot[CE,CO]{}\n",
				 "\\IfFileExists{$pdffile}{%\n";
    #
    # check and remove CropBox
    #
#    $CropBoxY = check_pdffile_scale ($pdffile);
#    if ($CropBoxY < 800) {
#        print TeXOut "\\includepdf[pages=-, noautoscale, offset=2pt -4pt,\n";
#        print DBG "pdf ($CropBoxY) scale=1.03, offset=10pt 0pt, \n";
#    } else {
#        print TeXOut "\\includepdf[pages=-, scale=1.07, offset=0 24pt,\n";
#        print DBG "pdf ($CropBoxY) scale=1.07, offset=0pt 24pt, \n";
#    }
	#
	# print watermark for peer-reviewed conferences when watermark string is defined and paper is "a"pproved
	#	this is achieved using packages "eso-pic" and "ifoddpage" within "includepdf" as parameters to "pagecommand"
	#
    print TeXOut "\\includepdf[pagecommand={%\n";
	#
	# print watermark for peer-reviewed conferences when watermark string is defined and paper is "a"pproved
	#
#	print ">> ($paper_code[$pg_idx]]) \"$referee_stat[$pg_idx]\" has $ref_watermark_prt\n";
	if ($ref_watermark_prt ne "") {
		if ($referee_stat[$pg_idx] eq "a") {
#			print ">> ($paper_code[$pg_idx]]) \"$referee_stat[$pg_idx]\"\n";
			print TeXOut "                          \\checkoddpage\n",
			             "                          \\ifoddpage\n",
						 "                              \\AddToShipoutPicture*{\\put( 42,23){\\small\\bfseries%\n",
						 "                                                     \\rotatebox{90}{$ref_watermark_prt}}}\n",
			             "                          \\else\n",
						 "                              \\AddToShipoutPicture*{\\put(545,23){\\small\\bfseries%\n",
						 "                                                     \\rotatebox{90}{$ref_watermark_prt}}}\n",
			             "                          \\fi\n";
			}
	}
    print TeXOut "                          }]{$pdffile}}%\n",
                 "              {%\n",
                 "%%%%%%%%%%%%%%%%\n";
    print TeXOut "\\title{\\uppercase{$santitle}}\n\n";
	if ($gen_atc) {
		print TeXATC "$santitle}\n\n",
					 "\\vspace*{\\baselineskip}\n\n",
					 "\\fontsize{12.0}{13.5}\\selectfont\\normalfont\n";
	}
    my $combauth = $auth_list_pdf_tex[$pg_idx];
    $combauth    =~ s/\]/\]\\\\/g;
    print TeXOut "\\author{$combauth}\n\n",
                 "\\maketitle\n\n",
                 "\\begin{abstract}\n";
	if ($gen_atc) {
		(my $combauth_nbsp = $combauth) =~ s/\. /\.~/g;
		print TeXATC "$combauth_nbsp\n\n",
					 "\\end{center}\n",
					 "\\noindent\\rule{\\textwidth}{1pt}\n";
	}
	#
    # temporary hacks till cleanup of convert_spec_chars2TeX
    #
    $abs_nyr = convert_spec_chars2TeX ($paper_abs[$pg_idx], "pap_abs-TeX");
    $abs_nyr = revert_from_context ($abs_nyr);
    if (defined $abs_nyr) {
        print TeXOut "$abs_nyr\n";
    }
    print TeXOut "\\end{abstract}\n\n",
                 "\\newpage\n\n",
                 "\\mbox{} \\vfill \\vfill\n",
                 "\\centering\n\n\\begin{spacing}{2.5}\n",
                 "\\textsf{\\textbf{\\Huge $paper_not_received_text}}\n",
                 "\\end{spacing}\n\n",
                 "\\vfill\n\n}\n",
                 "\\end{document}\n";
    close (TeXOut);
	my $pcode_lc = lc $paper_code[$pg_idx];
	if ($gen_atc) {
		#
		# inclusion for ATC parts of original PDF
		#
		print TeXATC "\\IfFileExists{$pdffile}{%\n",
					 "\\hspace*{-20mm}\\includegraphics[trim=0mm 180mm 19mm 0mm, clip]{$pdffile}\n\n",
					 "\\noindent\\uwave{\\rule{\\textwidth}{0pt}}}\n",
					 "              {%\n",
					 "%%%%%%%%%%%%%%%%\n",
					 "\\newpage\n\n",
					 "\\mbox{} \\vfill \\vfill\n",
					 "\\centering\n\n\\begin{spacing}{2.5}\n",
					 "\\textsf{\\textbf{\\Huge $paper_not_received_text}}\n",
					 "\\end{spacing}\n\n",
					 "\\vfill\n\n}\n",
					 "\\end{document}\n";
		close (TeXATC);
		if ($atc_print) {
			#
			# write batch file entry for TeX-file when it should be printed (not Red/Black/Assigned)
			#
			print BATATC "echo ---------------------------------------\n",
						 "echo generating \"$paper_code[$pg_idx].pdf\"\n",
						 "echo ---------------------------------------\n",
						 " pdflatex $pcode_lc.tex\n";
		}
	}
    #
    # ONLY if paper is publishable,
    #      it will get an entry into the BATCH file
    #
    my $is_publishable = $paper_pub[$pg_idx];
    if ($is_publishable) {
        print BAT    "echo ---------------------------------------\n",
                     "echo generating \"$paper_code[$pg_idx].pdf\"\n",
                     "echo ---------------------------------------\n",
                     " lualatex $pcode_lc.tex\n";
#thumb        if (-e $paper_directory.$pcode_lc.".tpt") {
#thumb        } else {
#thumb            print BAT " thumbpdf $pcode_lc.pdf\n",
#thumb                      " lualatex $pcode_lc.tex\n";
#thumb        }
#170619        print BAT  "$WL_Rem $WL_DelRM $pcode_lc.tex\n",
#170619                   "$WL_Rem $WL_DelRM $pcode_lc.log\n";	# fixed ";" 170619
# aux needed later " $WL_DelRM $pcode_lc.aux\n",
# out not produced " $WL_DelRM $pcode_lc.out\n";
#        print CAT    "echo ---------------------------------------\n",
#                     "echo adding \"$paper_code[$pg_idx].pdf\"\n",
#                     "echo ---------------------------------------\n",
#                     " lualatex $pcode_lc.tex\n";
    }
	Deb_call_strucOut ();
}
#-----------------------------
sub create_missing_tex_file {
  	Deb_call_strucIn ("create_missing_tex_file");

    (my $texfile = $raw_paper_directory."MISSING/".lc($paper_code[$pg_idx]).".tex") =~ s/\.\./\./ ;
    open (TeXMis, ">:encoding(UTF-8)", $texfile) or die ("Cannot open '$texfile' \n--are you using the correct script setup?-- $! (line ",__LINE__,")\n");
    print TeXMis $intromis;
    print TeXMis "\\input{jacowscript-jpsp}\n\n".
                 "%\\setlength\\titleblockheight{30mm}\n\n".
                 "\\begin{document}\n\n".
                 "\\title{\\uppercase{$santitle}}\n\n";

    my $combauth = $auth_list_pdf_tex[$pg_idx];
    $combauth    =~ s/\]/\]\\\\/g;
    print TeXMis "\\author{$combauth}\n\n",
                 "\\maketitle\n\n",
                 "\\begin{abstract}\n";
    #
    # temporary hacks till cleanup of convert_spec_chars2TeX
    #
    $abs_nyr = convert_spec_chars2TeX ($paper_abs[$pg_idx], "pap_abs-nyr");
    $abs_nyr = revert_from_context ($abs_nyr);
    print TeXMis "$abs_nyr\n";
    print TeXMis "\\end{abstract}\n\n",
                 "\\newpage\n\n",
                 "\\mbox{} \\vfill \\vfill \\vfill\n",
                 "\\centering\n\n\\begin{spacing}{2.5}\n",
                 "\\textsf{\\textbf{\\Huge $paper_not_received_text}}\n",
                 "\\end{spacing}\n\n",
                 "\\vfill\n\n",
                 "\\end{document}\n";
    close (TeXMis);
	Deb_call_strucOut ();
}
#-----------------------------
sub prepare_proctex_file {
  	Deb_call_strucIn ("prepare_proctex_file");

    my $file = "$paper_directory"."proceed.tex";
    open (TeXLGOut, ">", $file) or die ("Cannot open '$file' -- $! (line ",__LINE__,")\n");
#<	print TeXLGOut "\\pdfsuppresswarningpagegroup=1\n";
#<  print TeXLGOut $introbase;
	print TeXLGOut $introdoc8;
    print TeXLGOut "\\hypersetup{colorlinks=true, linktocpage=true,\n",
	               "             pdfpagemode=UseOutlines,%\n",
				   "             pdfpagelayout=SinglePage,%\n",
                   "             pdfstartview=Fit,\n",
                   "             pdftitle={$conference_name --- $conference_longname},\n",
                   "             pdfauthor={Volker RW Schaa [GSI, Darmstadt, Germany] },\n",
                   "             pdfsubject={$conference_name: The complete proceedings volume},\n",
                   "             pdfkeywords={JACoW, $conference_name, proceedings}%\n",
                   "            }\n\n";
    print TeXLGOut "\\usepackage{proceed-p1}\n\n",
                   "\\pagestyle{fancy}\n",
                   "\\thispagestyle{fancy}\n",
                   "\\usepackage{multicol}\n",
				   "\\usepackage{soul}\n",
                   "\\usepackage{pifont}\n",
                   "\\usepackage{url}\n\n",
                   "\\newcommand{\\Tel}{\\Pisymbol{dingbest}{83}}\n",
                   "\\newcommand{\\FaX}{\\Pisymbol{dingbest}{84}}\n\n",
#					"\\fancyhead[CE,CO]{$conference_name -- $conference_site_lat}\n",
#                   "\\fancyhead[LE,LO]{}\n",
#                   "\\fancyhead[RE,RO]{}\n",
#                   "\\fancyfoot[CE,CO]{}\n",
#                   "\\fancyfoot[RO,LE]{\\thepage}\n",
#                   "\\fancyfoot[RE,LO]{}\n\n",
                   "\\begin{document}\n\n",
                   "\\frontmatter\n",
                   "\\input{proceed-p2.tex}\n\n",
                   "\\input{jacowscript-jpsp}\n\n",
                   "\\thispagestyle{fancy}\n\n",
                   "\\mainmatter\n\n";
#<skip-papers>            "\\mainmatter\n\n\\iffalse\n\n";
    my $filep1 = "$paper_directory"."proceed1.tex";
    open (TeXP1Out, ">", $filep1) or die ("Cannot open '$filep1' -- $ (line ",__LINE__,")!\n");
    print TeXP1Out $introbase;
    print TeXP1Out 	"\\hypersetup{colorlinks=true, linktocpage=true,\n",
					"             pdfstartview=Fit,\n",
					"             pdftitle={$conference_name --- Proceedings at a Glance},\n",
					"             pdfauthor={Volker RW Schaa [GSI, Darmstadt, Germany] },\n",
					"             pdfsubject={First page only of all papers with hyperlinks to complete versions},\n",
					"             pdfkeywords={JACoW, $conference_name, proceedings}%\n",
					"            }\n\n";
    print TeXP1Out 	"\\begin{document}\n\n",
					"\\pagestyle{empty}\n",
					"\\thispagestyle{empty}\n",
					"\\renewcommand{\\headrulewidth}{0pt}\n\n",
					"\\let\\normalpdfximage\\pdfximage\\def\\pdfximage{\\immediate\\normalpdfximage}\n\n";
    print TeXP1Out 	"\\includepdfset{pages=1, noautoscale, offset=0pt 0pt, linktodoc}\n",
					"\\typeout{**************** page inclusion begins ********************}\n";
	Deb_call_strucOut ();
}
#-----------------------------
sub inclsession_in_proctex {
#070109    my $insert_page = ".$content_directory$session_abbr[$sess_idx].pdf";
#070109    print TeXLGOut "\\cleardoublepage\n\n",
#070109                   "\\refstepcounter{section}\n",
#070109                   "\\addcontentsline{toc}{section}{$session_name[$sess_idx]}\n\n",
#070109                   "\\IfFileExists{$insert_page}{\\thispagestyle{empty}%\n",
#070109                   "      \\includepdf[pagecommand={}]{$insert_page}\n\n",
#070109                   "      \\clearpage\n      \\thispagestyle{empty}%\n      \\mbox{}\n",
#070109                   "      \\clearpage}{}\n\n";
}
#-----------------------------
sub write_proctex_file {
  	Deb_call_strucIn ("write_proctex_file (".uc($paper_code[$pg_idx]).")");

    #--------------------
    # if no TeX/PDF file should be generated for missing papers,
    #    we have to check for a valid raw PDF file in $raw_paper_directory
    #    only for the one page version we go to the $paper_directory
    #
    my $pdffile = $raw_paper_directory.lc($paper_code[$pg_idx]).".pdf";    # raw version
    my $pdffnl  = $paper_directory.lc($paper_code[$pg_idx]).".pdf";        # final version with wrapper
#    my $pdffile    = "$pdffilenex.pdf";
    if (!$paper_not_received_link) {
        (my $chkpdffile = $pdffile) =~ s/\.\./\./;
        #
        if (-e "$chkpdffile") {
            # file exists
        } else {
			Deb_call_strucOut ();
            return;
        }
    }
    #---------------------
    # everything is fine...
    #
    if ($page_start[$pg_idx]) {
        print TeXLGOut "\\setcounter{page}{$page_start[$pg_idx]}   % $paper_code[$pg_idx]\n";
        print TeXP1Out "\\setcounter{page}{$page_start[$pg_idx]}   % $paper_code[$pg_idx]\n";
    }
#070302%    convert_spec_chars2TeX ($title[$pg_idx], "title-TeXLG");
    print TeXLGOut "\\refstepcounter{subsection}\n",
                   "\\addcontentsline{toc}{subsection}{$paper_code[$pg_idx] -- $santitle}\n",
                   "\\hypertarget{lab:$paper_code[$pg_idx]}{}\n\n";
#
# copy from above /SPMS header)
#    if (!$conference_type_indico) {
#        print TeXOut "\\fancyhead[LE,RO]{\\bfseries\\textcolor{$TeXhighlite}{$paper_code[$pg_idx]}}\n";
#    }

# (!!)
    if (!defined $clsMline || $clsMline eq "") { $clsMline = " "; }
    if (!defined $clsSline || $clsSline eq "") { $clsSline = " "; }
    #
    # printing header and footer
    #
    # copyright note needs to be positioned relative to the even page
    #   number (end) with a varying negative distance to compensate for
    #   current writing position
    #
    CopyrightOffset ($page_start[$pg_idx]);
#    print TeXLGOut "\\fancyhead[CE,CO]{\\bfseries\\textcolor{$TeXhighlite}{Proceedings of $conference_name, $conference_site_lat}}%\n",
#                   "\\fancyhead[LE,RO]{\\bfseries\\textcolor{$TeXhighlite}{$paper_code[$pg_idx]}}\n",
#                   "\\fancyhead[RE,LO]{}\n";

	print TeXLGOut "\\fancyhead[CE,CO]{\\small $conference_title_shrt\\hfill $conference_name, $conference_site_lat\\hfill $conference_pub_by\\\\".
										 "ISBN: \\texttt{$conference_isbn}\\hfill{$issn_str\\hfill}\\texttt{doi:10.18429/JACoW-$conference_name-$paper_code[$pg_idx]}}\n",
                   "\\fancyhead[RE,LO]{}\n",
                   "\\fancyhead[RO,LE]{}\n";
	#
	# ISBN string placement: footer is default  header selectable using "$conference_isbn_pos = 1"
	#
	my $texout_str;
	if ($conference_isbn_pos) {
		print TeXOut "$texout_str\n";
		$texout_str = "\\fancyfoot[LE]{{\\bfseries\\textcolor{$TeXhighlite}{$paper_code[$pg_idx]}\\\\[5pt]\\normalsize\\textcolor{$TeXhighlite}{\\thepage}}%\n".
					  "                    \\begin{picture}(0,0)\\put($cpx_pos_off,0){\\small%\n".
					  "                          \\rotatebox{90}{\\includegraphics[width=20pt]{$ccby_logo} $copyr_prepress}}%\n".
					  "                    \\end{picture}}\n";
		print TeXOut "$texout_str\n";
		$texout_str = "\\fancyfoot[RO]{{\\bfseries\\textcolor{$TeXhighlite}{$paper_code[$pg_idx]}\\\\[5pt]\\normalsize\\textcolor{$TeXhighlite}{\\thepage}}%\n".
					  "                    \\begin{picture}(0,0)\\put(5,0){\\small%\n".
					  "                          \\rotatebox{90}{\\includegraphics[width=20pt]{$ccby_logo} $copyr_prepress}}%\n".
					  "                    \\end{picture}}\n";
#		$texout_str = "\\fancyfoot[RO]{\\mbox{}\\\\[5pt]\\normalsize\\textcolor{$TeXhighlite}{\\thepage%\n".
#	                  "                    \\begin{picture}(0,0)\\put(5,0){\\textcolor[gray]{0.7}{%\n".
#					  "                          \\rotatebox{90}{$copyr_prepress}}}%\n".
#					  "                    \\end{picture}}}\n";
		print TeXLGOut "$texout_str\n";
		$texout_str = "\\fancyfoot[LE]{{\\bfseries\\textcolor{$TeXhighlite}{$paper_code[$pg_idx]}\\\\[5pt]\\normalsize\\textcolor{$TeXhighlite}{\\thepage}}%\n".
					  "                    \\begin{picture}(0,0)\\put($cpx_pos_off,0){\\small%\n".
					  "                          \\rotatebox{90}{\\includegraphics[width=20pt]{$ccby_logo} $copyr_prepress}}%\n".
					  "                    \\end{picture}}\n";
#		$texout_str = "\\fancyfoot[LE]{\\mbox{}\\\\[5pt]\\normalsize\\textcolor{$TeXhighlite}{\\thepage%\n".
#	                  "                    \\begin{picture}(0,0)\\put($cpx_pos_off,0){\\textcolor[gray]{0.7}{%\n".
#					  "                          \\rotatebox{90}{$copyr_prepress}}}%\n".
#					  "                    \\end{picture}}}\n";
		print TeXLGOut "$texout_str\n";
		print TeXLGOut "\\fancyhead[RE,LO]{\\bfseries\\textcolor{$TeXhighlite}{$isbn_str}}\n";
	} else {
		$texout_str = "\\fancyfoot[RO]{{\\bfseries\\textcolor{$TeXhighlite}{$paper_code[$pg_idx]}\\\\[5pt]\\normalsize\\textcolor{$TeXhighlite}{\\thepage}}%\n".
					  "                    \\begin{picture}(0,0)\\put(5,0){\\small%\n".
					  "                          \\rotatebox{90}{\\includegraphics[width=20pt]{$ccby_logo} $copyr_prepress}}%\n".
					  "                    \\end{picture}}\n";
		print TeXLGOut "$texout_str\n";
		$texout_str = "\\fancyfoot[LE]{{\\bfseries\\textcolor{$TeXhighlite}{$paper_code[$pg_idx]}\\\\[5pt]\\normalsize\\textcolor{$TeXhighlite}{\\thepage}}%\n".
					  "                    \\begin{picture}(0,0)\\put($cpx_pos_off,0){\\small%\n".
					  "                          \\rotatebox{90}{\\includegraphics[width=20pt]{$ccby_logo} $copyr_prepress}}%\n".
					  "                    \\end{picture}}\n";
		print TeXLGOut "$texout_str\n";
	}
    print TeXLGOut "\\fancyfoot[CE,CO]{}\n";
    if ($clsSline eq "" || $clsSline eq " " || $clsSline eq "\\mbox{ }") {
        print TeXLGOut "\\fancyfoot[LO,RE]{\\bfseries\\mbox{ }\\\\[5pt]\\textcolor{$TeXhighlite}{$clsMline}}\n";
    } else {
        print TeXLGOut "\\fancyfoot[LO,RE]{\\bfseries\\textcolor{$TeXhighlite}{$clsMline}\\\\[5pt]\\textcolor{$TeXhighlite}{$clsSline}}\n";
    }
    print TeXLGOut "\\IfFileExists{$pdffile}{%\n",
                   "\\includepdf[pagecommand={}\n",
                   "           ]{$pdffile}}%\n";
    print TeXLGOut "{\\mbox{}\\vfill\n",
                   "\\centering\\textsf{\\Huge $paper_not_received_text}\n",
                   "\\vfill}\n\n\\clearpage\n\n";
    print TeXP1Out "\\IfFileExists{.$pdffnl}{%\n",
                   "\\includepdf{.$pdffnl}}%\n",
                   "{\\typeout{**************** file not found: $pdffile}}\n\n\\clearpage\n\n";
	Deb_call_strucOut ();
}
#-----------------------------
sub finish_proctex_file {
  	Deb_call_strucIn ("finish_proctex_file");

    my $insert_page = ".".$content_directory."AP.pdf";
    print TeXLGOut "\n\\cleardoublepage\n\n",
#<skip-papers>            "\\fi\n\n\\refstepcounter{section}\n\\addcontentsline{toc}{section}{Appendices}\n\n",
                   "\\refstepcounter{section}\n\\addcontentsline{toc}{section}{Appendices}\n\n",
                   "\\IfFileExists{$insert_page}{\\thispagestyle{empty}%\n",
                   "      \\fancyfoot[RE,LO]{}\\fancyfoot[CE,CO]{}%\n",
                   "      \\includepdf[pagecommand={}]{$insert_page}\n\n",
                   "      \\cleardoublepage}{}\n\n";
#
# read external file for authors
#
#~~	CopyrightOffset ();    # use last page count
	print TeXLGOut 	"\\fancyhead[CE,CO]{\\small $conference_title_shrt\\hfill $conference_name, $conference_site_lat\\hfill $conference_pub_by\\\\".
#‰									 "ISBN: \\texttt{$conference_isbn}{\\hfill}{$issn_str}}\n",
									 "ISBN: \\texttt{$conference_isbn}\\hfill{$issn_str}}\n",
					"\\fancyhead[RO,LE]{}%\n";
	print TeXLGOut 	"\\fancyfoot[RE,LO]{\\mbox{}\\\\[-10pt]\\bfseries\\mbox{ }\\\\[5pt]List of Authors}\n",
					"\\fancyfoot[RO]{{\\mbox{}\\\\[5pt]\\mbox{}\\normalsize\\bfseries\\textcolor{$TeXhighlite}{\\thepage}}%\n",
					"                    \\begin{picture}(0,0)\\put(5,0){\\small%\n",
					"                          \\rotatebox{90}{\\includegraphics[width=20pt]{$ccby_logo} $copyr_prepress}}%\n",
					"                    \\end{picture}}\n",
					"\\fancyfoot[LE]{{\\mbox{}\\\\[5pt]\\bfseries\\textcolor{$TeXhighlite}{\\thepage}}%\n",
					"                    \\begin{picture}(0,0)\\put($cpx_pos_off,0){\\small%\n",
					"                          \\rotatebox{90}{\\includegraphics[width=20pt]{$ccby_logo} $copyr_prepress}}%\n",
					"                    \\end{picture}}\n",
					"\\fancyfoot[CE,CO]{}\n\n";
    print TeXLGOut "\\subsection*{\\Large List of Authors}\n",
                   "\\refstepcounter{subsection}\n\\addcontentsline{toc}{subsection}{List of Authors}\n",
                   "\n\n\\begin{flushleft}\n",
#                   "\\textit{Italic} papercodes indicate primary authors\n\n",
                   "\\textbf{Bold} papercodes indicate primary authors; \\st{crossed out} papercodes indicate `no submission'\n\n",
                   " \\begin{multicols}{2}\n";    # "    %\\fboxsep8pt\n";
    #
    # read "Authors List" from TeX file
    #
    my $texi = $content_directory."authtexidx.tex";
    print TeXLGOut "      \\input{.".$texi."}\n",
                   " \\end{multicols}\n",
                   "\\end{flushleft}\n\n",
                   "\\cleardoublepage\n\n";
#
# read external file for institutes
#
#~~	CopyrightOffset ();    # use last page count
	print TeXLGOut 	"\\fancyhead[CE,CO]{\\small $conference_title_shrt\\hfill $conference_name, $conference_site_lat\\hfill $conference_pub_by\\\\".
									 "ISBN: \\texttt{$conference_isbn}\\hfill{$issn_str}\\hfill}\n",
					"\\fancyhead[RO,LE]{}%\n";
    print TeXLGOut "\\fancyfoot[RE,LO]{\\mbox{}\\\\[-10pt]\\bfseries\\mbox{ }\\\\[5pt]Institutes List}\n",
					"\\fancyfoot[RO]{{\\mbox{}\\\\[5pt]\\mbox{}\\normalsize\\bfseries\\textcolor{$TeXhighlite}{\\thepage}}%\n",
					"                    \\begin{picture}(0,0)\\put(5,0){\\small%\n",
					"                          \\rotatebox{90}{\\includegraphics[width=20pt]{$ccby_logo} $copyr_prepress}}%\n",
					"                    \\end{picture}}\n",
					"\\fancyfoot[LE]{{\\mbox{}\\\\[5pt]\\bfseries\\textcolor{$TeXhighlite}{\\thepage}}%\n",
					"                    \\begin{picture}(0,0)\\put($cpx_pos_off,0){\\small%\n",
					"                          \\rotatebox{90}{\\includegraphics[width=20pt]{$ccby_logo} $copyr_prepress}}%\n",
					"                    \\end{picture}}\n",
					"\\fancyfoot[CE,CO]{}\n\n";
    print TeXLGOut "\\clearpage\n\n",
                   "\\newcommand\\IDot[2]{{\\hspace*{3mm}\\quad\\textbullet\\ \\hyperlink{lab:#1}{#2}}\\newline}\n\n",
                   "\\subsection*{\\Large Institutes List}\n",
                   "\\refstepcounter{subsection}\n",
                   "\\addcontentsline{toc}{subsection}{ Institutes List}\n",
                   "\n\n\\begin{flushleft}\n",
                   " \\begin{multicols*}{2}\n",
                   "    \\small\n";
    #
    # read "Institutes List" from TeX file
    #
    $texi = $content_directory."instidx.tex";
    print TeXLGOut "     \\input{.".$texi."}\n",
                   " \\end{multicols*}\n",
                   "\\end{flushleft}\n\n",
#                   "\\cleardoublepage\n\n";
                   "\\clearpage\n\n";
#
# prepare link for external file for participants
#
#~~	CopyrightOffset ();    # use last page count
	print TeXLGOut 	"\\fancyhead[CE,CO]{\\small $conference_title_shrt\\hfill $conference_name, $conference_site_lat\\hfill $conference_pub_by\\\\".
									 "ISBN: \\texttt{$conference_isbn}\\hfill{$issn_str}\\hfill}\n",
					"\\fancyhead[RO,LE]{}%\n";
    print TeXLGOut "\\fancyfoot[RE,LO]{\\mbox{}\\\\[-10pt]\\bfseries\\mbox{ }\\\\[5pt]Participants List}\n",
					"\\fancyfoot[RO]{{\\mbox{}\\\\[5pt]\\mbox{}\\normalsize\\bfseries\\textcolor{$TeXhighlite}{\\thepage}}%\n",
					"                    \\begin{picture}(0,0)\\put(5,0){\\small%\n",
					"                          \\rotatebox{90}{\\includegraphics[width=20pt]{$ccby_logo} $copyr_prepress}}%\n",
					"                    \\end{picture}}\n",
					"\\fancyfoot[LE]{{\\mbox{}\\\\[5pt]\\bfseries\\textcolor{$TeXhighlite}{\\thepage}}%\n",
					"                    \\begin{picture}(0,0)\\put($cpx_pos_off,0){\\small%\n",
					"                          \\rotatebox{90}{\\includegraphics[width=20pt]{$ccby_logo} $copyr_prepress}}%\n",
					"                    \\end{picture}}\n",
					"\\fancyfoot[CE,CO]{}\n\n";
    print TeXLGOut "\\clearpage\n\n",
                   "\\subsection*{\\Large Participants List}\n",
                   "\\refstepcounter{subsection}\n",
                   "\\addcontentsline{toc}{subsection}{ Participants List}\n",
                   "\n\n\\begin{flushleft}\n",
                   " \\begin{multicols*}{3}\n",
                   "    \\small\n",
                   "    %\\raggedcolumns\n";
    #
    # read "Participants List" from TeX file
    #
    $texi = $content_directory."participants.tex";
    print TeXLGOut "     \\input{.".$texi."}\n",
                   " \\end{multicols*}\n",
                   "\\end{flushleft}\n\n",
                   "\\cleardoublepage\n\n";
#
# read external file for vendors
#
    my $vendor_pck = $content_directory."Vendors.pdf";
    if (-e $vendor_pck) {
#~~	CopyrightOffset ();    # use last page count
        print TeXLGOut "\\IfFileExists{$vendor_pck}{%\n",
                       "\\fancyfoot[LO,RE]{\\bfseries\\mbox{ }\\\\[5pt]Vendors List}\n",
					   "\\fancyfoot[RO]{\\bfseries\\textcolor{$TeXhighlite}{$isbn_str}\\\\[5pt]\\normalsize\\textcolor{$TeXhighlite}{\\thepage%\n",
					   "                    \\begin{picture}(0,0)\\put(5,0){\\textcolor[gray]{0.7}{%\n",
					   "                          \\rotatebox{90}{$conference_pub_copyr}}}%\n",
					   "                    \\end{picture}}}\n",
					   "\\fancyfoot[LE]{\\bfseries\\textcolor{$TeXhighlite}{$isbn_str}\\\\[5pt]\\normalsize\\textcolor{$TeXhighlite}{\\thepage%\n",
					   "                    \\begin{picture}(0,0)\\put($cpx_pos_off,0){\\textcolor[gray]{0.7}{%\n",
					   "                          \\rotatebox{90}{$conference_pub_copyr}}}%\n",
					   "                    \\end{picture}}}\n";
		print TeXLGOut "%\\subsection*{\\Large Vendors List}\n",
                       "\\refstepcounter{subsection}\n\\addcontentsline{toc}{subsection}{ Vendors List}\n",
                       "\\includepdf[pagecommand={}]{$vendor_pck}}\n\n\\clearpage\n\n";
    } else {
        print DBG " no Exhibitor/Vendor information file \"$vendor_pck\"\n";
    }
    $vendor_pck = $content_directory."Vendors-src.tex";
    if (-e $vendor_pck) {
        open (TEXI, "<", $vendor_pck) or die ("Cannot open '$vendor_pck' -- $! (line ",__LINE__,")\n");
        while (<TEXI>) {
            print TeXLGOut " $_";
        }
        close (TEXI);
    } else {
        print DBG " no Exhibitor/Vendor information file \"$vendor_pck\"\n";
    }
#
# read external file for production notes
#
    $texi = $content_directory."production_notes.tex";
    open (TEXI, "<", $texi) or die ("Cannot open '$texi' -- $! (line ",__LINE__,")\n");
    while (<TEXI>) {
        print TeXLGOut " $_";
    }
    close (TEXI);
    print TeXLGOut "\n\\end{document}\n";
    close (TeXLGOut);
    print TeXP1Out "\\end{document}\n";
    close (TeXP1Out);
	Deb_call_strucOut ();
}
#-----------------------------
sub finish_procbat_file {
  	Deb_call_strucIn ("finish_procbat_file");

    print BAT "echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n",
              "echo generating \"Proceedings Volume\"\n",
              "echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n",
              " pdflatex proceed\n",
              " pdflatex proceed\n",
              " pdflatex proceed\n",
              "echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n",
              "echo generating \"Page 1 Volume\"\n",
              "echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n",
#              " pdflatex proceed1\n",
#              " pdflatex proceed1\n",
              " pdflatex proceed1\n";
	Deb_call_strucOut ();
}
#-----------------------
sub sort_institutes {
  	Deb_call_strucIn ("sort_institutes");
#
# base html file for author list
#
 my $institutefile   = $html_directory."inst.htm";
 print DBG "== List of Institutes\n";
 open (IHTM, ">:encoding(UTF-8)", $institutefile) or die ("Cannot open '$institutefile' -- $! (line ",__LINE__,")\n");
 print IHTM  $html_content_type."\n",
             "<html lang=\"en\">\n",
             "<head>\n",
             "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#			 "  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
             "  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
             "  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
             "  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
             "  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
             "  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
             "  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
             "  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
             "  <title>$conference_name - List of Institutes</title>\n",
             "</head>\n\n",
             "<frameset rows=\"",$banner_height,"px, *\">\n",
             "  <frame src=\"b0nner.htm\" name=\"b0nner\" frameborder=\"1\" />\n",
             "  <frameset cols=\"20%,*\">\n",
             "    <frame src=\"inst1.htm\" name=\"left\"  frameborder=\"1\" />\n",
             "    <frame src=\"inst2.htm\" name=\"right\" frameborder=\"1\" />\n",
             "  </frameset>\n",
             "  <noframes>\n",
             "    <body class=\"debug\">\n",
             "    <p>This page uses frames, but your browser doesn't support them.</p>\n",
             "    </body>\n",
             "  </noframes>\n",
             "</frameset>\n",
             "</html>\n";
 close (IHTM);
 $inst2file   = $html_directory."inst2.htm";
 open (IHTM, ">:encoding(UTF-8)", $inst2file) or die ("Cannot open '$inst2file' -- $! (line ",__LINE__,")\n");
 print IHTM  $html_content_type."\n",
             "<html lang=\"en\">\n",
             "<head>\n",
             "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#			 "  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
             "  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
             "  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
             "  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
             "  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
             "  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
             "  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
             "  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
             "  <title>$conference_name - List of Institutes</title>\n",
             "</head>\n\n",
             "<body>\n",                 # bgcolor=\"\#ffffff\">\n",
             "<br />\n",
             "<span class=\"list-item\">Click on an institute to display a list of authors.</span>\n",
             "</body>\n",
             "</html>\n";
 close (IHTM);
 @sorted_institutes = sort {uc($a) cmp uc($b)} @inst_author;
 #
 # Debug print into debug-author file
 #
 open (DEBAUTH, ">>:encoding(UTF-8)", $debauthfile) or die ("Cannot open '$debauthfile' -- $! (line ",__LINE__,")\n");
 my $div_line = "-------+-----------------------------------------+-----------------------------------------+----------------+----------------------------------------------------+------+";
 my $lst_ins = "";
 my $inst_ak = -1;
 for ($i=0; $i<=$inst_author_nr; $i++) {
	($act_abr, $act_auth, $auth8, $act_inst, $act_aid, $pap_num) = split (/∞/, $sorted_institutes[$i]);
	$act_abr =~ s/\s+$//;	# trim string extension for sorting
#	print DBG sprintf (" s_i:%5i |%s\n", $i, $sorted_institutes[$i]);
	if ($act_abr ne $lst_ins) { $inst_ak++; print DEBAUTH sprintf ("%s  %4i\n", $div_line, $inst_ak); $lst_ins = $act_abr;}
    print DEBAUTH sprintf (" %5i | %-40s| %-40s| %14s | %-50s | %4i |\n",
	                         $i,
                                   substr($act_abr, 0, 40),
                                          substr($auth8, 0, 40),
												 $act_aid,
														substr($act_inst, 0, 50),
																$pap_num);
 }
 print DEBAUTH $div_line."\n\n\n";
 close (DEBAUTH);
 #
 # Institute's index file
 #
 my $instfile   = $html_directory."inst1.htm";
 open (IHTM, ">:encoding(UTF-8)", $instfile) or die ("Cannot open '$instfile' -- $! (line ",__LINE__,")\n");
 print IHTM  $html_content_type."\n",
             "<html lang=\"en\">\n",
             "<head>\n",
             "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#			 "  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
             "  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
             "  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
             "  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
             "  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
             "  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
             "  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
             "  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
             "  <title>$conference_name - List of Institutes</title>\n",
             "</head>\n\n",
             "<body class=\"debug\">\n",
             "<p class=\"list-title\">List of Institutes<p/>\n";
 #
 my $last_auth = "";
 my $last_aid  = 0;		# compare with JACoW Id
 use vars qw ($inst_ptr $inst_file_open $last_inst);
 $inst_ptr  		= 0;
 $inst_file_open 	= 0;
 $last_inst 		= "";	# compare with actual institute
 #
 # loop over 
 #
 for ($i=0; $i<=$inst_author_nr; $i++) {
	($act_abr, $act_auth, $auth8, $act_inst, $act_aid, $pap_num) = split (/∞/, $sorted_institutes[$i]);
	$act_abr =~ s/\s+$//;	# trim string extension for sorting
    print DBG sprintf (" >%4i. Institut : %-40s # %-50s # %s-%s # %s\n", $inst_ptr, $act_inst, $act_abr, $act_auth, $auth8, $act_aid);
	#
	# same institute again?
	#
    if ($act_abr eq $last_inst) {
		#
		# YES => Old institute again, new author...
		#
        print DBG sprintf (" >      Institut : %s\n", $act_abr);
    } else {
		#
		# NO => new institute, so close last institute first
		#
		if ($inst_file_open) { 
			close_institute_htmlfile ();
			$inst_file_open = 0;
        }
		#
		# new Institute, but same Author as from last institute?
		#
		if ($act_aid eq $last_aid) {
			#
			# YES => skip author (open new institute file only when author 
			#	                  hadn't been in the last one already)
			#
			print     ">> prevent opening >> $inst2file --for same author -$auth8-\n";
			print DBG ">> prevent opening >> $inst2file --for same author -$auth8-\n";
		} else {
			#
			# NO => new author -> open new institute file
			#
			$inst2file = sprintf ("inst%04i.htm", $inst_ptr);
			$inst_ptr++;
			#
			# special InDiCo case: Abbreviation == Institute's name
			#
			if ($act_abr eq $act_inst) {
				$abbinsthtml = convert_spec_chars ($act_abr, "act_abr");
			} else {
				$abbinsthtml = convert_spec_chars ("$act_abr<br />$act_inst", "act_abr-inst");
			}
			print IHTM "<p><a class=\"inst-item\" href=\"$inst2file\" target=\"right\">$abbinsthtml</a></p>\n";
			generate_institute_htmlfile ();
		}
    }
	#
	# new author?
	#
    if ($act_aid ne $last_aid) {
        print DBG sprintf (" >      Auth :     %-20s-%-20s * %-20s\n", $act_auth, $auth8, $last_auth);
        $last_aid = $act_aid;
        add_institute_entry ();
    }
    $last_inst = $act_abr;
}
$num_of_institutes = $inst_ptr;
#
# for last institute which does not pass through the loop
# 
 if ($inst_file_open) {
	 close_institute_htmlfile ();
	 print IHTM "</body>\n\n",
				"</html>\n";
	 close (IHTM);
 }
#
# Generate Institutes list for LaTeX
#
 my @auth;
 $last_inst = "";
 $last_auth = "";
 my	$jj = -1;
 my $i1;
 my $lbl;
 my $inst_file = $content_directory."instidx.tex";
# open (ITEX, ">", $inst_file) or warn ("Cannot open '$inst_file' -- $! (line ",__LINE__,")\n");
 open (ITEX, ">:encoding(UTF-8)", $inst_file) or warn ("Cannot open '$inst_file' -- $! (line ",__LINE__,")\n");
 for ($i=0; $i<=$inst_author_nr; $i++) {
#     print "****> $i --> $sorted_institutes[$i]\n";
    ($act_abr, $act_auth, $auth8, $act_inst, $act_aid) = split (/∞/, $sorted_institutes[$i]);
	$act_abr =~ s/\s+$//;	# trim string extension for sorting
    if ($act_abr eq $last_inst) {
         if ($auth8 ne $last_auth) {
             $jj++;
             $last_auth	= $auth8;
             $auth[$jj]	= $auth8;
             $aaid[$jj]	= $act_aid;
             print DBG "*==> '$act_abr', '$jj', '$auth[$jj]--[$aaid[$jj]]'\n";
         }
     } else {
         $last_inst = $act_abr;
         if ($jj >= 0) {
             print DBG " $jj *******************************************\n";
             for ($i1=0; $i1<=$jj; $i1++) {
                 print DBG "<$i1> orig:$auth[$i1] ";
                 convert_spec_chars2TeX ($auth[$i1], "auth-ITEX");
#                print DBG " c2t:$_ ";
                 revert_from_context ($_);
#                print DBG " rfc:$_ \n";
                 #
                 # ger rid of special chars in labels
                 #
                 $lbl = $_;
                 $lbl =~ s/[.,\x00-\x40\x5b-\x60\x7b-\xff]/_/g;  # only 0-9,A-Z,a-z, all other converted to "_"
                 $lbl =~ s/[\x{0100}-\x{059f}]/-/g;              # all above 0x0100 to 0x059f (Cyrillic) converted to "-"
				 $lbl .= $aaid[$i1];
                 print ITEX "    \\IDot{$lbl}{$_}\n";
             }
             print ITEX "\\vspace*{-\\baselineskip}\n\\end{trivlist}\n\n";
         }
         $jj = 0;
#<8>     $auth[$jj]  = $act_auth;
         $auth[$jj]  = $auth8;
		 $aaid[$jj]  = $act_aid;
#<8>     $last_auth = $act_auth;
         $last_auth = $auth8;
         print DBG "*==> '$act_abr', '$jj', '$auth[$jj]'\n";
         my $act_tp = convert_spec_chars2TeX ($act_abr, "act_tp-ITEX");
         $act_tp    = revert_from_context ($act_tp);
         print ITEX "\\begin{trivlist}\n",
                    "    \\item[]\n",
                    "    \\textsf{\\textbf{$act_tp}}\\newline\n";
         if ($act_inst ne "") {
             $act_tp = convert_spec_chars2TeX ($act_inst, "act_inst");
             $act_tp = revert_from_context ($act_tp);
             print ITEX "    \\qquad{$act_tp}\\newline\n";
          }
     }
 }
 for ($i1=0; $i1<=$jj; $i1++) {
     convert_spec_chars2TeX ($auth[$i1], "auth2-ITEX");
     revert_from_context ($_);
     #
     # get rid of special chars in labels
     #
     $lbl = $_;
     $lbl =~ s/[.,\x00-\x40\x5b-\x60\x7b-\xff]/_/g;  # only 0-9,A-Z,a-z, all other converted to "_"
     $lbl =~ s/[\x{0100}-\x{059f}]/-/g;              # all above 0x0100 to 0x059f (Cyrillic) converted to "-"
	 $lbl .= $aaid[$i1];
     print ITEX "    \\IDot{$lbl}{$_}\n";
 }
 print ITEX "\\vspace*{-\\baselineskip}\n\\end{trivlist}\n\n";
 close (ITEX);
 Deb_call_strucOut ();
}
#-----------------------
sub generate_institute_htmlfile {

  	Deb_call_strucIn ("generate_institute_htmlfile ($abbinsthtml)");

	open (I2HTM, ">:encoding(UTF-8)", $html_directory.$inst2file) or die ("Cannot open '$inst2file' -- $! (line ",__LINE__,")\n");
	print DBG "## opening ## $inst2file ---  $act_abr ($act_inst) --- $act_auth\n";
	$inst_file_open = 1;

  convert_spec_chars ("$act_abr<br />$act_inst", "act_abr-inst-geninst");
  my $inst_header = convert_spec_chars ("$act_abr ($act_inst)", "inst_header");

  print I2HTM  $html_content_type."\n",
			   "<html lang=\"en\">\n",
			   "<head>\n",
			   "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#			   "  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
			   "  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
			   "  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
			   "  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
			   "  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
			   "  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
			   "  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
			   "  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
			   "  <title>$conference_name - List of Institutes: $inst_header</title>\n",
			   "</head>\n\n",
			   "<body>\n",                 # bgcolor=\"\#ffffff\">\n",
#               "<br />\n",
			   "<span class=\"sessionheader\">$abbinsthtml</span>\n",
			   "<table  class=\"tabledef\">\n",
#               "<tbody>\n",
			   "    <tr class=\"tablerow\">\n",
			   "        <th class=\"authinst\">Author</th>\n",
			   "    </tr>\n";
	Deb_call_strucOut ();
}
#-----------------------
sub add_institute_entry {
 	Deb_call_strucIn ("add_institute_entry");

	my $i1;
	for ($i1=1; $i1<=$author_max_nr; $i1++) {
		$authname = $sorted_authors[$i1];
		if ($act_auth eq $authname && $act_aid eq $sorted_auth_id[$i1]) {
			print DBG "!!!!!>> [$i1] Act:$act_auth <=> Auth:$authname (id:$act_aid)\n";
			last; 
		}
	}
	my $link = sprintf ("auth%04i.htm", $i1);
	print DBG sprintf ("+++ (%s) %4i. Author: >%-s<--->%-s<\n", $act_auth, $i1, $authname, $link);
	convert_spec_chars ($auth8, "auth8-I2");
	print I2HTM "    <tr class=\"tablerow\">\n",
				"        <td><a class=\"auth-item\" href=\"$link\">$_</a>\n",
				"        </td>\n",
				"    </tr>\n",
    Deb_call_strucOut ();
}
#-----------------------
sub close_institute_htmlfile {
 	Deb_call_strucIn ("close_institute_htmlfile");

	print I2HTM	"</table>\n",
				"</body>\n\n",
				"</html>\n";
	close (I2HTM);
    Deb_call_strucOut ();
}
#-----------------------
sub check_pdffile_scale {
 	Deb_call_strucIn ("check_pdffile_scale");

 #
 # if a pdf file exists, scan it for the entries
 #   /MediaBox [ lx ly ox uy ]
 #   with (at least) Acrobat 7.0 this has changed to
 #   /MediaBox [lx ly ox uy]
 # and
 #   /CropBox [ lx ly ox uy ]
 #   with (at least) Acrobat 7.0 this has changed to
 #   /CropBox [lx ly ox uy]
 #    whereas lx...uy can be floating point now.
 #
 # to determine the scaling factor for TeXs final run
 #
 my $pdffiletext;
 use vars qw ($uryc $urym $llx $lly $urx $ury);
 my $file = substr (shift(@_), 1);
 print DBG "pdf File: $file\n";
 {
    local undef $/;
    if (open (PDF, "<", $file)) {
        print DBG "pdf file opened\n";
    } else {
        print DBG "pdf Cannot open '$file' -- $! (line ",__LINE__,")\n";
		Deb_call_strucOut ();
        return $uryc = -1;
    }
    binmode (PDF);
    $pdffiletext = <PDF>;
    print DBG "pdf ---> L‰nge: ".length($pdffiletext)."\n";
    close (PDF);
    Deb_call_strucOut ();
 }
 $pdffiletext =~ s/stream.+?endstream/--/msg;
 print DBG "pdf strl L‰nge: ".length($pdffiletext)."\n";
 if ($pdffiletext =~ m|\/MediaBox\[(.*?)\]|msxg) {
     ($llx, $lly, $urx, $ury) = split (/ /, $1);
     print DBG "pdf MEDIA: $1\n";
     $urym = $ury;
 }
 if ($pdffiletext =~ m|\/CropBox\[(.*?)\]|msxg) {
     ($llx, $lly, $urx, $ury) = split (/ /, $1);
     print DBG "pdf CROP : $1\n";
     $uryc = $ury;
 }
 Deb_call_strucOut ();
 return $uryc;
}
##############################################
#
# convert_spec_chars    <√±|
#
##############################################
# c_s_c
#
#    convert all non-displayable characters by their
#    html equivalents or Unicode representation
#    Arguments [0] string to be converted
#              [1] identification string from where the procedure was called
#    returns   [0] modified $_
#
sub convert_spec_chars {

    $_    = $_[0];   # was @_[0]
 my $wohe = $_[1];
    if ($_ eq "") {
        print DBG " --> ($wohe) ^empty string ($paper_code[$pap])\n";
        return;
    }
	my $in_string = $_;
 	Deb_call_strucIn ("convert_spec_chars     ($_)");

    print DBG ">c_s_c ($wohe)> $_\n" unless $debug_restricted; 
#
# in Matt's XML "&#" seem to be converted to "&amp;#"
#
    s|&amp;#|&#|g;
    s|&amp;([a-z]{2,};)|&$1|g;
#
# one byte codes (Windows-1252) into utf-8
#
    s|\xb4|\x92|g;              #<¥|†>        ++*

#+    s|\x80|\x..\x..\x..|g;       #
#+
#+   0x80                          eURO sign                               128     U+20AC  &#8364; "‚Ç¨"  &euro;    e2, 82, ac
#+   0x82  baseline single quote   single low-9 quotation mark             130     U+201A  &#8218; "‚Äö"  &sbquo;   e2, 80, 9a
#+   0x83  florin                  Latin small letter f with hook          131     U+0192  &#402;  "∆'"   &fnof;    c6, 92
#+   0x84  baseline double quote   double low-9 quotation mark             132     U+201E  &#8222; "‚Äû"  &bdquo;   e2, 80, 9e
#+   0x85  ellipsis                horizontal ellipsis                     133     U+2026  &#8230; "‚Ä¶"  &hellip;  e2, 80, a6
#+   0x86  dagger                  dagger                                  134     U+2020  &#8224; "‚Ä†"  &dagger;  e2, 80, a0
#+   0x87  double dagger           double dagger                           135     U+2021  &#8225; "‚Ä°"  &Dagger;  e2, 80, a1
#+   0x88  circumflex accent       modifier letter circumflex accent       136     U+02C6  &#710;  "ÀÜ"   &circ;    cb, 86
#+   0x89  permile                 per mille sign                          137     U+2030  &#8240; "‚Ä∞"  &permil;  e2, 80, b0
#+   0x8a  S Hacek                 Latin capital letter S with caron       138     U+0160  &#352;  "≈†"   &Scaron;  c5, a0
#+   0x8b  left single guillemet   single left-pointing angle quot. m.     139     U+2039  &#8249; "‚Äπ"  &lsaquo;  e2, 80, b9
#+   0x8c  OE ligature             Latin capital ligature OE               140     U+0152  &#338;  "≈'"   &OElig;   c5, 92
#+   0x8e                          LATIN CAPITAL LETTER Z WITH CARON       142     U+017D  &#381;  "≈Ω"             c5, bd
#+   0x91  left single quote       left single quotation mark              145     U+2018  &#8216; "‚Äò"   &lsquo;   e2, 80, 98
#+   0x92  right single quote      right single quotation mark             146     U+2019  &#8217; "‚Äô"  &rsquo;   e2, 80, 99
#+   0x93  left double quote       left double quotation mark              147     U+201C  &#8220; "‚Äú"  &ldquo;   e2, 80, 9c
#+   0x94  right double quote      right double quotation mark             148     U+201D  &#8221; "‚Äù"   &rdquo;   e2, 80, 9d
#+   0x95  bullet                  bullet                                  149     U+2022  &#8226; "‚Ä¢"  &bull;    e2, 80, a2
#+   0x96  endash                  en dash                                 150     U+2013  &#8211; "‚Äì"  &ndash;   e2, 80, 93
#+   0x97  emdash                  em dash                                 151     U+2014  &#8212; "‚Äî"  &mdash;   e2, 80, 94
#+   0x98  tilde accent            small tilde                             152     U+02DC  &#732;  "Àú"   &tilde;   cb, 9c
#+   0x99  trademark ligature      trade mark sign                         153     U+2122  &#8482; "‚Ñ¢"  &trade;   e2, 84, a2
#+   0x9a  s Hacek                 Latin small letter S with caron         154     U+0161  &#353;  "≈°"   &scaron;  c5, a1
#+   0x9b  right single guillemet  single right-pointing angle quot. m.    155     U+203A  &#8250; "‚Ä∫"  &rsaquo;  e2, 80, ba
#+   0x9c  oe ligature             Latin small ligature oe                 156     U+0153  &#339;  "≈ì"   &oelig;   c5, 93
#+   0x9e                          LATIN SMALL LETTER Z WITH CARON         158     U+017E  &#382;  "≈æ"             c5, be	
#+   0x9f  Y Dieresis              Latin capital letter Y with diaeresis   159     U+0178  &#376;  "≈∏"   &Yuml;    c5, b8
#+

#
# xa1...bf -> xc2.a1...bf
# xc0...ff -> xc3.80...bf
#
    s|\xc2\x96|--|g;         #<¬?|ñ>
    s|\xc2\xa0| |g;          #<¬†|†>
    s|\xc2\xa1|\xa1|g;             #<test> ° Inverted Exclamation Mark
    s|\xc2\xa2|\xa2|g;             #<test> ¢ Cent Sign
    s|\xc2\xa3|\xa3|g;             #<test> £ Pound Sign
    s|\xc2\xa4|\xa4|g;             #<test> ° Inverted Exclamation Mark
    s|\xc2\xa5|\xa5|g;             #<test> • Yen Sign
    s|\xc2\xa6|\xa6|g;             #<test> ¶ Broken Bar
    s|\xc2\xa7|\xa7|g;             #<test> ß Section Sign
    s|\xc2\xa8|\xa8|g;             #<test> ® Diaeresis
    s|\xc2\xa9|\xa9|g;             #<¬©|©> © Copyright Sign
    s|\xc2\xaa|\xaa|g;             #<test> ™ Feminine Ordinal Indicator
    s|\xc2\xab|\xab|g;             #<test> ´ Left-Pointing Double Angle Quotation Mark
    s|\xc2\xac|\xac|g;             #<¬¨|¨> ¨ Not Sign
    s|\xc2\xad|\xad|g;             #<test>   Soft Hyphen
    s|\xc2\xae|\xae|g;             #<¬Æ|Æ> Æ Registered Sign
    s|\xc2\xaf|\xaf|g;             #<test> Ø Macron
#
    s|\xc2\xb0|\xb0|g;             #<¬∞|∞> ∞ Degree Sign
    s|\xc2\xb1|\xb1|g;             #<¬±|±> ± Plus minus symbol
    s|\xc2\xb2|\xb2|g;             #<test> ≤ Superscript Two  # introduced 2016-08-22
    s|\xc2\xb3|\xb3|g;             #<test> ≥ Superscript Three
#   s|\xc2\xb3|\\ge|g;       #<¬≥|>= > --> \ge
    s|\xc2\xb4|\xb4|g;             #<test> ¥ Acute Accent     # introduced 2016-08-22
    s|\xc2\xb5|\xb5|g;             #<¬µ|µ> µ Micro Sign
    s|\xc2\xb6|\xb6|g;             #<test> ∂ Pilcrow Sign
#   s|\xc2\xb7|\x95|g;       #<¬∑|∑>  => \cdot (instead of 'b7' used '95'  # before 2016-03-06
    s|\xc2\xb7|\xb7|g;             #<¬∑|∑> ∑ Middle Dot		  # reintroduced 2016-08-22
    s|\xc2\xb8|\xb8|g;             #<¬∏|∏> ∏ Cedilla
    s|\xc2\xb9|\xb9|g;             #<test> π Superscript One
    s|\xc2\xba|\xba|g;             #<¬∫|∫> ∫ Masculine Ordinal Indicator
    s|\xc2\xbb|\xbb|g;             #<¬     ª Right-Pointing Double Angle Quotation Mark
    s|\xc2\xbc|\xbc|g;             #<test> º Vulgar Fraction One Quarter
    s|\xc2\xbd|\xbd|g;             #<¬Ω|Ω> Ω Vulgar Fraction One Half
    s|\xc2\xbe|\xbe|g;             #<test> æ Vulgar Fraction Three Quarters
#    s|\xc2\xbf|\xbf|g;             #<test> ø Inverted Question Mark
    s|\xc2\xbf|'|g;             	#<test> mostly single quote
#
    s|\xc3\x80|\xc0|g;             #<test> ¬ Latin Capital Letter a with Circumflex
    s|\xc3\x81|\xc1|g;             #<test> √ Latin Capital Letter a with Tilde
    s|\xc3\x82|\xc2|g;             #<test> ¬ Latin Capital Letter a with Circumflex
    s|\xc3\x83|\xc3|g;             #<test> √ Latin Capital Letter a with Tilde
#    s|\xc3\x83|\xe0|g;       #<√Ö|`a> original
#>?    s|\xc3\x83|≈|g;       #<√Ö|`a>
    s|\xc3\x84|\xc4|g;             #<test> ƒ Latin Capital Letter a with Diaeresis
    s|\xc3\x85|\xc5|g;             #<test> ≈ Latin Capital Letter a with Ring Above
    s|\xc3\x86|\xc6|g;             #<test> ∆ Latin Capital Letter Ae
    s|\xc3\x87|\xc7|g;             #<test> « Latin Capital Letter C with Cedilla
    s|\xc3\x88|\xc8|g;             #<test> » Latin Capital Letter E with Grave
    s|\xc3\x89|\xc9|g;             #<√â|…> … Latin Capital Letter E with Acute
    s|\xc3\x8a|\xca|g;             #<test>   Latin Capital Letter E with Circumflex
    s|\xc3\x8b|\xcb|g;             #<test> À Latin Capital Letter E with Diaeresis
    s|\xc3\x8c|\xcc|g;             #<test> Ã Latin Capital Letter I with Grave
    s|\xc3\x8d|\xcd|g;             #<test> Õ Latin Capital Letter I with Acute
    s|\xc3\x8e|\xce|g;             #<test> Œ Latin Capital Letter I with Circumflex
    s|\xc3\x8f|\xcf|g;             #<test> œ Latin Capital Letter I with Diaeresis
#
    s|\xc3\x90|\xd0|g;             #<test> – Latin Capital Letter Eth
    s|\xc3\x91|\xd1|g;             #<test> — Latin Capital Letter N with Tilde
    s|\xc3\x92|\xd2|g;             #<test> “ Latin Capital Letter O with Grave
    s|\xc3\x93|\xd3|g;             #<test> ” Latin Capital Letter O with Acute
    s|\xc3\x94|\xd4|g;             #<test> ‘ Latin Capital Letter O with Circumflex
    s|\xc3\x95|\xd5|g;             #<test> ’ Latin Capital Letter O with Tilde
    s|\xc3\x96|\xd6|g;             #<test> ÷ Latin Capital Letter O with Diaeresis
    s|\xc3\x97|\xd7|g;             #<√ó|◊> ◊ Multiplication Sign
    s|\xc3\x98|\xd8|g;             #ÿ	   ÿ Latin Capital Letter O with Stroke
    s|\xc3\x99|\xd9|g;             #<test> Ÿ Latin Capital Letter U with Grave
    s|\xc3\x9a|\xda|g;             #<test> ⁄ Latin Capital Letter U with Acute
    s|\xc3\x9b|\xdb|g;             #<test> € Latin Capital Letter U with Circumflex
    s|\xc3\x9c|\xdc|g;             #<test> ‹ Latin Capital Letter U with Diaeresis
    s|\xc3\x9d|\xdd|g;             #<test> › Latin Capital Letter Y with Acute
    s|\xc3\x9e|\xde|g;             #<test> ﬁ Latin Capital Letter Thorn
#31.10.2020    s|\xc3\x9f|\xdf|g;             #<√ü|ﬂ> ﬂ Latin Small Letter Sharp S   why??
	s|\xc3\x9f|\xdf|g;             #<√ü|ﬂ> ﬂ Latin Small Letter Sharp S  
#
    s|\xc3\xa0|\xe0|g;             #<√†|‡> ‡ Latin Small Letter a with Grave
    s|\xc3\xa1|\xe1|g;             #<test> · Latin Small Letter a with Acute
    s|\xc3\xa2|\xe2|g;             #<√¢|‚> ‚ Latin Small Letter a with Circumflex
    s|\xc3\xa3|\xe3|g;             #<√£|„> „ Latin Small Letter a with Tilde
	s|\xc3\xa4|\xe4|g;             #<√§|‰> ‰ Latin Small Letter a with Diaeresis
    s|\xc3\xa5|\xe5|g;             #<test> Â Latin Small Letter a with Ring Above
    s|\xc3\xa6|\xe6|g;             #<test> Ê Latin Small Letter Ae
	s|\xc3\xa7|\xe7|g;             #<√ß|Á> Á Latin Small Letter C with Cedilla  #> introduced 2020-07-01
    s|\xc3\xa8|\xe8|g;             #<√®|Ë> Ë Latin Small Letter E with Grave
    s|\xc3\xa9|\xe9|g;             #<√©|È> È Latin Small Letter E with Acute
    s|\xc3\xaa|\xea|g;             #<test> Í Latin Small Letter E with Circumflex
    s|\xc3\xab|\xeb|g;             #<√´|Î> Î Latin Small Letter E with Diaeresis
    s|\xc3\xac|\xec|g;             #<test> Ï Latin Small Letter I with Grave
    s|\xc3\xad|\xed|g;             #<test> Ì Latin Small Letter I with Acute  #> introduced 2017-10-04
    s|\xc3\xae|\xee|g;             #<test> Ó Latin Small Letter I with Circumflex
    s|\xc3\xaf|\xef|g;             #<test> Ô Latin Small Letter I with Diaeresis
#
    s|\xc3\xb0|\xf0|g;             #<test>  Latin Small Letter Eth
    s|\xc3\xb1|\xf1|g;             #<√≥|Ò> Ò Latin Small Letter N with Tilde
    s|\xc3\xb2|\xf2|g;             #<√≤|Ú> Ú Latin Small Letter O with Grave
    s|\xc3\xb3|\xf3|g;             #<√≥|Û> Û Latin Small Letter O with Acute
    s|\xc3\xb4|\xf4|g;             #<test> Ù Latin Small Letter O with Circumflex
    s|\xc3\xb5|\xf5|g;             #<test> ı Latin Small Letter O with Tilde
    s|\xc3\xb6|\xf6|g;             #<√∂|ˆ> ˆ Latin Small Letter O with Diaeresis
    s|\xc3\xb7|\xf7|g;             #<test> ˜ Division Sign
    s|\xc3\xb8|\xf8|g;             #¯      ¯ Latin Small Letter O with Stroke
    s|\xc3\xb9|\xf9|g;             #<test> ˘ Latin Small Letter U with Grave
    s|\xc3\xba|\xfa|g;             #<√∫|˙> ˙ Latin Small Letter U with Acute
    s|\xc3\xbb|\xfb|g;             #<test> ˚ Latin Small Letter U with Circumflex
    s|\xc3\xbc|\xfc|g;             #<√º|¸> ¸ Latin Small Letter U with two Dots
    s|\xc3\xbd|\xfd|g;             #<√Ω|˝> ˝ Latin Small Letter Y with Acute
    s|\xc3\xbe|\xfe|g;             #<test> ˛ Latin Small Letter Thorn
    s|\xc3\xbf|\xff|g;             #<test> ˇ Latin Small Letter Y with Diaeresis
#---------------------------------------------------------------------------------
#?   s|ø|'|g;
#    s|\xce\xb2|\\beta|g;     #<Œ≤|?>  -> 3b2 -> \beta    -+
#    s|\\beta|\xce\xb2|g;     # 0xCEB2   due to encoding issues in session names now utf-8 equivalent
    s|\xce\xb3|\\gamma|g;    #<Œº|?>  -> 3b3 -> \gamma     |
    s|\xce\xbb|\\lambda|g;   #<Œº|?>  -> 3bb -> \lambda     > correct conversion to html follows later
#    s|\xce\xbc|\\mu|g;       #<Œº|?>  -> 3bc -> \mu        |
    s|\xce\xbc|µ|g;       	 #<Œº|?>  -> 3bc -> \mu        |
    s|\xcf\x80|\\pi|g;       #<œÄ|?>  -> 3c0 -> \pi       -+
#160306    s|\xe2\x80\x93|\x96|g;   	 #<‚Äì|ñ>     ++*   was \x96
#160306    s|\xe2\x80\x94|\x97|g;   #<‚Äî|ó>     ++*
#160306    s|\xe2\x80\x98|\x91|g;   #<‚Äò|ë>     ++*
#160306    s|\xe2\x80\x99|\x92|g;   #<‚Äô|'>     ++*
#160306    s|\xe2\x80\x9c|\x93|g;   #<‚Äú|ì>     ++*
#160306    s|\xe2\x80\x9d|\x94|g;   #<‚Äù|î>     ++*
#160306    s|\xe2\x80\xa0|\x86|g;   #<‚Ä†|Ü>     ++*
#160306    s|\xe2\x80\xa2|\x95|g;   #<‚Ä¢|ï>     ++*
    s|\xe2\x80\xa6|...|g;    #<‚Ä¢|...>
    s|\xe2\x85\xa1|II|g;     #<‚Ö°|II>    Roman II
    s|\xe2\x88\xbc|\\simeq|g;#<‚àº|\simeq>  -> 213c -> DOUBLE-STRUCK SMALL PI => \pi ~~~> \simeq
    s|\xe2\x89\x88|\\approx|g; #<‚â•|>=>      -> .approx.
    s|\xe2\x89\xa5|&ge;|g;   #<‚â•|>=>    -> .ge.
    s|\xef\x80\xa0|&nbsp;|g; #<ÔÄ | >
#    s|\xef\x81\xad|\\mu|g;   #<ÔÅ≠|µ>    -> f06d        -> private use area => µ, \mu
    s|\xef\x81\xad|µ|g;   #<ÔÅ≠|µ>    -> f06d        -> private use area => µ, \mu
    s|\xef\x81\xb0|\\pi|g;   #<ÔÅ∞|\pi>
    s|\xef\x82\xb3|\\ge|g;   #<ÔÇ≥|>= >  -> f083(61571) -> private use area => \ge
#   s|\xef\x83\x97|\xb7|g;   #<ÔÉó|∑>    -> f0d7(61655) -> private use area => \cdot
#160306    s|\xef\x83\x97|\x95|g;   #<ÔÉó|∑>    -> f0d7(61655) -> private use area => \cdot (instead of 'b7' used '95'       ++*
	s|\xc3\xb8|¯|g;                #<√∏|ÿ klein>
	s|√∏|¯|g;                #<√∏|ÿ klein>
#
# utf-8/Windows 1522  1 byte characters
#
    s|\x80|&#8364;|g;        # dagger
    s|&#x84;|&ldquo;|g;      # wrongly translated ",," (opening apostrophes German) as "``" (opening ..
    s|\x84|&ldquo;|g;        # ... apostrophes English) as there are no German Abstracts
    s|\x86|&#8224;|g;        # dagger
    s|\x87|&#8225;|g;        # double dagger
    s|\x95|&#8226;|g;        # Windows 1522 bullet
    s|&#xD8;|ÿ|g;
    s|&#xE0;|‡|g;
    s|&#xE8;|Ë|g;
    s|&#xE9;|È|g;
    s|&#xED;|Ì|g;
    s|&#xF3;|Û|g;
    s|&#xFC;|¸|g;
	s|\x16|???? µ ????|g;	#control character identified as "µ" in IPAC2017 in TUPAB139 and MOPAB054
#    s|&#x3BC;|µ|g;
    s|||g;                  # don't know what this is
#
# control character
#
    s|\x0b| |g;             #<VT|†>
#
#x    s|&beta;|\xce\xb2|g;     # \beta
#
	s|&#1084;|m|g;          # new in IPAC'14 (Cyrillic "m")
    s|&#1088;|p|g;          # Cyrillic "p" (er)
#
	s|&#9702;|∞|g;			# &#9702; U+25E6 (White Bullet) used as degree sign

    s|&#8210;|&mdash;|g;    # "Figure Dash" (U+2012 = &#8210;) # used in FLS'18 as emdash 
	s|&#8231;|&#183;|g;     # "HYPHENATION POINT" (U+2027 = &#8231;) # used in IPAC'14 as centered dot => U+00B7 &#183; "Middle Dot"
    s|&#8232;| |g;          # "Line Separator" (U+2028 = &#8232;)
    s|&#150;|&ndash;|g;     # "en dash"
    s|--|&ndash;|g;         # "en dash" TeX
    s|ó|&ndash;|g;          # "en dash"/divis
    s|&#8211;|&ndash;|g;    # "en dash"
    s|&#x2013;|&ndash;|g;   # "en dash" in hex                     (<= &#8211;)
##
    s|---|&mdash;|g;        # "em dash"
    s|&#x2014;|&mdash;|g;   # "em dash"                            (<= &#8211; ??)
##
#    s|&#8216;|&lsquo;|g;   # "left single quotation mark"         (<= &#145;)
#    s|&#x2018;|&lsquo;|g;  # "left single quotation mark" in hex  (<= &#145;)
    s|&#x2018;|&#8216;|g;   # "left single quotation mark" from hex  (<= &#145;)
#    s|ë|&lsquo;|g;         # "left single quotation mark"         (<= &#145;)
    s|ë|&#8216;|g;          # "left single quotation mark"         (<= &#145;)
#    s|`|&lsquo;|g;         # "left single quotation mark"         (<= &#145;)
    s|`|&#8216;|g;          # "left single quotation mark"         (<= &#145;)
##
#    s|&#8217;|&rsquo;|g;   # "right single quotation mark"        (<= &#147;)
#    s|&#8201;|&#8201;|g;   # thin space
    s|&#8203;||g;           # Zero width space                     (U+200B &#8203;)
    s|&#8206;||g;           # left to right mark
#    s|&#x2019;|&rsquo;|g;  # "right single quotation mark" in hex (<= &#146;)
    s|&#x2019;|&#8217;|g;   # "right single quotation mark" in hex (<= &#146;)
#    s|'|&rsquo;|g;         # "right single quotation mark"        (<= &#146;)
    s|'|&#8217;|g;          # "right single quotation mark"        (<= &#146;)
##
#    s|&#8220;|&ldquo;|g;   # ì left to right (66) "left double quotation mark"         (<= &#147;)
#    s|&#x201C;|&ldquo;|g;  # ì left to right (66) "left double quotation mark" in hex  (<= &#147;)
    s|&#x201C;|&#8220;|g;   # ì left to right (66) "left double quotation mark" in hex  (<= &#147;)
    s|ì|&#8220;|g;          # ì left to right (66) "left double quotation mark"
    s|ì|&ldquo;|g;          # ì left to right (66) "left double quotation mark"
##
#    s|&#8221;|&rdquo;|g;   # î right to left (99) "right double quotation mark"        (<= &#148;)
#    s|&#x201D;|&rdquo;|g;  # î right to left (99) "right double quotation mark" in hex (<= &#148;)
    s|&#x201D;|&#8221;|g;   # î right to left (99) "right double quotation mark" in hex (<= &#148;)
#    s|î|&rdquo;|g;         # î right to left (99) "right double quotation mark" in hex (<= &#148;)
    s|î|&#8221;|g;          # î right to left (99) "right double quotation mark" in hex (<= &#148;)
##
    s|&#x2026;|&hellip;|g;  # ... "horizontal ellipsis"                                 (<= "...")
    s|\.\.\.|&hellip;|ig;   # ... "horizontal ellipsis"                                 (<= &#133;)
##    s|&#64257;|fi|g;        # fi-ligature
##    s|&#64259;|ffi|g;
    s|ô|&trade;|g;          # "trade mark sign"                                         (<= &#153;)
    s|&#8451;|∞C|g;         # degrees Celsius as unit
    s|&#8208;|-|g;          # hyphen surrounded space => was minus (-) in NA-PAC2013
#    s|&#8209;|????|g;      # ???
     s|&#13211;|&mu;m|g;    # µm
	 s|&#13212;|mm|g;       # Square Mm CJK Compatibility  U+339C &#13212; 

     s|&#12310;|\x{3016}|g;    # U+3016 Left White Lenticular Bracket 
     s|&#12311;|\x{3017}|g;    # U+3017 Right White Lenticular Bracket 

	if (m|&#65342;|) {      # U+FF3E "FULLWIDTH CIRCUMFLEX ACCENT" (^)
		if (m|&#65342;(\d+)|) {
			s|&#65342;(\d+)|<sup>$1</sup>}|g;  # used as "power"
		} else {
		#	s|&#65342;||g;      # let it stay
			print DBG " \"FULLWIDTH CIRCUMFLEX ACCENT\" character sequence without number: $_\n";
			print     " \"FULLWIDTH CIRCUMFLEX ACCENT\" character sequence without number: $_\n";
		}
	}
	s|&#61616;|∞|g;         # U+F0B0
	s|&#61617;|±|g;         # U+F0B1
#
# intermediate hack while script is too clever and
# converts zip codes and other numbers containing
# assumed powers of ten to superscripts...
# 30.07.10 .*? changed to .+?
#
    s|\{10\}|zEhNZeHn|g;
    if (m|\{(.*?)(10)(.*?)\}|) {
#        print "~~~ $_\n";
        s|\{(.*?)(10)(.*?)\}|\{$1$ZeHn$3\}|g;
    }
#
# for GSI's PNP we just need pure ConTeXt output
# so convert the ConTeXt line breaks into "<br />"
#
    s|\\blank\[medium,flexible\]|<br />|g;
    s|\\blank\[small,flexible\]|<br />|g;
    s|\\Space|<br />|g;
    s|\\noindent||g;
    s|\\ |&nbsp;|g;
#Q    s|~|&nbsp;|g;
    s|\{\\bfseries (.*?)\}|<strong>$1<\/strong>|g;
    s|\{\\bf (.*?)\}|<strong>$1<\/strong>|g;
    s|\\bf\{(.*?)\}|<strong>$1<\/strong>|g;
    s|\\func\{(.*?)\}|<span style=\"font-family:\'Helvetica\',Helvetica,sans-serif\">$1<\/span>|g;
    s|\{\\rm (.*?)\}|$1|g;
    s|\{\\it (.*?)\}|<em>$1<\/em>|g;
    s|\\textbf\{(.*?)\}|<strong>$1<\/strong>|g;
    s|\\textit\{(.*?)\}|<em>$1<\/em>|g;
    s|\\mathrm\{(.*?)\}|$1|g;
    s|\\textsl\{(.*?)\}|<span style=\"font-family:\'Helvetica\',Helvetica,sans-serif\">$1<\/span>|g;
    s|\\small\{(.*?)\}|<span style=\"font-size:small\">$1</span>|g;
    s|\\cite\{(.*?)\}|<strong>[$1]<\/strong>|g;
    s|\\bibitem\{(.*?)\}|<strong>[$1]<\/strong>|g;
    s|\\emph\{(.*?)\}|<em>$1<\/em>|g;
    s|\\;|&ensp;|g;
    s|\\,|&thinsp;|g;
    s|\\\/|&zwj;|g;    #zero width joining
    s|\\left||g;
    s|\\right||g;
#
# special symbols or LaTeX notations with $....$
#   are hard to convert, so if the $s come in pairs
#   they will be deleted otherwise we have to deal
#   with them directly...
    my $countdolares = ($_ =~ s/\$/\$/g);
    if ($countdolares % 2) {
#<<<< 16.04.2009
#<<<<   $_ =~ s/\$/\\\$/g;
        # nada mas
    } else {
        $_ =~ s/\$//g;
        print DBG " --g---c_s_c ($wohe)> CountDollar $countdolares *** $_\n" unless $debug_restricted;
    }
#
# miscellaneous
#
    s|&#8729;|&#183;|g;   # \cdot
    s|°©|-|g;
    s|\\deg|<sup>o</sup>|g;
    s|\\lt|&lt;|g;
    s|\\gt|&gt;|g;
    s|\\v\{C\}|&#268;|g;
    s|\\v\{c\}|&#269;|g;
    s|\\c\{S\}|&#350;|g;
    s|\\c\{S\}|&#351;|g;
    s|\\v\{S\}|&#352;|g;
    s|\\v\{s\}|&#353;|g;
    s|\\diameter|&#8709;|g;   # same as \emptyset  (#0216,#0248)
    s|\$\\Phi\$|&#934;|g;     # specialty when in title line in LaTeX
#
# some µ elements (µ+ / µ-)
#
    s|\\mu\^-|&mu;<sup>&#8722;</sup>|g;
    s|µ\^-|µ<sup>&#8722;</sup>|g;
    s|\\mu\^+|&mu;<sup>+</sup>|g;
    s|µ\^+|µ<sup>+</sup>|g;
#
# the standard
#
    s|\\sum|&#8721;|g;
    s|\\prod|&#8719;|g;
    s|\\int|&#8747;|g;
    s|\\oint|(&#8747;)|g;
    s|\\bigcap|&#8745;|g;
    s|\\bigcup|&#8746;|g;
    s|\\bigvee|&#8744;|g;
    s|\\bigwedge|&#8743;|g;
    s|\\bigotimes|&#8855;|g;
    s|\\bigoplus|&#8853;|g;
    s|&#12290;|.|g;                                        # U+3002 IDEOGRAPHIC FULLSTOP
    s|&#12539;|&#183;|g;                                   # 140520 U+30FB KATAKANA MIDDLE DOT
    s|\\alpha|&#945;|g;
#    s|\\beta|\xce\xb2|g;                                  # 0xCEB2   due to encoding issues in session names now utf-8 equivalent
#      $\beta^*$
    s|\\beta\^\*|&#946;<sup>*</sup>|g;                     # 0xCEB2   due to encoding issues in session names now utf-8 equivalent
    s|\\beta\^\\star|&#946;<sup>*</sup>|g;                 # various kinds of beta*
    s|\\beta\^|&#946;^|g;                                  # 120410 beta^≤/≥
    s|\\beta_|&#946;_|g;                                   # 120410 beta_x/y^*
    s|([ (])beta\*|$1&#946;<sup>*</sup>|g;                 # 120410 beta*
    s/([ (])beta([\s]{0,}[=<>~*][\s]{0,})/$1&#946;$2/ig;   # corr: 110709 beta  120410 beta *
    s/^beta([\s]{0,}[=<>~*][\s]{0,})/&#946;$1/ig;          # corr: 110709 beta  120410 beta *
    s|\\bt|&#946;|g;
#    s|beta([ =&])|&#946;$1|g;
    s|\\gamma|&#947;|g;
    s|\\delta|&#948;|g;
    s|\\epsilon|&#949;|g;
    s|\\varepsilon|&#949;|g;
    s|\\zeta|&#950;|g;
    s|\\eta|&#951;|g;
    s|\\theta|&#952;|g;
    s|\\vartheta|&#977;|g;
    s|\\iota|&#953;|g;
    s|\\kappa|&#954;|g;
    s|\\lambda|&#955;|g;
    s|lambda|&#955;|g;
#    s|&mu;|\\mu|ig;
    s|&mu;|µ|ig;
#    s|&amp;mu;|\\mu|ig;
    s|&amp;mu;|µ|ig;
#¸¸    s|µ|\\mu|g;										# changed 180820 due to better support of µ in LaTeX (upright)
    s/([\d| ])micro[ |-|]ampere[s]{0,1}/$1&#956;A/g;    # changed 130518 due to wrong substitution of " Micro "
    s/([\d| |])micro[ |-|]A /$1&#956;A /g;              # changed 130518 due to wrong substitution of " Micro "
    s|microA |&#956;A |ig;
    s| micro |&#956;|g;                                 # changed 130518 due to wrong substitution of " Micro "
    s| microsec\b| &#956;s|ig;
    s| usec\b| &#956;s|ig;
    s|\\micro|&#956;|ig;
    s|\\mu|&#956;|g;
    s|&#61540;|&#916;|g;   # IPAC'13 Delta
    s|&#61543;|&#947;|g;   # PCaPAC gamma
    s|&#61548;|&bull;|g;   # bullet F06c => 25CF
    s|&#61537;|&#945;|g;   # there is no character mapping for (U+FF5E = &#61537;) which is not a valid Unicode character (=> alpha?)
    s|&#61538;|&#946;|g;
    s|&#61549;|&#956;|g;
    s|&#61550;|&#957;|g;   # nu (v)
	s|\^&#8727;|&#8432;|g;
    s|\\nu|&#957;|g;
    s|\\xi|&#958;|g;
    s|&#61552;|&#960;|g;
    s|&#61554;|&#961;|g;   # Pierce parameter (U+F072 = &#61554) => \rho
    s|<pi>|&#960;|g;
    s|&pi;|&#960;|g;
    s|&amp;pi;|&#960;|g;
    s|&lt;pi&gt;|&#960;|g;
    s|\\pi|&#960;|g;
    s|\\varpi|&#982;|g;
    s|\\rho|&#961;|g;
    s|\\varrho|&#961;|g;
    s|\\sigma|&#963;|g;
    s|sigma|&#963;|g;
    s|\\varsigma|&#962;|g;
    s|\\tau|&#964;|g;
    s|\\upsilon|&#965;|g;
    s|\\phi|&#966;|g;
    s|\\varphi|&#981;|g;
    s|\\chi|&#967;|g;
    s|\\psi|&#968;|g;
    s|\\omega|&#969;|g;
    s|\\Gamma|&#915;|g;
    s|\\Delta|&#916;|g;      # was wrong code (U+2206/&#8710;) => INCREMENT should be U+0394|&#916; => GREEK CAPITAL LETTER DELTA
    s|&#61508;|&#916;|g;
	s|&#9651;|&#916;|g;      # wrong code  (U+25B3/&#9651;) => WHITE UP-POINTING TRIANGLE should be U+0394|&#916; => GREEK CAPITAL LETTER DELTA
    s|\\Theta|&#920;|g;
    s|\\Lambda|&#923;|g;
    s|\\Xi|&#926;|g;
    s|\\Pi|&#928;|g;
    s|\\Sigma|&#931;|g;
    s|&#61523;|&#931;|g;
    s|\\Upsilon|&#933;|g;
    s|\\Phi|&#934;|g;
    s|\\Psi|&#936;|g;
    s|\\Omega|&#8486;|g;
    s|\\Ohm|&#8486;|ig;
    s|&#61527;|&#8486;|g;    # Ohm in an article from CERN
    s|&#937;|&#8486;|g;
#    s| Ohm| &#8486;|ig;
    s|\\Mho|&#8487;|ig;
    s|\\hbar|(<sup>h</sup>/<sub>2<font face="symbol">p</font></sub>)|g;
    s|\\imath|&#953;|g;
    s|\\jmath|j|g;
    s|\\ell|<i>l</i>|g;
    s|\\wp|&#8472;|g;
    s|\\Re|&#8476;|g;
    s|\\Im|&#8465;|g;
    s|\\prime|&#8242;|g;
    s|\\emptyset|&#8709;|g;
    s|\\angle|&#8736;|g;
    s|\\infty|&#8734;|g;
    s|\\partial|&#8706;|g;
    s|\\nabla|&#8711;|g;
    s|\\forall|&#8704;|g;
    s|\\exists|&#8707;|g;
    s|\\neg|&#172;|g;
    s|\\surd|&#8730;|g;
    s|\\top|&#8868;|g;
    s|\\bot|&#8869;|g;
    s|\\backslash|\\|g;
    s|\\clubsuit|&#9827;|g;
    s|\\diamondsuit|&#9830;|g;
    s|\\heartsuit|&#9829;|g;
    s|\\spadesuit|&#9824;|g;
    s|\\dag|&#8224;|g;
    s|\\ddag|&#8225;|g;
    s|\\S|&#167;|g;
    s|\\P|&#182;|g;
    s|\\copyright|&#169;|g;
    s|\\pounds|&#163;|g;
    s|\\diamond|&#9674;|g;
#   s|\\Box|<font size="-2"><sup>[<u>&#175;</u>]</sup></font>|g;
    s|\\Box|&#8239;|g;
    s|ï|&#183;|g;
    s|\\ldots|&#8230;|g;
    s|\\cdots|&#8943;|g;
	s|&#8901;|&#183;|g;			# map "Dot Operator" U+22C5 to "Middle Dot" U+00B7
    s|\\cdot|&#183;|g;
    s|\\vdots|&#8942;|g;
    s|\\ddots|&#8945;|g;
    s|\\lfloor|&#8970;|g;
    s|\\lceil|&#8968;|g;
    s|\\langle|&#9001;|g;
    s|\\rfloor|&#8971;|g;
    s|\\rceil|&#8969;|g;
    s|\\rangle|&#9002;|g;
    s|\\uparrow|&#8593;|g;
    s|\\downarrow|&#8595;|g;
    s|\\Uparrow|&#8657;|g;
    s|\\Downarrow|&#8659;|g;
    s|\\leq|&#8804;|g;
    s|\\le|&#8804;|g;
    s|\\geq|&#8805;|g;
    s|\\ge|&#8805;|g;
    s|\\ll|&#8810;|g;
    s|\\gg|&#8811;|g;
    s|\\subseteq|&#8838;|g;
    s|\\supseteq|&#8839;|g;
    s|\\subset|&#8834;|g;
    s|\\supset|&#8835;|g;
    s|\\in|&#8712;|g;
    s|\\ni|&#8715;|g;
    s|\\equiv|&#8801;|g;
    s|\\simeq|&#8773;|g;			# Approximately Equal To
    s|\\sim|&#160;&#8764;&#160;|g;	# Tilde Operator
    s|&amp;sim;|&#8764;|ig;
    s|\\perp|&#8869;|g;
    s|\\parallel|&#124;&#124;|g;
    s|\\approx|&#8776;|g;
    s|\\cong|&#8773;|g;
    s|\\neq|&#8800;|g;
    s|\\propto|&#8733;|g;
#  plus/minus see below "^+}-" substitution
    s|&#61620;|&times;|g;
	s|&#61624;|&ndash;|g;		# unknown character &#61624; U+F0B8 converted to "ndash" as it was used as a 'to sign' in "1&#61624;4.5 GeV/u".  
    s|◊|&times;|g;
    s|\\times|&times;|g;
    s|\\div|&#247;|g;
    s|\\ast|&#8727;|g;
    s|\\star|&#8727;|g;
    s|&deg;|&#176;|g;       # degree sign
    s|&amp;deg;|&#176;|g;       # degree sign
    s|∫|&#176;|g;           # degree sign
    s|&lt;br&gt;|<br />|g;
    s|∞|&#176;|g;           # degree sign
#?    s|&#61616|&#192;|g;     # degree sign
    s|&#61616|&#176;|g;     # degree sign
    s|Ω|&#189;|g;
    s|\\circ|&#176;|g;
    s|\\bullet|&#8226;|g;
    s|\\cdot|&#183;|g;
    s|\\cap|&#8745;|g;
    s|\\cup|&#8746;|g;
    s|\\vee|&#8744;|g;
    s|\\wedge|&#8743;|g;
    s|\\diamond|&#9674;|g;
    s|\\oplus|&#8853;|g;
    s|\\otimes|&#8855;|g;
    s|\\oslash|&#8709;|g;
    s|\\dagger|f|g;
    s|\\ddagger|<strike>f</strike>|g;
    s|\\longrightarrow|&#8594;|g;
    s|\\longleftarrow|&#8592;|g;
    s|\\longleftrightarrow|&#8596;|g;
    s|\\longmapsto|&#8594;|g;
    s|\\Longleftrightarrow|&#8660;|g;
    s|\\Longrightarrow|&#8658;|g;
    s|\\Longleftarrow|&#8656;|g;
    s|\\leftarrow|&#8592;|g;
    s|\\Leftarrow|&#8656;|g;
    s|\\rightarrow|&#8594;|g;
    s|\\Rightarrow|&#8658;|g;
    s|\\leftrightarrow|&#8596;|g;
    s|\\Leftrightarrow|&#8660;|g;
    s|\\mapsto|&#8594;|g;
    s|\\uparrow|&#8593;|g;
    s|\\Uparrow|&#8657;|g;
    s|\\downarrow|&#8595;|g;
    s|\\Downarrow|&#8659;|g;
    s|\\lesssim|&#8818;|g;
    s|\\gtrsim|&#8819;|g;
#
# highlighting __x__
#
    s|__(.*?)__|<strong>$1</strong>|g;
#
# illegal U+0096 ("ó") En dash ASCII
#
    if (m/[\s|\w]\x96[\s|\w]/g) {
        s|\s\x96\s| &ndash; |g;         # " - " => en dash
        s|(\d)\x96(\d)|$1&ndash;$2|g;   # "3-5" => use en dash
        s|(\w)\x96(\w)|$1&ndash;$2|g;   # "per-buffer" => "-"
    }
	s|\x96|ó|g;	# endash
	s|\xc2\x96|ó|g;	# endash
#
#  two with "|"
#
##    s+\\|+&#124;&#124;+g;
    s+\\mid+|+g;
#
# curly braces
# ^{} and _{} substitution (if formula is set in "$"..."$"
#                           remove these "$" too
#
    if (m/[\^_]\{(.+?)\}/ig) {
        print DBG "# --($wohe)> [sup0>] ª$1´ $_\n" unless $debug_restricted;
        s|\$?\^\{(.+?)\}\$?|<sup>$1</sup>|g;
        s|\$?_\{(.+?)\}\$?|<sub>$1</sub>|g;
        print DBG "# --($wohe)> [sup0<] ª$1´ $_\n" unless $debug_restricted;
    }
#
# round braces
# ^() and _() substitution (if formula is set in "$"..."$"
#                           remove these "$" too
#
    if (m/[\^_]\((.+?)\)/ig) {
        print DBG "# --($wohe)> [sup1>] ª$1´ $_\n" unless $debug_restricted;
        s|\$?\^\((.+?)\)\$?|<sup>$1</sup>|g;
        s|\$?_\((.+?)\)\$?|<sub>$1</sub>|g;
        print DBG "# --($wohe)> [sup1<] ª$1´ $_\n" unless $debug_restricted;
    }
#
# simple notation with
# ^-1 or ^2
#
    if (m/\^(-?\d+)/g) {
        print DBG "# --($wohe)> [supS>] ª$1´ $_\n" unless $debug_restricted;
        s|\^(-?\d+)|<sup>$1</sup>|g;
        print DBG "# --($wohe)> [supS<] ª$1´ $_\n" unless $debug_restricted;
    }
#
# simple notation with
# ^+ ^-
#
    if (m/\^(.)/g) {
        print DBG "# --($wohe)> [supS+>] ª$1´ $_\n" unless $debug_restricted;
        s|\^(.)|<sup>$1</sup>|g;
        print DBG "# --($wohe)> [supS+<] ª$1´ $_\n" unless $debug_restricted;
    }
#
# ^2 bearbeiten
#
    if (m/\^([-+]{0,1}\d+?)(\D)/g) {
        print DBG "# --($wohe)> [sup2>] ª$1´ ª$2´ $_\n" unless $debug_restricted;
        s|\^([-+]{0,1}\d+?)(\D)|<sup>$1</sup>$2|g;
        print DBG "# --($wohe)> [sup2<] ª$1´ ª$2´ $_\n" unless $debug_restricted;
    }
#
# notation 10e13 or 10^13 or 10e-9
#
    if (m/10[e\^]([+-]{0,1}\d+)([ .,\/-])/ig) {
        if ($1) {
            print DBG "# --($wohe)> [sup3>] ª$1´ ª$2´ $_\n" unless $debug_restricted;
            s#10[e\^]([+-]{0,1}\d+)([ .,\/-])#10<sup>$1</sup>$2#ig;
            print DBG "# --($wohe)> [sup3<] ª$1´ ª$2´ $_\n" unless $debug_restricted;
        }
    }
#
# notation 1e13/1e-13 (special case)
#
    if (m/1e([+-]{0,1}\d+)/ig) {
        if ($1) {
            print DBG "# --($wohe)> [sup4>] ª$1´ $_\n" unless $debug_restricted;
            s#1e([+-]{0,1}\d+)#10<sup>$1</sup>#ig;
            print DBG "# --($wohe)> [sup4<] ª$1´ $_\n" unless $debug_restricted;
        }
    }
#
# 6.45E9
#             -> missing is e-9")"
#             120410 corrected for empty (space) $1 argument
#
    if (m/([0-9]{1,}?)E([+-]{0,1}\d{1,2})([ .,\/-])/ig) {
        if ($2) {
            print DBG "# --($wohe)> [sup5>] ª$1´ ª$2´ $_\n" unless $debug_restricted;
            if (s|([0-9]{1,}?)E([+-]{0,1}\d{1,2})([ .,\/-])|$1&#183;10<sup>$2</sup>$3|ig) {
                print DBG "# --($wohe)> [sup5<] ª$1´ ª$2´ ª$3´ $_\n";
            }
        }
    }
#
# notation 1013 or 10-13   (should be corrected in the abstract!)
#                          do not convert ZIP codes and something like X-104
#!!  now without /g only the first instance will be converted
#!!  should be better to rescan string under the same conditions
#!!  "-" removed from list of allowed characters after power notation 105-109 MHz
#
    if (m|([^0-9])10([+-]{0,1}(\d{1,2}))([ .,\/])| && ($wohe ne "paper_ftn-web")) {
        print DBG "# --($wohe)> [3a] =$1=$2=$3=$4= |($3)|\n" unless $debug_restricted;
        if ($1 && ($3 >1 && $3<20)) {
            print DBG "# --($wohe)> [sup6>] =$1==$2==$3==$4= $_\n" unless $debug_restricted;
            if ($2) {
                s|([^0-9])10([+-]{0,1}(\d{1,2}))([ .,\/])|$1$ZeHn<sup>$2</sup>$4|;
                print DBG "# --($wohe)> [sup6<] =$1==$2==$3==$4= $_\n" unless $debug_restricted;
            } else {
                print DBG "# --($wohe)> [sup6!] =$1==$2==$3==$4= $_\n" unless $debug_restricted;
            }
        } else {
            print DBG "# --($wohe)> [sup6=] =$1==$2==$3==$4= $_\n" unless $debug_restricted;
        }
    }
##    if (m|[ -]{1,1}10([+-]{0,1}\d{1,2})[ .,\/-]|g) {
##        if ($1) {
##            s|([ -]{1,1})10([+-]{0,1}\d{1,2})([ .,\/-])|$1&zwj;10<sup>$2</sup>$3|g;
##        }
##    }
#
# notation 1e13 or 10^13
#? 21.07.10 check!!
#?    if (m|([0-9])e([+-]{0,1}\d+?)([ .,\/-])|ig) {
#?        if ($1) {
#?            print DBG "# --($wohe)> [sup7>] ª$1´ ª$2´ ª$3´ $_\n";
#?            s|([0-9])e([+-]{0,1}\d+?)([ .,\/-])| 10<sup>$1</sup>$2|ig;
#?            print DBG "# --($wohe)> [sup<7] ª$1´ ª$2´ ª$3´ $_\n";
#?        }
#?    }
#
# notation "10**13 "
#
    if (m/10\*\*([+-]{0,1}\d+?)/g) {
        print DBG "* found 10**xx -> 10**$1\n";
        if ($1) {
            print DBG "# --($wohe)> [sup8>] ª$1´ $_\n" unless $debug_restricted;
            print DBG "* found 10**xx -> 10**$1\n" unless $debug_restricted;
            s|10\*\*([+-]{0,1}\d+?)([ .,\/-])|10<sup>$1</sup>$2|g;
            print DBG "# --($wohe)> [sup8<] ª$1´ ª$2´ $_\n" unless $debug_restricted;
        }
    }
#
# element notation [single letter](\d*?)+
#
    if (m/([a-zA-Z]{1,2})(\d*?)\+/ig) {
        if ($2) {
            print DBG "# --($wohe)> [sup9>] ª$1´ ª$2´ $_\n" unless $debug_restricted;
            s|([a-zA-Z]{1,2})(\d*?)\+|$1<sup>$2+</sup>|g;
            print DBG "# --($wohe)> [sup9<] ª$1´ ª$2´ $_\n" unless $debug_restricted;
        }
    }
#
# single character or token ("\xxx ", "&#...;") as subscript _x
# HTML only!
#
    if (m|_(.)|) {
        if ($1 eq "\\") { s|_(\\.+? )|<sub>$1</sub>|g; }
        if ($1 eq "\&") {
            s|_(\&.*?;)|<sub>$1</sub>|g;
        } else {
            if (m|_\}|) {
                # don't!!
            } elsif (m|author_(.)|) {
                # don't!!
            } else {
                s|_(.)|<sub>$1</sub>|g;
            }
        }
    }
#
# sqrt
#
    if (m|\\sqrt\{(.*?)\}|ig) {
# 090719
#       s|\\sqrt\{(.*?)\}|<span style="font-weight:bold; font-size:120%">&#x221a;</span>($1)|ig;
        s|\\sqrt\{(.*?)\}|<span style="font-weight:bold; font-size:150%">&#x221a;</span>\{$1\}|ig;
    } elsif (m|\\sqrt(.*?) |ig) {
# 090719
#       s|\\sqrt(.*?) |<span style="font-weight:bold; font-size:120%">&#x221a;</span>($1) |ig;
        s|\\sqrt(.*?) |<span style="font-weight:bold; font-size:150%">&#x221a;</span>\{$1\} |ig;
    }
#
# [/*]ohm[/*]
#
    if (m|[/* ]{1,1}ohm[/* ]{1,1}|ig) {
        s|([/* ]{1,1})ohm([/* ]{1,1})|$1&#8486;$2|ig;
    }
#
# cm+-n
#
    if (m|cm[+-]{0,1}(\d)|g) {
        s|cm([+-]{0,1}\d)|cm<sup>$1</sup>|g;
    }
#
# some other elements (H+ / H- / e- / e+ / D+)
#
    s|e\+(.{0,1})e-|e<sup>+</sup>$1e<sup>&#8722;</sup>|g;
    s|e-(.{0,1})e\+|e<sup>&#8722;</sup>$1e<sup>+</sup>|g;
#
# Nb3Sn Q0 nanoohm [0-9]\.∞C SiO2 BBr3? H2 Qext  ??
#
    s|Nb3Sn|Nb<sub>3</sub>Sn|g;
    s|Nb2O5|Nb<sub>2</sub>O<sub>5</sub>|g;
    s|Nb\+|Nb<sup>+</sup>|g;
    s| N2| N<sub>2</sub>|g;
    s| H2| H<sub>2</sub>|g;
    s|BBr3|BBr<sub>3</sub>|g;
    s|MgB2|MgB<sub>2</sub>|g;
    s|Nb2N|Nb<sub>2</sub>N|g;
    s|Cs2Te|Cs<sub>2</sub>Te|g;
    s|CaF2|CaF<sub>2</sub>|g;
	s|H2SO4|H<sub>2</sub>SO<sub>4</sub>|g;
    s|SiO2|SiO<sub>2</sub>|g;
	s|Q0|Q<sub>0</sub>|g;
	s|HNO3|HNO<sub>3</sub>|g;
	s|nanoohm|n&#8486;|g;
	s|nOhm|n&#8486;|g;
    s|SnCl2|S<sub>n</sub>Cl<sub>2</sub>|g;
	s|Eacc|E<sub>acc</sub>|g;
	s|Qext|Q<sub>ext</sub>|g;
	s|TiO2|TiO<sub>2</sub>|g;
	s|CH4|CH<sub>4</sub>|g;
	s|CO2|CO<sub>2</sub>|g;

#
# substitute \overline{x} by HTML
#
	s|\\overline\{(.{0,1})\}|<span style=\"text-decoration: overline;\">$1</span>|g;
#
# version not used anymore, due to font enc problems with IE:   s|e\+e-|e<sup>+</sup>e&#713;|g;
#
    if (m/([a-zA-Z]{1,2})e- /) {
        # don't do anything (it might be something like "one- or two-fold")
    } else {
        # s|e- |e<sup><font size=\"-1\">-</font></sup> |g;
        # other not used version, due to font enc problems with IE: s|e- |e&#713; |g;
        s|e- |e<sup>-</sup> |g;
    }
    s|p\+([ ,/)-])|p<sup>+</sup>$1|g;
    s|e\+ |e<sup>+</sup> |g;
    s|H\+|H<sup>+</sup>|g;
    s|H\^\+|H<sup>+</sup>|g;
    s|H0([ ,/)])|H<sup>0</sup>$1|g;
    s|H2\+|H<sup>2+</sup>|g;
    s|H3\+|H<sup>3+</sup>|g;
# not used version, due to font enc problems with IE:   s|H- |H<sup><font size=\"-1\">&#713;</font></sup> |g;
    s|H-([ )])|H<sup>&#8722;</sup>$1|g;
    s|H\^- |H<sup>&#8722;</sup> |g;
    s|H\^&#8722; |H<sup>&#8722;</sup> |g;
    s|D\+|D<sup>+</sup>|g;
    if (m/[s|sec]-1[^0-9]/) {
#>        s=[s|sec]-1=s<sup>&#8722;1</sup>=g;
    }
    if (m/(s-1)[^0-9]/ || m/(sec-1)[^0-9]/) {
		s=[s|sec]-1=s<sup>&#8722;1</sup>=g;
    }
#
# missing space after punctuation (often used due to too short Abstract text allowance)
#
#***    s|(\w)\.([A-Z]{1})|$1.&nbsp;$2|g;   #***
    s|([\w]{3,})\.([A-Z]{1})|$1.&nbsp;$2|g;      # wrong quantity for an abstract
    s|([\(\)\w]{3,}),([\w]{1})|$1,&nbsp;$2|gi;
#
# different order, otherwise U73+-ions will be wrong with a "+-" after U73
#
#    s|±|&#177;|g;       # 1300801
    s|\+/\-|&#177;|g;
    s|\+\\-|&#177;|g;
    s|\+\-|&#177;|g;
    s|\\pm|&#177;|g;
    s|\\mp|&#177;|g;
#
# diacritical letters (and others)
#
				if (0) { # commented out due to the problems in coding the bibliographic export
				   s|¬|&Acirc;|g;
				   s|‚|&acirc;|g;
				   s|√|&Atilde;|g;
				   s|„|&atilde;|g;
				   s|∆|&AElig;|g;
				   s|Ê|&aelig;|g;
				   s|¡|&Aacute;|g;
				   s|·|&aacute;|g;
				   s|≈|&Aring;|g;
				   s|Â|&aring;|g;
				   s|¿|&Agrave;|g;
				   s|‡|&agrave;|g;
				   s|ƒ|&Auml;|g;
				   s|‰|&auml;|g;
				#
				   s|«|&Ccedil;|g;
				   s|Á|&ccedil;|g;
				#
				   s| |&Ecirc;|g;
				   s|Í|&ecirc;|g;
				   s|–|&ETH;|g;
				   s||&eth;|g;
				   s|»|&Egrave;|g;
				   s|Ë|&egrave;|g;
				   s|…|&Eacute;|g;
				   s|È|&eacute;|g;
				   s|À|&Euml;|g;
				   s|Î|&euml;|g;
				#
				   s|Œ|&Icirc;|g;
				   s|Ó|&icirc;|g;
				   s|Õ|&Iacute;|g;
				   s|Ì|&iacute;|g;
				   s|œ|&Iuml;|g;
				   s|Ô|&iuml;|g;
				   s|Ã|&Igrave;|g;
				   s|Ï|&igrave;|g;
				#
				   s|—|&Ntilde;|g;
				   s|Ò|&ntilde;|g;
				#
				   s|“|&Ograve;|g;
				   s|Ú|&ograve;|g;
				   s|÷|&Ouml;|g;
				   s|ˆ|&ouml;|g;
				   s|‘|&Ocirc;|g;
				   s|Ù|&ocirc;|g;
				   s|’|&Otilde;|g;
				   s|ı|&otilde;|g;
				   s|”|&Oacute;|g;
				   s|Û|&oacute;|g;
				   s|ÿ|&Oslash;|g;
				   s|¯|&oslash;|g;
				#
				   s|ﬂ|&szlig;|g;
				#
				   s|ﬁ|&THORN;|g;
				   s|˛|&thorn;|g;
				#
				   s|⁄|&Uacute;|g;
				   s|˙|&uacute;|g;
				   s|€|&Ucirc;|g;
				   s|˚|&ucirc;|g;
				   s|‹|&Uuml;|g;
				   s|¸|&uuml;|g;
				   s|Ÿ|&Ugrave;|g;
				   s|˘|&ugrave;|g;
				#
				   s|›|&Yacute;|g;
				   s|˝|&yacute;|g;
				   s|ˇ|&yuml;|g;
} # commented out
#
   s|&#61472;|&nbsp;|g;     # non-breakable space
#
##   s|&#8470;|&#8470;|g;   # numero (N^o)
    s| fuer | f&uuml;r |g;
    s| f\. | f&uuml;r |g;   # abbreviation "f." for "f¸r"
	s|CesrTA|CesrTA|ig;                   # CesrTA
    s/DA(F|PH)NE/DA&#934;NE/g;            # DAPHNE /  DAFNE
    s|DAEdALUS|DAE&#948;ALUS|ig;          # DAEdALUS
    s|Lodz|&#x0141;Ûd&#x017a;|g;   # for my Polish friends!
    s|Krakow|KrakÛw|g;             			# for my Polish friends!
    s|Swierk|&#x015a;wierk|g;             # for my Polish friends!
    s|Poznan|Pozna&#x0144;|g;             # for my Polish friends!
    s|Juelich|J&uuml;lich|g;
    s|akultaet|akult&auml;t|g;
    s|versitaet|versit&auml;t|g;
    s|m.b.H.|mbH|g;
    s|Rez|&#x0158;e&#x017e;|g;            # for my Czech friends!
    s|Jyvaskyla|Jyv‰skyl‰|g;
    s|SCK.CEN|SCK&#8226;CEN|g;
    s|swissfel|SwissFEL|ig;               # logo for PSI's FEL
    s|berlinpro|B<em>ERL</em>inPro|ig;    # logo for HZB ERL Linac Project
    s|sflash|sFLASH|ig;                   # logo
    s|, Canada's National Laboratory for Particle and Nuclear Physics||ig;

#    s/micro([-| |]{0,1})sec\b/&#956;$1s/ig;
    s|\\EUR|&#128;|ig;
#
# edit some list environments
#    the source should look like
#       [+ -)  -)  -)  +]  or
#       [+ 1)  2)  3)  +]  or
#       [+ a)  b)  c)  +]
#
#
    if (m|\[\+|) {
        my $listmode = 0;
        my $iltype   = "";
        my $listline = "";
        if (m|(\[\+.*?\+\])|) {
            #
            # itemize list now in $listline buffer
            #
            $listline = $1;
            if ($listline =~ m|(.)\)|) {
                #
                # determine what kind of itemize list it is
                #
                $listmode = 1;
                my $ilt = $1;
                if ($ilt =~ m|-|) {
                    $iltype = "<ul>";
                } else {
                    $listmode = 2;
                    if ($ilt =~ m|[aA]|) {
                        $iltype = "<ol type=\"$ilt\">";
                    } else {
                        $iltype = "<ol>";
                    }
                }
                $listline =~ s|\[\+|$iltype|;
            }
            if ($listmode) {
                $listline =~ s| .\)|<li>|;
                $listline =~ s| .\)|</li> <li>|g;
                if ($listmode == 1) {
                    $listline =~ s|\+\]|</li></ul>|;
                } else {
                    $listline =~ s|\+\]|</li></ol>|;
                }
            }
            s|\[\+.*?\+\]|$listline|;
        }
    }
#
# new paragraph in Abstracts
# 
    if (m|\[p\]|) {
		s|\[p\]|<p></p>|g;
	}
#
# get rid of some not used edit marks
#
##    s|\[\+||g;
##    s|\+\]||g;
    s|˜|/|g;
#30.07.10 .*? changed to .+?
#         \{+\} removed from substitution
#
#30.07.    s|\{(.+?)($ZeHn)(.+?)\}|$1ZeHn$3|g;
#01.07.11    s|(.+?)($ZeHn)(.+?)|$1ZeHn$3|g;
    s|\$ZeHn|10|g;
    s|zEhNZeHn|10|g;
##    s|\{(.*?)\}|$1|g;
    if (m|\{_\}|) {
        # reset escaping
        s|\{_\}|_|g;
    }
#
# correct wrong substitutions
#
	s|Indus<sup>&#8722;1</sup>|Indus-1|g;
    s|CLIC<sub>D</sub>DS|CLIC_DDS|g;
	s|SPARC<sub>L</sub>AB|SPARC&#95;LAB|ig; # SPARC_LAB
	
    if (m|<sup>&</sup>|g) {
        s|<sup>&</sup>(.*?;)|<sup>&$1</sup>|g;
	}
	#
	# no substitutions made in "convert_spec_chars"
	#
    if ($_ eq $in_string) {
		print DBG "<c_s_c ($wohe)> nosubs\n";
	} else {
		print DBG "<c_s_c ($wohe)> $_\n" unless $debug_restricted;
	}
	Deb_call_strucOut ();
    return $_;
}	
##############################################
#
# convert_spec_chars2TeX
#
##############################################
#   c_s_c2T
#
#    convert all non TeX characters by their
#    \TeX equivalents representation
#
sub convert_spec_chars2TeX {

    $_    = $_[0];   # was @_[0]
 my $wohe = $_[1];
    if ($_ eq "" || !defined $_) {
		if (!defined $_) {
			print     " undefined Argument for \$_ (==>$_[1]) found on line $.\n\n";
			print DBG " undefined Argument for \$_ (==>$_[1]) found on line $.\n\n";
		}
        return;
    }
	my $in_string = $_;
 	Deb_call_strucIn ("convert_spec_chars2TeX ($_)");

	my $utf_switch = $_[2];
    #
    # if no argument for utf-8 is given switch it to off (ISO-8859)
    #
    if (!defined $utf_switch) {
        $utf_switch = 0;
    }
#    print " call convert_spec_chars2TeX ($wohe) $utf_switch\n";
    print DBG ">c_s_c2t ($wohe)> $_\n" unless $debug_restricted;
#
# in Matt's XML "&#" seem to be converted to "&amp;#"
#
    s|&amp;#|&#|g;
    s|&amp;#321;|{\\L}|g;

    s|&amp;([a-z]{2,};)|&$1|g;
#
# utf-8 2/3 byte character sequences
#
 if ($utf_switch) {  #------------------------------- utf-8 -------------------------------
#    print " ####################################################################################> uft8\n";
    print DBG " s=> UTF-8 $_\n";
    s|\x95|\xc2\xb7|g;             #<¬∑|∑>  => \cdot (instead of 'b7' used '95')
#
# xa1...bf -> xc2.a1...bf
# xc0...ff -> xc3.80...bf
#
    s|\xa1|\xc2\xa1|g;             #<test> ° Inverted Exclamation Mark 
    s|\xa2|\xc2\xa2|g;             #<test> ¢ Cent Sign 
    s|\xa3|\xc2\xa3|g;             #<test> £ Pound Sign 
    s|\xa4|\xc2\xa4|g;             #<test> ° Inverted Exclamation Mark     s|\xa5|\xc2\xa5|g;             #<test>
    s|\xa5|\xc2\xa5|g;             #<test> • Yen Sign 
    s|\xa6|\xc2\xa6|g;             #<test> ¶ Broken Bar 
    s|\xa7|\xc2\xa7|g;             #<test> ß Section Sign 
    s|\xa8|\xc2\xa8|g;             #<test> ® Diaeresis
    s|\xa9|\xc2\xa9|g;             #<¬©|©> © Copyright Sign
    s|\xaa|\xc2\xaa|g;             #<test> ™ Feminine Ordinal Indicator 
    s|\xab|\xc2\xab|g;             #<test> ´ Left-Pointing Double Angle Quotation Mark 
    s|\xac|\xc2\xac|g;             #<¬¨|¨> ¨ Not Sign
    s|\xad|\xc2\xad|g;             #<test>   Soft Hyphen 
    s|\xae|\xc2\xae|g;             #<¬Æ|Æ> Æ Registered Sign
    s|\xaf|\xc2\xaf|g;             #<test> Ø Macron 
    s|\xb0|\xc2\xb0|g;             #<¬∞|∞> ∞ Degree Sign 
#?    s|\xb0|\\high{o}|g;            #<¬∞|∞> ∞ Degree Sign 
    s|\xb1|\xc2\xb1|g;             #<¬±|±> ± Plus minus symbol 
    s|\xb2|\xc2\xb2|g;             #<test> ≤ Superscript Two
    s|\xb3|\xc2\xb3|g;             #<test> ≥ Superscript Three 
    s|\xb4|\xc2\xb4|g;             #<test> ¥ Acute Accent 
#?    s|\xb5|\xc2\xb5|g;             #<¬µ|µ> µ Micro Sign
    s|\xb6|\xc2\xb6|g;             #<test> ∂ Pilcrow Sign 
    s|\xb7|\xc2\xb7|g;             #<¬∑|∑> ∑ Middle Dot 
    s|\xb8|\xc2\xb8|g;             #<¬∏|∏> ∏ Cedilla 
    s|\xb9|\xc2\xb9|g;             #<test> π Superscript One  
    s|\xba|\xc2\xba|g;             #<¬∫|∫> ∫ Masculine Ordinal Indicator 
    s|\xbb|\xc2\xbb|g;             #<¬     ª Right-Pointing Double Angle Quotation Mark
    s|\xbc|\xc2\xbc|g;             #<test> º Vulgar Fraction One Quarter
#    s|\xc2\xba|\\high{o}|g;        #<¬∫|∫>
    s|\xbd|\xc2\xbd|g;             #<¬Ω|Ω> Ω Vulgar Fraction One Half 
    s|\xbe|\xc2\xbe|g;             #<test> æ Vulgar Fraction Three Quarters 
    s|\xbf|\xc2\xbf|g;             #<test> ø Inverted Question Mark
#see HTML part   s|\xbf|\xc2\xbf|g;             #<¬ø|ø>
#?    s|\xc2\xbf|'|g;                #<¬ø|ø>
    s|ø|'|g;                       # don't know why it isn't the inverted questionmark but in text it's used as "'" (04.08.10)
#
    s|\xc0|\xc3\x80|g;             #<test> ¬ Latin Capital Letter a with Circumflex   
    s|\xc1|\xc3\x81|g;             #<test> √ Latin Capital Letter a with Tilde   
    s|\xc2|\xc3\x82|g;             #<test> ¬ Latin Capital Letter a with Circumflex  
    s|\xc3|\xc3\x83|g;             #<test> √ Latin Capital Letter a with Tilde   
    s|\xc4|\xc3\x84|g;             #<test> ƒ Latin Capital Letter a with Diaeresis   
    s|\xc5|\xc3\x85|g;             #<test> ≈ Latin Capital Letter a with Ring Above   
    s|\xc6|\xc3\x86|g;             #<test> ∆ Latin Capital Letter Ae
    s|\xc7|\xc3\x87|g;             #<test> « Latin Capital Letter C with Cedilla 
    s|\xc8|\xc3\x88|g;             #<test> » Latin Capital Letter E with Grave   
    s|\xc9|\xc3\x89|g;             #<√â|…> … Latin Capital Letter E with Acute
    s|\xca|\xc3\x8a|g;             #<test>   Latin Capital Letter E with Circumflex  
    s|\xcb|\xc3\x8b|g;             #<test> À Latin Capital Letter E with Diaeresis  
    s|\xcc|\xc3\x8c|g;             #<test> Ã Latin Capital Letter I with Grave   
    s|\xcd|\xc3\x8d|g;             #<test> Õ Latin Capital Letter I with Acute  
    s|\xce|\xc3\x8e|g;             #<test> Œ Latin Capital Letter I with Circumflex 
    s|\xcf|\xc3\x8f|g;             #<test> œ Latin Capital Letter I with Diaeresis  
    s|\xd0|\xc3\x90|g;             #<test> – Latin Capital Letter Eth  
    s|\xd1|\xc3\x91|g;             #<test> — Latin Capital Letter N with Tilde  
    s|\xd2|\xc3\x92|g;             #<test> “ Latin Capital Letter O with Grave  
    s|\xd3|\xc3\x93|g;             #<test> ” Latin Capital Letter O with Acute  
    s|\xd4|\xc3\x94|g;             #<test> ‘ Latin Capital Letter O with Circumflex  
    s|\xd5|\xc3\x95|g;             #<test> ’ Latin Capital Letter O with Tilde  
#    s|\xd6|\\oeh|g;                #<√ñ|÷>
#    s|÷|\\oeh|g;                   #<√ñ|÷>
    s|\xd6|\xc3\x96|g;             #<test> ÷ Latin Capital Letter O with Diaeresis 
    s|\xd7|\xc3\x97|g;             #<√ó|◊> ◊ Multiplication Sign 
    s|\xd8|\xc3\x98|g;             #ÿ	   ÿ Latin Capital Letter O with Stroke 
    s|\xd9|\xc3\x99|g;             #<test> Ÿ Latin Capital Letter U with Grave 
    s|\xda|\xc3\x9a|g;             #<test> ⁄ Latin Capital Letter U with Acute 
    s|\xdb|\xc3\x9b|g;             #<test> € Latin Capital Letter U with Circumflex 
    s|\xdc|\xc3\x9c|g;             #<test> ‹ Latin Capital Letter U with Diaeresis 
    s|\xdd|\xc3\x9d|g;             #<test> › Latin Capital Letter Y with Acute 
    s|\xde|\xc3\x9e|g;             #<test> ﬁ Latin Capital Letter Thorn
    s|\xdf|\xc3\x9f|g;             #<√ü|ﬂ>
    s|\xe0|\xc3\xa0|g;             #<√†|‡>
    s|\xe1|\xc3\xa1|g;             #<test> · Latin Small Letter a with Acute
    s|\xe2|\xc3\xa2|g;             #<√¢|‚>
    s|\xe3|\xc3\xa3|g;             #<√£|„>
	s|\xe4|\xc3\xa4|g;             #<√§|‰>
    s|\xe5|\xc3\xa5|g;             #<test> Â Latin Small Letter a with Ring Above
    s|\xe6|\xc3\xa6|g;             #<test> Ê Latin Small Letter Ae
	s|\xe7|\xc3\xa7|g;             #<√ß|Á> 2020.07.01.
    s|\xe8|\xc3\xa8|g;             #<√®|Ë>
    s|\xe9|\xc3\xa9|g;             #<√©|È>
    s|\xea|\xc3\xaa|g;             #<test>
    s|\xeb|\xc3\xab|g;             #<√´|Î>
    s|\xec|\xc3\xac|g;             #<test>
    s|\xed|\xc3\xad|g;             #<test>
    s|\xee|\xc3\xae|g;             #<test>
    s|\xef|\xc3\xaf|g;
    s|\xf0|\xc3\xb0|g;             #<test>  Latin Small Letter Eth 
    s|\xf1|\xc3\xb1|g;             #<√≥|Ò>
    s|\xf2|\xc3\xb2|g;             #<√≤|Ú>
    s|\xf3|\xc3\xb3|g;             #<√≥|Û>≤
    s|\xf4|\xc3\xb4|g;             #<test> Ù Latin Small Letter O with Circumflex
    s|\xf5|\xc3\xb5|g;             #<test> ı Latin Small Letter O with Tilde 
    s|\xf6|\xc3\xb6|g;             #<√∂|ˆ>
    s|\xf7|\xc3\xb7|g;             #<test> ˜ Division Sign 
    s|\xf8|\xc3\xb8|g;             #¯
    s|\xf9|\xc3\xb9|g;             #<test>
    s|\xfa|\xc3\xba|g;             #<√∫|˙>
    s|\xfb|\xc3\xbb|g;             #<test>
    s|\xfc|\xc3\xbc|g;             #<√º|¸>
    s|\xfd|\xc3\xbd|g;             #<test>
    s|\xfe|\xc3\xbe|g;             #<test>
    s|\xff|\xc3\xbf|g;             #<test>
    s|&#373;|\x{0175}|g;           # ^w 	      Latin Small Letter W with Circumflex (hat) U+0175   utf8: c5 b5 
	if ($_ eq "√?\.") {
		s|√?\.|≈\.|g;
		print "\n # # # # # # # found # # # # # # # \n";
	}
    print DBG " e=> UTF-8 $_\n";
 } else {  #dx---------------------------- iso-8859 -------------------------------
    print DBG " s=> LATIN $_\n" unless $debug_restricted;
    s|\xc2\x96|ó|g;                #<¬?|ñ>
    s|\xc2\xa0| |g;                #<¬†|†>
    s|\xc2\xa9|\xa9|g;             #<¬©|©>
    s|\xc2\xac|\xac|g;             #<¬¨|¨>
    s|\xc2\xae|\xae|g;             #<¬Æ|Æ>
    s|\xc2\xb0|\xb0|g;             #<¬∞|∞>
    s|\xc2\xb1|\xb1|g;             #<¬±|±>
    s|\xc2\xb2|\xb2|g;             #<¬≤|≤>
    s|\xc2\xb3|\$\\ge\$|g;         #<¬≥|>= > --> \ge
    s|\xc2\xb5|\xb5|g;             #<¬µ|µ>
	s|\xc2\xb7|\xb7|g;             #<¬∑|∑>	reintroduced 2016-08-22
#160306    s|\xc2\xb7|\x95|g;             #<¬∑|∑>  => \cdot (instead of 'b7' used '95')
    s|\xc2\xb8|\xb8|g;             #<¬∏|∏>
    s|\xc2\xba|\xba|g;             #<¬∫|∫>
    s|\xc2\xbd|\xbd|g;             #<¬Ω|Ω>
    s|\xc2\xbf|\xbf|g;             #<¬ø|ø>
    s|ø|'|g;
    s|\xc3\x83|\\`{a}|g;           #<√Ö|  `a  > original
#>>    s|\xc3\x83|{\\aa}|g;           #<√Ö|  `a  >
    s|\xc3\x85|{\\AA}|g;           #<√Ö| Aring>
    s|\xc3\x89|\xc9|g;             #<√â|…>
    s|\xc3\x96|\xd6|g;             #<√ñ|÷>
    s|\xc3\x97|\xd7|g;             #<√ó|◊>
    s|\xc3\x98|{\\O}|g;            #<√ó|{\O}>
# 31.10.2020    s|\xc3\x9f|\xdf|g;             #<√ü|ﬂ>  why??
    s|\xc3\x9f|\xdf|g;             #<√ü|ﬂ>
    s|\xc3\xa0|\xe0|g;             #<√†|‡>
    s|\xc3\xa2|\\^{a}|g;           #<√¢|‚>
    s|\xc3\xa3|\xe3|g;             #<√£|„>
#    s|\xc3\xa4|\xe4|g;             #<√§|‰>
    s|\xc3\xa4|\\"a|g;             #<√§|‰>
    s|\xc3\xa8|\xe8|g;             #<√®|Ë>
    s|\xc3\xa9|\xe9|g;             #<√©|È>
    s|\xc3\xab|\xeb|g;             #<√´|Î>
    s|\xc3\xad|\xed|g;             #<√≠|Ì>
    s|\xc3\xb1|\xf1|g;             #<√≥|Ò>
    s|\xc3\xb2|\\.{o}|g;           #<√≤|Ú>
    s|\xc3\xb3|\xf3|g;             #<√≥|Û>
    s|\xc3\xb6|\xf6|g;             #<√∂|ˆ>
    s|\xc3\xb8|{\\o}|g;            #<√∏|ÿ klein>
    s|\xc3\xbc|\xfc|g;             #<√º|¸>
	s|\xc5\x9f|\\c{s}|g;		   #	
	s|\x{0103}|\\u{a}|g;           #<  |\u{a}>
	s|\x{0105}|\\c{a}|g;           #<ƒÖ|\c{a}>
    s|\x{0107}|\\'{c}|g;           #<ƒá|\'{C}>
    s|\x{010c}|\\v{C}|g;           #<ƒå|\v{C}>
    s|\x{010d}|\\v{c}|g;           #<ƒç|\v{c}>
	s|\x{011f}|\\u{g}|g;           #<ƒü|\u{g}>
    s|\x{0131}|{\\i}|g;            #<ƒ±|{\i}>
    s|\x{0141}|{\\L}|g;            #<≈ |{\L}>
    s|\x{0142}|{\\l}|g;            #<≈,|{\l}>
    s|\x{0144}|\\'{n}|g;           #<≈,|\'{n}>
    s|\x{0158}|\\v{R}|g;           #<  |\v{R}>
    s|\x{0159}|\\v{r}|g;           #<≈ô|\v{r}>
    s|\xc5\x99|\\v{r}|g;           #<≈ô|\v{r}>
    s|\x{015a}|\\'{S}|g;           #<≈õ?|\'{S}>
    s|\x{015b}|\\'{s}|g;           #<≈õ|\'{s}>
    s|\x{015f}|\\c{s}|g;           #<≈ü|\c{s}>
    s|\x{0160}|\\v{S}|g;           #<≈ |\v{S}>
    s|\x{0161}|\\v{s}|g;           #<≈°|\v{s}>
    s|\x{0162}|\\v{t}|g;           #<≈£|\v{t}>
    s|\x{017b}|\\.{Z}|g;           #<≈ª|\.{Z}>
    s|\x{017c}|\\.{z}|g;           #<≈º|\.{z}>
    s|\x{017d}|\\v{Z}|g;           #<≈Ω|\v{Z}>
    s|\x{017e}|\\v{z}|g;           #<  |\v{z}>
    s|\x{c2}\x{9e}|\\v{z}|g;       #<¬û|\v{z}>
    s|\x{021b}|t|g;                #<+¯|t>     # U+021B LATIN SMALL LETTER T WITH COMMA BELOW => no LaTeX equivalent
    s|\xce\xb2|\$\\beta\$|g;       #<Œ≤|?>  -> 3b2 -> \beta
    s|\xce\xb3|\$\\gamma\$|g;      #<Œº|?>  -> 3b3 -> \gamma
    s|\xce\xbb|\$\\lambda\$|g;     #<Œº|?>  -> 3bb -> \lambda
#    s|\xce\xbc|\$\\mu\$|g;         #<Œº|?>  -> 3bc -> \mu
    s|\xce\xbc|µ|g;         		#<Œº|?>  -> 3bc -> \mu (upright µ)
    s|\xcf\x80|\$\\pi\$|g;         #<œÄ|?>  -> 3c0 -> \pi
    s|\xe1\xb8\xb1|\\'{k}|g;       #<·∏±| > -> U+1E31 LATIN SMALL LETTER K WITH ACUTE
    s|\x{1E31}|\\'{k}|g;           #<·∏±| > -> U+1E31 LATIN SMALL LETTER K WITH ACUTE
    s|\x{1D9C}|\\textsuperscript{\\small\\textrm{c}}|g;#        -> U+1D9C MODIFIER LETTER SMALL C
#160306	s|\xe2\x80\x93|\x96|g;         #<‚Äì|ñ>
	s|\xe2\x80\x93|--|g;			#<‚Äì|ñ>
#160306	s|\xe2\x80\x94|\x97|g;         #<‚Äî|ó>
	s|\xe2\x80\x94|---|g;			#<‚Äî|ó>
#160306	s|\xe2\x80\x98|\x91|g;         	#<‚Äò|ë>
	s|\xe2\x80\x98|\{\\textquoteleft\}|g;         #<‚Äò|ë>
#160306	s|\xe2\x80\x99|\x92|g;         	#<‚Äô|'>
    s|\xe2\x80\x99|\{\\textquoteright\}|g;         #<‚Äô|'>
#160306	s|\xe2\x80\x9c|\x93|g;         	#<‚Äú|ì>
    s|\xe2\x80\x9c|\{\\textquotedblleft\}|g;         #<‚Äú|ì>
#160306	s|\xe2\x80\x9d|\x94|g;         	#<‚Äù|î>
    s|\xe2\x80\x9d|\{\\textquotedblright\{|g;         #<‚Äù|î>
#160306	s|\xe2\x80\xa0|\x86|g;         	#<‚Ä†|Ü>
    s|\xe2\x80\xa0|\{\\dag\}|g;			#<‚Ä†|Ü>
#160306	s|\xe2\x80\xa2|\x95|g;         #<‚Ä¢|ï> \\bullet
    s|\xe2\x80\xa2|\{\\bullet\}|g;         #<‚Ä¢|ï> 
    s|\xe2\x80\xa6|\\ldots|g;      #<‚Ä¢|...>   "Ö" U+2026 HORIZONTAL ELLIPSIS
    s|\xe2\x85\xa1|II|g;           #<‚Ö°|II>    Roman II
    s|\xe2\x88\xbc|\$\\simeq\$|g;  #<‚àº|\simeq>  -> 213c -> DOUBLE-STRUCK SMALL PI => \pi ~~~> \simeq
    s|\xe2\x89\x88|\$\\approx\$|g; #<‚â•|>=>      -> .approx.
    s|\xe2\x89\xa5|\$\\ge\$|g;     #<‚â•|>=>      -> .ge.
    s|\xef\x80\xa0|&nbsp;|g;       #<ÔÄ | >
#    s|\xef\x81\xad|\$\\mu\$|g;     #<ÔÅ≠|µ>    -> f06d        -> private use area => µ, \mu
    s|\xef\x81\xad|µ|g;     		#<ÔÅ≠|µ>    -> f06d        -> private use area => µ, \mu
    s|\xef\x81\xb0|\$\\pi\$|g;     #<ÔÅ∞|\pi>
    s|\xef\x82\xb3|\$\\ge\$|g;     #<ÔÇ≥|>= >  -> f083(61571) -> private use area => \ge
#   s|\xef\x83\x97|\xb7|g;         #<ÔÉó|∑>    -> f0d7(61655) -> private use area => \cdot
    s|\xef\x83\x97|\x95|g;         #<ÔÉó|∑>    -> f0d7(61655) -> private use area => \cdot (instead of 'b7' used '95')
#
# utf-8/Windows 1522  1 byte characters
#
#    s|\x80|\\textgreek{\\euro}|g;  # Euro		2016-08-22
    s|\x80|{\\texteuro}|g;  # Euro
#160306	s|&#x84;|``|g;
    s|&#x84;|\{\\textquotedblleft\}|g;
#160306	s|\x84|``|g;
    s|\x84|\{\\textquotedblleft\}|g;
    s|\x86|\\dag|g;                # dagger
    s|\x87|\\ddag|g;               # double dagger
    s|\x95|\\bullet|g;             # Windows 1522
    s|\xb1|\\ensuremath{\\pm}|g;   #"á"
    s|\xb2|\\high{2}|g;            #<≤|^2>
    s|\xb3|\\high{3}|g;            #<≥|^3>
#160306	s|\xb4|\x92|g;				#<¥|†>
    s|\xc2\xb4|\{\\textquoteright\}|g;		#<¥|†>
    s|\xb4|\{\\textquoteright\}|g;		#<¥|†>
    s|&#xd8;|¯|g;
    s|&#xe0;|‡|g;
    s|&#xe4;|‰|g;
    s|\xe4|‰|g;
    s|&#xe8;|Ë|g;
    s|&#xe9;|È|g;
    s|&#xed;|Ì|g;
    s|&#xf3;|Û|g;
    s|&#xfc;|¸|g;
    s|&#x3bc;|µ|g;
# ICALEPCS problematic chars
    s|\xe9|\\'{e}|g;
    s|\xf1|\\~{n}|g;
    s|\xf2|\\`o|g;
    s|\xf3|\\'o|g;
    s|\xfa|\\'u|g;
	s|\x16|???? {\\textmu}µ ????|g;	# control character identified as "µ" in IPAC2017 in TUPAB139 and MOPAB054
    
    print DBG " e=> LATIN $_\n" unless $debug_restricted;
 } #------------------------------- both utf-8/iso-8859 -------------------------------
 
	s|&lt;sub&gt;(.*?)&lt;/sub&gt;|\\low{$1}|g;			# FEL'19 with HTML entity encoding
# 	s|&lt;sub&gt;(.*?)&lt;\/sub&gt;|\\low{$1}|g;		# FEL'19 with HTML entity encoding

 
    s|&#x2013;|&#8211;|g;
    s|&#x2014;|---|g;
#--
	s|&#272;|–|g;			# U+0110 "Latin Capital Letter D with Stroke"
    s|&#321;|\{\\L\}|g;     # U+0141 "LATIN SMALL LETTER L WITH A STROKE"
    s|&#778;|\\high{o}|g;   # U+030A "COMBINING RING ABOVE" (&#778;)
	s|&#7873;|\\`{\\^{e}}|g;	# U+1EC1 "Latin Small Letter E with Circumflex and Grave"
	s|&#7877;|\\~{\\^{e}}|g;	# U+1EC5 "Latin Small Letter E with Circumflex and Tilde"
    s|&#8210;|---|g;        # "Figure Dash" (U+2012 = &#8210;) # used in FLS'18 as emdash 
    s|&#8231;|\\cdot|g;     # U+2027 "HYPHENATION POINT" (&#8231;) see v19.7 : U+00B7 &#183; Middle dot
	s|&#8901;|\\cdot|g;		# map "Dot Operator" U+22C5 to "Middle Dot" U+00B7
    s|&#8232;| |g;          # U+2028 "Line Separator" (U+2028 = &#8232;)
    s|&#8254;|\\high{\$-\$}|g;  # U+203E "OVERLINE"		added math-mode for longer minus sign  2016-08-24
    s|&#9472;|--|g;         # U+2500 "BOX DRAWINGS LIGHT HORIZONTAL"
    s|&#65285;|\\,\\%|g;    # U+FF05 "Fullwidth Percent Sign"
    s|&#65288;| (|g;        # U+FF08 "FULLWIDTH LEFT PARENTHESIS"
    s|&#65289;|) |g;        # U+FF09 "FULLWIDTH RIGHT PARENTHESIS"
	s|&#65290;|* |g;        # U+FF0A "FULLWIDTH ASTERISK" (&#65290;)
    s|&#65292;|, |g;        # U+FF0C "FULLWIDTH COMMA"
    s|&#65294;|. |g;        # U+FF0E "FULLWIDTH FULL STOP"
    s|&#65308;|<|g;         # U+FF1C "FULLWIDTH LESS-THAN SIGN"
	if (m|&#65342;|) {      # U+FF3E "FULLWIDTH CIRCUMFLEX ACCENT" (^)
		if (m|&#65342;(\d+)|) {
			s|&#65342;(\d+)|\\textsuperscript{$1}|g;  # used as "power"
		} else {
			s|&#65342;||g;      # no idea what comes after that...
		}
	}
	s|&#65374;|\$\\sim\$|g; # U+FF5E "FULLWIDTH TILDE" (&#65374;)
	s|&#61616;|\\high{o}|g; # U+F0B0
	s|&#61617;|\\ensuremath{\\pm}|g;         # U+F0B1
#
# translation list for HTML4 to TeX
#
    s|&#150;|--|g;          # "en dash"
    s|&#8211;|--|g;         # "en dash"
    s|&#8722;|--|g;         # "Math Minus" to "en dash"
    s|&#8725;|/|g;			# U+2215	Division Slash
    s|ó|--|g;               # "en dash"
    s|ñ|--|g;               # "en dash"/divis
    s|&ndash;|--|g;         # "en dash" TeX
    s|&#151;|---|g;         # "em dash"
    s|&mdash;|---|g;        # "em dash" 0xE28094-UTF-8 => 0x2014-UTF16
    s|&#8213;|---|g;        # U+2015 "HORIZONTAL BAR" [longer than "EM DASH" (&#8213;)
    s|&sim;|\$\\sim\$|g;    #
    s|&#8195;| |g;          # "em space"
	s|&#8196;| |g;           # U+2004 THREE-PER-EM SPACE => \, (for test " " instead of "\\,")
#
# control character
#
    s|\x0b| |g;             #<VT|†>
#
##
    s|ë|`|g;
    s|`|`|g;
    s|&#145;|`|g;
    s|&lsquo;|`|g;          # "left single quotation mark"         (<= &#145;)
    s|&#8216;|`|g;          # "left single quotation mark"         (<= &#145;)
    s|&#x2018;|`|g;         # "left single quotation mark"         (<= &#145;)
    s|&#8217;|'|g;          # "right single quotation mark"        (<= &#146;)
    s|&#x2019;|'|g;         # "right single quotation mark"        (<= &#146;)
    s|&#146;|'|g;
    s|í|'|g;
    s|&#713;|\\high{\$-\$}|g;	# unicode ^-	added math-mode for longer minus sign  2016-08-24
    s|&rsquo;|'|g;          # "right single quotation mark"        (<= &#147;)
    s|&#x201C;|``|g;        # ì left to right (66) "left double quotation mark"         (<= &#147;)
    s|&#8220;|``|g;         # ì left to right (66) "left double quotation mark"         (<= &#147;)
    s|&#147;|``|g;          # ì left to right
    s|ì|``|g;               # ì left to right
    s|&ldquo;|``|g;         # ì left to right (66) "left double quotation mark"         (<= &#147;)
    s|&#x201D;|''|g;        # î right to left (99) "right double quotation mark"        (<= &#148;)
    s|&#8221;|''|g;         # î right to left (99) "right double quotation mark"        (<= &#148;)
    s|&#148;|''|g;          # î right to left
    s|î|''|g;               # î right to left
    s|&rdquo;|''|g;         # î right to left (99) "right double quotation mark"        (<= &#148;)
    s|&#x2026;|\\ldots|g;
    s|&hellip;|\\ldots|g;   # ... "horizontal ellipsis"                                 (<= "...")
    s|Ö|{\\ldots}|g;        # "Ö" U+2026 HORIZONTAL ELLIPSIS                            (<= "...")
    s|&trade;|\\high{TM}|g; # "trade mark sign"                                         (<= &#153;)
    s|&#153;|\\high{TM}|g;  # trademark symbol
    s|ô|\\high{TM}|g;       # trademark symbol
    s|&#8201;|\\,|g;        # thin space
    s|&#8202;|\\,|g;        # Hair space
	s|&#8203;||g;           # Zero width space                     (U+200B &#8203;)
    s|&#8208;|-|g;          # hyphen surrounded space => was minus (-) in NA-PAC2013
    s|&#8208;|\\,-\\,|g;    # hyphen surrounded space
    s|&#8209;|-|g;          # hyphen or endash?
    s|&#8451;|∞C|g;         # degrees Celsius as unit
#
# math chars
#	
	s|&#119864;|\\textit{E}|g;				# U+1D438	Mathematical Italic Capital E
	s|&#120549;|\\ensuremath{\\Delta}|g;	# U+1D6E5	Mathematical Italic Capital Delta
	s|&#120590;|\\ensuremath{\\sigma}|g;	# U+1D70E	Mathematical Italic Small Sigma
#
#
#
    s| &amp; | \\& |g;     # LaTeX's escaped &
    s| & | \\& |g;         # LaTeX's escaped &
    s|A&amp;M|A\\&M|g;     # without this line we either get a "A\& " or "A\&\M "
                           # depending on the sequence of the statement with "s/;/;\\\\/g;"
    s|R&amp;D|R\\&D|g;
#???    s|&quot;|\{\"|g;
#
#>>>> 16.04.2009
# special symbols or LaTeX notations with $....$
#   are hard to convert, so if the $s come in pairs
#   they will be deleted otherwise we have to deal
#   with them directly...
    my $countdolares = ($_ =~ s/\$/\$/g);
    if ($countdolares % 2) {
        $_ =~ s/\$/\\\$/g;
        # nada mas
    } else {
#01.08.10        $_ =~ s/\$//g;
        print DBG " --g---c_s_c2T$ ($wohe)> CountDollar [$countdolares] *** $_\n" unless $debug_restricted;
    }
#<<<< 16.04.2009
#
# some specialities discovered in GSI's PNP conference
#
# 30.07.10 .*? changed to .+? like in HTML part
    if (m|\{(.+?)(10)(.+?)\}|) {
        s|\{(.+?)(10)(.+?)\}|\{$1$ZeHn$3\}|g;
    }
    s|Ü|\\textdagger|g;    # LaTeX's dagger
    s|\\noindent||g;
    s|\{\\bfseries (.*?)\}|\{\\bf $1\}|g;
    s|\\bf\{(.*?)\}|{\\bf $1}|g;
#    s|\{\\bf (.*?)\}|
#    s|\{\\rm (.*?)\}|
#    s|\{\\it (.*?)\}|
#    s|\\textbf\{(.*?)\}|{\\bf $1}|g;		#removed 27.3c -> beware when using ConTeXt
#    s|\\textit\{(.*?)\}|{\\it $1}|g;		#removed 27.3c -> beware when using ConTeXt
#    s|\\textsl\{(.*?)\}|{\\sl $1}|g;		#removed 27.3c -> beware when using ConTeXt
#    s|\\func\{(.*?)\}|{\\sl $1}|g;			#changed 27.3c -> beware when using ConTeXt
    s|\\func\{(.*?)\}|\\textsl\{$1\}|g;
    s|\\small\{(.*?)\}|{\\tfx $1}|g;
    s|\\cite\{(.*?)\}|{\\bf \[$1\]}|g;
    s|\\bibitem\{(.*?)\}|{\\bf \[$1\]}|g;
    s|\\emph\{(.*?)\}|{\\em $1}|g;
#    s|\\;|
#    s|\\,|
#    s|\\\/|
#    s|\\left|
#    s|\\right|
#
# miscellaneous
#
    s|°©|-|g;
    s|©|\\copyright{}|g;
    s|&lt;pi&gt;|\$\\pi\$|g; #<pi> isn't always what it should be
    s|&lt;|\$<\$|g;
    s|&le;|\$\\le\$|g;
	s|&#247;|\$\\times\$|g;   #
    s|&#261;|\\c{a}|g;        # a-ogonek
    s|&#262;|\\'{C}|g;        # C-acute
    s|&#263;|\\'{c}|g;        # c-acute
    s|&#268;|\\v{C}|g;        # C-caron
    s|&#269;|\\v{c}|g;        # c-caron
    s|&#279;|\\.{e}|g;        # LATIN SMALL LETTER E WITH DOT ABOVE EDIT  U+0117 &#279;
    s|&#281;|\\c{e}|g;        # LATIN SMALL LETTER E WITH OGONEK  U+0119 &#281; 
	s|\x{0119}|\\c{e}|g;      # utf8
    s|&#304;|\\.{I}|g;        # LATIN CAPITAL LETTER I WITH DOT
    s|&#305;|{\\i}|g;         # LATIN SMALL LETTER DOTLESS i
    s|&#322;|{\\l}|g;         # polish l-slash
    s|&#324;|\\'{n}|g;        # n-acute
    s|&#345;|\\v{r}|g;        # Latin Small Letter R with Caron
    s|&#346;|\\'{S}|g;        # LATIN CAPITAL LETTER S WITH ACUTE
    s|&#347;|\\'{s}|g;        # LATIN SMALL LETTER S WITH ACUTE
    s|&#350;|\\c{S}|g;        # S-cedilla
    s|&#351;|\\c{S}|g;        # s-cedilla
    s|&#352;|\\v{S}|g;        # S-caron
    s|&#353;|\\v{s}|g;        # s-caron
    s|&#373;|\\ensuremath{\\hat{w}}|g;  # ^w 	      Latin Small Letter W with Circumflex U+0175   utf8: c5 b5 	
    s|&#378;|\\'{z}|g;        # z-acute
    s|&#380;|\\.{z}|g;        # z-dot above
    s|&#415;|O|g;             # LATIN CAPITAL LETTER O WITH MIDDLE TILDE U+019F unclear what it should look like or do (ICALEPCS2015)
	
    if (m|~|) {
       print DBG " --g---c_s_c2T= ($wohe)> [T~>] $_\n" unless $debug_restricted;
       if (m|\\~\{|) {
            print DBG "# --g---c_s_c2T1 ($wohe)> [T~T>] $_\n" unless $debug_restricted;
        } elsif (m|~[0-9{]|) {
            print DBG "# --g---c_s_c2T2 ($wohe)> [T~R>] $_\n" unless $debug_restricted;
            s|~([0-9{])|\$\\sim\$$1|g;
            print DBG "# --g---c_s_c2T3 ($wohe)> [T~R<] $_\n" unless $debug_restricted;
        } else {
            print DBG "# --g---c_s_c2T4 ($wohe)> [T~X>] $_\n" unless $debug_restricted;
        }
    }

    if (m|[^\.]~|) {
        if (m|\~\{|) {
            # nada
        } else {
            s|~|\$\\sim\$|g;
        }
    }

    s|&#61472;|~|g;
    s|ï|\\cdot|g;
    s|&#61552;|\$\\pi\$|g;
    s|&#61537;|\$\\alpha\$|g;			# there is no character mapping for (U+FF5E = &#61537; [61537=U+F061]) which is not a valid Unicode character (=> alpha?)
    s|&#61538;|\$\\beta\$|g;
    s|&#61554;|\$\\rho\$|g;				# Pierce parameter (U+F072 = &#61554,) => \rho
    s|&#61566;|?????????|g;				# U+F07E = &#61554;) => ?
    s|&#61617;|???????|g;				# unknown glyph U+F0B1 private user area
    s|&#61620;|\$\\times\$|g;
    s|&#61624;|--|g;					# unknown character &#61624; U+F0B8 converted to "ndash" as it was used as a 'to sign' in "1&#61624;4.5 GeV/u".
    s|◊|\$\\times\$|g;
    s|%|\\%|g;							# escape "%"
    s|\\\\%|\\%|g;						# unescape escaped "%"
    s|&gt;|\$>\$|g;	
    s|&#8709;|\$\\diameter\$|g;			# same as \emptyset  (#0216,#0248)
    s|&#934;|\$\\Phi\$|g;				# specialty when in title line in LaTeX
    s|&#632;|\$\\phi\$|g;				# lower case phi
    s|&#1040;|A|g;						# Cyrillic "A"
    s|&#1052;|M|g;						# Cyrillic "M"
    s|&#1057;|C|g;						# Cyrillic "C"
    s|&#1060;|\$\\Phi\$|g;				# new in ICALEPCS'09
	s|&#1084;|m|g;						# new in IPAC'14 (Cyrillic "m")
    s|&#1088;|p|g;						# Cyrillic "p" (er)
    s|&#8364;|{\\texteuro}|ig;			# Euro

#
# some µ elements (µ+ / µ-)
#
#    s|\\mu\^-|µ\\high{\$-\$}|g;		# added math-mode for longer minus sign  2016-08-24
    s|\\mu\^-|\\mu\\high{\$-\$}|g;		# added math-mode for longer minus sign  2016-08-24
#    s|\\mu\^+|µ\\high{+}|g;
    s|\\mu\^+|\\mu\\high{+}|g;
    
#
# the standard
#
    s|&#95;|\\_|g;
    s|&#8721;|\$\\sum\$|g;
    s|&#8719;|\$\\prod\$|g;
    s|&#8747;|\$\\int\$|g;
    s|(&#8747;)|\$\\oint\$|g;
    s|&#8745;|\$\\bigcap\$|g;
    s|&#8746;|\$\\bigcup\$|g;
    s|&#8744;|\$\\bigvee\$|g;
    s|&#8743;|\$\\bigwedge\$|g;
    s|&#8855;|\$\\bigotimes\$|g;
    s|&#8853;|\$\\bigoplus\$|g;
    s|&#12288;| |g;                                 # U+3000 IDEOGRAPHIC SPACE
    s|&#12289;|,|g;                                 # U+3001 IDEOGRAPHIC COMMA
    s|&#12290;|.|g;                                 # U+3002 IDEOGRAPHIC FULLSTOP
	s|&#12310;|[\\kern-2pt(|g;                      # U+3016 LEFT WHITE LENTICULAR BRACKET
    s|&#12311;|)\\kern-2pt]|g;                      # U+3017 RIGHT WHITE LENTICULAR BRACKET
    s|&#12539;|\\cdot|g;                          	# U+30FB KATAKANA MIDDLE DOT
    s|&#120587;|\\pi|g;      						# U+1D70B => Mathematical Italic Small Pi 
    s|&#120573;|\\beta|g;    						# U+1D6FD => Mathematical Italic Small Beta
	s|&#706;|<|g;            						# U+02C2 => Modifier Letter Left Arrowhead 
    s|&#916;|\$\\Delta\$|g;
    s|&#9651;|\$\\Delta\$|g;                        # wrong code (U+25B3/&#9651;) => WHITE UP-POINTING TRIANGLE should be U+0394|&#916; => GREEK CAPITAL LETTER DELTA 
    s|&#61508;|&#916;|g;
	s|&#9651;|&#916;|g;      

    s|&#945;|\$\\alpha\$|g;                         # \$ introduced (090518)
# reintroduced as \beta star
    s|\$\\beta\^\*\$|\$\\beta\\high{*}\$|g;
    s|\\beta\^\\star|\$\\beta\\high{*}\$|g;            # various kinds of beta*
    s|([ (])beta\*|$1\$\\beta\\high{*}\$|g;            # 120410 beta_x/y^*
    s|\\beta\^|\$\\beta^|g;                            # 120410 beta^≤/≥
    s|\\beta_|\$\\beta_|g;                             # 120410 beta*
    s/([ (])beta([\s]{0,}[=<>~*][\s]{0,})/$1\$\\beta\$$2/ig; # corr: 110709 beta  120410 beta *
    s/^beta([\s]{0,}[=<>~*][\s]{0,})/\$\\beta\$$1/ig;  # corr: 110709 beta  120410 beta *
    s|&beta;|\$\\beta\$|g;                             # corr: 110709 \&s
#    s|\\nu|\$\\nu\$|g;
#?    s|<beta>|\$\\beta\$|g;
#    s|&#946;([ =&])|\$\\beta\$$1|g;
    s|&#946;|\$\\beta\$|g;
    s|&#61543;|\$\\gamma\$|g;   # PCaPAC gamma
    s|&#947;|\$\\gamma\$|g;
    s|&#948;|\$\\delta\$|g;
    s|&#949;|\$\\epsilon\$|g;
    s|&#1013;|\$\\epsilon\$|g;
    s|&#949;|\$\\varepsilon\$|g;
    s|&#950;|\$\\zeta\$|g;
    s|&#951;|\$\\eta\$|g;
    s|&#952;|\$\\theta\$|g;
    s|&#977;|\$\\vartheta\$|g;
    s|&#953;|\$\\iota\$|g;
    s|&#954;|\$\\kappa\$|g;
	s|&#9702;|∞|g;									# &#9702; U+25E6 (White Bullet) used as degree sign
	s|&lambda;|\$\\lambda\$|g;
#    s|\\lambda|\$\\lambda\$|g;
    s|&#955;|\$\\lambda\$|g;
#    s|&#13234;|\$\\mu\$s|g; # µs
    s|&#13234;|µs|g; 		# µs
#    s|&#13211;|\$\\mu\$m|g; # µm
    s|&#13211;|µm|g; 		# µm
	s|&#13212;|mm|g;        # Square Mm CJK Compatibility U+339C &#13212; 

    s|&#61472;|~|g;
    s|&#64256;|ff|g;        # ff-ligature
    s|&#64257;|fi|g;        # fi-ligature
    s|&#64258;|fl|g;        # fl-ligature
    s|&#64259;|ffi|g;       # ffi-ligature
#    s|&mu;|\$\\mu\$|ig;
    s|&mu;|µ|ig;
    s|&#8544;|I|g;          # U+2160 ROMAN NUMERAL ONE
    s|&#8545;|II|g;         # funny II sign for PLS-II (U+2161 ROMAN NUMERAL TWO)
    s|&#8206;||g;           # Left to right mark
    s|||g;                 #don't know what this is
    s||fi|g;               # looks like a fi-ligature
#¸¸¸    s|µ|\$\\mu\$|g;		# changed 180820 for upright µ
#
    s|&#730;|\\high{o}|g;      # degree sign
    s|&deg;|\\high{o}|ig;
    s|&amp;deg;|\\high{o}|ig;
    s|∞|\\high{o}|g;         # degree / number sign??
    s|Ω|\$\\frac{1}{2}\$|g;
    s|&#176;|\\high{o}|g;    # degree / number sign??
    s|&lt;br&gt;|\\newline|g;
#    s/ micro[-| |]ampere[s]{0,1}/  \$\\mu\$A/g;    # changed 130518 due to wrong substitution of " Micro "
    s/ micro[-| |]ampere[s]{0,1}/  µA/g;    # changed 130518 due to wrong substitution of " Micro "
#    s| micro |\$\\mu\$|g;                          # changed 130518 due to wrong substitution of " Micro "
    s| micro |µ|g;                          # changed 130518 due to wrong substitution of " Micro "
#    s|&mu;|\$\\mu\$|ig;
    s|&mu;|µ|ig;
#    s|&amp;mu;|\$\\mu\$|ig;
    s|&amp;mu;|µ|ig;
#    s/([\d| ])micro[-| |]A /$1\$\\mu\$A /g;        # changed 130518 due to wrong substitution of " Micro "
    s/([\d| ])micro[-| |]A /$1µA /g;        # changed 130518 due to wrong substitution of " Micro "
#    s| microsec\b| \$\\mu\$s|ig;
    s| microsec\b| µs|ig;
#    s| usec\b| \$\\mu\$s|ig;
    s| usec\b| µs|ig;
#    s|\\micro|\$\\mu\$|ig;
    s|\\micro|µ|ig;
#    s|&#956;|\$\\mu\$|g;
    s|&#956;|µ|g;
    s|&#61548;|\$\\bullet\$|g;
#    s|&#61549;|\$\\mu\$|g;
    s|&#61549;|µ|g;
    s|&#61550;|\$\\nu\$|g;   # nu (v)
    s|&#957;|\$\\nu\$|g;
    s|&#958;|\$\\xi\$|g;
    s|&#61552;|\$\\pi\$|g;
    s|<pi>|\$\\pi\$|g;
    s|&#960;|\$\\pi\$|g;
    s|&#982;|\$\\varpi\$|g;
    s|&#961;|\$\\rho\$|g;
    s|&#961;|\$\\varrho\$|g;
    s|&#963;|\$\\sigma\$|g;
    s|&#962;|\$\\varsigma\$|g;
    s|&#964;|\$\\tau\$|g;
    s|&#965;|\$\\upsilon\$|g;
    s|&#966;|\$\\phi\$|g;
    s|&#981;|\$\\varphi\$|g;
    s|&#967;|\$\\chi\$|g;
    s|&#968;|\$\\psi\$|g;
    s|&#969;|\$\\omega\$|g;
    s|&#1052;|M|g;              # Russian 'M'
    s|&#1057;|C|g;              # cyrillic "C"
    s|&#1043;|\$\\Gamma\$|g;    # Russian 'Gamma'
    s|&#915;|\$\\Gamma\$|g;
    s|&#8710;|\$\\Delta\$|g;    # wrong code  (U+2206/&#8710;) => INCREMENT should be U+0394|&#916; => GREEK CAPITAL LETTER DELTA
    s|&#61508;|\$\\Delta\$|g;
    s|&#920;|\$\\Theta\$|g;
    s|&#923;|\$\\Lambda\$|g;
    s|&#926;|\$\\Xi\$|g;
    s|&#928;|\$\\Pi\$|g;
    s|&#61523;|\$\\Sigma\$|g;
    s|&#931;|\$\\Sigma\$|g;
    s|&#933;|\$\\Upsilon\$|g;
    s|&#934;|\$\\Phi\$|g;
    s|&#936;|\$\\Psi\$|g;
    s|&#937;|\$\\Omega\$|g;
    s|&#61527;|\$\\Omega\$|g;   # new 090416
    s|&#8486;|\$\\Omega\$|g;
#    s|\\Ohm|\$\\Omega\$|ig;
#    s|\\Mho|\$\\Mho\$|ig;
    s|&#8487;|\$\\Mho\$|ig;
#    s|\\hbar|
#    s|\\imath|&#953;|g;
#    s|\\jmath|j|g;
#    s|\\ell|<i>l</i>|g;
    s|&#8472;|\$\\wp\$|g;
    s|&#8476;|\$\\Re\$|g;
    s|&#8465;|\$\\Im\$|g;
    s|&#8470;|N\\high{o}|g;   #numero (N^o)
    s|&#8242;|\$\\prime\$|g;
    s|&#8243;|\\textit\{\"\}|g;
    s|&#8709;|\$\\emptyset\$|g;
    s|&#8736;|\$\\angle\$|g;
    s|&#8734;|\$\\infty\$|g;
    s|&#8706;|\$\\partial\$|g;
    s|&#8711;|\$\\nabla\$|g;
    s|&#8704;|\$\\forall\$|g;
    s|&#8707;|\$\\exists\$|g;
    s|&#172;|\$\\neg\$|g;
    s|&#8730;|\$\\surd\$|g;
    s|&#8868;|\$\\top\$|g;
    s|&#8869;|\$\\bot\$|g;
#    s|\\|\$\\backslash\$|g;
    s|&#9827;|\$\\clubsuit\$|g;
    s|&#9830;|\$\\diamondsuit\$|g;
    s|&#9829;|\$\\heartsuit\$|g;
    s|&#9824;|\$\\spadesuit\$|g;
#    s|\\dag|f|g;
#    s|\\ddag|<strike>f</strike>|g;
    s|&#167;|\\S|g;
    s|&#182;|\\P|g;
    s|&#169;|\\high{\\copyright}|g;
    s|&#163;|\\pounds|g;
    s|&#9674;|\$\\diamond\$|g;
    s|&#8239;|\$\\Box\$|g;
    s|&#8729;|\\cdot|g;   # \cdot  06.02.2018 changed from "\\cdot\$" to "\\cdot"
    s|&#183;|\\cdot|g;
    s|&#903;|\\cdot|g;
    s|&#8230;|\$\\ldots\$|g;
    s|&#8943;|\\cdots|g;
    s|&#8942;|\$\\vdots\$|g;
    s|&#8945;|\$\\ddots\$|g;
    s|&#63728;|\$\\lfloor\$|g;
    s|&#63726;|\$\\lceil\$|g;
    s|&#9001;|\$\\langle\$|g;
    s|&#63739;|\$\\rfloor\$|g;
    s|&#63737;|\$\\rceil\$|g;
    s|&#9002;|\$\\rangle\$|g;
    s|&#8593;|\$\\uparrow\$|g;
    s|&#8595;|\$\\downarrow\$|g;
    s|&#8657;|\$\\Uparrow\$|g;
    s|&#8659;|\$\\Downarrow\$|g;
    s|&#8804;|\$\\leq\$|g;
    s|&#8805;|\$\\geq\$|g;
    s|&#8810;|\$\\ll\$|g;
    s|&#8811;|\$\\gg\$|g;
    s|&#8834;|\$\\subset\$|g;
    s|&#8835;|\$\\supset\$|g;
    s|&#8838;|\$\\subseteq\$|g;
    s|&#8839;|\$\\supseteq\$|g;
    s|&#8712;|\$\\in\$|g;
    s|&#8715;|\$\\ni\$|g;
    s|&#8801;|\$\\equiv\$|g;
#    s|&#160;&#8764;&#160;|\$\\sim\$|g;
    s|&#8764;|\$\\sim\$|g;
    s|&#8869;|\$\\perp\$|g;
    s|&#8773;|\$\\simeq\$|g;
    s|&#124;&#124;|\$\\parallel\$|g;
    s|&#8776;|\$\\sim\$|g;				# Almost Equal To
    s|&#8773;|\$\\cong\$|g;
    s|&#8800;|\$\\neq\$|g;
    s|&#8733;|\$\\propto\$|g;
#  plus/minus see below "^+}-" substitution
    s|&#61620;|\$\\times\$|g;
    s|&#61627;| =???= |g;
    s|◊|\\times|g;
    s|&times;|\$\\times\$|g;
    s|&#247;|\$\\div\$|g;
    s|&#8727;|\$\\ast\$|g;
#    s|&#8727;|\$\\star\$|g;
#30.07.10    s|∫|\$\\textdegree\$|g;           # degree sign >30.07. conversion removed due to utf-8 chars
    s|&#61616|\$\\degree\$|g;     # degree sign
    s|&#8226;|\$\\bullet\$|g;
    s|&#8745;|\$\\cap\$|g;
    s|&#8746;|\$\\cup\$|g;
    s|&#8744;|\$\\vee\$|g;
    s|&#8743;|\$\\wedge\$|g;
    s|&#9674;|\$\\diamond\$|g;
    s|&#8853;|\$\\oplus\$|g;
    s|&#8855;|\$\\otimes\$|g;
    s|&#8709;|\$\\oslash\$|g;
#    s|\\dagger|f|g;
#    s|\\ddagger|<strike>f</strike>|g;
    s|&#8594;|\$\\longrightarrow\$|g;
    s|&#8592;|\$\\longleftarrow\$|g;
    s|&#8596;|\$\\longleftrightarrow\$|g;
    s|&#8594;|\$\\longmapsto\$|g;
    s|&#8658;|\$\\Longrightarrow\$|g;
    s|&#8656;|\$\\Longleftarrow\$|g;
    s|&#8660;|\$\\Longleftrightarrow\$|g;
    s|&#8592;|\$\\leftarrow\$|g;
    s|&#8656;|\$\\Leftarrow\$|g;
    s|&#8594;|\$\\rightarrow\$|g;
    s|&#8658;|\$\\Rightarrow\$|g;
    s|&#8596;|\$\\leftrightarrow\$|g;
    s|&#8660;|\$\\Leftrightarrow\$|g;
    s|&#8594;|\$\\mapsto\$|g;
    s|&#8593;|\$\\uparrow\$|g;
    s|&#8657;|\$\\Uparrow\$|g;
    s|&#8595;|\$\\downarrow\$|g;
    s|&#8659;|\$\\Downarrow\$|g;
#    s|\\hbar|
    s|&#8736;|\$\\angle\$|g;
    s|&#8818;|\$\\lesssim\$|g;
    s|&#8819;|\$\\gtrsim\$|g;
#
# illegal U+0096 ("-")
#
    if (m/[\s|\w]\x96[\s|\w]/g) {
        s|\s\x96\s| -- |g;         # " - " => en dash
        s|(\d)\x96(\d)|$1--$2|g;   # "3-5" => use en dash
        s|(\w)\x96(\w)|$1-$2|g;    # "per-buffer" => "-"
    }
    s|\x{c296}|--|g;            	#
#
# highlighting __x__
#
    s|__(.*?)__|\{\\bf $1\}|g;
#
#  two with "|"
#
##    s+\\|+&#124;&#124;+g;
    s+\\mid+|+g;
    #
    # curly braces
    # ^{} and _{} substitution (if formula is set in "$"..."$"
    #                           remove these "$" too
    # 21.07.10 .*? changed to .+? like in HTML part
    #
#+    if (m/[\^_]\{[+-]?\d*?\}/ig) {
#+        s|\$?\^\{([+-]?\d*?)\}\$?|\\high{$1}|g;
#+        s|\$?_\{([+-]?\d*?)\}\$?|\\low{$1}|g;
#+    }
	if (0) {
		#
		# block commented out 2017-06-24 (see below)
		#
			if (m/[\^_]\{.+?\}/ig) {
		#<<< 16.04.2009        s|\$?\^\{(.*?)\}\$?|\\high{$1}|g;
		#<<< 16.04.2009        s|\$?_\{(.*?)\}\$?|\\low{$1}|g;
		#                      s|\^\{(.+?)\}|\\high\{$1\}|g;
				s|\^\{(.+?)\}|\\high\{$1\}|g;
				s|_\{(.+?)\}|\\low\{$1\}|g;
			}
	}
	#
	# introduced 2017-06-24
	#
    if (m/\$[\^\_]{1}\\[A-Za-z].+?\$/g) {
        s|\$\^(\\[A-Za-z].+?)\$|\\high\{$1\}|g;
        s|\$\_(\\[A-Za-z].+?)\$|\\low\{$1\}|g;
		print ">>>? $1\n";
    }
    #
    # round braces
    # ^() and _() substitution (if formula is set in "$"..."$"
    #                           remove these "$" too
    # 21.07.10 .*? changed to .+? like in HTML part
    #
    if (m/[\^_]\(.+?\)/ig) {
        s|\^\((.+?)\)|\\high\{$1\}|g;
        s|_\((.+?)\)|\\low\{$1\}|g;
    }
    #
    # simple notation with
    # ^-1 or ^2
    #
	if (m/\^(-?\d+)/g) {
		print DBG "# --($wohe)> [TsupS>] ª$1´ $_\n" unless $debug_restricted;
		s|\^(-?\d+)|\\high\{$1\}|g;
		print DBG "# --($wohe)> [TsupS<] ª$1´ $_\n" unless $debug_restricted;
	}
    #
    # simple notation with
    # ^+ ^-
    #
	if (m/\^(.)/g) {
		print DBG "# --($wohe)> [TsupS+>] ª$1´ $_\n" unless $debug_restricted;
		s|\^(.)|\\high\{$1\}|g;
		print DBG "# --($wohe)> [TsupS+<] ª$1´ $_\n" unless $debug_restricted;
	}
    #
    # ^n like conversion
    # 21.07.10 .*? changed to .+? like in HTML part
    #
    if (m/\^[-+]{0,1}\d+?\D/g) {
        s|\^([-+]{0,1}\d+?)(\D)|\\high\{$1\}$2|g;
    }
    #
    # notation 10e13 or 10^13 or 10e-9 or e+9
    #
    if (m/10[e|\^]([+-]{0,1}\d+)[ .,\/-]/ig) {  # 10e-1233 10^123E 108.49 MHz  10^8.49
        if ($1) {
            s#10[e|\^]([+-]{0,1}\d+)([ .,\/-])#10\\high\{$1\}$2#ig;
            if ($1) { print DBG "# --($wohe)> [1T] ª$1´ $_\n" unless $debug_restricted; }
        }
    }
#
# notation ◊E7 => &times;E7
#
    if (m/&times;E([+-]{0,1}\d+)([ .,\/-])/ig) {
        if ($1) {
            print DBG "# --($wohe)> [sup*E>] ª$1´ ª$2´ ª$3´ $_\n" unless $debug_restricted;
            s#&times;E([+-]{0,1}\d+)([ .,\/-])#∑10\\high\{$1\}$2#ig;
            print DBG "# --($wohe)> [sup*E<] ª$1´ ª$2´ ª$3´ $_\n" unless $debug_restricted;
        }
    }
#
# notation 1e13/1e-13 (special case)
#
    if (m/1e([+-]{0,1}\d+)/ig) {
        if ($1) {
            s#1e([+-]{0,1}\d+)#10\\high\{$1\}#ig;
            if ($1) { print DBG "# --($wohe)> [1-T] ª$1´ $_\n" unless $debug_restricted; }
        }
    }
#
# 6.45E9
#             -> missing is e-9")"
#             120410 corrected for empty (space) $1 argument
#
    if (m/([0-9]{1,}?)E([+-]{0,1}\d{1,2})([ .,\/-])/ig) {
        if ($2) {
#21.07.10   s|(\d*?)E([+-]{0,1}\d{1,2})([ .,\/-])|$1\$\\cdot\$10\\high{$2}$3|ig;
            print DBG "# --($wohe)> [sup5>ltx] ª$1´ ª$2´ $_\n" unless $debug_restricted;
            s|([0-9]{1,}?)E([+-]{0,1}\d{1,2})([ .,\/-])|$1\$\\cdot\$10\\high\{$2\}$3|ig;
            if ($1) { print DBG "# --($wohe)> [2T] ª$1´ ª$2´ ª$3´ $_\n" unless $debug_restricted; }
        }
    }
#
# notation 10-13   (should be corrected in the abstract!)
#                   do not convert ZIP codes and something like X-104
#                                                but still 101.28 MHz
#21.07.10 added check for zero power
#
#30.07.10 if (m|([^0-9])10([+-]{0,1}\d{1,2})([ .,\/-])|g) {
    if (m|([^0-9])10([+-]{0,1}\d{1,2})([ \/-])|g) {
        if ($1) {
            if ($2 ne "0" && $2 ne "00") {
#30.07.10       s|([^0-9])10([+-]{0,1}\d{1,2})([ .,\/-])|$1$ZeHn\\high\{$2\}$3|g;
                s|([^0-9])10([+-]{0,1}\d{1,2})([ \/-])|$1$ZeHn\\high\{$2\}$3|g;
            }
        }
    }
#
# notation 1e13 or 10^13
#? 21.07.10 check and compare with HTML!
#?
#?    if (m|[0-9]e([+-]{0,1}\d+?)[ .,\/-]|ig) {
#?        if ($1) {
#?            s|[0-9]e([+-]{0,1}\d+?)([ .,\/-])|10\\high\{$1\}$2|ig;
#?        }
#?    }
#
# notation 10**13
#
    if (m/10\*\*([+-]{0,1}\d+?)/g) {
        if ($1) {
            s|10\*\*([+-]{0,1}\d+?)([ .,\/-])|10\\high\{$1\}$2|g;
        }
    }
#
# element notation [single letter](\d*?)+
#
    if (m/([a-zA-Z]{1,2})(\d*?)\+/ig) {
        if ($2) {
            s|([a-zA-Z]{1,2})(\d*?)\+|$1\\high\{$2+\}|g;
        }
    }
#
# escape original TeX code like  ^{12}C^{+4}
#
    if (m/\^\{(.*?)\}/g) {
        if ($1) {
            s|\^\{(.*?)\}|\\high\{$1\}|g;
        }
    }
#
# single character subscript _x
#
    s|_(.)|\\low{$1}|g;
#
# sqrt
#
#<<< 16.04.2009
#   s|\\sqrt\{(.*?)\}|\$\\sqrt{\\rm $1}\$|ig;
#
    if (m|\\sqrt\{(.*?)\}|ig) {
        s|\\sqrt\{(.*?)\}|\$\\sqrt{\\rm $1}\$|ig;
    } elsif (m|\\sqrt(.*?) |ig) {
        s|\\sqrt(.*?) |\$\\sqrt{\\rm $1}\$ |ig;
    }
#
# [/*]ohm[/*]
#
    if (m|[/* ]{1,1}ohm[/* ]{1,1}|ig) {
        s|([/* ]{1,1})ohm([/* ]{1,1})|$1\$\\Omega\$$2|ig;
    }
#
# cm+-n
#
    if (m|cm[+-]{0,1}(\d)|g) {
        s|cm([+-]{0,1}\d)|cm\\high{$1}|g;
    }
#
# some other elements (H+ / H- / H0 / e- / e+ / D+)
#
    s|e\+(.{0,1})e-|e\\high{+}$1e\\high{\$-\$}|g;		# added math-mode for longer minus sign  2016-08-24
    s|e-(.{0,1})e\+|e\\high{\$-\$}$1e\\high{+}|g;
#
# Nb3Sn Q0 nanoohm [0-9]\.∞C SiO2 BBr3? H2 Qext  ??
#
    s|Nb3Sn|Nb\\low{3}Sn|g;
    s|Nb2N|Nb\\low{2}N|g;
    s|Cs2Te|Cs\\low{2}Te|g;
    s|CaF2|CaF\\low{2}|g;
    s|Nb\+|Nb\\high{+}|g;
    s| N2| N\\low{2}|g;
    s| H2| H\\low{2}|g;
    s|Nb2O5|Nb\\low{2}O\\low{5}|g;
    s|MgB2|MgB\\low{2}|g;
    s|BBr3|BBr\\low{3}|g;
    s|SiO2|SiO\\low{2}|g;
	s|Q0|Q\\low{0}|g;
	s|HNO3|HNO\\low{3}|g;
	s|H2SO4|H\\low{2}SO\\low{4}|g;
	s|nanoohm|n\$\\Omega\$|g;
	s|nOhm|n\$\\Omega\$|g;
    s|SnCl2|S\\low{n}Cl\\low{2}|g;
	s|Eacc|E\\low{acc}|g;
	s|Qext|Q\\low{ext}|g;
	s|TiO2|TiO\\low{2}|g;
	s|CH4|CH\\low{4}|g;
	s|CO2|CO\\low{2}|g;

##    s|e\+e-|e\\high{+}e\\high{-}|g;    # 120416
    if (m/([a-zA-Z]{1,2})e- /) {
        # don't do anything (it might be something like "one- or two-fold")
    } else {
        s|e- |e\\high{\$-\$} |g;			# added math-mode for longer minus sign  2016-08-24
    }
    s|p\+([ ,/)-])|p\\high{+}$1|g;
    s|e\+ |e\\high{+} |g;
    s|H\+|H\\high{+}|g;
    s|H\^\+|H\\high{+}|g;
    s|H0([ ,/)])|H\\high{0}$1|g;
    s|H2\+|H\\high{2}|g;
    s|H3\+|H\\high{3}|g;
    s|H- |H\\high{\$-\$} |g;
    s|H\^- |H\\high{\$-\$} |g;
    s|H\^&#8722; |H\\high{\$-\$} |g;
    s|&#61485;|\\high{\$-\$}|g;
    s|D\+|D\\high{+}|g;
    if (m/[s|sec]-1[^0-9]/) {
        s#[s|sec]-1#s\\high{\$-1\$}#g;
    }
#
# missing space after punctuation
#
#***    s|(\w)\.([A-Z]{1})|$1.=$2|g;   #***
#***    s|(\w),([A-Z]{1})|$1,\,$2|g;   #***    \, is wrong, should be \\, or just ,
    s|([\(\)\w]{3,})\.([A-Z]{1})|$1.~$2|g;      # wrong quantity for an abstract
#??    s|([\(\)\w]{3,}),([\w]{1})|$1, $2|g;
#??    s|([\w\)]),([\w]{1})|$1, $2|g;
#
# different order, otherwise U73+-ions will be wrong with a "±" after U73
#
#    s|±|\\ensuremath{\\pm}|g;
    s|\+/\-|\\ensuremath{\\pm}|g;
    s|\+\-|\\ensuremath{\\pm}|g;
    s|&#177;|\\ensuremath{\\pm}|g;
#
# diacritical letters (and others)
#
   s|&Acirc;|¬|g;
   s|&acirc;|‚|g;
   s|&Atilde;|√|g;
   s|&atilde;|„|g;
   s|&AElig;|∆|g;
   s|&aelig;|Ê|g;
   s|&Aacute;|¡|g;
   s|&aacute;|·|g;
   s|&Aring;|≈|g;
   s|≈|{\\AA}|g;         # √=Aring Package inputenc Error: Unicode char \u 8:≈I not set up for use with LaTeX
   s|&aring;|Â|g;
   s|&Agrave;|¿|g;
   s|&agrave;|‡|g;
   s|&Auml;|ƒ|g;
   s|&auml;|‰|g;
#
   s|&Ccedil;|«|g;
   s|&ccedil;|Á|g;
#
   s|&Ecirc;| |g;
   s|&ecirc;|Í|g;
   s|&ETH;|–|g;
   s|&eth;||g;
   s|&Egrave;|»|g;
   s|&egrave;|Ë|g;
   s|&Eacute;|…|g;
   s|&eacute;|È|g;
   s|&Euml;|À|g;
   s|&euml;|Î|g;
#
   s|&Icirc;|Œ|g;
   s|&icirc;|Ó|g;
   s|&Iacute;|Õ|g;
   s|&iacute;|Ì|g;
   s|&Iuml;|œ|g;
   s|&iuml;|Ô|g;
   s|&Igrave;|Ã|g;
   s|&igrave;|Ï|g;
#
   s|&Ntilde;|—|g;
   s|&ntilde;|Ò|g;
#Ú
   s|&Ograve;|“|g;
   s|&ograve;|Ú**|g;
   s|&Ouml;|÷|g;
   s|&ouml;|ˆ|g;
   s|&Ocirc;|‘|g;
   s|&ocirc;|Ù|g;
   s|&Otilde;|’|g;
   s|&otilde;|ı|g;
   s|&Oacute;|”|g;
   s|&oacute;|Û|g;
   s|&Oslash;|ÿ|g;
   s|&oslash;|¯*|g;
#
   s|&szlig;|ﬂ|g;
#
   s|&THORN;|ﬁ|g;
   s|&thorn;|˛|g;
#
   s|&Uacute;|⁄|g;
   s|&uacute;|˙|g;
   s|&Ucirc;|€|g;
   s|&ucirc;|˚|g;
   s|&Uuml;|‹|g;
   s|&uuml;|¸|g;
   s|&Ugrave;|Ÿ|g;
   s|&ugrave;|˘|g;
#
   s|&Yacute;|›|g;
   s|&yacute;|˝|g;
   s|&yuml;|ˇ|g;
#
   if (m|#|) {
       if (m|&#|) {
           # nada
       } else {
           s|#|\\#|gs;        # escape
       }
   }
   if (m|&|) {
       if (m|&amp;[^#]|) {
           s|&amp;|\\&|g;
       }
       if (m|&#|) {
           # nada
       }
#070719>       if (m|[^\\]&|) {
#070719>           s|[^\\]&|\\&|gs;        # escape
#070719>       }
   }
#
# ensure Math Mode usage
#
    s|\\bullet|\\ensuremath{\\bullet}|g;  # \bullet
	s|&#9642; |\\ensuremath{\\bullet}~|g;	# square bullet => standard one of LaTeX
    s|\\cdot|\\ensuremath{\\cdot}|g;      # \cdot
    s|\\beta|\\ensuremath{\\beta}|g;    # \beta
    s|\\lambda|\\ensuremath{\\lambda}|g;  # \lambda
#    s|\\mu|{\\textmu}|ig;                 # \mu		#2016-08-21
    s|\\nu|\\ensuremath{\\nu}|g;          # \nu
#    s|\\pi|\\ensuremath{\\piup}|g;        # \pi
    s|\\pi|\\ensuremath{\\pi}|g;          # \pi			#2016-08-21
    s|\\omega|\\ensuremath{\\omega}|g;    # \omega
    s|\\Ohm|\\ensuremath{\\Ohm}|g;        # \Ohm
    s|\\Mho|\\ensuremath{\\Mho}|g;        # \Mho
    s|\\sigma|\\ensuremath{\\sigma}|g;    # \sigma
#
# escape possible problem when Apostrophe meets letter in TeX
#
#>>> no idea 20150707   s|[^\\]"|\{\"\}|g;                     # changed to check for leading \ 110708
   s|&quot;|\"\{\}|g;
   s| "| \"\{\}|g;
   s|" |\"\{\} |g;

#
# should be extended
#
   s| fuer | f\\"{u}r |g;
   s| f\. | f\\"{u}r |g;                  # abbreviation "f." for "f¸r"
   s|CesrTA|CesrTA|ig;                    # CesrTA
   s/DA(F|PH)NE/DA\$\\mathrm{\\Phi}\$NE/g;              # DAPHNE / DAFNE
#   s|DAEdALUS|DAE\$\\mathrm{\\deltaup}\$ALUS|ig;          # DAEdALUS			#2016-08-21
   s|DAEdALUS|DAE\$\\delta\$ALUS|ig;      # DAEdALUS
   s|&#x0141;&#x00f3;d&#x017a;|{\\L}\\'{o}d\\'{z}|g;    # for my Polish friends!
   s|Lodz|{\\L}\\'{o}d\\'{z}|g;           # for my Polish friends!
   s|Krakow|Krak\\'{o}w|g;                # for my Polish friends!
   s|Swierk|\\'{S}wierk|g;                # for my Polish friends!
   s|Poznan|Pozna\\'{e}{n}|g;             # for my Polish friends!
   s|Pecs|P\\'{e}{e}ce|g;                # for my Hungarian friends!
   s|Juelich|J\\"{u}lich|g;
   s|akultaet|akult\\"{a}t|g;
   s|versitaet|versit\\"{a}t|g;
   s|m.b.H.|mbH|g;
   s|Rez|\\v{R}e\\v{z}|g;                 # for my Czech friends!
   s|Jyvaskyla|Jyv‰skyl‰|g;
#    s/micro([-| |]{0,1})sec\b/\$\mu\$$1{}s/ig;
#   s|\\EUR |\\textgreek{\\euro} |ig;
   s|\\EUR |\{\\texteuro\} |ig;
   s|\.\.\.|\$\\ldots\$|ig;
   s|&#1051;&#1071;&#1056;|FLNR|g;        # the FLNR of JINR, Dubna
   s|SCK.CEN|SCK\\ensuremath{\\bullet}CEN|ig;
   s|swissfel|SwissFEL|ig;                # logo for PSI's FEL
   s|berlinpro|B\\textsl{ERL}inPro|ig;    # logo for HZB Linac Project
   s|sflash|sFLASH|ig;                    # logo
   s|Indus\\high\{\$-1\$\}|Indus-1|g;
   s|Phass\\high\{\$-1\$\}|Phase-1|g;
#
# disable some commands which play havoc on the Abstract booklet etc (\author)
#
   s|\\author||i;
   s|\\footnote||i;
#
# edit some list environments
#    the source should look like
#       [+ -)  -)  -)  +]  or
#       [+ 1)  2)  3)  +]  or
#       [+ a)  b)  c)  +]
#
#
    if (m|\[\+|) {
        my $listmode = 0;
        my $iltype   = "";
        my $listline = "";
        if (m|(\[\+.*?\+\])|) {
            $listline = $1;
            if ($listline =~ m|(.)\)|) {
                $listmode = 1;
                my $ilt = $1;
                if ($ilt =~ m|-|) {
                    $iltype = "\\startitemize\[packed,broad,joinedup\]";
                } else {
                    $listmode = 2;
                    if ($ilt =~ m|[aA]|) {
                        $iltype = "\\startitemize\[$ilt,packed,broad,joinedup\]";
                    } else {
                        $iltype = "\\startitemize\[n,packed,broad,joinedup\]";
                    }
                }
                $listline =~ s|\[\+|$iltype|;
            }
            if ($listmode) {
                $listline =~ s|.\)| \\item |g;
                $listline =~ s|\+\]| \\stopitemize |;
            }
            s|\[\+.*?\+\]|$listline|;
        }
    }
#
# new paragraph in Abstracts
# 
    if (m|\[p\]|) {
		s|\[p\]|\\\\[.3\\baselineskip]|g;
	}

#
# help ConTeXt hyphenate (but not --, ---, {-}, or $-$
#
    if ($context_switch) {
        if (m#--|\{-|\$-\$#g) {
            # nada
        } else {
            if (m#\w[/-]\w#) {
                s#([/-])#|$1|#g;
            }
        }
    }
#
# ???????????????????  help ConTeXt hyphenate (but not --, ---, {-}, or $-$
#
    if ($abslatex_switch) {
        if (m#--|\{-|\$-\$#g) {
            # nada
        } else {
            if (m#\w[/-]\w#) {
                s#([/-])#|$1|#g;
            }
        }
    }
#
# get rid of some not used edit marks
#
##    s|\[\+||g;
##    s|\+\]||g;
    s|˜|/|g;
##    s|{(.*?)}|$1|g;
#21.07.10 ??    s|-ZeHn-|10|g;
#30.07.    s|{(.+?)($ZeHn)(.+?)}|$1ZeHn$3|g;
    s|(.+?)($ZeHn)(.+?)|$1ZeHn$3|g;
    s|(.+?)($ZeHn)(.+?)|$1ZeHn$3|g;
    s|ZeHn|10|g;
    s|&nbsp;| |g;         #***> " "
    s|\$\$||g;            #correction for sequencial math mode
    s/-\|\|-\|\|-/---/g;  #sanitize some to strong hyphenation helps
    s/-\|\|-/--/g;        #sanitize some to strong hyphenation helps
#
# correct wrong substitutions
#
    if (m|CLIC([_<\\].*?)DDS|g) {
        print DBG ">c_s_c2t ($wohe) [CLIC]> $1 -- $_\n" unless $debug_restricted;
        s|CLIC<sub>D</sub>DS|CLIC\\_DDS|g;
        s|CLIC\\low\{D\}DS|CLIC\\_DDS|g;
        s|CLIC_DDS|CLIC\\_DDS|g;
    }
    s|SPARC\\low\{L\}AB|SPARC\\_LAB|g;	      # SPARC_LAB
    s|CLIC\\low\{D\}DS|CLIC\\_DDS|g;
    s|PREEMPT\\\\low\{R\}T|PREEMPT\\_RT|g;
    s|PREEMPT\\low\{R\}T|PREEMPT\\_RT|g;
	s|\xa0| |g;            # sanitize "required blanks" by substituting them to "space"
#	s|\\={w}|\\^\{w\}|g;     # w 	      LATIN SMALL LETTER W WITH CIRCUMFLEX (escaped so that there will be no \high{w} in the output
# LATIN SMALL LETTER W WITH CIRCUMFLEX (escaped so that there will be no \high{w} in the output
	s|\\=\{w\}|\\^\{w\}|g;   # w 	      modified 160121 for warning message "Unescaped left brace in regex is deprecated" 
#
# wrong entry for "x_text" => "x\low{text}"
#
	if (m|(\\low\{\\\}text\{(.*?)\}\$)|i) {
		print "*> *> *> ($1--$2)\n";
		s|(\\low\{\\\}text\{(.*?)\}\$)|\\low\{\\text\{$2\}\}\$|ig;
	}
#
# wrong entry for "x^text" => "x\high{\command}" => $\high{\}command$"
#   $\high{\}circ$C =>! $\high{\circ}$C => \high{\circ}C
#
#>	if (m|(\$\\high\{\\\}(.*?)\$)|i) {
#>		print "*< *< *< ($1--$2)\n";
#>		s|(\$\\high\{\\\}(.*?)\$)|\\high\{\\$2\}|ig;
#>	}
#
# <sup>X</sup>
#
	s|<sup>(.+?)</sup>|\\textsuperscript\{$1\}|g;
#
#
# some utf-8 encodings destroyed by single byte corrections
#
    if ($utf_switch) {  #------------------------------- utf-8 -------------------------------
       s|\\oeh|\xc3\x96|g;        #<√ñ|÷>
       s|÷|\xc3\x96|g;            #<√ñ|÷>
    }
#
# no substitutions made in "convert_spec_chars2TeX"
#
    if ($_ eq $in_string) {
		print DBG "<c_s_c2tn ($wohe)> nosubs\n";
	} else {
		print DBG "<c_s_c2ty ($wohe)> $_\n" unless $debug_restricted;
	}

    Deb_call_strucOut ();
    return $_;
}
#---------------------------
# Straiten Author's name (first character) if accented
#
sub straighten_name {

    $_ = $_[0];
    if (m/[A-Z]/i) { return; }
 	Deb_call_strucIn ("straighten_name in($_)");

    s/[ƒ≈¿¡¬√∆]/A/i;
    s/[“”‘’÷ÿ]/O/i;
    s/[Ÿ⁄€‹]/U/i;
    s/[»… À]/E/i;
    s/[ÃÕŒœ]/I/i;
    s/[—]/N/i;
    s/[«]/C/i;
    s/[›ü]/Y/i;
    s/[éè]/Z/i;
	s/\xC3\x85/A/g;
    $_[0] = $_;
    Deb_call_strucOut ();
 }
#-------------------------------
#
# generate an Authors index with links to paper
#     due to problems when switching to utf-8 (XeTeX) for Abstract Booklet production
#     now two files are written (XETAidx only when Abstract booklet is selected)
#       LTXAidx   $content_directory."authtexidx.tex"        LaTeX    iso-8859
#       XETAidx   $content_directory."authbookletidx.tex"    XeTeX    utf-8
#
 sub generate_author_TeXindex {
 	Deb_call_strucIn ("generate_author_TeXindex");

    my $lbl;
    my $file  = $content_directory."authtexidx.tex";
#    open (LTXAidx, ">:encoding(iso-8859-1)", $file)  or die ("Cannot open '$file' -- $! (line ",__LINE__,")\n");
    open (LTXAidx, ">:encoding(UTF-8)", $file)  or die ("Cannot open '$file' -- $! (line ",__LINE__,")\n");
	print LTXAidx "% !TeX encoding = UTF-8\n";

    if ($context_switch) {
        my $ctxtfile = $content_directory."authcontextidx.tex";
#        open (CTXTAidx, ">", $ctxtfile) or die ("Cannot open '$ctxtfile' -- $! (line ",__LINE__,")\n");
        open (CTXTAidx, ">:encoding(UTF-8)", $ctxtfile) or die ("Cannot open '$ctxtfile' -- $! (line ",__LINE__,")\n");
    }
    if ($abslatex_switch) {
        my $ltxfile = $content_directory."authbookletidx.tex";
        open (XETAidx, ">:encoding(UTF-8)", $ltxfile) or die ("Cannot open '$ltxfile' -- $! (line ",__LINE__,")\n");
    }
    my $last_author = "";
	my $last_aid_i  = "";
    my $last_fc     = "";
    my $act_fc;
    my $bf  = "\\TxtNormal";
    my $bfc = "";
    my $cpa = 0;
    my $ji  = 0;
    my @paplist ="";
    print DBG "\n---# TeX Author Index #-----\n";
    for ($ialentry=0; $ialentry<=$author_max_nr; $ialentry++) {
        print DBG sprintf (" #%4i: %s\n", $ialentry, $sorted_all_idx_authors[$ialentry]);
         (my $z, $authname, my $aid, my $c, $pap, my $d, my $e, my $author_fl, my $author_ln8) = split (/∞/, $sorted_all_idx_authors[$ialentry]);
        $authname   =~ s/\s*$//o;
        $author_ln8 =~ s/\s*$//o;
        #
        # $act_fc has first letter (capitalized) of actual name
        #
        $act_fc   = uc substr($authname, 0, 1);
        straighten_name ($act_fc);
        $act_fc   = $_;
        $author_fl=~ s/\s*$//o;
        print DBG sprintf (" #%4i: %30s ~~ %30s ~~ %30s ~~ %30s\n", $ialentry, $author_fl, $main_author[$pap], $author_fl, $author_ln8);
        #
        # compare author_fl (<I.>~<Lastname>) with main_author (<I.>~<Lastname>)
        #
        #
        if ($author_fl eq $main_author[$pap]) {
            $bf  = "\\TxtItalic";
            $bfc = "\\it ";
        } else {
            $bf  = "\\TxtNormal";
            $bfc = "";
        }
        if ($authname ne $last_author || $aid ne $last_aid_i) {
            #
            # new Author gets something special
            #
            $cpa = 0;
            if ($ji > 0) {
                print LTXAidx   " \} \\newline %1\n";
                if ($context_switch) { print CTXTAidx  " \\NC\\SR\n"; }
                if ($abslatex_switch) { print XETAidx  " \\\\\n"; }
            }
            $ji = 0;
            @paplist="";
            if ($last_fc ne $act_fc) {
                #
                # actual letter for register preceded by empty line
                #
                if ($last_fc) {
                    if ($context_switch) { print CTXTAidx " \\stoptabulate\n\n"; }
                    if ($abslatex_switch) { print XETAidx " \\end{tabular}\n\n"; }
                }
                print LTXAidx "\\vspace*{-\\baselineskip}\n\n\\smallskip\n\n\\colorbox{grau}{\\makebox[210pt][l]{\\textbf{--- $act_fc ---}}}\n\n\\vspace*{1mm}\n\n";
                if ($context_switch) {
                    print CTXTAidx " \\subject{$act_fc}\n\n",
                                   " \\starttabulate[|lw(36mm)|pT|]\n";
    #                print CTXTAidx " \\NC                \\NC                   \\NC\\SR\n",
    #                               " \\NC \\JustLeft \\inframed[frame=off, width=fit, offset=-8pt]{\\tfd\\bf $act_fc} \\NC \\NC\\SR\n";
                }
                if ($abslatex_switch) {
                    print XETAidx "\n\\smallskip\n\n\\colorbox{grau}{\\makebox[\\IndxAlphBoxWidth][l]{\\TxtBold{--- $act_fc ---}}}\n\n\\vspace*{1mm}\n\n";
#130820#                    print XETAidx "\n\\smallskip\n\n\\colorbox{grau}{\\makebox[\\IndxAlphBoxWidth][l]{\\TxtBold{\xe2\x80\x94 $act_fc \xe2\x80\x94}}}\n\n\\vspace*{1mm}\n\n";
#101029#                    print XETAidx " \\subsection{$act_fc}\n\n",
#101029#                                  " \\begin{tabular}{|lp(36mm)|l|]}\n";
                }
                $last_fc = $act_fc;
            }
            print DBG "ln8-> $author_ln8\n";
            convert_spec_chars2TeX ($author_ln8, "authname-Ctxt/LTXAidx"); # 0=latin-1
            print DBG "8-2-> $_\n";
            if ($context_switch) {
                print CTXTAidx " \\NC $_ \\NC {$bfc$paper_code[$pap]}";
            }
            revert_from_context ($_);
            print DBG "8rv-> $_\n";
            $lbl = $_;
            $lbl =~ s/[.,\x00-\x40\x5b-\x60\x7b-\xff]/_/g;  # only 0-9,A-Z,a-z, all other converted to "_"
            $lbl =~ s/[\x{0100}-\x{059f}]/-/g;              # all above 0x0100 to 0x059f (Cyrillic) converted to "-"
			$lbl .= $aid;
            print DBG "LTXAidx-label $lbl [$aid]\n";
			#
			# link only for paper_codes with PDF
			#
			if ($paper_with_pdf[$pap] || $conference_pre) {
				$hyperl = "\\hyperlink{lab:$paper_code[$pap]}{$paper_code[$pap]}";
			} else {
				$hyperl = "\\st{$paper_code[$pap]}";
			}
			#
			# if name is too long for 105pt => measure ?!
			#
            print LTXAidx " \\makebox[105pt][l]{\\hypertarget{lab:$lbl}{}$_}% (0)\n",
                          "         \\makebox[130pt][l]{{$bf\{$hyperl}}";
            if ($abslatex_switch) {
                convert_spec_chars2TeX ($author_ln8, "authname-XETAidx", 1); # 1=utf-8
                print XETAidx " \\makebox[\\IndxNameBoxWidth][l]{\\hypertarget{lab:$lbl}{}\\TxtAuthor $_}% (1)\n",
                              "        \\makebox[\\IndxCodeBoxWidth][l]{\\TxtType{$bf\{$hyperl}}}";
            }
        } else {
            if (!grep(/$pap/,@paplist)){
				#
				# link only for paper_codes with PDF
				#
				if ($paper_with_pdf[$pap] || $conference_pre) {
					$hyperl = "\\hyperlink{lab:$paper_code[$pap]}{$paper_code[$pap]}";
				} else {
					$hyperl = "\\st{$paper_code[$pap]}";
				}
				$cpa++;
				if ($cpa % $PPL_ltx) { # modulo papers <paper_code>s in authors' list per line
					print LTXAidx ", {$bf\{$hyperl}}";
				} else {
					print DBG " ? % $PPL_ltx: $authname\n";
#>‰‰‰				revert_from_context ($_);
					print LTXAidx ",\ \} \\newline %2\n",
								  " \\makebox[105pt][l]{}%\n",
								  "         \\makebox[130pt][l]{{$bf\{$hyperl}}";
				}
				if ($context_switch) {
					if ($cpa % $PPL_ctx) {
						print CTXTAidx ", {$bfc$paper_code[$pap]}";
						print DBG "       ? $ % $PPL_ctx: $authname\n";
					} else {
						print CTXTAidx  ", \\NC\\SR\n",
										"  \\NC \\NC {$bfc$paper_code[$pap]}";
					}
				}
				if ($abslatex_switch) {
					if ($cpa % $PPL_xtx) {
						print XETAidx ",{$bf\{$hyperl} }";
					} else {
						print XETAidx ", \ \} \\newline\n",
									  " \\makebox[\\IndxNameBoxWidth][l]{ }%\n",
									  "          \\makebox[\\IndxCodeBoxWidth][l]{\\TxtType$bf {$hyperl} }";
					}
				}
            }
        }
        $ji++;
        $last_author = $authname;
		$last_aid_i  = $aid;
        push(@paplist,$pap);
    }
    if ($context_switch) {
        print CTXTAidx " \\NC\\SR\n",
                       " \\stoptabulate\n\n";
        close CTXTAidx;
    }
    if ($abslatex_switch) {
        print XETAidx  "\} \\newline\n\n";
#101029#        print XETAidx " \\\\\n",
#101029#                      " \\end{tabular}\n\n";
        close XETAidx;
    }
    print LTXAidx  "\ } \\newline %3\n\n";
    close LTXAidx;
 print DBG "---#------------------#-----\n";
 Deb_call_strucOut ();
}

#
# read xml tags and assign values
#
#-----------------------------
sub read_and_interpret_tags {
	#
	# ignored tags follow
	#
	if (m|<?xml|)         { return; }
    if (m|<files>|)       { return; }
    if (m|<file>|)        { return; }
    if (m|<postal_code>|) { return; }
    if (m|<address1>|)    { return; }
    if (m|<address2>|)    { return; }
    if (m|<address3>|)    { return; }
    if (m|<URL>|)         { return; }
    if (m|<po_box>|)      { return; }
    if (m|<zip_code>|)    { return; }
    if (m|<department>|)  { return; }
#
#
	Deb_call_strucIn ("read_and_interpret_tags $_");

    my $key;
#
# tag <paper code="..." pages="...">
#     <paper>
#       <abstract_id>3099</abstract_id>
#       <code>MOAA001</code>
#       <main_class> ... </main_class>
#       <sub_class>  ... </sub_class>  or       <sub_class/>
#       <publishable> ... </publishable>
#       <presentation type="..." option="..."> ... </presentation>
#       <start_time> ... </start_time>
#    	<duration> ... </duration>
#       :
#       : <title><abstract> | <footnote> | <agency> | <contributors> |
#       :
#     </paper>
#
# since March 2013
# ================
#     <paper>
#       <abstract_id>3099</abstract_id>
#       <main_class> ... </main_class>
#       <sub_class>  ... </sub_class>  or       <sub_class/>
#       <publishable> ... </publishable>
#		<program_codes>
#			<program_code>
#				<code>SUPWA001</code>
#				<presentation type="..."> ... </presentation>
#				<start_time> ... </start_time>
#				<duration> ... </duration>
#			</program_code>
#			<program_code>
#				<code>MOAA001</code>
#				<presentation type="..."> ... </presentation>
#			</program_code>
#		</program_codes>
#       :
#       : <title><abstract> | <footnote> | <agency> | <contributors> |
#       :
#     </paper>
#
# since March 2014 (as of 27 March there can be codes with only <code primary="N">, not showing a <code primary="Y"> entry in the group)
# ================
#     <paper>
#       <abstract_id>3099</abstract_id>
#       <main_class> ... </main_class>
#       <sub_class>  ... </sub_class>  or       <sub_class/>
#       <publishable> ... </publishable>
#		<program_codes>
#			<program_code>
#				<code primary="N">SUPWA001</code>
#				<presentation type="..."> ... </presentation>
#				<start_time> ... </start_time>
#				<duration> ... </duration>
#			</program_code>
#			<program_code>
#				<code primary="Y">MOAA001</code>
#				<presentation type="..."> ... </presentation>
#			</program_code>
#		</program_codes>
#       :
#       : <title><abstract> | <footnote> | <agency> | <contributors> |
#       :
#     </paper>
#
    print DBG "|| $_\n";
    if (m|<paper>|) {
        if ($paper_open) {
            croak " opening next paper, while paper '$paper_code[$paper_nr]' is not closed yet (input xml line $.)\n";
        } else {
#140724           $paper_struc  =  1;  # more structures have to be checked ( <code> <main_class> <sub_class> <presentation ...> )
			$institute_nr = -1;  # institute numbering per paper
			$paper_open   =  1;
			$prog_codes   =  0;  # reset program_code assignment
			$paper_nr++;
			#
			# initialize - main/sub classification to black (less errors)
			#            - page numbers to zero
			#            - page start numbers to zero
			#            - dot color reset/set empty
			#            - page start numbers to zero
			#			 - referee status to "n" (none defined)
			#
			$paper_mcls[$paper_nr]		= " ";
			$paper_scls[$paper_nr]  	= " ";
			$paper_pages[$paper_nr]		= 0;        # <pages> will fill it
			$paper_dotc[$paper_nr] 		= "";       # <dot> will fill it
			$page_start[$paper_nr]		= 0;        # <toc> will fill it
			$presentation_type 			= 0;		# 0=Poster 1=Oral
			$referee_stat[$paper_nr]	= "n";      # <referee_status ...> will fill it when present
			$paper_recv[$paper_nr]		= "";		# paper received date-time (22-Mar-2019 10:23:55) processed from <log_status code="FUP">File Uploaded</log_status> record
			$paper_acpt[$paper_nr]		= "";		# paper accepted date-time (22-Mar-2019 10:23:55) processed from <log_status code=\"FQ">Final QA Passed</log_status> record
			#
			# store first paper entry for actual open session
			#
			if ($session_start) {
				$session_startp[$session_nr]	= $paper_nr;
				$session_endp[$session_nr]		= $paper_nr - 1;
				$session_start					= 0;
			}
        }
		Deb_call_strucOut ();
        return;
    }
#++++++++++++++++++++++++++++
#
# tag <abstract_id>...</abstract_id>
#
#    if (m|<abstract_id>\s*(.*?)</abstract_id>|) {
#
#  there is a phase in the conference where abstracts are there but no
#  paper_codes have been assigned yet. To process such a conference, we
#  accept abstract_ids as paper_codes. abstract_ids are automatically
#  overwritten, when a paper_code has been assigned.
#
#++++++++++++++++++++++++++++
#
# tag <abstract_id>...</abstract_id>
#
    if (m|<abstract_id>\s*(.*?)\s*</abstract_id>|) {
		$abstr_id = $1;
 #140724       if ($paper_struc) {
			# obviously nevere used 160130 $id_abstract{$abstr_id}  = $paper_nr;
			$abs_id[$paper_nr] = $abstr_id;
##            print ">1< abstract_id: $abstr_id\n";
#140724        } else {
#140724            croak " defining abstract id '$abstr_id' while no paper is open (anymore) in line $.\n";
#140724        }
		Deb_call_strucOut ();
        return;
    }
#++++++++++++++++++++++++++++
#
# tag <program_codes>
#
	if (m|<program_codes>|) {
		if (!$xml_program_codes) { 
			#
			# found new multiple program code XML 
			# (only multiple codes have the tag "<program_codes>"
			#
			$xml_program_codes = 1; 
			print DBG "\n found new multiple program code XML\n\n";
		}
		if ($prog_codes) {
			croak " starting program codes for abstract_id '$abstr_id' while last program code assignment hasn't been finished in line $.\n";
		} else {
			#
			# open program code assignment
			#   and reset assignment index ($prg_idx)
			#
			$prog_codes =  1;
			$prg_idx    = -1;
		}
		Deb_call_strucOut ();
		return;
	}
#++++++++++++++++++++++++++++
#
# tag <program_code>
#
#>	if (m|<program_code>|) {
#>		if (!$prog_codes) {
#>			croak " starting program codes for abstract_id '$abstr_id' while program code assignment hasn't been opened in line $.\n";
#>		} else {
#>			#
#>			# increment assignment index ($prg_idx)
#>			#
#>			$prg_idx++;
#>		}
#>		Deb_call_strucOut ();
#>		return;
#>	}
#++++++++++++++++++++++++++++
#
# tag </program_codes>
#
	if (m|</program_codes>|) {
		my $code_cnt = $#{$prg_code[$paper_nr]} + 1;
#		print " ------------: $code_cnt + $prog_codes\n";
		if ($prog_codes && $code_cnt > 1) {
			#
			# compare Session with Code and assign
			# corresponding Paper_id to $paper_code
			#
			$i = 0;
			while ($i < $code_cnt) {
				my $prg_sess = substr($prg_code[$paper_nr][$i], 0, length($session_abbr[$session_nr]));
				if ($prg_sess eq $session_abbr[$session_nr]) {
					$paper_code[$paper_nr] = $prg_code[$paper_nr][$i];
				    $talk_btime[$paper_nr] = $prg_btim[$paper_nr][$i];
					$talk_etime[$paper_nr] = $prg_etim[$paper_nr][$i];
					$talk_duration[$paper_nr] = $prg_dura[$paper_nr][$i];
					print DBG " -S-A->$session_abbr[$session_nr]< -->$prg_code[$paper_nr][$i]<\n";
					last;
				} else {
					print DBG " -S-A->$session_abbr[$session_nr]< ~~>$prg_code[$paper_nr][$i]<\n";
					$i++;
				}
			}
		} else {
			#
			# single paper code entry
			#
			$paper_code[$paper_nr] = $prg_code[$paper_nr][0];
			$talk_btime[$paper_nr] = $prg_btim[$paper_nr][0];
			$talk_etime[$paper_nr] = $prg_etim[$paper_nr][0];
			$talk_duration[$paper_nr] = $prg_dura[$paper_nr][0];
		}
		$prog_codes = 0; 		# reset for next paper
		Deb_call_strucOut ();
		return;
	}
#++++++++++++++++++++++++++++
#
# tag <code>...</code>
#
#    if (m|<code>\s*(.*?)</code>|)
#
#++++++++++++++++++++++++++++
#
# tag <code>...</code>
#   or
# tag <code primary="x">...</code>
#
    if (m|<code(.*?)>\s*(.*?)</code>|) {
#140724        if ($paper_struc) {
			#
			# old or new XML structure [different program_codes?]
			#
			if ($prog_codes) {
				#
				# new XML with primary code "Y"es or "N"o
				#
				$prg_idx++;
				$prg_code[$paper_nr][$prg_idx] = uc $2;
				#
				# do we have to skip a paper?
				#
				if ($paper_skip_list_anz > 0) {
					#
					# there are papers to skip, is this paper in the list?
					#
					$skip_this_paper = 0;
					for ($i=0; $i<$paper_skip_list_anz; $i++) {
						if ($paper_skip_list[$i] eq $prg_code[$paper_nr][$prg_idx]) {
							$skip_this_paper = 1;
							last;
						}
					}
					if ($skip_this_paper) {
						Deb_call_strucOut ();
						return;
					}
				}
				#
				# paper stays, now check for Primary No/Yes
				#
				my $y_test;
				my $prgcodep = " ";
				if ($1 ne "") {
					print DBG "prg_code: $1\n";
					$y_test = ($1 =~ m|primary=\"Y\"|i);
					if ($y_test) {
						#
						# PRIMARY
						#
						$prg_code_p[$paper_nr]  = $prg_idx;
						$prgcodep				= $prg_code_p[$paper_nr];
					}
				}
				print DBG " +P+A+> $1 ($2) Paper:$paper_nr Index:$prg_idx (prg_code_p: $prgcodep) -- $prg_code[$paper_nr][$prg_idx]\n";
			} else {
				#
				# old XML
				#
				$paper_code[$paper_nr] = uc $2;
##     			print ">2< code   : $2\n";
				print POSTOUT "<$paper_code[$paper_nr]>\n";
			}
#140724		} else {
#140724            croak " defining paper code '$2' while no paper is open (anymore) in line $.\n";
#140724        }
 		Deb_call_strucOut ();
        return;
    }
#
# <presentation type="xxxx">yyyy</presentation> xxxx is "Oral" or "Poster"; yyyy is more specific (Invited/Contributed/...)
#
    if (m|<presentation type="\s*(.*?)\s*">\s*(.*?)\s*</presentation>|) {
		if ($1 =~ m|Oral|i) {
			$presentation_type 		= 1;		# 0=Poster 1=Oral
		}
		Deb_call_strucOut ();
        return;
    }
#
# <start_time> ... </start_time> xxxx is the hour in 24h format: 1130 is 11:30
#
    if (m|<start_time>\s*(.*?)\s*</start_time>|) {
		#
		# is it an Oral? ~SPMS 10.4.10 introduced btime/etime/duration for Posters (do we need them?)
		#
		if ($presentation_type) {
			#
			# old or new XML structure [different program_codes?]
			#
			if ($prog_codes) {
				$prg_btim[$paper_nr][$prg_idx] = $1;
			} else {
				$talk_btime[$paper_nr] = $1;
			}
		}
		Deb_call_strucOut ();
        return;
    }
#
# <duration> ... </duration> xx is the duration of the talk in minutes
#
    if (m|<duration>\s*(.*?)\s*</duration>|) {
		#
		# is it an Oral? ~SPMS 10.4.10 introduced btime/etime/duration for Posters (do we need them?)
		#
		if ($presentation_type) {
			#
			# old or new XML structure [different program_codes?]
			#
			if ($prog_codes) {
				$prg_dura[$paper_nr][$prg_idx] = $1;
				my $prg_et = $prg_btim[$paper_nr][$prg_idx] + $prg_dura[$paper_nr][$prg_idx];
				if ($prg_et % 100 >= 60) {
					$prg_et += 40;
				}
				$prg_btim[$paper_nr][$prg_idx] = sprintf ("%.2d:%.2d", int($prg_btim[$paper_nr][$prg_idx]/100), $prg_btim[$paper_nr][$prg_idx] % 100);
				$prg_etim[$paper_nr][$prg_idx] = sprintf ("%.2d:%.2d", int($prg_et / 100), $prg_et % 100);
			} else {
				$talk_duration[$paper_nr] = $1;
				$talk_etime[$paper_nr]    = $talk_btime[$paper_nr] + $talk_duration[$paper_nr];
				if ($talk_etime[$paper_nr] % 100 >= 60) {
					$talk_etime[$paper_nr] += 40;
				}
		##        		print " $paper_nr: $talk_btime[$paper_nr] $talk_etime[$paper_nr] $talk_duration[$paper_nr]\n";
				$talk_btime[$paper_nr] = sprintf ("%.2d:%.2d", int($talk_btime[$paper_nr]/100), $talk_btime[$paper_nr] % 100);
				$talk_etime[$paper_nr] = sprintf ("%.2d:%.2d", int($talk_etime[$paper_nr]/100), $talk_etime[$paper_nr] % 100);
		##        		print " $paper_nr: $talk_btime[$paper_nr] $talk_etime[$paper_nr] $talk_duration[$paper_nr]\n";
			}
		}
		Deb_call_strucOut ();
        return;
    }
#?#
#?# test page numbers are generated here
#?#
#¸        $paper_pages[$paper_nr] = 3;
#¸        if (substr($paper_code[$paper_nr], 2, 1) ne "P") {
#¸            $paper_pages[$paper_nr] = 5;
#¸        }
#¸        if ($paper_nr >= 0) {
#¸            $page_start[$paper_nr + 1] = $page_start[$paper_nr] + $paper_pages[$paper_nr];
#¸        }
#¸        print DBG "~~> page #pap($paper_nr): $page_start[$paper_nr] -- $paper_pages[$paper_nr]\n";
#
# tag <main_class>
#
    if (m|<main_class>\s*(.*?)\s*</main_class>|) {
#140724        if ($paper_struc) {
            $paper_mcls[$paper_nr] = $1;
#140724        } else {
#140724            croak " defining paper main_class '$1' while no paper is open (anymore) in line $.\n";
#140724        }
		Deb_call_strucOut ();
        return;
    }
#
# tag <sub_class>
#
    if (m|<sub_class>\s*(.*?)\s*</sub_class>|) {
#140724        if ($paper_struc) {
            $paper_scls[$paper_nr] = $1;
#140724        } else {
#140724            croak " defining paper sub_class '$1' while no paper is open (anymore) in line $.\n";
#140724        }
		Deb_call_strucOut ();
        return;
    }
#
# tag <sub_class/> defines no subclassification
#
    if (m|<sub_class/>|) {
#140724        if ($paper_struc) {
            $paper_scls[$paper_nr] = " ";
#140724        } else {
#140724            croak " defining paper sub_class '$1' while no paper is open (anymore) in line $.\n";
#140724        }
		Deb_call_strucOut ();
        return;
    }
#
# tag <publishable> defines whether it's ready to be published or not
#     <publishable>No, Editor Status Code is not Publishable, Final QA Failed</publishable>
#     <publishable>No, Editor Status Code is not Publishable, Final QA Not Publishable</publishable>
#     
#     <publishable>No, Final QA Pending</publishable>
#     <publishable>Yes</publishable>
#
# through Secondary paper codes (PRIMARY="N") we get more publishable ones than available
#         therefore the none-Primary ones are not counted but that has to come at a later 
#         stage as here we do not know about primary/secondary paper code
#
    if (m|<publishable>\s*(.*?)\s*</publishable>|) {
#140724        if ($paper_struc) {
            if (substr($1, 0, 3) eq "Yes") {
                $paper_pub[$paper_nr] = 1;
            } else {
                $paper_pub[$paper_nr] = 0;
            }
#            print DBG "$paper_nr:>$paper_code[$paper_nr]< Status: $1\n";  paper code not defined before publishable status
            print DBG "$paper_nr: Status: $1\n";
#140724        } else {
#140724            croak " defining paper publishable '$1' while no paper is open (anymore) in line $.\n";
#140724        }
		Deb_call_strucOut ();
        return;
    }
#
# <dot>Green</dot> Status of Paper
#
    if (m|<dot>\s*(.*?)\s*</dot>|) {
        $paper_dotc[$paper_nr] = $1;
		Deb_call_strucOut ();
        return;
    }
#
# <pages>xxx<pages/> number of pages
#
    if (m|<pages>\s*(.*?)\s*</pages>|) {
        $paper_pages[$paper_nr] = $1;
		Deb_call_strucOut ();
        return;
    }
#
# <pages/> number of pages unknown
#
    if (m|<pages/>|) {
		Deb_call_strucOut ();
        return;
    }
#
# tag <toc> start page number
#
    if (m|<toc>\s*(.*?)\s*</toc>|) {
        $page_start[$paper_nr] = $1;
        print DBG "~~> page #pap($paper_nr): $page_start[$paper_nr] -- $paper_pages[$paper_nr]\n";
		Deb_call_strucOut ();
        return;
    }
#
# tag <toc/> start page number is empty/unknown
#
    if (m|<toc/>|) {
        print DBG "--> page #pap($paper_nr): $page_start[$paper_nr] -- $paper_pages[$paper_nr]\n";
		Deb_call_strucOut ();
        return;
    }
#
# tag </paper>
#
    if (m|</paper>|) {
        if ($paper_open) {
           $paper_open = 0;
           #
           # postprocess author and institute info (store into combinedauthors)
           #
#‰           print DBG "+++ </paper> vor combine_authors\n",
#‰                     "+++ #Authors: ",$authors[$paper_nr]+1,"\n",
#‰                     "+++ page start #pap($paper_nr): $page_start[$paper_nr]\n";
           combine_authors_institutes ();
        } else {
           croak " closing paper while no paper is open in line $.\n";
        }
		#
		# has a paper_code been assigned or are we
		# still in the abstract phase
		#
		if (!$paper_code[$paper_nr] || $paper_code[$paper_nr] eq "") {
			$paper_code[$paper_nr] = $abstr_id;
		}
		if ($referee_stat[$paper_nr] ne "n") {
#			print "--- $paper_code[$paper_nr] is $referee_stat[$paper_nr]\n";
		}
		$prg_idx    = -1;
		Deb_call_strucOut ();
        return;
    }
#
# check for <abstract> of this paper
#
    #
    # one line abstract
    #
    if (m|<abstract>\s*(.*?)\s*</abstract>|) {
        $abstract_text = $1;
        print DBG " Abs (sgl): $1\n" unless $debug_restricted;
        #
        # built in for InDiCo-Sessions without abstracts
        #
        if ($abstract_text eq "") {
            if ($abstract_insert) {
                #
                # inclusion of external Abstract is selected
                #         get Abstract for paper from "<paper_code>.abs"
                #
                print DBG "######>>>>>>>>> $paper_code[$paper_nr]\n";
                read_external_abs ($paper_code[$paper_nr]);
                print DBG "==$abstract_text\n";
                $paper_abs[$paper_nr] = $abstract_text;
            } else {
                #
                # Standard text is "no abstract available" ,
                #          define omission text in config file
                #
                ($paper_abs[$paper_nr] = $abstract_omission_text) =~ s/^\"(.*?)\"$/$1/s;
                print " NoAbs >$1< \n";
            }
        } else {
            $paper_abs    [$paper_nr] = $abstract_text;
            print DBG " whole Abs (sgl): $abstract_text\n" unless $debug_restricted;
        }
		#
		# convert Abstract to encoded text (UTF-8, LaTeX)
		#
        $paper_abs_utf[$paper_nr] = convert_spec_chars     ($paper_abs[$paper_nr], "<-abstract->");
        $paper_abs_ltx[$paper_nr] = convert_spec_chars2TeX ($paper_abs[$paper_nr], "<-abstract->");

		$abstract_open = 0;
		Deb_call_strucOut ();
        return;
    }
    #
    # more than one abstract line
    #
    if (m/<abstract>(.*?)$/) {
        $abstract_open = 1;
        $abstract_text = $1;
        print DBG " first Abstract line with: $1\n" unless $debug_restricted;
		Deb_call_strucOut ();
        return;
    }
    if (m|(.*?)</abstract>|) {
        print DBG " Abs (end): $1\n";
        if($abstract_open) {
            $abstract_text .= " $1";
            print DBG " whole Abs (mul): $abstract_text\n" unless $debug_restricted;
            $paper_abs[$paper_nr] = $abstract_text;
            $abstract_open = 0;
        } else {
            croak " Closing a not opened <abstract> in line $.\n";
        }
		Deb_call_strucOut ();
        return;
    }
#
# check for <agency> of this paper
#
    #
    # one line agency
    #
    if (m|<agency>\s*(.*?)\s*</agency>|) {
        $paper_agy[$paper_nr] = $1;
        print DBG " whole Agency: $1\n";
        $agency_open = 0;
		Deb_call_strucOut ();
        return;
    }
    #
    # more than one agency line
    #
    if (m/<agency>(.*?)\s*$/) {
        $agency_open = 1;
        $agency_text = $1;
		Deb_call_strucOut ();
        return;
    }
    if (m|(.*?)</agency>|) {
        if($agency_open) {
            $agency_text .= $1;
            $paper_agy[$paper_nr] = $agency_text;
            print DBG " whole Agency  : $agency_text\n";
            $agency_open = 0;
        } else {
            croak " Closing a not opened <agency> in line $.\n";
        }
		Deb_call_strucOut ();
        return;
    }
#
# check for <footnote> of this paper
#
    #
    # one line footnote
    #
    if (m|<footnote>\s*(.*?)\s*</footnote>|) {
        $paper_ftn[$paper_nr] = $1;
        print DBG " whole Footnote: $1\n";
        $footnote_open = 0;
		Deb_call_strucOut ();
        return;
    }
    #
    # more than one footnote line
    #
    if (m/<footnote>(.*?)\s*$/) {
        $footnote_open = 1;
        $footnote_text = "$1\\Space ";
		Deb_call_strucOut ();
        return;
    }
    if (m|(.*?)</footnote>|) {
        if($footnote_open) {
            $footnote_text .= $1;
            $paper_ftn[$paper_nr] = $footnote_text;
            print DBG " whole Footnote: $footnote_text\n";
            $footnote_open = 0;
        } else {
            croak " Closing a not opened <footnote> in line $.\n";
        }
		Deb_call_strucOut ();
        return;
    }
#
# tags <title>...</title>
#
    #
    # one line title
    #
    if (m|<title>\s*(.*?)\s*</title>|) {
        $title[$paper_nr] = $1;
        print DBG " whole Title (sgl): $1\n";
        $title_open = 0;
		Deb_call_strucOut ();
        return;
    }
    #
    # more than one title line
    #
    if (m/<title>(.*?)\s*$/) {
        $title_open = 1;
        $title_text = $1;
		Deb_call_strucOut ();
        return;
    }
    if (m|(.*?)</title>|) {
        if($title_open) {
            $title_text .= $1;
            $title[$paper_nr] = $title_text;
            print DBG " whole Title (mul): $title_text\n";
            $title_open = 0;
        } else {
            croak " Closing a not opened <title> in line $.\n";
        }
		Deb_call_strucOut ();
        return;
    }
#
# look for Referee status changes in <referee_status code="?">
#      this code can appear in <abstract_log> (SPMS 11.1.05) with
#		1)	<log_status code="DR">Dot Reassignment</log_status>
#		2)  <log_status code="REF">Referee</log_status> 
# the first one is probably dangerous, but happened in IPAC'18
#
# <referee_status code="d">declined</referee_status>
#
    if (m|<referee_status code="\s*(.*?)\s*">\s*(.*?)\s*</referee_status>|) {
		my $code = $1;
		my $codl = $2;
		if ($code =~ /[acd]/i) {
			$referee_stat[$paper_nr] = $code;
			print DBG "--- $paper_code[$paper_nr] is $referee_stat[$paper_nr]\n";
		} else {
			print DBG "~~~unexpected $code - $codl for $paper_code[$paper_nr]\n";
		}
		Deb_call_strucOut ();
        return;
    }
#
# Check file received date-time from <log_status code="FUP">File Uploaded</log_status> record
#	next record contains date and time
#
    if (m|<log_status code=\"FUP\">File Uploaded</log_status>| && $paper_recv[$paper_nr] eq "") {
		# next record has the date-time in format "<timestamp>18-Sep-2018 02:19:06</timestamp>"
		my $nextline = <PLIN>;
		if ($nextline =~ m|<timestamp>\s*(.*?)\s*</timestamp>|) {
			$paper_recv[$paper_nr] = $1;
			print DBG sprintf (" Paper %9s  received: %20s\n", $paper_code[$paper_nr], $paper_recv[$paper_nr]);
#			print     sprintf (" Paper %9s  received: %20s\n", $paper_code[$paper_nr], $paper_recv[$paper_nr]);
		}
		Deb_call_strucOut ();
        return;
    }
#
# Check Final QA Passed date-time from <log_status code="FQ">Final QA Passed</log_status> record
#	next record contains date and time
#
    if (m|<log_status code=\"FQ\">Final QA Passed</log_status>|) {
		# next record has the date-time in format "<timestamp>18-Sep-2018 02:19:06</timestamp>"
		my $nextline = <PLIN>;
		if ($nextline =~ m|<timestamp>\s*(.*?)\s*</timestamp>|) {
			$paper_acpt[$paper_nr] = $1;
			print DBG sprintf (" Paper %9s  accepted: %20s\n", $paper_code[$paper_nr], $paper_acpt[$paper_nr]);
#			print     sprintf (" Paper %9s  accepted: %20s\n", $paper_code[$paper_nr], $paper_acpt[$paper_nr]);
		}
		Deb_call_strucOut ();
        return;
	}
#
# tag <keywords>...</keywords>
#  or <keyword>...</keyword>
#  or <keyword>
#   + </keyword>
#
#ﬂﬂ    if (m|keyword|) {
#ﬂﬂ        #
#ﬂﬂ        # tag <keywords>
#ﬂﬂ        #
#ﬂﬂ        if (m|<keywords>|) {
#ﬂﬂ            if ($keyword_open) {
#ﬂﬂ                croak " keywords already open for paper '$paper_code[$paper_nr]' in line $.\n";
#ﬂﬂ            } else {
#ﬂﬂ                $keyword_open = 1;
#ﬂﬂ            }
#ﬂﬂ	           Deb_call_strucOut ();
#ﬂﬂ            return;
#ﬂﬂ        }
#ﬂﬂ
#ﬂﬂ        #
#ﬂﬂ        # tag </keywords>
#ﬂﬂ        #
#ﬂﬂ        if (m|</keywords>|) {
#ﬂﬂ            if ($keyword_open) {
#ﬂﬂ                $keyword_open = 0;
#ﬂﬂ            } else {
#ﬂﬂ                croak " keywords already closed for paper '$paper_code[$paper_nr]' in line $.\n";
#ﬂﬂ            }
#ﬂﬂ            Deb_call_strucOut ();
#ﬂﬂ            return;
#ﬂﬂ        }
#ﬂﬂ
#ﬂﬂ
#ﬂﬂ        if (m|<keyword>(.*?)</keyword>|) {
#ﬂﬂ            if ($keyword_open) {
#ﬂﬂ                $key = $1;
#ﬂﬂ                 push (@{$keywords[$paper_nr]}, $key);
#ﬂﬂ            } else {
#ﬂﬂ                croak " keywords not open for paper '$paper_code[$paper_nr]' in line $.\n";
#ﬂﬂ            }
#ﬂﬂ            Deb_call_strucOut ();
#ﬂﬂ            return;
#ﬂﬂ        } else {
#ﬂﬂ            $keyw_open = 1;
#ﬂﬂ            Deb_call_strucOut ();
#ﬂﬂ            return;
#ﬂﬂ        }
#ﬂﬂ
#ﬂﬂ        if (m|</keyword>|) {
#ﬂﬂ            $keyw_open = 0;
#ﬂﬂ            print DBG " keyword collection : $keyw_text\n";
#ﬂﬂ            #push (@{$keywords[$paper_nr]}, $key);
#ﬂﬂ            Deb_call_strucOut ();
#ﬂﬂ            return;
#ﬂﬂ        }
#ﬂﬂ    }
#
# tag <institutions>
#     <institutions>            => Chair
#     <institutions>            => Owner
#     <institutions ckey="PRI"> => Primary Author
#     <institutions ckey="PRE"> => Presenter
#     <institutions ckey="COA"> => Co-Author
#
# paper[paper_nr][institute][author]
# institute[paper_nr][author_nr]
#
    if (m|<institutions|) {   # gets all types
        $institute_open =  1;
        $institute_nr   = -1;
		Deb_call_strucOut ();
        return;
    }
    if (m|</institutions>|) {
        $institute_open = 0;
        #
        # check author's initial (</institutions> is the first place to do the check)
        #
        my $ini;
        if ($person_mode == $CONTRIBUTOR) {
            if (!defined $contrib_ini[$paper_nr][$contrib_nr]) {  # special InDiCo
                $key = "";
            } else {
                $key = $contrib_ini[$paper_nr][$contrib_nr];
            }
            if ($key eq "" || $key eq ".") {
                $ini = substr($contrib_fst[$paper_nr][$contrib_nr], 0, 1);
                print DBG "==========> empty ª$key´ initial in paper:contrib ª$paper_nr:$contrib_nr´ substituted by ª$ini.´\n";
                $key = "$ini.";
            }
            $contrib_ini[$paper_nr][$contrib_nr] = $key;
        } elsif
            ($person_mode == $PRESENTER) {
            if (!defined $presenter_ini[$paper_nr]) {            # copy from above: therefore anything => special InDiCo ?
                $key = "";
            } else {
                $key = $presenter_ini[$paper_nr];
            }
            if ($key eq "" || $key eq ".") {
                $ini = substr($presenter_fst[$paper_nr], 0, 1);
                print DBG "==========> empty ª$key´ initial in paper:presenter ª$paper_nr:$contrib_nr´ substituted by ª$ini.´\n";
                $key = "$ini.";
            }
            $presenter_ini[$paper_nr] = $key;
        }
        #
        # check presence of institute info
        #
        if
           ($person_mode == $CONTRIBUTOR && !defined $contrib_ins[$paper_nr][$contrib_nr]) {
            $contrib_ins[$paper_nr][$contrib_nr] ="";
            $contrib_abb[$paper_nr][$contrib_nr] ="";
            print DBG "-- missing institute for CONTRIBUTOR #Pap:$paper_nr #Contr:$contrib_nr\n";
        } elsif
           ($person_mode == $CHAIR && !defined $chair_inst_name[$session_nr][$chair_nr]) {
            $chair_inst_name[$session_nr][$chair_nr] = "";
            $chair_inst_abb[$session_nr][$chair_nr] = "";
            print DBG "-- missing institute for CHAIR[$chair_nr] #Session:$session_nr\n";
        } elsif
           ($person_mode == $PRESENTER && !defined $presenter_ins[$paper_nr]) {
            $presenter_ins[$paper_nr] = "";
            $presenter_abb[$paper_nr] = "";
            print DBG "-- missing institute for PRESENTER #Pap:$paper_nr\n";
        }
		Deb_call_strucOut ();
        return;
    }
#
# tag <institute>
#
    if (m|<institute>|) {
        if ($institute_open) {
            $institute_nr++;
            #
            # empty parts of which affiliation abbreviation is constructed
            #
            $affil_abbr   = "-";
			#
			# create a new Author set when this is an additional affiliation
			#      'static' data are copied, UTF8 names, email address and
			#      institute are coming in later fields
			#
			print DBG "<institute> incr:$institute_nr mode:$person_mode (line:$.)\n";
			if ($institute_nr > 0 && $person_mode ne $OTHER) {
				$contrib_nr++;
				print DBG "<inst-new set> inst:$institute_nr  contrib:$contrib_nr ($paper_code[$paper_nr])\n";
				$contrib_ini[$paper_nr][$contrib_nr] = $contrib_ini[$paper_nr][$contrib_nr-1];
				$contrib_lst[$paper_nr][$contrib_nr] = $contrib_lst[$paper_nr][$contrib_nr-1];
				$contrib_fst[$paper_nr][$contrib_nr] = $contrib_fst[$paper_nr][$contrib_nr-1];
				$contrib_mna[$paper_nr][$contrib_nr] = $contrib_mna[$paper_nr][$contrib_nr-1];
				$contrib_aid[$paper_nr][$contrib_nr] = $contrib_aid[$paper_nr][$contrib_nr-1];
				$contrib_typ[$paper_nr][$contrib_nr] = $contrib_typ[$paper_nr][$contrib_nr-1];
				# $contrib_ins + $contrib_abb will be filled with the new Institute later
			}
        }
		Deb_call_strucOut ();
        return;
    }
#
# tag </institute>
#
    if (m|</institute>|) {
        if
           ($person_mode == $CONTRIBUTOR) {
            print DBG "-^-closing CONTRIBUTOR #Pap:$paper_nr #Contr:$contrib_nr #Inst:$institute_nr -> $contrib_ins[$paper_nr][$contrib_nr]\n\n";
        } elsif
           ($person_mode == $CHAIR) {
           if ($chair_inst_name[$session_nr][$chair_nr]) {
                print DBG "-^-closing CHAIR[$chair_nr] #Session:$session_nr -> $chair_inst_name[$session_nr][$chair_nr]\n\n";
           }
        } elsif
           ($person_mode == $PRESENTER) {
            print DBG "-^-closing PRESENTER #Pap:$paper_nr -> $presenter_ins[$paper_nr]\n\n";
        }
		Deb_call_strucOut ();
        return;
    }
#
# tag <town>
#
#‰    if (m|<town>|) {
#‰        if (m|<town>\s*(.*?)\s*</town>|) {
#‰            if      ($person_mode == $CONTRIBUTOR) {
#‰                $contrib_abb[$paper_nr][$contrib_nr] .= ", $1";
#‰                print DBG " appending town ª$1´ to inst-abbr ª$contrib_abb[$paper_nr][$contrib_nr]´ in line $.\n";
#‰            } elsif ($person_mode == $CHAIR) {
#‰                $chair_inst_abb[$session_nr][$chair_nr] .= ", $1";
#‰                print DBG " appending town ª$1´ to inst-abbr ª$chair_inst_abb[$session_nr][$chair_nr]´ in line $.\n";
#‰            } elsif ($person_mode == $PRESENTER) {
#‰                $presenter_abb[$paper_nr] .= ", $1";
#‰                print DBG " appending town ª$1´ to inst-abbr ª$presenter_abb[$paper_nr]´ in line $.\n";
#‰            }
#‰        }
#‰         Deb_call_strucOut ();
#‰        return;
#‰    }
# {#‰
# tag: <town>...</town>  for town of institute (now being stored into "..._ins")
#
    if (m|<town>\s*(.*?)\s*</town>|) {
        $key = "$1";
        if ($key eq "") {
            $key =" ";
        } else {
			convert_spec_chars ($key, "<town>");
		}
        if ($person_mode == $CONTRIBUTOR) {
            $contrib_ins[$paper_nr][$contrib_nr] = $key;
            print DBG "###Co> town: ª$1´\n";
        } elsif ($person_mode == $CHAIR) {
            $chair_inst_name[$session_nr][$chair_nr] = $key;
            print DBG "###Ch> town: ª$1´\n";
        } elsif ($person_mode == $PRESENTER) {
            $presenter_ins[$paper_nr] = $key;
            print DBG "###Pr> town: ª$key´\n";
        }
		Deb_call_strucOut ();
        return;
    } #‰}
#
# tag: <country_code abbrev="..">...</country_code>  for Country of institute (add to "..._ins")
#
    if (m|<country_code abbrev="(.*?)">\s*(.*?)\s*</country_code>|) {
        my $ctr_key = $1;
        my $country = $2;
        if ($country eq "United States of America") {
            $country = "USA";
        }
        my $ctr_add;
        if ($person_mode == $CONTRIBUTOR) {
            if ($contrib_ins[$paper_nr][$contrib_nr] eq "") {
                print DBG "###> $institute_nr.institute for paper ($paper_nr) without city: ª$country [$ctr_key]´\n";
                $ctr_add = $country;
            } else {
                $ctr_add = ", ".$country;
            }
            $contrib_ins[$paper_nr][$contrib_nr] .= $ctr_add;
            print DBG "###> country: ª$country [$ctr_key]´\n";
        } elsif ($person_mode == $CHAIR) {
            if ($chair_inst_name[$session_nr][$chair_nr] eq "") {
                print DBG "###> $institute_nr.institute for paper ($paper_nr) without city: ª$country [$ctr_key]´\n";
                $ctr_add = $country;
            } else {
                $ctr_add = ", ".$country;
            }
            $chair_inst_name[$session_nr][$chair_nr] .= $ctr_add;
            print DBG "###> country: ª$2 [$1]´\n";
        } elsif ($person_mode == $PRESENTER) {
            if ($presenter_ins[$paper_nr] eq "") {
                print DBG "###> $institute_nr.institute for paper ($paper_nr) without city: ª$country [$ctr_key]´\n";
                $ctr_add = $country;
            } else {
                $ctr_add = ", ".$country;
            }
            $presenter_ins[$paper_nr] .= $ctr_add;
            print DBG "###> country: ª$country [$ctr_key]´\n";
        }
		Deb_call_strucOut ();
        return;
    }
#
# tag <institute> <full_name abbrev="...">institute's name</full_name>
#
    if (m|<full_name|) {
        if ($institute_open) {
            if (m|abbrev=\s*"\s*(.*?)\s*"|) {
			#
			# use Acronym (abbreviation)
			#
                $affil_abbr = $1;
                if ($affil_abbr eq "") {
                    print DBG "** institute's abbreviation empty\n";
                    if (m|>\s*(.*?)\s*</full_name>|) {
                        $affil_abbr = $1;
                        print DBG "** institute's abbreviation fixed: '$affil_abbr'\n";
                    }
                } else {
                    print DBG "** institute's abbreviation: '$affil_abbr'\n";
                }
				convert_spec_chars ($affil_abbr, "<full_name abbr=");
            } else {
			#
			# Acronym (abbreviation) missing, check "Affiliation Request Pending"
			#
                #
                # fix missing institute's abbreviation
                #   (set abbr to name1 + name2,
                #    clear full name)
                #
                $affil_abbr = "-";
                #
                # special case of "New Affiliation Request"
                #
                if (m|Affiliation Request|i) {
                    print     " --> Affiliation Request Pending for";
                    print DBG " --> Affiliation Request Pending for";
                    if
                       ($person_mode == $CONTRIBUTOR) {
                        $contrib_ins[$paper_nr][$contrib_nr] = "-TBS-";
                        print     " \"$contrib_lst[$paper_nr][$contrib_nr]\"\n";
                        print DBG " \"$contrib_lst[$paper_nr][$contrib_nr]\"\n";
                        print DBG " \"$contrib_ln8[$paper_nr][$contrib_nr]\"\n";    # utf-8
                    } elsif
                       ($person_mode == $CHAIR) {
                        $chair_inst_name[$session_nr][$chair_nr] = "-TBS-";
                        print     " \"$chair_lst[$session_nr][$chair_nr]\"\n";
                        print DBG " \"$chair_lst[$session_nr][$chair_nr]\"\n";
                    } elsif
                       ($person_mode == $PRESENTER) {
                        $presenter_ins[$paper_nr] = "-TBS-";
                        print     " \"$presenter_lst[$paper_nr]\"\n";
                        print DBG " \"$presenter_lst[$paper_nr]\"\n";
                    } else {
                        print     " --> Paper seq number <$paper_nr> Person-mode: <$person_mode> Paper_Code/Id: <$paper_code[$paper_nr] Inst:<$institute_nr>\n";
                        print DBG " --> Paper seq number <$paper_nr> Person-mode: <$person_mode> Paper_Code/Id: <$paper_code[$paper_nr] Inst:<$institute_nr>\n";
                    }
                }
            }
            if
               ($person_mode == $CONTRIBUTOR) {
                $contrib_abb[$paper_nr][$contrib_nr] = $affil_abbr;
                if (!defined $contrib_ins[$paper_nr][$contrib_nr]) {
                    $contrib_ins[$paper_nr][$contrib_nr] = $affil_abbr;
                }
            } elsif
               ($person_mode == $CHAIR) {
                $chair_inst_abb[$session_nr][$chair_nr] = $affil_abbr;
                if (!defined $chair_inst_name[$session_nr][$chair_nr]) {
                    $chair_inst_name[$session_nr][$chair_nr] = $affil_abbr;
                }
            } elsif
               ($person_mode == $PRESENTER) {
                $presenter_abb[$paper_nr] = $affil_abbr;
                if (!defined $presenter_ins[$paper_nr]) {
                    $presenter_ins[$paper_nr] = $affil_abbr;
                }
            }
        } else {
            croak " no <institute> open for institute's name ª$affil_abbr´ in line $.\n";
        }
		Deb_call_strucOut ();
        return;
    }
# {#‰
# tag: <name1>...</name1> + <name2>...</name2>
#
    if (m|<name\d>|) {
		#
		# Acronym (abbreviation) missing, and build from "name1, name2"; "Full Name" was cleared 
		#
        if ($affil_abbr eq "-") {
            if (m|<name1>\s*(.*?)\s*</name1>|) {
                if ($1 ne "") {
					convert_spec_chars ($1, "<name1>");
                    if ($person_mode == $CONTRIBUTOR) {
                        $contrib_abb[$paper_nr][$contrib_nr] = $1;
                        print DBG "###> name1: ª$1´\n";
                    } elsif ($person_mode == $CHAIR) {
                        $chair_inst_abb[$session_nr][$chair_nr] = $1;
                        print DBG "###> name1: ª$1´\n";
                    } elsif ($person_mode == $PRESENTER) {
                        $presenter_abb[$paper_nr] = $1;
                        print DBG "###> name1: ª$1´\n";
                    }
					Deb_call_strucOut ();
                    return;
                }
            }
            if (m|<name2>\s*(.*?)\s*</name2>|) {
                if ($1 ne "") {
 					convert_spec_chars ($1, "<name2>");
                   if ($person_mode == $CONTRIBUTOR) {
                        $contrib_abb[$paper_nr][$contrib_nr] .= ", $1";
                        print DBG "###> name2: ª$1´\n";
                    } elsif ($person_mode == $CHAIR) {
                        $chair_inst_abb[$session_nr][$chair_nr] .= ", $1";
                        print DBG "###> name2: ª$1´\n";
                    } elsif ($person_mode == $PRESENTER) {
                        $presenter_abb[$paper_nr] .= ", $1";
                        print DBG "###> name2: ª$1´\n";
                    }
					Deb_call_strucOut ();
                    return;
                }
            }
        }
		Deb_call_strucOut ();
        return;
    } #‰
#
# tag: <email>...</email>  for main authors' email address
#
    if (m|<email>\s*(.*?)\s*</email>|) {
        $key = "$1";
        if ($key eq "") {
            $key ="-";
        }
        if ($person_mode == $CONTRIBUTOR) {
            $contrib_ema[$paper_nr][$contrib_nr] = $key;
            print DBG "###> email: ª$1´\n";
        } elsif ($person_mode == $CHAIR) {
            $chair_ema[$session_nr][$chair_nr] = $key;
            print DBG "###> email: ª$1´\n";
        } elsif ($person_mode == $PRESENTER) {
            $presenter_ema[$paper_nr] = $key;
            print DBG "###> email: ª$1´\n";
        }
		Deb_call_strucOut ();
        return;
    }
#
# tag: <emails>...<emails> to check for any email address present
#
    if (m|<emails>|) {
		Deb_call_strucOut ();
        return;
    }
    if (m|</emails>|) {
        if ($person_mode == $CONTRIBUTOR && !defined $contrib_ema[$paper_nr][$contrib_nr]) {
            $contrib_ema[$paper_nr][$contrib_nr] = "";
            print DBG "###> missing email for: ªauthor pap:$paper_nr contr:$contrib_nr´\n";
        } elsif ($person_mode == $CHAIR && !defined $chair_ema[$session_nr][$chair_nr]) {
            $chair_ema[$session_nr][$chair_nr] = "";
            print DBG "###> missing email for: ªchair[$chair_nr] ses:$session_nr´\n";
        } elsif ($person_mode == $PRESENTER && !defined $presenter_ema[$paper_nr]) {
            $presenter_ema[$paper_nr] = "";
            print DBG "###> missing email for: ªpresenter pap:$paper_nr´\n";
        }
		Deb_call_strucOut ();
        return;
    }
#
# tag: <contributor type="...">
#
    if (m|<contributor |) { # space importent for type="..." detection
        print DBG " <contributor> for <paper> '$paper_code[$paper_nr]'\n";
        if ($paper_open) {
            #
            # paper is open, determine Contributor's type
            #
            #  Presenter|Speaker               => PRESENTER
            #  Author|Co-Author|Primary Author => CONTRIBUTOR
            #  Owner                           => OTHER
            #
            #
            #-- mail Matt: Tue 2009-05-19 16:28
            #
            # Here's the complete list with pairings.
            #
            #   SQL> l
            #      1  select author_code, author_type, author_descr, pc_mode_descr
            #      2* from author_codes
            #   SQL> /
            #
            #   AUTH AUTH AUTHOR_DESCR      PC_MODE_DESCR
            #   ---- ---- ----------------- -----------------
            #   PRI  AUTH Primary Author    Proposed Author
            #   PRE  PRES Speaker           Proposed Speaker
            #   COA  AUTH Co-Author         Alternate Speaker
            #             Owner             Proposer/"Proposed By"
            #--
            # type="..." of (Author|Co-Author|Presenter|Speaker)
            #
            $main_author_key  = 0;
            if (m|type\s*=\s*"(.*?)\s*"|) {
                $key = $1;
                #
                # Author|Co-Author|Primary Author:
                # increment <contributor> counter and set main author
                #
                if ($key =~ /Author/ || $key =~ /Alternate Speaker/) {
                    #
                    # covers "Proposed Author" + "Primary Author" + "Co-Author" + "Alternate Speaker"
                    #
                    $person_mode = $CONTRIBUTOR;
                    $contrib_nr++;
                    print DBG " new Contributor [#$contrib_nr]\n";
                    if ($key eq "Author" || $key eq "Primary Author" || $key eq "Proposed Author") {
                        #
                        # covers all 'Primary' Author rÙles
                        #
                        $main_author_key = 1;
                        $main_author_indx = $contrib_nr;
                        print DBG sprintf ("> Paper #%4i - MainAuthor is #%2i\n", $paper_nr, $main_author_indx);
                        $contrib_typ[$paper_nr][$contrib_nr] = "Author";    # change 070918 $key;
                    } else {
                        #
                        # covers "Co-Author" + "Alternate Speaker"
                        #
                        if ($key =~ /Co-Author/ || $key =~ /Alternate Speaker/) {
                            $contrib_typ[$paper_nr][$contrib_nr] = "Co-Author";
                        } else {
                            print " unknown key: $key\n";        # change 070918 into else part
                        }
                    }
                    $contrib_ema[$paper_nr][$contrib_nr] = "";
                    $contrib_abb[$paper_nr][$contrib_nr] = "";
                    $contrib_ins[$paper_nr][$contrib_nr] = "";
                }
				#
				# SPEAKER or PRESENTER are the remaining rÙles that are additional flags to the above
				#
                if ($key =~ /Speaker/i || $key =~ /Presenter/i) {
                    $person_mode = $PRESENTER;
                    print DBG " SPEAKER or PRESENTER of contribution/paper [#$paper_nr]\n";
                    $presenter_typ[$paper_nr] = $key;
                    $presenter_ema[$paper_nr]  = "";
                    $presenter_abb[$paper_nr]  = "";
                    $presenter_ins[$paper_nr]  = "";
                }
            }
        } else {
            #
            # paper not open, no need for a <contributor>
            #
            croak " ?? '$name' not open, no need for a <contributor>! $.\n";
        }
		Deb_call_strucOut ();
        return;
    }
#
# tag: </contributor>
#
    if (m|</contributor>|) {
		my $DBAG = "";  # clear string
		if ($person_mode == $CONTRIBUTOR) { # only CONTRIBUTORs are treated here, as PRESENTERs have an additional XML set as CONTRIBUTORs
			#
			# actual candidate in the list of SPMS UTF-8 names?
			#
			my $act_jacowid	= $contrib_aid[$paper_nr][$contrib_nr];
			print DBG sprintf (" UTF8-09942 %s name:%s\n", $act_jacowid, $contrib_lst[$paper_nr][$contrib_nr]);
			if (exists($utf8_names{$act_jacowid})) {
				my $curr_jid = $utf8_names{$act_jacowid};
				$contrib_ln8[$paper_nr][$contrib_nr] = $lastname_8[$curr_jid];
				$contrib_in8[$paper_nr][$contrib_nr] = $firstini_8[$curr_jid];
			#	$firstname_8[$act_jacowid]
			#	$firstname[$act_jacowid]
				$contrib_lst[$paper_nr][$contrib_nr] = $lastname[$curr_jid];
				$contrib_ini[$paper_nr][$contrib_nr] = $firstini[$curr_jid];
			} else {
				$contrib_ln8[$paper_nr][$contrib_nr] = $contrib_lst[$paper_nr][$contrib_nr];
				$contrib_in8[$paper_nr][$contrib_nr] = $contrib_ini[$paper_nr][$contrib_nr];
			}
			#
			# counters for the copy and print action
			#
			my $c_start = $contrib_nr - $institute_nr;
			my $c_end   = $contrib_nr;
			if ($institute_nr > 0) {
				print DBG " copy Inst-data: pap:$paper_nr contrib:$contrib_nr inst:$institute_nr ($paper_code[$paper_nr]) => $person_mode\n";
				for ($i = $c_start; $i < $c_end; $i++) {
	#            for ($i=$contrib_nr; $i>=$contrib_nr - $institute_nr + 1; $i--) {
					print DBG " copying Inst-data: set:$contrib_nr => ",$i,"\n";
					$contrib_in8[$paper_nr][$i] = $contrib_in8[$paper_nr][$contrib_nr];
					$contrib_ln8[$paper_nr][$i] = $contrib_ln8[$paper_nr][$contrib_nr];
					$contrib_ema[$paper_nr][$i] = $contrib_ema[$paper_nr][$contrib_nr];
				}
			}
			#
			# debug output for CONTRIBUTORs
			#
			$DBAG    = "";
			my $icnt = 0;
            if ($main_author_key) {
                $main_author[$paper_nr] = "$contrib_ini[$paper_nr][$contrib_nr] $contrib_lst[$paper_nr][$contrib_nr]";
				for ($i = $c_start; $i <= $c_end; $i++) {
					$DBAG  =         "--- Contributor Data Set (Mainauthor) --------------------------------------\n";
					$DBAG .=         "    Paper      : $paper_code[$paper_nr]\n";
					$DBAG .=         "    Abstract_Id: $abs_id[$paper_nr]\n";
					$DBAG .= sprintf("    PapNr,Cont#: %i, %i\n", $paper_nr, $i);
					$DBAG .=         "    Type       : $contrib_typ[$paper_nr][$i]\n";
					$DBAG .=         "    Mainauthor : $contrib_ini[$paper_nr][$i] $contrib_lst[$paper_nr][$i]\n";
					$DBAG .=         "        ln8    : $contrib_in8[$paper_nr][$i] $contrib_ln8[$paper_nr][$i]\n";
					$DBAG .=         "    Email      : $contrib_ema[$paper_nr][$i]\n";
					$DBAG .= sprintf("    Institute %i: $contrib_ins[$paper_nr][$i]\n", $i - $c_start);
					$DBAG .=         "    InstShort  : $contrib_abb[$paper_nr][$i]\n";
					$DBAG .=         "----------------------------------------------------------------------------\n";
					print DBG $DBAG;
					print DBA $DBAG;
				}
            } else {
				for ($i = $c_start; $i <= $c_end; $i++) {
					$icnt  = $i - $c_start;
					$DBAG  =         "--- Contributor Data Set ---------------------------------------------------\n";
					$DBAG .=         "    Paper      : $paper_code[$paper_nr]\n";
					$DBAG .=         "    Abstract_Id: $abs_id[$paper_nr]\n";
					$DBAG .= sprintf("    PapNr,Cont#: %i, %i\n", $paper_nr, $i);
					$DBAG .=         "    Type       : $contrib_typ[$paper_nr][$i]\n";
					$DBAG .=         "    Contributor: $contrib_ini[$paper_nr][$i] $contrib_lst[$paper_nr][$i]\n";
					$DBAG .=         "        ln8    : $contrib_in8[$paper_nr][$i] $contrib_ln8[$paper_nr][$i]\n";
					$DBAG .=         "    Email      : $contrib_ema[$paper_nr][$i]\n";
					$DBAG .= sprintf("    Institute %i: $contrib_ins[$paper_nr][$i]\n", $i - $c_start);
					$DBAG .=         "    InstShort  : $contrib_abb[$paper_nr][$i]\n";
					$DBAG .=         "----------------------------------------------------------------------------\n";
					print DBG $DBAG;
					print DBA $DBAG;
				}
            }
        } elsif ($person_mode == $PRESENTER) {  # these are SPEAKERs and PRESENTERs
			$DBAG  =         "--- Presenter Data Set ---------------------------------------------------\n";
			$DBAG .=         "    Paper      : $paper_code[$paper_nr]\n";
			$DBAG .=         "    Abstract_Id: $abs_id[$paper_nr]\n";
			$DBAG .= sprintf("    PapNr,Cont#: %i, %i\n", $paper_nr, $contrib_nr);
			$DBAG .=         "    Type       : $presenter_typ[$paper_nr]\n";
			$DBAG .=         "    Presenter  : $presenter_ini[$paper_nr] $presenter_lst[$paper_nr]\n";
			$DBAG .=         "    Email      : $presenter_ema[$paper_nr]\n";
			$DBAG .= sprintf("    Institute %i: $presenter_ins[$paper_nr]\n", $institute_nr);
			$DBAG .=         "    InstShort  : $presenter_abb[$paper_nr]\n",
			$DBAG .=         "----------------------------------------------------------------------------\n";
			print DBG $DBAG;
			print DBA $DBAG;
        }
        $person_mode = $OTHER;  #?? just (additional) reset of type?
		Deb_call_strucOut ();
        return;
    }
#
# structure data for "person"
#
#-------------
#   <lname>#</lname>
#   <fname>#</fname>
# *-  <mname>#</mname> or <mname/>    will be ignored *****
#   <iname>#</iname>
#   <author_id>#</author_id>
#   <institutions>
#      <institute>
#         <full_name abbrev="..."> ... </full_name>
#         <name1> ... </name1>
#         <name2> ... </name2>
#         <department> ... </department>
#         <url> ... </url>
#      </institute>
#   </institutions>
#   <emails>
#      <email> ... </email>
#   </emails>
#---
#   $contrib_ini[$pap][]       [0..$contrib_nr]   author's initials ($contrib_nr) for "$paper_nr"
#   $contrib_lst[$pap][]       [0..$contrib_nr]   author's last name ($contrib_nr) for "$paper_nr"
#   $contrib_fst[$pap][]       [0..$contrib_nr]   author's first name ($contrib_nr) for "$paper_nr"
# *-  $contrib_mna[$pap][]       [0..$contrib_nr]   author's middle name ($contrib_nr) for "$paper_nr"
#   $contrib_ins[$pap][]       [0..$contrib_nr]   author's institute (numbered by $ins) ($contrib_nr) for "$paper_nr"
#   $contrib_abb[$pap][]       [0..$contrib_nr]   author's institute abbr (numbered by $ins) ($contrib_nr) for "$paper_nr"
#-------------
    if (m|<lname>\s*(.*?)\s*</lname>|) {
		#
		# Name contains html entities &#/&
		#
		my $lstn_html = $1;
		if ($lstn_html =~ m/&/g) {
            print DBG " HTML ln: >$lstn_html<\n";
		}
        convert_entity_chars2iso ($lstn_html);
        if ($lstn_html ne $_) {
            print DBG "entity_chars2iso: >$lstn_html< >$_<\n";
        }
        $key = $_;
        if ($key eq "") { $key = "???"; } # specialty InDiCo
        #
        print DBG "###> lname: ª$key´\n";
        #
        # Name completely uppercase => convert to lowercase with Initial Caps
        #
        my $allupper = () = $key =~ m/[A-Z]/g;
        if ($allupper == length($key)) {
            my $nkey = ucfirst (lc($key));
			$uplow   = sprintf ("\n## upper ###[%4.i]######> %s => %s\n\n", $abs_id[$paper_nr], $key, $nkey);
            print DBG $uplow;
            print     $uplow;
            $key = $nkey;
        }
        #
        # Name completely lowercase => convert to Initial Caps
        #
        my $alllower = () = $key =~ m/[a-z]/g;
        if ($alllower == length($key)) {
            my $nkey = ucfirst (lc($key));
			$uplow   = sprintf ("\n## lower ###[%4.i]######> %s => %s\n\n", $abs_id[$paper_nr], $key, $nkey);
            print DBG $uplow;
            print     $uplow;
            $key = $nkey;
        }
        # assign last name to role based field
        if      ($person_mode == $CONTRIBUTOR) {
            $contrib_lst[$paper_nr][$contrib_nr] = $key;
        } elsif ($person_mode == $CHAIR) {
            $chair_lst[$session_nr][$chair_nr] = $key;
        } elsif ($person_mode == $PRESENTER) {
            $presenter_lst[$paper_nr] = $key;
        }
		Deb_call_strucOut ();
        return;
    }
#--
    if (m|<fname>\s*(.*?)\s*</fname>|) {
		#
		# Name contains html entities &#/& ?
		#
		my $fstn_html = $1;
		if ($fstn_html =~ m/&/g) {
            print DBG " HTML fn: >$fstn_html<\n";
		}
        $key = "$fstn_html";
        print DBG "###> fname: ª$key´\n";
        $ini_from_firstname = substr ($key, 0, 1).".";
        # assign first name to role based field
        if      ($person_mode == $CONTRIBUTOR) {
            $contrib_fst[$paper_nr][$contrib_nr] = $key;
            $contrib_ini[$paper_nr][$contrib_nr] = $ini_from_firstname;
        } elsif ($person_mode == $CHAIR) {
            $chair_fst[$session_nr][$chair_nr] = $key;
            $chair_ini[$session_nr][$chair_nr] = $ini_from_firstname;
        } elsif ($person_mode == $PRESENTER) {
            $presenter_fst[$paper_nr] = $key;
            $presenter_ini[$paper_nr] = $ini_from_firstname;
        }
		Deb_call_strucOut ();
        return;
    }
#
# <iname> for authors' name (initials)
#
    if (m|<iname>\s*(.*?)\s*</iname>|) {
		#
		# Name contains html entities &#/&
		#
		my $inin_html = $1;
		if ($inin_html =~ m/&/g) {
            print DBG " HTML in: >$inin_html<\n";
		}
        $key = "$inin_html";
        print DBG "###> iname: ª$inin_html´\n";
        if ($key eq "") {
            print DBG "==========> empty initial on line $.\n";
            $key = $ini_from_firstname;
            print DBG "==========> substitued by ª$key´\n";
        }
		#
		# check for unusual long initials (like last name appears in initials)
		#       >6 means more than 3 initials + "." (spaces removed)
		#
		$key =~ s| ||g;
		if (length($key) gt 6) {
#			my $kc  = $key  =~ s| ||g;
#			print     "==========> initials? >$kc<\n";
#			my $count = $kc =~ s|\.|\.|g;
#			my $leng  = length($kc);
#			print     "==========> $count ~ $leng\n";
				print     "==========> long initials? >$key<\n";
				print DBG "==========> long initials? >$key<\n";
#			if (2*$count ne $leng) {
				if      ($person_mode == $CONTRIBUTOR) {
					print DBG "==========> $contrib_fst[$paper_nr][$contrib_nr] $contrib_lst[$paper_nr][$contrib_nr]\n";
					print     "==========> $contrib_fst[$paper_nr][$contrib_nr] $contrib_lst[$paper_nr][$contrib_nr]\n";
				} elsif ($person_mode == $CHAIR) {
					print DBG "==========> $contrib_fst[$session_nr][$chair_nr] $contrib_lst[$session_nr][$chair_nr]\n";
					print     "==========> $contrib_fst[$session_nr][$chair_nr] $contrib_lst[$session_nr][$chair_nr]\n";
				} elsif ($person_mode == $PRESENTER) {
					print DBG "==========> $contrib_fst[$paper_nr] $contrib_lst[$paper_nr]\n";
					print     "==========> $contrib_fst[$paper_nr] $contrib_lst[$paper_nr]\n";
				}
#			}
		}
        # assign initial(s) to role based field
        if      ($person_mode == $CONTRIBUTOR) {
            $contrib_ini[$paper_nr][$contrib_nr] = $key;
        } elsif ($person_mode == $CHAIR) {
            $chair_ini[$session_nr][$chair_nr] = $key;
        } elsif ($person_mode == $PRESENTER) {
            $presenter_ini[$paper_nr] = $key;
        }
		Deb_call_strucOut ();
        return;
    }
#
# <author_id> for authors unique JACoW identifier
#
    if (m|<author_id>\s*(\d+)\s*</author_id>|) {
        $key = $1;
        if ($key eq "") {
            $key = 0
        }
        my $authkey;
        $authkey = sprintf ("JACoW-%08d", $key);
        print DBG "###> auth_id: ª$1´ ($authkey)\n";
        #
        if      ($person_mode == $CONTRIBUTOR) {
            $contrib_aid[$paper_nr][$contrib_nr] = $authkey;
            if ($key eq 0) {
                print DBG "==========> Contrib: empty author_id for \"$contrib_lst[$paper_nr][$contrib_nr]\" on line $.\n";
            }
        } elsif ($person_mode == $CHAIR) {
            $chair_aid[$session_nr][$chair_nr] = $authkey;
            if ($key eq 0) {
                print DBG "==========> Chair: empty author_id for \"$chair_lst[$session_nr][$chair_nr]\" on line $.\n";
            }
        } elsif ($person_mode == $PRESENTER) {
            $presenter_aid[$paper_nr] = $authkey;
            if ($key eq 0) {
                print DBG "==========> Presenter: empty author_id for \"$presenter_lst[$paper_nr]\" on line $.\n";
            }
        }
		Deb_call_strucOut ();
        return;
    }
#--
#
# <mname> for authors' name (middle name)
#   <mname>#</mname> or <mname/>
#
    if (m|<mname\s*/>|) {
        $contrib_mna[$paper_nr][$contrib_nr] = "";
        print DBG "###> no middle name in line $.\n";
		Deb_call_strucOut ();
        return;
    }
    if (m|<mname>\s*(.*?)\s*</mname>|) {
        $key = $1;
        print DBG "###> mname: ª$1´\n";
        #
        if      ($person_mode == $CONTRIBUTOR) {
            if ($key eq "") {
                $contrib_mna[$paper_nr][$contrib_nr] = "";
            } else {
                $contrib_mna[$paper_nr][$contrib_nr] = $key;
            }
        } elsif ($person_mode == $CHAIR) {
            $chair_mna[$session_nr][$chair_nr] = "$key";
        } elsif ($person_mode == $PRESENTER) {
            if ($key eq "") {
                $presenter_mna[$paper_nr] = "";
            } else {
                $presenter_mna[$paper_nr] = $key;
            }
        }
		Deb_call_strucOut ();
        return;
    }
#
# tag: <contributors>...</contributors>
#
    #
    # InDiCo specialty
    #
    if (m|<contributors>\s*(.*?)\s*</contributors>|) {
        $contrib_nr         =  0;             # reset number of contributors for paper
        $main_author_indx   = -1;
        $authors[$paper_nr] = -1;
        print DBG sprintf (" ª%i:  no contributors  for paper????? >%s<\n", $paper_nr, $paper_code[$paper_nr]);
#        $contrib_typ[$paper_nr][$contrib_nr] = $key;
        $contrib_ema[$paper_nr][$contrib_nr]  = "";
        $contrib_abb[$paper_nr][$contrib_nr]  = "";
        $contrib_ins[$paper_nr][$contrib_nr]  = "";
    }
#
# tag: <contributors>
#          <....>
#      </contributors>
#
    if (m|<contributors>|) {
        $main_author_indx = -1;
        $contrib_nr       = -1;    # reset number of contributors for paper
		Deb_call_strucOut ();
        return;
    }
    if (m|</contributors>|) {
        if ($contrib_nr  == -1) {
            $authors[$paper_nr] = -1;
            print DBG sprintf (" ª%i:  no contributors for paper >%s<\n", $paper_nr, $paper_code[$paper_nr]);
            # +++++++++++++++++++++++++++++++++++
            #
            # InDiCo specialty: Presenter/Speaker set?
            #
            if ($conference_type_indico && $presenter_lst[$paper_nr] ne "") {
                $authors[$paper_nr] = 0;
                $contrib_ini[$paper_nr][0] = $presenter_ini[$paper_nr];
                $contrib_lst[$paper_nr][0] = $presenter_lst[$paper_nr];
#				$contrib_fst[$paper_nr][0] = $presenter_fst[$paper_nr];
				#
				# no check for UTF-names as there is no DB table for InDiCo 
				# (InDiCo should be Unicode anycase [not sure for JACoW-InDiCo])
				#
                $contrib_mna[$paper_nr][0] = $presenter_mna[$paper_nr];
                $contrib_ema[$paper_nr][0] = $presenter_ema[$paper_nr];
                $contrib_ins[$paper_nr][0] = $presenter_ins[$paper_nr];
                $contrib_abb[$paper_nr][0] = $presenter_abb[$paper_nr];
                $contrib_aid[$paper_nr][0] = $presenter_aid[$paper_nr];
                $main_author[$paper_nr]    = "$contrib_ini[$paper_nr][0] $contrib_lst[$paper_nr][0]";
            }
        } else {
            $authors[$paper_nr] = $contrib_nr;
            print DBG sprintf (" ª%i: %i´ contributors for paper %s\n", $paper_nr, $authors[$paper_nr]+1, $paper_code[$paper_nr]);
            #
            # this is where the main author should be sorted to first place
            # =============================================================
            #   $contrib_ini[$pap][]       [0..$contrib_nr]   authors' initials (numbered by $contrib_nr) for "$paper_nr"
            #   $contrib_lst[$pap][]       [0..$contrib_nr]   authors' last name (numbered by $contrib_nr) for "$paper_nr"
            #   $contrib_fst[$pap][]       [0..$contrib_nr]   authors' first name (numbered by $contrib_nr) for "$paper_nr"
            #   $contrib_mna[$pap][]       [0..$contrib_nr]   authors' middle name (numbered by $contrib_nr) for "$paper_nr"
            #   $contrib_ema[$pap][]       [0..$contrib_nr]   authors' email address (numbered by $contrib_nr) for "$paper_nr"
            #   $contrib_ins[$pap][]       [0..$contrib_nr]   authors' institute ($contrib_nr) for "$paper_nr"
            #   $contrib_abb[$pap][]       [0..$contrib_nr]   authors' (numbered by $contrib_nr) institute abbr ($contrib_nr) for "$paper_nr"
            #   $contrib_aid[$pap][]       [0..$contrib_nr]   authors' unique JACoW identifier (numbered by $contrib_nr) for "$paper_nr"
            # =============================================================
            # main_author_indx is the pointer to the main author's entry in the $contrib_xxx fields
            #                  now save the #0 entry, put the main author into #0 and shift everybody one up
            # save #0
#            print DBG sprintf ("= Paper #%4i - MainAuthor is #%2i\n", $paper_nr, $main_author_indx);
            #
            # shift everybody one up and free #0
            #
            for ($i=$contrib_nr+1; $i>=1; $i--) {
				$contrib_ln8[$paper_nr][$i] = $contrib_ln8[$paper_nr][$i-1];
				$contrib_in8[$paper_nr][$i] = $contrib_in8[$paper_nr][$i-1];
				$contrib_lst[$paper_nr][$i] = $contrib_lst[$paper_nr][$i-1];
				$contrib_ini[$paper_nr][$i] = $contrib_ini[$paper_nr][$i-1];
                $contrib_fst[$paper_nr][$i] = $contrib_fst[$paper_nr][$i-1];
                $contrib_mna[$paper_nr][$i] = $contrib_mna[$paper_nr][$i-1];
                $contrib_ema[$paper_nr][$i] = $contrib_ema[$paper_nr][$i-1];
                $contrib_aid[$paper_nr][$i] = $contrib_aid[$paper_nr][$i-1];
                $contrib_ins[$paper_nr][$i] = $contrib_ins[$paper_nr][$i-1];
                $contrib_abb[$paper_nr][$i] = $contrib_abb[$paper_nr][$i-1];
#¸                $contrib_cab[$paper_nr][$i] = $contrib_cab[$paper_nr][$i-1];
#                print DBG sprintf ("= Paper #%4i - Entry #%2i (%s %s -- %s-%s)\n", $paper_nr, $i, $contrib_ini[$paper_nr][$i],
#                                                                    $contrib_lst[$paper_nr][$i],
#                                                                    $contrib_abb[$paper_nr][$i],
#                                                                    $contrib_ins[$paper_nr][$i]);
            }
            #
            # now copy main author into #0
            #
			$contrib_ln8[$paper_nr][0] = $contrib_ln8[$paper_nr][$main_author_indx+1];
			$contrib_in8[$paper_nr][0] = $contrib_in8[$paper_nr][$main_author_indx+1];
			$contrib_lst[$paper_nr][0] = $contrib_lst[$paper_nr][$main_author_indx+1];
			$contrib_ini[$paper_nr][0] = $contrib_ini[$paper_nr][$main_author_indx+1];
            $contrib_fst[$paper_nr][0] = $contrib_fst[$paper_nr][$main_author_indx+1];
            $contrib_mna[$paper_nr][0] = $contrib_mna[$paper_nr][$main_author_indx+1];
            $contrib_ema[$paper_nr][0] = $contrib_ema[$paper_nr][$main_author_indx+1];
            $contrib_aid[$paper_nr][0] = $contrib_aid[$paper_nr][$main_author_indx+1];
            $contrib_ins[$paper_nr][0] = $contrib_ins[$paper_nr][$main_author_indx+1];
            $contrib_abb[$paper_nr][0] = $contrib_abb[$paper_nr][$main_author_indx+1];
#¸            $contrib_cab[$paper_nr][0] = $contrib_cab[$paper_nr][$main_author_indx+1];
#            print DBG sprintf ("= Paper #%4i - MainAuthor (%s %s -- %s-%s)\n", $paper_nr, $contrib_ini[$paper_nr][0],
#                                                                $contrib_lst[$paper_nr][0],
#                                                                $contrib_abb[$paper_nr][0],
#                                                                $contrib_ins[$paper_nr][0]);
            #
            # and compact again (throw out duplicate main author)
            #
            $j = 0;
            for ($i=1; $i<=$contrib_nr; $i++) {
                $j++;
#                print DBG sprintf ("= Paper #%4i - Index + ShiftInx (%2i:%2i)\n", $paper_nr, $i, $j);
                if ($i eq $main_author_indx+1) {
                    $j++;
#                    print DBG sprintf ("= Paper #%4i - Index # Main+1 (%s:%s)\n", $paper_nr, $i, $main_author_indx+1);
                }
                if ($i ne $j) {
                    $contrib_ini[$paper_nr][$i] = $contrib_ini[$paper_nr][$j];
                    $contrib_in8[$paper_nr][$i] = $contrib_in8[$paper_nr][$j];
                    $contrib_lst[$paper_nr][$i] = $contrib_lst[$paper_nr][$j];
                    $contrib_ln8[$paper_nr][$i] = $contrib_ln8[$paper_nr][$j];
                    $contrib_fst[$paper_nr][$i] = $contrib_fst[$paper_nr][$j];
                    $contrib_mna[$paper_nr][$i] = $contrib_mna[$paper_nr][$j];
                    $contrib_ema[$paper_nr][$i] = $contrib_ema[$paper_nr][$j];
                    $contrib_ins[$paper_nr][$i] = $contrib_ins[$paper_nr][$j];
                    $contrib_abb[$paper_nr][$i] = $contrib_abb[$paper_nr][$j];
                    $contrib_aid[$paper_nr][$i] = $contrib_aid[$paper_nr][$j];
#                    print DBG sprintf ("= Paper #%4i - i/j#%2i:%2i (%s %s -- %s-%s)\n", $paper_nr, $i, $j, $contrib_ini[$paper_nr][$i],
#                                                                        $contrib_lst[$paper_nr][$i],
#                                                                        $contrib_abb[$paper_nr][$i],
#                                                                        $contrib_ins[$paper_nr][$i]);
                }
#                print DBG sprintf ("~ Paper #%4i - Entry #%2i (%s %s -- %s-%s)\n", $paper_nr, $i, $contrib_ini[$paper_nr][$i],
#                                                                    $contrib_lst[$paper_nr][$i],
#                                                                    $contrib_abb[$paper_nr][$i],
#                                                                    $contrib_ins[$paper_nr][$i]);
            }
            $main_author[$paper_nr] = "$contrib_ini[$paper_nr][0] $contrib_lst[$paper_nr][0]";
#utf-8       $main_author[$paper_nr] = "$contrib_ini[$paper_nr][0] $contrib_lst[$paper_nr][0]";
        }
        $main_author_indx = -1;
		Deb_call_strucOut ();
        return;
    }
#
# tag: <session>
#
    if (m|<session|) {
        $institute_open = 0;
        $chair_nr       = -1;
        print DBG "\n<session> $_\n";
        if ($session_open) {
            #
            # session still open
            #
            croak " opening session '$name' while session '$session_name[$session_nr]' is still open in line $.\n";
        } else {
            #
            # session not open, so
            #    - open it
            #    - initialize "$session_start" to enable first paper entry by <paper>
            #    - increment "$session_nr"
            #    - session's name and dates are separate structures between <session> and <chair>,
            #      so detection of <name ...> and <date ...> is enabled with "$session_struc" here,
            #      and disabled with <chair>
            #
			#
			# since 2012-05-21 we got a type for a session <session type="Oral">
			#                  type could be "Oral" or something else like "Poster" or "ePoster"
			#
            my $sess_arg = " ";
            if (m|type\s*=\s*"(.*?)"|) {
                $sess_arg = $1;
            } else {
                carp " opening session without type in line $.\n";
            }
            $session_open  = 1;
            $session_struc = 1;
            $session_start = 1;
            $session_nr++;
			$session_type[$session_nr] = $sess_arg;
            if ($session_nr) {
                $session_startp[$session_nr] = $session_endp[$session_nr - 1] + 1;
            } else {
                $session_startp[$session_nr] = 0;
            }
#¸            if ($session_div_pages) {
#¸                #
#¸                # act on session dividing pages
#¸                #
#¸                if (!($page_start[$paper_nr + 1] & 1)) { # page is not odd, so next is odd, add 1
#¸                    $page_start[$paper_nr + 1]++;
#¸                }
#¸                $page_start[$paper_nr + 1] += $session_div_pages;
##                print "< add> $paper_nr.=> $page_start[$paper_nr] ($title[$paper_nr]) --> $page_start[$paper_nr+1]\n";
#¸            }
        }
		Deb_call_strucOut ();
        return;
    }
    if (m|</session>|) {
        if ($session_open) {
            $chairs[$session_nr] = $chair_nr;
            my $clos_ses = sprintf ("['%2i':%-6s] [chairs :%s] : %s",
                                     $session_nr, $session_abbr[$session_nr], $chairs[$session_nr]+1, $session_name[$session_nr]);
            warn " going to close session $clos_ses\n";
            $session_endp[$session_nr] = $paper_nr;
            $session_open = 0;
        } else {
            croak " closing session while no session is open in line $.\n";
        }
		Deb_call_strucOut ();
        return;
    }
#
# tag: <name abbr="...">session name</name>
#
    if (m|<name abbr|) {
        my $act_arg;
        #
        # <name abbr="...">....
        #
        if (m|abbr\s*=\s*"(.*?)"|) {
            $act_arg = $1;
        } else {
            $act_arg = " ";
        }
        #
        # some InDiCo conferences contain "/" which will be disastrous for
        #             file generation when understood as (sub)directories
        #
        $act_arg =~ s|/|~|g;
        #
        # InDiCo specialty: session names with closing "hyphen 1"
        #
        if ($conference_type_indico) {
            #
            # remove "-1" ?
            #
            if ($indico_cut_of_trailing_ho) {
                $act_arg =~ s/-1$//g;
            }
            #
            # Uppercase InDiCo's session names?
            #
            if ($indico_uppercase_session) {
                $act_arg = uc $act_arg;
            }
        }
        #
        # is there an entry in the list of 'sessions to skip'
        # Check whether this session is in the list of 'sessions to skip'
        #
        if ($sess_skip_list_anz > 0) {
            #
            # there are sessions to skip, is this session in the list?
            #
            $skip_this_session = 0;
            for ($i=0; $i<$sess_skip_list_anz; $i++) {
                if ($sess_skip_list[$i] eq $act_arg) {
                    $sess_skipping     = $act_arg;
                    $skip_this_session = 1;
                    last;
                }
            }
            #
            # do we have to skip this session?
            #
            if ($skip_this_session) {
                print " ∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞> session '$act_arg' is skipped!\n";
                $session_struc = 0;
                $session_open = 0;
                $session_start = 0;
                $session_nr--;
				Deb_call_strucOut ();
                return;
            }
        }
        if ($session_struc) {
            #
            # initialize session structure
            #  (if it stays empty, do not output it!)
            #
            $session_date[$session_nr]  = " ";
            $session_btime[$session_nr] = " ";
            $session_etime[$session_nr] = " ";
            $session_abbr[$session_nr] = $act_arg;
#>            #
#>            # get session location name into vars
#>            #
#>            get_session_location ($act_arg);
            #
            # <name ... >session date</name>
            #            sessions's name is argument
            #
            if (m|>\s*(.*?)\s*</name>|) {
                $act_arg = $1;
            } else {
                $act_arg = " ";
            }
            $session_name[$session_nr] = $act_arg;
            print DBG "<session   name=> '$session_name[$session_nr]'\n";
        } else {
            croak " session 'name' while no session structures are open in line $.\n";
        }
		Deb_call_strucOut ();
        return;
    }
#
# tag: <date btime="..." etime="...">date</date>
#
    if (m|<date|) {
        if ($session_struc) {
            my $act_arg;
            my $betim;
            #
            # <date btime="..."
            #
            if (m|btime\s*=\s*"(.*?)"|) {
                ($betim = $1) =~ s|:||;
                $act_arg = substr($betim, 0, 2).":".substr($betim, 2, 2);
            } else {
                $act_arg = " ";
            }
            $session_btime[$session_nr] = $act_arg;
            print DBG "<session   begT=> '$session_btime[$session_nr]'\n";
            #
            # <date etime="..."
            #
            if (m|etime\s*=\s*"(.*?)"|) {
                ($betim = $1) =~ s|:||;
                $act_arg = substr($betim, 0, 2).":".substr($betim, 2, 2);
            } else {
                $act_arg = " ";
            }
            $session_etime[$session_nr] = $act_arg;
            print DBG "<session   endT=> '$session_etime[$session_nr]'\n";
            #
            # <date ... >session date</date>
            #            date is argument
            #
            if (m|>\s*(.*?)-(.*?)-(.*?)\s*</date>|) {
                $act_arg = "$1-".ucfirst "$2-$3";
            } else {
                $act_arg = " ";
            }
            $session_date[$session_nr] = $act_arg;
            print DBG "<session   date=> '$session_date[$session_nr]'\n";
        } else {
            croak " session 'date' while no session structures are open in line $.\n";
        }
		Deb_call_strucOut ();
        return;
    }
#
# tag: <location type="....">......</location>
#
    if (m|<location|) {
        if ($session_struc) {
            my $act_arg;
#<            #
#<            # <location type="....">
#<            #
#<            if (m|type\s*=\s*"(.*?)"|) {
#<                $act_arg = $1;
#<            } else {
#<                $act_arg = " ";
#<            }
#<            #
#<            # extract 'Oral' or 'Invited Oral' from type argument
#<            #
#<            if ($act_arg =~ m/Oral|Invite/i) {
#<                if ($act_arg =~ m/Oral/i) {
#<                    $session_type[$session_nr] = substr ($act_arg, 0, index (lc $act_arg, "oral")+4);
#<                } elsif ($act_arg =~ m/Invite/i) {
#<                    $session_type[$session_nr] = "Oral";
#<                }
#<            } else {
#<                $session_type[$session_nr] = $act_arg;
#<            }
#<            print DBG "<session   Type=> '$session_type[$session_nr]'\n";
            #
            # <location ... >location name</date>
            #
            if (m|>\s*(.*?)\s*</location>|) {
#!                s/([\w']+)/(\u\L$1)/g;
                $act_arg = $1;
            } else {
                $act_arg = " ";
            }
            $session_location[$session_nr] = $act_arg;
            print DBG "<session   loc => '$session_location[$session_nr]'\n";
        } else {
            croak " session 'location' while no session structures are open in line $.\n";
        }
        if (!$session_locrd) {
            $sess_color[$session_nr] = "posses";
            print CODLOC $session_abbr[$session_nr]."\#".$session_type[$session_nr]."\#".$session_name[$session_nr]."\#".$session_location[$session_nr]."\#".$sess_color[$session_nr]."\n";
        }
		Deb_call_strucOut ();
        return;
    }
#
# tag: <chairs> </chairs>
#
# due to InDiCo conferences with more than one chair man, we have
# to introduce a count "chair_nr" which is reset at the outer level.
# <chairs> couldn't be used, because there are still conferences
# without these tags (before June '07), so <session> is used.
#
    if (m|<chairs>|) {
        #    $chair_nr       = -1;
        print DBG " <chairs> for <session:$session_name[$session_nr]> open\n";
		Deb_call_strucOut ();
        return;
    }
    if (m|</chairs>|) {
        #    $chairs[$session_nr] = $chair_nr;
        print DBG " <chairs> for <session:$session_name[$session_nr]> closed\n";
		Deb_call_strucOut ();
        return;
    }
#
# tag: <chair>
#
#    - disable detection of <name ...> and <date ...> structures
#
    if (m|<chair>|) {
        $session_struc = 0;
        $chair_nr++;
        print DBG " <chair:$chair_nr> for <session> $session_name[$session_nr]\n";
#        print     " <chair:$chair_nr> for <session> $session_name[$session_nr]\n";
        if ($session_open) {
            #
            # session is open
            #
##            $chair_open = 1;
            $person_mode = $CHAIR;
            $chair_ini[$session_nr][$chair_nr]       = "";
            $chair_lst[$session_nr][$chair_nr]       = "";
            $chair_inst_name[$session_nr][$chair_nr] = "";
            $chair_inst_abb[$session_nr][$chair_nr]  = "";
        } else {
            #
            # session not open, no need for a chair person
            #
            croak " session '$name' not open, no need for a <chair> person! $.\n";
        }
		Deb_call_strucOut ();
        return;
    }
    if (m|</chair>|) {
##        $chair_open = 0;
        if (!defined $chair_ema[$session_nr][$chair_nr]) {
            $chair_ema[$session_nr][$chair_nr] = "";
            print DBG "###> missing email for: ªchair[$chair_nr] ses:$session_nr´\n";
        }
        if ($chair_lst[$session_nr][$chair_nr]) {
            print DBG "--- Chair Data Set ---------------------------------------------------------\n";
            print DBG "    Chair     : #",$chair_nr+1,"\n";
            print DBG "    Session   : $session_name[$session_nr]\n";
            print DBG "    Abbr      : $session_abbr[$session_nr]\n";
            print DBG "    Date      : $session_date[$session_nr]\n";
            print DBG "    Begin     : $session_btime[$session_nr]\n";
            print DBG "    End       : $session_etime[$session_nr]\n";
            print DBG "    Chair     : $chair_ini[$session_nr][$chair_nr] $chair_lst[$session_nr][$chair_nr]\n";
            print DBG "    Email     : $chair_ema[$session_nr][$chair_nr]\n";
            print DBG "    Institute : $chair_inst_name[$session_nr][$chair_nr]\n";
            print DBG "    InstShort : $chair_inst_abb[$session_nr][$chair_nr]\n";
            print DBG "----------------------------------------------------------------------------\n";
        }
        $person_mode = 0;  #??
		Deb_call_strucOut ();
        return;
    }
#
# tag <conference>
#
    if (m|<conference|) {
        #
        # initialization
        #
        $skip_this_session = 0;    # do not skip
        #
        #  SPMS:
        #  InDiCo: <conference xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:date="http://exslt.org/dates-and-times" xsi:noNamespaceSchemaLocation="http://bel.gsi.de/docs/xml/conference_indico.xsd" name="CHEP 06, Tata Institute of Fundamental Research">
        #
        if (m|<conference(.*?)SchemaLocation="(.*?)"|) {
            $conference_type_indico = ($2 =~ m|indico|i);
            if ($conference_type_indico) {
                print DBG "Conference XML '$conference_name' Type 'InDiCo' opened\n";
                print   "\nConference XML '$conference_name' Type 'InDiCo' opened\n";
            } else {
                print DBG "Conference XML '$conference_name' Type 'SPMS' opened\n";
                print   "\nConference XML '$conference_name' Type 'SPMS' opened\n";
            }
        }
		Deb_call_strucOut ();
        return;
    }
    if (m|</conference|) {
        print DBG "Conference XML '$conference_name' closed\n";
        print    "\nConference XML '$conference_name' closed\n";
        $conf_close = 1;
        print sprintf ("\n#### %6.2f [s] ### end of XML read\n", gettimeofday-$start_tm);
		Deb_call_strucOut ();
        return;
    }
#
# tag <video_URL>http://....</video_URL>
#       ->     http://agenda.cern.ch/askArchive.php?base=agenda&categ=a042767&id=a042767s1/video_download
#       ->     shorten that by "_download"
#
    if (m|<video_URL>(.*?)</video_URL>|) {
        my $vid =$1;
        $video[$paper_nr] = $vid;
        print DBG "Video: $video[$paper_nr]\n";
		Deb_call_strucOut ();
        return;
    }
#
# newer versions of SPMS allow video upload, mostly as movies for slides 
#   (this code was the same as above, therefore "<'----'video" entered to comment it out)
#
    if (m|<----video_URL>(.*?)</video_URL>|) {
        my $vid =$1;
#        $vid =~ s|_download||;
        $video[$paper_nr] = $vid;
#        ($video[$paper_nr] = $vid) =~ s/_download//;
        print DBG "Video: $video[$paper_nr]\n";
		Deb_call_strucOut ();
        return;
    }
#
# actually the last SPMS version which allowed video upload seems to be for IPAC2016
#   now it seeems to be not available anymore; therefore "..._talks.mp4/m4v" 
#                          with <fileURL type="Talk Movies" type are taken
#
    if (m|<fileURL type=\"Talk Movies\">(.*?)</fileURL>|i) {
		if (m|wanted_file=\s*(.*?)</fileURL>|) {
			my $vid = lc $1;
			my $vex = lc $paper_code[$paper_nr]."_talk.mp4";
			if ($vid eq $vex) {
				$video[$paper_nr] = $vid;
				print DBG "11113-Video: $video[$paper_nr]\n";
			}
		}
		Deb_call_strucOut ();
        return;
    }
#
# tag <file>
#       -> <file_type abbrev="TRAN">Transparencies</file_type>
#          <file>
#             <file_type abbrev="TRAN">Transparencies</file_type>
#             <name>836-MOXACH01-talk.ppt</name>
#          </file>
#     InDiCo:
#          <file_type abbrev="pdf">Slides</file_type>
#
#>@    if (m|<file_type abbrev="(.*?)">(.*?)</file_type>|i) {
#>@        if ($1 eq "") {
#>@            $wget_filetype ="unk";
#>@        } else {
#>@            if ($1 eq $2) {
#>@                print DBG "<<-InDiCo-wget: $1\n";
#>@                $wget_filetype =$1;
#>@            } else {
#>@ #!                print DBG "<<-InDiCo->> $1:$2\n";
#>@            }
#>@        }
#>@		Deb_call_strucOut ();
#>@        return;
#>@    }
#
# tag <file>
#          <file>
#        -->  <platform abbrev="xxx">yyyyy</platform>
#             <file_type abbrev="x">yyyyy</file_type>
#             <name>file_name.type</name>
#          </file>
#
    if (m|<platform abbrev=".*?">(.*?)</platform>|i) {
        print DBG "SPMS:Platform= $1\n";
        $src_platform_last = $1;
		Deb_call_strucOut ();
        return;
    }
    #
    # SPMS transparencies/source
    #
    if (m/<file_type abbrev="(TRAN|TPDF)">/i) {
        print DBG "SPMS:Slides:o intro\n";
        $slide_open = 1;
		Deb_call_strucOut ();
        return;
    }
    if (m|<file_type abbrev="SRC">|i) {
        print DBG "SPMS:Source:o intro\n";
        $src_open = 1;
		Deb_call_strucOut ();
        return;
    }
    #
    # InDiCo transparencies/source
    #
    if (m|<file_type abbrev="(.*?)">(.*?)</file_type>|i) {
        $wget_filetype = $1;
        $wget_type     = $2;
        print DBG "<<-InDiCo-wget: $wget_filetype ($wget_type)\n";
        if ($wget_type =~ m|Slides|i) {
            print DBG "InDi:Slides:o intro\n";
            $slide_open = 1;
        }
		Deb_call_strucOut ();
        return;
    }
#
# tag <name> for InDiCo
#
    if ($conference_type_indico && m|<name>(.*?)</name>|) {
		print "##~~~## indico ###\n";
        $wget_filename = $1;
 		Deb_call_strucOut ();
        return;
    }
#
# tag <fileURL ...>
#       -> <fileURL type="...">URL to file</fileURL>
#
#               <fileURL type="Source File (MS Word or LaTeX)">http://icap06.gsi.de/cgi/download.pl?paper_id=MOMPMP01&amp;wanted_file=MOMPMP01.doc</fileURL>
#               <fileURL type="Portable Document Format">...wanted_file=MOMPMP01.PDF</fileURL>
#               <fileURL type="Portable Document Format">...wanted_file=MOMPMP01.PDF</fileURL>
#               <fileURL type="Transparencies">...wanted_file=MOMPMP01_talk.pdf</fileURL>
#               <fileURL type="Transparencies">...paper_id=MOMPMP01&amp;wanted_file=MOMPMP01_talk.ppt</fileURL>
#               <fileURL type="Portable Document Format">...paper_id=MOMPMP01&amp;wanted_file=MOMPMP01.PDF</fileURL>
#               <fileURL type="Post Script File">...paper_id=MOMPMP01&amp;wanted_file=MOMPMP01.PS</fileURL>
#				<fileURL type="Transparencies Movie">...paper_id=TUDC01&amp;wanted_file=TUDC01.ogg</fileURL>
#	introduced by ICALEPCS2017 but not following the rule being a pointer to the file server (therefore skipped in v27.3)
#				<fileURL type="Streaming Video">https://youtu.be/xyz</fileURL>
#
#				<file_type abbrev="MOV">Transparencies Movie</file_type>
#               <file_type abbrev="pdf">Slides</file_type>
#               <file_type abbrev="pdf">Paper</file_type>
#                                       Poster, Minutes, Agenda, Pictures, Text, More information,
#                                       Document, List of actions, Drawings, Proceedings, Live broadcast,
#                                       Video, Streaming video, Down-loadable video
# md5_hex($shared_hash, $papercode) for "&hcheck=265816F61F44A325918B70BDB0CBEBBF"
#
#
# actual status v30.x  SPMS v11.x.y
#				<fileURL type="Talk Movies">...paper_id=MOAO05&amp;wanted_file=moao05_talk.mp4</fileURL>
#				<fileURL type="Portable Document Format or Post Script">...paper_id=MOAO05&amp;wanted_file=MOAO05.PDF</fileURL>
#				<fileURL type="Source File (MS Word, Open Document or LaTeX)">...paper_id=MOAO05&amp;wanted_file=MOAO05.docx</fileURL>
#				<fileURL type="Transparencies">...paper_id=MOAO05&amp;wanted_file=MOAO05_TALK.PDF</fileURL>
#				<fileURL type="Other Supporting Files">...paper_id=TUAO02&amp;wanted_file=TUAO02f2.eps</fileURL>
#				<fileURL type="Poster">...paper_id=TUPP05&amp;wanted_file=TUPP05_poster.pdf</fileURL>
#
#
#  Example for command differences using wget or cURL
#  --------------------------------------------------
#      print WGETPDF "    curl -o \"$wget_fullfilename\" -k \"$wgetlines$hashline\"\n";
#      print WGETPDF "    wget -O \"$wget_fullfilename\" --no-check-certificate \"$wgetlines$hashline\"\n";
#
#
    if (m|<fileURL type=\"Streaming Video\">\s*(.*?)</fileURL>|) {
		print DBG "                       ## utube ## $1 for $paper_nr ###\n";
		$stream[$paper_nr] = $1;
 		Deb_call_strucOut ();
        return;
    }

    if (m|<fileURL(.*?)>\s*(.*?)</fileURL>|) {
        (my $wgetlines = $2) =~ s|&amp;|&|g;
        #
        # InDiCo specialty (coding "&" as "&amp;amp;"
        #
        $wgetlines =~ s|&amp;|&|g;
        #
        # JACoW way of file typing
        #
        if (m|wanted_file=\s*(.*?)</fileURL>|) {
            $wget_fullfilename = lc "$1";
            #
            # initiate zip file download for snapshot (once per paper_code)
            #
            if ($snapshot ne $paper_nr) {
                #
                # new paper code
                #
                $snapshot = $paper_nr;
                (my $snapline) = split (/&/, $wgetlines);
                $snapline     .= "&downthemall=recent";
				if ($PassPhraseDown ne "") {
					$snapline     .= "&hcheck=".md5_hex($PassPhraseDown, $paper_code[$paper_nr]);
				}
				print WGETOUT "    curl -o \"$paper_code[$paper_nr].zip\" -k \"$snapline\"\n";
                print WGETOUT "    unzip -o -d $paper_code[$paper_nr] $paper_code[$paper_nr].zip\n";
            }
            #
            # look for <paper_code>.pdf
            #          <paper_code>_talk.pdf
            #          <paper_code>_poster.pdf
			#		   <paper_code>_talk.mp4/m4v/...
			# ^ and $ introduced to make sure only correctly named files are downloaded
            #
            if ($wget_fullfilename =~ m/^$paper_code[$paper_nr](|_talk|_poster)\.(pdf|mp4)/i) {
				#
				# error in Matt's file line 
				#    in the line of <fileURL>....editor.zipdownload.pl?paper_id=WEPRO046&amp;wanted_file=SUSPSNE013_poster.pdf</fileURL>
				#    the "paper_id" is not the same as the "wanted_file" for paper_id which are PRIMARY="N"
	            #
				# <temporary fix>
				#    $wget_fullfilename contains filename with paper_code, type and extension 
				#
#				if ($wget_fullfilename =~ m/$paper_code[$paper_nr](_poster)\.pdf/i) {
#					$wget_fullfilename =~ m|^(.*?)[._]|;
#					my $arga1 = uc $1;
#					$wgetlines =~ m|paper_id=(.*?)\&|i;
#					my $arga2 = uc $1;
#					if ($arga1 ne $arga2) {
#						#
#						# if paper_id is not paper_code => exchange it
#						#
#						$wgetlines =~ s|$arga2|$arga1|;
#					}
#				}
#				# </temporary fix>#
				my $arg_pid = "";
				if ($wgetlines =~ m|paper_id=(.*?)\&|i) {
					$arg_pid = uc $1;
				}
				#
				# this should be optimized as it can happen that the same file appears not directly after 
				#
				if ($wget_fullfilename ne $filename_last_used) {
				    my $hashline = "";
					if ($arg_pid ne $paper_code[$paper_nr]) {
						#
						# only print message if even the secondary code doesn't match
						#
						if ($arg_pid ne $prg_code[$paper_nr][$prg_code_p[$paper_nr]]) {
							print "?paper_id=$arg_pid <> $paper_code[$paper_nr]\n";
						}
						$hashline = "&hcheck=".md5_hex($PassPhraseDown, $arg_pid);
					} else {
						if ($PassPhraseDown ne "") {
							$hashline = "&hcheck=".md5_hex($PassPhraseDown, $paper_code[$paper_nr]);
						}
					}
                    #
                    # store actual filename for next download candidate
                    #
                    $filename_last_used = $wget_fullfilename;
                    #
                    # write into batch file for download
                    #
                    print WGETPDF "    curl -o \"$wget_fullfilename\" -k \"$wgetlines$hashline\"\n";
                    #
                    # MOVE commands are depended on content
                    #
                    # Paper only
                    #
					#	print WGETPDF  "REM    is present #########\n";   
					my $file_exists;
					$file_exists	= 0;
                    if ($wget_fullfilename =~ m/^$paper_code[$paper_nr]\.pdf$/i) {
                        ($wrt_dir = $raw_paper_directory) =~ s/\.\./\./;
                        print WGETPDF  "    $WL_Move \"$wget_fullfilename\" \"$wrt_dir$wget_fullfilename\"\n";
						$file_exists	= 1 if (-e "$wrt_dir$wget_fullfilename");
						if ($pdf_update_only && $file_exists) {
							print PAPEROUT "REM curl -o \"$wget_fullfilename\" -k \"$wgetlines$hashline\"\n";
						} else {
							print PAPEROUT "    curl -o \"$wget_fullfilename\" -k \"$wgetlines$hashline\"\n";
							print PAPEROUT "    $WL_Move \"$wget_fullfilename\" \"$wrt_dir$wget_fullfilename\"\n";
						}
                    }
                    #
                    # Talks/Slides
                    #
                    if ($wget_fullfilename =~ m/^$paper_code[$paper_nr]_talk\.pdf$/i) {
                        ($wrt_dir = $slides_directory) =~ s/\.\./\./;
                        print WGETPDF  "    $WL_Move \"$wget_fullfilename\" \"$wrt_dir$wget_fullfilename\"\n";
						$file_exists	= 1 if (-e "$wrt_dir$wget_fullfilename");
						if ($pdf_update_only && $file_exists) {
							print TALKSOUT "REM curl -o \"$wget_fullfilename\" -k \"$wgetlines$hashline\"\n";
 						} else {
							print TALKSOUT "    curl -o \"$wget_fullfilename\" -k \"$wgetlines$hashline\"\n";
							print TALKSOUT "    $WL_Move \"$wget_fullfilename\" \"$wrt_dir$wget_fullfilename\"\n";
							clean_pdf_metadata (*TALKSCLN);
						}
                    }
                    #
                    # Talk movies (actual only mp4)
                    #
                    if ($wget_fullfilename =~ m/^$paper_code[$paper_nr]_talk\.mp4$/i) {
                        ($wrt_dir = $video_directory) =~ s/\.\./\./;
                        print WGETPDF  "    $WL_Move \"$wget_fullfilename\" \"$wrt_dir$wget_fullfilename\"\n";
						$file_exists	= 1 if (-e "$wrt_dir$wget_fullfilename");
						if ($pdf_update_only && $file_exists) {
							print VIDEOOUT "REM curl -o \"$wget_fullfilename\" -k \"$wgetlines$hashline\"\n";
 						} else {
							print VIDEOOUT "    curl -o \"$wget_fullfilename\" -k \"$wgetlines$hashline\"\n";
							print VIDEOOUT "    $WL_Move \"$wget_fullfilename\" \"$wrt_dir$wget_fullfilename\"\n";
						}
                    }
                    #
                    # Poster
                    #
                    if ($wget_fullfilename =~ m/^$paper_code[$paper_nr]_poster\.pdf$/i) {
                        ($wrt_dir = $poster_directory) =~ s/\.\./\./;
                        print WGETPDF   "    $WL_Move \"$wget_fullfilename\" \"$wrt_dir$wget_fullfilename\"\n";
						$file_exists	= 1 if (-e "$wrt_dir$wget_fullfilename");
						if ($pdf_update_only && $file_exists) {
							print POSTEROUT "REM curl -o \"$wget_fullfilename\" -k \"$wgetlines$hashline\"\n";
 						} else {
							print POSTEROUT "    curl -o \"$wget_fullfilename\" -k \"$wgetlines$hashline\"\n";
							print POSTEROUT "    $WL_Move \"$wget_fullfilename\" \"$wrt_dir$wget_fullfilename\"\n";
							clean_pdf_metadata (*POSTERCLN);
						}
                    }
                    print POSTOUT "    <$wget_fullfilename>\n";
                } else {
                    print DBG "==:$wget_fullfilename--l:$filename_last_used\n";
                }
            }
            if ($wget_fullfilename =~ m|\.ppt|i) {
                print POSTOUT "    <$wget_fullfilename>\n";
            }
        } else {
            #
            # InDiCo part
            #
            # slides or other material?
            #
            $wget_fullfilename = lc $paper_code[$paper_nr];
            my $dispo = "   ";
            if ($wget_type =~ m|Slides|i) {
                $wget_fullfilename .= "_talk";
                ($wrt_dir = $slides_directory) =~ s/\.\./\./;
                if ($wget_filetype eq "pdf") {
                    $wget_fullfilename .= ".$wget_filetype";
                    $dispo = "   ";
                } else {
                    $wget_fullfilename .= "-$wget_filename";
                    $dispo = "REM";
                }
            } else {
                #
                # pdf file (direct usable or else)?
                #
                ($wrt_dir = $raw_paper_directory) =~ s/\.\./\./;
                if ($wget_filetype eq "pdf") {
                    $wget_fullfilename .= ".$wget_filetype";
                    $dispo = "   ";
                } else {
                    $wget_fullfilename .= "-$wget_filename";
                    $dispo = "REM";
                }
            }
            print WGETOUT "$dispo curl -o \"$wget_fullfilename\" -k \"$wgetlines\"\n";
            print WGETOUT "$dispo $WL_Move \"$wget_fullfilename\" \"$wrt_dir$wget_fullfilename\"\n";
        }
        print DBG "File Location: $wgetlines\n";
 		Deb_call_strucOut ();
        return;
    }
#
# </file>
#
    if (m|</file|) {
        print DBG "Files: end\n";
        if ($slide_open) {
             if ($slide_name) {
                if ($conference_type_indico) {
                    $slides[$paper_nr] = lc($paper_code[$paper_nr])."_talk.pdf";
                    print DBG "Slides:e-InDi $slide_name\n";
                } else {
                    $slides[$paper_nr] = $slide_name;
                    print DBG "Slides:e-SPMS $slide_name\n";
                }
             }
            $slide_open = 0;
        }
        if ($src_open) {
            $src_open = 0;
        }
 		Deb_call_strucOut ();
        return;
    }
#
# Paper Editor
#
    if (m|<editor>\s*(.*?)\s*</editor>|) {
        $key = $1;
        print DBG "###> Editor: ª$1´\n";
        $paper_editor[$paper_nr] = $key;
 		Deb_call_strucOut ();
        return;
    }
#
# QA Editor
#
    if (m|<final_qa>\s*(.*?)\s*</final_qa>|) {
        $key = $1;
        print DBG "###> QAEditor: ª$1´\n";
        $qa_editor[$paper_nr] = $key;
 		Deb_call_strucOut ();
        return;
    }
#
# is this a known structure?
#
    if (m|^(.*?)$|) {
        #
        # check for running text inside <abstract>, <agency>, <title>, and <footnote>
        #       (whatever that might be...)
        #
        s/\s+/ /;
        if ($keyword_open) {
            $keyw_text .= $_;
			Deb_call_strucOut ();
            return;
        }
        if ($abstract_open) {
            $abstract_text .= " $_";
			Deb_call_strucOut ();
            return;
        }
        if ($title_open) {
            $title_text .= " $_";
			Deb_call_strucOut ();
            return;
        }
        if ($footnote_open) {
            $footnote_text .= " $_\\Space ";
			Deb_call_strucOut ();
            return;
        }
        if ($agency_open) {
            $agency_text .= " $_";
			Deb_call_strucOut ();
            return;
        }
        if ($slide_open) {
            if (m|<name>(.*?)</name>|) {
                my $slides = $1;
				# print "### $slides\n";
                if ($conference_type_indico) {
                    if ($slides =~ m/\.ppt|\.pdf/i) {
                        $slide_name = lc $slides;             # what to do here? 090728
                        print DBG "Slides:+ $slide_name\n";
                    } else {
                        print DBG "Slides:- $slides\n";
                        $slide_open = 0;
                    }
                } else {
                    if ($slides =~ m/\.pdf/i) {
                        $slide_name = lc $slides;             # what to do here? 090728
                        print DBG "Slides:+ $slide_name\n";
                    } else {
                        print DBG "Slides:- $slides\n";
                        $slide_open = 0;
                    }
                }
				Deb_call_strucOut ();
                return;
            }
        }
        if ($src_open) {
#            print SRCTYPE ("> $_\n");
            if (m|<name>(.*?)\.(.*?)</name>|) {
                my $accpap = lc ($1."\.".$2);
                my $doc = lc ($1."\.".substr ($2, 0, 3));  # reduce filetype to 3 letter so that DOC and DOOX are the same for the statistics
                my $src;
                my $pa = lc $paper_code[$paper_nr];
                my $abc = $doc =~ m|^$pa\..*?|;            # make sure that filename starts with <papercode>
                if ($src_docname ne $doc) {
                    print SRCTYPE sprintf ("------------------------\n");
                }
                print SRCTYPE sprintf ("       [%8s]<%4i>  (%s) [%s]\n", $pa, $paper_nr, uc $accpap, $src_platform_last);
                if ($abc) {
                    if ($src_docname ne $doc) {
                        $src_docname = $doc;
                        $src_nr++;
                        $src = "???";
                        if ($src_docname =~ m/\.doc/i) {
                            $src_doc++;
                            $src = "DOC";
                        }
                        if ($src_docname =~ m/\.odt/i) {
                            $src_odt++;
                            $src = "ODT";
                        }
                        if ($src_docname =~ m/\.tex/i) {
                            $src_tex++;
                            $src = "TeX";
                        }
                        print SRCTYPE sprintf (" %4i: %-12s (%4i:%4i:%4i) [%5.1f:%5.1f:%5.1f] %3s\n",
                                $src_nr, $src_docname,
                                $src_doc,             $src_tex,             $src_odt,
                                $src_doc*100/$src_nr, $src_tex*100/$src_nr, $src_odt*100/$src_nr,
                                $src);
                    } else {
                        
                    }
                } else {
                    #
                    # document doesn't start with "<papercode>." is it a secondary and does the primary fit??
                    #
					$pa = lc $prg_code[$paper_nr][$prg_code_p[$paper_nr]];
					# does it start with the secondary paper code?
					if ($doc !~ m|^$pa\..*?|) {
						print         "--> Papercode: $pa ### Documentname: $doc\n";
						print SRCTYPE "--> Papercode: $pa ### Documentname: $doc\n";
						print DBG     "--> Papercode: $pa ### Documentname: $doc\n";
					} else {
						#
						# count it if filetype is one of the three 
						#
						# ???????????????????????????
					}
                }
				Deb_call_strucOut ();
                return;
            }
            print DROP sprintf ("?s?> text dropped in line %5i: ª%s´\n", $., $_);
        }
        print DROP sprintf ("?e?> text dropped in line %5i: ª%s´\n", $., $_);
    }
	Deb_call_strucOut ();
	return;
}
#---------------------------
# generate all classification infos
#
sub generate_class_info  {
	Deb_call_strucIn ("generate_class_info");

 my @csa;
 my $csa;
 for ($i=0; $i<=$paper_nr; $i++) {
 #@                           72  74 146 147 152
#@     $csa[$i] = sprintf ("%-72s  %-72s %4i %-10s\n", $paper_mcls[$i], $paper_scls[$i], $i, $paper_code[$i]);
     $csa[$i] = sprintf ("%s@%s@%4i@%s@\n", $paper_mcls[$i], $paper_scls[$i], $i, $paper_code[$i]);
 }
 my @csa_sort = sort @csa;
#
# base html file for classification list
#
 my $classfile   = $html_directory."class.htm";
 print DBG "== List of Classifications\n";
 open (CFHTM, ">:encoding(UTF-8)", $classfile) or die ("Cannot open '$classfile' -- $! (line ",__LINE__,")\n");
 print CFHTM $html_content_type."\n",
             "<html lang=\"en\">\n",
             "<head>\n",
             "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#			 "  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
			 "  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
             "  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
             "  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
             "  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
             "  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
             "  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
             "  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
             "  <title>$conference_name - List of Classifications</title>\n",
             "</head>\n\n",
             "<frameset rows=\"",$banner_height,"px, *\">\n",
             "  <frame src=\"b0nner.htm\" name=\"b0nner\" frameborder=\"1\" />\n",
             "  <frameset cols=\"30%,*\">\n",
             "    <frame src=\"class1.htm\" name=\"left\"  frameborder=\"1\" />\n",
             "    <frame src=\"class2.htm\" name=\"right\" frameborder=\"1\" />\n",
             "  </frameset>\n",
             "  <noframes>\n",
             "    <body class=\"debug\">\n",
             "    <p>This page uses frames, but your browser doesn't support them.</p>\n",
             "    </body>\n",
             "  </noframes>\n",
             "</frameset>\n",
             "</html>\n";
 close (CFHTM);
#
# classification file (contains main- and sub-classification)
#
 $classfile   = $html_directory."class1.htm";
 open (CXHTM, ">:encoding(UTF-8)", $classfile) or die ("Cannot open '$classfile' -- $! (line ",__LINE__,")\n");
 print CXHTM $html_content_type."\n",
             "<html lang=\"en\">\n",
             "<head>\n",
             "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#			 "  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
             "  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
             "  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
             "  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
             "  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
             "  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
             "  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
             "  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
             "  <title>$conference_name - List of classifications</title>\n",
             "</head>\n\n",
             "<body class=\"debug\">\n",
             "<p class=\"list-title\">List of Classifications</p>\n";
  my $ck;
#    $mcls;                 # actual classification
  my $mcls_lst  = "";       # last processed classification
#    $scls;                 # actual sub-classification
  my $scls_lst  = "";       # last processed sub-classification
     $cls_fl    = -1;       # count of class-files
     $cls_open  = 0;        # classification html file open
  my $cls_chg   = 1;        # (sub)class change
  my $papcs;
  for ($icl=0; $icl<=$paper_nr; $icl++) {
	  $ck = $csa_sort[$icl];
	 ($mcls, $scls, $pap, $papcs) = split (/@/, $ck);
	  if ($mcls ne $mcls_lst) {
		 #
		 # we got a new Main Classification
		 #    - keep new class string for comparision (without &nbsp;)
		 #    - substitute spaces by unbreakable ones
		 #    - close old class file
		 #    - open new one
		 #
		 $mcls_lst = $mcls;
		 $mcls     =~ s/ /&nbsp;/g;
		 #
		 # close still open classification file
		 #
		 if ($cls_open) {
			 class_file_close ();
			 if ($scls ne " ") {
				 print CXHTM "   </ul>\n";
			 }
		 }
		 class_file_open ();
		 if ($scls eq " ") {
			#
			# create new main entry (without sub entry)
			#        file pointer => main entry
			#
			print CXHTM "   <span>&#9658;&nbsp;<a class=\"class-wb\" href=\"$cls_fl_str\" target=\"right\">$mcls</a></span><br />\n";
		 } else {
			#
			# create new main entry
			#        new sub entry
			#        file pointer => sub entry
			#
			print CXHTM "   <span class=\"w\">&#9658;&nbsp;$mcls</span>\n";
			print CXHTM "   <ul class=\"cls-ul\">\n",
						"       <li><a class=\"class-b\" href=\"$cls_fl_str\" target=\"right\">$scls</a></li>\n";
		 }
		 $scls_lst = $scls;
	  } else {
		 if ($scls ne $scls_lst) {
			$scls_lst = $scls;
			# close old file
			# create new sub entry
			#        file => sub entry
			#
			class_file_close ();
			class_file_open ();
			print CXHTM "       <li><a class=\"class-b\" href=\"$cls_fl_str\" target=\"right\">$scls</a></li>\n";
		 }
	  }
		#	
		# SCHTM for multiple program codes, the secondary paper codes are skipped as main entry
		#
		if ($prg_code[$pap][$prg_code_p[$pap]] eq $paper_code[$pap]) {
		  print DBG $ck;
		  convert_spec_chars ($title[$pap], "title-SC");
		  print SCHTM "    <tr class=\"tablerow\" id=\"$paper_code[$pap]\">\n";
		  my $lc_paper = ".".$paper_directory.lc($paper_code[$pap]).".pdf";
		  if ($paper_with_pdf[$pap]) {
			  #
			  # give link (and size as tooltip)
			  #
			  print SCHTM "        <td class=\"papkey\"><a class=\"papkey-hov\" href=\"$lc_paper\" onmouseover=\"XBT(this, {text: '$paper_pdf_size[$pap]', className: 'xbtooltip'})\"",
						  " target=\"pdf\">$paper_code[$pap]</a></td>\n",
		  } else {
		  #---
			if ($conference_type_indico) {
				#
				# for InDiCo conferences the paper_code name is not shown (pure numeric)
				#
				print SCHTM "        <td class=\"papkey\"></td>\n";
			} else {
				my $class_c = "papkey";
				if ($paper_strike_thru) {
					$class_c = "papkeystr";
				}
				#
				# Multiple Program Codes additions (do not stroke out and change tooltip text)
				#
				if ($paper_code[$pap] ne $prg_code[$pap][$prg_code_p[$pap]]) {
					$paper_pdf_size[$pap] = "&nbsp;Check primary paper code below for contribution&nbsp;";
					$class_c = "papkey";
				}
				print SCHTM "        <td class=\"$class_c\"><div class=\"xbtooltipstr\" onmouseover=\"XBT(this, {text: '$paper_pdf_size[$pap]', className: 'xbtooltipstrc'})\">$paper_code[$pap]</div></td>\n";
			}
		  }
		  #---
		  # SCHTM output Paper Title and Page number in proceedings
		  #
		  print SCHTM "        <td class=\"paptitle\">$_</td>\n";
		  if ($paper_with_pdf[$pap]) {
			  $page_start_toc = $page_start[$pap];
			  if ($page_start_toc == 0) {
				  $page_start_toc = 1;
			  }
			  if ($conference_pre) {
				  # Pre-Press Release
				  $page_start_toc = -1;
			  }
			  print SCHTM "        <td class=\"pappage\">$page_start_toc</td>\n";
		  } else {
			  print SCHTM "        <td>&nbsp;</td>\n";
		  }
		  #######
			#
			# SCHTM for multiple program codes output additional infos (primary paper code)
			#
			if ($#{$prg_code[$pap]} > 0) {
				#
				# there is (at least) one secondary code
				#  => easy: $prg_code[$pap][$prg_code_p[$pap]] => give primary code e.g. TUPRO023
				#
				for ($i = 0; $i <= $#{$prg_code[$pap]}; $i++) {
					my $sesslink	= find_lc_session ($prg_code[$pap][$i]); 
					if ($prg_code[$pap][$i] ne $paper_code[$pap]) {
						print SCHTM "    </tr>\n";
						print SCHTM "    <tr class=\"tablerow\">\n";
						print SCHTM "        <td class=\"papkey\"><a class=\"papkey-hov\" href=\"$sesslink.htm#$prg_code[$pap][$i]\" target=\"_self\">$prg_code[$pap][$i]</a></td>\n";
						print SCHTM "        <td class=\"comment\">$code_link_altern_text</td>\n";
						print SCHTM "        <td>&nbsp;</td>\n";
					}
				}
			}
		  ######
		  #
		  # NOMAT? 
		  #		are there paper and/or slides, or does the author provide nothing for publication?
		  #
#InAc	  NoMat (*SCHTM, $pap, $sess);
		  #
		  ######
		  #
		  # SCHTM <ul> prepare Author list
		  #	
		  print SCHTM "    </tr>\n",
					  "    <tr class=\"tablerow\">\n",
					  "        <td>&nbsp;</td>\n",
					  "        <td><ul>\n";
		  #
		  # list with authors over institutes
		  #
		  my $authorlist = "";
		  my $numele = $authors[$pap];
		  my @contrib_seq;
		  my $author_ac;
		  undef @contrib_seq;
		  my $i1;
		  my $act_ins_abb;    # author's institute abbreviation
		  my $act_idx;
		  $j = 0;
		  while ($j <= $numele) {
			  for ($auth=0; $auth<=$numele; $auth++) {
				  if (!defined $contrib_seq[$auth]) {
					  $act_ins_abb = $contrib_abb[$pap][$auth];
					  $act_idx     = $auth;
					  $author_ac   = "$contrib_ini[$pap][$auth] $contrib_lst[$pap][$auth]";
					  if ($author_ac eq $main_author[$pap]) {
						  $authorlist = "<strong>$contrib_in8[$pap][$auth]&nbsp;$contrib_ln8[$pap][$auth]</strong>"; #utf-8
					  } else {
						  $authorlist =         "$contrib_in8[$pap][$auth]&nbsp;$contrib_ln8[$pap][$auth]";          #utf-8
					  }
					  $contrib_seq[$auth]++;
					  $i1 = $auth + 1;
					  last;
				  }
			  }
			  for ($auth=$i1; $auth<=$numele; $auth++) {
				   if (!defined $contrib_seq[$auth] && $act_ins_abb eq $contrib_abb[$pap][$auth]) {
						$contrib_seq[$auth]++;
						$author_ac = "$contrib_ini[$pap][$auth] $contrib_lst[$pap][$auth]";
						if ($author_ac eq $main_author[$pap]) {
							$authorlist .= ", <strong>$contrib_in8[$pap][$auth]&nbsp;$contrib_ln8[$pap][$auth]</strong>"; #utf-8
						} else {
							$authorlist .= ", $contrib_in8[$pap][$auth]&nbsp;$contrib_ln8[$pap][$auth]";                  #utf-8
						}
					}
			  }
			  convert_spec_chars ($authorlist, "authorlist-SC");
			  print SCHTM "                <li><span class=\"author_cl\">$_</span><br />\n";
			  #
			  # special InDiCo case: Abbreviation == Institute's name
			  #
			  if ($contrib_abb[$pap][$act_idx] eq $contrib_ins[$pap][$act_idx] or
					$contrib_ins[$pap][$act_idx] eq "") {
				  convert_spec_chars ("$contrib_abb[$pap][$act_idx]", "contrib_abb-SC");
			  } else {
				  convert_spec_chars ("$contrib_abb[$pap][$act_idx], $contrib_ins[$pap][$act_idx]", "contrib_abb-ins-SC");
			  }
			  print SCHTM "                       $_</li>\n";
			  $j = $numele + 1;
			  for ($i=0; $i<=$numele; $i++) {
				  if (!defined $contrib_seq[$i]) {
					  $j = $i;
					  last;
				  }
			  }
		  } #outer while <= numele
		  print SCHTM "        </ul></td>\n",
					 "        <td>&nbsp;</td>\n",
					 "    </tr>\n";
		  #
		  # is there an "funding note"/"abstract"/"foot note" to include?
		  #
		  include_abstract_etc (*SCHTM);
	} else { # else not primary
		#
		# skipped records for secondary paper_codes
		#
		print DBG "SCHTM-skip $paper_code[$pap] <act--prim> $prg_code[$pap][$prg_code_p[$pap]]\n";
	} # end skip (secondary) paper
  }
  $num_of_classifications = $cls_fl;
  #
  # end of paper table
  #
  class_file_close ();
  #
  # end of (sub)classification table
  #
  print CXHTM "   </ul>\n",
              "</body>\n\n",
              "</html>\n";
  close (CXHTM);
  my $class2file   = $html_directory."class2.htm";
  open (CBHTM, ">:encoding(UTF-8)", $class2file) or die ("Cannot open '$class2file' -- $! (line ",__LINE__,")\n");
  print CBHTM  $html_content_type."\n",
               "<html lang=\"en\">\n",
               "<head>\n",
               "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#			   "  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
               "  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
               "  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
               "  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
               "  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
               "  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
			   "  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
               "  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
               "  <title>$conference_name - List of Classifications</title>\n",
               "</head>\n\n",
               "<body>\n",                 # bgcolor=\"\#ffffff\">\n",
               "<br />\n",
               "<hr />\n",
               "<span class=\"list-item\">Click on a Classification to display a list of papers.</span>\n",
               "<br />\n",
               "</body>\n",
               "</html>\n";
  close (CBHTM);
  Deb_call_strucOut ();
}
#---------------------------
# open classification file
#
sub class_file_open  {
	Deb_call_strucIn ("class_file_open ($mcls/$scls)");

    $cls_fl_str = sprintf ("clas%03i.htm", ++$cls_fl);
    my $lc_cfs  = $html_directory.$cls_fl_str;
    open (SCHTM, ">:encoding(UTF-8)", $lc_cfs) or die ("Cannot open '$lc_cfs' -- $! (line ",__LINE__,")\n");
    $cls_open = 1;
    print SCHTM $html_content_type."\n",
                "<html lang=\"en\">\n",
                "<head>\n",
                "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#			    "  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
                "  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
                "  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
				"  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
                "  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
                "  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
                "  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
                "  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
                "  <script src=\"xbt.js\"></script>\n",
                "  <script src=\"Hyphenator.js\"></script>\n",
                "  <script src=\"en.js\"></script>\n",
                "  <script type=\"text/javascript\">Hyphenator.config({remoteloading : false}); Hyphenator.run();</script>\n",
                "\n";
    my $MSClassOL = "";
    my $MSClassTL = "";
    if ($scls eq " ") {
        $MSClassOL = $mcls;
        $MSClassTL = $mcls;
    } else {
        $MSClassOL = "$mcls / $scls";
        $MSClassTL = "$mcls<br />$scls";
    }
    print SCHTM "  <title>$conference_name - Classification: $MSClassOL</title>\n",
                "</head>\n\n",
                "<body class=\"debug\">\n";

    print SCHTM "<span class=\"sessionheader\">$MSClassTL</span>\n",#
#~#                "<table  class=\"tabledef\" title=\"All papers with Classification: $MSClassOL\">\n",
                "<table  class=\"tabledef\">\n",
#                "  <tbody>\n",
                "    <tr class=\"tablerow\">\n",
                "        <th class=\"papercodehead\">Paper</th>\n",
                "        <th class=\"papertitlehead\">Title</th>\n",
                "        <th class=\"papernumberhead\">Page</th>\n",
                "    </tr>\n";
	Deb_call_strucOut ();
}
#---------------------------
# close classification file
#
sub class_file_close {
	Deb_call_strucIn ("class_file_close");

    print SCHTM "</table>\n",
                "<br />\n",
                "</body>\n\n",
                "</html>\n";
    close (SCHTM);
    $cls_open = 0;
	Deb_call_strucOut ();
}
#-----------------------
#
# revert_from_context
#
#    make sure that all control sequences
#    are pure LaTeX ones !!
#
sub revert_from_context {
	Deb_call_strucIn ("revert_from_context");

    $_ = $_[0];   # was @_[0]
    if (!defined $_ || $_ eq "") {
        $_ = "";
		Deb_call_strucOut ();
        return;
    }
    s#\|-\|#-#g;
    s#\|/\|#/#g;
    s#\\high\{\$-\$\}#\\high\{-\}#g;
    s#\\startitemize\[n,packed,broad,joinedup\]#\\begin{itemize}#g;
    s#\\startitemize\[a,packed,broad,joinedup\]#\\begin{itemize}\\renewcommand{\\theenumi}{\\alph{enumi}}#g;
    s#\\stopitemize#\\end{itemize}#g;
	Deb_call_strucOut ();
    return $_;
}
#-----------------------
#
# convert_entity_chars2iso
#
#    convert all html entities to
#    at least ISO-Lation 1 chars
#    if unique (better UTF-8!!!!)
#
sub convert_entity_chars2iso {
	Deb_call_strucIn ("convert_entity_chars2iso");

    $_ = $_[0];   # was @_[0]
    if ($_ eq "") {
		Deb_call_strucOut ();
        return;
    }
    s|&amp;|&|g;
    s|&#228;|‰|g;
    s|&#246;|ˆ|g;
    s|&#252;|¸|g;
    s|&#261;|a|g;        # a-ogonek
    s|&#262;|C|g;        # C-acute
    s|&#263;|c|g;        # c-acute
    s|&#268;|C|g;        # C-caron
    s|&#269;|c|g;        # c-caron
    s|&#279;|e|g;        # e-dot above
    s|&#279;|e|g;        # LATIN SMALL LETTER E WITH DOT ABOVE EDIT  U+0117 &#279;
#230917    s|&#281;|e|g;        # LATIN SMALL LETTER E WITH OGONEK  U+0119 &#281; 
    s|&#322;|l|g;        # polish l-slash
    s|&#324;|n|g;        # n-acute
    s|&#350;|S|g;        # S-cedilla
    s|&#351;|S|g;        # s-cedilla
    s|&#352;|S|g;        # S-caron
    s|&#353;|s|g;        # s-caron
    s|&#378;|z|g;        # z-acute
    s|&#380;|z|g;        # z-dot
#
# diacritical letters (and others)
#
   s|&Acirc;|¬|g;
   s|&acirc;|‚|g;
   s|&Atilde;|√|g;
   s|&atilde;|„|g;
   s|&AElig;|∆|g;
   s|&aelig;|Ê|g;
   s|&Aacute;|¡|g;
   s|&aacute;|·|g;
   s|&Aring;|≈|g;
   s|&aring;|Â|g;
   s|&Agrave;|¿|g;
   s|&agrave;|‡|g;
   s|&Auml;|ƒ|g;
   s|&auml;|‰|g;
#
   s|&Ccedil;|«|g;
   s|&ccedil;|Á|g;
#
   s|&Ecirc;| |g;
   s|&ecirc;|Í|g;
   s|&ETH;|–|g;
   s|&eth;||g;
   s|&Egrave;|»|g;    #check!!!
   s|&egrave;|Ë|g;    #check!!!
   s|&Eacute;|…|g;
   s|&eacute;|È|g;
   s|&Euml;|À|g;
   s|&euml;|Î|g;
#
   s|&Icirc;|Œ|g;
   s|&icirc;|Ó|g;
   s|&Iacute;|Õ|g;
   s|&iacute;|Ì|g;
   s|&Iuml;|œ|g;
   s|&iuml;|Ô|g;
   s|&Igrave;|Ã|g;
   s|&igrave;|Ï|g;
#
   s|&Ntilde;|—|g;
   s|&ntilde;|Ò|g;
#
   s|&Ograve;|“|g;
   s|&ograve;|Ú|g;
   s|&Ouml;|÷|g;
   s|&ouml;|ˆ|g;
   s|&Ocirc;|‘|g;
   s|&ocirc;|Ù|g;
   s|&Otilde;|’|g;
   s|&otilde;|ı|g;
   s|&Oacute;|”|g;
   s|&oacute;|Û|g;
   s|&Oslash;|ÿ|g;
   s|&oslash;|¯|g;
#
   s|&szlig;|ﬂ|g;
#
   s|&THORN;|ﬁ|g;
   s|&thorn;|˛|g;
#
   s|&Uacute;|⁄|g;
   s|&uacute;|˙|g;
   s|&Ucirc;|€|g;
   s|&ucirc;|˚|g;
   s|&Uuml;|‹|g;
   s|&uuml;|¸|g;
   s|&Ugrave;|Ÿ|g;
   s|&ugrave;|˘|g;
#
   s|&Yacute;|›|g;
   s|&yacute;|˝|g;
   s|&yuml;|ˇ|g;

   Deb_call_strucOut ();
}
#
#---------------------------
# write a default Index file (indexloc.htm)
#
sub generate_default_html  {
  Deb_call_strucIn ("generate_default_html");

  open (INDEX, ">:encoding(UTF-8)", "indexloc.htm") or croak "\n could not create local default 'indexloc.htm'! (line ",__LINE__,")\n";
  my $con_logo  = $logo_image;
  $con_logo =~ s|\.\./||;

  print INDEX "<!DOCTYPE html>\n";
  print INDEX "<html lang=\"en\">\n";
  print INDEX "<head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n";
#  print INDEX "      <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n";
  print INDEX "<title>$conference_name - Contributions to the Proceedings</title>\n";
  print INDEX "</head>\n";
  print INDEX "<body alink=\"\#cc3300\" bgcolor=\"\#ffffff\" link=\"\#cc3300\" text=\"\#0066cc\" vlink=\"\#cc3300\">\n";
  print INDEX "<div align=\"center\">\n";
  print INDEX "  <center>\n";
  print INDEX "  <table style=\"border-collapse: collapse;\" id=\"AutoNumber1\" border=\"0\" bordercolor=\"\#111111\" cellpadding=\"0\" cellspacing=\"0\" width=\"75%\">\n";
  print INDEX "    <tbody>\n";
  print INDEX "    <tr><td colspan=\"3\" align=\"right\" width=\"100%\">&nbsp;</td></tr>\n";
  print INDEX "    <tr>\n";
  print INDEX "      <td colspan=\"2\" align=\"left\" width=\"100%\"><font face=\"Arial, Helvetica, sans-serif\" size=\"6\"><b>$conference_name</b></font>\n";
  print INDEX "                                                <font face=\"Arial, Helvetica, sans-serif\" size=\"5\">Contributions to the Proceedings</font>\n";
  print INDEX "                                            </td><td align=\"right\">\n";
  print INDEX "                                            <img alt=\"conference logo\" src=\"$con_logo\" border=\"0\" width=\"$logo_width\" height=\"$logo_height\" />\n";
  print INDEX "      </td></tr>\n";
  print INDEX "    <tr><td colspan=\"3\" width=\"100%\"><hr /></td></tr>\n";
  print INDEX "    <tr><td colspan=\"3\" width=\"100%\">\n";
  print INDEX "          <font face=\"Arial, Helvetica, sans-serif\">Contributions to the conference have been classified into the following main groups:<br />\n";
  print INDEX "            invited papers, contributed papers, and poster presentations. The links below lead to more detailed listings and eventually\n";
  print INDEX "            to Acrobat Format (PDF) files containing the papers and many of the slides from the oral presentations.\n";
  print INDEX "          </font>\n";
  print INDEX "        </td></tr>\n";
  print INDEX "    <tr><td colspan=\"3\" width=\"100%\">&nbsp;</td></tr>\n";
  print INDEX "    <tr>\n";
  print INDEX "      <td width=\"50%\"><img alt=\"conference logo\" src=\"$con_logo\" border=\"0\" height=\"500\" width=\"356\" /><br />Special logo here</td>\n";
  print INDEX "      <td colspan=\"2\" align=\"center\" valign=\"top\" width=\"30%\">\n";
  print INDEX "         <table style=\"border-collapse: collapse;\" border=\"0\" bordercolor=\"\#111111\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\">\n";
  print INDEX "           <tbody><tr>\n";
  print INDEX "             <td width=\"2%\">&nbsp;</td><td width=\"40%\">&nbsp;</td><td width=\"2%\">&nbsp;</td>\n";
  print INDEX "             <td width=\"50%\"><font face=\"Arial, Helvetica, sans-serif\">\n";
  print INDEX "                <a style=\"font-family: Arial; font-size: 12pt;\" target=\"second\" href=\"\#\#program%20committee\#\#\">Programme Committee</a></font></td>\n";
  print INDEX "             <td width=\"2%\">&nbsp;</td>\n";
  print INDEX "           </tr><tr><td colspan=\"5\">&nbsp;</td></tr>\n";
  print INDEX "           <tr><td colspan=\"3\">&nbsp;</td>\n";
  print INDEX "             <td width=\"50%\">\n";
  print INDEX "               <font face=\"Arial, Helvetica, sans-serif\">\n";
  print INDEX "                   <a style=\"font-family: Arial; font-size: 12pt;\" target=\"second\" href=\"\#\#organizing%20committee\#\#\">Local Organizing Committee</a>\n";
  print INDEX "               </font>\n";
  print INDEX "             </td><td width=\"2%\">&nbsp;</td>\n";
  print INDEX "           </tr><tr><td colspan=\"5\"></td>\n";
  print INDEX "           </tr><tr><td colspan=\"3\">&nbsp;</td>\n";
  print INDEX "             <td width=\"50%\">\n";
  print INDEX "               <font face=\"Arial, Helvetica, sans-serif\">\n";
  print INDEX "                   <a style=\"font-family: Arial; font-size: 12pt;\" target=\"second\" href=\"html/sessi0n.htm\">Table of Sessions</a>\n";
  print INDEX "               </font>\n";
  print INDEX "             </td><td width=\"2%\">&nbsp;</td>\n";
  print INDEX "           </tr><tr><td colspan=\"5\">&nbsp;</td>\n";
  print INDEX "           </tr><tr><td colspan=\"3\">&nbsp;</td>\n";
  print INDEX "             <td width=\"50%\">\n";
  print INDEX "               <font face=\"Arial, Helvetica, sans-serif\">\n";
  print INDEX "                   <a style=\"font-family: Arial; font-size: 12pt;\" target=\"second\" href=\"html/author.htm\">Authors Index</a>\n";
  print INDEX "               </font>\n";
  print INDEX "             </td><td colspan=\"5\">&nbsp;</td></tr>\n";
  print INDEX "             <tr><td width=\"2%\">&nbsp;</td>\n";
  print INDEX "             <td width=\"20%\" align=\"center\"><img alt=\"institute's logo\" src=\"\#\#institute's%20logo\" valign=\"middle\" border=\"0\" width=\"90\" /></td>\n";
  print INDEX "             <td width=\"2%\">&nbsp;</td>\n";
  print INDEX "             <td width=\"50%\">\n";
  print INDEX "               <font face=\"Arial, Helvetica, sans-serif\">\n";
  print INDEX "                   <a style=\"font-family: Arial; font-size: 12pt;\" target=\"second\" href=\"html/keyword.htm\">Keywords</a>\n";
  print INDEX "               </font>\n";
  print INDEX "             </td><td width=\"2%\">&nbsp;</td>\n";
  print INDEX "           </tr><tr>\n";
  print INDEX "             <td colspan=\"3\">&nbsp;</td>\n";
  print INDEX "             <td width=\"50%\">\n";
  print INDEX "               <font face=\"Arial, Helvetica, sans-serif\">\n";
  print INDEX "                   <a style=\"font-family: Arial; font-size: 12pt;\" target=\"second\" href=\"html/inst.htm\">List of Institutes</a>\n";
  print INDEX "               </font>\n";
  print INDEX "             </td><td width=\"2%\">&nbsp;</td>\n";
  print INDEX "           </tr>\n";
  print INDEX "           <tr><td colspan=\"5\">&nbsp;</td></tr>\n";
  print INDEX "           <tr><td colspan=\"3\">&nbsp;</td>\n";
  print INDEX "             <td width=\"50%\">\n";
  print INDEX "               <font face=\"Arial\"><span lang=\"en-us\">\n";
  print INDEX "                   <a style=\"font-family: Arial; font-size: 12pt;\" target=\"second\" href=\"\#\#participants%20list\">List of Participants</a></span>\n";
  print INDEX "               </font>\n";
  print INDEX "             </td>\n";
  print INDEX "             <td width=\"2%\">&nbsp;</td>\n";
  print INDEX "           </tr><tr><td colspan=\"5\">&nbsp;</td>\n";
  print INDEX "           </tr>\n";
  print INDEX "           <tr><td colspan=\"3\">&nbsp;</td>\n";
  print INDEX "             <td width=\"50%\">\n";
  print INDEX "               <font face=\"Arial, Helvetica, sans-serif\">\n";
  print INDEX "                   <a style=\"font-family: Arial; font-size: 12pt;\" target=\"second\" href=\"\#\#pictures\#\#\">Conference&nbsp;Photographs</a>\n";
  print INDEX "               </font>\n";
  print INDEX "             </td><td width=\"2%\">&nbsp;</td>\n";
  print INDEX "           </tr>\n";
  print INDEX "           <tr><td colspan=\"5\">&nbsp;</td></tr>\n";
  print INDEX "           <tr><td colspan=\"3\">&nbsp;</td>\n";
  print INDEX "             <td width=\"50%\">\n";
  print INDEX "               <font face=\"Arial\"><span lang=\"en-us\">\n";
  print INDEX "                   <a style=\"font-family: Arial; font-size: 12pt;\" target=\"second\" href=\"papers/proceed.pdf\">Proceedings&nbsp;Volume</a></span></font><br />\n";
  print INDEX "                   <font style=\"font-family: Arial; font-size: 8pt;\"><span lang=\"en-us\">full proceedings volume with all received papers, preface, photos, and authors'\n";
  print INDEX "                   list (completely hyperlinked)</span>&nbsp;<span style=\"color: rgb(255, 0, 0);\">[??MB]</span><br />\n";
  print INDEX "               </font>\n";
  print INDEX "             </td><td width=\"2%\">&nbsp;</td>\n";
  print INDEX "           </tr>\n";
  print INDEX "           <tr><td colspan=\"5\">&nbsp;</td></tr>\n";
  print INDEX "           <tr><td colspan=\"3\">&nbsp;</td>\n";
  print INDEX "             <td width=\"50%\">\n";
  print INDEX "               <font face=\"Arial\"><span lang=\"en-us\">\n";
  print INDEX "                   <a style=\"font-family: Arial; font-size: 12pt;\" target=\"second\" href=\"papers/proceed1.pdf\">Proceedings&nbsp;Pages&nbsp;1</a></span></font><br />\n";
  print INDEX "                   <font style=\"font-family: Arial; font-size: 8pt;\"><span lang=\"en-us\">only first page of each document with&nbsp; hyperlink to complete\n";
  print INDEX "                        paper&nbsp;</span>&nbsp;<span style=\"color: rgb(255, 0, 0);\">[??MB]</span><br />\n";
  print INDEX "               </font>\n";
  print INDEX "             </td><td width=\"2%\">&nbsp;</td>\n";
  print INDEX "           </tr>\n";
  print INDEX "           <tr><td colspan=\"5\">&nbsp;</td></tr>\n";
  print INDEX "           <tr><td colspan=\"3\">&nbsp;</td>\n";
  print INDEX "             <td width=\"50%\">\n";
  print INDEX "               <font face=\"Arial\"><span lang=\"en-us\">\n";
  print INDEX "                   <a style=\"font-family: Arial; font-size: 12pt;\" target=\"second\" href=\"papers/abstract.pdf\">Abstract Booklet</a></span></font><br />\n";
  print INDEX "                   <font style=\"font-family: Arial; font-size: 8pt;\"><span lang=\"en-us\">complete Abstract Booklet\n";
  print INDEX "                        </span>&nbsp;<span style=\"color: rgb(255, 0, 0);\">[??MB]</span><br />\n";
  print INDEX "               </font>\n";
  print INDEX "             </td><td width=\"2%\">&nbsp;</td>\n";
  print INDEX "           </tr>\n";
  print INDEX "         </tbody>\n";
  print INDEX "        </table>\n";
  print INDEX "      </td>\n";
  print INDEX "    </tr>\n";
  print INDEX "    <tr><td colspan=\"5\"></td></tr><tr><td colspan=\"5\"></tr>\n";
  print INDEX "    <tr><td colspan=\"5\"><hr /></td></tr>\n";
  print INDEX "    <tr><td colspan=\"3\" align=\"center\" width=\"100%\">&nbsp;<span lang=\"en-us\"><font face=\"Arial, Helvetica, sans-serif\" size=\"1\">\n";
  print INDEX "            July 2005&nbsp;&nbsp;&nbsp;&nbsp;Volker RW Schaa, GSI</font></span></td><td></td></tr>\n";
  print INDEX "  </tbody></table>\n";
  print INDEX "  </center></div>\n";
  print INDEX "</body>\n</html>\n";
  close (INDEX);
  Deb_call_strucOut ();
}
#---------------------------
# write a default utility for time measuring in batch files
#
sub generate_tm_uti  {
  Deb_call_strucIn ("generate_tm_uti");

  open (TMUTI, ">", $paper_directory."start_tm.pl") or croak "\n could not create ".$paper_directory."start_tm.pl! (line ",__LINE__,")\n";
  print TMUTI "#!$^X\n";   # sr
  print TMUTI " use Time::HiRes qw(gettimeofday);\n";
  print TMUTI " use strict;\n";
  print TMUTI " no strict \'refs\';\n";
  print TMUTI " use vars qw (\$start_tm \$stop_tm \$sec \$min \$hour \$mday \$mon \$year \$wday \$yday \$isdst);\n";
  print TMUTI "#\n";
  print TMUTI "# start time\n";
  print TMUTI "#\n";
  print TMUTI "\$start_tm = gettimeofday;\n";
  print TMUTI "(\$sec,\$min,\$hour,\$mday,\$mon,\$year,\$wday,\$yday,\$isdst) = localtime(\$start_tm);\n";
  print TMUTI "print sprintf (\"\nStart: %2.2i.%2.2i.%4.4i %2.2i:%2.2i:%2.2i\n\", \$mday, \$mon, \$year+1900, \$hour, \$min, \$sec);\n";
  print TMUTI "open (ST, \">\", \"start.tm\") or die (\"Cannot open \'start.tm\' -- \$!\n\");\n";
  print TMUTI "print ST sprintf (\"Sec: %f\n\", \$start_tm);\n";
  print TMUTI "close (ST);\n";
  print TMUTI "exit;\n";
  close (TMUTI);
  open (TMUTI, ">", $paper_directory."stop_tm.pl") or croak "\n could not create ".$paper_directory."stop_tm.pl! (line ",__LINE__,")\n";
  print TMUTI "#!$^X\n";   # sr
  print TMUTI " use Time::HiRes qw(gettimeofday);\n";
  print TMUTI " use strict;\n";
  print TMUTI " no strict \'refs\';\n";
  print TMUTI " use vars qw (\$start_tm \$stop_tm \$sec \$min \$hour \$mday \$mon \$year \$wday \$yday \$isdst);\n";
  print TMUTI "#\n";
  print TMUTI "# first determine stop time\n";
  print TMUTI "#\n";
  print TMUTI "\$stop_tm = gettimeofday;\n";
  print TMUTI "#\n";
  print TMUTI "# then read start time\n";
  print TMUTI "#\n";
  print TMUTI "open (ST, \"<\", \"start.tm\") or die (\"Cannot open 'start.tm' -- \$!\n\");\n";
  print TMUTI "while (<ST>) {\n";
  print TMUTI "    chomp;                  # no newline\n";
  print TMUTI "    s/Sec: //;              # no comments\n";
  print TMUTI "    \$start_tm = \$_;\n";
  print TMUTI "}\n";
  print TMUTI "close (ST);\n";
  print TMUTI "\n";
  print TMUTI "(\$sec,\$min,\$hour,\$mday,\$mon,\$year,\$wday,\$yday,\$isdst) = localtime(\$start_tm);\n";
  print TMUTI "print sprintf (\"\nStart: %2.2i.%2.2i.%4.4i %2.2i:%2.2i:%2.2i\n\", \$mday, \$mon, \$year+1900, \$hour, \$min, \$sec);\n";
  print TMUTI "(\$sec,\$min,\$hour,\$mday,\$mon,\$year,\$wday,\$yday,\$isdst) = localtime(\$stop_tm);\n";
  print TMUTI "print sprintf (\"Stop:  %2.2i.%2.2i.%4.4i %2.2i:%2.2i:%2.2i\n\", \$mday, \$mon, \$year+1900, \$hour, \$min, \$sec);\n";
  print TMUTI "#\n";
  print TMUTI "# time difference\n";
  print TMUTI "#\n";
  print TMUTI "print sprintf (\"\n\n elapsed time: %.2f [s]\n\", \$stop_tm-\$start_tm);\n";
  print TMUTI "exit;\n";
  close (TMUTI);
  Deb_call_strucOut ();
}
#---------------------------
# read utf-8 names from file
#
sub read_names_UTF8 {
    Deb_call_strucIn ("read_names_UTF8");
	
    my $utfnames = "modnames-utf.txt";
    open (UTFN, "<:encoding(UTF-8)", $content_directory.$utfnames) or die ("Cannot open '$content_directory$utfnames' -- $! (line ",__LINE__,")\n");
#
# read UTF-8 name correction file
#
    my $full_keyname;
    my $checkctr;
    my $j	 = -1;
	my $jlin = -1;
    print DBG "----------------------------------UTF-8---------------------------------\n";
	#
	# $j	number of conversion lines
	# $jlin	number of total lines
	#
    while (<UTFN>) {
        chomp;
		$jlin++;
		if (m|^#|) { next; }
        $j++;
		my $match_count = ($_ =~ s/∞/∞/g);
        if ($match_count ne 8) {
            croak "\n==> version of \"$utfnames\" has an delimiter error in line ",$jlin+1," (match count: $match_count)!\n\n";
        }
       if (m|^#|) {
            croak "\n==> version of \"$utfnames\" does not work \n    with this version of spmsbatch.pl ($sc_version)\n==> Please get newer version of \"$utfnames\"!\n";
        }
        ($jacowid[$j], $lastname_8[$j], $lastname[$j], $firstname_8[$j], $firstname[$j],  $firstini_8[$j], $firstini[$j], $checkctr) = split (/∞/);
		print DBG sprintf (" UTF8-12028 (%3i) %s name:%s\n            %s:%s - %s:%s\n", $j, $jacowid[$j], $lastname[$j],$lastname_8[$j], $lastname[$j],$firstini_8[$j], $firstini[$j]);
        print DBG " $checkctr <=($_)\n";
        if ($checkctr =~ m/!!/) {
            # perfect
#8        } elsif ($checkctr =~ m/\+!/) {
#8			print DBG ">>Special Last ",$j+1,"-- $checkctr\n";
#8			$lastname_new[$j]	= substr ($checkctr, 2);
#8			print DBG "<<< $lastname_new[$j]\n";
#8        } elsif ($checkctr =~ m/\-!/) {
#8			print DBG ">>Special First ",$j+1,"-- $checkctr\n";
#8			$firstname_new[$j]	= substr ($checkctr, 2);
#8			print DBG "<<< $firstname_new[$j]\n";
        } elsif ($checkctr !~ m/\?\?/) {
            print DBG ">>",$j+1,"-- $_\n";
		}
		#
		# use JACoW Id (=Author_Id) as key
		#
		$full_keyname = sprintf ("JACoW-%08d", $jacowid[$j]);
        if (exists($utf8_names{$full_keyname})) {
            croak "\n==> version of \"$utfnames\" generates a duplicate entry for \"$lastname[$j], $firstini[$j]\" entry \"$j\"\n==> Please check!\n\n";
		} else {
			#
			# store JACoW Id entry as key for utf-8 name
			#
			$utf8_names{$full_keyname} = $j;            
		}
        my $print_utf = sprintf (" %3i: {%s} %-20s,-%15s => %-20s,-%15s\n",
                                   $j, $full_keyname,
                                       $lastname_8[$j], $firstname_8[$j],
                                       $lastname[$j],   $firstname[$j]);
        my $utf_str = nice_string ($print_utf);
        print DBG "=nutf= $utf_str";
    }
    $num_utf8_names = $j;
	print DBG " number of utf8 replacements: $num_utf8_names\n";
    close(UTFN);
    print DBG "----------------------------------UTF-8---------------------------------\n";
	Deb_call_strucOut ();
}
#---------------------------
sub nice_string {
    join("",
    map { $_ > 255 ?                  # if wide character...
               sprintf("\\x{%04X}", $_) :  # \x{...}
 #              chr($_) =~ /[[:cntrl:]]/ ?  # else if control character ...
 #              sprintf("\\x%02X", $_) :    # \x..
 #              quotemeta(chr($_))          # else quoted or as themselves
                chr($_)
    } unpack("U*", $_[0]));           # unpack Unicode characters
}
#---------------------------
# read external Abstract from file
#
sub read_external_abs {
    Deb_call_strucIn ("read_external_abs");

    $_ = $_[0];
    if ($_ eq "") {
        print DBG "^??? empty <paper_code> \"$_\"\n";
        return;
    }
    (my $xtn_filename = $abstract_directory.$_.".abs") =~ s|\.\.|\.|;
    if (open (XTA, "<", $xtn_filename)) {
        #
        # read abstract
        #
        print DBG "----------------------------------Abstract---------------------------------\n";
        while (<XTA>) {
            chomp;
            print DBG "$_\n";
            $abstract_text .= " ".$_;
        }
        print DBG "->$abstract_text\n";
        print DBG "----------------------------------Abstract---------------------------------\n";
    } else {
        if ($abstract_omission_text eq "") {
            $abstract_text = "";
        } else {
            ($abstract_text = $abstract_omission_text) =~ s/^\"(.*?)\"$/$1/s;
        }
        print DBG " no external abstract found for \"$xtn_filename\" (line ",__LINE__,")\n";
    }
    close(XTA);
    Deb_call_strucOut ();
}
#--------------------------------
# write internal Abstract to file
#
sub write_internal_abs {

    my $paper_code = $_[0];
    if ($paper_code eq "") {
        print DBG "^??? empty <paper_code> \"$paper_code\"\n";
        return;
    }
	my $abs_text = $_[1];
    if ($abs_text eq "") {
        print DBG "^??? empty <abstract> \"$abs_text\"\n";
        return;
    }
    Deb_call_strucIn ("write_internal_abs");
    (my $xtn_filename = $abstract_directory.$paper_code.".abs") =~ s|\.\.|\.|;
    if (open (XTA, ">:encoding(UTF-8)", $xtn_filename)) {
        #
        # write abstract
        #
        print DBG "----------------------------------Abstract---<$paper_code>----------------\n";
        print XTA $abs_text."\n";
        print DBG "->$abs_text\n";
        print DBG "----------------------------------Abstract---------------------------------\n";
    } else {
        print DBG " cannot open Abstract Output file \"$xtn_filename\" (line ",__LINE__,")\n";
    }
    close(XTA);
    Deb_call_strucOut ();
}
#---------------------------
# get name of day of the week from session date
#
sub get_wday {
    Deb_call_strucIn ("get_wday");

    my $dd = shift || return(0);
    my ($mday, $mmonth, $myear) = split(/-/, $dd);
    $i=0;
    while ($mmonth ne substr($month[$i], 0, 3)) { $i++; }
    my $epochtime = timelocal_nocheck (0, 0, 0, $mday, $i, $myear+2000);
    my $day = (localtime($epochtime))[6];
    $Smonth = $month[$i];
    Deb_call_strucOut ();
#	print " wday--> $mday-$Smonth-$myear ($weekday[$day])\n";
    return $weekday[$day];
}
#---------------------------
# read external session location names
#
sub get_session_locread {
    Deb_call_strucIn ("get_session_locread");
    if (open (LOC, "<", $content_directory."codelocation.txt")) {
        print "\n Code&Location file found!\n";
        $i = -1;
        while (<LOC>) {
            chomp;                  # no newline
            $i++;
            ($sess_abb[$i], $sess_mod[$i], $sess_class[$i], $sess_loc[$i], $sess_color[$i]) = split(/\#/, $_, 5);
            print sprintf ("['%2i':%-6s] %s -- %s -- %s -- %s\n",
                               $i, $sess_abb[$i], $sess_mod[$i], $sess_class[$i], $sess_loc[$i], $sess_color[$i]);
        }
        $session_codes = $i;
        print "# ",$session_codes+1," code & locations\n";
        $session_locrd = 1;
        close (LOC);
    } else {
        print " no Code&Location file found on line $.\n";
    }
    Deb_call_strucOut ();
}
#---------------------------
# fill session location names into vars
#
sub get_session_location {
    Deb_call_strucIn ("get_session_location");

    $session_location[$session_nr] = "";
    $session_type[$session_nr]     = "";
    if (!$session_locrd) {
		Deb_call_strucOut ();
        return;
    }
    #
    # search session
    #
    for ($i=0; $i<=$session_codes; $i++) {
        if ($session_abbr[$session_nr] eq $sess_abb[$i]) {
            $session_location[$session_nr] = $sess_loc[$i];
#            print "> Session: $session_abbr[$session_nr] is '$session_type[$i]' in Location: $sess_loc[$i]\n";
            last;
        }
    }
    Deb_call_strucOut ();
}
#
# subroutine to print a hexdump of a string
#
sub hexdump {
    Deb_call_strucIn ("hexdump");

    my $offset = 0;
    my(@array,$format);
    foreach my $data (unpack("a16"x(length($_[0])/16)."a*",$_[0])) {
        my($len)=length($data);
#        if ($len == 16) {
#            @array = unpack('N4', $data);
#            $format="0x%08x (%05d)   %08x %08x %08x %08x   %s\n";
#        } else {
            @array = unpack('C*', $data);
            $_ = sprintf "%2.2x", $_ for @array;
            push(@array, '  ') while $len++ < 16;
            $format="0x%08x (%05d)" .
               "   %s%s%s%s %s%s%s%s %s%s%s%s %s%s%s%s   %s\n";
#        }
        $data =~ tr/\0-\37\177-\377/./;
        printf $format,$offset,$offset,@array,$data;
        $offset += 16;
    }
    Deb_call_strucOut ();
}
#-------------------------------------------------------------
#
# subroutine to calculate the Offset position
#
sub CopyrightOffset {
    my $start_page_count = $_[0];

    #
    # printing header and footer
    #
    # copyright note needs to be positioned relative to the even page
    #   number (end) with a varying negative distance to compensate for
    #   current writing position
    #
    if ($start_page_count > 999) {
        return $cpx_pos_off = -30;
    }
    if ($start_page_count > 99) {
        return $cpx_pos_off = -26;
    }
    if ($start_page_count > 9) {
        return $cpx_pos_off = -21;
    }
    return $cpx_pos_off = -18;
}
#-------------------------------------------------------------
#
# InspireHeader prints the standard header, some encoding stuff and
#               the conference related fixed data
#  140127: PCDATA section with html entities removed from procedure
#
sub InspireHeader {
    Deb_call_strucIn ("InspireHeader");
	print INSPIRE "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
	print INSPIRE "<!-- Generated by JPSP version $sc_version on $generation_date at $generation_time -->\n";
	print INSPIRE "<!--   JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´ -->\n";

	print INSPIRE "<collection>\n",
                  "  <record>\n";
	(my $hyphenfree_isbn	= $conference_isbn) =~ s|-||g;
	print INSPIRE "    <datafield tag=\"020\" ind1=\" \" ind2=\" \">\n",
                  "       <subfield code=\"a\">$hyphenfree_isbn</subfield>\n",
				  "    </datafield>\n";
	if ($series_issn ne "") {	# '0' Continuing resource of international interest 
		print INSPIRE "    <datafield tag=\"021\" ind1=\"0\" ind2=\" \">\n",
					  "       <subfield code=\"a\">$series_issn</subfield>\n",
					  "    </datafield>\n";
	}
	if ($conference_editor ne "") {
		$conference_editor =~ s|\"||g;		# remove quotation marks around string
		#
		# split editors at ";"
		#
		@editor_list  = split (/;/, $conference_editor);
		#
		# print Editors
		#
		$i = -1;
		$DOI_land{editors} = "";
		while (++$i <= $#editor_list) {
			#
			# tag = 100 for Editor in Chief
			#       700 for Co-Editor
			#
			my $INSPIRE_tag = 700;
			if ($i eq 0) {
				$INSPIRE_tag = 100;
			}
			print INSPIRE "    <datafield tag=\"$INSPIRE_tag\" ind1=\" \" ind2=\" \">\n";
			$editor_list[$i] 	=~ s|\s*(.*?)\s*\((.*?)\)\s*\[(.*?)\]|$1|;		# left is only the lastname, firstname part (with spacing)
			$editor_affil   	= $2;
			print INSPIRE "       <subfield code=\"a\">$editor_list[$i]</subfield>\n";
			#
			# check for affiliation (isolate and remove it)
			#
			if ($editor_affil ne "") {
#rem 21.11.19	(my $editor_aff_main, my $a0, my $b0) = split (/,/, $editor_affil); 
#rem 21.11.19	print INSPIRE "       <subfield code=\"u\">$editor_aff_main</subfield>\n";
				print INSPIRE "       <subfield code=\"v\">$editor_affil</subfield>\n";
			}
			print INSPIRE "       <subfield code=\"e\">ed.</subfield>\n",
						  "    </datafield>\n";
			#
			# only DOI_xml needs the unique Id for the editors, therefore we use the complete editor_list
			#      "$conference_editor" has the names "lastname, firstname(s)" hier we put them "first last"
			#
			$DOI_xml{editor}[$i]	= $editor_list[$i];
			$DOI_xml{editor_af}[$i]	= $editor_affil;
			#
			# formatting the editor id (ORCID or JACoW)
			# 	ORCID in its unchanged format [ORCID:0000-0003-1866-8570]
			#	JACoW formatted from [JACoWId:6482] to [JACoWId-00006482]
			#
			my $editor_id	= $3;
			my ($editor_id_org, $editor_id_nr) = split (/:/, $editor_id);
			if (index ($editor_id_org, "JAC") > 0) {
				$DOI_xml{editor_id}[$i]	= sprintf ("JACoWId-%8i", $editor_id_nr);
			} else {
				$DOI_xml{editor_id}[$i]	= $editor_id;
			}
			#
			# for the landing page we take a different scheme: "firstname lastname (affiliation)"
			#     this is close to the "$conference_editor" string but with first/last swapped and
			#	  and the unique Id in "[]" should be removed
			#
			my ($a, $b) = split(/,/, $editor_list[$i]);
			$DOI_land{editors} .= sprintf ("%s %s (%s); ", trim($b), trim($a), $editor_affil);
		}
		$DOI_land{editors}		=~ s/; $//;
		$DOI_xml{num_editors}	= $#editor_list;
	}
   	print INSPIRE "    <datafield tag=\"245\" ind1=\" \" ind2=\" \">\n",
                  "       <subfield code=\"a\">Proceedings, $conference_title, $conference_name</subfield>\n",
                  "       <subfield code=\"b\">$conference_site_UTF, $conference_date</subfield>\n",
                  "    </datafield>\n";
   	print INSPIRE "    <datafield tag=\"260\" ind1=\" \" ind2=\" \">\n",
                  "       <subfield code=\"a\">JACoW</subfield>\n",
                  "       <subfield code=\"b\">Geneva, Switzerland</subfield>\n",
                  "       <subfield code=\"c\">$conference_pub_date</subfield>\n",
				  "    </datafield>\n";
   	print INSPIRE "    <datafield tag=\"540\" ind1=\"\" ind2=\"\">\n",
# rem 21.11.19    "       <subfield code=\"a\">Open Access</subfield>\n",			# changed 21.11.19
                  "       <subfield code=\"a\">CC-BY-3.0</subfield>\n",
                  "       <subfield code=\"u\">https://creativecommons.org/licenses/by/3.0/</subfield>\n",
				  "    </datafield>\n";
   	print INSPIRE "    <datafield tag=\"856\" ind1=\"4\" ind2=\" \">\n",
                  "       <subfield code=\"u\">$conference_url</subfield>\n",
 				  "       <subfield code=\"y\">JACoW</subfield>\n",
				  "    </datafield>\n",
                  "  </record>\n";
    Deb_call_strucOut ();
	return;
}
#-------------------------------------------------
# trim function
#-----------------------
sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

#------------------------------------------------------------
# &#64259;  ffi ligature
#
#\pdfcompresslevel=9
#\pdfobjcompresslevel=2
#
#todo
#      &amp;#1040; => russian A
#-------------------------------------------------------------
# Debug service routine for showing the call depth graphically
#
sub Deb_call_strucIn {
    my $callfrom = $_[0];
	$deb_sub_cnt++;
	$deb_cnt++;
	if ($deb_calltree) {
		print CDEB sprintf ("%6i: %*s+-%2.2i %-s\n", $deb_cnt, 3*$deb_sub_cnt, " ", $deb_sub_cnt, $callfrom);
		print  DBG sprintf ("%6i: %*s+-%2.2i %-s\n", $deb_cnt, 3*$deb_sub_cnt, " ", $deb_sub_cnt, $callfrom) unless $debug_restricted;
	}
	return;
}
sub Deb_call_strucOut {
	$deb_sub_cnt--;
	return;
}
#-------------------------------------------------------------
# Batch_RenameMove
#   before opening
#     - new output files for direct file load with wget
#     - save/rename the old ones for later checks (*wget.bat => $protocol_directory./*wget-<aaaa-mm-dd-hhmmss.bat) 
#
sub Batch_RenameMove {

 use vars qw (@dloads $dloads);
 use vars qw ($mtime $tm $fm $ft);
# use Time::gmtime;
 use File::Basename;
 use File::stat;

#
# array of download batch files
#
 @dloads  = qw(paperwget posterwget talkswget pdfwget);

	my $cp_downl;
	foreach my $elem (@dloads) {
		my $downld = $elem.".bat";
		print " file to save: $downld\n";
#		my $date_string = ctime(stat($downl)->mtime);
#		print " File ->$downl<- DT:$date_string\n";

#    my $write_secs = (stat($downl))[9];
#    printf "file %s updated at %s\n", $downl, scalar localtime($write_secs);


#		my $mytime      = (stat($downld))[9];
#		$tm             = localtime($mytime);
#		print " File ->$downl<- already exists! -- $mytime -- $tm\n";

		if (-e $downld) {
			my $mtime    = (stat($downld))[9];
			$tm       = localtime($mtime);
			print " File ->$downld<- already exists! -- $mtime -- $tm\n";
			my($filename, $directories, $suffix) = fileparse($downld);
			($fm, $ft) = split (/\./, $filename);

			my $mvfile  = sprintf ("%-s%-s-%04d%02d%02d-%02d%02d%02d.%-s",
									$protocol_directory,
									$fm, ($tm->year)+1900, ($tm->mon)+1, $tm->mday,
									$tm->hour, $tm->min, $tm->sec,
									$ft);

			if (-e $mvfile) {
				print " Save file ->$mvfile<- already exist!\n";
			} else {
				print " File ->$downld<- will be saved and moved as ->$mvfile<-\n";

				my $command =  sprintf ("move %-s %-s", $downld, $mvfile);
				   $command =~ s|\/|\\|g;
				system ($command);
			}
		} else {
			print " File ->$downld<- is new!\n";
		}
	}
	return;
}
#-------------------------------------------------------------
#
#  convert all HTML entities to UTF-8 with the exception of
#  (&, <, >) which have to be escaped to survive the transformation
#
sub UTF_convert_spec_chars {

    $_    = $_[0];
 my $wohe = $_[1];
    if (!defined $_ || $_ eq "") {
        print DBG " --> ($wohe) ^empty string ($paper_code[$pap])\n";
        return;
    }
    Deb_call_strucIn ("UTF_convert_spec_chars");

	convert_spec_chars ($_, "UTF_conv_spec <- $wohe ($_)");
	#
	# convert chars or string inside <sup>...</sup> or <sub>...</sub> to UTF-8 
	#
	$_ = UTF_supb ($_);

	print  DBE sprintf (" =================\n -------- pre_dec in:%s> \n%s\n", $paper_code[$pap], $_) unless $debug_restricted; 
#
# clean-up of html in INSPIRE/DOI xml
#
	s|<strong>||ig;
	s|<\/strong>||ig;
	s|&amp;amp;|&amp;|g;
	s|&amp;#|&#|g;			# leftovers in first names, cities and institutes
	#
	# convert html entities to UTF-8 and re-substitute the escaped entities
	#
	decode_entities ($_);
	print  DBE sprintf (" -------- post_dec\n%s\n", $_) unless $debug_restricted; 
	#
	# all \^{} escaped due to warning message "Unescaped left brace in regex is deprecated, passed through in regex"
	#
	s|\^\{+\}|\x{207a}|g;
	s|\^\{-\}|\x{207b}|g;
	s|\^\{-1\}|\x{207b}\x{00B9}|g;
	s|\^\{*\}|*|g;
	
    Deb_call_strucOut ();
	return $_;
}
#-------------------------------------------------------------
#
# convert chars or string inside <sup>...</sup> or <sub>...</sub> to UTF-8 
#
sub UTF_supb {

 use vars qw (@superscript $superscript @subscript $subscript %superscript_i %subscript_i);
 use vars qw ($utf8sscr $tmp_str $tmp_len $tmp_pos $tmp_chr);

%superscript_i	= ( "0" => "\x{2070}", "1" => "\x{00B9}", "2" => "\x{00B2}", "3" => "\x{00B3}", "4" => "\x{2074}", "5" => "\x{2075}", 
                    "6" => "\x{2076}", "7" => "\x{2077}", "8" => "\x{2078}", "9" => "\x{2079}", "+" => "\x{207a}", "-" => "\x{207b}" );
%subscript_i	= ( "0" => "\x{2080}", "1" => "\x{2081}", "2" => "\x{2082}", "3" => "\x{2083}", "4" => "\x{2084}", "5" => "\x{2085}", 
                    "6" => "\x{2086}", "7" => "\x{2087}", "8" => "\x{2088}", "9" => "\x{2089}", "+" => "\x{208a}", "-" => "\x{208b}" );

    $_ = $_[0];
    if (!defined $_ || $_ eq "") {
        print DBG " --> (UTF_sub) ^empty string ($paper_code[$pap])\n";
        return;
    }
    Deb_call_strucIn ("UTF_supb");
	#
	# substitute all Superscripts <sup>...</sup>
	#
	s|&#8722;|-|g;		# Mathematical Minus Sign
	while (m|<sup>([-+0-9]+)<\/sup>|) {
		print  DBG sprintf (" UTF_sup in:%s> \n", $1) unless $debug_restricted; 
		$utf8sscr	= "";
		$tmp_str	=  $1;            # argument with numbers/+/- inside <sup> only
		$tmp_len	= length $1;      # length of found string to be replaced
		for $tmp_pos (0 .. $tmp_len-1) {
			$tmp_chr = substr ($tmp_str, $tmp_pos, 1);
			$utf8sscr .= $superscript_i{$tmp_chr};
		}
		s|<sup>([-+0-9]+)<\/sup>|$utf8sscr|;
		print  DBG sprintf (" -->sup out:%s\n", $utf8sscr) unless $debug_restricted; 
	}
	#
	# substitute all Subscripts <sub>...</sub>
	#
	while (m|<sub>([-+0-9]+)<\/sub>|) {
		$tmp_str	=  $1;            # argument with numbers/+/- inside <sub> only
		print  DBG sprintf (" UTF_sub in:%s\n", $1) unless $debug_restricted; 
		$utf8sscr	= "";
		$tmp_len	= length $1;      # length of found string to be replaced
		for $tmp_pos (0 .. $tmp_len-1) {
			$tmp_chr = substr ($tmp_str, $tmp_pos, 1);
			$utf8sscr .= $subscript_i{$tmp_chr};
		}
		s|<sub>([-+0-9]+)<\/sub>|$utf8sscr|;
		print  DBG sprintf (" -->sub out:%s\n", $utf8sscr) unless $debug_restricted; 
	}
	#
	# substitute all other (remaining) Super- & Subscripts to LaTeX notation _/^{...} without "$"
	#
	s|<sup>*<\/sup>|*|;
	while (m|<sup>(.*?)<\/sup>|) {
		s|<sup>(.*?)<\/sup>|\^\{$1\}|;
	}
	while (m|<sub>(.*?)<\/sub>|) {
		s|<sub>(.*?)<\/sub>|_\{$1\}|;
	}
	#
	# substitute ^{-}/{+} and _{-}/{+}
	#
	s|\^\{-\}|\x{207b}|g;			#	Superscript Minus
	s|\^\{\x{2212}\}|\x{207b}|g;	#	Superscript math Minus (U+2212)
	s|\^\{+\}|\x{207a}|g;			#	Superscript Plus
	#
	# remove italics
	#
	s|<em>||g;
	s|<\/em>||g;
	
    Deb_call_strucOut ();
	return $_;
}
#-------------------------------------------------------------
#
# ExportCitations  generates a number of standard citation/reference files
#                  - BibTeX (@InProceedings)
#                  - LaTeX (\bibitem)
#                  - Text/Word (unformatted text)
#				   - RIS
#				   - Endnote-XML
#				   - JSON
#
sub ExportCitations {
    Deb_call_strucIn ("ExportCitations");
	
	my $pap_nr = shift;
#
# Text
# ---------
#   (fields with "+" are missing when no paper had been published)
#
#	[key] : [<main_author>:<conference_name>-<paper_code>]
#		<main_author>, <co_author>, <co_author>, (up to 6) last one with ", and"
#		% <main_author> \emph{et al.},  (in addition when more than 6)
#		"<title>",
#	+	<paper_code>, in \emph{Proc. <conference_title> (<conference_id)},
#	+	pp. <page_start>-<page_end>,
#	+	ISBN <conference_isbn>
#	+	https://accelconf.web.cern.ch/AccelConf/IPAC2014/papers/<paper_code>.pdf,
#		<conference_site>, {year} of <conference_pub_date>
# ---------
#
#-     [Wei:IPAC2014-MOYBA01]
#-          J. Wei,
#-          "The Very High Intensity Future",
#-          MOYBA01, in Proc. IPAC2014,
#-          MOYBA01, in Proc. 5th International Particle Accelerator Conference (IPAC2014),
#-          pp. 635--639,
#-          ISBN: 978-3-95450-133-5,
#-          https://accelconf.web.cern.ch/AccelConf/IPAC2014/papers/moyba01.pdf,
#-          Dresden, Germany (2014).
#-----------
	#
	# prepare variables for output
	#
	my $citpapcod	= $prg_code[$pap_nr][$prg_code_p[$pap_nr]];  # always the primary paper code!
	my $citpapfil	= $paper_code[$pap_nr];
	my $citdoi		= $DOI_land{$pap_nr}{doi};
	#
	# hack for secondary papercodes which have their primary data used for citations
	#
	if (!defined $DOI_land{$pap_nr}{doi}) {
		$citdoi		= $DOI_prefix."/JACoW-".$conference_name."-".$citpapcod;	
	}
#
# authors appear only once and without affiliation
#
	my @bibauth		= ();
	$j = -1;
	my $auth_last	= "";	# author[$i-1]
	my $act_auth;			# actual author ([$])
	for ($i = 0; $i <= $authors[$pap_nr]; $i++) {
		my $auth_fli  = "$contrib_lst[$pap_nr][$i];$contrib_ini[$pap_nr][$i]";
		my $auth_fl8  = "$contrib_ln8[$pap_nr][$i];$contrib_in8[$pap_nr][$i]";
		#
		# use UTF8 name if different from ISO8859 name
		#
#~*		if ($auth_fli eq $auth_fl8) {
#~*			$act_auth		= $auth_fli;
#~*		} else {
			$act_auth		= $auth_fl8;
#~*		}
		#
		# remove duplicates and assign authors to new list
		#
		if ($act_auth eq $auth_last) {
			next;
		}
#~*		$bibauth[++$j]	= $act_auth;
		$bibauth[++$j]	= convert_spec_chars ($act_auth, "BiBTeX/LaTeX");
		$auth_last		= $act_auth;
	}
#
# remove duplicate authors (here due to different affiliations 
# not consecutives and therefore not eliminated in the last loop)
#
	my $mainauth	= $bibauth[0];
	@bibauth		= sort @bibauth;
	s/&#8217;/'/ for @bibauth;
	my @bibauthS	= ();
	$bibauthS[0]	= $mainauth;
	my $bibix		= 0;
	for ($i =0; $i <= $j; $i++ ) {
		if ($mainauth eq $bibauth[$i]) {
			#
			# skip main author (will be reentered as first in the save list)
			#
			next;
		} else {
			#
			# copy to bibauthor save list
			#
			$bibix++;
			$bibauthS[$bibix] = $bibauth[$i]
		}
	}
#
# now $bibauthS has the correct authors (no duplicates, correct sequence)
#
	$j	= $bibix;
	$bibix	= 0;
	my $authloopend = $j;
	my $cnt_authors = $j;  #will be used for RIS and EndNotes format

#
# sorted list (with "First Initials";"Lastname" in @bibauth)
#
	my $auth_str	= "";	# all authors
	my $auth_str_6	= "";	# max authors >6 (show first + "et al.")
	my $auth_str_s	= "";	# short version, max 6 authors
	my $bibtex_au_s	= "";	# short author string for BiBTeX (one + et al.)
	my $bibtex_au_6	= "";	# author string for BiBTeX (six (+ et al.)
	my $bibtex_auth	= "";	# author string for BiBTeX (full)
	my $stopcol_1   = 0;	# stop collecting: authors due to "et al."
	my $stopcol_2   = 0;	# stop collecting: max 6 authors reached
	print CITDB "-- Authors -----------------\n";
	for ($i =0; $i <= $j; $i++ ) {
		my ($ln, $fn)	= split (";", $bibauthS[$i]);
		$bibauth[$i]	= "$fn∞$ln";
		$bibtex_auth	.= "$fn $ln and ";
		$bibtex_au_s	.= "$fn $ln and " unless $stopcol_2;
		$bibtex_au_6	.= "$fn $ln and " unless $stopcol_1;
		$auth_str		.= "$fn $ln, ";
		$auth_str_s		.= "$fn $ln, " unless $stopcol_2;
		$auth_str_6		.= "$fn $ln, " unless $stopcol_1;
		print CITDB " i:j[$i;$j] bibtex_auth<$bibtex_auth>  auth_str[$auth_str] auth_str_s<$auth_str_s> auth_str_6[$auth_str_6]\n" ;
		if ($i == 0 && $j > 5) {
			#
			# Number of Authors is >6
			# -----------------------
			# BibTeX:    add ' other' to string and exit
			# LaTeX >6:  remove last ", " and add "et al." and exit
			#
			$bibtex_au_6	.= "others";
			if ($i == 0) {
				$auth_str_6		=~ s|, $||;
			}
			$auth_str_6		.= " \\emph{et al.}";
			$stopcol_1		= 1;
		}
		if ($i > 0 && $i eq $j-1) {
			#
			# we are close to the penultimate author, add " and "
			#
			$auth_str		.= "and ";
			$auth_str_s		.= "and " unless $stopcol_2;
			$auth_str_6		.= "and " unless $stopcol_1;
			$bibtex_au_s	.= "and " unless $stopcol_2;
			$bibtex_au_6	.= "and " unless $stopcol_1;
		}
		if ($i == 5) {
			#
			# we have accumulated 6 Authors
			# ------------------------------
			# LaTeX:   stop here and add "et al." then exit
			#
			if ($j ne 5) {
				$auth_str_s		.= "\\emph{et al.}";
			$	bibtex_au_s		.= "others";
			}
			$stopcol_2		= 1;
		}
		print CITDB " i:[$i] <$bibauth[$i]>  [$bibtex_auth]\n" ;
	}
	#
	# hot fix for two authors (which are not covered in the above code)
	#
	if ($j == 1) {
#		print "$i#$j: $auth_str_s\n";
		$auth_str_s		=~	s|, | and |;
		$auth_str		= $auth_str_s;
		$auth_str_6		= $auth_str_s;
	}
	#
	# remove last ' and ' for BibTeX author string
	#
	$bibtex_auth	=~ s| and $||;
	$bibtex_au_s	=~ s| and $||;
	$bibtex_au_6	=~ s| and $||;
	$bibtex_au_s	=~ s| and and| and|;
	$bibtex_au_6	=~ s| and and| and|;
	$auth_str		=~ s|, $||;
	$auth_str_s		=~ s|, $||;
	$auth_str_6		=~ s|, $||;
	
	print CITDB " i:j[$i;$j] bibtex_auth<$bibtex_auth>  auth_str[$auth_str] auth_str_s<$auth_str_s> auth_str_6[$auth_str_6]\n" ;
	print CITDB "--------------------------------\n";
#
# assign other citation variables 
#
	my $citkey		= "$contrib_ln8[$pap_nr][0]:$conference_name-$citpapcod";
	   $citkey		=~ s| ||g;
	   $citkey		=~ s|'||g;
	   $citkey		= helpsort_acc_chars ($citkey, "citation keys");
# Title
	my $citpaptitl	= convert_spec_chars ($title[$pap_nr], "title_citexp");
    my $citpaptitl8	= convert_spec_chars_TXT ($title[$pap_nr], "title_citexp_TXTs");
# 
	my $citurl		= $conference_url."papers/".lc($citpapcod).".pdf";
    my $citstapg	= $page_start[$pap_nr];
	my $publshd		= $citstapg > 0;
	my $citendpg	= $page_start[$pap_nr] + $paper_pages[$pap_nr] - 1;
	my $UCpapcod	= uc $citpapcod;
# Abstract
	my $citpapabs8		= UTF_convert_spec_chars ($paper_abs[$pap_nr], "citpapabs8");
	my $citpapabs8xml	= encode_entities ($citpapabs8, '<>&"');

#	if ($citpapabs8 eq )

#----------------------------------------------------------
# text/Word export
#------------------------------------
	my $citexpfile	= $export_directory.$citpapfil."-txt.htm";
	my $au_str;
	open (CITEXP, ">:encoding(UTF-8)", $citexpfile) or die ("Cannot open '".$citexpfile."' -- $! (line ",__LINE__,")\n");

	include_HighwirePress_DC_Tags (*CITEXP, $pap_nr, "Text/Word");

	$au_str = $auth_str_s;
#	$au_str =~ s|~| |g;
	if ($auth_str_s ne $au_str) {
		$au_str = $auth_str_s;
	}
	if ($auth_str_s ne $auth_str_6) {
		$au_str = $auth_str_6;
	}
	$au_str =~ s|\\emph\{et al.\}|<i>et al.</i>|;

	print CITEXP "<p class=\"JACoW_Reference # 10 onwards\">\n",
				 "   <span style=\"font-family:Times-New-Roman; font-size:9pt;\">$au_str,\n",
				 "    \x{201c}$citpaptitl8\x{201d},\n";
	(my $conference_title_shrt_no_thinspace = $conference_title_shrt) =~ s|\,| |g;
	if ($publshd) {
#nov18	print CITEXP "   in <i>Proc. $conference_title_shrt_no_thinspace ($conference_sh_name)</i>,",
		print CITEXP " in <i>Proc. $conference_sh_name</i>,",
					 " $conference_site_UTF, $conf_month_abbr, pp. $citstapg-$citendpg.</span>",
#nov18					 " <span class=\"urlm\">doi:$citdoi</span>";
						 " <span style=\"font-family:'Liberation Mono'; font-size:8pt;\">doi:$citdoi</span>";
#					 "   doi:$citdoi";
	} else {
		print CITEXP " presented at the $conference_title_shrt_no_thinspace ($conference_sh_name),",
					 " $conference_site_UTF, $conf_month_abbr, paper $UCpapcod, unpublished.</span>";
	}

	print CITEXP "</p>\n",
				 "</body>\n",
				 "</html>\n";
	close (CITEXP);				  

#----------------------------------------------------------
# LaTeX \bibitem
#------------------------------------
#   (fields with "+" are missing when no paper had been published)
#
#	[cite] : [<main_author>:<conference_name>-<paper_code>]
#	[key] : [<main_author>:<conference_name>-<paper_code>]
#		<main_author>, <co_author>, <co_author>, (up to 6)
#		% <main_author> \emph{et al.},  (in addition when more than 6)
#		"<title>",
#	+	<paper_code>, in \emph{Proc. <conference_name>},
#	+	pp. <page_start>-<page_end>,
#	+	ISBN <conference_isbn>
#	+	https://accelconf.web.cern.ch/AccelConf/IPAC2014/papers/<paper_code>.pdf,
#		<conference_site>, {year} of <conference_pub_date>.
# ---------
#
#-     %\cite{Wei:IPAC2014-MOYBA01}
#-     \bibitem{Wei:IPAC2014-MOYBA01}
#-          J.~Wei,
#-          "The Very High Intensity Future",
#-          MOYBA01, in \emph{Proc. IPAC2014},
#-          pp. 635--639,
#-          ISBN: 978-3-95450-133-5,
#-          \url{https://accelconf.web.cern.ch/AccelConf/IPAC2014/papers/moyba01.pdf},
#-          Dresden, Germany, 2014.
#+
#+     %\cite{Wei:IPAC2014-MOYBA01}
#+     \bibitem{Wei:IPAC2014-MOYBA01}
#+          J.~Wei,
#+          "The Very High Intensity Future",
#+          in \emph{Proc. IPAC2014}, Dresden, Germany, Jun 2014[.|, pp. 635--639].
#+          \url{doi:10.18429/JACoW-IPAC2014-MOYBA01}
#+
#
	#
	# open file as "<papercode>-tex.htm" on "$export_directory"
	#
	$citexpfile = $export_directory.$citpapfil."-tex.htm";
    $citpaptitl = revert_from_context (convert_spec_chars2TeX($citpaptitl, "title_citexp_TeX"));
	open (CITEXP, ">:encoding(UTF-8)", $citexpfile) or die ("Cannot open '".$citexpfile."' -- $! (line ",__LINE__,")\n");
	#
	include_HighwirePress_DC_Tags (*CITEXP, $pap_nr, "LaTeX");
	print CITEXP "%\\cite{$citkey}\n",
	             "\\bibitem{$citkey}\n";
	print CITEXP "   $auth_str_s,\n";
	if ($auth_str_s ne $auth_str) {
		print CITEXP "%   $auth_str,\n";
	}
	if ($auth_str_s ne $auth_str_6) {
		print CITEXP "%   $auth_str_6,\n";
	}
#	for (my $a_n = 0; $a_n <= $cnt_authors; $a_n++) {
#		print CITEXP ("% $DOI_xml{$pap_nr}{author}[$a_n]\" />\n");
#	}

######################
	print CITEXP "   \\textquotedblleft{$citpaptitl}\\textquotedblright,\n";
	if ($publshd) {
		print CITEXP "% --- abbreviated form (published paper) - JACoW template Feb 2018 ---\n",
		             "   in \\emph{Proc. $conference_sh_name}, $conference_site_lat, $conf_month_abbr, pp. $citstapg--$citendpg.\n",
					 "   \\url{doi:$citdoi}\n";
#'		print CITEXP "% --- complete form (published paper) - JACoW template Feb 2018 ---\n",
#'					 "%  in \\emph{Proc. ".ordinal($conference_number)." $conference_series ($conference_sh_name)}, $conference_site_lat, $conf_month_abbr,\n",
#'					 "%  pp. $citstapg--$citendpg. \\url{doi:$citdoi}\n";
		print CITEXP "% --- additional material -ISSN/ISBN--\n";
		if ($series_issn eq "") { #' removed \url{$citurl} (link to paper PDF) from both cases
			print CITEXP "%  ISBN: $conference_isbn\n";		
		} else {
			print CITEXP "%  ISBN: $conference_isbn, ISSN: $series_issn\n";
		}
	} else {
		print CITEXP "% --- abbreviated form (UNpublished paper) - JACoW template Feb 2018 ---\n",
					 "  presented at $conference_sh_name, $conference_site_lat, $conf_month_abbr, paper $UCpapcod, unpublished.\n";
#'		print CITEXP "% --- complete form (UNpublished paper) - JACoW template Feb 2018 ---\n",
#'					 "%  presented at the ".ordinal($conference_number)." $conference_series ($conference_sh_name), $conference_site_lat, $conf_month_abbr, paper $UCpapcod, unpublished.\n";
	}
	print CITEXP "</pre>\n",
				 "</body>\n",
				 "</html>\n";
	close (CITEXP);
#----------------------------------------------------------
# BibTeX for IEEEtran.bst see http://mirror.unl.edu/ctan/macros/latex/contrib/IEEEtran/bibtex/IEEEtran_bst_HOWTO.pdf (2015)
#---------------------------------------
#   r = required
#   e = extension (may not be supported)
#   o = optional
# 	- = does not exist
#
#  tags for "@conference" (first column) and 
#           "@InProceedings" (second column)
#           "@unpublished"
# -----------------
#   -  	r	author
#	r	r	title 
#	e	e/	language  ala babel => english/USenglish/UKenglish
#	-	e	intype
#	-	r	booktitle
#	-	e	language
#	o	o	series
#	o	o	editor
#	o	o	volume
#	o	o	number
#	o	o	organization
#	o	o	address
#	o	o	publisher
#	o	o	month
#	r	r	year 
#	-	e	paper
#	-	e	type 
#	-	o	pages
#	o	o	note
#           doi
#	e	e	url
#  crossref see http://tex.stackexchange.com/questions/123252/how-to-manage-conference-proceedings-in-bibtex
#---------------------------------------
#    fields with "+" are missing when no paper had been published
#    fields with "!" are required, "~" optional, and "x" not used anymore
#
#-     @InProceedings{<main_author>:<conference_name>-<paper_code>,
#-  !     author       = {<main_author>, <co_author>, <co_author>, ...},
#-  !     title        = {<title>},
#-  !     booktitle    = {Proc. of <conference_series> (<conference_name>)\n",
#-					      <onference_site>, <conference_date>} 
#-  ~  +  pages        = {<page>+},
#-        paper        = {<paper_id>},
#-  ~     language     = {english},
#-        keywords     = {<keywords>},
#-  ~     editor       = {<conference_editor>},
#-  ~     venue        = {<conference_site>},
#-  ~     series       = {<conference_title>},
#-  ~  +  number       = {<conference_number>},
#-  ~     publisher    = {JACoW Publishing, Geneva, Switzerland},
#-  x     address      = {Geneva, Switzerland},     <= should be location => added to publisher
#-  x     location     = {Geneva, Switzerland},     => added to publisher
#-  ~  +  month        = [month] of <conference_pub_date>,
#-  !  +  year         = [year] of <conference_pub_date>,
#-  ~!    date         = [year-month-day] of <conference_pub_date>,  <BibLaTeX>
#-  ~  +  isbn         = {<conference_isbn>},
#-  ~  +  doi          = {10.18429/JACoW-<conference_name>-<paper_code>},
#-  ~  +  url          = {https://accelconf.web.cern.ch/AccelConf/<conference_name>/papers/<paper_code>.pdf}
#-  ~     note         = {https-doi}",
#-        abstract     = {Abstract of paper},
#-     }
#   other optional fields: subtitle, titleaddon, maintitle, mainsubtitle, maintitleaddon, booksubtitle, booktitleaddon,
#                          eventtitle, eventtitleaddon, eventdate, volume, part, volumes, organization, location, eid, chapter, 
#						   addendum, pubstate, eprint, eprintclass, eprinttype, urldate
	#
	# open file as "<papercode>-bib" on "$export_directory"
	#
	$citexpfile = $export_directory.$citpapfil."-bib.htm";
	open (CITEXP, ">:encoding(UTF-8)", $citexpfile) or die ("Cannot open '".$citexpfile."' -- $! (line ",__LINE__,")\n");
	include_HighwirePress_DC_Tags (*CITEXP, $pap_nr, "BiBTeX");
	#
	# put {} around uppercase letters
#####  function removed, instead placed curly braces around full string
	#
####	(my $bibtitle = $citpaptitl) =~ s|([A-Z-\@]+)|\{$1\}|g;
	#
	#
	# paper published ?
	#
	if ($publshd) {
		print CITEXP "\@InProceedings{$citkey,\n";
		print CITEXP "  author       = \{$bibtex_auth\},\n";
		if ($bibtex_au_s ne $bibtex_auth) {
			print CITEXP "% author       = \{$bibtex_au_s\},\n";
		}
		if ($bibtex_au_6 ne $bibtex_auth) {
			print CITEXP "% author       = \{$bibtex_au_6\},\n";
		}
####		print CITEXP "  title        = \{\{$bibtitle\}\},\n",
		print CITEXP "  title        = \{\{$citpaptitl\}\},\n",
					 "  booktitle    = \{Proc. $conference_sh_name\},\n";                  
		print CITEXP "  pages        = \{$citstapg--$citendpg\},\n",
					 "  paper        = \{$UCpapcod\},\n",
					 "  language     = \{english\},\n",
					 "  keywords     = \{$keywjoin{$citpapcod}\},\n";
		print CITEXP #####	"  editor       = \{$DOI_land{editors}\},\n",    # doesn't work with IEEEtran BibTeX style
					 "  venue        = \{$conference_site_UTF\},\n",
					 "  series       = \{$conference_series\},\n",
					 "  number       = \{$conference_number\},\n";
		print CITEXP "  publisher    = \{JACoW Publishing, Geneva, Switzerland\},\n";
#0920	print CITEXP "  month        = \{$pub_month_abbr\},\n";	$pubmonth_nr
		print CITEXP "  month        = \{$pubmonth_nr\},\n";	
		print CITEXP "  year         = \{$pubyear_nr\},\n";
		if ($series_issn ne "") {
			print CITEXP "  issn         = \{$series_issn\},\n";
		}
		print CITEXP "  isbn         = \{$conference_isbn\},\n",
					 "  doi          = \{$citdoi\},\n",
					 "  url          = \{$citurl\},\n";
		print CITEXP "  note         = \{https://doi.org/$citdoi\},\n";					# DOI placed in 'note' as it is not picked up otherwise by IEEEtran in BibTeX, but BibLaTeX does
	} else {
		print CITEXP "\@unpublished{$citkey,\n";
		print CITEXP "  author       = \{$bibtex_auth\},\n";
		if ($bibtex_au_s ne $bibtex_auth) {
			print CITEXP "% author       = \{$bibtex_au_s\},\n";
		}
		if ($bibtex_au_6 ne $bibtex_auth) {
			print CITEXP "% author       = \{$bibtex_au_6\},\n";
		}
####		print CITEXP "  title        = \{$bibtitle\},\n",
		print CITEXP "  title        = \{\{$citpaptitl\}\},\n",
					 "  booktitle    = \{\{Proc. $conference_sh_name\},\n",
					 "  language     = \{english\},\n";
		print CITEXP ######		"  editor       = \{$DOI_land{editors}\},\n", extra\n   # doesn't work with IEEEtran BibTeX style
					 "  intype       = \{\{presented at the\},\n",
					 "  series       = \{\{$conference_series\},\n",
					 "  number       = \{$conference_number\},\n",
					 "  venue        = \{$conference_site_UTF\},\n";
		print CITEXP "  publisher    = \{JACoW Publishing, Geneva, Switzerland\},\n";
		print CITEXP "  month        = \{$pub_month_abbr\},\n",
					 "  year         = \{$pubyear_nr\},\n";
#		my $ord_conf_nr	= ordinal ($conference_number);
		print CITEXP "  note         = \{presented at $conference_name in $conference_site_UTF, unpublished\},\n";
	}
	print CITEXP "  abstract     = \{\{$citpapabs8\}\},\n",	
			     "}\n",
	             "</pre>\n",
				 "</body>\n",
				 "</html>\n";
	close (CITEXP);

#--------------------------------------------------------------------------------------
# updated: reference used in v28.3: http://refdb.sourceforge.net/manual-0.9.6/sect1-ris-format.html
#                                   Chapter 7 for more than one reference in a RIS dataset
#
#  RIS (file format)
#       RIS is a standardized tag format developed by Research Information Systems, 
#		Incorporated (the format name refers to the company) to enable citation programs 
#		to exchange data.[1] It is supported by a number of reference managers. 
#		Many digital libraries, like IEEE Xplore, Scopus, the ACM Portal, Scopemed, 
#		ScienceDirect, and SpringerLink, can export citations in this format.
#--------------
#  tags with
#		"o"  are supplied
#       "-"  not needed
#       "r"  are required
#       "+"  are missing when no paper had been published
#       "??" found in http://www.citavi.com/sub/manual4/en/importing_a_ris_file.html)
#   	"~~" some identfiers found in http://refdb.sourceforge.net/manual-0.9.4/c2166.html
#--------------
#.	r	TY  - Type of reference (must be the first tag)
#				CONF  - Conference proceeding
#			->  CpapER - Conference paper
#				UNPB  - unpublished
# 		CPAPER	Conference Paper
#		CONF	Conference Proceeding
#		UNPD	Unpublished Work
#
#
#
#.	o	AU  - Authors, Editors, Translators (each author on its own line preceded by the tag) 
#Z		A1	- Author Primary
#.	-	A2  - Secondary Author (each author on its own line preceded by the tag)
#Z !o   A2  - Editor(s) 
#.	-	A3  - Tertiary Author (each author on its own line preceded by the tag) / Collaborators
#.  x?  A3  - Series Editor
#.	-	A4  - Subsidiary Author (each author on its own line preceded by the tag)
#.	o	AB  - Abstract
#.	-	AD  - Author Address
#.	-	AN  - Accession Number
#   ??	BT	- ParentReference (citavi)  => for BOOK and UNPB the same as TI
#.	-	C1-C8 Custom 1...8
#   x?  C1    Place Published -> CY
#   x?  C2    Year Published
#   x?  C3    Proceedings Title
#   x?  C5    Packaging Method
#.	-	CA  - Caption
#.	-	CN  - Call Number
#	??	CP	- Place Published
#.Z o	CY  - Conference Location
#.	o	DA  - Date (YYYY[/MM[/DD[/other info]]])
#.	-	DB  - Name of Database
#.	o	DO  - DOI
#.	-	DP  - Database Provider
#Z  o+  ED  - Editor (synonym A2)
#.Z o+	EP  - End Page (Pages: Zotero)
#.	r	ER  - End of Reference (must be the last tag)
#.	-	ET  - Edition
#	??	H1	- Place of Publication
#	??	H2	- Library Location
#		ID	- ??
#.	-	IS  - Number / ~~the issue of the journal/periodical
#	??	JA	- Journal (citavi)
#	~~	JF	- The full name of a journal or periodical.
#	~~	JO	- The abbreviated name of a journal or periodical.
#	~~	J1	- The abbreviated name of a journal or periodical (user abbreviation 1).
#	~~	J2	- The abbreviated name of a journal or periodical (user abbreviation 2).
#.	o	J2  - Alternate Title (this field is used for the abbreviated title of a book or journal name) / Periodical name: standard abbreviation
#.	o+	KW  - Keywords (keywords should be entered each on its own line preceded by the tag)
#	??	L1-L4 InternetLink
#.	-	L1  - File Attachments (this is a link to a local file on the users system not a URL link)
#.	-	L4  - Figure (this is also meant to be a link to a local file on the users's system and not a URL link)
#.	o	LA  - Language
#.	-	LB  - Label
#	-	M1  - Number
#.	-	M3  - Type of Work
#.	-	N1  - Notes
#Z  ??	N2	- Abstract (synonym AB)
#.	-	NV  - Number of Volumes
#.	-	OP  - Original Publication
#.Z	o	PB  - Publisher (JACoW Publishing)
#.Z o+	PY  - Publication Year (4 digits) YYYY[/MM[/DD/]]
#	-	RI  - Reviewed Item
#	-	RN  - Research Notes
#.	-	RP  - Reprint status (ON REQUEST (mm/dd/yy)/IN FILE/NOT IN FILE)
#	-	SE  - Section
#Z	o+	SN  - ISBN/ISSN
#	o+	SP  - Start Page
#	-	ST  - Short Title
#Z	-	T1  - Primary Title
#.	-	T2  - Secondary Title / Parent Reference / Editor (Zotero) / book title for a CHAP reference.
#Z	-	T3  - Tertiary Title / Series Title / the series title for a CHAP reference.
#	o	TI  - Title => for BOOK and UNPB the same as BT
#	-	TA  - Translated Author
#	-	TT  - Translated Title
#	??  U1-U5 SpecialText1-5
#.Z	o+	UR  - Web/URL
#Z	-	VL  - Volume number
#   ??  Y1  - Year (Citavi)
#	-	Y2  - Access Date / Date
#
#.	r	ER  - End of Reference (must be the last tag)
#		
#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
	my $RISfile = $protocol_directory.$citpapfil.".ris";
	open (RIS, ">:encoding(UTF-8)", $RISfile) or die ("Cannot open '".$RISfile."' -- $! (line ",__LINE__,")\n");
	#
	# Published (CPAPER) or unpublished (UNPB) work?
	#
	if ($publshd) {
#		print RIS "TY  - CPAPER\n";
		print RIS "TY  - CONF\n";
	} else {
		print RIS "TY  - UNPB\n";  
	}
	#
	# AUthor name one per row
	#
	for ($i = 0; $i <= $cnt_authors; $i++) {
		(my $fni, my $lni) = split ("∞", $bibauth[$i]);
		print RIS "AU  - $lni, $fni\n";
	}
	#
	# EDitor name one per row
	#
	for ($i = 0; $i <= $DOI_xml{num_editors}; $i++) {
		print RIS "ED  - $DOI_xml{editor}[$i]\n";
	}
	print RIS 		"TI  - $citpaptitl8\n",
					"J2  - Proc. of $conference_name, $conference_site_UTF, $conference_date\n",
					"CY  - $conference_site_UTF\n",
					"T2  - $conference_series\n",
					"T3  - $conference_number\n",
					"LA  - english\n",
					"AB  - $citpapabs8\n",
					"PB  - JACoW Publishing\n",
					"CP  - Geneva, Switzerland\n";
	if ($publshd) {
		print RIS	"SP  - $citstapg\n",
					"EP  - $citendpg\n";
		for ($k=0; $k<=$#{$keywords[$pap_nr]}; $k++) {
			print RIS "KW  - $keywords[$pap_nr][$k]\n";
		}
		print RIS 	"DA  - $pubyear_nr/$pubmonth_nr\n",
					"PY  - $pubyear_nr\n";
		if ($series_issn ne "") {
			print RIS "SN  - $series_issn\n";
		}
		print RIS 	"SN  - $conference_isbn\n",
					"DO  - doi:$citdoi\n",
					"UR  - $citurl\n";
	}
	print RIS "ER  - \n";
	close (RIS);
#~~~~~~~~~~~~~~~~~~~~ write REFDB (refs.jacow.org/reference) record ~~~~~~~~~~~~~~~~~~~~~~~~~~
#   DOI: 
#    format: [strings in quoatation marks]
#    content:
#	  JACoW [PubStatus=1] or 
#	  journal DOI [PubStatus=2] (if known at update/publication time) or
#	  empty [PubStatus=3Ö5]
#	  
#   PubStatus:   format: [number]
#    content:
#	  1 published
#	  2 published with light-review (might have additional DOI of journal)
#	  3 presented
#	  4 withdrawn
#	  5 excluded
#
#32.4	if ($citstapg) {
		my $op_ses = substr ($citpapcod, 2, 2) ; # look for 3rd/4th char of paper_id
#		my $op_ses =~ n|OP|CL|i;
		if ($op_ses =~ "OP|CL") {
			print " Opening/Closing Paper\n";
		} else {
			print REFDB	"$citpapcod,\"";
			#
			# author names "first initials last, ..."index
			#
			for ($i = 0; $i < $cnt_authors; $i++) {
				(my $fni, my $lni) = split ("∞", $bibauth[$i]);
				$fni =~ s|\.|\. |g;
				$fni =~ s|\. -|\.-|g;
				print REFDB	"$fni$lni,";
			}
			(my $fni, my $lni) = split ("∞", $bibauth[$i]);
			$fni =~ s|\.|\. |g;
			$fni =~ s|\. -|\.-|g;
			if ($citstapg) {
				print REFDB "$fni$lni\",\"$citpaptitl8\",$citstapg-$citendpg,$abs_id[$pap_nr],$citdoi,1\n";
			} else {
				print REFDB	"$fni$lni\",\"$citpaptitl8\",,$abs_id[$pap_nr],,3\n";	
			}
		}
#	}
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	#
	# open file as "<papercode>-ris.htm" on "$export_directory"
	#
	$citexpfile = $export_directory.$citpapfil."-ris.htm";
	open (CITEXP, ">:encoding(UTF-8)", $citexpfile) or die ("Cannot open '".$citexpfile."' -- $! (line ",__LINE__,")\n");
	include_HighwirePress_DC_Tags (*CITEXP, $pap_nr, "RIS");
	open (RIS, "<:encoding(UTF-8)", $RISfile) or die ("Cannot open '".$RISfile."' -- $! (line ",__LINE__,")\n");
	while (<RIS>) {
		print CITEXP $_;
	}
	close (RIS);
	print CITEXP "</pre>\n",
				 "</body>\n",
				 "</html>\n";
	close (CITEXP);	
#--------------------------------------------------------------------------------------
#  EndNote (XML file format)
#       is a commercial reference management software package, used to manage 
#		bibliographies and references when writing essays and articles. 
#		It is produced by Thomson Reuters.
#		
#--------------
	#
	# open file as "<papercode>.xml" on "$export_directory"
	#
	$citexpfile = $export_directory.$citpapfil.".xml";
	open (CITEXP, ">:encoding(UTF-8)", $citexpfile) or die ("Cannot open '".$citexpfile."' -- $! (line ",__LINE__,")\n");
	#

	print CITEXP "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n",
				 "<xml>\n",
				 "  <records>\n",
				 "    <record>\n",
				 "       <contributors>\n",
				 "          <authors>\n";
	for ($i = 0; $i <= $cnt_authors; $i++) {
		#
		# print author names for XML
		#
		(my $fni, my $lni) = split ("∞", $bibauth[$i]);
		print CITEXP "             <author>$lni, $fni</author>\n";
	}
				 
	print CITEXP "          </authors>\n",
				 "       </contributors>\n",
				 "       <titles>\n",
				 "          <title>\n",
				 "             $citpaptitl8\n",
				 "          </title>\n",
				 "       </titles>\n",
				 "       <publisher>JACoW Publishing</publisher>\n",
				 "       <pub-location>Geneva, Switzerland</pub-location>\n";
	#
	# paper published ?
	#
	if ($publshd) {
		if ($series_issn ne "") {
			print CITEXP "		 <isbn>$series_issn</isbn>\n";
		}
		print CITEXP "		 <isbn>$conference_isbn</isbn>\n",
					 "		 <electronic-resource-num>$citdoi</electronic-resource-num>\n",
					 "		 <language>English</language>\n",
					 "		 <pages>$citstapg-$citendpg</pages>\n",
# ???					 "       <pages>$UCpapcod</pages>\n",
					 "       <keywords>\n";
		for ($k=0; $k<=$#{$keywords[$pap_nr]}; $k++) {
			print CITEXP "          <keyword>$keywords[$pap_nr][$k]</keyword>\n";
		}
		print CITEXP "       </keywords>\n",
					 "       <work-type>Contribution to a conference proceedings</work-type>\n",
					 "       <dates>\n";
		print CITEXP "          <year>$pubyear_nr</year>\n",
					 "          <pub-dates>\n";
		print CITEXP "             <date>$pubyear_nr-$pubmonth_nr</date>\n",
					 "          </pub-dates>\n",
					 "       </dates>\n",
					 "       <urls>\n",
					 "          <related-urls>\n";
		print CITEXP "              <url>https://doi.org/$citdoi</url>\n";
		print CITEXP "              <url>$citurl</url>\n",
					 "          </related-urls>\n",
					 "       </urls>\n";
	}
# still valid from line 13190 (522 lines above)	my $citpapabs8xml	= 	encode_entities ($citpapabs8, '<>&"');
	print CITEXP "       <abstract>\n",
				 "          $citpapabs8xml\n",
				 "       </abstract>\n",
				 "    </record>\n",
				 "  </records>\n",
				 "</xml>\n";

	close (CITEXP);	
#
# JSON version not produced v26.0ff
#
#--------------------------------------------------------------------------------------
if (0) {
#--------------------------------------------------------------------------------------
#  JSON (JavaScript Object Notation) is a lightweight data-interchange format.
#       see https://www.json.org/ for the language syntax
#		JSON can easily be converted to any CSL specific citation style
#		(Zotero, Mendeley, etc.)
#		
#--------------
	#
	# open file as "<papercode>-json.htm" on "$export_directory"
	#
	$citexpfile = $export_directory.$citpapfil."-json.htm";
	open (CITEXP, ">:encoding(UTF-8)", $citexpfile) or die ("Cannot open '".$citexpfile."' -- $! (line ",__LINE__,")\n");
	include_HighwirePress_DC_Tags (*CITEXP, $pap_nr, "CSL-JSON");

	print CITEXP "[{\"id\": \"JACoW-$conference_name-$citpapcod\",\n",
				 "  \"type\": \"paper-conference\",\n",
				 "  \"title\": \"$citpaptitl8\",\n",
				 "  \"collection-title\": \"$conference_series\",\n",
				 "  \"volume\": \"$conference_number\",\n",
				 "  \"publisher\": \"JACoW Publishing\",\n",
				 "  \"publisher-place\": \"Geneva, Switzerland\",\n",
				 "  \"event\": \"$conference_name, $conference_date\",\n",
				 "  \"event-place\": \"$conference_site_UTF\",\n",
				 "  \"abstract\": \"$citpapabs8\",\n";
	if ($series_issn ne "") {
		print CITEXP "  \"ISSN\": \"$series_issn\",\n";
	}
	print CITEXP "  \"ISBN\": \"$conference_isbn\",\n",
				 "  \"language\": \"english\",\n",
				 "  \"author\": [\n";
#
# Authors
#
	for (my $i = 0; $i <= $authors[$pap_nr]; $i++) {
		my $comyn	= ",";
		if ($i == $authors[$pap_nr]) {
			$comyn	= "";
		}
		my $famgiv	= sprintf ("      {\"family\": \"%s\", \"given\": \"%s\"}%s\n", $contrib_ln8[$pap_nr][$i], $contrib_fst[$pap_nr][$i], $comyn);
		print CITEXP $famgiv;
	}
#
# only if published
#
	if ($publshd) {
		print CITEXP "  \"page\": \"$citstapg-$citendpg\",\n",
					 "  \"URL\": \"$citurl\",\n",
					 "  \"DOI\": \"$citdoi\",\n";
	#
	# Editors
	#
		print CITEXP "  \"editor\": [\n";
		for ($i = 0; $i <= $DOI_xml{num_editors}; $i++) {
			my ($lastN, $firstN)	= split (/,/, $DOI_xml{editor}[$i]);
			$firstN		= trim($firstN);
			my $comyn	= ",";
			if ($i == $DOI_xml{num_editors}) {
				$comyn	= "";
			}
			my $famgiv	= sprintf ("      {\"family\": \"%s\", \"given\": \"%s\"}%s\n", $lastN, $firstN, $comyn);
			print CITEXP $famgiv;
		}
		print CITEXP "  ]\n",
					 "  \"issued\": \{\"date-parts\": [[\"$pubyear_nr\", 1]]\}\n",;
	} else {
	print CITEXP "  extra.........\n",
	             "  ]\n";
	}
#
# end of dataset / pre (code part) / html
#
	print CITEXP "\}]\n",
				 "</pre>\n",
				 "</body>\n",
				 "</html>\n";
	close (CITEXP);	
} # JSON code production placed in a maybe logic)

    Deb_call_strucOut ();
	return;
}
##############################################
#
# convert_spec_chars_TXT    <√±|
#
##############################################
# c_s_c
#
#    convert all HTML characters by their text equivalent (mostly done by "decode_entities")
#    Arguments [0] string to be converted
#              [1] identification string from where the procedure was called
#    Returns   [0] modified $_
#
sub convert_spec_chars_TXT {

    $_    = $_[0];   # was @_[0]
 my $wohe = $_[1];
    if ($_ eq "") {
        print DBG " --> ($wohe) ^empty string ($paper_code[$pap])\n";
        return;
    }
	my $in_string = $_;
 	Deb_call_strucIn ("convert_spec_chars_TXT ($_)");

    print DBG ">c_s_c_TXT ($wohe)> $_\n" unless $debug_restricted;
#
# substitute HTML/LaTeX sequences by text
#
    s|<sup>&#8722;</sup>|\^-|g;
    s|&amp;|&|g;
	$_ = UTF_convert_spec_chars ($_, "css_TXT");
	s|\\&|&|g;
#	s|\{\"\}|"|g;
	s|\{\"\}|'|g;
	s|&quot;|"|g;
#%	s|&ndash;|ó|g;          # endash
#%  s|&#8217;|'|g;          # "right single quotation mark"        (<= &#146;)
#%    s|&#64256;|ff|g;        # ff-ligature
#%    s|&#64257;|fi|g;        # fi-ligature
#%    s|&#64258;|fl|g;        # fl-ligature
#%    s|&#64259;|ffi|g;       # ffi-ligature
#%    s|&#8545;|II|g;         # funny II sign for PLS-II (U+2161 ROMAN NUMERAL TWO)
#%    s|&#8216;|`|g;          # "left single quotation mark"         (<= &#145;)
#%    s|&#8220;|ì|g;          # ì left to right (66) "left double quotation mark"
#%	s|&#8221;|î|g;          # î right to left (99) "right double quotation mark" in hex (<= &#148;)
#%    s|&#934;|PH|g;			# Phi of DAPHNE
#%    s|&#946;|ﬂ|g;           # beta
#%	s|&#956;|µ|g;			# micro/mue
#%	s|&#95;|_|g;            #
	
	if (m|&[#0-9]|) {
		print " ???: $_\n";
	}
#
# some spacing introduced at some point is unwanted, try to get rid of ") , "
#    happens in author lines for abstract booklets
#
	s|\) , |\), |g;
#
# fixing errors "\high{-}-?" => "\high{-?}"
#
	if (m|high\{-\}-|) {
		print " found \"high{-}-\" \n";
		s|high\{-\}-(.)|high\{-$1\}|g;
	}
#
# no substitutions made in "convert_spec_chars_TXT"
#
    if ($_ eq $in_string) {
		print DBG "<c_s_c_TXT ($wohe)> nosubs\n";
	} else {
		print DBG "<c_s_c_TXT ($wohe)> $_\n" unless $debug_restricted;
	}

	Deb_call_strucOut ();
    return $_;
}
#-----------------------------
#
#  Write clean up command file for poster and talk PDFs
#
#-----------------------------
sub clean_pdf_metadata {
  	Deb_call_strucIn ("clean_pdf_metadata");
	#
	# write a commandline for "exiftool" to put sensible/clean METADATA 
	#       into the hidden fields of PDF talks and posters
	#
	my $pfh = shift;
	#
	# write "Author", "Subject" and "Title" fields for each downloaded PDF file
	#
	my $auth = "$contrib_ini[$paper_nr][0] $contrib_lst[$paper_nr][0] ($contrib_abb[$paper_nr][0], $contrib_ins[$paper_nr][0])";
    my $cls  = "$paper_mcls[$paper_nr]";
	my $scls = $paper_scls[$paper_nr];
	if ($scls ne " ") {
		$cls .= " / $scls";
	}
	print $pfh sprintf ("exiftool -Author=\"%-s\" -Creator=\"%-s\" -Subject=\"%-s\" -Title=\"%-s\" %-s\n",
						$auth, $auth, $cls, $title[$paper_nr], $wget_fullfilename);

	Deb_call_strucOut ();
	return;
}
#---------------------------------------------------------------------------------
#
#  Write INSPIRE record with all authors / keywords / Publication date / base data
#
#-----------------------------
sub INSPIRE_write_data_record {
  	Deb_call_strucIn ("INSPIRE_write_data_record");
#
# INSPIRE $100=main author 
#         $700=co-author
#               $$a=Author
#				$$u=Affiliation
#				$$v=Acronym
#				$$m=Email
#				$$j=Author Id = JACoW-Id
#
print DBG " entering INSP for Pap:$pap #auth:$authors[$pap]\n";
	my %seen 	= ();
	my $numele 	= $authors[$pap];
	my $ai;
	my $ar;
	my $gshn;
	my $xml_a_cnt = -1;
	for ($ai=0; $ai <= $numele; $ai++) {
		$gshn = 1;
		unless ($seen{$ai}) { $gshn = 0; };
		print DBG " INSP_wr: Pap: $pap AuthI:$ai seen:$gshn Contrib:$contrib_typ[$pap][$ai] Author:$contrib_ln8[$pap][$ai], $contrib_fst[$pap][$ai] JACoW:$contrib_aid[$pap][$ai]\n";
		unless ($seen{$ai}) {
			#
			# check for main author
			# tag = $100 for main-author 
			#       $700 for co-author
			#
			my $INSPIRE_tag = 700;
			my $author_act	= "$contrib_ini[$pap][$ai] $contrib_lst[$pap][$ai]";
			if ($author_act eq $main_author[$pap]) {
				$INSPIRE_tag = 100;
			}
			#
			# the following statements seem to be not executed at all (neither with "&#" nor with "&amp;#")
			#
			if ($contrib_fst[$pap][$ai] =~ m|&#|) {			# was &amp;#
				print " Firstname &: ($contrib_fst[$pap][$ai]\n";
				$contrib_fst[$pap][$ai] = UTF_convert_spec_chars ($contrib_fst[$pap][$ai]);
			}
			if ($contrib_ins[$pap][$ai] =~ m|&#|) {			# was &amp;#
				print " Institute &: ($contrib_fst[$pap][$ai]\n";
				$contrib_ins[$pap][$ai] = UTF_convert_spec_chars ($contrib_ins[$pap][$ai]);
			}
			#
			# this is just a very frantic try to correct the XML names (at the last possible moment)
			#
			$contrib_fst[$pap][$ai]	= Frantic ($contrib_fst[$pap][$ai]);
#			$contrib_lst[$pap][$ai]	= Frantic ($contrib_lst[$pap][$ai]);
			$contrib_ins[$pap][$ai]	= Frantic ($contrib_ins[$pap][$ai]);
			$contrib_ln8[$pap][$ai]	= Frantic ($contrib_ln8[$pap][$ai]);
			#
			#
			#
			$seen{$ai} = 1;
			#
			# main entry with name and affiliation
			#
			print INSPIRE "    <datafield tag=\"$INSPIRE_tag\" ind1=\" \" ind2=\" \">\n",     # first author, if possible with full first name
						  "       <subfield code=\"a\">$contrib_ln8[$pap][$ai], $contrib_fst[$pap][$ai]</subfield>\n",
# rem 21.11.19	  		  "       <subfield code=\"u\">$contrib_abb[$pap][$ai]</subfield>\n",
						  "       <subfield code=\"v\">$contrib_abb[$pap][$ai], $contrib_ins[$pap][$ai]</subfield>\n";
			#
			# now check for duplicate JACoW ids: these authors have a second/third/... affiliation 
			#                                    which is written as $$u/v subfields in the same record
			#
			my $jac_id = $contrib_aid[$pap][$ai];
			for ($ar = $ai + 1; $ar <= $numele; $ar++) {
				$gshn = 1;
				unless ($seen{$ai}) { $gshn = 0; };
				print DBG " INSP_w2: ar:$ar act_id:$contrib_aid[$pap][$ar] seen:$gshn\n";
				if (($jac_id eq $contrib_aid[$pap][$ar]) && !$seen{$ar}) {
					$seen{$ar} = 1;
					print DBG " INSP_w3: ar:$ar act_id:$contrib_aid[$pap][$ar] seen:$seen{$ar}\n";
# rem 21.11.19		print INSPIRE "       <subfield code=\"u\">$contrib_abb[$pap][$ar]</subfield>\n";
					print INSPIRE "       <subfield code=\"v\">$contrib_abb[$pap][$ar], $contrib_ins[$pap][$ar]</subfield>\n";
				}
			} #> end duplicate JACoW Ids
			print INSPIRE "       <subfield code=\"m\">$contrib_ema[$pap][$ai]</subfield>\n",
						  "       <subfield code=\"j\">$jac_id</subfield>\n",
						  "    </datafield>\n";
			#
			# store data for DOI XML
			#
			$xml_a_cnt++;
			$DOI_xml{$pap}{authcnt}				= $xml_a_cnt;
			$DOI_xml{$pap}{author}[$xml_a_cnt]	= "$contrib_ln8[$pap][$ai], $contrib_fst[$pap][$ai]";
			$DOI_xml{$pap}{affil}[$xml_a_cnt]	= "$contrib_abb[$pap][$ai], $contrib_ins[$pap][$ai]";
			$DOI_xml{$pap}{jacid}[$xml_a_cnt]	= $jac_id;
		} #> end unless seen
	} #> end all authors
	print DBG " leaving  INSP for Pap:$pap #auth:$authors[$pap]\n";
	Deb_call_strucOut ();
	return;
}
#---------------------------------------------------------------------------------
#
#  Write INSPIRE record with keywords / Publication date / base data
#
#-----------------------------
sub INSPIRE_Keywords {
  	Deb_call_strucIn ("INSPIRE_Keywords");
#
# INSPIRE $453 $$a=keywords $$2="JACoW"
#
	for ($k=0; $k<=$#{$keywords[$pap]}; $k++) {
		print INSPIRE "    <datafield tag=\"653\" ind1=\"1\" ind2=\" \">\n",       # JACoW keywords
					  "       <subfield code=\"a\">$keywords[$pap][$k]</subfield>\n",
					  "       <subfield code=\"2\">JACoW</subfield>\n",
					  "    </datafield>\n";
	}
#
# INSPIRE $260 $$c=publication date 
#
	print INSPIRE "    <datafield tag=\"260\" ind1=\" \" ind2=\" \">\n",           # date of publication <year>-<month> (aaaa-mm)
				  "       <subfield code=\"c\">$conference_pub_date</subfield>\n",
				  "    </datafield>\n",
				  "  </record>\n";
	Deb_call_strucOut ();
	return;
}
#---------------------------------------------------------------------------------
#
#  official abbreviations for Internation/Conference/Proceedings/etc
#
#-----------------------------
sub title_short {
  	Deb_call_strucIn ("title_short");

	$_    = $_[0];
#
# substitute known abbr. for long words
#
	s|International|Int.|ig;
	s|Conference|Conf.|ig;
	s|Proceeding[s]{0,1}|Proc.|ig;
	s|Engineering|Eng.|ig;
	s|Instrumentation|Instrum.|ig;
	s|Mechanical|Mech.|ig;
	s|Radiation|Radiat.|ig;
	s|Equipment|Equip.|ig;
	s|Accelerator|Acc.|ig;
	s|Experimental|Exp.|ig;

	Deb_call_strucOut ();
	return $_;
}
#---------------------------------------------------------------------------------
#
#  generate DOI landing page with all metadata in HTML 	=> "$doi_directory" ~> 
#         + DOI XML set for datacite.org				=> "$doixml_directory"
#         + DOI registration commands for "mdssuite"	=> ditto
#
#-----------------------------
sub DOI_landing_html {
  	Deb_call_strucIn ("DOI_landing_html");

	my $doitest	= $protocol_directory."DOI-testfile.txt";
	open (DOITEST, ">:encoding(UTF-8)", $doitest) or die ("Cannot open '".$doitest."' -- $! (line ",__LINE__,")\n");
#
# DOI registration commands using "mdssuite"
#
#<i>	my $doireg	= $doixml_directory."DOI-register.bat";
#<i>	open (MDSSUITE, ">", $doireg) or die ("Cannot open '".$doireg."' -- $! (line ",__LINE__,")\n");

#
# DOI registration commands using "curl" (put registration cite in filename)
#
	$DOI_site		=~ m|//(.*?)/|;
	my $reg_cite	= $1;
	$reg_cite		=~ s|\.|-|g;
	print "Registration on $reg_cite => $DOI_site\n";

	my $doicurl	= sprintf ("%sDOI-curl-reg-%s.bat", $doixml_directory, $reg_cite);
	open (DOICURL, ">", $doicurl) or die ("Cannot open '".$doicurl."' -- $! (line ",__LINE__,")\n");
	#
	# Generate DOI for conference
	#
	DOI_conference_proceedings ();
	#
	# Open "Reference Search Tool" csvfile
	#
	my $refdb 	= $protocol_directory.$conference_name."-refdb.csv";
	open (REFDB, ">:encoding(UTF-8)", $refdb) or die ("Cannot open '".$refdb."' -- $! (line ",__LINE__,")\n");
	print REFDB ("PaperId,Authors,Title,Page-Range,Contribution_id,DOI,PubStatus\n");

	my $citdb 	= $protocol_directory."citdb.txt";
	open (CITDB, ">:encoding(UTF-8)", $citdb) or die ("Cannot open '".$citdb."' -- $! (line ",__LINE__,")\n");

	$num_of_doipl = 0;
	for (my $pap_nr = 0; $pap_nr <= $paper_nr_max; $pap_nr++) {
		#
		# skip all submissions without published paper (normally only Orals)
		#
		print CITDB ("\n PapNr [$pap_nr] --> $paper_code[$pap_nr]\n");
		if ($DOI_land{$pap_nr}{paperlink} ne "") {
			#
			# open DOI landing page file
			#
			my $file = $DOI_lpd."/".$DOI_land{$pap_nr}{doi_jcp}.".html";
			$DOI_land{$pap_nr}{filename} = $file;
			open (DOILP, ">:encoding(UTF-8)", $file) or die ("Cannot open '".$file."' -- $! (line ",__LINE__,")\n");

			print DOILP $html_content_type."\n",
						"<html lang=\"en\">\n",
						"<head>\n",
						"  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#						"  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
						"  <meta name=\"keywords\" content=\"doi, conference, proceedings\" />\n",
						"  <meta name=\"generator\" content=\"copyright 2015-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
						"  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
						"  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
						"  <link rel=\"stylesheet\" href=\"../html/doi.css\" />\n",
						"  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
						"  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
#						"  <script src=\"xbt.js\"></script>\n",
						"  <script src=\"../html/Hyphenator.js\"></script>\n",
						"  <script src=\"../html/en.js\"></script>\n",
						"  <script type=\"text/javascript\">Hyphenator.config({remoteloading : false}); Hyphenator.run();</script>\n";
			HighwirePress_Tags (*DOILP, $pap_nr);


			print DOILP	sprintf ("<title>DOI - %s</title>\n", $DOI_land{$pap_nr}{doi_jcp});
			print DOILP	"</head>\n<body>\n<a href=\"https://www.jacow.org\"><img src=\"$jacow_hdr\"  width=\"480\" height=\"60\" alt=\"JACoW logo\" /></a>\n", 
						"<h1>Joint Accelerator Conferences Website</h1>\n",
						"<p class=\"intro\">The Joint Accelerator Conferences Website (<a href=\"https://www.jacow.org\">JACoW</a>) is an international collaboration that publishes the ",
						"proceedings of accelerator conferences held around the world.</p>\n<hr />\n";
		#
		# DOI banner (DOI address gets link to paper on JACoW)
		#
			print DOILP	sprintf ("<div><span class=\"doiheader\"><a href=\"%s\">https://doi.org/%s</a></span></div>\n<div>\n", 
						$DOI_land{$pap_nr}{paperlink}, $DOI_land{$pap_nr}{doi});
			print DOILP "<table class=\"doitabledef\">\n";
		#
		# Title
		#
			print DOILP	"<tr class=\"tablerow\">\n",
						"    <td class=\"fieldgrp\">Title</td>\n";
			print DOILP sprintf ("   <td class=\"fieldhigh\">%s</td>\n", $DOI_land{$pap_nr}{title});
			print DOILP	"</tr>\n";
		#
		# Authors
		#
			print DOILP	"<tr class=\"tablerow\">\n",
						"    <td class=\"fieldkey\">Authors</td>\n",
						"    <td class=\"datarowleft\">\n",
						"        <ul>\n";
			print DOILP sprintf ("  %s\n", $DOI_land{$pap_nr}{authors});
			print DOILP	"        </ul>\n",
						"    </td>\n",
						"</tr>\n";
		#
		# Abstract
		#
			print DOILP	"<tr class=\"tablerow\">\n",
						"    <td class=\"fieldkey\">Abstract</td>\n";
			print DOILP sprintf ("    <td>\n      <span class=\"abstract hyphenate jtext\" lang=\"en\">%s</span>\n", $DOI_land{$pap_nr}{abstract});
			print DOILP	"    </td>\n",
						"</tr>\n";
		#
		# Footnotes
		#
			if ($DOI_land{$pap_nr}{footnote} ne "") {
				print DOILP	"<tr class=\"tablerow\">\n",
							"    <td class=\"fieldkey\">Footnotes & References</td>\n";
				print DOILP sprintf ("    <td class=\"datarow\">%s</td>\n", $DOI_land{$pap_nr}{footnote});
				print DOILP	"</tr>\n";
			}
		#
		# Funding
		#
			if ($DOI_land{$pap_nr}{funding} ne "") {
				print DOILP	"<tr class=\"tablerow\">\n",
							"    <td class=\"fieldkey\">Funding</td>\n";
				print DOILP sprintf ("    <td class=\"datarow\">%s</td>\n", $DOI_land{$pap_nr}{funding});
				print DOILP	"</tr>\n";
			}
		#
		# Paper link
		#
			print DOILP	"<tr class=\"tablerow\">\n",
						"    <td class=\"fieldkey\">Paper</td>\n";
			print DOILP sprintf ("    <td class=\"datarow\">%s</td>\n", $DOI_land{$pap_nr}{papertextlnk});
			print DOILP	"</tr>\n";
		#
		# Slides link
		#
			if ($DOI_land{$pap_nr}{slideslink} ne "") {
				print DOILP	"<tr class=\"tablerow\">\n",
							"    <td class=\"fieldkey\">Slides</td>\n";
				print DOILP sprintf ("    <td class=\"datarow\">%s</td>\n", $DOI_land{$pap_nr}{slideslink});
				print DOILP	"</tr>\n";
			}
		#
		# Poster link
		#
			if ($DOI_land{$pap_nr}{posterlink} ne "") {
				print DOILP	"<tr class=\"tablerow\">\n",
							"    <td class=\"fieldkey\">Poster</td>\n";
				print DOILP sprintf ("    <td class=\"datarow\">%s</td>\n", $DOI_land{$pap_nr}{posterlink});
				print DOILP	"</tr>\n";
			}
		#
		# Bibliographic data links
		#
#check 170707			my $expdir = $conference_url."export/$paper_code[$pap_nr]";
			my $expdir = ".$export_directory$paper_code[$pap_nr]";
			print DOILP	"<tr class=\"tablerow\">\n",
						"    <td class=\"fieldkey\">Export</td>\n";
			print DOILP "    <td class=\"datarow\">download &#8251; <a href=\"$expdir-bib.htm\" target=\"exp\">BibTeX</a> \n",
						"                                 &#8251; <a href=\"$expdir-tex.htm\" target=\"exp\"> LaTeX</a> \n",
						"                                 &#8251; <a href=\"$expdir-txt.htm\" target=\"exp\">Text/Word</a> \n",
						"                                 &#8251; <a href=\"$expdir-ris.htm\" target=\"exp\">RIS</a> \n",
						"                                 &#8251; <a href=\"$expdir.xml\" target=\"exp\">EndNote</a></td>\n";
			print DOILP	"</tr>\n";
		#
		# Conference
		#
			print DOILP	"<tr class=\"tablerow\">\n",
						"    <td class=\"fieldgrp\">Conference</td>\n";
#			print DOILP sprintf ("    <td class=\"fieldhigh\">%s</td>\n", $conference_name);
			print DOILP sprintf ("    <td class=\"fieldhigh\"><a href=\"%s\" target=\"pdf\">%s</a></td>\n", $conference_url, $conference_name);
			print DOILP	"</tr>\n";
		#
		# Series
		#
			print DOILP	"<tr class=\"tablerow\">\n",
						"    <td class=\"fieldkey\">Series</td>\n";
			print DOILP sprintf ("    <td class=\"datarow\">%s (%s)</td>\n", $conference_series, ordinal($conference_number));
			print DOILP	"</tr>\n";
		#
		# Location
		#
			print DOILP	"<tr class=\"tablerow\">\n",
						"    <td class=\"fieldkey\">Location</td>\n";
			print DOILP sprintf ("    <td class=\"datarow\">%s</td>\n", $conference_site_UTF);
			print DOILP	"</tr>\n";
		#
		# Proceedings
		#
#			print DOILP	"<tr class=\"tablerow\">\n",
#						"    <td class=\"fieldkey\">Proceedings</td>\n";
#			print DOILP sprintf ("    <td class=\"datarow\">Link to full <a href=\"%s\" target=\"pdf\">%s Proceedings</a></td>\n", 
#								 $conference_url, $conference_name);
#			print DOILP	"</tr>\n";
		#
		# Session
		#
#			print DOILP	"<tr class=\"tablerow\">\n",
#						"    <td class=\"fieldkey\">Session</td>\n";
#			print DOILP sprintf ("    <td class=\"datarow\">%s</td>\n", $DOI_land{$pap_nr}{session});
#			print DOILP	"</tr>\n";
		#
		# Date
		#
			print DOILP	"<tr class=\"tablerow\">\n",
						"    <td class=\"fieldkey\">Date</td>\n";
			print DOILP "    <td class=\"datarow\">$conference_date</td>\n";
			print DOILP	"</tr>\n";
		#
		# Main Classification
		#
#			print DOILP	"<tr class=\"tablerow\">\n",
#						"    <td class=\"fieldkey\">Main Classification</td>\n";
#			print DOILP sprintf ("    <td class=\"datarow2\">%s</td>\n", $DOI_land{$pap_nr}{main});
#			print DOILP	"</tr>\n";
		#
		# Sub Classification
		#
#			if ( defined $DOI_land{$pap_nr}{sub} && $DOI_land{$pap_nr}{sub} ne ' ' ) {
#				print DOILP	"<tr class=\"tablerow\">\n",
#							"    <td class=\"fieldkey\">Sub Classification</td>\n";
#				print DOILP sprintf ("    <td class=\"datarow2\">%s</td>\n", $DOI_land{$pap_nr}{sub});
#				print DOILP	"</tr>\n";
#			}
		#
		# Keywords
		#
#			print DOILP	"<tr class=\"tablerow\">\n",
#						"    <td class=\"fieldkey\">Keywords</td>\n";
#			print DOILP sprintf ("    <td class=\"datarow\">%s</td>\n", $keywjoin{$paper_code[$pap_nr]});
#			print DOILP	"</tr>\n";
		#
		# Publisher
		#
			print DOILP	"<tr class=\"tablerow\">\n",
						"    <td class=\"fieldgrp\">Publisher</td>\n",
						"    <td class=\"fieldhigh\"><a href=\"https://www.jacow.org\" target=\"pdf\">JACoW Publishing, Geneva, Switzerland</a></td>\n",
						"</tr>\n";
		#
		# Editors (remove quotes and id from string e.g. [JACoW:1111])
		#
			print DOILP	"<tr class=\"tablerow\">\n",
						"    <td class=\"fieldkey\">Editorial Board</td>\n";
			print DOILP sprintf ("    <td class=\"datarow\">%s</td>\n", $DOI_land{editors}	);
			print DOILP	"</tr>\n";
		#
		# ISBN
		#
			print DOILP	"<tr class=\"tablerow\">\n",
						"    <td class=\"fieldkey\" nowrap>Online ISBN</td>\n";
			print DOILP sprintf ("    <td class=\"datarow\">%s</td>\n", $conference_isbn);
			print DOILP	"</tr>\n";
		#
		# ISSN
		#
			if ($series_issn ne "") {
				print DOILP	"<tr class=\"tablerow\">\n",
							"    <td class=\"fieldkey\" nowrap>Online ISSN</td>\n";
				print DOILP sprintf ("    <td class=\"datarow\">%s</td>\n", $series_issn);
				print DOILP	"</tr>\n";
			}
		#
		# Paper received
		#
			print DOILP	"<tr class=\"tablerow\">\n",
						"    <td class=\"fieldkey\">Received</td>\n";
			print DOILP sprintf ("    <td class=\"datarow\">%s</td>\n", PubDate ($paper_recv[$pap_nr]));
			print DOILP	"</tr>\n";
		#
		# Paper accepted
		#
			print DOILP	"<tr class=\"tablerow\">\n",
						"    <td class=\"fieldkey\">Accepted</td>\n";
			print DOILP sprintf ("    <td class=\"datarow\">%s</td>\n", PubDate ($paper_acpt[$pap_nr]));
			print DOILP	"</tr>\n";
		#
		# Published (Available online)
		#
			print DOILP	"<tr class=\"tablerow\">\n",
						"    <td class=\"fieldkey\">Issue Date</td>\n";
			print DOILP sprintf ("    <td class=\"datarow\">%s %s %s</td>\n", $pubday_nr, $pubmonth_alf, $pubyear_nr);
			print DOILP	"</tr>\n";
		#
		# DOI (again)
		#
			print DOILP	"<tr class=\"tablerow\">\n",
						"    <td class=\"fieldkey\">DOI</td>\n";
			print DOILP sprintf ("    <td class=\"datarow\"><span style=\"font-family:'Liberation Mono'; font-size:12pt;\">doi:10.18429/%s</span></td>\n", $DOI_land{$pap_nr}{doi_jcp});
			print DOILP	"</tr>\n";
		#
		# Pages
		#
			my $endpage	= $page_start[$pap_nr] + $paper_pages[$pap_nr] - 1;
			print DOILP	"<tr class=\"tablerow\">\n",
						"    <td class=\"fieldkey\">Pages</td>\n";
			print DOILP "    <td class=\"datarow\">$page_start[$pap_nr]-$endpage</td>\n";
			print DOILP	"</tr>\n";
		#
		# Copyright
		#
			print DOILP	"<tr class=\"tablerow\">\n",
						"    <td class=\"fieldkey\">Copyright</td>\n",
						"    <td class=\"datarow\">\n",
						"        <table>\n";
			print DOILP "          <tr><td><span class=\"abstract hyphenate jtext\" lang=\"en\"><a href=\"https://creativecommons.org/licenses/by/3.0/\"><img alt=\"Creative Commons CC logo\" src=\"../im0ges/cc.png\" style=\"float: left; margin: 10px\" height=\"30\"></a><i>Published by JACoW Publishing under the terms of the <a href=\"https://creativecommons.org/licenses/by/3.0/\">Creative Commons Attribution 3.0 International</a> license. Any further distribution of this work must maintain attribution to the author(s), the published article's title, publisher, and DOI.</i></span></td>\n",
						"          </tr>\n",
						"        </table>\n",
						"    </td>\n";
		#
		# closing elements
		#
			print DOILP	"</table>\n</div>\n\n</body>\n</html>";
			close (DOILP);
			$num_of_doipl++;
	#-------------------------------------------------------------
		#
		# open XML files with DOI metadata
		#
			$DOI_xmlfile = sprintf ("%s/DOI-%s.xml", $doixml_directory, $DOI_land{$pap_nr}{doi_jcp});
			open (DOIxml, ">:encoding(UTF-8)", $DOI_xmlfile) or die ("Cannot open '$DOI_xmlfile' -- $! (line ",__LINE__,")\n");
		#
		# DOI identifier
		# mds: 1.
		#								<resource xsi:schemaLocation="http://datacite.org/schema/kernel-4 http://schema.datacite.org/meta/kernel-4/metadata.xsd" 
		
			print DOIxml 			  "<resource xsi:schemaLocation=\"http://datacite.org/schema/kernel-4 http://schema.datacite.org/meta/kernel-4/metadata.xsd\" ",
																	"xmlns=\"http://datacite.org/schema/kernel-4\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">\n",
									  "<identifier identifierType=\"DOI\">$DOI_land{$pap_nr}{doi}</identifier>\n",
									  "<creators>\n";
		#
		# Authors: name / affiliation / ID
		# mds: 2.1-2.3
		#
			for (my $a_n = 0; $a_n <= $DOI_xml{$pap_nr}{authcnt}; $a_n++) {
				print DOIxml 		  "  <creator>\n";
				print DOIxml sprintf ("    <creatorName>%s</creatorName>\n", $DOI_xml{$pap_nr}{author}[$a_n]);
				print DOIxml sprintf ("    <nameIdentifier schemeURI=\"https://www.jacow.org/\" nameIdentifierScheme=\"JACoW-ID\">%s</nameIdentifier>\n", 
										$DOI_xml{$pap_nr}{jacid}[$a_n]);
				print DOIxml sprintf ("    <affiliation>%s</affiliation>\n", $DOI_xml{$pap_nr}{affil}[$a_n]);
				print DOIxml 		  "  </creator>\n";
			}
			print DOIxml 			  "</creators>\n",
									  "<titles>\n";
		#
		# Title
		# mds: 3.
		#
			print DOIxml sprintf	 ("  <title xml:lang=\"en-us\">%s</title>\n", $DOI_land{$pap_nr}{titleXML});
			print DOIxml 			  "</titles>\n",
		#
		# Publisher
		# mds: 4.
		#
									  "<publisher>JACoW Publishing, Geneva, Switzerland </publisher>\n";
		#
		# Publication Year
		# mds: 5.
		#
			print DOIxml sprintf	 ("<publicationYear>%s</publicationYear>\n", $pubyear_nr);
		#
		# Subjects:  "Accelerator Physics<"
		#			 "Main Classification"
		#			 "Sub Classification"
		# mds: 6.
		#
			print DOIxml 			  "<subjects>\n",
									  "  <subject xml:lang=\"en-us\">Accelerator Physics</subject>\n";
			print DOIxml sprintf	 ("  <subject xml:lang=\"en-us\">%s</subject>\n", $DOI_land{$pap_nr}{main});

			if ( defined $DOI_land{$pap}{sub} && $DOI_land{$pap}{sub} ne ' ' ) {
				print DOIxml sprintf ("  <subject xml:lang=\"en-us\">%s</subject>\n", $DOI_land{$pap_nr}{sub});
			}
			print DOIxml 			  "</subjects>\n",
									  "<contributors>\n";
		#
		# Contributors: Editors
		# mds: 7.1 - 7.4
		#
			for (my $e_n = 0; $e_n <= $DOI_xml{num_editors}; $e_n++) {
				print DOIxml		  "  <contributor contributorType=\"Editor\">\n";
				print DOIxml sprintf ("    <contributorName>%s (Ed.)</contributorName>\n", $DOI_xml{editor}[$e_n]);
				#
				# get Id_scheme and number
				#
				my ($id_scheme, $id_num) = split (/:/, $DOI_xml{editor_id}[$e_n]);

				my $id_schurl = "https://www.jacow.org/";
				if ($id_scheme =~ m/ORCID/i) {
					$id_scheme = "ORCID";
					$id_schurl = "https://orcid.org/";
				} else {
					$id_num	= sprintf ("JACoW-%08d", $id_num);
				}
				print DOIxml sprintf ("    <nameIdentifier schemeURI=\"%s\" nameIdentifierScheme=\"%s\">%s</nameIdentifier>\n",
												$id_schurl, $id_scheme, $id_num);
				print DOIxml sprintf ("    <affiliation>%s</affiliation>\n", $DOI_xml{editor_af}[$e_n]);
				print DOIxml		  "  </contributor>\n";
			}
			print DOIxml 			  "</contributors>\n",
									  "<dates>\n";
		#
		# Dates
		# mds: 8.
		#
			print DOIxml sprintf	 ("  <date dateType=\"Created\">%s</date>\n", $data_generation_date);		# or "Issued"
			print DOIxml 			  "</dates>\n",
		#
		# Language + ResourceType
		# mds: 9. + 10.
		#
									  "<language>en-us</language>\n",
									  "<resourceType resourceTypeGeneral=\"Text\">ConferencePaper</resourceType>\n",
									  "<relatedIdentifiers>\n";
		#
		# relatedIdentifier: ISBN 
		# mds: 12.1
		#
			print DOIxml sprintf     ("  <relatedIdentifier relatedIdentifierType=\"ISBN\" relationType=\"IsPartOf\">%s</relatedIdentifier>\n", 
											$conference_isbn);
		#
		# relatedIdentifier: ISSN 
		# mds: 12.1 (copied from ISBN)
		#
			if ($series_issn ne "") {
				print DOIxml sprintf     ("  <relatedIdentifier relatedIdentifierType=\"ISSN\" relationType=\"IsPartOf\">%s</relatedIdentifier>\n", 
												$series_issn);
			}
		#
		# closing </relatedIdentifiers>
		#
			print DOIxml 			  "</relatedIdentifiers>\n";
		#
		# Sizes: # of pages + Mb
		# mds: 13.
		#
			(my $fsiz = $paper_fss[$pap_nr]) =~ s|[\[\]]||g;
			print DOIxml sprintf	 ("<sizes>\n  <size>%d pages</size>\n", $paper_pages[$pap_nr]);
			print DOIxml sprintf	 ("  <size>%s</size>\n", $fsiz);
		#
		# Format: PDF
		# mds: 14.
		#
			print DOIxml 			  "</sizes>\n",
									  "<formats><format>PDF</format></formats>\n",
									  "<rightsList>\n",
		#
		# Rights: CC-BY-3.0
		# mds: 16.
		#
									  "  <rights rightsURI=\"https://creativecommons.org/licenses/by/3.0/\">CC 3.0</rights>\n",
									  "</rightsList>\n",
									  "<descriptions>\n",
									  "  <description xml:lang=\"en-us\" descriptionType=\"Abstract\">\n";
		#
		# Destriptions: 
		#				Type: Abstract
		#				Type: SeriesInformation
		# mds: 17.1
		#
			print DOIxml sprintf	 ("    %s\n", $DOI_land{$pap_nr}{abstract});			  
			print DOIxml 			  "  </description>\n",
									  "  <description descriptionType=\"SeriesInformation\">\n";
			print DOIxml sprintf	 ("    Proceedings of the %s, %s, %s\n", $conference_title, $conference_name, $conference_site_UTF);
			print DOIxml 			  "  </description>\n",
									  "</descriptions>\n",
									  "</resource>\n";  
			close (DOIxml);
	#-------------------------------------------------------------
	#
	#  generate the DOI registration commands (PERL)
	#
			#
			# the DOI_xml-file is now in the XML directory below
			#
			my $xmlfile = sprintf ("./DOI-JACoW-%s-%s.xml", $conference_name, $paper_code[$pap_nr]);

			#
			# CURL parameters
			#    -d, --data DATA     HTTP POST data (H)
			#    -H, --header LINE   Pass custom header LINE to server (H)
			# 	 -k, --insecure      Allow connections to SSL sites without certs (H)
			#    -u, --user USER[:PASSWORD]  Server user and password (passed by $DOI_useraccount)
			#
			print DOICURL sprintf  ("\n$WL_Rem -------- %s ---------\n", 
									$paper_code[$pap_nr]);
			print DOICURL sprintf  ("curl --insecure --header Content-Type:application/xml --data-binary \@%s %s https://mds.datacite.org/metadata\n", 
									$xmlfile, $DOI_useraccount);
			print DOICURL sprintf  ("curl --insecure --data doi=%s --data url=%s%s\.html %s https://mds.datacite.org/doi\n", 
									$DOI_land{$pap_nr}{doi}, $DOI_site, $DOI_land{$pap_nr}{doi_jcp}, $DOI_useraccount);
			#>>
			#	mds-suite.pl metadata put 10.1234/JACoW-IPAC2014-MOXAA01 < MAXAA01-metadata.xml
			#	mds-suite.pl doi post 10.1234/JACoW-IPAC2014-MOXAA01 "https://accelconf.web.cern.ch/AccelConf/IPAC2014/papers/moxaa01.pdf"
			#>>
	#<i>
	#<i>		print MDSSUITE sprintf ("\n$WL_Rem -------- %s ---------\n", 
	#<i>								$paper_code[$pap_nr]);
	#<i>		print MDSSUITE sprintf ("mds-suite.pl metadata put %s < %s\n", 
	#<i>								$DOI_land{$pap_nr}{doi}, $xmlfile);
	#<i>		print MDSSUITE sprintf ("mds-suite.pl doi post %s \"%s%s.html\"\n", 
	#<i>								$DOI_land{$pap_nr}{doi}, $DOI_site, $DOI_land{$pap_nr}{doi_jcp});
			
	#---------------------------------------------------------------------------------
		# 
		# protocol output
		#
			print DOITEST "--------------------------------------\n";
			print DOITEST sprintf (" %4i. %s\n", $pap_nr, $file);
	#		print DOITEST "Abstract:    $DOI_land{$pap_nr}{abstract}\n";
			print DOITEST "paperlnk:    $DOI_land{$pap_nr}{papertextlnk}\n";
			if ($DOI_land{$pap_nr}{slideslink} ne "") {
				print DOITEST "slidelnk:    $DOI_land{$pap_nr}{slideslink}\n";
			}
			if ($DOI_land{$pap_nr}{posterlink} ne "") {
				print DOITEST "posterlnk:   $DOI_land{$pap_nr}{posterlink}\n";
			}
			print DOITEST "Conference:  $conference_name, $conference_site_UTF\n"; 
			print DOITEST sprintf ("Proceedings: Link to full <a href=\"%s\" target=\"pdf\">%s Proceedings</a>\n", $conference_url, $conference_name);
			print DOITEST "Session:     $DOI_land{$pap_nr}{session}\n";
			print DOITEST "Date:        $DOI_land{$pap_nr}{date}\n";
			print DOITEST "Main:        $DOI_land{$pap_nr}{main}\n";
			if ( defined $DOI_land{$pap}{sub} && $DOI_land{$pap}{sub} ne ' ' ) {
				print DOITEST "Sub:         $DOI_land{$pap_nr}{sub}\n";
			}
			print DOITEST "Keywords:    $keywjoin{$paper_code[$pap_nr]}\n";
			print DOITEST "Publisher:   JACoW Publishing, Geneva, Switzerland\n";
			print DOITEST "Editors:     $DOI_land{editors}\n";
			print DOITEST "ISBN:        $conference_isbn\n";
			if ($series_issn ne "") {
				print DOITEST "ISSN:        $series_issn\n";
			}
			if ( defined $DOI_land{$pap}{sub} && $DOI_land{$pap}{sub} ne ' ' ) {
				print DOITEST "Sub:         $DOI_land{$pap_nr}{sub}\n";
			}
		
			print DOITEST "Published:   $pubmonth_alf $pubyear_nr\n";
			print DOITEST "Series:      $conference_series (".ordinal($conference_number).")\n";
			print DOITEST "Copyright:   $conference_pub_copyr\n";
		}
		#
		# export citations for ALL paper (number is "$pap_nr")
		#
		ExportCitations ($pap_nr);
	} # end loop over papers [$pap_nr]
	close (CITDB);
	close (REFDB);

	close (DOITEST);
	#
	# make the MDS suite Executable on Lunix
	#
	if ($os_platform_id == 0) {
		# BAT
		system ("chmod a=r+w+x $doicurl");
	}

	Deb_call_strucOut ();
	return $_;
}
#---------------------------------------------------------------------------------
#
#  generate DOI for the conference itself				=> jacow.org/<conference>
#         + DOI XML set for datacite.org				=> "$doixml_directory"
#         + DOI registration commands for "mdssuite"	=> ditto
#
#-----------------------------
sub DOI_conference_proceedings {
  	Deb_call_strucIn ("DOI_conference_proceedings");

#ß	my $doitest	= $protocol_directory."DOI-conference.txt";
#ß	open (DOITEST, ">:encoding(UTF-8)", $doitest) or die ("Cannot open '".$doitest."' -- $! (line ",__LINE__,")\n");
#
# DOI registration commands using "curl" (put registration cite in filename)
#
#ß	$DOI_site		=~ m|//(.*?)/|;
#ß	my $reg_cite	= $1;
#ß	$reg_cite		=~ s|\.|-|g;
#ß	print "Registration on $reg_cite => $DOI_site\n";

#ß	my $doicurl	= sprintf ("%sDOI-curl-conference-%s.bat", $doixml_directory, $reg_cite);
#ß	open (DOICURL, ">", $doicurl) or die ("Cannot open '".$doicurl."' -- $! (line ",__LINE__,")\n");
#
# open XML files with conference DOI metadata  "DOI-<$conference_name>"
#
	$DOI_xmlfile = sprintf ("%s/DOI-JACoW-%s.xml", $doixml_directory, $conference_name);
	open (DOIxml, ">:encoding(UTF-8)", $DOI_xmlfile) or die ("Cannot open '$DOI_xmlfile' -- $! (line ",__LINE__,")\n");
#
# DOI identifier
# mds: 1.
#		<resource xsi:schemaLocation="http://datacite.org/schema/kernel-4 http://schema.datacite.org/meta/kernel-4/metadata.xsd" 
#		<identifier identifierType="DOI">10.18429/JACoW-FEL2019</identifier>
# Creator: name / affiliation / ID
# mds: 2.1-2.3
	print DOIxml "<resource xsi:schemaLocation=\"http://datacite.org/schema/kernel-4 http://schema.datacite.org/meta/kernel-4/metadata.xsd\" ",
					"xmlns=\"http://datacite.org/schema/kernel-4\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">\n",
				 "<identifier identifierType=\"DOI\">10.18429/JACoW-$conference_name</identifier>\n",
				 "<creators>\n";
	print DOIxml "  <creator>\n";
	print DOIxml "    <creatorName>Schaa, Volker R.W.</creatorName>\n";
	print DOIxml "    <nameIdentifier schemeURI=\"https://orcid.org/\" nameIdentifierScheme=\"ORCID\">0000-0003-1866-8570</nameIdentifier>\n";
	print DOIxml "    <affiliation>GSI, Darmstadt, Germany</affiliation>\n";
	print DOIxml "  </creator>\n";
	print DOIxml "</creators>\n";
#
# Title
# mds: 3.
#
	print DOIxml sprintf	 ("<titles>\n  <title xml:lang=\"en-us\">Proceedings of the %s</title>\n</titles>\n", $conference_title);
#
# Publisher
# mds: 4.
#
	print DOIxml			  "<publisher>JACoW Publishing, Geneva, Switzerland </publisher>\n";
	#
	# Publication Year
	# mds: 5.
	#
		print DOIxml sprintf ("<publicationYear>%s</publicationYear>\n", $pubyear_nr);
	#
	# Subjects:  "Accelerator Physics<"
	#			 "Main Classification"
	#			 "Sub Classification"
	# mds: 6.
	#
	print DOIxml 			  "<subjects>\n",
							  "  <subject xml:lang=\"en-us\">Publication of proceedings of accelerator conferences held around the world.</subject>\n";
	print DOIxml 			  "</subjects>\n",
							  "<contributors>\n";
#
# Contributors: Editors
# mds: 7.1 - 7.4
#
	for (my $e_n = 0; $e_n <= $DOI_xml{num_editors}; $e_n++) {
		print DOIxml		  "  <contributor contributorType=\"Editor\">\n";
		print DOIxml sprintf ("    <contributorName>%s (Ed.)</contributorName>\n", $DOI_xml{editor}[$e_n]);
		#
		# get Id_scheme and number
		#
		my ($id_scheme, $id_num) = split (/:/, $DOI_xml{editor_id}[$e_n]);

		my $id_schurl = "https://www.jacow.org/";
		if ($id_scheme =~ m/ORCID/i) {
			$id_scheme = "ORCID";
			$id_schurl = "https://orcid.org/";
		} else {
			$id_num	= sprintf ("JACoW-%08d", $id_num);
		}
		print DOIxml sprintf ("    <nameIdentifier schemeURI=\"%s\" nameIdentifierScheme=\"%s\">%s</nameIdentifier>\n",
										$id_schurl, $id_scheme, $id_num);
		print DOIxml sprintf ("    <affiliation>%s</affiliation>\n", $DOI_xml{editor_af}[$e_n]);
		print DOIxml		  "  </contributor>\n";
	}
	print DOIxml 			  "</contributors>\n",
									  "<dates>\n";
#
# Dates
# mds: 8.
#
	print DOIxml sprintf	 ("  <date dateType=\"Created\">%s</date>\n", $data_generation_date);		# or "Issued"
	print DOIxml 			  "</dates>\n",
#
# Language + ResourceType
# mds: 9. + 10.
#
							  "<language>en-us</language>\n",
							  "<resourceType resourceTypeGeneral=\"Text\">ConferencePaper</resourceType>\n",
							  "<relatedIdentifiers>\n";
#
# relatedIdentifier: ISBN 
# mds: 12.1
#
	print DOIxml sprintf     ("  <relatedIdentifier relatedIdentifierType=\"ISBN\" relationType=\"IsPartOf\">%s</relatedIdentifier>\n", 
									$conference_isbn);
#
# relatedIdentifier: ISSN 
# mds: 12.1 (copied from ISBN)
#
	if ($series_issn ne "") {
		print DOIxml sprintf     ("  <relatedIdentifier relatedIdentifierType=\"ISSN\" relationType=\"IsPartOf\">%s</relatedIdentifier>\n", 
										$series_issn);
	}
#
# closing </relatedIdentifiers>
#
	print DOIxml 			  "</relatedIdentifiers>\n";
#
# Rights: CC-BY-3.0
# mds: 16.
#
	print DOIxml 			  "<rightsList>\n",
							  "  <rights rightsURI=\"https://creativecommons.org/licenses/by/3.0/\">CC 3.0</rights>\n",
							  "</rightsList>\n",
							  "<descriptions>\n";
#
# Destriptions: 
#				Type: Abstract
#				Type: SeriesInformation
# mds: 17.1
#
	print DOIxml			  "  <description xml:lang=\"en-us\" descriptionType=\"SeriesInformation\">\n";
	print DOIxml sprintf	 ("    Proceedings of the %s, %s, %s\n", $conference_title, $conference_name, $conference_site_UTF);
	print DOIxml 			  "  </description>\n",
							  "</descriptions>\n",
							  "</resource>\n";  
	close (DOIxml);
#-------------------------------------------------------------
#
#  generate the DOI registration commands (PERL)
#
	#
	# the DOI_xml-file is now in the XML directory below
	#
#??	$DOI_xmlfile = sprintf ("%s/DOI-JACoW-%s.xml", $doixml_directory, $conference_name});
	my $xmlfile = sprintf ("./DOI-JACoW-%s.xml", $conference_name);

	#
	# CURL parameters
	#    -d, --data DATA     HTTP POST data (H)
	#    -H, --header LINE   Pass custom header LINE to server (H)
	# 	 -k, --insecure      Allow connections to SSL sites without certs (H)
	#    -u, --user USER[:PASSWORD]  Server user and password (passed by $DOI_useraccount)
	#
	print DOICURL sprintf  ("\n$WL_Rem -------- Conference %s ---------\n", $conference_name);
	print DOICURL sprintf  ("curl --insecure --header Content-Type:application/xml --data-binary \@%s %s https://mds.datacite.org/metadata\n", 
							$xmlfile, $DOI_useraccount);
	# the jacow.org address/link has to be given WITHOUT "www." as datacite.org _____________v   throws an error "URL is not allowed by repository domain settings."
	print DOICURL sprintf  ("curl --insecure --data doi=10.18429/JACoW-%s --data url=https://jacow.org/%s/index\.html %s https://mds.datacite.org/doi\n", 
							$conference_name, $conference_name,  $DOI_useraccount);
	#>>
	# REM  -------- Conference  FEL2019 ---------
	# curl --insecure --header Content-Type:application/xml --data-binary @./DOI-JACoW-FEL2019.xml --user CERN.JACOW:<password> https://mds.datacite.org/metadata
	#----------------------------------------------------------------------v without "www." because datacite.org doesn't like it
	# curl --insecure --data doi=10.18429/JACoW-FEL2019 --data url=https://jacow.org/fel2019/index.html --user CERN.JACOW:<password>  https://mds.datacite.org/doi
	#>>

	Deb_call_strucOut ();
	return $_;
}
#-----------------------------------------------------------------------------------
#
# get ordinal of number 1st 2nd 3rd 4...th
#
#-----------------------------------------------------------------------------------
sub ordinal {
  return $_.(qw/th st nd rd/)[/(?<!1)([123])$/ ? $1 : 0] for int shift;
}
#-----------------------------------------------------------------------------------
#
#capitalize_title ($str,
#                  NOT_CAPITALIZED => \@exceptions,
#                  PRESERVE_ALLCAPS => 1,
#                  PRESERVE_ANYCAPS => 1);
# 
######
#
#  http://www.math.ntnu.no/~stacey/HowDidIDoThat/LaTeX/mathgrep.html
#
# RIS (Dateiformat) Ref
#
# \c{C} c,
#
# convert all ^{-} ^{-1} ^{*}
#             
#	Superscript Minus
#	U+207B &#8315; 
##
#	Superscript Plus Sign
#	U+207A &#8314; 
#
#-----------------------------------------------------------------------------------
# Highwire Press tags (e.g. https://scholar.google.com/intl/en-us/scholar/inclusion.html#indexing)
#                      and https://jira.duraspace.org/secure/attachment/13020/Invisible_institutional.pdf  
#
# https://scholar.google.com/intl/en/scholar/inclusion.html
#
# for usage of tags see Survey in http://www.monperrus.net/martin/accurate+bibliographic+metadata+and+google+scholar
#
# DOI is coded according to http://www.ukoln.ac.uk/metadata/dcmi-ieee/identifiers/
# see also http://ntl.bts.gov/dublincore/ntl_dc_table.html
#
#  title tag 
#		<citation_title> 
#				must contain the title of the paper. Don't use it for the title of the journal or a book in which the paper was published, 
#			  	or for the name of your repository. This tag is required for inclusion in Google Scholar.
#
#  author tag 
#		<citation_author> 
#				must contain the authors (and only the actual authors) of the paper. Don't use it for the author of the website or for 
#             	contributors other than authors, e.g., thesis advisors. Author names can be listed either as "Smith, John" or as "John Smith". Put each 
#			  	author name in a separate tag and omit all affiliations, degrees, certifications, etc., from this field. 
#			  	At least one author tag is required for inclusion in Google Scholar.
#
#  publication date tag 
#		<citation_publication_date> / <citation_date> (last not mentioned on Google Scholar page)
#				must contain the date of publication, i.e., the date that would normally be cited in references to this 
#			  	paper from other papers. Don't use it for the date of entry into the repository - that should go into citation_online_date instead. Provide 
#		      	full dates in the "2010/5/12" format if available; or a year alone otherwise. This tag is required for inclusion in Google Scholar.
#
#  For conference papers, provide the bibliographic citation data in the following tags: 
#
#	$DOI_xml{$pap}{author}[$k]		 1 citation_author 						DC.creator
#	$pubyear_nr/$pubmonth_alf		 2 citation_date 						DC.issued
#                                      citation_publication_date
#	$pubyear_nr						---										dcterms:issued (examples only show YEAR)
#	$DOI_land{$pap}{title}			 3 citation_title 						DC.title
#	$DOI_land{$pap}{titleXML}		 3 citation_title 						DC.title        with escaped HTML entities (&<>'")
#	"JACoW, Geneva, Switzerland"	 4 citation_publisher 					DC.publisher
#	---								 5 citation_journal_title 				DC.relation.ispartof
#	---								 6 citation_volume 						DC.citation.volume
#	---								 7 citation_issue 						DC.citation.issue
#	$DOI_land{$pap}{firstpage}		 8 citation_firstpage 					DC.citation.spage
#	$DOI_land{$pap}{lastpage}		 9 citation_lastpage 					DC.citation.epage
#	$DOI_land{$pap}{doi}			10 citation_doi							DC:identifier 	 => "info:doi/10.18429/xxx"
#																			DC:identifier  scheme="DCTERMS.URI" content="doi:10.18429/xxx"
#	(only some)						11 citation_issn 						dcterms:isPartOf => "urn:ISSN:-yyyy"
#	$conference_isbn				12 citation_isbn 						dcterms:isPartOf => "urn:ISBN:978-3-95450-xxx-x"
#																			DC:source  scheme="URI" content="urn:ISBN:978-3-95450-xxx-x"
#	series_issn						?? ???									DC:??
#	$keywords[$pap][$k]				13 citation_keywords 					DC.subject
#	---								14 citation_dissertation_institution 	DC.publisher
#	---								15 citation_dissertation_name			---
#	---								16 citation_technical_report_institution DC.publisher
#	---								17 citation_technical_report_number 	---
#	"en"							18 citation_language 					DC.language
#	$conference_title + 			19 citation_conference_title 			dcterms:bibliographicCitation
#	($conference_sh_name),	+
#	$conference_site, +
#	$conference_date
#	---								20 citation_inbook_title				---
#	$DOI_land{$pap}{paperlink}		21 citation_pdf_url 					DC.identifier
#	$DOI_land{$pap_nr}{filename}	22 citation_abstract_html_url			---
# 
#
#-----------------------------------------------------------------------------------
sub include_HighwirePress_DC_Tags {
	#
	# the call parameter is the FileHandler to write to
	#
	my $fh      = shift;
	my $papnr	= shift;
	my $citype	= shift;
  	Deb_call_strucIn ("include_HighwirePress_DC_Tags $papnr $citype");

	print $fh qq(<!DOCTYPE html>\n);
	print $fh qq(<html lang="en">\n);
	print $fh qq(<head>\n);
	print $fh qq(  <style>\n);
	print $fh qq(     div.relative {\n);
	print $fh qq(        position: relative;\n);
	print $fh qq(        left: 60px;\n);
	print $fh qq(        width: 500px;\n);
	print $fh qq(     }\n);      
	print $fh qq(  </style>\n);
	print $fh qq( <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />\n);
#	print $fh qq( <meta http-equiv="Content-Security-Policy" content="script-src 'self'" />\n);
	print $fh qq( <meta name="keywords" content="doi, conference, proceedings, JACoW" />\n);
	print $fh qq( <meta name="generator" content="copyright 2015-$actual_year vrws Generated by JPSP version $sc_version on $generation_date at $generation_time" />\n);
	print $fh qq( <meta name="generator" content="JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´" />\n);
	
	print $fh qq( <link rel="stylesheet" type="text/css" href="../html/expcit.css" />\n);
	print $fh qq( <link rel="shortcut icon" href="$favicon" />\n);
	print $fh qq( <link rel="icon" href="$favicon_ani" type="image/gif" />\n);
#	print $fh qq( <link rev="made" href="mailto:volker\@vrws.de" />\n);
	print $fh qq( <!--[if gt IE 8]>\n);
	print $fh qq(     <style type="text/css">div.restrictedflag {filter:none;}</style>\n);
	print $fh qq( <![endif]-->\n);
#
# if published, the following metadata will be embedded in the HTML file
#
	if (defined $DOI_xml{$papnr}{authcnt}) {
		HighwirePress_Tags ($fh, $papnr);
	}
	#
	# entry JACoW header
	#
	print $fh qq (<title>$citype - $paper_code[$papnr]</title>\n);
	print $fh qq (</head>\n<body>\n<a href="https://www.jacow.org"><img src="$jacow_hdr" width="480" height="60"); 
	print $fh qq ( alt="JACoW logo" /></a>\n<h1>Joint Accelerator Conferences Website</h1>\n);
	print $fh qq (<p class="intro">The Joint Accelerator Conferences Website (<a href="https://www.jacow.org">JACoW</a>) is an international collaboration that publishes the );
	print $fh qq (proceedings of accelerator conferences held around the world.</p>\n);
	print $fh qq (<hr /><div class="citexp">$citype citation export for <span class="tt">$paper_code[$papnr]</span>: <em>$DOI_land{$papnr}{title}</em></div><hr />\n);
	if ($citype ne "Text/Word") {
		print $fh qq (<pre>\n);
	}

	Deb_call_strucOut ();
	return;
}
#-----------------------------------------------------------------------------------
# HighwirePress tags
#
#-----------------------------------------------------------------------------------
sub HighwirePress_Tags {
	#
	# the call parameter is the FileHandler to write to
	#
	my $fh      = shift;
	my $papnr	= shift;

	print $fh qq( <meta name="citation_title" content="$DOI_land{$papnr}{title}" />\n);
	for (my $a_n = 0; $a_n <= $DOI_xml{$papnr}{authcnt}; $a_n++) {
		print $fh (" <meta name=\"citation_author\" content=\"$DOI_xml{$papnr}{author}[$a_n]\" />\n");
	}
	my $meta_cit_date = sprintf ("%s/%02i", $pubyear_nr, $pubmonth_nr);
	print $fh qq( <meta name="citation_date" content="$meta_cit_date" />\n);
	my $meta_cit_date2 = sprintf ("%s/%02i/01", $pubyear_nr, $pubmonth_nr);
	print $fh qq( <meta name="citation_publication_date" content="$meta_cit_date2" />\n);
	print $fh qq( <meta name="citation_publisher" content="JACOW Publishing, Geneva, Switzerland" />\n);
	print $fh qq( <meta name="citation_firstpage" content="$DOI_land{$papnr}{firstpage}" />\n);
	print $fh qq( <meta name="citation_lastpage" content="$DOI_land{$papnr}{lastpage}" />\n);
	print $fh qq( <meta name="citation_doi" content="$DOI_land{$papnr}{doi}" />\n);
	print $fh qq( <meta name="citation_isbn" content="$conference_isbn" />\n);
	if ($series_issn ne "") {
		print $fh qq( <meta name="citation_issn" content="$series_issn" />\n);
	}
	print $fh qq( <meta name="citation_keywords" content="$keywjoin{$paper_code[$papnr]}" />\n);
	print $fh qq( <meta name="citation_language" content="en" />\n);
	my $cit_conf_title = "$conference_title ($conference_sh_name), $conference_site_UTF, $conference_date";
	print $fh qq( <meta name="citation_conference_title" content="$cit_conf_title" />\n);
	print $fh qq( <meta name="citation_pdf_url" content="$DOI_land{$papnr}{paperlink}" />\n);
# 	print $fh qq( <meta name="citation_abstract_html_url" content="$DOI_land{$papnr}{filename}" />\n);
#
# DC tags
#
	for (my $a_n = 0; $a_n <= $DOI_xml{$papnr}{authcnt}; $a_n++) {
		print $fh (" <meta name=\"DC.creator\" content=\"$DOI_xml{$papnr}{author}[$a_n]\" />\n");
	}
	print $fh qq( <meta name="DC.issued" content="$meta_cit_date" />\n);
	print $fh qq( <meta name="dcterms:issued" content="$pubyear_nr" />\n);
	print $fh qq( <meta name="DC.title" content="$DOI_land{$papnr}{title}" />\n);
	print $fh qq( <meta name="DC.publisher" content="JACOW Publishing, Geneva, Switzerland" />\n);
	print $fh qq( <meta name="DC.citation.spage" content="$DOI_land{$papnr}{firstpage}" />\n);
	print $fh qq( <meta name="DC.citation.epage" content="$DOI_land{$papnr}{lastpage}" />\n);
	(my $DC_doi = $DOI_land{$papnr}{doi}) =~ s|DOI:||; # remove "DOI:"
	print $fh qq( <meta name="DC:identifier" content="info:doi/$DC_doi" />\n);
# DC:identifier  scheme="URI" content="doi:10.18429/xxx"
# 	print $fh qq( <meta name="DC:identifier" scheme="dcterms.URI" content="$DOI_land{$papnr}{doi}" />\n);
	if ($series_issn ne "") {
		print $fh qq( <meta name="dcterms:isPartOf" content="urn:ISSN:$series_issn" />\n);
	}
	print $fh qq( <meta name="dcterms:isPartOf" content="urn:ISBN:$conference_isbn" />\n);
# DC.Source scheme="URI" content="urn:isbn:1-56592-149-6"
# 	print $fh qq( <meta name="DC:source" scheme="dcterms.URI" content="urn:ISBN:$conference_isbn" />\n);
	print $fh qq( <meta name="DC.subject" content="$keywjoin{$paper_code[$papnr]}" />\n);
	print $fh qq( <meta name="citation_language" content="en" />\n);
	print $fh qq( <meta name="dcterms:bibliographicCitation" content="$cit_conf_title" />\n);
	print $fh qq( <meta name="DC.identifier" content="$DOI_land{$papnr}{paperlink}" />\n);

	return;
}
#-----------------------------------------------------------------------------------
#
# generate pages for Institutes showing DOIs and paper titles by people from this Institute
#
#-----------------------------------------------------------------------------------
sub sort_instDOI {
  	Deb_call_strucIn ("sort_instDOI");
#
# base html file for Institute-DOI list
#
 my $instDOIfile   = $html_directory."instdoi.htm";
 print DBG "== List of Institutes with DOIs\n";

 open (DHTM, ">:encoding(UTF-8)", $instDOIfile) or die ("Cannot open '$instDOIfile' -- $! (line ",__LINE__,")\n");
 print DHTM qq(<!DOCTYPE html>\n);
 print DHTM qq(<html lang="en">\n);
 print DHTM qq(<head>\n);
 print DHTM qq(  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />\n);
# print DHTM qq(  <meta http-equiv="Content-Security-Policy" content="script-src 'self'" />\n);
 print DHTM qq(  <link rel="stylesheet" type="text/css" href="confproc.css" />\n);
 print DHTM qq(  <link rel="shortcut icon" href="$favicon" />\n);
 print DHTM qq(  <link rel="icon" href="$favicon_ani" type="image/gif" />\n);
 print DHTM qq(  <meta name="keywords" content="conference, proceedings" />\n);
 print DHTM qq(  <meta name="generator" content="copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time" />\n);
 print DHTM qq(  <meta name="generator" content="JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´" />\n);
 print DHTM qq(  <meta name="author" content="volker rw schaa\@gsi de" />\n);
 print DHTM qq(  <title>List of DOIs for Institutes - $conference_name</title>\n);
 print DHTM qq(</head>\n\n);
 print DHTM qq(<frameset rows="$banner_height px, *">\n);
 print DHTM qq(  <frame src="b0nner.htm" name="b0nner" frameborder="1" />\n);
 print DHTM qq(  <frameset cols="20%,*">\n);
 print DHTM qq(    <frame src="instdoi1.htm" name="left"  frameborder="1" />\n);
 print DHTM qq(    <frame src="instdoi2.htm" name="right" frameborder="1" />\n);
 print DHTM qq(  </frameset>\n);
 print DHTM qq(  <noframes>\n);
 print DHTM qq(    <body class="debug">\n);
 print DHTM qq(    <p>This page uses frames, but your browser doesn't support them.</p>\n);
 print DHTM qq(    </body>\n);
 print DHTM qq(  </noframes>\n);
 print DHTM qq(</frameset>\n);
 print DHTM qq(</html>\n);
 close (DHTM);
 $instDOIfile   = $html_directory."instdoi2.htm";
 open (DHTM, ">:encoding(UTF-8)", $instDOIfile) or die ("Cannot open '$instDOIfile' -- $! (line ",__LINE__,")\n");
 print DHTM qq(<!DOCTYPE html>\n);
 print DHTM qq(<html lang="en">\n);
 print DHTM qq(<head>\n);
 print DHTM qq(  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />\n);
# print DHTM qq(  <meta http-equiv="Content-Security-Policy" content="script-src 'self'" />\n);
 print DHTM qq(  <link rel="stylesheet" type="text/css" href="confproc.css" />\n);
 print DHTM qq(  <link rel="shortcut icon" href="$favicon" />\n);
 print DHTM qq(  <link rel="icon" href="$favicon_ani" type="image/gif" />\n);
 print DHTM qq(  <meta name="keywords" content="conference, proceedings" />\n);
 print DHTM qq(  <meta name="generator" content="copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time" />\n);
 print DHTM qq(  <meta name="generator" content="JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´" />\n);
 print DHTM qq(  <meta name="author" content="volker rw schaa\@gsi de" />\n);
 print DHTM qq(  <title>List of DOIs for Institutes - $conference_name</title>\n);
 print DHTM qq(</head>\n\n);
 print DHTM qq(<body>\n);
 print DHTM qq(<br />\n);
 print DHTM qq(<span class="list-item">Click on an institute to display a list of DOI papers.</span>\n);
 print DHTM qq(</body>\n);
 print DHTM qq(</html>\n);
 close (DHTM);
 #
 # Institute's index file
 #
 $instDOIfile   = $html_directory."instdoi1.htm";
 open (DHTM, ">:encoding(UTF-8)", $instDOIfile) or die ("Cannot open '$instDOIfile' -- $! (line ",__LINE__,")\n");
 print DHTM qq(<!DOCTYPE html>\n);
 print DHTM qq(<html lang="en">\n);
 print DHTM qq(<head>\n);
 print DHTM qq(  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />\n);
# print DHTM qq(  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n);
 print DHTM qq(  <link rel="stylesheet" type="text/css" href="confproc.css" />\n);
 print DHTM qq(  <link rel="shortcut icon" href="$favicon" />\n);
 print DHTM qq(  <link rel="icon" href="$favicon_ani" type="image/gif" />\n);
 print DHTM qq(  <meta name="keywords" content="conference, proceedings" />\n);
 print DHTM qq(  <meta name="generator" content="copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time" />\n);
 print DHTM qq(  <meta name="generator" content="JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´" />\n);
 print DHTM qq(  <meta name="author" content="volker rw schaa\@gsi de" />\n);
 print DHTM qq(  <title>List of DOI per Institute - $conference_name</title>\n);
 print DHTM qq(</head>\n\n);
 print DHTM qq(<body class="debug">\n);
 print DHTM qq(<p class="list-title">DOIs of Institutes<p/>\n);

 use vars qw ($num_DOIinst $instDOI_file_open);
 #
 # print out of listed Institutes
 #
 open (DEBAUTH, ">>:encoding(UTF-8)", $debauthfile) or die ("Cannot open '$debauthfile' -- $! (line ",__LINE__,")\n");
 print DEBAUTH ("  nr  | Institute abb                                     | pap       |pap_nr|inst\n");
 #
 #
 my $last_instDOI	= "";
 my $last_paper		= -4711;
 my $instcnt		=     0;
 my $riscnt			=     0;
 for ($i=0; $i<=$author_max_nr; $i++) {
    ($ctr_abb, my $ctr_pap) = split (/∞/, $sorted_all_idx_inst[$i]);
	$ctr_abb =~ s/\s+$//;	# trim spaces on right due to sort formatting [%-40s]
	#
	# Virginia Polytechnic Institute and State University∞-A-∞-¡-∞Blacksburg, USA∞---∞112
	#   v                             v
	($act_abr, $act_auth, $auth8, $act_inst, $act_aid, $pap_num) = split (/∞/, $sorted_institutes[$i]);
	$act_abr =~ s/\s+$//;	# trim string extension for sorting
	
	print DBG " $i:soia:$sorted_all_idx_inst[$i]\n";
	print DBG " $i:soi :$sorted_institutes[$i]\n";
	#
	# increment institute pointer when Institute changes 
	#
	if ($act_abr ne $ctr_abb) { 
		$instcnt++;
	}
	#
	# if paper is not publishable, there is no DOI
	#
	if (!$paper_pub[$ctr_pap]) {
		next;
	}
	#
	# still the same institute?
	#
	if ($ctr_abb eq $last_instDOI) {
		#
		# print new institute to Debug log, if new paper
		#
		if ($ctr_pap ne $last_paper) {
			print DEBAUTH sprintf ("%5i | %-50s| %-9s | %4i |\n", $i, substr($ctr_abb, 0, 50), $paper_code[$ctr_pap], $ctr_pap);
		}
		#
		# new Institute
		#
	} else {
		#
		# close last institute (if open)
		#
		if ($instDOI_file_open) { 
			close_instituteDOI_htmlfile ();
        }
		$last_instDOI	= $ctr_abb;
		$last_paper		= -1;			# the same paper may appear for the next institute
		#
		# open new institute-DOI file
		#
		$inst2file = sprintf ("instdoi%04i.htm", $instcnt);
		$instcnt++;
		#
		# downloadable RIS file name entry "../export"
		#
		$ris2file	= "$export_directory".sprintf ("risdoi%04i.ris", $riscnt);
		$riscnt++;
		#
		# print new institute to Debug log
		#
		print DEBAUTH sprintf ("------+---------------------------------------------------+-----------+------+%4i\n", $instcnt);
		print DEBAUTH sprintf ("%5i | %-50s| %-9s | %4i |\n", $i, substr($ctr_abb, 0, 50), $paper_code[$ctr_pap], $ctr_pap);
		#
		# Virginia Polytechnic Institute and State University∞---∞---∞Blacksburg, USA∞---∞112
		#   v                             v
#		($act_abr, $act_auth, $auth8, $act_inst, $act_aid, $pap_num) = split (/∞/, $sorted_institutes[$i]);
#		$act_abr =~ s/\s+$//;	# trim string extension for sorting
		#
		#
		#
		if ($act_abr ne $ctr_abb) {
			print DBG " ##### should never happen $i => '$act_abr' <=> '$ctr_abb' <?> '$act_inst'\n";
		}
		#
		# special InDiCo case: Abbreviation == Institute's name
		#
		if ($act_abr eq $act_inst) {	# $act_abr = $act_inst = $ctr_abb
#			$abbinsthtml = convert_spec_chars ($act_abr, "act_abr");
			$abbinsthtml = convert_spec_chars ($ctr_abb, "act_abr");
		} else {
			$abbinsthtml = convert_spec_chars ("$ctr_abb<br />$act_inst", "act_abr-inst");
		}
		print DHTM "<p><a class=\"inst-item\" href=\"$inst2file\" target=\"right\">$abbinsthtml</a></p>\n";
		generate_instituteDOI_htmlfile ();
	}
	#
	# list paper with DOI and Title if not same
	#
	if ($ctr_pap eq $last_paper) {
		next;			# same paper means different author
	} else {
		$last_paper	= $ctr_pap;
		add_instituteDOI_entry ($ctr_pap);
	}
 }
#
# close last instDOI file
# for last institute which does not pass through the loop
# 
 if ($instDOI_file_open) {
	close_instituteDOI_htmlfile ();
	print DHTM	"</body>\n\n",
				"</html>\n";
	close (DHTM);
 }
 print DEBAUTH ("------+---------------------------------------------------+-----------+------+\n");
 close (DEBAUTH);

 return;
}
#-----------------------------------------------------------------------------------
#
# file showing all DOIs and papers of one institute
#
#-----------------------------------------------------------------------------------
sub generate_instituteDOI_htmlfile {

  Deb_call_strucIn ("generate_instituteDOI_htmlfile ($abbinsthtml)");

  open (D2HTM, ">:encoding(UTF-8)", $html_directory.$inst2file) or die ("Cannot open '$inst2file' -- $! (line ",__LINE__,")\n");
  open (RISSUM, ">:encoding(UTF-8)", $ris2file) or die ("Cannot open '$ris2file' -- $! (line ",__LINE__,")\n");
  $instDOI_file_open = 1;

  print DBG "## opening ## $inst2file ---  $act_abr ($act_inst) --- $act_auth\n";
  
  #
  # downloadable RIS file name entry
  #
  my $destfris = "<span class=\"sessdoiheader\"><a download href=\".$ris2file\">download RIS dataset for institute's DOIs</a></span>";
  #
  # special InDiCo case: Abbreviation == Institute's name
  #
  my $inst_header = convert_spec_chars ("$ctr_abb ($act_inst)", "inst_header");

  if ($act_abr eq $act_inst) {	# $act_abr = $act_inst = $ctr_abb
#	  $abbinsthtml = convert_spec_chars ($act_abr, "act_abr");
	  $abbinsthtml = convert_spec_chars ($ctr_abb, "act_abr");
	  $abbinsthtml .= "<br />$destfris";
  } else {
	  $abbinsthtml = convert_spec_chars ("$ctr_abb<br />$act_inst", "act_abr-inst");
	  $abbinsthtml =~ s|<br />|$destfris<br />|;
  }
  print D2HTM  $html_content_type."\n",
			   "<html lang=\"en\">\n",
			   "<head>\n",
			   "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#			   "  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
			   "  <link rel=\"stylesheet\" href=\"confproc.css\" />\n",
			   "  <link rel=\"shortcut icon\" href=\"$favicon\" />\n",
			   "  <link rel=\"icon\" href=\"$favicon_ani\" type=\"image/gif\" />\n",
			   "  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
			   "  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
			   "  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
			   "  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
			   "  <title>DOIs of Institute $inst_header - $conference_name</title>\n",
			   "</head>\n\n",
			   "<body>\n",
			   "<p style=\"text-align:left;\" class=\"sessionheader\">$abbinsthtml</p>\n",
#-----------------------
			   "<table  class=\"tabledef\">\n",
			   "    <tr class=\"tablerow\">\n",
			   "        <th class=\"papercodehead\">DOI</th>\n",
			   "        <th class=\"papertitlehead\">Title</th>\n",
			   "    </tr>\n";
	Deb_call_strucOut ();
	return;
}
#-----------------------
sub add_instituteDOI_entry {
 	Deb_call_strucIn ("add_instituteDOI_entry");
	
	my $pap_idx	=	shift;
	
	if ($prg_code[$pap_idx][$prg_code_p[$pap_idx]] ne $paper_code[$pap_idx]) {
		print DBG "DOI code: $prg_code[$pap_idx][$prg_code_p[$pap_idx]] prim:$paper_code[$pap_idx] \n";
		return;
	}
	my $DOI_str	= $DOI_prefix."/JACoW-".$conference_name."-".$prg_code[$pap_idx][$prg_code_p[$pap_idx]];	#$paper_code[$pap_idx];	# is already primary

	my $INSP_Tit	= UTF_convert_spec_chars ($title[$pap_idx], "pap-add-instDOI_title");

	print D2HTM "    <tr class=\"tablerow\">\n",
				"        <td><a class=\"papkey\" href=\"https://doi.org/$DOI_str\">$DOI_str</a>\n",
				"        </td>\n",
				"		 <td class=\"paptitle\">$INSP_Tit</td>\n",
				"    </tr>\n";
	#
	# append paper RIS file to RISSUM
	#
	my $RISfile = $protocol_directory.$prg_code[$pap_idx][$prg_code_p[$pap_idx]].".ris";
	open (RIS, "<:encoding(UTF-8)", $RISfile) or die ("Cannot open '".$RISfile."' -- $! (line ",__LINE__,")\n");
	while (<RIS>) {
		print RISSUM $_;
	}
	print RISSUM "\n";
	close (RIS);
	
	Deb_call_strucOut ();
	return;
}
#-----------------------
sub close_instituteDOI_htmlfile {
 	Deb_call_strucIn ("close_instituteDOI_htmlfile");

	print D2HTM	"</table>\n",
				"</body>\n\n",
				"</html>\n";
	close (D2HTM);
	close (RISSUM);
	$instDOI_file_open = 0;

    Deb_call_strucOut ();
	return;
}
#-----------------------------
#
# html file for temporary index.html
#
sub generate_index_basefile {
    my $baseindexfile = "index.html";
	if (-e $baseindexfile) {
		#
		# index.html already exists, do not overwrite
		#
		print "\n >>>>>>>>>>>> index.html  ::::NOT OVERWRITTEN::::\n\n"
	} else {
		Deb_call_strucIn ("generate_index_basefile");
		open (IXHTM, ">:encoding(UTF-8)", $baseindexfile) or die ("Cannot open '$baseindexfile' -- $! (line ",__LINE__,")\n");
		print IXHTM $html_content_type."\n",
					"<html lang=\"en\">\n",
					"<head>\n",
					"  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n",
#					"  <meta http-equiv=\"Content-Security-Policy\" content=\"script-src 'self'\" />\n",
					"  <link rel=\"stylesheet\" href=\"html/confproc.css\" />\n",
					"  <meta name=\"keywords\" content=\"conference, proceedings\" />\n",
					"  <meta name=\"generator\" content=\"copyright 2003-$actual_year Generated by JPSP version $sc_version on $generation_date at $generation_time\" />\n",
					"  <meta name=\"generator\" content=\"JPSP script name ª$jpsp_script´ modification date ª$jpsp_script_date´\" />\n",
					"  <meta name=\"author\" content=\"volker rw schaa\@gsi de\" />\n",
					"  <title>$conference_name - temporary Index</title>\n",
					"</head>\n\n",
					"<frameset rows=\"",$banner_height,"px, *\">\n",
					"  <frame src=\"html/b0nner.htm\" name=\"b0nner\" frameborder=\"1\" />\n",
					"  <frameset cols=\"20%,*\">\n",
					"    <frame src=\"html/sessi0n1.htm\" name=\"left\"  frameborder=\"1\" />\n",
					"    <frame src=\"html/sessi0n2.htm\" name=\"right\" frameborder=\"1\" />\n",
					"  </frameset>\n",
					"  <noframes>\n",
					"    <body class=\"debug\">\n",
					"    <p>This page uses frames, but your browser doesn't support them.</p>\n",
					"    </body>\n",
					"  </noframes>\n",
					"</frameset>\n",
					"</html>\n";
		close (IXHTM);
		Deb_call_strucOut ();
	}
	return;
}
####
#-----------------------------
#
# a bit of gymnasics with month of conference and short name of conference
#       date ranges are only accepted in ISO 8601 format
#		"startdate/enddate" with start-/enddate in the format "YYYY-MM-DD"
#		with the separator "/"
#
sub conference_month_name {

	if ($conference_date !~ m|/|) {
		croak "\n==> no valid ISO8601 date range (\"/\" missing between start date and end date)\n";
	}
	my ($fromdate, $todate) = split (/\//, $conference_date);
	
	if ($fromdate !~ /(\d{4})-(\d\d)-(\d\d)/) {
		croak "\n==> Bad date string provided for start date: $fromdate (should be e.g. \"2034-04-29\n";
	}
	my ($styear, $stmonth, $stday) = ($1, $2, $3);

	if ($todate !~ /(\d{4})-(\d\d)-(\d\d)/) {
		croak "\n==> Bad date string provided for start date: $todate (should be e.g. \"2034-05-03\n";
	}
	my ($edyear, $edmonth, $edday) = ($1, $2, $3);

	if ($edmonth < $stmonth || $styear ne $edyear) {
		croak "\n==> Bad dates provided: end year != start year or end month < start month";
	}
#
# date formally correct
# conference date in format
#                       long                  short
#       one month		10-16 June 2014       Jun 2014
#		two months		29 April-04 May 2014  Apr-May 2014
#
#
	if ($styear eq $edyear) {
		# same year
		if ($stmonth eq $edmonth) {
			# same month
#			$conf_month_abbr = substr($monthab[$edmonth-1], 0, 3)." $edyear";
			$conf_month_abbr = "$monthab[$edmonth-1] $edyear";
			$conference_date = "$stday-$edday $month[$edmonth-1] $edyear"
		} else {
			# diff months
#			$conf_month_abbr = substr($monthab[$stmonth-1], 0, 3)."-".substr($monthab[$edmonth-1], 0, 3)." $edyear";
			$conf_month_abbr = "$monthab[$stmonth-1]-$monthab[$edmonth-1] $edyear";
			$conference_date = "$stday $month[$stmonth-1]-$edday $month[$edmonth-1] $edyear"
		}
	} else {
		croak "\n==> Bad dates provided: JACoW does not feature conferences around the turn of the year\n";
	}
	print " Conference date: $conference_date\n",
		  " Conf date abbr : $conf_month_abbr\n";
#
# conference short name (IBIC2015) => (IBIC'15)
#
	($conference_sh_name = $conference_name) =~ s/20/'/;

	return;
}
#---------------------------------------------------------------------
#
# Receive/Publication date
#
# Received date from SPMS: <22-Mar-2019 13:09:42>
#               in DOI     <22 March 2019>
#-----------------------------------
sub PubDate {
	my $pbdate = shift;
	my ($stday, $stmonth, $styear) = split (/-/, substr ($pbdate, 0, 11));
	$i=0;
    while ($stmonth ne substr($month[$i], 0, 3)) { $i++; }
	$pbdate = sprintf ("%02d %s %4s", $stday, $month[$i], $styear);
	return $pbdate;
}
#---------------------------------------------------------------------
#
# CTAN/support/bibtexperllibs/LaTeX-ToUnicode/lib/LaTeX/ToUnicode/
#
#-----------------------------------
#
# find the correct session for the papercode argument and 
#		return the lowercase session name
#	reason for this procedure: 
#		in some conferences, the papercodes are not
#		consisting of session_abbr + sequence number, 
#		but have addition characteristics as Invited/Contributed/etc.
#		E.g. NA-PAC had session "WEA1" and papers "WEA1IO01" or "WEA1CO04"
#			
sub find_lc_session {

	my $prg_code = shift;
	my $j;
	my $sessabbr;
	for ($j = 0; $j <= $session_nr; $j++) {
		$sessabbr	= $session_abbr[$j];
		if ($sessabbr eq substr ($prg_code, 0, length ($sessabbr))) {
			last;
		} 
	}
	return lc $sessabbr;
}
#-----------------------------------
#
# correct config file?
# 		find mayor and minor version id and check whether it fits
#  
sub check_config_version {
	my $vs_config_maj;
	my $vs_config_min;
	# 
	# standard internal version string should look 
	# like "v=xx.y= dd mmm aaaa ????"
	# only the part between "=" is relevant (xx.y)
	#
	(my $a1, my $vs_script, my $a3) = split (/=/, $sc_version);
	(my $vs_script_maj, my $vs_script_min) = split (/\./, $vs_script);
	if (defined $version_script_bt) {
		($vs_config_maj, $vs_config_min) = split (/\./, $version_script_bt);
	} else {
		croak "\n==> config file version not defined!\n==> Please specify!\n";
	}
	if ($version_script_bt ne $vs_script) {
#		print "\nscr>$vs_script -- cfg>$version_script_bt\n";
#		print "\nscr-major>$vs_script_maj -- cfg-major>$vs_config_maj\n";
#		print "\nscr-minor>$vs_script_min -- cfg-minor>$vs_config_min\n";
		if ($vs_config_maj ne $vs_script_maj) {
			#
			# Major version id mismatch
			#
			if ($vs_config_maj gt $vs_script_maj) {
				# problem: newer script version requested than used
				croak "\n#>>\n#>> your config file requests a newer major scripts version ($version_script_bt) than used ($vs_script)\n#>>\n";
			} else {
				# problem: warn user that config's major version id is lower than scripts' id
				croak "\n#>>\n#>> your config file is asking for an older major scripts version ($version_script_bt) than used ($vs_script)\n#>>\n";
			}
		} else {
			#
			# minor version id mismatch
			#
			if ($vs_config_min gt $vs_script_min) {
				# warning: newer script version requested than used
				carp "\n#>>\n#>> your config file requests a newer minor scripts version ($version_script_bt) than used ($vs_script)\n#>>\n";
			} else {
				# warning: warn user that config's minor version id is lower than scripts' id
				carp "\n#>>\n#>> your config file is asking for an older minor scripts version ($version_script_bt) than used ($vs_script)\n#>>\n";
			}
		}
	}
	return;
}
#-----------------------------------
#
# NoMat
# 	are there paper and/or slides, or does the author provide nothing for publication?
#  
sub NoMat {
	#
	# InActive for now (until problems with oral/poster detection [$sess] is solved)
	#
	return;
	#
	# if Mark is not set => return
	#
	if ($no_material_mark) {
		return;
	}
	#
	# the call parameter is the FileHandle to write to, Paper nr and Session Name
	#
	my $fhnm	= shift;	# FileHandle to write to
	my $cpap	= shift;	# current paper_nr
	my $csess	= shift;	# current session
	
  	Deb_call_strucIn ("NoMat $pap");

	if ($session_type[$csess] =~ m/Oral/i) {
		if ($paper_with_pdf[$cpap] or $slides[$cpap]) {
			# at least one piece to publish
			print "pri: $paper_with_pdf[$cpap] ## $slides[$cpap]\n";
		} else {
			print "pri: $paper_code[$cpap] NIX\n";
			my $nomastr	= $no_material_text;
			if ($authors[$cpap] eq 0) {
				$nomastr	=~ s|s | |;
			}
			print $fhnm "    <tr class=\"tablerow\">\n",
						"        <td>&nbsp;</td>\n",
						"        <td class=\"nomat\">$nomastr</td>\n",
						"        <td>&nbsp;</td>\n",
						"    </tr>\n";			
		}
	}
	Deb_call_strucOut ();
	return;
}
#-------------------------------------------------
#
# find full script name and last modification date (for print out in HTML headers)
#
sub JPSP_Script_ND {
	use Time::localtime;
	$jpsp_script = dirname($0)."\\".basename($0);
	$jpsp_script =~ s|\\|/|g;

	$jpsp_script_date = ctime(stat($jpsp_script)->mtime);
	return;
}
#-------------------------------------------------
#
# Frantic: this is just a very frantic try to correct the XML names (at the last possible moment)
#
sub Frantic {
	my $con_8_o	= shift;
	my $con_8_c	= convert_spec_chars ($con_8_o, "Frantic");
	
	my $con_corr	= $con_8_c;
	if ($con_8_o ne $con_8_c && $con_8_c =~ m|&#|) {
		$con_corr 	= $con_8_o;
	#	print DBG "?> DOI_XML $pap: o:$con_8_o >=< c:$con_8_c\n";
	}
	return $con_corr;
}
#-------------------------------------------------
#
# check a talk PDF for videos
#
sub check_video_in_talk {

	my $file = shift;
	my $pdffiletext;
	{
		local undef $/;
		if (open (PDF, "<", $file)) {
#			print "pdf file opened\n";
		} else {
			print "pdf Cannot open '$file' -- $! (line ",__LINE__,")\n";
    }
    binmode (PDF);
    $pdffiletext = <PDF>;
    close (PDF);
 }
 #
 # remove stream content
 #
 $pdffiletext =~ s/stream.+?endstream/--/msg;
 my $num_videos = () = $pdffiletext =~ /\/video/g;
# print "### Anzahl videos: $num_videos\n";
 
 return $num_videos;
}
 