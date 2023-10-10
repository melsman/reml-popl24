FLAGS ?=
REML ?= reml $(FLAGS)

.PHONY: all
all: pmsort.res pmsort.exe

%.exe: %.mlb %.sml
	$(REML) -o $@ $<

%.out: %.exe
	@(./$< > $@ 2>&1; echo "done" >> /dev/null)

%.res: %.out
	@(diff -aq $< $*.out.ok > /dev/null 2>&1; \
         if [ $$? -eq 0 ]; then \
             echo "Test $*: OK" > $@ \
         ; else \
             if [ -e $*.out.ok ]; then \
                echo "Test $*: *** ERR: file $< differs from $*.out.ok ***" > $@ \
             ; else \
                echo "Test $*: *** ERR: file $*.out.ok does not exist ***" > $@ \
             ; fi \
         ; fi)
	@cat $@
	@cat $@ >> complog.txt

.PHONY: clean
clean:
	rm -rf MLB ../util/MLB *.exe *~ *.res *.out complog.txt
