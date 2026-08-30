(*---------------------------------------------------------------------------
 * Tempo - synchronous runtime for OCaml
 * Copyright (C) 2025 Frédéric Dabrowski
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *---------------------------------------------------------------------------*)

(** This library revisits the ReactiveML programming model using {b OCaml 5
    algebraic effects}, instead of the continuation-passing and compilation
    techniques used in the original ReactiveML implementation. Tempo 0.3
    requires OCaml 5.4.1 or newer.
    
    Programs are executed according to a synchronous semantics: 
    computation progresses in a sequence of logical instants,
    and reactive signal observations within an instant form one synchronous
    reaction. Ordinary OCaml side effects retain their usual execution order.
    
    For a given set of signal emissions in each instant, the observable
    behavior of a purely functional program is deterministic when aggregate
    updates are independent of emission order. Internal scheduling and
    execution order are then not observable and do not affect the final
    synchronous outcome.
    
    *)

(** {1 Runtime logging} *)

module Logging : sig
  val source : Logs.src
  (** The dedicated [Logs] source for Tempo runtime diagnostics, named
      ["tempo.runtime"]. Tempo never installs a reporter and never changes the
      global or source-specific reporting levels. The host application may
      enable this source with [Logs.Src.set_level source level] after installing
      the reporter of its choice. *)
end

(** {1 Computations} *)

(** A name for a delayed OCaml computation passed to a Tempo control operator.

    This is a transparent type abbreviation: [(fun () -> body)] is already a
    computation and no constructor is required. It introduces vocabulary, not a
    distinct runtime representation or a static guarantee. The name marks API
    boundaries where Tempo decides when or under which reactive control scope
    [body] starts. Effects such as {!val:pause} still require an enclosing
    {!val:execute}.

    Immediate operations keep their ordinary direct-style signatures. For
    example, [emit signal value], [await signal], and [pause ()] execute at the
    current point of the surrounding computation. *)
type 'a computation = unit -> 'a

(** {1 Signals }
    Signals are the primary communication mechanism between tasks.
    They come in two flavours:

    - {b Event signals} guarantee at most one [emit] per instant. Presence is a
      boolean flag and the value is delivered during the instant. Multiple emissions
      raise an exception.
    - {b Aggregate signals} may be emitted multiple times within the same
      instant. Values are combined using a user-provided accumulator function, and
      the final accumulated value is visible at the next instant.

    In both cases, presence information is scoped to the current instant. When a
    task waits for a signal, the scheduler suspends it across instants until
    the signal becomes present.*)

(** Signal kinds are tracked with phantom markers so that the type system can
    distinguish single-emission (event) signals from aggregate signals while
    still sharing the same primitives. *)

(** Abstract marker for single-emission event signals. *)
type event

(** Abstract marker for aggregate signals. *)
type aggregate

(** Generalized abstract signal type. ['emit] is the type of values passed to
    [emit], ['observe] is the value observed by [await] (equal to ['emit] for
    events, but possibly different for aggregates), and ['kind] encodes the
    signal flavour. The runtime representation is intentionally hidden. *)
type ('emit, 'observe, 'kind) signal_core

(** Every signal belongs to the particular {!val:execute} invocation in which
    it was created. This includes the input and output signals passed to the
    top-level process. A nested or later [execute] invocation is a different
    execution, even when it runs on the same OCaml Domain.

    Signals may be stored in ordinary OCaml values, but applying {!val:emit},
    {!val:await}, {!val:await_immediate}, {!val:when_}, or {!val:watch} from a
    different execution, or after the owning execution has returned, raises
    [Invalid_argument] at that operation's call site. *)

(** A value of type ['a signal] represents a single-emission signal (at most one
    [emit] per instant) carrying values of type ['a]. Attempts to emit twice in
    the same instant raise [Invalid_argument]. *)
type 'a signal = ('a, 'a, event) signal_core

(** Aggregate signals can be emitted several times per instant; their values
    are combined using the user-provided accumulator before the aggregated value
    is made visible for the next instant. *)
type ('emit, 'observe) agg_signal =
  ('emit, 'observe, aggregate) signal_core

(** {1 Signal creation} *)

(** [new_signal ()] creates a new event signal.

    The signal starts absent in the current instant and can be emitted at most
    once per instant. Event signals are compatible with every primitive that
    expects a signal argument; they are also the only signals that support
    {!val:await_immediate}. *)
val new_signal : unit -> 'a signal

(** [new_signal_agg ~initial ~combine] creates an aggregate signal. When the
    signal is emitted several times within the same instant, each value is
    folded into the accumulator using [combine]. The accumulator starts at
    [initial] for the first emission of the instant. Aggregate signals can be
    used with the same primitives as event signals; the sole restriction is that
    {!val:await_immediate} is unavailable because their combined value is only
    produced at the end of the instant. If several tasks may emit concurrently,
    [combine] must make accumulation independent of emission order to retain
    scheduler-order determinism. [combine] is a synchronous runtime callback,
    not a Tempo computation, and must not perform Tempo effects. *)
val new_signal_agg :
  initial:'agg -> combine:('agg -> 'emit -> 'agg) -> ('emit, 'agg) agg_signal

  (** {1 Synchronous operators} *)

(** {2 Emission } *)

(** [emit s v] marks [s] as present in the current instant and propagates the
    value [v].

    - For event signals, emitting twice in the same instant raises an exception
      at the [emit] call site.
    - For aggregate signals, [v] is combined with the current accumulator using
      the function supplied at creation time; awaiters only observe the final
      accumulator value at the end of the instant. An exception raised by the
      combine function is likewise re-raised at the [emit] call site. *)
val emit : ('emit, 'agg, 'mode) signal_core -> 'emit -> unit

(** {2 Signal status } *)

(** [await s] waits for signal [s] to be emitted.

    The continuation is always resumed in the {b next} instant, even if the
    signal is already present when [await] is executed. Example:

    {[
      let s = new_signal () in
        emit s 42;
        let v = await s in
            (* v = 42, this line runs in the instant following the emission. *)
            Format.printf "received %d@." v
    ]}
    Aggregated signals behave the same, except that the value returned by
    [await] is the accumulated one:

    {[
      let s = new_signal_agg ~initial:0 ~combine:( + ) in
        emit s 1;
        emit s 2;
        emit s 3;
        let sum = await s in
            (* sum = 6, this line runs in the instant following the emission. *)
            Format.printf "sum=%d@." sum
    ]}
*)
val await : ('emit, 'agg, 'mode) signal_core -> 'agg

(** [await_immediate s] waits for [s] but resumes as soon as the signal is
    present, within the {b current} instant. This is restricted to
    event signals because aggregate signals only deliver their combined value at
    the end of the instant. Calling it on an aggregate signal is a type error.

    {[
      let s = new_signal () in
          emit s 42;
          let v = await_immediate s in
            (* v = 42, this line still runs in the same instant. *)
            Format.printf "saw %d@." v
    ]}
*)
val await_immediate : 'a signal -> 'a

(** {2 Suspension } *)

(** [pause ()] suspends the current task until the next instant.

    The current task yields control and is resumed at the beginning
    of the next instant, unless it is aborted.

    {[
      let rec loop () =
        Format.printf "Looping@.";
        pause ();
        loop ()
    ]}
*)
val pause : unit -> unit

(** [when_ g body] executes [body] under a presence guard.

    The body is executed only when signal [g] is present in the current
    instant. If [g] is absent, the task is blocked intra-instant and may
    be resumed later in the same instant if [g] is emitted.

    Nested calls to [when_] correspond to a conjunction of guards. When [body]
    completes normally, its result is returned and execution continues outside
    the guarded scope. An exception raised by [body] is re-raised at the
    [when_] call site. *)
val when_ :
  ('emit, 'agg, 'mode) signal_core -> 'result computation -> 'result

(** {2 Weak preemption } *)

(** [watch s body] schedules [body] to start in the current instant under a
    weak-preemption scope.

    If [body] completes normally before instant closure, [watch] returns in the
    same instant. If [s] is present at instant closure while [body] is still
    active, the runtime stops [body] and its reactive descendants before the
    next instant, then schedules the caller's continuation for that next
    instant under its enclosing guards. Effects already produced by [body] in
    the closing instant remain visible.

    This rule also applies when [s] is already present at the call: [body] may
    execute its current-instant prefix, but a suspended remainder does not run
    in the next instant. Normal completion or an exception before closure wins
    over preemption. An exception that exits the scheduled invocation of [body]
    is re-raised at the [watch] call site with its original backtrace.

    The [unit] result does not distinguish normal completion from preemption.
    Preemption discards scheduled continuations; it does not unwind them.
    Consequently, cleanup handlers such as [Fun.protect]'s [finally] callback
    inside a preempted remainder are not guaranteed to run. *)
val watch :
  ('emit, 'agg, 'mode) signal_core -> unit computation -> unit

(** {2 Concurrency}

    {!val:parallel} launches several behaviors concurrently within the same
    synchronous instant semantics. The call returns only when every branch has
    completed. If [parallel] itself is guarded with {!val:when_}, the entire
    composition is suspended whenever the guard is absent; none of the branches
    progress until the guard holds again. Likewise, wrapping [parallel] in
    {!val:watch} causes every branch to be stopped together at instant closure,
    before the next instant, if the watched signal is present. *)

(** [parallel computations] starts every computation in the current instant.
    If all branches finish normally, it returns after all of them have
    completed.

    An exception escaping a branch triggers weak fail-fast termination. Tempo
    first lets the current synchronous reaction reach quiescence, so sibling
    branches may complete work that is already runnable in the failing instant.
    It then stops every still-active branch and reactive descendant before any
    of them can enter a later instant, and re-raises the exception at the
    [parallel] call site in the same instant with its original backtrace.

    If several branches of the same [parallel] fail before that barrier, the
    exception from the lowest-indexed branch in [computations] is selected,
    independently of their execution order. Nested failures cross [parallel]
    scopes from the innermost scope outwards.

    The failing branch's own OCaml stack is unwound normally. Stopping its
    siblings is weak preemption: their suspended continuations are discarded,
    not unwound, so cleanup handlers such as [Fun.protect]'s [finally] callback
    in those continuations are not guaranteed to run. *)
val parallel : unit computation list -> unit

(** Experimental phases reported by [on_snapshot]. [`Before_step] precedes the
    [input] callback. [`After_step] follows reaction quiescence and the optional
    [output] callback. [`After_finalize] follows signal finalization and the
    scheduling of blocked tasks. [`After_rollover] follows rollover processing
    when the next-instant queue was non-empty. It does not guarantee that live
    work remains or that the possible next instant will be opened. At that
    phase, {!type:runtime_snapshot}'s [instant] field already denotes the
    possible next instant.

    Not every phase occurs for every instant. A zero-instant execution emits no
    snapshot, [`After_rollover] is omitted when the next-instant queue is empty,
    and an exception can truncate the sequence. The phase set and callback
    schedule may change in a later 0.x release. *)
type snapshot_phase =
  [ `Before_step
  | `After_step
  | `After_finalize
  | `After_rollover
  ]

(** Immutable snapshot of scheduler and GC counters for one instant phase.
    Fields are readable by clients, but only the runtime can construct a
    snapshot.

    This is an experimental diagnostics interface in Tempo 0.3. The record
    shape, individual counters, and their exact meanings may change between
    later 0.x releases. It must not be persisted or used to define the
    functional behavior of a Tempo program. *)
type runtime_snapshot = private {
    phase : snapshot_phase
  ; instant : int
  ; step : int
  ; current_q : int
  ; blocked_q : int
  ; next_q : int
  ; tracked_signals : int
  ; awaiters : int
  ; guard_waiters : int
  ; kill_watchers : int
  ; live_tasks : int
  ; kill_context_refs : int
  ; kill_context_nodes : int
  ; kill_context_max_depth : int
  ; active_thread_slots : int
  ; total_active_threads : int
  ; total_suspended_threads : int
  ; task_counter : int
  ; thread_counter : int
  ; signal_counter : int
  ; free_task_count : int
  ; gc_minor_words : float
  ; gc_promoted_words : float
  ; gc_major_words : float
  ; gc_minor_collections : int
  ; gc_major_collections : int
  ; gc_heap_words : int
  ; gc_live_words : int
  ; gc_free_words : int
  ; gc_top_heap_words : int
  ; gc_stack_size : int
  ; cum_tasks_created : int
  ; cum_tasks_disposed : int
  ; cum_tasks_enqueued_now : int
  ; cum_tasks_enqueued_next : int
  ; cum_tasks_blocked : int
  ; cum_signals_created : int
  ; cum_signals_tracked : int
  ; cum_signals_untracked : int
  ; cum_awaiters_registered : int
  ; cum_awaiters_resumed : int
  ; cum_awaiters_pruned : int
  ; cum_guard_waiter_registrations : int
  ; cum_guard_waiter_wakeups : int
  ; cum_kill_watchers_registered : int
  ; cum_kill_watchers_fired : int
  ; cum_kill_watchers_pruned : int
}

(** [execute ?instants ?input ?output ?on_snapshot main] runs [main] in a fresh
    synchronous runtime.

    {b Instants and termination.} [main input_signal output_signal] runs as a
    scheduled Tempo task in the first logical instant that is opened. If
    [instants] is omitted, [execute] keeps opening instants while scheduler work
    remains queued for a later instant. On the normal path, every opened instant
    is driven to reaction quiescence and closed before the next one is opened.

    [~instants:n] sets an upper bound; it does not request exactly [n] instants.
    Execution may stop earlier when no later work is queued, or when an
    exception escapes. If [n <= 0], no instant is opened, and [main], [input],
    [output], and [on_snapshot] are not called. The bound is checked only between
    instants: it cannot interrupt a computation that fails to reach quiescence
    within the current instant. Work still suspended or scheduled beyond the
    bound is abandoned when the runtime closes.

    {b Host input and output.} [input_signal] and [output_signal] are ordinary
    event signals. On the normal path, [input] is called once for every instant
    that is actually opened, after the optional [`Before_step] snapshot callback
    and before reactive stepping. [Some value] makes [input_signal] present
    before scheduled tasks run; [None] performs no host emission. [input]
    defaults to a callback that always returns [None].

    The presence of an [input] callback does not by itself keep [execute]
    running, and the bound does not force input polling. In particular, a
    continuation suspended only by {!val:await} or {!val:await_immediate} on an
    absent signal does not schedule another instant. A host-driven service must
    keep a task scheduled for later instants, for example with a {!val:pause}
    loop or a persistent {!val:when_} guard.

    After the reaction reaches quiescence, [output] is called once with the
    value of [output_signal] if that signal is present; otherwise it is not
    called. [output] defaults to a no-op. Output runs before signal finalization,
    including the end-of-instant preemption performed by {!val:watch}.

    {b Callbacks and failures.} [input], [output], and [on_snapshot] are
    synchronous host callbacks. They run on the Domain calling [execute],
    outside Tempo task scheduling, and must not perform Tempo effects. If a
    callback blocks, [execute] blocks. If it raises, its exception escapes
    [execute] and no later phase of that instant is run; ordinary OCaml side
    effects already performed are not rolled back.

    An exception that escapes the top-level Tempo process likewise terminates
    [execute]. If it escapes during reactive stepping, [output] and the remaining
    snapshot and finalization phases of that instant are skipped. Catch it
    inside the Tempo process when the current instant must still be flushed to
    the host.

    When [execute] returns, normally or exceptionally, all suspended
    continuations owned by that invocation are abandoned and its signals
    expire. Shutdown does not unwind those suspended continuations and does not
    guarantee execution of cleanup handlers stored in them.

    When [on_snapshot] is provided, the runtime emits an experimental
    {!type:runtime_snapshot} at the phases described by
    {!type:snapshot_phase}.

    {b Domains.} Sequential and nested invocations are supported, subject to
    signal ownership. Concurrent invocations of [execute] on multiple OCaml
    Domains are outside the Tempo 0.3 contract: no correctness or determinism
    guarantee is provided, and applications must serialize them. This does not
    restrict the logical concurrency provided by {!val:parallel}. *)
val execute :
     ?instants:int
  -> ?input:(unit -> 'input option)
  -> ?output:('output -> unit)
  -> ?on_snapshot:(runtime_snapshot -> unit)
  -> ('input signal -> 'output signal -> unit)
  -> unit
