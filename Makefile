version := 3.7.8
version_stamp := version_$(version).stamp

CCACHE_REPO := ../ccache

empy_files += $(filter-out footer.empy header.empy, $(wildcard *.empy))

generated += $(empy_files:.empy=.html)
generated += license.html
generated += manual/latest.html
generated += releasenotes.html

ccache_github_base = https://raw.githubusercontent.com/ccache/ccache/v$(version)

ASCIIDOC := asciidoc

.PHONY: all
all: $(generated)

$(version_stamp):
	touch $@

.INTERMEDIATE: authors.adoc
authors.adoc: $(version_stamp)
	git -C $(CCACHE_REPO) show v$(version):doc/AUTHORS.adoc >$@

.INTERMEDIATE: license.adoc
license.adoc: $(version_stamp)
	git -C $(CCACHE_REPO) show v$(version):LICENSE.adoc >$@

.INTERMEDIATE: manual/$(version).adoc
manual/$(version).adoc: $(version_stamp)
	git -C $(CCACHE_REPO) show v$(version):doc/MANUAL.adoc >$@

.INTERMEDIATE: releasenotes.adoc
releasenotes.adoc: $(version_stamp)
	git -C $(CCACHE_REPO) show v$(version):doc/NEWS.adoc >$@

manual/latest.html: manual/$(version).html
	ln -sf $(version).html $@

credits.html: authors.adoc extra-credits.txt
documentation.html: manual/$(version).html
index.html news.html: news.yaml

%.html: %.empy header.empy footer.empy $(version_stamp)
	empy $< >$@.tmp
	sed -e 's/^ *//' -e 's/ *$$//' -e '/^$$/d' $@.tmp >$@
	rm $@.tmp

%.html: %.adoc
	$(ASCIIDOC) -a revnumber=$(version) -a toc -b xhtml11 -o $@ $<

.PHONY: clean
clean:
	rm -rf $(generated) *~ *.stamp
