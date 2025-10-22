all: $(:%=%.pdf)
		pdflatex bab*.tex
#%.pdf: %.tex
#		pdflatex $(@%.pdf=%.tex)
#		pdflatex $(@%.pdf=%.tex)
		rm -f *.aux *.log *.nav *.out *.snm *.vrb
clean:
		rm -f *.aux *.log *.nav *.out *.snm *.toc *.vrb #*.pdf
