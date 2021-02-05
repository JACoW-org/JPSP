pdftk mo*pdf cat output out-mo.pdf
pdftk tu*.pdf cat output out-tu.pdf
pdftk we*.pdf cat output out-we.pdf
pdftk th*.pdf cat output out-th.pdf
pdftk fr*.pdf cat output out-fr.pdf
pdftk out-*.pdf cat output proc-out.pdf
qpdf --linearize proc-out.pdf proc-out-lin.pdf
del out-*.pdf
del proc-out.pdf
move /Y proc-out-lin.pdf proc-all.pdf
