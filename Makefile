EMACS ?= emacs

PKG       =  llvm-mode.el
LOAD_PATH ?= 
LOAD_PATH += -L .
BATCH     =  $(EMACS) -Q -batch $(LOAD_PATH)

README.md: el2markdown.el ${PKG}
	$(BATCH) -l $< $(PKG) -f el2markdown-write-readme
	$(RM) $@~

.INTERMEDIATE: el2markdown.el
el2markdown.el:
	wget \
  -q -O $@ "https://github.com/Lindydancer/el2markdown/raw/master/el2markdown.el"

.PHONY: clean distclean
clean:
	$(RM) *~

distclean: clean
	$(RM) *autoloads.el *loaddefs.el TAGS *.elc
