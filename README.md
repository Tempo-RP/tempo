# Tempo

> A lightweight synchronous runtime inspired by Esterel, Boussinot’s FairThreads, and ReactiveML.

Tempo is a deterministic reactive execution model for OCaml: programs evolve by logical instants, communicate with signals, and coordinate behavior safely through event-driven control.

## Table of contents

- [Overview](#overview)
- [Programming model](#programming-model)
  - [Instants and execution lifecycle](#instants-and-execution-lifecycle)
  - [Fundamental primitives](#fundamental-primitives)
  - [Optional PPX syntax](#optional-ppx-syntax)
- [Install Tempo](#install-tempo)
  - [Requirements](#requirements)
  - [Install from source](#install-from-source)
- [Quick start](#quick-start)
  - [Create and run a minimal application](#create-and-run-a-minimal-application)
  - [Runtime logging and diagnostics](#runtime-logging-and-diagnostics)
- [Contributing](#contributing)

---

## Overview

- Tempo programs execute in **logical instants**.
- Communication is based on **signals** carrying values.
- The scheduler guarantees deterministic behavior when primitives are used correctly.
- It is useful for reactive behaviors, event orchestration, and simulation-style workloads.

## Programming model

### Instants and execution lifecycle

A program is evaluated over a sequence of discrete instants. At each instant:

- A signal is either **present** (emitted by environment or program) or **absent**.
- The absence of a signal is only observed in the following instant, which preserves determinism.
- Weak preemption is supported through constructs such as `watch`, allowing controlled interruption without breaking synchronous semantics.

`execute` runs to quiescence. Before each logical instant it actually opens,
Tempo calls the host `input` callback once. It stops when the scheduler has no
work queued for a possible next instant. Work invalidated during rollover can
still cause one final empty instant to be opened. A continuation registered only
as a signal awaiter does not keep the runtime alive by itself; once `execute`
returns, a later input value cannot restart that invocation.

The optional `~instants` argument is consequently a maximum, not a promise to
run exactly that many instants. Without it there is no numerical limit, but
quiescence still terminates the execution. A non-positive bound opens no
instant. The bound is checked only between instants and cannot interrupt code
that diverges without suspending during the current instant. Long-lived
integrations must keep their lifetime explicit, for example with a driver
branch that calls `pause ()` while the host should continue polling.

Sequential and nested `execute` calls on one OCaml Domain are supported, with
the signal-ownership rules described below. Tempo 0.3 does not support several
`execute` invocations running concurrently on distinct Domains; the host must
serialize them. This does not restrict Tempo's logical `parallel` operator.
Host callbacks are synchronous and must not perform Tempo effects. A blocking
callback blocks `execute`; an exception from a callback escapes `execute` and
skips the remaining phases of that instant.

### Fundamental primitives

Tempo supports two kinds of signals:

- **Event signals** (`new_signal ()`) accept at most one emission per instant.
- **Aggregate signals** (`new_signal_agg ~initial ~combine`) can accumulate multiple emissions in one instant using a combine function.

Every signal belongs to the particular `execute` invocation that created it,
including the host input and output signals. It remains an ordinary storable
OCaml value, but Tempo operations reject it with `Invalid_argument` from a
nested/later execution or after its owning execution has returned. Returning
from `execute` abandons pending continuations without unwinding them.

Reactive behavior is built from these primitive operations:

- `emit signal value`  
  Mark `signal` as present in the current instant and resume waiting tasks.
- `await signal`  
  Suspend until `signal` becomes present; resume at the beginning of the next instant.
- `await_immediate signal`  
  Return immediately if already present. Otherwise suspend and resume in the
  same instant in which a later emission makes the signal present, without the
  extra instant imposed by `await`.
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

Single-body control scopes use an application-shaped payload. The extension
name is `tempo.when`; the library function is named `Tempo.when_` only because
`when` is an OCaml keyword:

```ocaml
let result =
  [%tempo.when guard
    (let value = await payload in
     value + 1)]
in
[%tempo.watch stop
  (service ();
   pause ())]
```

These forms expand respectively to:

```ocaml
let result =
  Tempo.when_ guard (fun () ->
      let value = await payload in
      value + 1)
in
Tempo.watch stop (fun () ->
    service ();
    pause ())
```

The PPX requires exactly one syntactic body argument after the signal. An
atomic body needs no grouping (`[%tempo.when guard value]`); every compound
body must be enclosed in parentheses or `begin ... end`. For example,
`[%tempo.when guard emit signal value]` is rejected as an ambiguous
multi-argument payload; write `[%tempo.when guard (emit signal value)]`.
A computed signal expression must likewise be grouped, as in
`[%tempo.when (select_guard key) body]`.

For `tempo.parallel`, the payload must be a literal OCaml list. Keep the direct
`Tempo.parallel computations` API for a list assembled dynamically. An
ordinary function still requires its normal application inside every generated
body, for example `worker ()`; otherwise `tempo.when` can legitimately return
the function value. Immediate Tempo operations such as `emit signal value` do
not gain an extra application.

The spelling `parallel%tempo [...]` is deliberately not provided: OCaml parses
it as an application of the infix `%` operator, not as a PPX extension point.
The PPX marks generated closures with the internal attributes
`tempo.parallel_branch`, `tempo.when_body`, and `tempo.watch_body`, preserving
each body's source location so later typed-tree tooling can identify the
boundaries. These markers are descriptive; they are not by themselves a static
safety proof.

## Install Tempo

### Requirements

- OCaml >= 5.4.1
- opam
- dune >= 3.19

### Install from source

Tempo 0.3 is not yet published in the official opam repository. Install the
current release candidate from its source tree:

```sh
git clone https://github.com/Tempo-RP/tempo.git
cd tempo
opam install ./tempo.opam
```

Install the optional PPX package from the same checkout when needed:

```sh
opam install ./tempo-ppx.opam
```

The generated API documentation is available at
<https://tempo-rp.github.io/tempo/>.

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

### Runtime logging and diagnostics

Tempo sends its runtime diagnostics through the dedicated
`Tempo.Logging.source`, named `tempo.runtime`. Loading Tempo does not install a
reporter, change any global logging level, inspect command-line arguments, or
interpret logging environment variables. The host application owns those
policies.

For example, an application can enable Tempo diagnostics without changing the
levels of other libraries (and should list `logs` alongside `tempo` in its Dune
`libraries` field):

```ocaml
Logs.set_reporter (Logs.format_reporter ());
Logs.Src.set_level Tempo.Logging.source (Some Logs.Debug)
```

With the default `Logs` warning level, Tempo stays silent because its runtime
diagnostics use the `Info` and `Debug` levels.

`Tempo.runtime_snapshot` and the `on_snapshot` callback are experimental
diagnostic interfaces in Tempo 0.3. Their record fields and counter meanings
may change in later 0.x releases, as may the snapshot phases and callback
schedule. Not every phase is emitted for every instant. These interfaces are
intended for tests, profiling, and scheduler inspection, not for defining
application behavior or persisted data.

## Contributing

From source:

```sh
git clone https://github.com/Tempo-RP/tempo.git tempo-dev
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
