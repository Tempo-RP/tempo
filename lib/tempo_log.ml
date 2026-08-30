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

module Tempo_log = struct
  module Backend_logs = Logs

  (* Runtime logging helpers and printer functions for runtime data structures.
     Reporter installation and log-level policy belong to the host application. *)

  let source =
    Backend_logs.Src.create ~doc:"Tempo synchronous runtime" "tempo.runtime"

  (* A lightweight record that captures the current instant/step when emitting logs.
     The scheduler rebuilds it at each log call so we only pass immutable data. *)
  type context = { instant : int; step : int }

  let context ~instant ~step = { instant; step }

  (* --- Tag helpers -------------------------------------------------------- *)
  module Log_tags = struct
    let task_id : int Backend_logs.Tag.def =
      Backend_logs.Tag.def "task" ~doc:"Task identifier" Format.pp_print_int

    let signal_id : int Backend_logs.Tag.def =
      Backend_logs.Tag.def "signal" ~doc:"Signal identifier" Format.pp_print_int
  end

  let add_opt_tag def value tags =
    match value with None -> tags | Some v -> Backend_logs.Tag.add def v tags

  (* --- Logging front-end -------------------------------------------------- *)
  let level_enabled level =
    match Backend_logs.Src.level source with
    | Some current -> level <= current
    | None -> false

  let should_log ?(level = Backend_logs.Debug) () = level_enabled level

  let log ?(level = Backend_logs.Debug) ?task ?signal _ctx scope fmt =
    let printer =
      if level_enabled level then
        Format.kasprintf (fun msg ->
            let tags =
              Backend_logs.Tag.empty
              |> add_opt_tag Log_tags.task_id task
              |> add_opt_tag Log_tags.signal_id signal
            in
            Backend_logs.msg ~src:source level (fun m ->
                m ~header:scope ~tags "%s" msg))
      else Format.ifprintf Format.std_formatter
    in
    printer fmt

  let log_banner ctx scope fmt =
    log ~level:Backend_logs.Info ctx scope
      ("==================== " ^^ fmt ^^ " ====================")

  (* Compact helpers for scheduler snapshots. *)
  let log_banner_instant ctx instant =
    log ~level:Backend_logs.Info ctx "instant"
      "==================== INSTANT %03d ====================" instant

  let log_banner_step ctx =
    log ~level:Backend_logs.Info ctx "step"
      "====================== STEP %03d ======================" ctx.step

  (* type step_stats =
  { mutable spawns_now : int
  ; mutable spawns_next : int
  ; mutable blocks : int
  ; mutable aborted : int
  } *)

  (* let empty_stats () =
  { spawns_now = 0
  ; spawns_next = 0
  ; blocks = 0
  ; aborted = 0
  } *)

  let pp_span fmt span =
    let ms = Mtime.Span.to_float_ns span /. 1e6 in
    Format.fprintf fmt "%.3fms" ms

  let log_step_summary ctx span =
    log ~level:Backend_logs.Debug ctx "step" "step=%a" pp_span span

  let pp_waiting fmt waits =
    match waits with
    | [] -> Format.pp_print_string fmt "none"
    | lst ->
        let pp_pair fmt (w, t) = Format.fprintf fmt "%d→%d" w t in
        Format.pp_print_list
          ~pp_sep:(fun fmt () -> Format.pp_print_string fmt ", ")
          pp_pair fmt lst

  (* --- Printers for runtime data structures ------------------------------- *)
  let snapshot_worklist q = Tempo_task.worklist_to_list q

  let default_sep fmt () = Format.fprintf fmt "; "

  let pp_task ?(brief = false) fmt t =
    let queued_msg = if t.queued then "queued" else "not queued" in
    let blocked_msg = if t.blocked then "blocked" else "not blocked" in
    if brief then Format.fprintf fmt "#%d (%s,%s)" t.t_id queued_msg blocked_msg
    else
      let guards = Tempo_task.task_guards_count t
      and kills = Tempo_task.task_kills_count t in
      Format.fprintf fmt "[task %d | %s, %s, guards=%d, kills=%d]" t.t_id
        queued_msg blocked_msg guards kills

  let pp_task_id fmt t = Format.fprintf fmt "%d" t.t_id

  let pp_task_id_list ?(pp_sep = default_sep) fmt ts =
    Format.pp_print_list ~pp_sep pp_task_id fmt ts

  let pp_queue_compact fmt tasks =
    Format.fprintf fmt "[%a]"
      (Format.pp_print_list
         ~pp_sep:(fun fmt () -> Format.pp_print_string fmt " ")
         pp_task_id)
      tasks

  let pp_signal_compact fmt (Any s) =
    let present = if s.present then "✓" else "·" in
    Format.fprintf fmt "#%d(%s)" s.s_id present

  let pp_signal_list_compact fmt signals =
    Format.pp_print_list
      ~pp_sep:(fun fmt () -> Format.pp_print_string fmt " ")
      pp_signal_compact fmt signals

  let pp_task_id_list_default = pp_task_id_list ~pp_sep:default_sep

  let pp_task_list ?(pp_sep = default_sep) ?(brief = false) fmt ls =
    let printer = pp_task ~brief in
    Format.pp_print_list ~pp_sep printer fmt ls

  let pp_task_list_brief = pp_task_list ~pp_sep:default_sep ~brief:true
  let pp_task_list_full = pp_task_list ~pp_sep:default_sep ~brief:false

  let pp_signal_waiters fmt signals =
    let waiting =
      List.filter_map
        (fun (Any s) ->
          let awaits = s.awaiters in
          if awaits = [] then None
          else
            let aw_count = List.length awaits in
            Some (s.s_id, aw_count))
        signals
    in
    match waiting with
    | [] -> Format.pp_print_string fmt "none"
    | lst ->
        let pp_entry fmt (sid, aw_count) =
          Format.fprintf fmt "signal #%d awaiters=%d" sid aw_count
        in
        Format.pp_print_list
          ~pp_sep:(fun fmt () -> Format.pp_print_string fmt " ")
          pp_entry fmt lst

  let pp_limited_list ?(pp_sep = default_sep) ?(max_items = None) printer fmt
      lst =
    let rec take acc n rest =
      match (max_items, rest) with
      | Some limit, _ when n >= limit -> (List.rev acc, true)
      | _, [] -> (List.rev acc, false)
      | _, x :: xs -> take (x :: acc) (n + 1) xs
    in
    let items, truncated = take [] 0 lst in
    Format.pp_print_list ~pp_sep printer fmt items;
    if truncated then Format.pp_print_string fmt "; ..."

  let pp_signal ?(brief = false) fmt s =
    let present_msg = if s.present then "present" else "absent" in
    if brief then Format.fprintf fmt "[sig %d %s]" s.s_id present_msg
    else
      Format.fprintf fmt "[sig %d | %s, guards=[%a]]" s.s_id present_msg
        pp_task_list_brief s.guard_waiters

  let pp_any_signal ?brief fmt (Any s) = pp_signal ?brief fmt s
  let pp_any_signal_list ?brief = Format.pp_print_list (pp_any_signal ?brief)
  let pp_any_signal_list_full = pp_any_signal_list ~brief:false

  let pp_any_guard ?(brief = true) fmt (Any s) =
    if brief then Format.fprintf fmt "[sig %d]" s.s_id
    else
      let present_msg = if s.present then "present" else "absent" in
      Format.fprintf fmt "[sig %d | %s]" s.s_id present_msg

  let pp_any_guard_list ?brief = Format.pp_print_list (pp_any_guard ?brief)

  let log_pick ctx task =
    log ~task:task.t_id ctx "step.select"
      "pick task #%d (logical thread=%d guards=%d)" task.t_id task.thread
      (Tempo_task.task_guards_count task)

  let log_block ctx task missing_guards =
    log ~task:task.t_id ctx "step.block" "block (guards missing %a)"
      (pp_any_guard_list ~brief:true)
      missing_guards

  let log_snapshot ctx ~current ~blocked ~next ~signals =
    log ctx "queues" "queues  current=%a blocked=%a next=%a" pp_queue_compact
      current pp_queue_compact blocked pp_queue_compact next;
    log ctx "signals" "signals %a" pp_signal_list_compact signals

  let log_queue_state ctx scope current blocked paused =
    let pp_ids = pp_task_id_list_default in
    log ~level:Backend_logs.Debug ctx scope
      "counts current=%d blocked=%d paused=%d" (List.length current)
      (List.length blocked) (List.length paused);
    log ctx scope "current=[%a] blocked=[%a] paused=[%a]" pp_ids current pp_ids
      blocked pp_ids paused

  (* --- Duration metrics --------------------------------------------------- *)
  module Scope_metrics = struct
    type data = {
        mutable count : int
      ; mutable total : Mtime.span
      ; mutable max : Mtime.span
    }

    let table : (string, data) Hashtbl.t = Hashtbl.create 16

    let ensure scope =
      match Hashtbl.find_opt table scope with
      | Some data -> data
      | None ->
          let data =
            { count = 0; total = Mtime.Span.zero; max = Mtime.Span.zero }
          in
          Hashtbl.add table scope data;
          data

    let record scope span =
      let data = ensure scope in
      data.count <- data.count + 1;
      data.total <- Mtime.Span.add data.total span;
      if Mtime.Span.compare span data.max > 0 then data.max <- span

    let iter f = Hashtbl.iter (fun scope data -> f scope data) table
  end

  let record_duration scope span =
    if level_enabled Backend_logs.Debug then Scope_metrics.record scope span

  let log_duration_summary () =
    if level_enabled Backend_logs.Debug then
      Scope_metrics.iter (fun scope data ->
          let avg =
            if data.count = 0 then Mtime.Span.zero
            else
              let avg_ns =
                Mtime.Span.to_float_ns data.total /. float data.count
              in
              match Mtime.Span.of_float_ns avg_ns with
              | Some span -> span
              | None -> Mtime.Span.zero
          in
          log
            (context ~instant:0 ~step:0)
            "metrics" "[%s] count=%d total=%a avg=%a max=%a" scope data.count
            pp_span data.total pp_span avg pp_span data.max)

end

include Tempo_log
