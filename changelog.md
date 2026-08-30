## [0.3.0] - Unreleased

### Added
- Added the optional `tempo-ppx` package and the
  `[%tempo.parallel [branch; ...]]`, `[%tempo.when guard body]`, and
  `[%tempo.watch signal body]` syntaxes for delayed control computations.
- Added the transparent `'a computation = unit -> 'a` name for delayed Tempo
  control bodies.
- Added public API compile checks and precise behavioral tests for guarded,
  preemptive, and parallel control scopes.

### Changed
- Made signal and runtime representations private implementation details.
- Generalized `when_` so a normally completed guarded computation returns its
  result.
- Defined `watch` as weak preemption and documented its timing and cleanup
  limitations.
- Made exceptions escaping `parallel` branches weakly fail-fast, deterministic
  by branch index, and catchable at the lexical call site in the same instant.
- Made signal emission failures observable in direct style at the `emit` call
  site.

### Fixed
- Bound every signal to its creating `execute` invocation, reject foreign or
  expired signals at the direct-style call site, and detach pending runtime
  registrations whenever `execute` returns.
- Prune completed `watch` scopes at instant finalization so dead kill watchers
  do not accumulate on long-lived absent signals.
- Stop replacing the host application's global `Logs` reporter and reporting
  levels when Tempo is loaded. Runtime diagnostics now use the dedicated
  `Tempo.Logging.source` and remain under application control.

### Removed
- Removed the unstable public `Constructs` compatibility module.
- Removed implicit parsing of the generic `--log-level` option and the legacy
  `RML_*` logging environment variables from the runtime library.

## [0.2.1] - 2026-08-06

### Added
- Added `parallel` as a first-class concurrency effect in the API.
- Added a reactive supervision benchmark.
- Added multi-instant benchmark variants (B1/B4) for broader runtime comparison.
- Added richer benchmark and evaluation tooling for Tempo vs reference implementations.

### Changed
- Renamed the guard effect from `guard` to `When`.
- Removed the low-level `kill` effect and refactored related checkpoint logic.
- Reworked signal/continuation structures:
  - introduced structured resume plans,
  - refined typed signal-tracking state,
  - clarified guard cache state,
  - reworked watch/exit and join-registration paths.

### Fixed
- Stabilized watch kill-context semantics.
- Clarified and fixed behavior for `watch` across `pause` and `await_immediate`.
- Improved correctness of process/control flow around instant scheduling, including:
  - no premature process exit on `run_instant`,
  - better stop/resume behavior for guarded execution.
- Addressed cancellation and invalidation consistency for watch and task records.

### Performance
- Reduced allocations and improved reuse in runtime structures:
  - reused scheduler task records,
  - reused task records across `await`/`when`/`pause`/`watch` paths,
  - reused parent task records in parallel joins,
  - introduced reusable scheduler worklists.
- Added fast-path optimizations for single-signal guard checks.
- Refactored internal bookkeeping paths to reduce repeated allocation and registration overhead.

### Benchmarks and Tooling
- Updated benchmark harnesses and scripts, including native-mode comparisons.
- Refreshed benchmark reference outputs and diagnostic data.
- Added configuration improvements for default logging noise and frozen reference packs.

### Documentation
- Updated `README` and project documentation details.

### Dependencies
- Updated `raylib` to `2.2.2`.

## [v0.2.0]
- Baseline release.
