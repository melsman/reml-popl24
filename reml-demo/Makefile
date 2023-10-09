FLAGS=-no_basislib --maximum_inline_size 0 -no_opt
ROOT=~/gits/mlkit
REML ?= $(ROOT)/bin/reml $(FLAGS)
KITTESTER = $(ROOT)/bin/kittester

REMLSOURCES=er*.sml param.sml rec.sml tup.sml call.sml call2.sml ty1.sml err_expty1.sml err_expty2.sml \
  err_expty3.sml err_patty1.sml err_funty1.sml err_funty2.sml err_funty3.sml expty1.sml expty2.sml \
  nomut-err.sml nomut-ok.sml nomut2-err.sml disputs.sml disputs2.sml par.sml par-no.sml par-no2.sml

.PHONY: all
all:
	$(KITTESTER) "SML_LIB=$(ROOT) $(REML)" --logdirect all.tst

all.sml: $(REMLSOURCES)
	echo '(* Testfiles *)' > $@
	for x in $(REMLSOURCES) ; do \
          echo "\n(*** $$x: ***)" >> $@; \
          cat $$x >> $@; \
        done

.PHONY: test
test: all

.PHONY: clean
clean:
	rm -rf *~ *.log test_report.html MLB KITversion TESTmessages *.out runexe all.sml
