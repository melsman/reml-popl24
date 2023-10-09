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

This command will put you into a shell inside a directory containing
the experimental infrastructure.  Run `make test` to run the ReML test
suite.

## Introduction

This artifact includes (1) a tutorial aiming at demonstrating the
features of ReML presented in the POPL 2024 paper "Explicit Effects
and Effect Constraints in ReML", and (2) the source code for ReML,
including a detailed description of the implementation aspects of ReML.

A Standard ML program is also a ReML program and in ReML, source files
are given to the ReML compiler (i.e., the `reml` executable) either as
a single source file or as an mlb-file describing a directed asyclic
graph (DAG) of source code files. The ReML compiler also accepts a
series of flags, which can be printed using `reml --help` or `man
reml`:

    $ reml --version
    ....

For the sake of the tutorial, a pre-installed `reml-demo` folder is
present in the home directory:

    $ cd reml-demo

The `reml-demo` directory contains a series of ReML tests and a few more
serious examples.

## Running the ReML Tests

## Parallel Mergesort

## Parallel Mandelbrot

## Parallel Ray Tracing

## Local Mutable Storage

## Step by Step Instructions

## Adding a new Example

This artifact is not intended as an extensible framework, but it is
not too onerous to add new example.

Each of the larger examples resides in their own folder in the
`reml-demo` directory and is represented by an `.mlb` file that
mentions the source files of the example, and its dependencies.

The easiest way to add a new example is to copy `reml-demo/mergesort`
(for example), give it a new name (including the `.mlb` file), and add
it to the file `all.tst` in the `reml-demo` folder. Examples that
compile successfully expects a file `file.mlb.out.ok`. Examples that
are expected to halt with a compile time error appears with an "ecte"
entry in the `all.tst` file. Examples are responsible for doing their own
validation by writing to stderr (e.g., using `print`).

## System Requirements

The artifact assumes that `reml` is immediately runnable from the
command line and that necessary environment variables have been set
for them to work.  The provided Docker container has all this set up
already.

Constructing the image from `Dockerfile` requires access to the
Internet, but running `make` does not.

### Building ReML from Source

The Docker image contains source code for ReML v4.7.4, which is part
of the MLKit distribution located in the folder `mlkit-4.7.4`. As an
**optional first step** (before running the benchmarks), it is
possible to compile and install ReML and the MLKit from source, using
the following steps (ignore the possible error by `autobuild`):

```
$ cd mlkit-4.7.3
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
text editors installed.  The user account has passwordless `sudo` so
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

* `tools/`: Various SML programs that constitute the experimental
  tooling.  You should not need to look at these.

* `Dockerfile`: The file used to build the Docker image.  You should
  use the prebuilt image if possible, but if necessary you can build
  it yourself with `make reml-popl24.tar.gz` (uses `sudo`).

  Notice that the Dockerfile is *not* reproducible, so it may or may
  not result in a working image if you try this in the distant future.

* `Makefile`: The commands executed when running `make`.  You can
  extract the commands if you need to run them out of order.

* `mlkit-4.7.4`: Source directory for MLKit v4.7.4, which is the
  source for the binary version of ReML and the MLKit, installed in
  the Docker image.
