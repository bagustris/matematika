TEXS := $(wildcard bab*_*.tex)
PDFS := $(patsubst %.tex,docs/%.pdf,$(TEXS))

.PHONY: all clean clean-pdf

all: $(PDFS)

docs:
	mkdir -p docs

docs/%.pdf: %.tex | docs
	pdflatex -interaction=nonstopmode -halt-on-error -output-directory=docs $<
	pdflatex -interaction=nonstopmode -halt-on-error -output-directory=docs $<
	@rm -f docs/$*.aux docs/$*.log docs/$*.nav docs/$*.out docs/$*.snm docs/$*.toc docs/$*.vrb

clean:
	@rm -f *.aux *.log *.nav *.out *.snm *.toc *.vrb
	@rm -f docs/*.aux docs/*.log docs/*.nav docs/*.out docs/*.snm docs/*.toc docs/*.vrb

clean-pdf:
	@rm -f docs/bab*_*.pdf
