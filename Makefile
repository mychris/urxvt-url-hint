SHELL := /bin/sh

GIT_REV_COUNT != git rev-list --count HEAD 2>/dev/null || echo '0'
GIT_REV_SHORT != git rev-parse --short HEAD 2>/dev/null || echo '0000'
GIT_VERSION := r$(GIT_REV_COUNT).$(GIT_REV_SHORT)
GIT_DATE != git log -1 --format='%as' 2>/dev/null || date '+%Y-%m-%d'

all: check README.pod urxvt-url-hint.1.gz

# Always create a new README.pod file and change the real one only
# if there are changes.
# Ensures that README.pod is re-created if there was an error during
# its creation before and that it is not touched if there is nothing to change.
README.pod: README.pod.bak
	test -f $@ && diff -u $@ $< | patch -s || cp $< $@
	rm -f $<

README.pod.bak: url-hint
	podselect $< | sed -e :a -e '/^\n*$$/{$$d;N;ba' -e '}' >$@

# URxvt itself installs the man pages for the core extensions in section 1
# with a page header of RXVT-UNICODE (see man 1 urxvt-matcher)
urxvt-url-hint.1: url-hint
	pod2man --utf8 --section=1 --quotes=\" --name=urxvt-url-hint \
	        --date=$(GIT_DATE) --release=$(GIT_VERSION) \
	        --center=RXVT-UNICODE $< $@

urxvt-url-hint.1.gz: urxvt-url-hint.1
	gzip -c $< >$@

tidy: url-hint
	perltidy -b $<

check: url-hint
	perlcritic --quiet --harsh --verbose 8 $<
	perltidy -st -se -ast $< >/dev/null

clean:
	rm -f urxvt-url-hint.1 urxvt-url-hint.1.gz

dist-clean: clean
	rm -f *.bak *.tdy

install:
	@echo 'No generic installation provided.'
	@echo 'To install into the users HOME directory, run `make install-home`.'

install-home: url-hint urxvt-url-hint.1.gz
	install -m 644 -Dt "$$HOME/.urxvt/ext/" url-hint
	install -m 644 -Dt "$$HOME/.local/share/man/man1/" urxvt-url-hint.1.gz

.PHONY: all tidy check clean dist-clean install install-home

