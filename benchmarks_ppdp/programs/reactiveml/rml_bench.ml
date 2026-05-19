(* THIS FILE IS GENERATED. *)
(* /Users/fdabrowski/Documents/Research/Papers/ppdp2026/rml-1.09.07-2021-07-26-ocaml-5/compiler/rmlc -n -1 -sampling -1.0 rml_bench.rml  *)

open Implem_lco_ctrl_tree_record;;
let benchmark = Stdlib.ref "propagation_chains" 
;;
let size = Stdlib.ref 10 
;;
let run_id = Stdlib.ref 1 
;;
let effective_propagation =
      (function | n__val_rml_5  -> Stdlib.max 1 n__val_rml_5 ) 
;;
let effective_broadcast =
      (function | n__val_rml_7  -> Stdlib.max 1 n__val_rml_7 ) 
;;
let effective_fork_depth =
      (function
        | n__val_rml_9  ->
            (let n__val_rml_10 = Stdlib.max 2 n__val_rml_9  in
              Stdlib.max
                1
                (Stdlib.int_of_float
                  (Stdlib.(/.)
                    (Stdlib.log (Stdlib.float_of_int n__val_rml_10))
                    (Stdlib.log 2.))))
        ) 
;;
let effective_guard_depth =
      (function | n__val_rml_12  -> Stdlib.max 1 n__val_rml_12 ) 
;;
let effective_preemption_depth =
      (function | n__val_rml_14  -> Stdlib.max 1 n__val_rml_14 ) 
;;
let effective_multi_rounds =
      (function
        | n__val_rml_16  ->
            (let n__val_rml_17 = Stdlib.max 2 n__val_rml_16  in
              Stdlib.max
                2
                (Stdlib.int_of_float
                  (Stdlib.(/.)
                    (Stdlib.log (Stdlib.float_of_int n__val_rml_17))
                    (Stdlib.log 2.))))
        ) 
;;
let effective_supervision_sensors =
      (function | n__val_rml_19  -> Stdlib.max 1 n__val_rml_19 ) 
;;
let effective_supervision_rounds =
      (function
        | n__val_rml_21  ->
            (let n__val_rml_22 = Stdlib.max 2 n__val_rml_21  in
              Stdlib.max
                8
                (Stdlib.( * )
                  2
                  (Stdlib.int_of_float
                    (Stdlib.(/.)
                      (Stdlib.log (Stdlib.float_of_int n__val_rml_22))
                      (Stdlib.log 2.)))))
        ) 
;;
let instants_for =
      (function
        | bench__val_rml_24  ->
            (function
              | n__val_rml_25  ->
                  (match bench__val_rml_24 with
                   | "propagation_chains_multi"  ->
                       effective_multi_rounds n__val_rml_25
                   | "broadcast_expansion"  -> 2
                   | "fork_explosion"  -> effective_fork_depth n__val_rml_25
                   | "guarded_cascades_multi"  ->
                       effective_multi_rounds n__val_rml_25
                   | "nested_preemption"  -> 2
                   | "reactive_supervision"  ->
                       Stdlib.(+)
                         (Stdlib.( * )
                           2 (effective_supervision_rounds n__val_rml_25))
                         1
                   | _  -> 1 )
              )
        ) 
;;
let parse_args =
      (function
        | ()  ->
            Arg.parse
              (("--benchmark", (Arg.Set_string benchmark), "Benchmark name")
                ::
                (("--size", (Arg.Set_int size), "Benchmark size parameter")
                  :: (("--run", (Arg.Set_int run_id), "Run index") :: ([]))))
              (function | _  -> () )
              "rml_bench --benchmark <name> --size <n> --run <k>"
        ) 
;;
let link =
      (function
        | signals__val_rml_29  ->
            (function
              | i__val_rml_30  ->
                  ((function
                     | ()  ->
                         Lco_ctrl_tree_record.rml_seq
                           (Lco_ctrl_tree_record.rml_await_immediate
                             (function
                               | ()  ->
                                   Array.get
                                     signals__val_rml_29 i__val_rml_30
                               ))
                           (Lco_ctrl_tree_record.rml_emit
                             (function
                               | ()  ->
                                   Array.get
                                     signals__val_rml_29
                                     (Stdlib.(+) i__val_rml_30 1)
                               ))
                     ):
                    (_) Lco_ctrl_tree_record.process)
              )
        ) 
;;
let bench_propagation =
      (function
        | n__val_rml_32  ->
            ((function
               | ()  ->
                   Lco_ctrl_tree_record.rml_def
                     (function | ()  -> effective_propagation n__val_rml_32 )
                     (function
                       | n__val_rml_33  ->
                           Lco_ctrl_tree_record.rml_def
                             (function
                               | ()  ->
                                   Array.init
                                     (Stdlib.(+) n__val_rml_33 1)
                                     (function
                                       | _  ->
                                           (let s__sig_35 =
                                                  Lco_ctrl_tree_record.rml_global_signal
                                                    ()
                                              in s__sig_35)
                                       )
                               )
                             (function
                               | signals__val_rml_34  ->
                                   Lco_ctrl_tree_record.rml_par_n
                                     ((Lco_ctrl_tree_record.rml_fordopar
                                        (function | ()  -> (0) )
                                        (function
                                          | ()  -> Stdlib.(-) n__val_rml_33 1
                                          )
                                        true
                                        (function
                                          | i__val_rml_36  ->
                                              Lco_ctrl_tree_record.rml_run
                                                (function
                                                  | ()  ->
                                                      link
                                                        signals__val_rml_34
                                                        i__val_rml_36
                                                  )
                                          ))
                                       ::
                                       ((Lco_ctrl_tree_record.rml_await_immediate
                                          (function
                                            | ()  ->
                                                Array.get
                                                  signals__val_rml_34
                                                  n__val_rml_33
                                            ))
                                         ::
                                         ((Lco_ctrl_tree_record.rml_compute
                                            (function
                                              | ()  ->
                                                  Lco_ctrl_tree_record.rml_expr_emit
                                                    (Array.get
                                                      signals__val_rml_34 (0))
                                              ))
                                           :: ([]))))
                               )
                       )
               ):
              (_) Lco_ctrl_tree_record.process)
        ) 
;;
let rec repeat_propagation =
          (function
            | rounds__val_rml_38  ->
                (function
                  | n__val_rml_39  ->
                      ((function
                         | ()  ->
                             Lco_ctrl_tree_record.rml_if
                               (function
                                 | ()  -> Stdlib.(<=) rounds__val_rml_38 (0)
                                 )
                               (Lco_ctrl_tree_record.rml_compute
                                 (function | ()  -> () ))
                               (Lco_ctrl_tree_record.rml_seq
                                 (Lco_ctrl_tree_record.rml_run
                                   (function
                                     | ()  -> bench_propagation n__val_rml_39
                                     ))
                                 (Lco_ctrl_tree_record.rml_if
                                   (function
                                     | ()  ->
                                         Stdlib.(<=) rounds__val_rml_38 1
                                     )
                                   (Lco_ctrl_tree_record.rml_compute
                                     (function | ()  -> () ))
                                   (Lco_ctrl_tree_record.rml_seq
                                     Lco_ctrl_tree_record.rml_pause
                                     (Lco_ctrl_tree_record.rml_run
                                       (function
                                         | ()  ->
                                             repeat_propagation
                                               (Stdlib.(-)
                                                 rounds__val_rml_38 1)
                                               n__val_rml_39
                                         )))))
                         ):
                        (_) Lco_ctrl_tree_record.process)
                  )
            ) 
;;
let bench_propagation_multi =
      (function
        | n__val_rml_41  ->
            ((function
               | ()  ->
                   Lco_ctrl_tree_record.rml_def
                     (function | ()  -> effective_multi_rounds n__val_rml_41
                       )
                     (function
                       | rounds__val_rml_42  ->
                           Lco_ctrl_tree_record.rml_run
                             (function
                               | ()  ->
                                   repeat_propagation
                                     rounds__val_rml_42 n__val_rml_41
                               )
                       )
               ):
              (_) Lco_ctrl_tree_record.process)
        ) 
;;
let observer =
      (function
        | trigger__val_rml_44  ->
            ((function
               | ()  ->
                   Lco_ctrl_tree_record.rml_await_immediate'
                     trigger__val_rml_44
               ):
              (_) Lco_ctrl_tree_record.process)
        ) 
;;
let rec observers =
          (function
            | n__val_rml_46  ->
                (function
                  | trigger__val_rml_47  ->
                      ((function
                         | ()  ->
                             Lco_ctrl_tree_record.rml_if
                               (function
                                 | ()  -> Stdlib.(<=) n__val_rml_46 (0) )
                               (Lco_ctrl_tree_record.rml_compute
                                 (function | ()  -> () ))
                               (Lco_ctrl_tree_record.rml_par
                                 (Lco_ctrl_tree_record.rml_run
                                   (function
                                     | ()  -> observer trigger__val_rml_47 ))
                                 (Lco_ctrl_tree_record.rml_run
                                   (function
                                     | ()  ->
                                         observers
                                           (Stdlib.(-) n__val_rml_46 1)
                                           trigger__val_rml_47
                                     )))
                         ):
                        (_) Lco_ctrl_tree_record.process)
                  )
            ) 
;;
let bench_broadcast =
      (function
        | n__val_rml_49  ->
            ((function
               | ()  ->
                   Lco_ctrl_tree_record.rml_def
                     (function | ()  -> effective_broadcast n__val_rml_49 )
                     (function
                       | n__val_rml_50  ->
                           Lco_ctrl_tree_record.rml_signal
                             (function
                               | trigger__sig_51  ->
                                   Lco_ctrl_tree_record.rml_par
                                     (Lco_ctrl_tree_record.rml_run
                                       (function
                                         | ()  ->
                                             observers
                                               n__val_rml_50 trigger__sig_51
                                         ))
                                     (Lco_ctrl_tree_record.rml_compute
                                       (function
                                         | ()  ->
                                             Lco_ctrl_tree_record.rml_expr_emit
                                               trigger__sig_51
                                         ))
                               )
                       )
               ):
              (_) Lco_ctrl_tree_record.process)
        ) 
;;
let rec fork_tree =
          (function
            | depth__val_rml_53  ->
                ((function
                   | ()  ->
                       Lco_ctrl_tree_record.rml_if
                         (function | ()  -> Stdlib.(<=) depth__val_rml_53 (0)
                           )
                         (Lco_ctrl_tree_record.rml_compute
                           (function | ()  -> () ))
                         (Lco_ctrl_tree_record.rml_seq
                           Lco_ctrl_tree_record.rml_pause
                           (Lco_ctrl_tree_record.rml_par
                             (Lco_ctrl_tree_record.rml_run
                               (function
                                 | ()  ->
                                     fork_tree
                                       (Stdlib.(-) depth__val_rml_53 1)
                                 ))
                             (Lco_ctrl_tree_record.rml_run
                               (function
                                 | ()  ->
                                     fork_tree
                                       (Stdlib.(-) depth__val_rml_53 1)
                                 ))))
                   ):
                  (_) Lco_ctrl_tree_record.process)
            ) 
;;
let bench_fork =
      (function
        | n__val_rml_55  ->
            ((function
               | ()  ->
                   Lco_ctrl_tree_record.rml_run
                     (function
                       | ()  ->
                           fork_tree (effective_fork_depth n__val_rml_55)
                       )
               ):
              (_) Lco_ctrl_tree_record.process)
        ) 
;;
let rec guarded =
          (function
            | guards__val_rml_57  ->
                (function
                  | i__val_rml_58  ->
                      (function
                        | done_sig__val_rml_59  ->
                            ((function
                               | ()  ->
                                   Lco_ctrl_tree_record.rml_if
                                     (function
                                       | ()  ->
                                           Stdlib.(>=)
                                             i__val_rml_58
                                             (Array.length
                                               guards__val_rml_57)
                                       )
                                     (Lco_ctrl_tree_record.rml_compute
                                       (function
                                         | ()  ->
                                             Lco_ctrl_tree_record.rml_expr_emit
                                               done_sig__val_rml_59
                                         ))
                                     (Lco_ctrl_tree_record.rml_when
                                       (function
                                         | ()  ->
                                             Array.get
                                               guards__val_rml_57
                                               i__val_rml_58
                                         )
                                       (Lco_ctrl_tree_record.rml_run
                                         (function
                                           | ()  ->
                                               guarded
                                                 guards__val_rml_57
                                                 (Stdlib.(+) i__val_rml_58 1)
                                                 done_sig__val_rml_59
                                           )))
                               ):
                              (_) Lco_ctrl_tree_record.process)
                        )
                  )
            ) 
;;
let rec emit_many =
          (function
            | guards__val_rml_61  ->
                (function
                  | i__val_rml_62  ->
                      ((function
                         | ()  ->
                             Lco_ctrl_tree_record.rml_if
                               (function
                                 | ()  ->
                                     Stdlib.(>=)
                                       i__val_rml_62
                                       (Array.length guards__val_rml_61)
                                 )
                               (Lco_ctrl_tree_record.rml_compute
                                 (function | ()  -> () ))
                               (Lco_ctrl_tree_record.rml_seq
                                 (Lco_ctrl_tree_record.rml_emit
                                   (function
                                     | ()  ->
                                         Array.get
                                           guards__val_rml_61 i__val_rml_62
                                     ))
                                 (Lco_ctrl_tree_record.rml_run
                                   (function
                                     | ()  ->
                                         emit_many
                                           guards__val_rml_61
                                           (Stdlib.(+) i__val_rml_62 1)
                                     )))
                         ):
                        (_) Lco_ctrl_tree_record.process)
                  )
            ) 
;;
let bench_guarded =
      (function
        | n__val_rml_64  ->
            ((function
               | ()  ->
                   Lco_ctrl_tree_record.rml_def
                     (function | ()  -> effective_guard_depth n__val_rml_64 )
                     (function
                       | depth__val_rml_65  ->
                           Lco_ctrl_tree_record.rml_def
                             (function
                               | ()  ->
                                   Array.init
                                     depth__val_rml_65
                                     (function
                                       | _  ->
                                           (let guard__sig_67 =
                                                  Lco_ctrl_tree_record.rml_global_signal
                                                    ()
                                              in guard__sig_67)
                                       )
                               )
                             (function
                               | guards__val_rml_66  ->
                                   Lco_ctrl_tree_record.rml_signal
                                     (function
                                       | done_sig__sig_68  ->
                                           Lco_ctrl_tree_record.rml_par_n
                                             ((Lco_ctrl_tree_record.rml_seq
                                                (Lco_ctrl_tree_record.rml_run
                                                  (function
                                                    | ()  ->
                                                        guarded
                                                          guards__val_rml_66
                                                          (0)
                                                          done_sig__sig_68
                                                    ))
                                                Lco_ctrl_tree_record.rml_nothing)
                                               ::
                                               ((Lco_ctrl_tree_record.rml_await_immediate'
                                                  done_sig__sig_68)
                                                 ::
                                                 ((Lco_ctrl_tree_record.rml_seq
                                                    (Lco_ctrl_tree_record.rml_run
                                                      (function
                                                        | ()  ->
                                                            emit_many
                                                              guards__val_rml_66
                                                              (0)
                                                        ))
                                                    Lco_ctrl_tree_record.rml_nothing)
                                                   :: ([]))))
                                       )
                               )
                       )
               ):
              (_) Lco_ctrl_tree_record.process)
        ) 
;;
let rec repeat_guarded =
          (function
            | rounds__val_rml_70  ->
                (function
                  | n__val_rml_71  ->
                      ((function
                         | ()  ->
                             Lco_ctrl_tree_record.rml_if
                               (function
                                 | ()  -> Stdlib.(<=) rounds__val_rml_70 (0)
                                 )
                               (Lco_ctrl_tree_record.rml_compute
                                 (function | ()  -> () ))
                               (Lco_ctrl_tree_record.rml_seq
                                 (Lco_ctrl_tree_record.rml_run
                                   (function
                                     | ()  -> bench_guarded n__val_rml_71 ))
                                 (Lco_ctrl_tree_record.rml_if
                                   (function
                                     | ()  ->
                                         Stdlib.(<=) rounds__val_rml_70 1
                                     )
                                   (Lco_ctrl_tree_record.rml_compute
                                     (function | ()  -> () ))
                                   (Lco_ctrl_tree_record.rml_seq
                                     Lco_ctrl_tree_record.rml_pause
                                     (Lco_ctrl_tree_record.rml_run
                                       (function
                                         | ()  ->
                                             repeat_guarded
                                               (Stdlib.(-)
                                                 rounds__val_rml_70 1)
                                               n__val_rml_71
                                         )))))
                         ):
                        (_) Lco_ctrl_tree_record.process)
                  )
            ) 
;;
let bench_guarded_multi =
      (function
        | n__val_rml_73  ->
            ((function
               | ()  ->
                   Lco_ctrl_tree_record.rml_def
                     (function | ()  -> effective_multi_rounds n__val_rml_73
                       )
                     (function
                       | rounds__val_rml_74  ->
                           Lco_ctrl_tree_record.rml_run
                             (function
                               | ()  ->
                                   repeat_guarded
                                     rounds__val_rml_74 n__val_rml_73
                               )
                       )
               ):
              (_) Lco_ctrl_tree_record.process)
        ) 
;;
let rec spin_forever =
          ((function
             | ()  ->
                 Lco_ctrl_tree_record.rml_seq
                   Lco_ctrl_tree_record.rml_pause
                   (Lco_ctrl_tree_record.rml_run
                     (function | ()  -> spin_forever ))
             ):
            (_) Lco_ctrl_tree_record.process) 
;;
let rec spinner =
          (function
            | steps__val_rml_77  ->
                ((function
                   | ()  ->
                       Lco_ctrl_tree_record.rml_if
                         (function | ()  -> Stdlib.(<=) steps__val_rml_77 (0)
                           )
                         (Lco_ctrl_tree_record.rml_compute
                           (function | ()  -> () ))
                         (Lco_ctrl_tree_record.rml_seq
                           Lco_ctrl_tree_record.rml_pause
                           (Lco_ctrl_tree_record.rml_run
                             (function
                               | ()  ->
                                   spinner (Stdlib.(-) steps__val_rml_77 1)
                               )))
                   ):
                  (_) Lco_ctrl_tree_record.process)
            ) 
;;
let rec nested_watch =
          (function
            | i__val_rml_79  ->
                (function
                  | depth__val_rml_80  ->
                      (function
                        | cancel_even__val_rml_81  ->
                            (function
                              | cancel_odd__val_rml_82  ->
                                  ((function
                                     | ()  ->
                                         Lco_ctrl_tree_record.rml_if
                                           (function
                                             | ()  ->
                                                 Stdlib.(>=)
                                                   i__val_rml_79
                                                   depth__val_rml_80
                                             )
                                           (Lco_ctrl_tree_record.rml_run
                                             (function
                                               | ()  ->
                                                   spinner
                                                     (Stdlib.(+)
                                                       depth__val_rml_80 3)
                                               ))
                                           (Lco_ctrl_tree_record.rml_def
                                             (function
                                               | ()  ->
                                                   if
                                                     Stdlib.(=)
                                                       (Stdlib.(mod)
                                                         i__val_rml_79 2)
                                                       (0)
                                                     then
                                                     cancel_even__val_rml_81
                                                     else
                                                     cancel_odd__val_rml_82
                                               )
                                             (function
                                               | cancel__val_rml_83  ->
                                                   Lco_ctrl_tree_record.rml_until'
                                                     cancel__val_rml_83
                                                     (Lco_ctrl_tree_record.rml_run
                                                       (function
                                                         | ()  ->
                                                             nested_watch
                                                               (Stdlib.(+)
                                                                 i__val_rml_79
                                                                 1)
                                                               depth__val_rml_80
                                                               cancel_even__val_rml_81
                                                               cancel_odd__val_rml_82
                                                         ))
                                               ))
                                     ):
                                    (_) Lco_ctrl_tree_record.process)
                              )
                        )
                  )
            ) 
;;
let killer =
      (function
        | cancel_even__val_rml_85  ->
            ((function
               | ()  ->
                   Lco_ctrl_tree_record.rml_seq
                     Lco_ctrl_tree_record.rml_pause
                     (Lco_ctrl_tree_record.rml_emit' cancel_even__val_rml_85)
               ):
              (_) Lco_ctrl_tree_record.process)
        ) 
;;
let bench_preemption =
      (function
        | n__val_rml_87  ->
            ((function
               | ()  ->
                   Lco_ctrl_tree_record.rml_def
                     (function
                       | ()  -> effective_preemption_depth n__val_rml_87 )
                     (function
                       | depth__val_rml_88  ->
                           Lco_ctrl_tree_record.rml_signal
                             (function
                               | cancel_even__sig_89  ->
                                   Lco_ctrl_tree_record.rml_signal
                                     (function
                                       | cancel_odd__sig_90  ->
                                           Lco_ctrl_tree_record.rml_par
                                             (Lco_ctrl_tree_record.rml_run
                                               (function
                                                 | ()  ->
                                                     nested_watch
                                                       (0)
                                                       depth__val_rml_88
                                                       cancel_even__sig_89
                                                       cancel_odd__sig_90
                                                 ))
                                             (Lco_ctrl_tree_record.rml_run
                                               (function
                                                 | ()  ->
                                                     killer
                                                       cancel_even__sig_89
                                                 ))
                                       )
                               )
                       )
               ):
              (_) Lco_ctrl_tree_record.process)
        ) 
;;
let sensor_value =
      (function
        | id__val_rml_92  ->
            (function
              | round__val_rml_93  ->
                  Stdlib.(mod)
                    (Stdlib.(+)
                      (Stdlib.( * )
                        (Stdlib.(+) id__val_rml_92 1)
                        (Stdlib.(+) round__val_rml_93 3))
                      (Stdlib.(mod) id__val_rml_92 7))
                    97
              )
        ) 
;;
let score_readings =
      (function
        | readings__val_rml_95  ->
            List.fold_left
              (function
                | acc__val_rml_96  ->
                    (function
                      | (id__val_rml_97, round__val_rml_98, value__val_rml_99)
                           ->
                          Stdlib.(+)
                            (Stdlib.(+)
                              acc__val_rml_96
                              (Stdlib.( * )
                                (Stdlib.(+) id__val_rml_97 1)
                                value__val_rml_99))
                            round__val_rml_98
                      )
                )
              (0) readings__val_rml_95
        ) 
;;
let sensor =
      (function
        | id__val_rml_101  ->
            (function
              | rounds__val_rml_102  ->
                  (function
                    | tick__val_rml_103  ->
                        (function
                          | ready__val_rml_104  ->
                              (function
                                | readings__val_rml_105  ->
                                    (function
                                      | observed__val_rml_106  ->
                                          ((function
                                             | ()  ->
                                                 Lco_ctrl_tree_record.rml_for
                                                   (function | ()  -> (0) )
                                                   (function
                                                     | ()  ->
                                                         Stdlib.(-)
                                                           rounds__val_rml_102
                                                           1
                                                     )
                                                   true
                                                   (function
                                                     | round__val_ml_107  ->
                                                         Lco_ctrl_tree_record.rml_seq
                                                           (Lco_ctrl_tree_record.rml_seq
                                                             (Lco_ctrl_tree_record.rml_await_immediate'
                                                               tick__val_rml_103)
                                                             (Lco_ctrl_tree_record.rml_when'
                                                               ready__val_rml_104
                                                               (Lco_ctrl_tree_record.rml_compute
                                                                 (function
                                                                   | 
                                                                   ()  ->
                                                                    Lco_ctrl_tree_record.rml_expr_emit_val
                                                                    readings__val_rml_105
                                                                    (id__val_rml_101,
                                                                    round__val_ml_107,
                                                                    (sensor_value
                                                                    id__val_rml_101
                                                                    round__val_ml_107));
                                                                    Stdlib.incr
                                                                    observed__val_rml_106
                                                                   ))))
                                                           Lco_ctrl_tree_record.rml_pause
                                                     )
                                             ):
                                            (_) Lco_ctrl_tree_record.process)
                                      )
                                )
                          )
                    )
              )
        ) 
;;
let rec sensors_loop =
          (function
            | id__val_rml_109  ->
                (function
                  | count__val_rml_110  ->
                      (function
                        | rounds__val_rml_111  ->
                            (function
                              | tick__val_rml_112  ->
                                  (function
                                    | ready__val_rml_113  ->
                                        (function
                                          | readings__val_rml_114  ->
                                              (function
                                                | observed__val_rml_115  ->
                                                    ((function
                                                       | ()  ->
                                                           Lco_ctrl_tree_record.rml_if
                                                             (function
                                                               | ()  ->
                                                                   Stdlib.(>=)
                                                                    id__val_rml_109
                                                                    count__val_rml_110
                                                               )
                                                             (Lco_ctrl_tree_record.rml_compute
                                                               (function
                                                                 | ()  -> ()
                                                                 ))
                                                             (Lco_ctrl_tree_record.rml_par
                                                               (Lco_ctrl_tree_record.rml_run
                                                                 (function
                                                                   | 
                                                                   ()  ->
                                                                    sensor
                                                                    id__val_rml_109
                                                                    rounds__val_rml_111
                                                                    tick__val_rml_112
                                                                    ready__val_rml_113
                                                                    readings__val_rml_114
                                                                    observed__val_rml_115
                                                                   ))
                                                               (Lco_ctrl_tree_record.rml_run
                                                                 (function
                                                                   | 
                                                                   ()  ->
                                                                    sensors_loop
                                                                    (Stdlib.(+)
                                                                    id__val_rml_109
                                                                    1)
                                                                    count__val_rml_110
                                                                    rounds__val_rml_111
                                                                    tick__val_rml_112
                                                                    ready__val_rml_113
                                                                    readings__val_rml_114
                                                                    observed__val_rml_115
                                                                   )))
                                                       ):
                                                      (_)
                                                        Lco_ctrl_tree_record.process)
                                                )
                                          )
                                    )
                              )
                        )
                  )
            ) 
;;
let rec supervisor =
          (function
            | round__val_rml_117  ->
                (function
                  | rounds__val_rml_118  ->
                      (function
                        | tick__val_rml_119  ->
                            (function
                              | ready__val_rml_120  ->
                                  (function
                                    | readings__val_rml_121  ->
                                        (function
                                          | alert__val_rml_122  ->
                                              (function
                                                | total__val_rml_123  ->
                                                    ((function
                                                       | ()  ->
                                                           Lco_ctrl_tree_record.rml_if
                                                             (function
                                                               | ()  ->
                                                                   Stdlib.(>=)
                                                                    round__val_rml_117
                                                                    rounds__val_rml_118
                                                               )
                                                             (Lco_ctrl_tree_record.rml_compute
                                                               (function
                                                                 | ()  -> ()
                                                                 ))
                                                             (Lco_ctrl_tree_record.rml_seq
                                                               (Lco_ctrl_tree_record.rml_compute
                                                                 (function
                                                                   | 
                                                                   ()  ->
                                                                    Lco_ctrl_tree_record.rml_expr_emit
                                                                    ready__val_rml_120;
                                                                    Lco_ctrl_tree_record.rml_expr_emit
                                                                    tick__val_rml_119
                                                                   ))
                                                               (Lco_ctrl_tree_record.rml_await_all'
                                                                 readings__val_rml_121
                                                                 (function
                                                                   | 
                                                                   batch__val_rml_124
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_def
                                                                    (function
                                                                    | ()  ->
                                                                    score_readings
                                                                    batch__val_rml_124
                                                                    )
                                                                    (function
                                                                    | score__val_rml_125
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_seq
                                                                    (Lco_ctrl_tree_record.rml_seq
                                                                    (Lco_ctrl_tree_record.rml_compute
                                                                    (function
                                                                    | ()  ->
                                                                    Stdlib.(:=)
                                                                    total__val_rml_123
                                                                    (Stdlib.(+)
                                                                    (Stdlib.(!)
                                                                    total__val_rml_123)
                                                                    score__val_rml_125);
                                                                    Lco_ctrl_tree_record.rml_expr_emit_val
                                                                    alert__val_rml_122
                                                                    score__val_rml_125
                                                                    ))
                                                                    Lco_ctrl_tree_record.rml_pause)
                                                                    (Lco_ctrl_tree_record.rml_run
                                                                    (function
                                                                    | ()  ->
                                                                    supervisor
                                                                    (Stdlib.(+)
                                                                    round__val_rml_117
                                                                    1)
                                                                    rounds__val_rml_118
                                                                    tick__val_rml_119
                                                                    ready__val_rml_120
                                                                    readings__val_rml_121
                                                                    alert__val_rml_122
                                                                    total__val_rml_123
                                                                    )) )
                                                                   )))
                                                       ):
                                                      (_)
                                                        Lco_ctrl_tree_record.process)
                                                )
                                          )
                                    )
                              )
                        )
                  )
            ) 
;;
let actuator_step =
      (function
        | alert__val_rml_127  ->
            (function
              | total__val_rml_128  ->
                  (function
                    | count__val_rml_129  ->
                        ((function
                           | ()  ->
                               Lco_ctrl_tree_record.rml_await_all'
                                 alert__val_rml_127
                                 (function
                                   | score__val_rml_130  ->
                                       Lco_ctrl_tree_record.rml_compute
                                         (function
                                           | ()  ->
                                               Stdlib.(:=)
                                                 total__val_rml_128
                                                 (Stdlib.(+)
                                                   (Stdlib.(!)
                                                     total__val_rml_128)
                                                   score__val_rml_130);
                                                 Stdlib.incr
                                                   count__val_rml_129
                                           )
                                   )
                           ):
                          (_) Lco_ctrl_tree_record.process)
                    )
              )
        ) 
;;
let rec actuator =
          (function
            | remaining__val_rml_132  ->
                (function
                  | alert__val_rml_133  ->
                      (function
                        | total__val_rml_134  ->
                            (function
                              | count__val_rml_135  ->
                                  ((function
                                     | ()  ->
                                         Lco_ctrl_tree_record.rml_if
                                           (function
                                             | ()  ->
                                                 Stdlib.(<=)
                                                   remaining__val_rml_132 (0)
                                             )
                                           (Lco_ctrl_tree_record.rml_compute
                                             (function | ()  -> () ))
                                           (Lco_ctrl_tree_record.rml_seq
                                             (Lco_ctrl_tree_record.rml_run
                                               (function
                                                 | ()  ->
                                                     actuator_step
                                                       alert__val_rml_133
                                                       total__val_rml_134
                                                       count__val_rml_135
                                                 ))
                                             (Lco_ctrl_tree_record.rml_run
                                               (function
                                                 | ()  ->
                                                     actuator
                                                       (Stdlib.(-)
                                                         remaining__val_rml_132
                                                         1)
                                                       alert__val_rml_133
                                                       total__val_rml_134
                                                       count__val_rml_135
                                                 )))
                                     ):
                                    (_) Lco_ctrl_tree_record.process)
                              )
                        )
                  )
            ) 
;;
let rec resetter =
          (function
            | round__val_rml_137  ->
                (function
                  | rounds__val_rml_138  ->
                      (function
                        | reset__val_rml_139  ->
                            ((function
                               | ()  ->
                                   Lco_ctrl_tree_record.rml_if
                                     (function
                                       | ()  ->
                                           Stdlib.(>=)
                                             round__val_rml_137
                                             rounds__val_rml_138
                                       )
                                     (Lco_ctrl_tree_record.rml_compute
                                       (function | ()  -> () ))
                                     (Lco_ctrl_tree_record.rml_seq
                                       (Lco_ctrl_tree_record.rml_seq
                                         Lco_ctrl_tree_record.rml_pause
                                         (Lco_ctrl_tree_record.rml_compute
                                           (function
                                             | ()  ->
                                                 if
                                                   Stdlib.(&&)
                                                     (Stdlib.(>)
                                                       round__val_rml_137 (0))
                                                     (Stdlib.(=)
                                                       (Stdlib.(mod)
                                                         round__val_rml_137 5)
                                                       (0))
                                                   then
                                                   Lco_ctrl_tree_record.rml_expr_emit
                                                     reset__val_rml_139
                                                   else ()
                                             )))
                                       (Lco_ctrl_tree_record.rml_run
                                         (function
                                           | ()  ->
                                               resetter
                                                 (Stdlib.(+)
                                                   round__val_rml_137 1)
                                                 rounds__val_rml_138
                                                 reset__val_rml_139
                                           )))
                               ):
                              (_) Lco_ctrl_tree_record.process)
                        )
                  )
            ) 
;;
let rec maintenance =
          (function
            | round__val_rml_141  ->
                (function
                  | rounds__val_rml_142  ->
                      (function
                        | reset__val_rml_143  ->
                            ((function
                               | ()  ->
                                   Lco_ctrl_tree_record.rml_if
                                     (function
                                       | ()  ->
                                           Stdlib.(>=)
                                             round__val_rml_141
                                             rounds__val_rml_142
                                       )
                                     (Lco_ctrl_tree_record.rml_compute
                                       (function | ()  -> () ))
                                     (Lco_ctrl_tree_record.rml_seq
                                       (Lco_ctrl_tree_record.rml_until'
                                         reset__val_rml_143
                                         (Lco_ctrl_tree_record.rml_seq
                                           Lco_ctrl_tree_record.rml_pause
                                           Lco_ctrl_tree_record.rml_pause))
                                       (Lco_ctrl_tree_record.rml_run
                                         (function
                                           | ()  ->
                                               maintenance
                                                 (Stdlib.(+)
                                                   round__val_rml_141 1)
                                                 rounds__val_rml_142
                                                 reset__val_rml_143
                                           )))
                               ):
                              (_) Lco_ctrl_tree_record.process)
                        )
                  )
            ) 
;;
let bench_supervision =
      (function
        | n__val_rml_145  ->
            ((function
               | ()  ->
                   Lco_ctrl_tree_record.rml_def
                     (function
                       | ()  -> effective_supervision_sensors n__val_rml_145
                       )
                     (function
                       | sensor_count__val_rml_146  ->
                           Lco_ctrl_tree_record.rml_def
                             (function
                               | ()  ->
                                   effective_supervision_rounds
                                     n__val_rml_145
                               )
                             (function
                               | rounds__val_rml_147  ->
                                   Lco_ctrl_tree_record.rml_def
                                     (function | ()  -> Stdlib.ref (0) )
                                     (function
                                       | observed__val_rml_148  ->
                                           Lco_ctrl_tree_record.rml_def
                                             (function
                                               | ()  -> Stdlib.ref (0) )
                                             (function
                                               | supervisor_total__val_rml_149
                                                    ->
                                                   Lco_ctrl_tree_record.rml_def
                                                     (function
                                                       | ()  ->
                                                           Stdlib.ref (0)
                                                       )
                                                     (function
                                                       | actuator_total__val_rml_150
                                                            ->
                                                           Lco_ctrl_tree_record.rml_def
                                                             (function
                                                               | ()  ->
                                                                   Stdlib.ref
                                                                    (0)
                                                               )
                                                             (function
                                                               | alert_count__val_rml_151
                                                                    ->
                                                                   Lco_ctrl_tree_record.rml_signal
                                                                    (function
                                                                    | tick__sig_152
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_signal
                                                                    (function
                                                                    | ready__sig_153
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_signal
                                                                    (function
                                                                    | reset__sig_154
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_signal_combine
                                                                    (function
                                                                    | ()  ->
                                                                    (0) )
                                                                    (function
                                                                    | ()  ->
                                                                    (function
                                                                    | score__val_rml_155
                                                                     ->
                                                                    (function
                                                                    | _  ->
                                                                    score__val_rml_155
                                                                    ) ) )
                                                                    (function
                                                                    | alert__sig_156
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_signal_combine
                                                                    (function
                                                                    | ()  ->
                                                                    ([]) )
                                                                    (function
                                                                    | ()  ->
                                                                    (function
                                                                    | reading__val_rml_157
                                                                     ->
                                                                    (function
                                                                    | acc__val_rml_158
                                                                     ->
                                                                    reading__val_rml_157
                                                                    ::
                                                                    acc__val_rml_158
                                                                    ) ) )
                                                                    (function
                                                                    | readings__sig_159
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_par_n
                                                                    ((Lco_ctrl_tree_record.rml_seq
                                                                    (Lco_ctrl_tree_record.rml_run
                                                                    (function
                                                                    | ()  ->
                                                                    supervisor
                                                                    (0)
                                                                    rounds__val_rml_147
                                                                    tick__sig_152
                                                                    ready__sig_153
                                                                    readings__sig_159
                                                                    alert__sig_156
                                                                    supervisor_total__val_rml_149
                                                                    ))
                                                                    Lco_ctrl_tree_record.rml_nothing)
                                                                    ::
                                                                    ((Lco_ctrl_tree_record.rml_seq
                                                                    (Lco_ctrl_tree_record.rml_run
                                                                    (function
                                                                    | ()  ->
                                                                    actuator
                                                                    rounds__val_rml_147
                                                                    alert__sig_156
                                                                    actuator_total__val_rml_150
                                                                    alert_count__val_rml_151
                                                                    ))
                                                                    Lco_ctrl_tree_record.rml_nothing)
                                                                    ::
                                                                    ((Lco_ctrl_tree_record.rml_seq
                                                                    (Lco_ctrl_tree_record.rml_run
                                                                    (function
                                                                    | ()  ->
                                                                    resetter
                                                                    (0)
                                                                    rounds__val_rml_147
                                                                    reset__sig_154
                                                                    ))
                                                                    Lco_ctrl_tree_record.rml_nothing)
                                                                    ::
                                                                    ((Lco_ctrl_tree_record.rml_seq
                                                                    (Lco_ctrl_tree_record.rml_run
                                                                    (function
                                                                    | ()  ->
                                                                    maintenance
                                                                    (0)
                                                                    rounds__val_rml_147
                                                                    reset__sig_154
                                                                    ))
                                                                    Lco_ctrl_tree_record.rml_nothing)
                                                                    ::
                                                                    ((Lco_ctrl_tree_record.rml_seq
                                                                    (Lco_ctrl_tree_record.rml_run
                                                                    (function
                                                                    | ()  ->
                                                                    sensors_loop
                                                                    (0)
                                                                    sensor_count__val_rml_146
                                                                    rounds__val_rml_147
                                                                    tick__sig_152
                                                                    ready__sig_153
                                                                    readings__sig_159
                                                                    observed__val_rml_148
                                                                    ))
                                                                    (Lco_ctrl_tree_record.rml_compute
                                                                    (function
                                                                    | ()  ->
                                                                    (let 
                                                                    expected_sensor_events__val_rml_160
                                                                    =
                                                                    Stdlib.( * )
                                                                    sensor_count__val_rml_146
                                                                    rounds__val_rml_147
                                                                     in
                                                                    if
                                                                    Stdlib.(<>)
                                                                    (Stdlib.(!)
                                                                    observed__val_rml_148)
                                                                    expected_sensor_events__val_rml_160
                                                                    then
                                                                    Stdlib.failwith
                                                                    (Stdlib.(^)
                                                                    "supervision sensor mismatch: expected "
                                                                    (Stdlib.(^)
                                                                    (Stdlib.string_of_int
                                                                    expected_sensor_events__val_rml_160)
                                                                    (Stdlib.(^)
                                                                    " got "
                                                                    (Stdlib.string_of_int
                                                                    (Stdlib.(!)
                                                                    observed__val_rml_148)))))
                                                                    else 
                                                                    ();
                                                                    if
                                                                    Stdlib.(<)
                                                                    (Stdlib.(!)
                                                                    alert_count__val_rml_151)
                                                                    (Stdlib.max
                                                                    1
                                                                    (Stdlib.(-)
                                                                    rounds__val_rml_147
                                                                    1)) then
                                                                    Stdlib.failwith
                                                                    (Stdlib.(^)
                                                                    "supervision alert mismatch: expected at least "
                                                                    (Stdlib.(^)
                                                                    (Stdlib.string_of_int
                                                                    (Stdlib.max
                                                                    1
                                                                    (Stdlib.(-)
                                                                    rounds__val_rml_147
                                                                    1)))
                                                                    (Stdlib.(^)
                                                                    " got "
                                                                    (Stdlib.string_of_int
                                                                    (Stdlib.(!)
                                                                    alert_count__val_rml_151)))))
                                                                    else 
                                                                    ();
                                                                    if
                                                                    Stdlib.(<=)
                                                                    (Stdlib.(!)
                                                                    actuator_total__val_rml_150)
                                                                    (0) then
                                                                    Stdlib.failwith
                                                                    (Stdlib.(^)
                                                                    "supervision actuator total mismatch: "
                                                                    (Stdlib.string_of_int
                                                                    (Stdlib.(!)
                                                                    actuator_total__val_rml_150)))
                                                                    else 
                                                                    ();
                                                                    if
                                                                    Stdlib.(<=)
                                                                    (Stdlib.(!)
                                                                    supervisor_total__val_rml_149)
                                                                    (0) then
                                                                    Stdlib.failwith
                                                                    (Stdlib.(^)
                                                                    "supervision supervisor total mismatch: "
                                                                    (Stdlib.string_of_int
                                                                    (Stdlib.(!)
                                                                    supervisor_total__val_rml_149)))
                                                                    else 
                                                                    ()) )))
                                                                    :: 
                                                                    ([]))))))
                                                                    ) ) ) ) )
                                                               )
                                                       )
                                               )
                                       )
                               )
                       )
               ):
              (_) Lco_ctrl_tree_record.process)
        ) 
;;
let selected =
      ((function
         | ()  ->
             Lco_ctrl_tree_record.rml_match
               (function | ()  -> Stdlib.(!) benchmark )
               (function
                 | "propagation_chains"  ->
                     Lco_ctrl_tree_record.rml_run
                       (function | ()  -> bench_propagation (Stdlib.(!) size)
                         )
                 | "propagation_chains_multi"  ->
                     Lco_ctrl_tree_record.rml_run
                       (function
                         | ()  -> bench_propagation_multi (Stdlib.(!) size) )
                 | "broadcast_expansion"  ->
                     Lco_ctrl_tree_record.rml_run
                       (function | ()  -> bench_broadcast (Stdlib.(!) size) )
                 | "fork_explosion"  ->
                     Lco_ctrl_tree_record.rml_run
                       (function | ()  -> bench_fork (Stdlib.(!) size) )
                 | "guarded_cascades"  ->
                     Lco_ctrl_tree_record.rml_run
                       (function | ()  -> bench_guarded (Stdlib.(!) size) )
                 | "guarded_cascades_multi"  ->
                     Lco_ctrl_tree_record.rml_run
                       (function
                         | ()  -> bench_guarded_multi (Stdlib.(!) size) )
                 | "nested_preemption"  ->
                     Lco_ctrl_tree_record.rml_run
                       (function | ()  -> bench_preemption (Stdlib.(!) size)
                         )
                 | "reactive_supervision"  ->
                     Lco_ctrl_tree_record.rml_run
                       (function | ()  -> bench_supervision (Stdlib.(!) size)
                         )
                 | x__val_rml_162  ->
                     Lco_ctrl_tree_record.rml_compute
                       (function
                         | ()  ->
                             Stdlib.invalid_arg
                               (Stdlib.(^)
                                 "unknown benchmark: " x__val_rml_162)
                         )
                 )
         ):
        (_) Lco_ctrl_tree_record.process) 
;;
let peak_mb =
      (function
        | ()  ->
            (let st__val_rml_164 = Gc.stat ()  in
              Stdlib.(/.)
                (Stdlib.(/.)
                  (Stdlib.( *. )
                    (Stdlib.float_of_int (st__val_rml_164).Gc.heap_words)
                    (Stdlib.float_of_int Sys.word_size))
                  8.)
                (Stdlib.( *. ) 1024. 1024.))
        ) 
;;
let () =
      Rml_machine.rml_exec
        ([])
        ((function
           | ()  ->
               Lco_ctrl_tree_record.rml_seq
                 (Lco_ctrl_tree_record.rml_compute
                   (function | ()  -> parse_args (); Gc.full_major () ))
                 (Lco_ctrl_tree_record.rml_def
                   (function | ()  -> Unix.gettimeofday () )
                   (function
                     | t0__val_rml_165  ->
                         Lco_ctrl_tree_record.rml_seq
                           (Lco_ctrl_tree_record.rml_run
                             (function | ()  -> selected ))
                           (Lco_ctrl_tree_record.rml_compute
                             (function
                               | ()  ->
                                   (let t1__val_rml_166 =
                                          Unix.gettimeofday ()
                                      in
                                     Gc.full_major ();
                                       (let time_ms__val_rml_167 =
                                              Stdlib.( *. )
                                                (Stdlib.(-.)
                                                  t1__val_rml_166
                                                  t0__val_rml_165)
                                                1000.
                                          in
                                         let instants__val_rml_168 =
                                               instants_for
                                                 (Stdlib.(!) benchmark)
                                                 (Stdlib.(!) size)
                                            in
                                           let line__val_rml_169 =
                                                 Stdlib.(^)
                                                   "rml,"
                                                   (Stdlib.(^)
                                                     (Stdlib.(!) benchmark)
                                                     (Stdlib.(^)
                                                       ","
                                                       (Stdlib.(^)
                                                         (Stdlib.string_of_int
                                                           (Stdlib.(!) size))
                                                         (Stdlib.(^)
                                                           ","
                                                           (Stdlib.(^)
                                                             (Stdlib.string_of_int
                                                               (Stdlib.(!)
                                                                 run_id))
                                                             (Stdlib.(^)
                                                               ","
                                                               (Stdlib.(^)
                                                                 (Stdlib.string_of_float
                                                                   time_ms__val_rml_167)
                                                                 (Stdlib.(^)
                                                                   ","
                                                                   (Stdlib.(^)
                                                                    (Stdlib.string_of_int
                                                                    instants__val_rml_168)
                                                                    (Stdlib.(^)
                                                                    ","
                                                                    (Stdlib.string_of_float
                                                                    (peak_mb
                                                                    ()))))))))))))
                                              in
                                             Stdlib.print_endline
                                               line__val_rml_169;
                                               Stdlib.flush Stdlib.stdout))
                               ))
                     ))
           ):
          (_) Lco_ctrl_tree_record.process) 
;;
