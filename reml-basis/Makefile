
FLAGS ?=

REML = reml

# Add "-Peffects -print_constraints -Ptypes -Pcee" to see the
# resulting region-annotated internal representation

# Add "-debug_constraint_solving" to see information about the
# constraint solving process...

.PHONY: all
all: test

.PHONY: test
test:
	SML_LIB=$(ROOT) $(REML) $(FLAGS) -c par-reml.mlb

.PHONY: clean
clean:
	rm -rf *~ MLB run
