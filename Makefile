version := 4.7
version_stamp := version_$(version).stamp

CCACHE_REPO ?= ../ccache
EMPY ?= empy3

empy_files += $(filter-out footer.empy header.empy, $(wildcard *.empy))

generated += $(empy_files:.empy=.html)
generated += howto/http-storage.html
generated += howto/redis-storage.html
generated += license.html
generated += manual/latest.html
generated += releasenotes.html

ccache_github_base = https://raw.githubusercontent.com/ccache/ccache/v$(version)

.PHONY: all
all: $(generated)

$(version_stamp):
	touch $@

gendocs/%/stamp:
	rm -rf gendocs/$*
	mkdir -p gendocs/$*
	git clone -b v$(version) $(CCACHE_REPO) gendocs/$*/ccache
	mkdir gendocs/$*/ccache/build
	cmake -S gendocs/$*/ccache -B gendocs/$*/ccache/build
	cmake --build gendocs/$*/ccache/build -- doc-html
	cp gendocs/$*/ccache/build/doc/*.html gendocs/$*
	cp $(CCACHE_REPO)/doc/AUTHORS.adoc gendocs/$*
	rm -rf gendocs/$*/ccache
	touch $@

license.html: gendocs/$(version)/stamp
	cp gendocs/$(version)/LICENSE.html $@

manual/$(version).html: gendocs/$(version)/stamp
	cp gendocs/$(version)/MANUAL.html $@

releasenotes.html: gendocs/$(version)/stamp
	cp gendocs/$(version)/NEWS.html $@

manual/latest.html: manual/$(version).html
	ln -sf $(version).html $@

credits.html: gendocs/$(version)/stamp extra-credits.txt
documentation.html: manual/$(version).html
index.html news.html: news.yaml

%.html: %.empy header.empy footer.empy $(version_stamp)
	$(EMPY) -D 'version = "$(version)"' $< >$@.tmp
	sed -e 's/^ *//' -e 's/ *$$//' -e '/^$$/d' $@.tmp >$@
	rm $@.tmp

.PHONY: clean
clean:
	rm -rf $(generated) *~ *.stamp gendocs

.PHONY: serve
serve:
	python3 -m http.server -b localhost
