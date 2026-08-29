let as_event_core (signal : int Tempo.signal) :
    (int, int, Tempo.event) Tempo.signal_core =
  signal

let as_aggregate_core (signal : (int, int) Tempo.agg_signal) :
    (int, int, Tempo.aggregate) Tempo.signal_core =
  signal

let inspect_snapshot (snapshot : Tempo.runtime_snapshot) =
  let (_ : Tempo.snapshot_phase) = snapshot.phase in
  ignore snapshot.instant;
  ignore snapshot.step;
  ignore snapshot.current_q;
  ignore snapshot.blocked_q;
  ignore snapshot.next_q;
  ignore snapshot.tracked_signals;
  ignore snapshot.awaiters;
  ignore snapshot.guard_waiters;
  ignore snapshot.kill_watchers;
  ignore snapshot.live_tasks;
  ignore snapshot.kill_context_refs;
  ignore snapshot.kill_context_nodes;
  ignore snapshot.kill_context_max_depth;
  ignore snapshot.active_thread_slots;
  ignore snapshot.total_active_threads;
  ignore snapshot.total_suspended_threads;
  ignore snapshot.task_counter;
  ignore snapshot.thread_counter;
  ignore snapshot.signal_counter;
  ignore snapshot.free_task_count;
  ignore snapshot.gc_minor_words;
  ignore snapshot.gc_promoted_words;
  ignore snapshot.gc_major_words;
  ignore snapshot.gc_minor_collections;
  ignore snapshot.gc_major_collections;
  ignore snapshot.gc_heap_words;
  ignore snapshot.gc_live_words;
  ignore snapshot.gc_free_words;
  ignore snapshot.gc_top_heap_words;
  ignore snapshot.gc_stack_size;
  ignore snapshot.cum_tasks_created;
  ignore snapshot.cum_tasks_disposed;
  ignore snapshot.cum_tasks_enqueued_now;
  ignore snapshot.cum_tasks_enqueued_next;
  ignore snapshot.cum_tasks_blocked;
  ignore snapshot.cum_signals_created;
  ignore snapshot.cum_signals_tracked;
  ignore snapshot.cum_signals_untracked;
  ignore snapshot.cum_awaiters_registered;
  ignore snapshot.cum_awaiters_resumed;
  ignore snapshot.cum_awaiters_pruned;
  ignore snapshot.cum_guard_waiter_registrations;
  ignore snapshot.cum_guard_waiter_wakeups;
  ignore snapshot.cum_kill_watchers_registered;
  ignore snapshot.cum_kill_watchers_fired;
  ignore snapshot.cum_kill_watchers_pruned

let () =
  let snapshots = ref 0 in
  Tempo.execute ~instants:1
    ~on_snapshot:(fun snapshot ->
      incr snapshots;
      inspect_snapshot snapshot)
    (fun _input _output ->
      let event = Tempo.new_signal () in
      let aggregate = Tempo.new_signal_agg ~initial:0 ~combine:( + ) in
      ignore (as_event_core event);
      ignore (as_aggregate_core aggregate);
      Tempo.emit event 42;
      if Tempo.await_immediate event <> 42 then
        failwith "event payload changed inside its emission instant";
      Tempo.emit aggregate 1;
      Tempo.emit aggregate 2);
  if !snapshots = 0 then failwith "execute did not expose runtime snapshots"
