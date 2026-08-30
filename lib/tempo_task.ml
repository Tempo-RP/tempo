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

open Tempo_types

let kill_epoch = ref 0
let guard_epoch = ref 0

let bump_kill_epoch () =
  kill_epoch := !kill_epoch + 1

let current_kill_epoch () = !kill_epoch

let bump_guard_epoch () =
  guard_epoch := !guard_epoch + 1

let guards_ok_list guards =
  List.for_all (fun (Any s) -> s.present) guards

let kills_alive kills =
  List.for_all (fun k -> !(k.alive)) kills

let empty_kill_context = KEmpty

let watched_signals_of_ctx = function
  | KEmpty -> []
  | KNode node -> node.watched_signals

let push_kill_context ?watch_signal_id (k : kill) (parent : kill_context) =
  let parent_signals = watched_signals_of_ctx parent in
  let watched_signals =
    match watch_signal_id with
    | None -> parent_signals
    | Some sid ->
        if List.mem sid parent_signals then parent_signals else sid :: parent_signals
  in
  KNode
    { kill = k; parent; watched_signals; checked_epoch = -1; alive_cached = true }

let kill_context_has_watch_signal (ctx : kill_context) sid =
  match ctx with
  | KEmpty -> false
  | KNode node -> List.mem sid node.watched_signals

let rec kill_context_alive (ctx : kill_context) =
  match ctx with
  | KEmpty -> true
  | KNode node ->
      if node.checked_epoch = !kill_epoch then node.alive_cached
      else
        let alive = !(node.kill.alive) && kill_context_alive node.parent in
        node.checked_epoch <- !kill_epoch;
        node.alive_cached <- alive;
        alive

let rec kill_context_depth (ctx : kill_context) =
  match ctx with
  | KEmpty -> 0
  | KNode node -> 1 + kill_context_depth node.parent

let kill_effectively_alive (k : kill) = !(k.alive)

let task_guards (t : task) =
  match t.guard_meta with
  | None -> []
  | Some gm -> gm.guards

let task_kill_ctx (t : task) = t.kill_ctx

let task_has_guards (t : task) =
  match t.guard_meta with
  | None -> false
  | Some _ -> true

let task_guards_count (t : task) =
  match t.guard_meta with
  | None -> 0
  | Some gm -> List.length gm.guards

let task_kills_count (t : task) =
  kill_context_depth t.kill_ctx

let task_guards_ok (t : task) =
  match t.guard_meta with
  | None -> true
  | Some gm ->
      if gm.cache_checked_epoch = !guard_epoch then gm.cache_ok
      else
        let ok =
          match gm.guards with
          | [ Any s ] -> s.present
          | _ -> guards_ok_list gm.guards
        in
        gm.cache_checked_epoch <- !guard_epoch;
        gm.cache_ok <- ok;
        ok

let task_kills_alive (t : task) =
  kill_context_alive t.kill_ctx

let create_worklist ?(capacity = 64) () =
  let capacity = max 1 capacity in
  { items = Array.make capacity None; head = 0; tail = 0; size = 0 }

let worklist_length q = q.size

let worklist_is_empty q = q.size = 0

let grow_worklist q =
  let old_items = q.items in
  let old_len = Array.length old_items in
  let new_len = old_len * 2 in
  let new_items = Array.make new_len None in
  for i = 0 to q.size - 1 do
    let old_idx = (q.head + i) mod old_len in
    new_items.(i) <- old_items.(old_idx);
    old_items.(old_idx) <- None
  done;
  q.items <- new_items;
  q.head <- 0;
  q.tail <- q.size

let worklist_add q t =
  if q.size = Array.length q.items then grow_worklist q;
  q.items.(q.tail) <- Some t;
  q.tail <- (q.tail + 1) mod Array.length q.items;
  q.size <- q.size + 1

let worklist_take q =
  if q.size = 0 then raise Queue.Empty
  else
    let idx = q.head in
    match q.items.(idx) with
    | None -> assert false
    | Some t ->
        q.items.(idx) <- None;
        q.head <- (q.head + 1) mod Array.length q.items;
        q.size <- q.size - 1;
        t

let worklist_clear q =
  let len = Array.length q.items in
  for i = 0 to q.size - 1 do
    q.items.((q.head + i) mod len) <- None
  done;
  q.head <- 0;
  q.tail <- 0;
  q.size <- 0

let worklist_iter f q =
  let len = Array.length q.items in
  for i = 0 to q.size - 1 do
    match q.items.((q.head + i) mod len) with
    | None -> ()
    | Some t -> f t
  done

let worklist_iter_lifo f q =
  let len = Array.length q.items in
  for i = q.size - 1 downto 0 do
    match q.items.((q.head + i) mod len) with
    | None -> ()
    | Some t -> f t
  done

let worklist_to_list q =
  let tasks = ref [] in
  worklist_iter (fun t -> tasks := t :: !tasks) q;
  List.rev !tasks

let enqueue_now st t =
  if not t.queued then (
    t.queued <- true;
    t.blocked <- false;
    st.metrics.tasks_enqueued_now <- st.metrics.tasks_enqueued_now + 1;
    worklist_add st.current t)

let enqueue_next st t =
  st.metrics.tasks_enqueued_next <- st.metrics.tasks_enqueued_next + 1;
  worklist_add st.next_instant t

let ensure_signal_owner : type e a m.
    scheduler_state -> (e, a, m) signal_core -> unit =
 fun st s ->
  if s.owner != st.runtime_token then
    if Atomic.get s.owner.active then
      invalid_arg "Tempo: signal belongs to another execution"
    else
      invalid_arg "Tempo: signal belongs to a completed execution"
  else if not (Atomic.get st.runtime_token.active) then
    invalid_arg "Tempo: signal belongs to a completed execution"

let ensure_signal_tracked : type e a m.
    scheduler_state -> (e, a, m) signal_core -> unit =
 fun st s ->
  ensure_signal_owner st s;
  match s.tracking with
  | Signal_tracked -> ()
  | Signal_untracked ->
      s.tracking <- Signal_tracked;
      st.metrics.signals_tracked <- st.metrics.signals_tracked + 1;
      st.signals <- Any s :: st.signals

let guard_meta_exn (t : task) =
  match t.guard_meta with
  | Some gm -> gm
  | None -> invalid_arg "task guard metadata missing"

let clear_missing_guard_cache (t : task) =
  match t.guard_meta with
  | None -> ()
  | Some gm ->
      (match gm.cache_missing_guards with
      | Missing_many tbl -> Hashtbl.reset tbl
      | Missing_none | Missing_one _ -> ());
      gm.cache_missing_guards <- Missing_none;
      gm.cache_missing_count <- 0

let missing_guard_cache_mem (gm : task_guard_meta) sid =
  match gm.cache_missing_guards with
  | Missing_none -> false
  | Missing_one one -> Int.equal sid one
  | Missing_many tbl -> Hashtbl.mem tbl sid

let set_missing_guard_cache_from_unique (t : task)
    (unique_missing : (int, any_signal) Hashtbl.t) =
  let gm = guard_meta_exn t in
  let count = Hashtbl.length unique_missing in
  gm.cache_missing_count <- count;
  match count with
  | 0 -> clear_missing_guard_cache t
  | 1 ->
      let sid = ref (-1) in
      Hashtbl.iter (fun key _ -> sid := key) unique_missing;
      (match gm.cache_missing_guards with
      | Missing_many tbl -> Hashtbl.reset tbl
      | Missing_none | Missing_one _ -> ());
      gm.cache_missing_guards <- Missing_one !sid
  | _ ->
      let tbl =
        match gm.cache_missing_guards with
        | Missing_many tbl ->
            Hashtbl.reset tbl;
            tbl
        | Missing_none | Missing_one _ -> Hashtbl.create (max 4 count)
      in
      Hashtbl.iter (fun sid _ -> Hashtbl.replace tbl sid ()) unique_missing;
      gm.cache_missing_guards <- Missing_many tbl

let register_missing_guards (st : scheduler_state) (t : task)
    (missing : any_signal list) =
  let gm = guard_meta_exn t in
  let unique_missing : (int, any_signal) Hashtbl.t =
    Hashtbl.create (max 4 (List.length missing))
  in
  List.iter
    (fun ((Any s) as signal) ->
      if not (Hashtbl.mem unique_missing s.s_id) then
        Hashtbl.add unique_missing s.s_id signal)
    missing;
  if gm.cache_registration_instant <> st.debug.instant_counter then begin
    gm.cache_registration_instant <- st.debug.instant_counter;
    clear_missing_guard_cache t
  end;
  Hashtbl.iter
    (fun sid signal ->
      if not (missing_guard_cache_mem gm sid) then begin
        let Any s = signal in
        ensure_signal_tracked st s;
        st.metrics.guard_waiter_registrations <-
          st.metrics.guard_waiter_registrations + 1;
        s.guard_waiters <- t :: s.guard_waiters
      end)
    unique_missing;
  set_missing_guard_cache_from_unique t unique_missing

let register_single_missing_guard (st : scheduler_state) (t : task) (Any s) =
  let gm = guard_meta_exn t in
  if gm.cache_registration_instant <> st.debug.instant_counter then begin
    gm.cache_registration_instant <- st.debug.instant_counter;
    clear_missing_guard_cache t
  end;
  if not (missing_guard_cache_mem gm s.s_id) then begin
    ensure_signal_tracked st s;
    st.metrics.guard_waiter_registrations <-
      st.metrics.guard_waiter_registrations + 1;
    s.guard_waiters <- t :: s.guard_waiters
  end;
  (match gm.cache_missing_guards with
  | Missing_many tbl -> Hashtbl.reset tbl
  | Missing_none | Missing_one _ -> ());
  gm.cache_missing_count <- 1;
  gm.cache_missing_guards <- Missing_one s.s_id

let infer_guard_cache parent guards =
  let epoch = !guard_epoch in
  let default () =
    if guards = [] then (epoch, true) else (-1, false)
  in
  match parent with
  | None -> default ()
  | Some p ->
      let p_guards = task_guards p in
      if guards == p_guards then
        if p_guards = [] then (epoch, true)
        else
          (match p.guard_meta with
          | Some pgm when pgm.cache_checked_epoch = epoch ->
              (epoch, pgm.cache_ok)
          | _ -> default ())
      else
        match guards with
        | Any s :: gs when gs == p_guards ->
            if p_guards = [] then (epoch, s.present)
            else
              (match p.guard_meta with
              | Some pgm
                when pgm.cache_checked_epoch = epoch && pgm.cache_ok ->
                  (epoch, s.present)
              | _ -> default ())
        | _ -> default ()

let make_guard_meta ?parent guards =
  if guards = [] then None
  else
    let cache_checked_epoch, cache_ok =
      infer_guard_cache parent guards
    in
    Some
      {
        guards
      ; cache_missing_count = 0
      ; cache_missing_guards = Missing_none
      ; cache_registration_instant = -1
      ; cache_checked_epoch
      ; cache_ok
      }

let create_task ?parent st thread guards kill_ctx run =
  let state = Tempo_thread.ensure st.threads thread in
  if state.completed && state.active = 0 then state.completed <- false;
  state.active <- state.active + 1;
  st.metrics.tasks_created <- st.metrics.tasks_created + 1;
  let t_id = st.debug.task_counter in
  st.debug.task_counter <- st.debug.task_counter + 1;
  let guard_meta = make_guard_meta ?parent guards in
  match st.free_tasks with
  | t :: free_tasks ->
      st.free_tasks <- free_tasks;
      t.t_id <- t_id;
      t.guard_meta <- guard_meta;
      t.kill_ctx <- kill_ctx;
      t.thread <- thread;
      t.run <- run;
      t.queued <- false;
      t.blocked <- false;
      t.retained <- false;
      t.generation <- 0;
      t
  | [] ->
      {
        t_id
      ; guard_meta
      ; kill_ctx
      ; thread
      ; run
      ; queued = false
      ; blocked = false
      ; retained = false
      ; generation = 0
      }

let reset_task ?parent t thread guards kill_ctx run =
  t.guard_meta <- make_guard_meta ?parent guards;
  t.kill_ctx <- kill_ctx;
  t.thread <- thread;
  t.run <- run;
  t.queued <- false;
  t.blocked <- false

let spawn_now ?parent st thread guards kill_ctx run =
  let t = create_task ?parent st thread guards kill_ctx run in
  enqueue_now st t;
  t

let spawn_next ?parent st thread guards kill_ctx run =
  let t = create_task ?parent st thread guards kill_ctx run in
  enqueue_next st t;
  t

let recycle_task (st : scheduler_state) (t : task) =
  t.guard_meta <- None;
  t.kill_ctx <- empty_kill_context;
  t.thread <- -1;
  t.run <- (fun () -> ());
  t.queued <- false;
  t.blocked <- false;
  t.retained <- false;
  t.generation <- 0;
  st.retired_tasks <- t :: st.retired_tasks

let dispose_task st t =
  if t.thread >= 0 then begin
    st.metrics.tasks_disposed <- st.metrics.tasks_disposed + 1;
    Tempo_thread.finish_task st.threads t.thread;
    recycle_task st t
  end

let block_on_guards (st : scheduler_state) (t : task) =
  if not t.blocked then (
    t.blocked <- true;
    st.metrics.tasks_blocked <- st.metrics.tasks_blocked + 1;
    st.blocked <- t :: st.blocked);
  match t.guard_meta with
  | None -> ()
  | Some gm ->
      gm.cache_checked_epoch <- !guard_epoch;
      gm.cache_ok <- false;
      (match gm.guards with
      | [ signal ] -> register_single_missing_guard st t signal
      | _ ->
          let miss = List.filter (fun (Any s) -> not s.present) gm.guards in
          register_missing_guards st t miss)

let block_on_guards_with_missing (st : scheduler_state) (t : task) miss =
  if not t.blocked then (
    t.blocked <- true;
    st.metrics.tasks_blocked <- st.metrics.tasks_blocked + 1;
    st.blocked <- t :: st.blocked);
  match t.guard_meta with
  | None -> ()
  | Some gm ->
      gm.cache_checked_epoch <- !guard_epoch;
      gm.cache_ok <- false;
      (match gm.guards, miss with
      | [ signal ], [ _ ] -> register_single_missing_guard st t signal
      | _ -> register_missing_guards st t miss)

let wake_guard_waiters st s =
  List.iter
    (fun t ->
      match t.guard_meta with
      | None -> ()
      | Some gm ->
          if gm.cache_registration_instant = st.debug.instant_counter then begin
            (match gm.cache_missing_guards with
            | Missing_none -> ()
            | Missing_one sid ->
                if Int.equal sid s.s_id then begin
                  gm.cache_missing_guards <- Missing_none;
                  if gm.cache_missing_count > 0 then
                    gm.cache_missing_count <- gm.cache_missing_count - 1
                end
            | Missing_many tbl ->
                if Hashtbl.mem tbl s.s_id then begin
                  Hashtbl.remove tbl s.s_id;
                  if gm.cache_missing_count > 0 then
                    gm.cache_missing_count <- gm.cache_missing_count - 1
                end);
            if gm.cache_missing_count = 0 then begin
              (match gm.cache_missing_guards with
              | Missing_many tbl -> Hashtbl.reset tbl
              | Missing_none | Missing_one _ -> ());
              gm.cache_missing_guards <- Missing_none;
              gm.cache_checked_epoch <- !guard_epoch;
              gm.cache_ok <- true;
              if task_kills_alive t then begin
                st.metrics.guard_waiter_wakeups <-
                  st.metrics.guard_waiter_wakeups + 1;
                enqueue_now st t
              end
            end
          end else if task_guards_ok t && task_kills_alive t then begin
            st.metrics.guard_waiter_wakeups <-
              st.metrics.guard_waiter_wakeups + 1;
            enqueue_now st t
          end)
    s.guard_waiters;
  s.guard_waiters <- []
