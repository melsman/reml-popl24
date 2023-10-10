# Artifact for the paper *Explicit Effects and Effect Constraints in ReML* submitted to POPL 2024

## Getting Started

The artifact comprises a Docker image `reml-popl24.tar.gz`.
Depending on your system, `docker` commands might or might not need to
be prefixed with `sudo`.  In the following we will leave off `sudo`,
but you may have to add it yourself.

You can load the Docker image into Docker with:

```
$ docker load -i reml-popl24.tar.gz
```

You can then run the image with:

```
$ docker run -it reml-popl24:latest
```

or

```
$ docker run --platform linux/amd64 -it reml-popl24:latest
```

This command will put you into a shell inside a directory containing
the experimental infrastructure.  Run `make all` to compile and run the
ReML test suite and all the examples. Running `make all` should take less
than a minute.

## Introduction

This artifact includes (1) a tutorial aiming at demonstrating the
features of ReML presented in the POPL 2024 paper "Explicit Effects
and Effect Constraints in ReML", and (2) the source code for ReML,
including a description of the implementation aspects of ReML.

A Standard ML program is also a ReML program and in ReML, source files
are given to the ReML compiler (i.e., the `reml` executable) either as
a single source file or as an mlb-file describing a directed acyclic
graph (DAG) of source code files. The ReML compiler also accepts a
series of flags, which can be printed using `reml --help`:

    $ reml --version
    ....

For the sake of the tutorial, a pre-installed `reml-demo` folder is
present in the `reml-popl24` directory:

    $ cd reml-demo

The `reml-demo` directory contains a series of ReML tests and a few
serious examples.

## List of Claims

The artifact establishes the following main claims mantioned in the
paper:

1. ReML has been implemented and syntactic constructs are available on
   top of Standard ML syntax to control the underlying region
   inference process (Introduction and Section 4.)

2. A few larger ReML examples demonstrate how ReML can be used to
   reason about effects and in particular about the lack of allocation
   races (Mergesort, ray tracing, Mandelbrot).


## Tutorial

The following subsections describe the basic ReML tests, the ReML
parallel library, parallel Mergesort, parallel Mandelbrot, and a
parallel ray-tracer. All tests and examples can be executed (and the
output tested) by running `make all` from within the `reml-demo`
folder.

### Running the ReML Tests

An overview of many of the basic ReML tests can be generated by writing

```
$ make tests.sml
```

This command generates a file `tests.sml` with descriptions and
expected output of ReML behavior. The behavior is checked by running
`make test` in the `reml-demo` folder. Many of the aspects of ReML
described in Section 4 of the paper is reflected in these tests,
including `err_copylist.sml`.

Here is a snippet including a few lines of the generated `tests.sml` file:

```
(*** SOURCE err_copylist.sml ***)
     1	(* Exomorphisms by non-unifiable explicit region variables *)
     2
     3	infix ::
     4
     5	fun copy `[r1 r2] (xs : int list`r1) : int list`r2 =
     6	   case xs of
     7	      nil => nil
     8	    | x :: xs => x :: xs   (* copy forgotten *)

(*** COMPILE FAILURE - COMPILER OUTPUT ***)
     [reading source file:	err_copylist.sml]
     > infix 0 ::
       val copy : int list`r1->int list`r2
     err_copylist.sml, line 5, column 9:
       fun copy `[r1 r2] (xs : int list`r1) : int list`r2 =
                ^^^^^^^^
     Cannot unify the explicit region variables `r1 and `r2
```

And here is another snippet:

```
(*** SOURCE er4.sml ***)
     1
     2	(* It is an error to refer to a region name that is not in scope *)
     3
     4	fun f () =
     5	  let val a = 3.2`r
     6	      with r2
     7	  in #1 (4,3.2`r2,a)
     8	  end

(*** COMPILE FAILURE - COMPILER OUTPUT ***)
     [reading source file:	er4.sml]
     > val f : unit->int
     er4.sml, line 5, column 17:
         let val a = 3.2`r
                        ^^
     Explicit region variable `r is not in scope.
```

There is also an example demonstrating local mutable updates:

```
(*** SOURCE nomut-ok.sml ***)
     1	local
     2	  fun print (s:string) : unit = prim("printStringML", s)
     3	  fun !(x: 'a ref): 'a = prim ("!", x)
     4	  infix 3 :=
     5	  fun (x: 'a ref) := (y: 'a): unit = prim (":=", (x, y))
     6	  val r = ref "Hello\n"
     7	in
     8	fun f() =
     9	    ( print (!r)
    10	    ; r := "Hello again\n"
    11	    ; print (!r)
    12	    )
    13
    14	val rec g `e : (unit #e -> unit) while nomut e =
    15	 fn ()  =>
    16	    let val r2 = ref "hi"
    17	    in r2 := "hi there\n"
    18	     ; print (!r2)
    19	    end
    20
    21	val () = f()
    22	val () = g()
    23	end

(*** COMPILE SUCCESS - EXECUTION OUTPUT ***)
     Hello
     Hello again
     hi there
```

We see that ReML has determined that the function `g` has no external
mutable effects.

In general, the generated file `tests.sml` may be a good reference to
understand some of the basic syntactic parts of ReML.

### The ReML Parallel Library

ReML comes with basic thread libraries `reml-basis/Thread-reml.sml` and
`reml-basis/ForkJoin-reml.sml`, which implement the signatures
```
signature THREAD = sig
  type 'a t
  val spawn    : (unit->'a) -> ('a t->'b) -> 'b
  val get      : 'a t -> 'a
  val numCores : unit -> int
end

signature FORK_JOIN = sig
  val par    : (unit -> 'a) * (unit -> 'b) -> 'a * 'b
  val pair   : ('a -> 'c) * ('b -> 'd) -> 'a * 'b -> 'c * 'd
  val parfor : int -> int * int -> (int -> unit) -> unit
  val pmap   : ('a -> 'b) -> 'a list -> 'b list

  val alloc  : int -> 'a -> 'a array

  type gcs = int * int (* max parallelism, min sequential work *)
  val parfor' : gcs -> int * int -> (int -> unit) -> unit
end
```

ReML does not currently reflect ReML region- and effect-constraints
and annotations at the signature level, thus, we need to look into the
implementation files `basis/Thread-reml.sml` and
`basis/ForkJoin-reml.sml` to find the explicit region- and
effect-annotated versions of the definitions:

```
signature THREAD = sig
  type 'a t
  val spawn `[e1 e2] : (unit #e1 ->'a) -> ('a t #e2 -> 'b) -> 'b while e1 ## e2
  val get            : 'a t -> 'a
  val numCores       : unit -> int
end

signature FORK_JOIN = sig
  val par  `[e1 e2] : (unit #e1 -> 'a) * (unit #e2 -> 'b) -> 'a*'b while e1 ## e2
  val pair `[e1 e2] : ('a #e1 -> 'b) * ('c #e2 -> 'd) -> 'a*'c -> 'b*'d while e1 ## e2
  val parfor     `e : int -> int*int -> (int #e -> unit) -> unit while noput e
  val pmap     `[e] : ('a #e ->'b) -> 'a list -> 'b list while noput e =

  val alloc         : int -> 'a -> 'a array

  type gcs = int * int (* max parallelism, min sequential work *)
  val parfor'  `[e] : gcs -> int*int -> (int #e -> unit) -> unit while noput e
end
```

Whereas the `spawn` function is considered primitive in the sense that
the constraint is there to provide guarantees about allocation races
for the underlying implementation of `spawn`, all the functions in
`ForkJoin-reml.sml` (`FORK_JOIN`) are implemented using `spawn` and
the ReML constraint system is capable of discharging these constraints
based on the constraint type provided for `spawn`.

### Parallel Mergesort

A parallel version of Mergesort similar to the version shown in the
paper is implemented in `reml-demo/pmsort/pmsort.sml` (the implemented
version uses an accumulating version of `merge`, which avoids troubles
with lack of stack space). The example uses the `ForkJoin.par`
function until the available parallelism is exhausted at which point
in reverts into a sequential Mergesort. Here is how to run the example:

```
$ cd reml-demo/pmsort
$ make all pmsort.exe
$ ./pmsort.exe -P 1
```

ReML finds out that local regions are used for storing the results of
the local sort results and is able to discharge the proof obligation
of the `ForkJoin.par` function.

A more interesting version uses array slices, which allows for
parallelising also the `merge` function using a binary search. This
version is available in `reml-demo/slmsort/slmsort.sml`:

```
$ cd reml-demo/slmsort
$ make all slmsort.exe
$ ./slmsort.exe -P 1
```

### Parallel Mandelbrot

A parallel version of Mandelbrot is implemented in
`reml-demo/mandelbrot/mandelbrot.sml`. It uses the `ForkJoin.parfor'`
function to generate the pixels of the Mandelbrot set in
parallel. Using the `parfor'` function it is possible to control both
the grain size (`-G`), that is how much work an individual thread
should do, and the number of used threads (`-P`) . To test the
implementation, do as follows:

```
$ cd reml-demo/mandelbrot
$ make all mandelbrot.exe
$ ./mandelbrot.exe -P 12 -f pic.ppm
$ convert pic.ppm pic.png         (convert not installed on image)
```

Notice that ReML checks that the function passed to `ForkJoin.parfor'`
makes no global `put`-effects. The function can perfectly well make
allocations in local regions. The `-P` parameter specifies the number
of parallel Pthreads used.

### Parallel Ray Tracing

A parallel ray tracer is implemented in `reml-demo/ray/ray.sml`. It
uses the `ForkJoin.parfor` function to generate the pixels of the
Mandelbrot set in parallel. Using the `parfor` function it is possible
to control only the grain size; the number of threads used is
determined by the library. To test the implementation, do as follows:

```
$ cd reml-demo/ray
$ make all ray.exe
$ time ./ray.exe -G 10000 -f pic.ppm
$ convert pic.ppm pic.png         (convert not installed on image)
```

Notice that ReML checks that the function passed to `ForkJoin.parfor`
again makes no global `put`-effects. The function can perfectly well
make allocations in local regions. The `-G` parameter specifies the
work given to each thread. Playing with different values for `-G` is
likely to have a influence on the time performance.

For this example, it was necessary to arrange that pixel values are
stored in a record of arrays instead of an array of records, which
would lead to allocation races due to each thread allocating records
for the pixels; an alternative would be to pack the channels into a
single word (instead of using three words as is currently the case.)

## Adding a new Example

This artifact is not intended as an extensible framework, but it is
not too onerous to add new example.

Each of the larger examples resides in their own folder in the
`reml-demo` directory and is represented by an `.mlb` file (and a
`Makefile`) that mentions the source files of the example, and its
dependencies.

The easiest way to add a new example is to copy `reml-demo/mergesort`
(for example), give it a new name (including the `.mlb` file), modify
the `Makefile`, and add it to the parent folders' `Makefile`. Examples
that compile successfully expects a file `file.mlb.out.ok`. To add a
new test, you may copy one of the existing tests, rename it, and add
it to the `all.tst` file in the `reml-demo` folder. Examples that are
expected to halt with a compile time error appears with an "ecte"
entry in the `all.tst` file, which is processed by the `kittester`
helper application (installed together with ReML and MLKit). The
examples are responsible for doing their own validation by writing to
`stdout` (e.g., using `print`).

## System Requirements

The artifact assumes that `reml` is immediately runnable from the
command line and that necessary environment variables have been set
for them to work.  The provided Docker container has all this set up
already.

Constructing the image from `Dockerfile` requires access to the
Internet, but running `make` does not.

### Building ReML from Source

The Docker image contains source code for ReML v4.7.5, which is part
of the MLKit distribution located in the folder `mlkit-4.7.5`. As an
**optional first step** (before running the benchmarks), it is
possible to compile and install ReML and the MLKit from source, using
the following steps (ignore the possible error by `autobuild`):

```
$ cd mlkit-4.7.5
$ ./autobuild
$ ./configure --with-compiler=mlkit --prefix=/home/art/mlkit
$ make mlkit && make mlkit_basislibs
$ make install
$ cd ..
```

These steps will overwrite the binary MLKit and ReML installations with a
bootstrapped version of the MLKit and a ReML compiler built with MLKit.

## Docker Image

For space reasons, the Docker image is very sparse and does not have
text editors installed.  The user account has password-less `sudo` so
you can install more things if you want.  Otherwise you can use
commands such as `docker cp` to move data out of the image for
inspection on the host system.  Consult your favorite search engine
for information on how to use Docker if you are unfamiliar.

## Manifest

This section describes every top-level directory and nontrivial file
and its purpose.

* `reml-demo/`: The ReML demo programs and a Makefile containing
  targets for compiling and executing the programs with ReML. The
  Makefile target `all` runs the target `test`, which runs the tests.

* `reml-basis/`: A local copy of the ReML parallel library
  `par-reml.mlb` including implementations of `THREAD` and `FORK_JOIN`
  signatures.

* `tools/`: Various SML programs that constitute the experimental
  tooling.  You should not need to look at these.

* `Dockerfile`: The file used to build the Docker image.  You should
  use the pre-built image if possible, but if necessary you can build
  it yourself with `make reml-popl24.tar.gz` (uses `sudo`).

  Notice that the Dockerfile is *not* reproducible, so it may or may
  not result in a working image if you try this in the distant future.

* `Makefile`: The commands executed when running `make`.  You can
  extract the commands if you need to run them out of order.

* `mlkit-4.7.5`: Source directory for MLKit v4.7.5, which is the
  source for the binary version of ReML and the MLKit, installed in
  the Docker image.

## ReML Source Code Overview

ReML is implemented on top of MLKit and is tightly integrated with the
source code of MLKit. The source code for the compiler is Standard ML
and the runtime system (target code is x86_64 machine code) is written
primarily in C. There is almost full support for the Standard ML Basis
Library.

As mentioned above, the source code is available in the folder
`mlkit-4.7.5`. Below, we will briefly describe the major source code
components that contribute to the ReML additions of MLKit:

- `src/Parsing`: ReML is backwards compatible with Standard ML and
  features no additional keywords. ReML make special use of the `with`
  and `while` keywords to bind effects and regions (`with`
  declarations) and to add constraints to type schemes (`while`
  types). The `DEC_GRAMMAR` signature is extended to fit the new
  constructs and `src/Parsing/Topdec.grm` is extended to support
  `with` declarations and `while` types. The special back-tick syntax
  for annotating expressions and types with explicit region and effect
  variables also involve changes to the grammar and the AST described
  by the `DEC_GRAMMAR` signature.

- `src/Common/EfficientElab/ElabDec.sml` and `src/Compiler/Lambda`:
  ReML does its best at propagating source code locations for
  annotations into the deeper languages in the compiler. Roughly,
  after elaboration (ML type inference), code is translated into a
  typed intermediate language representation
  (`src/Compiler/Lambda/LAMBDA_EXP`) for which all module language
  constructs have been eliminated. At these levels (elaboration and
  typed lambda language), ReML constraints and annotations are yet not
  used for any kind of checking.

- `src/Compiler/Regions`: After `LAMBDA_EXP` (and a series of
  optimisations), programs are compiled into explicit region-annotated
  terms (the language `REGION_EXP`). This translation is the process
  of *region inference*, a typed- and effect-based transformation that
  happen in two phases (see the paper for details). The first phase is
  a *spreading phase* that inserts fresh region- and effect-variables
  to the program. During this phase, which is implemented in
  `src/Compiler/Regions/SpreadExpression.sml`, explicit ReML region
  annotations are used to guide the insertion of fresh region- and
  effect-variables (by, for instance, associating explicit region- and
  effect-variables with the internal counterparts, which may be
  unified. The definition of internal region- and effect-variables is
  located in the file `src/Compiler/Regions/Effect.sml`. The
  definition is based on a union-find data structure that features a
  series of graph operations for instantiating and generalising graphs
  (i.e., region- and effect-polymorphic type schemes). The second
  phase is the *region inference* phase (file
  `src/Compiler/Regions/RegInf.sml`), which applies a series of
  so-called *contracting substitutions* (i.e., unifications) to ensure
  that the region-typing rules are satisfied. Because no fresh
  variables are created during this phase, the phase is guaranteed to
  terminate (provided the underlying ML program is well-typed).

  During these phases, ReML may complaint with errors if region
  inference is forcing unifications that do not adhere to the explicit
  region- and effect-annotations (including pinning of region- and
  effect- variables with `with` declarations and explicit region- and
  effect-parameters). The constraints that are annotated through the
  notion of `while` types are pushed into the region- and effect-graph
  structure, by annotations on region and effect variables.

  After the two region-inference phases, the constraints are checked
  by attempting to resolve constraints using simpler constraint
  assumptions and other effect properties (e.g., that locally defined
  effects are finite and closed and that a `nomut` constraint on an
  effect entails put-disjointness (##) with other effects). The code,
  which essentially follows the formal development in the paper,
  appears in `src/Compiler/Regions/Effect.sml` (functions
  `check_constraint` and `check_prop_constraint`).

- The deeper ReML compiler phases are fully shared with the MLKit
  Standard ML compiler.
