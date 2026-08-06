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