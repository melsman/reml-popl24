FLAGS=-no_basislib -no_opt
REML ?= reml $(FLAGS)
KITTESTER = kittester

REMLSOURCES=er*.sml param.sml rec.sml tup.sml call.sml call2.sml ty1.sml err_expty1.sml err_expty2.sml \
  err_expty3.sml err_patty1.sml err_funty1.sml err_funty2.sml err_funty3.sml expty1.sml expty2.sml \
  nomut-err.sml nomut-ok.sml nomut2-err.sml disputs.sml disputs2.sml par.sml par-no.sml par-no2.sml

.PHONY: all
all: test tests.sml
	$(MAKE) -C pmsort all
	$(MAKE) -C slmsort all
	$(MAKE) -C ray all
	$(MAKE) -C mandelbrot all

.PHONY: test
test:
	$(KITTESTER) "$(REML)" --logdirect all.tst

tests.sml: $(REMLSOURCES)
	echo '(* Testfiles *)' > $@
	for x in $(REMLSOURCES) ; do \
          echo "\n(*** SOURCE $$x ***)" >> $@; \
          cat -n $$x >> $@; \
          if [ -a $$x.out.ok ]; then \
             echo "\n(*** COMPILE SUCCESS - EXECUTION OUTPUT ***)" >> $@; \
             cat $$x.out.ok | sed 's/^/     /' >> $@; \
          fi; \
          if [ -a $$x.log.ok ]; then \
             echo "\n(*** COMPILE FAILURE - COMPILER OUTPUT ***)" >> $@; \
             cat $$x.log.ok | sed 's/^/     /' | grep -v 'Stopping compilation' >> $@; \
          fi; \
        done

.PHONY: clean
clean:
	rm -rf *~ *.log test_report.html MLB KITversion TESTmessages *.out runexe tests.sml all.sml
	$(MAKE) -C pmsort clean
	$(MAKE) -C slmsort clean
	$(MAKE) -C ray clean
	$(MAKE) -C mandelbrot clean
