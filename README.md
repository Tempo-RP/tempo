# Tempo

> A lightweight synchronous runtime inspired by Esterel, Boussinot’s FairThreads, and ReactiveML.

Tempo is a deterministic reactive execution model for OCaml: programs evolve by logical instants, communicate with signals, and coordinate behavior safely through event-driven control.

## Table of contents

- [Overview](#overview)
- [Programming model](#programming-model)
  - [Instants and execution model](#instants-and-execution-model)
  - [Fundamental primitives](#fundamental-primitives)
- [Install Tempo](#install-tempo)
  - [Requirements](#requirements)
  - [Install from opam](#install-from-opam)
- [Quick start](#quick-start)
  - [Create and run a minimal application](#create-and-run-a-minimal-application)
  - [Logging and runtime flags](#logging-and-runtime-flags)
- [Contributing](#contributing)
- [Run demos](#run-demos)
  - [Simple demos](#simple-demos)
  - [Advanced applications](#advanced-applications)
- [Application screenshots](#application-screenshots)
- [Troubleshooting](#troubleshooting)

---

## Overview

- Tempo programs execute in **logical instants**.
- Communication is based on **signals** carrying values.
- The scheduler guarantees deterministic behavior when primitives are used correctly.
- It is useful for reactive behaviors, event orchestration, and simulation-style workloads.

## Programming model

### Instants and execution model

A program is evaluated over a sequence of discrete instants. At each instant:

- A signal is either **present** (emitted by environment or program) or **absent**.
- The absence of a signal is only observed in the following instant, which preserves determinism.
- Weak preemption is supported through constructs such as `watch`, allowing controlled interruption without breaking synchronous semantics.

### Fundamental primitives

Tempo supports two kinds of signals:

- **Event signals** (`new_signal ()`) accept at most one emission per instant.
- **Aggregate signals** (`new_signal_agg ~initial ~combine`) can accumulate multiple emissions in one instant using a combine function.

Reactive behavior is built from these primitive operations:

- `emit signal value`  
  Mark `signal` as present in the current instant and resume waiting tasks.
- `await signal`  
  Suspend until `signal` becomes present; resume at the beginning of the next instant.
- `await_immediate signal`  
  Resume in the same instant if already present, otherwise like `await`.  
  For determinism this is restricted to event signals.
- `pause ()`  
  Suspend and resume at the next instant.
- `parallel [p1; …; pn]`  
  Start programs concurrently in the current instant and wait for all of them.
  If an exception escapes a branch, finish the runnable work of the current
  reaction, stop every branch before the next instant, and re-raise at the
  `parallel` call site in the failing instant. If several branches fail, the
  lowest list index wins. This is weak preemption: suspended sibling
  continuations are discarded, so their cleanup handlers are not guaranteed to
  run.
- `when_ guard body`  
  Run `body` only when `guard` is present, otherwise suspend the task; return
  the value produced by `body` when it completes.
- `watch signal body`  
  Run `body` under weak preemption. If `signal` is present at the end of the
  current instant while the body is still active, stop the body and its
  reactive descendants, then schedule the continuation after `watch` for the
  next instant under its enclosing guards. A body that finishes normally
  continues after `watch` in the same instant. Preemption discards suspended
  continuations and does not guarantee that their cleanup handlers run.

A delayed reactive body has the transparent type
`'a Tempo.computation = unit -> 'a`. Tempo uses this name at control-scope
boundaries, notably for the branches of `parallel` and the bodies of `when_` and
`watch`.
No wrapper is required; an ordinary `fun () -> ...` already has this type.
Inside such a body, immediate primitives stay in direct style:

```ocaml
parallel [
  (fun () ->
     pause ();
     emit signal 42);
  (fun () ->
     let value = await signal in
     Format.printf "received %d@.%!" value)
]
```

`emit signal 42` and `await signal` therefore need no extra `()` application.
`pause ()` keeps one because `unit` is its ordinary argument, not because it is
a delayed computation.

### Optional PPX syntax

Tempo 0.3 provides the optional `tempo-ppx` package. Enable it only in modules
that use the syntax extension:

```dune
(executable
 (name my_app)
 (libraries tempo)
 (preprocess
  (pps tempo-ppx)))
```

A parallel composition whose branches are known syntactically can then be
written without visible thunks:

```ocaml
[%tempo.parallel
  [ emit signal 42
  ; let value = await signal in
    Format.printf "received %d@.%!" value
  ]]
```

It expands to the ordinary library call:

```ocaml
Tempo.parallel
  [ (fun () -> emit signal 42)
  ; (fun () ->
      let value = await signal in
      Format.printf "received %d@.%!" value)
  ]
```

The payload must be a literal OCaml list. Keep the direct
`Tempo.parallel computations` API for a list assembled dynamically. An
ordinary function still requires its normal application inside a branch, for
example `worker ()`; immediate Tempo operations such as `emit signal value`
do not gain an extra application.

The spelling `parallel%tempo [...]` is deliberately not provided: OCaml parses
it as an application of the infix `%` operator, not as a PPX extension point.
The PPX marks each generated closure with the internal
`tempo.parallel_branch` attribute and preserves the branch's source location so
later typed-tree tooling can identify the boundary. This marker is descriptive;
it is not by itself a static safety proof.

## Install Tempo

### Requirements

- OCaml >= 5.4.1
- opam
- dune >= 3.19

### Install from opam

```sh
opam install tempo
```

Optional add-ons:

```sh
opam install tempo-ppx       # lightweight syntax extensions
opam install tempo-raylib tempo-fluidsynth tempo-score
```

This is enough if you only want to consume Tempo in your own projects.

## Quick start

### Create and run a minimal application

Create two files in a fresh folder (example: `./my-app`):

1) `dune`

```lisp
(executable
 (name my_app)
 (modules my_app)
 (libraries tempo))
```

2) `my_app.ml`

```ocaml
open Tempo

let run _input _output =
  let signal = new_signal () in
  parallel [
    (fun () ->
       let value = await signal in
       Format.printf "received %d@.%!" value);
    (fun () -> emit signal 42)
  ]

let () = execute run
```

Run it from this folder:

```sh
# build the executable
dune build ./my_app.exe

# run it
dune exec ./my_app.exe
```

## Contributing

From source:

```sh
git clone <repo-url> tempo-dev
cd tempo-dev

# install deps + docs/test dependencies
opam install . --with-test --with-doc

# build + tests
dune build
dune runtest

# optional: run a single test executable
dune exec tests/ok/emit_once_await_one.exe

# build API documentation
dune build @doc
```

Open local docs at:

```
_build/default/_doc/_html/tempo/index.html
```
