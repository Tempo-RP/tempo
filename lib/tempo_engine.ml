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

open Effect.Deep
open Tempo_types
open Tempo_thread 
open Tempo_task
open Tempo_signal

let log_ctx st =
  Tempo_log.context ~instant:st.debug.instant_counter ~step:st.debug.step_counter

type snapshot_phase =
  [ `Before_step
  | `After_step
  | `After_finalize
  | `After_rollover
  ]

type runtime_snapshot = {
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

let fold_signals_stats (signals : any_signal list) =
  List.fold_left
    (fun (awaiters, guards, kills) (Any s) ->
      ( awaiters + List.length s.awaiters
      , guards + List.length s.guard_waiters
      , kills + List.length s.kill_watchers ))
    (0, 0, 0) signals

let fold_threads_stats (threads : thread_table) =
  Array.fold_left
    (fun (slots, active, suspended) state ->
      match state with
      | None -> (slots, active, suspended)
      | Some ts ->
          ( slots + 1
          , active + ts.active
          , suspended + ts.suspended ))
    (0, 0, 0) threads.states

let fold_kill_context_stats (st : scheduler_state) =
  let refs = ref 0 in
  let nodes = ref 0 in
  let max_depth = ref 0 in
  let rec walk depth ctx =
    refs := !refs + 1;
    if depth > !max_depth then max_depth := depth;
    match ctx with
    | KEmpty -> ()
    | KNode node ->
        nodes := !nodes + 1;
        walk (depth + 1) node.parent
  in
  let walk_task (t : task) = walk 0 t.kill_ctx in
  let walk_signal (Any s) =
    let walk_resume_plan : type a. a resume_plan -> unit = function
      | Resume_stable_now r
      | Resume_stable_next r -> walk 0 r.resume_kill_ctx
      | Resume_spawn_now r
      | Resume_spawn_next r -> walk 0 r.resume_kill_ctx
    in
    List.iter walk_resume_plan s.awaiters;
    List.iter (fun (w : kill_watcher) -> walk 0 w.kill_ctx) s.kill_watchers
  in
  worklist_iter walk_task st.current;
  worklist_iter walk_task st.next_instant;
  List.iter walk_task st.blocked;
  List.iter walk_signal st.signals;
  Array.iter
    (function
      | None -> ()
      | Some ts ->
          List.iter
            (fun (w : join_waiter) -> walk 0 w.kill_ctx)
            ts.waiters)
    st.threads.states;
  (!refs, !nodes, !max_depth)

let make_snapshot (st : scheduler_state) (phase : snapshot_phase) =
  let awaiters, guard_waiters, kill_watchers = fold_signals_stats st.signals in
  let active_thread_slots, total_active_threads, total_suspended_threads =
    fold_threads_stats st.threads
  in
  let kill_context_refs, kill_context_nodes, kill_context_max_depth =
    fold_kill_context_stats st
  in
  let gc = Gc.quick_stat () in
  {
    phase
  ; instant = st.debug.instant_counter
  ; step = st.debug.step_counter
  ; current_q = worklist_length st.current
  ; blocked_q = List.length st.blocked
  ; next_q = worklist_length st.next_instant
  ; tracked_signals = List.length st.signals
  ; awaiters
  ; guard_waiters
  ; kill_watchers
  ; live_tasks = total_active_threads + total_suspended_threads
  ; kill_context_refs
  ; kill_context_nodes
  ; kill_context_max_depth
  ; active_thread_slots
  ; total_active_threads
  ; total_suspended_threads
  ; task_counter = st.debug.task_counter
  ; thread_counter = st.thread_counter
  ; signal_counter = st.debug.sig_counter
  ; free_task_count = List.length st.free_tasks + List.length st.retired_tasks
  ; gc_minor_words = gc.Gc.minor_words
  ; gc_promoted_words = gc.Gc.promoted_words
  ; gc_major_words = gc.Gc.major_words
  ; gc_minor_collections = gc.Gc.minor_collections
  ; gc_major_collections = gc.Gc.major_collections
  ; gc_heap_words = gc.Gc.heap_words
  ; gc_live_words = gc.Gc.live_words
  ; gc_free_words = gc.Gc.free_words
  ; gc_top_heap_words = gc.Gc.top_heap_words
  ; gc_stack_size = gc.Gc.stack_size
  ; cum_tasks_created = st.metrics.tasks_created
  ; cum_tasks_disposed = st.metrics.tasks_disposed
  ; cum_tasks_enqueued_now = st.metrics.tasks_enqueued_now
  ; cum_tasks_enqueued_next = st.metrics.tasks_enqueued_next
  ; cum_tasks_blocked = st.metrics.tasks_blocked
  ; cum_signals_created = st.metrics.signals_created
  ; cum_signals_tracked = st.metrics.signals_tracked
  ; cum_signals_untracked = st.metrics.signals_untracked
  ; cum_awaiters_registered = st.metrics.awaiters_registered
  ; cum_awaiters_resumed = st.metrics.awaiters_resumed
  ; cum_awaiters_pruned = st.metrics.awaiters_pruned
  ; cum_guard_waiter_registrations = st.metrics.guard_waiter_registrations
  ; cum_guard_waiter_wakeups = st.metrics.guard_waiter_wakeups
  ; cum_kill_watchers_registered = st.metrics.kill_watchers_registered
  ; cum_kill_watchers_fired = st.metrics.kill_watchers_fired
  ; cum_kill_watchers_pruned = st.metrics.kill_watchers_pruned
  }

let emit_snapshot on_snapshot st phase =
  match on_snapshot with
  | None -> ()
  | Some f -> f (make_snapshot st phase)

let handle_task : scheduler_state -> task -> unit =
  fun st t ->
    let debug_enabled = Tempo_log.should_log ~level:Logs.Debug () in
    let ctx = log_ctx st in
    let parent_thread = t.thread in
    let parent_guards = task_guards t in
    let parent_kill_ctx = task_kill_ctx t in
    let parent_alive () = kill_context_alive parent_kill_ctx in
    t.generation <- t.generation + 1;
    let generation = t.generation in
    t.retained <- false;
    st.running_task <- Some t;
    let dlog ?task ?signal scope fmt =
      if debug_enabled then
        Tempo_log.log ?task ?signal (ctx) scope fmt
      else Format.ifprintf Format.std_formatter fmt
    in
    let handle_owned_signal : type emit agg mode result.
        (emit, agg, mode) signal_core ->
        (result, unit) continuation ->
        (unit -> unit) ->
        unit =
     fun s k handle ->
      match Tempo_task.ensure_signal_owner st s with
      | () -> handle ()
      | exception exn ->
          let backtrace = Printexc.get_raw_backtrace () in
          discontinue_with_backtrace k exn backtrace
    in
    let handle_done () =
      dlog ~task:t.t_id "step" "task done | task=#%d thread=#%d" t.t_id t.thread
    in
    let handle_new_signal : type a.
        ((a, a, event) signal_core, unit) continuation -> unit =
     fun k ->
      let s = fresh_event_signal st in
      dlog ~task:t.t_id ~signal:s.s_id "step"
        "create event signal | task=#%d | signal=#%d" t.t_id s.s_id;
      continue k s
    in
    let handle_new_signal_agg : type emit agg.
        agg ->
        (agg -> emit -> agg) ->
        ((emit, agg, aggregate) signal_core, unit) continuation ->
        unit =
     fun initial combine k ->
      let s = fresh_aggregate_signal st ~initial ~combine in
      dlog ~task:t.t_id ~signal:s.s_id "step"
        "create aggregate signal | task=#%d signal=#%d" t.t_id s.s_id;
      continue k s
    in
    let handle_emit : type emit agg mode.
        (emit, agg, mode) signal_core ->
        emit ->
        (unit, unit) continuation ->
        unit =
     fun s v k ->
      dlog ~task:t.t_id ~signal:s.s_id "step"
        "emit | task=#%d signal=#%d" t.t_id s.s_id;
      match update_signal st s v with
      | () -> continue k ()
      | exception exn ->
          let backtrace = Printexc.get_raw_backtrace () in
          discontinue_with_backtrace k exn backtrace
    in
    let handle_await : type emit agg mode.
        (emit, agg, mode) signal_core -> (agg, unit) continuation -> unit =
     fun s k ->
      let current_task =
        match st.running_task with
        | Some task -> task
        | None -> t
      in
      let resume_stable v =
        reset_task ~parent:current_task current_task parent_thread parent_guards
          parent_kill_ctx
          (fun () -> continue k v);
        enqueue_next st current_task;
        dlog ~task:current_task.t_id ~signal:s.s_id "step"
          "resume await | task=#%d signal=#%d" current_task.t_id s.s_id
      in
      let resume_spawn v =
        let new_task =
          spawn_next ~parent:t st parent_thread parent_guards parent_kill_ctx
            (fun () -> continue k v)
        in
        dlog ~task:new_task.t_id ~signal:s.s_id "step"
          "resume await | task=#%d -> task=#%d signal=#%d"
          t.t_id new_task.t_id s.s_id
      in
      let stable_resume task =
        {
          resume_continue = (fun v -> continue k v)
        ; resume_task = task
        ; resume_thread = parent_thread
        ; resume_guards = parent_guards
        ; resume_kill_ctx = parent_kill_ctx
        }
      in
      let spawned_resume parent =
        {
          resume_continue = (fun v -> continue k v)
        ; resume_parent = parent
        ; resume_thread = parent_thread
        ; resume_guards = parent_guards
        ; resume_kill_ctx = parent_kill_ctx
        }
      in
      let register_stable_awaiter () =
        current_task.retained <- true;
        register_awaiter st s
          (Resume_stable_next (stable_resume current_task))
      in
      let register_spawn_awaiter () =
        mark_suspended st.threads parent_thread;
        register_awaiter st s
          (Resume_spawn_next (spawned_resume t))
      in
      if s.present then
        match s.kind with
        | Event_signal ->
            dlog ~task:t.t_id ~signal:s.s_id "step"
              "await present | task=#%d signal=#%d -> resume next instant"
              t.t_id s.s_id;
            if current_task.thread = parent_thread then begin
              current_task.retained <- true;
              resume_stable (Option.get s.value)
            end else
              resume_spawn (Option.get s.value)
        | Aggregate_signal _ ->
            if current_task.thread = parent_thread then register_stable_awaiter ()
            else register_spawn_awaiter ()
      else begin
        dlog ~task:t.t_id ~signal:s.s_id "step"
          "await absent | task=#%d signal`#%d -> enqueue" t.t_id s.s_id;
        if current_task.thread = parent_thread then register_stable_awaiter ()
        else register_spawn_awaiter ()
      end
    in
    let handle_await_immediate : type a.
        (a, a, event) signal_core -> (a, unit) continuation -> unit =
     fun s k ->
      if s.present then
        match s.value with
        | Some v ->
            dlog ~task:t.t_id ~signal:s.s_id "step"
              "await_immediate present | task=#%d signal`#%d -> resume now"
              t.t_id s.s_id;
            continue k v
        | None -> failwith "Error : present but no value"
      else
        let current_task =
          match st.running_task with
          | Some task -> task
          | None -> t
        in
        let stable_resume task =
          {
            resume_continue = (fun v -> continue k v)
          ; resume_task = task
          ; resume_thread = parent_thread
          ; resume_guards = parent_guards
          ; resume_kill_ctx = parent_kill_ctx
          }
        in
        let spawned_resume parent =
          {
            resume_continue = (fun v -> continue k v)
          ; resume_parent = parent
          ; resume_thread = parent_thread
          ; resume_guards = parent_guards
          ; resume_kill_ctx = parent_kill_ctx
          }
        in
        dlog ~task:t.t_id ~signal:s.s_id "step"
          "await immediate absent | task=#%d signal`#%d -> save continuation"
          t.t_id s.s_id;
        if current_task.thread = parent_thread then begin
          current_task.retained <- true;
          register_awaiter st s
            (Resume_stable_now (stable_resume current_task))
        end else begin
          mark_suspended st.threads parent_thread;
          register_awaiter st s
            (Resume_spawn_now (spawned_resume t))
        end
    in
    let handle_pause : (unit, unit) continuation -> unit =
     fun k ->
      let current_task =
        match st.running_task with
        | Some task -> task
        | None -> t
      in
      if parent_guards <> [] then
        let new_task =
          spawn_next ~parent:t st parent_thread parent_guards parent_kill_ctx
            (fun () -> continue k ())
        in
        dlog ~task:new_task.t_id "step"
          "pause | task=#%d resume next instant as task #%d"
          current_task.t_id new_task.t_id
      else if current_task.thread = parent_thread then begin
        current_task.retained <- true;
        reset_task ~parent:current_task current_task parent_thread parent_guards
          parent_kill_ctx
          (fun () -> continue k ());
        enqueue_next st current_task;
        dlog ~task:current_task.t_id "step"
          "pause | task=#%d resume next instant" current_task.t_id
      end else
        let new_task =
          spawn_next st parent_thread parent_guards parent_kill_ctx
            (fun () -> continue k ())
        in
        dlog ~task:new_task.t_id "step"
          "pause | task=#%d resume next instant as task #%d"
          current_task.t_id new_task.t_id
    in
    let handle_parallel : (unit -> unit) list -> (unit, unit) continuation -> unit =
     fun procs k ->
      let current_task =
        match st.running_task with
        | Some task -> task
        | None -> t
      in
      match procs with
      | [] -> continue k ()
      | _ ->
          (* A parallel failure is weakly fail-fast. Branches keep running
             until the current reaction reaches quiescence. The failure
             barrier then kills their shared scope and discontinues [k] in the
             same instant. Pending barriers are resolved deepest-first by
             [stabilize_reaction], so nested failures cross one lexical
             [parallel] boundary at a time. *)
          let parallel_thread = Tempo_thread.new_thread_id st in
          let parallel_kill = Tempo_low_level.new_kill () in
          let parallel_kill_ctx =
            push_kill_context parallel_kill parent_kill_ctx
          in
          let failure = ref None in
          let failure_registered = ref false in
          let settled = ref false in
          let close_parallel () =
            if !settled then false
            else begin
              settled := true;
              parallel_kill.alive := false;
              parallel_kill.cleanup <- None;
              true
            end
          in
          let failure_action () =
            match !failure with
            | None -> invalid_arg "parallel failure barrier without exception"
            | Some (_, exn, backtrace) ->
                discontinue_with_backtrace k exn backtrace
          in
          let schedule_spawn outcome action =
            let t' =
              spawn_now ~parent:t st parent_thread parent_guards parent_kill_ctx
                action
            in
            dlog ~task:t.t_id "step.parallel"
              "parallel resume (%s) | parent task=#%d as task=#%d"
              outcome t.t_id t'.t_id
          in
          let schedule_stable outcome action =
            current_task.retained <- true;
            reset_task ~parent:current_task current_task parent_thread
              parent_guards parent_kill_ctx action;
            enqueue_now st current_task;
            dlog ~task:current_task.t_id "step.parallel"
              "parallel resume (%s) | parent task=#%d" outcome
              current_task.t_id
          in
          let resume_spawn () =
            if close_parallel () then
              schedule_spawn "normal" (fun () -> continue k ())
          in
          let resume_stable () =
            if close_parallel () then
              schedule_stable "normal" (fun () -> continue k ())
          in
          let fail_spawn () =
            if close_parallel () && parent_alive () then
              schedule_spawn "exception" failure_action
          in
          let fail_stable () =
            if close_parallel () && parent_alive () then
              schedule_stable "exception" failure_action
          in
          let stable_parent = current_task.thread = parent_thread in
          parallel_kill.cleanup <-
            Some (if stable_parent then fail_stable else fail_spawn);
          let resolve_failure () =
            if not !settled then
              if parent_alive () then Tempo_low_level.abort_kill parallel_kill
              else ignore (close_parallel ())
          in
          let record_failure index exn backtrace =
            (match !failure with
            | Some (recorded_index, _, _) when recorded_index <= index -> ()
            | None | Some _ -> failure := Some (index, exn, backtrace));
            if not !failure_registered then begin
              failure_registered := true;
              let depth = kill_context_depth parallel_kill_ctx in
              st.pending_parallel_failures <-
                (depth, resolve_failure) :: st.pending_parallel_failures
            end
          in
          List.iteri
            (fun index proc ->
              let guarded_proc () =
                match proc () with
                | () -> ()
                | exception exn ->
                    let backtrace = Printexc.get_raw_backtrace () in
                    record_failure index exn backtrace
              in
              let child =
                spawn_now ~parent:t st parallel_thread parent_guards
                  parallel_kill_ctx guarded_proc
              in
              dlog ~task:t.t_id "step.parallel"
                "parallel spawn | parent task=#%d thread=#%d child task=#%d"
                t.t_id parallel_thread child.t_id)
            procs;
          let join_complete resume =
            match !failure with
            | None -> resume ()
            | Some _ -> ()
          in
          if stable_parent then begin
            current_task.retained <- true;
            add_stable_join_waiter st.threads parallel_thread
              ~kill_ctx:parallel_kill_ctx
              ~cancel:(fun () ->
                if not !settled then dispose_task st current_task)
              (fun () -> join_complete resume_stable)
          end else begin
            mark_suspended st.threads parent_thread;
            add_spawn_join_waiter st.threads parallel_thread
              ~waiter_thread:parent_thread ~kill_ctx:parallel_kill_ctx
              (fun () -> join_complete resume_spawn)
          end
    in
    let handle_when : type emit agg mode result.
        (emit, agg, mode) signal_core ->
        (unit -> result) ->
        (result, unit) continuation ->
        unit =
     fun s body k ->
      (* Safety invariant for [when_]:
         - never execute [body] inline in this handler frame because [body]
           can perform effects (await/pause/when_) that must be handled by
           the scheduler task trampoline;
         - always keep [s] in the scheduled task guard set, even if [s] is
           already present, so continuations after pause/await stay guarded
           in later instants;
         - resume [k] with the body's result, or discontinue it with the body's
           exception, so the caller continues under its original guard set. *)
      let current_task =
        match st.running_task with
        | Some task -> task
        | None -> t
      in
      let guarded_run () =
        match body () with
        | result ->
            if parent_alive () then begin
              dlog ~task:current_task.t_id "step"
                "when exit | task=#%d -> continue" current_task.t_id;
              continue k result
            end
        | exception exn ->
            let backtrace = Printexc.get_raw_backtrace () in
            if parent_alive () then
              discontinue_with_backtrace k exn backtrace
      in
      if current_task.thread = parent_thread then begin
        current_task.retained <- true;
        reset_task ~parent:current_task current_task parent_thread
          (Any s :: parent_guards)
          parent_kill_ctx guarded_run;
        enqueue_now st current_task;
        dlog ~task:current_task.t_id ~signal:s.s_id "step"
          "when enter | task=#%d signal=#%d" current_task.t_id s.s_id
      end else
        let guard_task =
          spawn_now ~parent:t st parent_thread (Any s :: parent_guards)
            parent_kill_ctx guarded_run
        in
        dlog ~task:guard_task.t_id ~signal:s.s_id "step"
          "when enter | task=#%d signal=#%d -> schedule task=#%d"
          t.t_id s.s_id guard_task.t_id
    in
    let handle_watch : type emit agg mode.
        (emit, agg, mode) signal_core ->
        (unit -> unit) ->
        (unit, unit) continuation ->
        unit =
     fun s body k ->
      (* Safety invariants for [watch]:
         - schedule [body] through the task trampoline, including when an
           ancestor already watches [s];
         - resume or discontinue [k] under the caller's guards and kill
           context, never under the body's new kill context;
         - on normal or exceptional completion, disarm the watcher before
           scheduling [k], so its one-shot continuation cannot be reused at
           instant closure;
         - preemption only schedules the normal next-instant continuation. It
           deliberately does not discontinue killed body continuations. *)
      if kill_context_has_watch_signal parent_kill_ctx s.s_id then begin
        let current_task =
          match st.running_task with
          | Some task -> task
          | None -> t
        in
        let resume_spawn () =
          let t' =
            spawn_now ~parent:t st parent_thread parent_guards parent_kill_ctx
              (fun () -> continue k ())
          in
          dlog ~task:t.t_id "step"
            "watch elided exit (normal) | task=#%d -> task=#%d"
            t.t_id t'.t_id
        in
        let resume_stable () =
          match st.running_task with
          | Some task when task.thread = parent_thread ->
              task.retained <- true;
              reset_task ~parent:task task parent_thread parent_guards
                parent_kill_ctx
                (fun () -> continue k ());
              enqueue_now st task;
              dlog ~task:task.t_id "step"
                "watch elided exit (normal) | task=#%d" task.t_id
          | _ -> resume_spawn ()
        in
        let discontinue_spawn exn backtrace =
          let t' =
            spawn_now ~parent:t st parent_thread parent_guards parent_kill_ctx
              (fun () -> discontinue_with_backtrace k exn backtrace)
          in
          dlog ~task:t.t_id "step"
            "watch elided exit (exception) | task=#%d -> task=#%d"
            t.t_id t'.t_id
        in
        let discontinue_stable exn backtrace =
          match st.running_task with
          | Some task when task.thread = parent_thread ->
              task.retained <- true;
              reset_task ~parent:task task parent_thread parent_guards
                parent_kill_ctx
                (fun () -> discontinue_with_backtrace k exn backtrace);
              enqueue_now st task;
              dlog ~task:task.t_id "step"
                "watch elided exit (exception) | task=#%d" task.t_id
          | _ -> discontinue_spawn exn backtrace
        in
        let elided_body resume discontinue =
          match body () with
          | () -> if parent_alive () then resume ()
          | exception exn ->
              let backtrace = Printexc.get_raw_backtrace () in
              if parent_alive () then discontinue exn backtrace
        in
        if current_task.thread = parent_thread then begin
          current_task.retained <- true;
          reset_task ~parent:current_task current_task parent_thread parent_guards
            parent_kill_ctx
            (fun () -> elided_body resume_stable discontinue_stable);
          enqueue_now st current_task;
          dlog ~task:current_task.t_id ~signal:s.s_id "step"
            "watch elided (ancestor already watches signal) | task=#%d signal=#%d"
            current_task.t_id s.s_id
        end else
          let t' =
            spawn_now ~parent:t st parent_thread parent_guards parent_kill_ctx
              (fun () -> elided_body resume_spawn discontinue_spawn)
          in
          dlog ~task:t.t_id ~signal:s.s_id "step"
            "watch elided (ancestor already watches signal) | task=#%d signal=#%d -> task=#%d"
            t.t_id s.s_id t'.t_id
      end
      else
        let current_task =
          match st.running_task with
          | Some task -> task
          | None -> t
        in
        let kk = Tempo_low_level.new_kill () in
        let resumed = ref false in
        let close_watch () =
          if !resumed then false
          else begin
            resumed := true;
            disarm_kill_watcher st s kk;
            true
          end
        in
        let resume_next () =
          if close_watch () then begin
            let t' =
              spawn_next ~parent:t st parent_thread parent_guards parent_kill_ctx
                (fun () -> continue k ())
            in
            dlog ~task:t.t_id "step"
              "watch exit (killed) | task=#%d -> task=#%d" t.t_id t'.t_id
          end
        in
        let schedule_now_spawn outcome run =
          let t' =
            spawn_now ~parent:t st parent_thread parent_guards parent_kill_ctx
              run
          in
          dlog ~task:t.t_id "step"
            "watch exit (%s) | task=#%d -> task=#%d" outcome t.t_id t'.t_id
        in
        let schedule_now_stable outcome run =
          match st.running_task with
          | Some task when task.thread = parent_thread ->
              task.retained <- true;
              reset_task ~parent:task task parent_thread parent_guards
                parent_kill_ctx run;
              enqueue_now st task;
              dlog ~task:task.t_id "step"
                "watch exit (%s) | task=#%d" outcome task.t_id
          | _ -> schedule_now_spawn outcome run
        in
        let resume_now () =
          if close_watch () then
            schedule_now_spawn "normal" (fun () -> continue k ())
        in
        let resume_now_stable () =
          if close_watch () then
            schedule_now_stable "normal" (fun () -> continue k ())
        in
        let discontinue_now exn backtrace =
          if close_watch () then
            schedule_now_spawn "exception" (fun () ->
                discontinue_with_backtrace k exn backtrace)
        in
        let discontinue_now_stable exn backtrace =
          if close_watch () then
            schedule_now_stable "exception" (fun () ->
                discontinue_with_backtrace k exn backtrace)
        in
        kk.cleanup <- Some resume_next;
        register_kill_watcher st s kk parent_kill_ctx;
        let guarded_body resume discontinue =
          match body () with
          | () -> resume ()
          | exception exn ->
              let backtrace = Printexc.get_raw_backtrace () in
              discontinue exn backtrace
        in
        let body_kill_ctx =
          push_kill_context ~watch_signal_id:s.s_id kk parent_kill_ctx
        in
        if current_task.thread = parent_thread then begin
          current_task.retained <- true;
          reset_task ~parent:current_task current_task parent_thread parent_guards
            body_kill_ctx
            (fun () -> guarded_body resume_now_stable discontinue_now_stable);
          enqueue_now st current_task;
          dlog ~task:current_task.t_id ~signal:s.s_id "step"
            "watch enter | task=#%d signal=#%d" current_task.t_id s.s_id
        end else
          let t' =
            spawn_now ~parent:t st parent_thread parent_guards body_kill_ctx
              (fun () -> guarded_body resume_now discontinue_now)
          in
          dlog ~task:t.t_id ~signal:s.s_id "step"
            "watch enter | task=#%d signal=#%d -> task=#%d"
            t.t_id s.s_id t'.t_id
    in
    let run_task () =
      match t.run () with
      (* Task termination *)
      | () -> handle_done ()
      (* Signal allocation and emission *)
      | effect (New_signal ()), k -> handle_new_signal k
      | effect (New_signal_agg (initial, combine)), k ->
          handle_new_signal_agg initial combine k
      | effect (Emit (s, v)), k ->
          handle_owned_signal s k (fun () -> handle_emit s v k)
      (* Suspension / resumption on signals *)
      | effect (Await s), k ->
          handle_owned_signal s k (fun () -> handle_await s k)
      | effect (Await_immediate s), k ->
          handle_owned_signal s k (fun () -> handle_await_immediate s k)
      (* Scheduling and thread control *)
      | effect Pause, k -> handle_pause k
      | effect (Parallel procs), k -> handle_parallel procs k
      (* Guarded and preemptive control operators *)
      | effect (When (s, body)), k ->
          handle_owned_signal s k (fun () -> handle_when s body k)
      | effect (Watch (s, body)), k ->
          handle_owned_signal s k (fun () -> handle_watch s body k)
    in
    let cleanup () =
      if t.generation = generation && not t.retained then dispose_task st t
    in
    try Fun.protect ~finally:cleanup run_task with
    | Aborted -> ()

let rec step : scheduler_state -> unit =
  fun st ->
    let debug_enabled = Tempo_log.should_log ~level:Logs.Debug () in
    let ctx = log_ctx st in
    let counter = if debug_enabled then Some (Mtime_clock.counter ()) else None in
    let record_step_metrics () =
      match counter with
      | Some c ->
          let span = Mtime_clock.count c in
          Tempo_log.log_step_summary (ctx) span;
          Tempo_log.record_duration "step" span
      | None -> ()
    in
    if debug_enabled then begin
      Tempo_log.log_banner_step (ctx);
      Tempo_log.log_snapshot (ctx)
        ~current:(Tempo_log.snapshot_worklist st.current)
        ~blocked:st.blocked
        ~next:(Tempo_log.snapshot_worklist st.next_instant)
        ~signals:st.signals
    end;
    st.debug.step_counter <- st.debug.step_counter + 1;
      let rec take_next () =
        if worklist_is_empty st.current then
          begin 
            Tempo_log.log ~level:Logs.Debug (ctx) "step"
              "queue empty | stop current instant";
            record_step_metrics ();
            None
          end
        else
          let t = worklist_take st.current in
          t.queued <- false;
          if task_kills_alive t then Some t
          else (
            dispose_task st t;
            take_next ())
      in
      match take_next () with
      | None ->
          record_step_metrics ()
      | Some t ->
          if debug_enabled then Tempo_log.log_pick (ctx) t;
          let continue =
            if task_has_guards t && not (task_guards_ok t) then begin
          if debug_enabled then begin
                let missing = Tempo_signal.missing_guards (task_guards t) in
                Tempo_log.log_block (ctx) t missing;
                block_on_guards_with_missing st t missing
              end else
                block_on_guards st t;
              fun () -> step st
            end else begin
              handle_task st t;
              fun () -> step st
            end
          in
          if debug_enabled then
            Tempo_log.log_snapshot (ctx)
              ~current:(Tempo_log.snapshot_worklist st.current)
              ~blocked:st.blocked
              ~next:(Tempo_log.snapshot_worklist st.next_instant)
              ~signals:st.signals;
          record_step_metrics ();
          continue ()

let rec stabilize_reaction (st : scheduler_state) =
  step st;
  match st.pending_parallel_failures with
  | [] -> ()
  | pending ->
      let deepest =
        List.fold_left (fun acc (depth, _) -> max acc depth) min_int pending
      in
      let current_wave, later =
        List.partition (fun (depth, _) -> depth = deepest) pending
      in
      st.pending_parallel_failures <- later;
      List.iter (fun (_, resolve) -> resolve ()) (List.rev current_wave);
      prune_dead_join_waiters st.threads (current_kill_epoch ());
      stabilize_reaction st

let rec run_instant : (runtime_snapshot -> unit) option -> (unit -> unit) ->
    (unit -> unit) -> scheduler_state -> int option -> unit =
  fun on_snapshot before_step after_step st remaining ->
    match remaining with
    | Some n when n <= 0 -> ()
    | _ ->
        let debug_enabled = Tempo_log.should_log ~level:Logs.Debug () in
        let ctx = log_ctx st in
        if debug_enabled then begin
          Tempo_log.log_banner_instant (ctx) st.debug.instant_counter;
          Tempo_log.log_snapshot (ctx)
            ~current:(Tempo_log.snapshot_worklist st.current)
            ~blocked:st.blocked
            ~next:(Tempo_log.snapshot_worklist st.next_instant)
            ~signals:st.signals
        end;
        let counter = if debug_enabled then Some (Mtime_clock.counter ()) else None in
        st.blocked <- [];
        st.free_tasks <- List.rev_append st.retired_tasks st.free_tasks;
        st.retired_tasks <- [];
        emit_snapshot on_snapshot st `Before_step;
        before_step ();
        stabilize_reaction st;
        after_step ();
        emit_snapshot on_snapshot st `After_step;
        (match counter with
        | Some c ->
            let span = Mtime_clock.count c in
            Tempo_log.log (ctx) "instant" "instant=%a" Tempo_log.pp_span span;
            Tempo_log.record_duration "instant" span
        | None -> ());
        finalize_signals st;
        prune_dead_join_waiters st.threads (current_kill_epoch ());
        List.iter
          ( fun (t : task) ->
              if t.blocked then begin
                t.blocked <- false;
                if task_kills_alive t then enqueue_next st t
                else dispose_task st t
              end )
          st.blocked;
          emit_snapshot on_snapshot st `After_finalize;
          st.debug.instant_counter <- st.debug.instant_counter + 1;
          st.debug.step_counter <- 0;
          if worklist_is_empty st.next_instant then begin
              if debug_enabled then
                Tempo_log.log ~level:Logs.Debug (ctx) "tasks"
                  "no more tasks | for next instant -> stop"
          end
          else begin
              let survivors = ref 0 in
              worklist_iter_lifo
                (fun t ->
                  if task_kills_alive t then begin
                    incr survivors;
                    enqueue_now st t
                  end else dispose_task st t)
                st.next_instant;
              worklist_clear st.next_instant;
              if debug_enabled then
                Tempo_log.log (ctx) "instant"
                  "rollover tasks | moving %d tasks to next instant"
                  !survivors;
              emit_snapshot on_snapshot st `After_rollover;
              run_instant on_snapshot before_step after_step st
                (Option.map pred remaining)
          end

let create_scheduler_state () = 
  let metrics =
    Tempo_types.
      {
        tasks_created = 0
      ; tasks_disposed = 0
      ; tasks_enqueued_now = 0
      ; tasks_enqueued_next = 0
      ; tasks_blocked = 0
      ; signals_created = 0
      ; signals_tracked = 0
      ; signals_untracked = 0
      ; awaiters_registered = 0
      ; awaiters_resumed = 0
      ; awaiters_pruned = 0
      ; guard_waiter_registrations = 0
      ; guard_waiter_wakeups = 0
      ; kill_watchers_registered = 0
      ; kill_watchers_fired = 0
      ; kill_watchers_pruned = 0
      }
  in
  { runtime_token   = { active = Atomic.make true }
    ;current        = create_worklist ()
    ;next_instant   = create_worklist ()
    ;pending_parallel_failures = []
    ;blocked         = []
    ;free_tasks      = []
    ;retired_tasks   = []
    ;running_task    = None
    ;signals         = []
    ;thread_counter  = 0
    ;debug           =
      { sig_counter     = 0
      ; task_counter    = 1
      ; step_counter    = 0
      ; instant_counter = 0 }
    ;threads         = Tempo_thread.create ()
    ;metrics         = metrics
  }

let execute ?instants ?(input = fun () -> None) ?(output = fun _ -> ())
    ?on_snapshot initial =
  let st = create_scheduler_state () in
  Fun.protect
    ~finally:(fun () -> Tempo_signal.close_runtime st)
    (fun () ->
      let input_signal = fresh_event_signal st in
      let output_signal = fresh_event_signal st in
      let before_step () =
        match input () with
        | None -> ()
        | Some payload -> emit_event_from_host st input_signal payload
      in
      let after_step () =
        match output_signal.value with
        | Some value -> output value
        | None -> ()
      in
      let thread = Tempo_thread.new_thread_id st in
      let initial_task =
        spawn_now st thread [] empty_kill_context
          (fun () -> initial input_signal output_signal)
      in
      Tempo_log.log_banner (log_ctx st) "execute"
        "runtime start | schedule initial task=#%d" initial_task.t_id;
      run_instant on_snapshot before_step after_step st instants;
      Tempo_log.log_duration_summary ())
