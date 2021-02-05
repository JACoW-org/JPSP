 use strict;
  
 use vars qw ($i $j $file @satz $satz @saetze $act_letter $lst_letter @name_prt $name_prt);

 $file = "Participants List - ECRIS10.txt";
 open (CSV, "<$file") or die "error opening '$file' ($!)\n";
 open (VS, ">$file-txt") or die "error opening '$file-txt' ($!)\n";
 open (VST, ">participants.tex") or die "error opening 'participants.tex' ($!)\n";
# open (CTR, ">countries.txt") or die "error opening 'countries.txt' ($!)\n";
#
# Title;Name;First name;Institute;E-mail;
#      ;Thomas;Sieber;MPI-K;Heidelberg;Germany#
# Fields           n# f# char contents 
#
#  Title                 0      Mr
#  First                 1      Mickael
#  Last                  2      Dubois
#  Inst-Abb              3      GANIL
#  Address               4      Bd Henri Becquerel
#  ZIP-Code              5      14076
#  City                  6      Caen
#  Country               7      France
#  Phone                 8      231454538
#  Email                 9      dubois@ganil.fr
#  special              10      * = columnbreak
#
# Title;First name;Surname;Affiliation;Address;ZIP code;City;Country;Phone;Email
# Mr;Mickael;Dubois;GANIL;Bd HENRI BECQUEREL;14076;Caen;France;231454538;DUBOIS@GANIL.FR
#
## Adli;Erik;University Oslo;Norway
## Nielsen;Jørgen;Aarhus University;ISA;Aarhus;Denmark
##
## \addcontentsline{toc}{subsubsection}{--- A ---}
## \subsubsection*{--- A ---}
## 
## \begin{trivlist}
## \item[]
##   Finn \textbf{Abildskov} (IFA)\newline
##   \href{mailto:fa@phys.au.dk}{\nolinkurl{fa@phys.au.dk}}\newline
##   Denmark\newline
## \end{trivlist}


 $i = -1;
 $act_letter = " ";
 $lst_letter = "";
 while (<CSV>) {
     $i++;
     chomp;
#     s/"//g;
     s/&/\\&/g;
#     s/_/\\_/g;
     convert_spec_chars2TeX ($_);
     @satz = split (/;/);
     $saetze[$i] = $satz;
     for ($j=0; $j<=$#satz; $j++) {
         my $sl = length($satz[$j]);
         print VS sprintf (" %3i:%2i%1s[%2i] %s\n", $i,$j, $sl > 31 ? "*":" ", $sl, $satz[$j]);
     }
     print VS "\n";


#>     @name_prt = split (/ /, $satz[2]);
#>     if ($#name_prt) {
#>        $act_letter = uc (substr ($name_prt[2], 0, 1));
#>     } else {
#>        $act_letter = uc (substr ($name_prt[1], 0, 1));
#>     }

     $act_letter = uc (substr ($satz[2], 0, 1));
     if ($act_letter ne $lst_letter) {
         print VST "\\refstepcounter{subsubsection}\n",
                   "\\addcontentsline{toc}{subsubsection}{--- $act_letter ---}\n",
                   "\\subsubsection*{--- $act_letter ---}\n\n";
         $lst_letter = $act_letter;         
     }

     print VST "\\begin{trivlist}\n\\item[]\n";
     print VST "  \\textbf{$satz[2]}, $satz[1]\\hfill\\newline\n";
     print VST "  $satz[3]\\hfill\\newline\n";
#     print VST "  \\href{mailto:$satz[4]}{\\nolinkurl{$satz[4]}}\\newline\n";
     print VST "  $satz[6], $satz[7]\\hfill\\newline\n";
#     print VST "  $satz[4]\\newline\n";

     print VST "\\end{trivlist}\n";
     
     if ($satz[6]) {
        if ($satz[6] =~ m/\*/) {
             print VST "\n\\vfill\\columnbreak\n";
        }
        if ($satz[6] =~ m/\+/) {
             print VST "\n\\vspace*{13mm}\n";
        }
     }

     print VST "\n";
 }
 close (VS);
 close (CSV);
# close (CTR);

exit;
#
# 
#

sub convert_spec_chars2TeX {
    $_    = $_[0];   # was @_[0]
 my $wohe = $_[1];
    if ($_ eq "") {
        return;
    }
 my $utf_switch = $_[2];
    #
    # if no argument for utf-8 is given, switch it to off (ISO-8859)
    #
    if (!defined $utf_switch) {
        $utf_switch = 0;
    }
#    print " call convert_spec_chars2TeX ($wohe) $utf_switch\n";

#
# utf-8 2/3 byte character sequences
#
 if ($utf_switch) {  #------------------------------- utf-8 -------------------------------
#    print " ####################################################################################> uft8\n";
    print DBG " s=> UTF-8 $_\n";
    s|\x95|\xc2\xb7|g;             #<Â·|·>  => \cdot (instead of 'b7' used '95')
    s|\xa1|\xc2\xa1|g;             #<test>
    s|\xa2|\xc2\xa2|g;             #<test>
    s|\xa3|\xc2\xa3|g;             #<test>
    s|\xa4|\xc2\xa4|g;             #<test>
    s|\xa5|\xc2\xa5|g;             #<test>
    s|\xa6|\xc2\xa6|g;             #<test>
    s|\xa7|\xc2\xa7|g;             #<test>
    s|\xa8|\xc2\xa8|g;             #<test>
    s|\xa9|\xc2\xa9|g;             #<Â©|©>
    s|\xaa|\xc2\xaa|g;             #<test>
    s|\xab|\xc2\xab|g;             #<test>
    s|\xac|\xc2\xac|g;             #<Â¬|¬>
    s|\xad|\xc2\xad|g;             #<test>
    s|\xae|\xc2\xae|g;             #<Â®|®>
    s|\xaf|\xc2\xaf|g;             #<test>
    s|\xb0|\\high{o}|g;            #<Â°|°>
    s|\xb1|\xc2\xb1|g;             #<Â±|±>
#    s|\xb5|\xc2\xb5|g;             #<Âµ|µ>
    s|\xb7|\xc2\xb7|g;             #<Â·|·>
    s|\xb8|\xc2\xb8|g;             #<Â¸|¸>
#    s|\xba|\xc2\xba|g;             #<Âº|º>
#?  s|\xbb|\xc2\xbb|g;             #<Â
    s|\xc1|\xc3\x81|g;             #<test 16.08.10>
    s|\xc2\xba|\\high{o}|g;        #<Âº|º>
#    s|\xbd|\xc2\xbd|g;             #<Â½|½>
#see HTML part   s|\xbf|\xc2\xbf|g;             #<Â¿|¿>
    s|\xc2\xbf|'|g;                #<Â¿|¿>
    s|¿|'|g;                       # don't know why it isn't the inverted questionmark but in text it's used as "'" (04.08.10)
    s|\xc9|\xc3\x89|g;             #<Ã‰|É>²
    s|\xd6|\\oeh|g;                #<Ã–|Ö>
    s|Ö|\\oeh|g;                   #<Ã–|Ö>
    s|\xd7|\xc3\x97|g;             #<Ã—|×>
    s|\xd8|\xc3\x98|g;             #Ø
    s|\xd9|\xc3\x99|g;             #<test>
    s|\xda|\xc3\x9a|g;             #<test>
    s|\xdb|\xc3\x9b|g;             #<test>
    s|\xdc|\xc3\x9c|g;             #<test>
    s|\xde|\xc3\x9e|g;             #<test>
    s|\xdf|\xc3\x9f|g;             #<ÃŸ|ß>
    s|\xe0|\xc3\xa0|g;             #<Ã |à>
    s|\xe2|\xc3\xa2|g;             #<Ã¢|â>
    s|\xe4|\xc3\xa4|g;             #<Ã¤|ä>
    s|\xe8|\xc3\xa8|g;             #<Ã¨|è>
    s|\xe9|\xc3\xa9|g;             #<Ã©|é>
    s|\xea|\xc3\xaa|g;             #<test>
    s|\xeb|\xc3\xab|g;             #<Ã«|ë>
    s|\xec|\xc3\xac|g;             #<test>
    s|\xed|\xc3\xad|g;             #<test>
    s|\xee|\xc3\xae|g;             #<test>
    s|\xef|\xc3\xaf|g;
    s|\xf0|\xc3\xb0|g;             #<test>
    s|\xf1|\xc3\xb1|g;             #<Ã³|ñ>
    s|\xf2|\xc3\xb2|g;             #<Ã²|ò>
    s|\xf3|\xc3\xb3|g;             #<Ã³|ó>²
    s|\xf4|\xc3\xb4|g;             #<test>
    s|\xf5|\xc3\xb5|g;             #<test>
    s|\xf6|\xc3\xb6|g;             #<Ã¶|ö>
    s|\xf7|\xc3\xb7|g;             #<test>
    s|\xf8|\xc3\xb8|g;             #ø
    s|\xf9|\xc3\xb9|g;             #<test>
    s|\xfa|\xc3\xba|g;             #<Ãº|ú>
    s|\xfb|\xc3\xbb|g;             #<test>
    s|\xfc|\xc3\xbc|g;             #<Ã¼|ü>
    s|\xfd|\xc3\xbd|g;             #<test>
    s|\xfe|\xc3\xbe|g;             #<test>
    s|\xff|\xc3\xbf|g;             #<test>
    print DBG " e=> UTF-8 $_\n";
 } else {  #------------------------------- iso-8859 -------------------------------
    print DBG " s=> LATIN $_\n";
    s|\xc2\xa0| |g;                #<Â | >
    s|\xc2\xa9|\xa9|g;             #<Â©|©>
    s|\xc2\xac|\xac|g;             #<Â¬|¬>
    s|\xc2\xae|\xae|g;             #<Â®|®>
    s|\xc2\xb0|\xb0|g;             #<Â°|°>
    s|\xc2\xb1|\xb1|g;             #<Â±|±>
    s|\xc2\xb3|\$\\ge\$|g;         #<Â³|>= > --> \ge
    s|\xc2\xb5|\xb5|g;             #<Âµ|µ>
#   s|\xc2\xb7|\xb7|g;             #<Â·|·>
    s|\xc2\xb7|\x95|g;             #<Â·|·>  => \cdot (instead of 'b7' used '95')
    s|\xc2\xb8|\xb8|g;             #<Â¸|¸>
    s|\xc2\xba|\xba|g;             #<Âº|º>
    s|\xc2\xbd|\xbd|g;             #<Â½|½>
    s|\xc2\xbf|\xbf|g;             #<Â¿|¿>
    s|¿|'|g;
    s|\xc3\x83|\\`{a}|g;           #<Ã…|  `a  >
    s|\xc3\x85|{\\AA}|g;           #<Ã…| Aring>
    s|\xc3\x89|\xc9|g;             #<Ã‰|É>
    s|\xc3\x96|\xd6|g;             #<Ã–|Ö>
    s|\xc3\x97|\xd7|g;             #<Ã—|×>
    s|\xc3\x98|{\\O}|g;            #<Ã—|{\O}>
    s|\xc3\x9f|\xdf|g;             #<ÃŸ|ß>
    s|\xc3\xa0|\xe0|g;             #<Ã |à>
    s|\xc3\xa2|\^{a}|g;            #<Ã¢|â>
    s|\xc3\xa4|\xe4|g;             #<Ã¤|ä>
    s|\xc3\xa8|\xe8|g;             #<Ã¨|è>
    s|\xc3\xa9|\xe9|g;             #<Ã©|é>
    s|\xc3\xab|\xeb|g;             #<Ã«|ë>
    s|\xc3\xad|\xed|g;             #<Ã­|í>
    s|\xc3\xb1|\xf1|g;             #<Ã³|ñ>
    s|\xc3\xb2|\\.{o}|g;           #<Ã²|ò>
    s|\xc3\xb3|\xf3|g;             #<Ã³|ó>
    s|\xc3\xb6|\xf6|g;             #<Ã¶|ö>
    s|\xc3\xb8|{\\o}|g;            #<Ã¸|Ø klein>
    s|\xc3\xbc|\xfc|g;             #<Ã¼|ü>
    s|\x{0107}|\\'{c}|g;           #<Ä‡|\'{C}>
    s|\x{010c}|\\v{C}|g;           #<ÄŒ|\v{C}>
    s|\x{010d}|\\v{c}|g;           #<Ä|\v{c}>
    s|\xc5\x99|\\v{r}|g;           #<Å™|\v{r}>
    s|\x{0142}|{\\l}|g;            #<Å,|{\l}>
    s|\x{0144}|\\'{n}|g;           #<Å,|\'{n}>
    s|\x{0159}|\\v{r}|g;           #<Å™|\v{r}>
    s|\x{0161}|\\v{s}|g;           #<Å¡|\v{s}>
    s|\x{017c}|\\.{z}|g;           #<Å¼|\.{z}>
    s|\xce\xb2|\$\\beta\$|g;       #<Î²|?>  -> 3b2 -> \beta
    s|\xce\xb3|\$\\gamma\$|g;      #<Î¼|?>  -> 3b3 -> \gamma
    s|\xce\xbb|\$\\lambda\$|g;     #<Î¼|?>  -> 3bb -> \lambda
    s|\xce\xbc|\$\\mu\$|g;         #<Î¼|?>  -> 3bc -> \mu
    s|\xcf\x80|\$\\pi\$|g;         #<Ï€|?>  -> 3c0 -> \pi
    s|\xe2\x80\x93|\x96|g;         #<â€“|–>
    s|\xe2\x80\x94|\x97|g;         #<â€”|—>
    s|\xe2\x80\x98|\x91|g;         #<â€˜|‘>
    s|\xe2\x80\x99|\x92|g;         #<â€™|’>
    s|\xe2\x80\x9c|\x93|g;         #<â€œ|“>
    s|\xe2\x80\x9d|\x94|g;         #<â€|”>
    s|\xe2\x80\xa0|\x86|g;         #<â€ |†>
    s|\xe2\x80\xa2|\x95|g;         #<â€¢|•>
    s|\xe2\x80\xa6|\\ldots|g;      #<â€¢|...>   "…" U+2026 HORIZONTAL ELLIPSIS
    s|\xe2\x85\xa1|II|g;           #<â…¡|II>    Roman II
    s|\xe2\x88\xbc|\$\\simeq\$|g;  #<âˆ¼|\simeq>  -> 213c -> DOUBLE-STRUCK SMALL PI => \pi ~~~> \simeq
    s|\xe2\x89\x88|\$\\approx\$|g; #<â‰¥|>=>      -> .approx.
    s|\xe2\x89\xa5|\$\\ge\$|g;     #<â‰¥|>=>      -> .ge.
    s|\xef\x80\xa0|&nbsp;|g;       #<ï€ | >
    s|\xef\x81\xad|\$\\mu\$|g;     #<ï­|µ>    -> f06d        -> private use area => µ, \mu
    s|\xef\x81\xb0|\$\\pi\$|g;     #<ï°|\pi>
    s|\xef\x82\xb3|\$\\ge\$|g;     #<ï‚³|>= >  -> f083(61571) -> private use area => \ge
#   s|\xef\x83\x97|\xb7|g;         #<ïƒ—|·>    -> f0d7(61655) -> private use area => \cdot
    s|\xef\x83\x97|\x95|g;         #<ïƒ—|·>    -> f0d7(61655) -> private use area => \cdot (instead of 'b7' used '95')
#
# utf-8 1 byte characters
#
    s|\xb4|\x92|g;              #<´| >
    s|&#xd8;|ø|g;
    s|&#xe0;|à|g;
    s|&#xe8;|è|g;
    s|&#xe9;|é|g;
    s|&#xed;|í|g;
    s|&#xf3;|ó|g;
    s|&#xfc;|ü|g;
    s|&#x3bc;|µ|g;
    print DBG " e=> LATIN $_\n";
 } #------------------------------- both utf-8/iso-8859 -------------------------------
    s|&#x2013;|&#8211;|g;
    s|&#x2014;|---|g;
#--
    s|&#8254;|\\high{-}|g;  # U+203E OVERLINE
    s|&#9472;|--|g;         # U+2500 BOX DRAWINGS LIGHT HORIZONTAL
    s|&#65288;| (|g;        # U+FF08 FULLWIDTH LEFT PARENTHESIS
    s|&#65289;|) |g;        # U+FF09 FULLWIDTH RIGHT PARENTHESIS
    s|&#65292;|, |g;        # U+FF0C FULLWIDTH COMMA
    s|&#65294;|. |g;        # U+FF0E FULLWIDTH FULL STOP
#
# translation list for HTML4 to TeX
#
    s|&#150;|--|g;          # "en dash"
    s|&#8211;|--|g;         # "en dash"
    s|&#8722;|--|g;         # "en dash"
    s|—|--|g;               # "en dash"
    s|–|--|g;               # "en dash"/divis
    s|&ndash;|--|g;         # "en dash" TeX
    s|&#151;|---|g;         # "em dash"
    s|&mdash;|---|g;        # "em dash" 0xE28094-UTF-8 => 0x2014-UTF16
    s|&sim;|\$\\sim\$|g;    #
##
    s|‘|`|g;
    s|`|`|g;
    s|&#145;|`|g;
    s|&lsquo;|`|g;          # "left single quotation mark"         (<= &#145;)
    s|&#8216;|`|g;          # "left single quotation mark"         (<= &#145;)
    s|&#x2018;|`|g;         # "left single quotation mark"         (<= &#145;)
    s|&#8217;|'|g;          # "right single quotation mark"        (<= &#146;)
    s|&#x2019;|'|g;         # "right single quotation mark"        (<= &#146;)
    s|&#146;|'|g;
    s|’|'|g;
    s|&#713;|\\high{-}|g;   # unicode ^-
    s|&rsquo;|'|g;          # "right single quotation mark"        (<= &#147;)
    s|&#x201C;|``|g;        # “ left to right (66) "left double quotation mark"         (<= &#147;)
    s|&#8220;|``|g;         # “ left to right (66) "left double quotation mark"         (<= &#147;)
    s|&#147;|``|g;          # “ left to right
    s|“|``|g;               # “ left to right
    s|&ldquo;|``|g;         # “ left to right (66) "left double quotation mark"         (<= &#147;)
    s|&#x201D;|''|g;        # ” right to left (99) "right double quotation mark"        (<= &#148;)
    s|&#8221;|''|g;         # ” right to left (99) "right double quotation mark"        (<= &#148;)
    s|&#148;|''|g;          # ” right to left
    s|”|''|g;               # ” right to left
    s|&rdquo;|''|g;         # ” right to left (99) "right double quotation mark"        (<= &#148;)
    s|&#x2026;|\\ldots|g;
    s|&hellip;|\\ldots|g;   # ... "horizontal ellipsis"                                 (<= "...")
    s|…|{\\ldots}|g;      # "…" U+2026 HORIZONTAL ELLIPSIS                            (<= "...")
    s|&trade;|\\high{TM}|g; # "trade mark sign"                                         (<= &#153;)
    s|&#153;|\\high{TM}|g;  # trademark symbol
    s|™|\\high{TM}|g;       # trademark symbol
    s|&#8208;|\\,-\\,|g;    # hyphen surrounded space
    s|&#8209;|-|g;          # hyphen or endash?
    s|&#8451;|°C|g;         # degrees Celsius as unit
#
#
#
    s| &amp; | \\& |g;     # LaTeX's escaped &
    s|A&amp;M|A\\&M|g;     # without this line we either get a "A\& " or "A\&\M "
                           # depending on the sequence of the statement with "s/;/;\\\\/g;"
    s|R&amp;D|R\\&D|g;
    s|&quot;|"|g;
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
        print DBG " --g---c_s_c2T ($wohe)> $countdolares *** $_\n";
    }
#<<<< 16.04.2009
#
# some specialities discovered in GSI's PNP conference
#
# 30.07.10 .*? changed to .+? like in HTML part
#s    if (m|\{(.+?)(10)(.+?)\}|) {
#s        s|\{(.+?)(10)(.+?)\}|\{$1$ZeHn$3\}|g;
#s    }
    s|†|\\textdagger|g;    # LaTeX's dagger
    s|\\noindent||g;
    s|\{\\bfseries (.*?)\}|\{\\bf $1\}|g;
    s|\\bf{(.*?)\}|{\\bf $1}|g;
#    s|\{\\bf (.*?)\}|
#    s|\{\\rm (.*?)\}|
#    s|\{\\it (.*?)\}|
    s|\\textbf\{(.*?)\}|{\\bf $1}|g;
    s|\\textit\{(.*?)\}|{\\it $1}|g;
    s|\\textsl\{(.*?)\}|{\\sl $1}|g;
    s|\\func{(.*?)\}|{\\sl $1}|g;
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
    s|¡©|-|g;
    s|&lt;pi&gt;|\$\\pi\$|g; #<pi> isn't always what it should be
    s|&lt;|\$<\$|g;
    s|&le;|\$\\le\$|g;
    s|&#263;|\\'{c}|g;
    s|&#268;|\\v{C}|g;
    s|&#269;|\\v{c}|g;
    s|&#281;|\\.{e}|g;        # e-dot above
    s|&#322;|{\\l}|g;         # polish l-slash
    s|&#324;|\\'{n}|g;        # n-acute
    s|&#350;|\\c{S}|g;
    s|&#351;|\\c{S}|g;
    s|&#352;|\\v{S}|g;
    s|&#353;|\\v{s}|g;
    s|&#378;|\\'{z}|g;        # z-acute
    s|&#380;|\\.{z}|g;        # z-dot above
    if (m|[^\.]~|) {
        s|~|\$\\sim\$|g;
    }
    s|&#61472;|~|g;
    s|•|\$\\cdot\$|g;
    s|([^\$])\\pi([^\$])|$1\$\\pi\$$2|g;         #all pi without $\pi$ will get $s       # corr: 090810 \$
    s|([^\$])\\omega([^\$])|$1\$\\omega\$$2|g;   #all omega without $\omega$ will get $s # corr: 090810 \$
    s|&#61552;|\$\\pi\$|g;
    s|&#61538;|\$\\beta\$|g;
    s|&#61620;|\$\\times\$|g;
    s|&#61617;|?|g;     # unknown glyph U+F0B1 private user area
    s|×|\$\\times\$|g;
    s|%|\\%|g;                    # escape "%"
    s|\\\\%|\\%|g;                # unescape escaped "%"
    s|&gt;|\$>\$|g;
    s|&#8709;|\$\\diameter\$|g;   # same as \emptyset  (#0216,#0248)
    s|&#934;|\$\\Phi\$|g;         # speciality when in title line in LaTeX
    s|&#1040;|A|g;                # cyrillic "A"
    s|&#1052;|M|g;                # cyrillic "M"
    s|&#1057;|C|g;                # cyrillic "C"
    s|&#1060;|\$\\Phi\$|g;        # new in ICALEPCS'09
    s|&#1088;|p|g;                 # cyrillic "p" (er)
    s|&#8364;|\\euro|ig;          # Euro
#
# the standard
#
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
    s|&#12288;| |g;         # U+3000 IDEOGRAPHIC SPACE
    s|&#12289;|,|g;         # U+3001 IDEOGRAPHIC COMMA
    s|&#916;|\$\\Delta\$|g;
    s|&#945;|\$\\alpha\$|g; # \$ introduced (090518)
#    s|\\beta|\$\\beta\$|g;
    s|([^\$])\\beta([^\$])|$1\$\\beta\$$2|g;         # corr: 090810 \$
#    s|\\nu|\$\\nu\$|g;
    s|([^\$])\\nu([^\$])|$1\$\\nu\$$2|g;             # corr: 090810 \$
#?    s|<beta>|\$\\beta\$|g;
#    s|&#946;([ =&])|\$\\beta\$$1|g;
    s|&#946;|\$\\beta\$|g;
    s|&#947;|\$\\gamma\$|g;
    s|&#948;|\$\\delta\$|g;
    s|&#949;|\$\\epsilon\$|g;
    s|&#949;|\$\\varepsilon\$|g;
    s|&#950;|\$\\zeta\$|g;
    s|&#951;|\$\\eta\$|g;
    s|&#952;|\$\\theta\$|g;
    s|&#977;|\$\\vartheta\$|g;
    s|&#953;|\$\\iota\$|g;
    s|&#954;|\$\\kappa\$|g;
#    s|\\lambda|\$\\lambda\$|g;
    s|([^\$])\\lambda([^\$])|$1\$\\lambda\$$2|g;     # corr: 090810 \$
    s|&#955;|\$\\lambda\$|g;
    s|&#13234;|\$\\mu\$s|g;
    s|&#61472;|~|g;
    s|&#64256;|ff|g;        # ff-ligature
    s|&#64257;|fi|g;        # fi-ligature
    s|&#64258;|fl|g;        # fl-ligature
    s|&#64259;|ffi|g;       # ffi-ligature
    s|&mu;|\$\\mu\$|ig;
    s|&#8545;|II|g;         # funny II sign for PLS-II
    s|&#8206;||g;           # Left to right mark
    s|||g;                 #don't know what this is
    s||fi|g;               # looks like a fi-ligature
    s|µ|\$\\mu\$|g;
#
    s|&#730;|\\high{o}|g;      # degree sign
    s|&deg;|\\high{o}|ig;
    s|&amp;deg;|\\high{o}|ig;
    s|°|\\high{o}|g;         # degree / number sign??
    s|½|\$\\frac{1}{2}\$|g;
    s|&#176;|\\high{o}|g;    # degree / number sign??
    s|&lt;br&gt;|\\newline|g;
    s/ micro[-| |]ampere[s]{0,1}/  \$\\mu\$A/ig;
    s| micro |\$\\mu\$|ig;
    s|&mu;|\$\\mu\$|ig;
    s|&amp;mu;|\$\\mu\$|ig;
    s/([\d| ])micro[-| |]A /$1&\$\\mu\$A /ig;
    s| microsec\b| \$\\mu\$s|ig;
    s| usec\b| \$\\mu\$s|ig;
    s|\\micro|\$\\mu\$|ig;
    s|&#956;|\$\\mu\$|g;
    s|&#61548;|\$\\bullet\$|g;
    s|&#61549;|\$\\mu\$|g;
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
    s|&#8710;|\$\\Delta\$|g;
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
    s|([^\$])\\Ohm([^\$])|$1\$\\Ohm\$$2|g;         # corr: 090810 \$
#    s|\\Ohm|\$\\Omega\$|ig;
    s|([^\$])\\Mho([^\$])|$1\$\\Mho\$$2|g;         # corr: 090810 \$
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
    s|&#8729;|\$\\cdot\$|g;   # \cdot
    s|&#183;|\$\\cdot\$|g;
    s|&#903;|\$\\cdot\$|g;
    s|&#8230;|\$\\ldots\$|g;
    s|&#8943;|\$\\cdots\$|g;
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
    s|&#8776;|\$\\sim\$|g;
    s|&#8773;|\$\\cong\$|g;
    s|&#8800;|\$\\neq\$|g;
    s|&#8733;|\$\\propto\$|g;
#  plus/minus see below "^+}-" substitution
    s|&#61620;|\$\\times\$|g;
    s|&#61627;| =???= |g;
    s|×|\\times|g;
    s|&times;|\$\\times\$|g;
    s|&#247;|\$\\div\$|g;
    s|&#8727;|\$\\ast\$|g;
#    s|&#8727;|\$\\star\$|g;
#30.07.10    s|º|\$\\textdegree\$|g;           # degree sign >30.07. conversion removed due to utf-8 chars
    s|&#61616|\$\\degree\$|g;     # degree sign
    s|&#8226;|\$\\bullet\$|g;
#    s|&#183;|\$\\cdot\$|g;
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
    if (m/[\^_]\{.+?\}/ig) {
#<<< 16.04.2009        s|\$?\^\{(.*?)\}\$?|\\high{$1}|g;
#<<< 16.04.2009        s|\$?_\{(.*?)\}\$?|\\low{$1}|g;
        s|\^\{(.+?)\}|\\high\{$1\}|g;
        s|_\{(.+?)\}|\\low\{$1\}|g;
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
        if (m/\^(-?\d?)/g) {
            s|\^(-?\d?)|\\high\{$1\}|g;
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
            if ($1) { print DBG "# --($wohe)> [1T] »$1« $_\n"; }
        }
    }
#
# notation 1e13/1e-13 (special case)
#
    if (m/1e([+-]{0,1}\d+?)/ig) {
        if ($1) {
            s#1e([+-]{0,1}\d+?)#10\\high\{$1\}#ig;
            if ($1) { print DBG "# --($wohe)> [1-T] »$1« $_\n"; }
        }
    }
#
# 6.45E9
#
    if (m/([ 0-9]{1,}?)E([+-]{0,1}\d{1,2})([ .,\/-])/ig) {
        if ($2) {
#21.07.10   s|(\d*?)E([+-]{0,1}\d{1,2})([ .,\/-])|$1\$\\cdot\$10\\high{$2}$3|ig;
            s|([ 0-9]{1,}?)E([+-]{0,1}\d{1,2})([ .,\/-])|$1\$\\cdot\$10\\high\{$2\}$3|ig;
            if ($1) { print DBG "# --($wohe)> [2T] »$1« »$2« »$3« $_\n"; }
        }
    }
#
# notation 10-13   (should be corrected in the abstract!)
#                   do not convert ZIP codes and something like X-104
#                                                but still 101.28 MHz
#21.07.10 added check for zero power
#
#30.07.10 if (m|([^0-9])10([+-]{0,1}\d{1,2})([ .,\/-])|g) {
#s    if (m|([^0-9])10([+-]{0,1}\d{1,2})([ \/-])|g) {
#s        if ($1) {
#s            if ($2 ne "0" && $2 ne "00") {
#30.07.10       s|([^0-9])10([+-]{0,1}\d{1,2})([ .,\/-])|$1$ZeHn\\high\{$2\}$3|g;
#s                s|([^0-9])10([+-]{0,1}\d{1,2})([ \/-])|$1$ZeHn\\high\{$2\}$3|g;
#s            }
#s        }
#s    }
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
# highlighting __x__
#
    s|__(.*?)__|\{\\bf $1\}|g;
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
# some other elements (H+ / H- / e- / e+ / D+)
#
    s|e\+e-|e\\high{+}e\\high{-}|g;
    if (m/([a-zA-Z]{1,2})e- /) {
        # don't do anything (it might be something like "one- or two-fold")
    } else {
        s|e- |e\\high{-} |g;
    }
    s|e\+ |e\\high{+} |g;
    s|H\+|H\\high{+}|g;
    s|H\^\+|H\\high{+}|g;
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
#***    s|(\w),([A-Z]{1})|$1,\,$2|g;   #***
    s|([\w]{3,})\.([A-Z]{1})|$1.~$2|g;      # wrong quantity for an abstract
    s|([\w]{3,}),([A-Z]{1})|$1,\,$2|g;
#
# different order, otherwise U73+-ions will be wrong with a "±" after U73
#
#    s|±|\$\\pm\$|g;
    s|\+/\-|\$\\pm\$|g;
    s|\+\-|\$\\pm\$|g;
    s|&#177;|\$\\pm\$|g;
#
# diacritical letters (and others)
#
   s|&Acirc;|Â|g;
   s|&acirc;|â|g;
   s|&Atilde;|Ã|g;
   s|&atilde;|ã|g;
   s|&AElig;|Æ|g;
   s|&aelig;|æ|g;
   s|&Aacute;|Á|g;
   s|&aacute;|á|g;
   s|&Aring;|Å|g;
   s|Å|{\\AA}|g;         # Ã=Aring Package inputenc Error: Unicode char \u 8:ÅI not set up for use with LaTeX
   s|&aring;|å|g;
   s|&Agrave;|À|g;
   s|&agrave;|à|g;
   s|&Auml;|Ä|g;
   s|&auml;|ä|g;
#
   s|&Ccedil;|Ç|g;
   s|&ccedil;|ç|g;
#
   s|&Ecirc;|Ê|g;
   s|&ecirc;|ê|g;
   s|&ETH;|Ð|g;
   s|&eth;|ð|g;
   s|&Egrave;|È|g;
   s|&egrave;|è|g;
   s|&Eacute;|É|g;
   s|&eacute;|é|g;
   s|&Euml;|Ë|g;
   s|&euml;|ë|g;
#
   s|&Icirc;|Î|g;
   s|&icirc;|î|g;
   s|&Iacute;|Í|g;
   s|&iacute;|í|g;
   s|&Iuml;|Ï|g;
   s|&iuml;|ï|g;
   s|&Igrave;|Ì|g;
   s|&igrave;|ì|g;
#
   s|&Ntilde;|Ñ|g;
   s|&ntilde;|ñ|g;
#ò
   s|&Ograve;|Ò|g;
   s|&ograve;|ò**|g;
   s|&Ouml;|Ö|g;
   s|&ouml;|ö|g;
   s|&Ocirc;|Ô|g;
   s|&ocirc;|ô|g;
   s|&Otilde;|Õ|g;
   s|&otilde;|õ|g;
   s|&Oacute;|Ó|g;
   s|&oacute;|ó|g;
   s|&Oslash;|Ø|g;
   s|&oslash;|ø*|g;
#
   s|&szlig;|ß|g;
#
   s|&THORN;|Þ|g;
   s|&thorn;|þ|g;
#
   s|&Uacute;|Ú|g;
   s|&uacute;|ú|g;
   s|&Ucirc;|Û|g;
   s|&ucirc;|û|g;
   s|&Uuml;|Ü|g;
   s|&uuml;|ü|g;
   s|&Ugrave;|Ù|g;
   s|&ugrave;|ù|g;
#
   s|&Yacute;|Ý|g;
   s|&yacute;|ý|g;
   s|&yuml;|ÿ|g;
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
#
   s|"|{"}|g;
   s|&quot;|{"}|g;
#
# should be extended
#
   s| fuer | f\\"{u}r |g;
   s| f\. | f\\"{u}r |g;                  # abbreviation "f." for "für"
   s/DA[F|PH]NE/DA\$\\mathrm{\\Phi}\$NE/g;
   s|&#x0141;&#x00f3;d&#x017a;|{\\L}\\'{o}d\\'{z}|g;        # for my Polish friends!
   s|Lodz|{\\L}\\'{o}d\\'{z}|g;           # for my Polish friends!
   s|Poznan|Pozna\acute{n}|g;             # for my Polish friends!
   s|Juelich|J\\"{u}lich|g;
   s|akultaet|akult\\"{a}t|g;
   s|versitaet|versit\\"{a}t|g;
   s|m.b.H.|mbH|g;
   s|Rez|\\v{R}e\\v{z}|g;                 # for my Czech friends!
   s|Jyvaskyla|Jyväskylä|g;
#    s/micro([-| |]{0,1})sec\b/\$\mu\$$1{}s/ig;
   s|\\EUR|\\euro|ig;
   s|\.\.\.|\$\\ldots\$|ig;
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
# help ConTeXt hyphenate (but not --, ---, {-}, or $-$
#
#s    if ($context_switch) {
#s        if (m#--|\{-|\$-\$#g) {
#s           # nada
#s        } else {
#s            if (m#\w[/-]\w#) {
#s                s#([/-])#|$1|#g;
#s            }
#s        }
#s    }
#
# ???????????????????  help ConTeXt hyphenate (but not --, ---, {-}, or $-$
#
#s    if ($abslatex_switch) {
#s        if (m#--|\{-|\$-\$#g) {
#s            # nada
#s        } else {
#s            if (m#\w[/-]\w#) {
#s                s#([/-])#|$1|#g;
#s            }
#s        }
#s    }
#
# get rid of some not used edit marks
#
##    s|\[\+||g;
##    s|\+\]||g;
    s|÷|/|g;
##    s|{(.*?)}|$1|g;
#21.07.10 ??    s|-ZeHn-|10|g;
#30.07.    s|{(.+?)($ZeHn)(.+?)}|$1ZeHn$3|g;
#s    s|(.+?)($ZeHn)(.+?)|$1ZeHn$3|g;
#s    s|(.+?)($ZeHn)(.+?)|$1ZeHn$3|g;
#s    s|ZeHn|10|g;
    s|&nbsp;| |g; #***> " "
#
# some utf-8 encodings destroyed by single byte corrections
#
    if ($utf_switch) {  #------------------------------- utf-8 -------------------------------
       s|\\oeh|\xc3\x96|g;        #<Ã–|Ö>
       s|Ö|\xc3\x96|g;            #<Ã–|Ö>
    }

    return $_;
}
