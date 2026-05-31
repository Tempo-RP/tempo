(* THIS FILE IS GENERATED. *)
(* rmlc -n -1 -sampling -1.0 rml_bench.rml  *)

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
let effective_network_nodes =
      (function | n__val_rml_24  -> Stdlib.max 2 n__val_rml_24 ) 
;;
let effective_network_rounds = (function | _n__val_rml_26  -> 24 ) 
;;
let instants_for =
      (function
        | bench__val_rml_28  ->
            (function
              | n__val_rml_29  ->
                  (match bench__val_rml_28 with
                   | "propagation_chains_multi"  ->
                       effective_multi_rounds n__val_rml_29
                   | "broadcast_expansion"  -> 2
                   | "fork_explosion"  -> effective_fork_depth n__val_rml_29
                   | "guarded_cascades_multi"  ->
                       effective_multi_rounds n__val_rml_29
                   | "nested_preemption"  -> 2
                   | "reactive_supervision"  ->
                       Stdlib.(+)
                         (Stdlib.( * )
                           2 (effective_supervision_rounds n__val_rml_29))
                         1
                   | "network_routing"  ->
                       Stdlib.(+)
                         (Stdlib.( * )
                           2 (effective_network_rounds n__val_rml_29))
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
        | signals__val_rml_33  ->
            (function
              | i__val_rml_34  ->
                  ((function
                     | ()  ->
                         Lco_ctrl_tree_record.rml_seq
                           (Lco_ctrl_tree_record.rml_await_immediate
                             (function
                               | ()  ->
                                   Array.get
                                     signals__val_rml_33 i__val_rml_34
                               ))
                           (Lco_ctrl_tree_record.rml_emit
                             (function
                               | ()  ->
                                   Array.get
                                     signals__val_rml_33
                                     (Stdlib.(+) i__val_rml_34 1)
                               ))
                     ):
                    (_) Lco_ctrl_tree_record.process)
              )
        ) 
;;
let bench_propagation =
      (function
        | n__val_rml_36  ->
            ((function
               | ()  ->
                   Lco_ctrl_tree_record.rml_def
                     (function | ()  -> effective_propagation n__val_rml_36 )
                     (function
                       | n__val_rml_37  ->
                           Lco_ctrl_tree_record.rml_def
                             (function
                               | ()  ->
                                   Array.init
                                     (Stdlib.(+) n__val_rml_37 1)
                                     (function
                                       | _  ->
                                           (let s__sig_39 =
                                                  Lco_ctrl_tree_record.rml_global_signal
                                                    ()
                                              in s__sig_39)
                                       )
                               )
                             (function
                               | signals__val_rml_38  ->
                                   Lco_ctrl_tree_record.rml_par_n
                                     ((Lco_ctrl_tree_record.rml_fordopar
                                        (function | ()  -> (0) )
                                        (function
                                          | ()  -> Stdlib.(-) n__val_rml_37 1
                                          )
                                        true
                                        (function
                                          | i__val_rml_40  ->
                                              Lco_ctrl_tree_record.rml_run
                                                (function
                                                  | ()  ->
                                                      link
                                                        signals__val_rml_38
                                                        i__val_rml_40
                                                  )
                                          ))
                                       ::
                                       ((Lco_ctrl_tree_record.rml_await_immediate
                                          (function
                                            | ()  ->
                                                Array.get
                                                  signals__val_rml_38
                                                  n__val_rml_37
                                            ))
                                         ::
                                         ((Lco_ctrl_tree_record.rml_compute
                                            (function
                                              | ()  ->
                                                  Lco_ctrl_tree_record.rml_expr_emit
                                                    (Array.get
                                                      signals__val_rml_38 (0))
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
            | rounds__val_rml_42  ->
                (function
                  | n__val_rml_43  ->
                      ((function
                         | ()  ->
                             Lco_ctrl_tree_record.rml_if
                               (function
                                 | ()  -> Stdlib.(<=) rounds__val_rml_42 (0)
                                 )
                               (Lco_ctrl_tree_record.rml_compute
                                 (function | ()  -> () ))
                               (Lco_ctrl_tree_record.rml_seq
                                 (Lco_ctrl_tree_record.rml_run
                                   (function
                                     | ()  -> bench_propagation n__val_rml_43
                                     ))
                                 (Lco_ctrl_tree_record.rml_if
                                   (function
                                     | ()  ->
                                         Stdlib.(<=) rounds__val_rml_42 1
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
                                                 rounds__val_rml_42 1)
                                               n__val_rml_43
                                         )))))
                         ):
                        (_) Lco_ctrl_tree_record.process)
                  )
            ) 
;;
let bench_propagation_multi =
      (function
        | n__val_rml_45  ->
            ((function
               | ()  ->
                   Lco_ctrl_tree_record.rml_def
                     (function | ()  -> effective_multi_rounds n__val_rml_45
                       )
                     (function
                       | rounds__val_rml_46  ->
                           Lco_ctrl_tree_record.rml_run
                             (function
                               | ()  ->
                                   repeat_propagation
                                     rounds__val_rml_46 n__val_rml_45
                               )
                       )
               ):
              (_) Lco_ctrl_tree_record.process)
        ) 
;;
let observer =
      (function
        | trigger__val_rml_48  ->
            ((function
               | ()  ->
                   Lco_ctrl_tree_record.rml_await_immediate'
                     trigger__val_rml_48
               ):
              (_) Lco_ctrl_tree_record.process)
        ) 
;;
let rec observers =
          (function
            | n__val_rml_50  ->
                (function
                  | trigger__val_rml_51  ->
                      ((function
                         | ()  ->
                             Lco_ctrl_tree_record.rml_if
                               (function
                                 | ()  -> Stdlib.(<=) n__val_rml_50 (0) )
                               (Lco_ctrl_tree_record.rml_compute
                                 (function | ()  -> () ))
                               (Lco_ctrl_tree_record.rml_par
                                 (Lco_ctrl_tree_record.rml_run
                                   (function
                                     | ()  -> observer trigger__val_rml_51 ))
                                 (Lco_ctrl_tree_record.rml_run
                                   (function
                                     | ()  ->
                                         observers
                                           (Stdlib.(-) n__val_rml_50 1)
                                           trigger__val_rml_51
                                     )))
                         ):
                        (_) Lco_ctrl_tree_record.process)
                  )
            ) 
;;
let bench_broadcast =
      (function
        | n__val_rml_53  ->
            ((function
               | ()  ->
                   Lco_ctrl_tree_record.rml_def
                     (function | ()  -> effective_broadcast n__val_rml_53 )
                     (function
                       | n__val_rml_54  ->
                           Lco_ctrl_tree_record.rml_signal
                             (function
                               | trigger__sig_55  ->
                                   Lco_ctrl_tree_record.rml_par
                                     (Lco_ctrl_tree_record.rml_run
                                       (function
                                         | ()  ->
                                             observers
                                               n__val_rml_54 trigger__sig_55
                                         ))
                                     (Lco_ctrl_tree_record.rml_compute
                                       (function
                                         | ()  ->
                                             Lco_ctrl_tree_record.rml_expr_emit
                                               trigger__sig_55
                                         ))
                               )
                       )
               ):
              (_) Lco_ctrl_tree_record.process)
        ) 
;;
let rec fork_tree =
          (function
            | depth__val_rml_57  ->
                ((function
                   | ()  ->
                       Lco_ctrl_tree_record.rml_if
                         (function | ()  -> Stdlib.(<=) depth__val_rml_57 (0)
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
                                       (Stdlib.(-) depth__val_rml_57 1)
                                 ))
                             (Lco_ctrl_tree_record.rml_run
                               (function
                                 | ()  ->
                                     fork_tree
                                       (Stdlib.(-) depth__val_rml_57 1)
                                 ))))
                   ):
                  (_) Lco_ctrl_tree_record.process)
            ) 
;;
let bench_fork =
      (function
        | n__val_rml_59  ->
            ((function
               | ()  ->
                   Lco_ctrl_tree_record.rml_run
                     (function
                       | ()  ->
                           fork_tree (effective_fork_depth n__val_rml_59)
                       )
               ):
              (_) Lco_ctrl_tree_record.process)
        ) 
;;
let rec guarded =
          (function
            | guards__val_rml_61  ->
                (function
                  | i__val_rml_62  ->
                      (function
                        | done_sig__val_rml_63  ->
                            ((function
                               | ()  ->
                                   Lco_ctrl_tree_record.rml_if
                                     (function
                                       | ()  ->
                                           Stdlib.(>=)
                                             i__val_rml_62
                                             (Array.length
                                               guards__val_rml_61)
                                       )
                                     (Lco_ctrl_tree_record.rml_compute
                                       (function
                                         | ()  ->
                                             Lco_ctrl_tree_record.rml_expr_emit
                                               done_sig__val_rml_63
                                         ))
                                     (Lco_ctrl_tree_record.rml_when
                                       (function
                                         | ()  ->
                                             Array.get
                                               guards__val_rml_61
                                               i__val_rml_62
                                         )
                                       (Lco_ctrl_tree_record.rml_run
                                         (function
                                           | ()  ->
                                               guarded
                                                 guards__val_rml_61
                                                 (Stdlib.(+) i__val_rml_62 1)
                                                 done_sig__val_rml_63
                                           )))
                               ):
                              (_) Lco_ctrl_tree_record.process)
                        )
                  )
            ) 
;;
let rec emit_many =
          (function
            | guards__val_rml_65  ->
                (function
                  | i__val_rml_66  ->
                      ((function
                         | ()  ->
                             Lco_ctrl_tree_record.rml_if
                               (function
                                 | ()  ->
                                     Stdlib.(>=)
                                       i__val_rml_66
                                       (Array.length guards__val_rml_65)
                                 )
                               (Lco_ctrl_tree_record.rml_compute
                                 (function | ()  -> () ))
                               (Lco_ctrl_tree_record.rml_seq
                                 (Lco_ctrl_tree_record.rml_emit
                                   (function
                                     | ()  ->
                                         Array.get
                                           guards__val_rml_65 i__val_rml_66
                                     ))
                                 (Lco_ctrl_tree_record.rml_run
                                   (function
                                     | ()  ->
                                         emit_many
                                           guards__val_rml_65
                                           (Stdlib.(+) i__val_rml_66 1)
                                     )))
                         ):
                        (_) Lco_ctrl_tree_record.process)
                  )
            ) 
;;
let bench_guarded =
      (function
        | n__val_rml_68  ->
            ((function
               | ()  ->
                   Lco_ctrl_tree_record.rml_def
                     (function | ()  -> effective_guard_depth n__val_rml_68 )
                     (function
                       | depth__val_rml_69  ->
                           Lco_ctrl_tree_record.rml_def
                             (function
                               | ()  ->
                                   Array.init
                                     depth__val_rml_69
                                     (function
                                       | _  ->
                                           (let guard__sig_71 =
                                                  Lco_ctrl_tree_record.rml_global_signal
                                                    ()
                                              in guard__sig_71)
                                       )
                               )
                             (function
                               | guards__val_rml_70  ->
                                   Lco_ctrl_tree_record.rml_signal
                                     (function
                                       | done_sig__sig_72  ->
                                           Lco_ctrl_tree_record.rml_par_n
                                             ((Lco_ctrl_tree_record.rml_seq
                                                (Lco_ctrl_tree_record.rml_run
                                                  (function
                                                    | ()  ->
                                                        guarded
                                                          guards__val_rml_70
                                                          (0)
                                                          done_sig__sig_72
                                                    ))
                                                Lco_ctrl_tree_record.rml_nothing)
                                               ::
                                               ((Lco_ctrl_tree_record.rml_await_immediate'
                                                  done_sig__sig_72)
                                                 ::
                                                 ((Lco_ctrl_tree_record.rml_seq
                                                    (Lco_ctrl_tree_record.rml_run
                                                      (function
                                                        | ()  ->
                                                            emit_many
                                                              guards__val_rml_70
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
            | rounds__val_rml_74  ->
                (function
                  | n__val_rml_75  ->
                      ((function
                         | ()  ->
                             Lco_ctrl_tree_record.rml_if
                               (function
                                 | ()  -> Stdlib.(<=) rounds__val_rml_74 (0)
                                 )
                               (Lco_ctrl_tree_record.rml_compute
                                 (function | ()  -> () ))
                               (Lco_ctrl_tree_record.rml_seq
                                 (Lco_ctrl_tree_record.rml_run
                                   (function
                                     | ()  -> bench_guarded n__val_rml_75 ))
                                 (Lco_ctrl_tree_record.rml_if
                                   (function
                                     | ()  ->
                                         Stdlib.(<=) rounds__val_rml_74 1
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
                                                 rounds__val_rml_74 1)
                                               n__val_rml_75
                                         )))))
                         ):
                        (_) Lco_ctrl_tree_record.process)
                  )
            ) 
;;
let bench_guarded_multi =
      (function
        | n__val_rml_77  ->
            ((function
               | ()  ->
                   Lco_ctrl_tree_record.rml_def
                     (function | ()  -> effective_multi_rounds n__val_rml_77
                       )
                     (function
                       | rounds__val_rml_78  ->
                           Lco_ctrl_tree_record.rml_run
                             (function
                               | ()  ->
                                   repeat_guarded
                                     rounds__val_rml_78 n__val_rml_77
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
            | steps__val_rml_81  ->
                ((function
                   | ()  ->
                       Lco_ctrl_tree_record.rml_if
                         (function | ()  -> Stdlib.(<=) steps__val_rml_81 (0)
                           )
                         (Lco_ctrl_tree_record.rml_compute
                           (function | ()  -> () ))
                         (Lco_ctrl_tree_record.rml_seq
                           Lco_ctrl_tree_record.rml_pause
                           (Lco_ctrl_tree_record.rml_run
                             (function
                               | ()  ->
                                   spinner (Stdlib.(-) steps__val_rml_81 1)
                               )))
                   ):
                  (_) Lco_ctrl_tree_record.process)
            ) 
;;
let rec nested_watch =
          (function
            | i__val_rml_83  ->
                (function
                  | depth__val_rml_84  ->
                      (function
                        | cancel_even__val_rml_85  ->
                            (function
                              | cancel_odd__val_rml_86  ->
                                  ((function
                                     | ()  ->
                                         Lco_ctrl_tree_record.rml_if
                                           (function
                                             | ()  ->
                                                 Stdlib.(>=)
                                                   i__val_rml_83
                                                   depth__val_rml_84
                                             )
                                           (Lco_ctrl_tree_record.rml_run
                                             (function
                                               | ()  ->
                                                   spinner
                                                     (Stdlib.(+)
                                                       depth__val_rml_84 3)
                                               ))
                                           (Lco_ctrl_tree_record.rml_def
                                             (function
                                               | ()  ->
                                                   if
                                                     Stdlib.(=)
                                                       (Stdlib.(mod)
                                                         i__val_rml_83 2)
                                                       (0)
                                                     then
                                                     cancel_even__val_rml_85
                                                     else
                                                     cancel_odd__val_rml_86
                                               )
                                             (function
                                               | cancel__val_rml_87  ->
                                                   Lco_ctrl_tree_record.rml_until'
                                                     cancel__val_rml_87
                                                     (Lco_ctrl_tree_record.rml_run
                                                       (function
                                                         | ()  ->
                                                             nested_watch
                                                               (Stdlib.(+)
                                                                 i__val_rml_83
                                                                 1)
                                                               depth__val_rml_84
                                                               cancel_even__val_rml_85
                                                               cancel_odd__val_rml_86
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
        | cancel_even__val_rml_89  ->
            ((function
               | ()  ->
                   Lco_ctrl_tree_record.rml_seq
                     Lco_ctrl_tree_record.rml_pause
                     (Lco_ctrl_tree_record.rml_emit' cancel_even__val_rml_89)
               ):
              (_) Lco_ctrl_tree_record.process)
        ) 
;;
let bench_preemption =
      (function
        | n__val_rml_91  ->
            ((function
               | ()  ->
                   Lco_ctrl_tree_record.rml_def
                     (function
                       | ()  -> effective_preemption_depth n__val_rml_91 )
                     (function
                       | depth__val_rml_92  ->
                           Lco_ctrl_tree_record.rml_signal
                             (function
                               | cancel_even__sig_93  ->
                                   Lco_ctrl_tree_record.rml_signal
                                     (function
                                       | cancel_odd__sig_94  ->
                                           Lco_ctrl_tree_record.rml_par
                                             (Lco_ctrl_tree_record.rml_run
                                               (function
                                                 | ()  ->
                                                     nested_watch
                                                       (0)
                                                       depth__val_rml_92
                                                       cancel_even__sig_93
                                                       cancel_odd__sig_94
                                                 ))
                                             (Lco_ctrl_tree_record.rml_run
                                               (function
                                                 | ()  ->
                                                     killer
                                                       cancel_even__sig_93
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
        | id__val_rml_96  ->
            (function
              | round__val_rml_97  ->
                  Stdlib.(mod)
                    (Stdlib.(+)
                      (Stdlib.( * )
                        (Stdlib.(+) id__val_rml_96 1)
                        (Stdlib.(+) round__val_rml_97 3))
                      (Stdlib.(mod) id__val_rml_96 7))
                    97
              )
        ) 
;;
let score_readings =
      (function
        | readings__val_rml_99  ->
            List.fold_left
              (function
                | acc__val_rml_100  ->
                    (function
                      | (id__val_rml_101,
                         round__val_rml_102, value__val_rml_103)  ->
                          Stdlib.(+)
                            (Stdlib.(+)
                              acc__val_rml_100
                              (Stdlib.( * )
                                (Stdlib.(+) id__val_rml_101 1)
                                value__val_rml_103))
                            round__val_rml_102
                      )
                )
              (0) readings__val_rml_99
        ) 
;;
let sensor =
      (function
        | id__val_rml_105  ->
            (function
              | rounds__val_rml_106  ->
                  (function
                    | tick__val_rml_107  ->
                        (function
                          | ready__val_rml_108  ->
                              (function
                                | readings__val_rml_109  ->
                                    (function
                                      | observed__val_rml_110  ->
                                          ((function
                                             | ()  ->
                                                 Lco_ctrl_tree_record.rml_for
                                                   (function | ()  -> (0) )
                                                   (function
                                                     | ()  ->
                                                         Stdlib.(-)
                                                           rounds__val_rml_106
                                                           1
                                                     )
                                                   true
                                                   (function
                                                     | round__val_ml_111  ->
                                                         Lco_ctrl_tree_record.rml_seq
                                                           (Lco_ctrl_tree_record.rml_seq
                                                             (Lco_ctrl_tree_record.rml_await_immediate'
                                                               tick__val_rml_107)
                                                             (Lco_ctrl_tree_record.rml_when'
                                                               ready__val_rml_108
                                                               (Lco_ctrl_tree_record.rml_compute
                                                                 (function
                                                                   | 
                                                                   ()  ->
                                                                    Lco_ctrl_tree_record.rml_expr_emit_val
                                                                    readings__val_rml_109
                                                                    (id__val_rml_105,
                                                                    round__val_ml_111,
                                                                    (sensor_value
                                                                    id__val_rml_105
                                                                    round__val_ml_111));
                                                                    Stdlib.incr
                                                                    observed__val_rml_110
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
            | id__val_rml_113  ->
                (function
                  | count__val_rml_114  ->
                      (function
                        | rounds__val_rml_115  ->
                            (function
                              | tick__val_rml_116  ->
                                  (function
                                    | ready__val_rml_117  ->
                                        (function
                                          | readings__val_rml_118  ->
                                              (function
                                                | observed__val_rml_119  ->
                                                    ((function
                                                       | ()  ->
                                                           Lco_ctrl_tree_record.rml_if
                                                             (function
                                                               | ()  ->
                                                                   Stdlib.(>=)
                                                                    id__val_rml_113
                                                                    count__val_rml_114
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
                                                                    id__val_rml_113
                                                                    rounds__val_rml_115
                                                                    tick__val_rml_116
                                                                    ready__val_rml_117
                                                                    readings__val_rml_118
                                                                    observed__val_rml_119
                                                                   ))
                                                               (Lco_ctrl_tree_record.rml_run
                                                                 (function
                                                                   | 
                                                                   ()  ->
                                                                    sensors_loop
                                                                    (Stdlib.(+)
                                                                    id__val_rml_113
                                                                    1)
                                                                    count__val_rml_114
                                                                    rounds__val_rml_115
                                                                    tick__val_rml_116
                                                                    ready__val_rml_117
                                                                    readings__val_rml_118
                                                                    observed__val_rml_119
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
            | round__val_rml_121  ->
                (function
                  | rounds__val_rml_122  ->
                      (function
                        | tick__val_rml_123  ->
                            (function
                              | ready__val_rml_124  ->
                                  (function
                                    | readings__val_rml_125  ->
                                        (function
                                          | alert__val_rml_126  ->
                                              (function
                                                | total__val_rml_127  ->
                                                    ((function
                                                       | ()  ->
                                                           Lco_ctrl_tree_record.rml_if
                                                             (function
                                                               | ()  ->
                                                                   Stdlib.(>=)
                                                                    round__val_rml_121
                                                                    rounds__val_rml_122
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
                                                                    ready__val_rml_124;
                                                                    Lco_ctrl_tree_record.rml_expr_emit
                                                                    tick__val_rml_123
                                                                   ))
                                                               (Lco_ctrl_tree_record.rml_await_all'
                                                                 readings__val_rml_125
                                                                 (function
                                                                   | 
                                                                   batch__val_rml_128
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_def
                                                                    (function
                                                                    | ()  ->
                                                                    score_readings
                                                                    batch__val_rml_128
                                                                    )
                                                                    (function
                                                                    | score__val_rml_129
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_seq
                                                                    (Lco_ctrl_tree_record.rml_seq
                                                                    (Lco_ctrl_tree_record.rml_compute
                                                                    (function
                                                                    | ()  ->
                                                                    Stdlib.(:=)
                                                                    total__val_rml_127
                                                                    (Stdlib.(+)
                                                                    (Stdlib.(!)
                                                                    total__val_rml_127)
                                                                    score__val_rml_129);
                                                                    Lco_ctrl_tree_record.rml_expr_emit_val
                                                                    alert__val_rml_126
                                                                    score__val_rml_129
                                                                    ))
                                                                    Lco_ctrl_tree_record.rml_pause)
                                                                    (Lco_ctrl_tree_record.rml_run
                                                                    (function
                                                                    | ()  ->
                                                                    supervisor
                                                                    (Stdlib.(+)
                                                                    round__val_rml_121
                                                                    1)
                                                                    rounds__val_rml_122
                                                                    tick__val_rml_123
                                                                    ready__val_rml_124
                                                                    readings__val_rml_125
                                                                    alert__val_rml_126
                                                                    total__val_rml_127
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
        | alert__val_rml_131  ->
            (function
              | total__val_rml_132  ->
                  (function
                    | count__val_rml_133  ->
                        ((function
                           | ()  ->
                               Lco_ctrl_tree_record.rml_await_all'
                                 alert__val_rml_131
                                 (function
                                   | score__val_rml_134  ->
                                       Lco_ctrl_tree_record.rml_compute
                                         (function
                                           | ()  ->
                                               Stdlib.(:=)
                                                 total__val_rml_132
                                                 (Stdlib.(+)
                                                   (Stdlib.(!)
                                                     total__val_rml_132)
                                                   score__val_rml_134);
                                                 Stdlib.incr
                                                   count__val_rml_133
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
            | remaining__val_rml_136  ->
                (function
                  | alert__val_rml_137  ->
                      (function
                        | total__val_rml_138  ->
                            (function
                              | count__val_rml_139  ->
                                  ((function
                                     | ()  ->
                                         Lco_ctrl_tree_record.rml_if
                                           (function
                                             | ()  ->
                                                 Stdlib.(<=)
                                                   remaining__val_rml_136 (0)
                                             )
                                           (Lco_ctrl_tree_record.rml_compute
                                             (function | ()  -> () ))
                                           (Lco_ctrl_tree_record.rml_seq
                                             (Lco_ctrl_tree_record.rml_run
                                               (function
                                                 | ()  ->
                                                     actuator_step
                                                       alert__val_rml_137
                                                       total__val_rml_138
                                                       count__val_rml_139
                                                 ))
                                             (Lco_ctrl_tree_record.rml_run
                                               (function
                                                 | ()  ->
                                                     actuator
                                                       (Stdlib.(-)
                                                         remaining__val_rml_136
                                                         1)
                                                       alert__val_rml_137
                                                       total__val_rml_138
                                                       count__val_rml_139
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
                                       (Lco_ctrl_tree_record.rml_seq
                                         Lco_ctrl_tree_record.rml_pause
                                         (Lco_ctrl_tree_record.rml_compute
                                           (function
                                             | ()  ->
                                                 if
                                                   Stdlib.(&&)
                                                     (Stdlib.(>)
                                                       round__val_rml_141 (0))
                                                     (Stdlib.(=)
                                                       (Stdlib.(mod)
                                                         round__val_rml_141 5)
                                                       (0))
                                                   then
                                                   Lco_ctrl_tree_record.rml_expr_emit
                                                     reset__val_rml_143
                                                   else ()
                                             )))
                                       (Lco_ctrl_tree_record.rml_run
                                         (function
                                           | ()  ->
                                               resetter
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
let rec maintenance =
          (function
            | round__val_rml_145  ->
                (function
                  | rounds__val_rml_146  ->
                      (function
                        | reset__val_rml_147  ->
                            ((function
                               | ()  ->
                                   Lco_ctrl_tree_record.rml_if
                                     (function
                                       | ()  ->
                                           Stdlib.(>=)
                                             round__val_rml_145
                                             rounds__val_rml_146
                                       )
                                     (Lco_ctrl_tree_record.rml_compute
                                       (function | ()  -> () ))
                                     (Lco_ctrl_tree_record.rml_seq
                                       (Lco_ctrl_tree_record.rml_until'
                                         reset__val_rml_147
                                         (Lco_ctrl_tree_record.rml_seq
                                           Lco_ctrl_tree_record.rml_pause
                                           Lco_ctrl_tree_record.rml_pause))
                                       (Lco_ctrl_tree_record.rml_run
                                         (function
                                           | ()  ->
                                               maintenance
                                                 (Stdlib.(+)
                                                   round__val_rml_145 1)
                                                 rounds__val_rml_146
                                                 reset__val_rml_147
                                           )))
                               ):
                              (_) Lco_ctrl_tree_record.process)
                        )
                  )
            ) 
;;
let bench_supervision =
      (function
        | n__val_rml_149  ->
            ((function
               | ()  ->
                   Lco_ctrl_tree_record.rml_def
                     (function
                       | ()  -> effective_supervision_sensors n__val_rml_149
                       )
                     (function
                       | sensor_count__val_rml_150  ->
                           Lco_ctrl_tree_record.rml_def
                             (function
                               | ()  ->
                                   effective_supervision_rounds
                                     n__val_rml_149
                               )
                             (function
                               | rounds__val_rml_151  ->
                                   Lco_ctrl_tree_record.rml_def
                                     (function | ()  -> Stdlib.ref (0) )
                                     (function
                                       | observed__val_rml_152  ->
                                           Lco_ctrl_tree_record.rml_def
                                             (function
                                               | ()  -> Stdlib.ref (0) )
                                             (function
                                               | supervisor_total__val_rml_153
                                                    ->
                                                   Lco_ctrl_tree_record.rml_def
                                                     (function
                                                       | ()  ->
                                                           Stdlib.ref (0)
                                                       )
                                                     (function
                                                       | actuator_total__val_rml_154
                                                            ->
                                                           Lco_ctrl_tree_record.rml_def
                                                             (function
                                                               | ()  ->
                                                                   Stdlib.ref
                                                                    (0)
                                                               )
                                                             (function
                                                               | alert_count__val_rml_155
                                                                    ->
                                                                   Lco_ctrl_tree_record.rml_signal
                                                                    (function
                                                                    | tick__sig_156
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_signal
                                                                    (function
                                                                    | ready__sig_157
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_signal
                                                                    (function
                                                                    | reset__sig_158
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_signal_combine
                                                                    (function
                                                                    | ()  ->
                                                                    (0) )
                                                                    (function
                                                                    | ()  ->
                                                                    (function
                                                                    | score__val_rml_159
                                                                     ->
                                                                    (function
                                                                    | _  ->
                                                                    score__val_rml_159
                                                                    ) ) )
                                                                    (function
                                                                    | alert__sig_160
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_signal_combine
                                                                    (function
                                                                    | ()  ->
                                                                    ([]) )
                                                                    (function
                                                                    | ()  ->
                                                                    (function
                                                                    | reading__val_rml_161
                                                                     ->
                                                                    (function
                                                                    | acc__val_rml_162
                                                                     ->
                                                                    reading__val_rml_161
                                                                    ::
                                                                    acc__val_rml_162
                                                                    ) ) )
                                                                    (function
                                                                    | readings__sig_163
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_par_n
                                                                    ((Lco_ctrl_tree_record.rml_seq
                                                                    (Lco_ctrl_tree_record.rml_run
                                                                    (function
                                                                    | ()  ->
                                                                    supervisor
                                                                    (0)
                                                                    rounds__val_rml_151
                                                                    tick__sig_156
                                                                    ready__sig_157
                                                                    readings__sig_163
                                                                    alert__sig_160
                                                                    supervisor_total__val_rml_153
                                                                    ))
                                                                    Lco_ctrl_tree_record.rml_nothing)
                                                                    ::
                                                                    ((Lco_ctrl_tree_record.rml_seq
                                                                    (Lco_ctrl_tree_record.rml_run
                                                                    (function
                                                                    | ()  ->
                                                                    actuator
                                                                    rounds__val_rml_151
                                                                    alert__sig_160
                                                                    actuator_total__val_rml_154
                                                                    alert_count__val_rml_155
                                                                    ))
                                                                    Lco_ctrl_tree_record.rml_nothing)
                                                                    ::
                                                                    ((Lco_ctrl_tree_record.rml_seq
                                                                    (Lco_ctrl_tree_record.rml_run
                                                                    (function
                                                                    | ()  ->
                                                                    resetter
                                                                    (0)
                                                                    rounds__val_rml_151
                                                                    reset__sig_158
                                                                    ))
                                                                    Lco_ctrl_tree_record.rml_nothing)
                                                                    ::
                                                                    ((Lco_ctrl_tree_record.rml_seq
                                                                    (Lco_ctrl_tree_record.rml_run
                                                                    (function
                                                                    | ()  ->
                                                                    maintenance
                                                                    (0)
                                                                    rounds__val_rml_151
                                                                    reset__sig_158
                                                                    ))
                                                                    Lco_ctrl_tree_record.rml_nothing)
                                                                    ::
                                                                    ((Lco_ctrl_tree_record.rml_seq
                                                                    (Lco_ctrl_tree_record.rml_run
                                                                    (function
                                                                    | ()  ->
                                                                    sensors_loop
                                                                    (0)
                                                                    sensor_count__val_rml_150
                                                                    rounds__val_rml_151
                                                                    tick__sig_156
                                                                    ready__sig_157
                                                                    readings__sig_163
                                                                    observed__val_rml_152
                                                                    ))
                                                                    (Lco_ctrl_tree_record.rml_compute
                                                                    (function
                                                                    | ()  ->
                                                                    (let 
                                                                    expected_sensor_events__val_rml_164
                                                                    =
                                                                    Stdlib.( * )
                                                                    sensor_count__val_rml_150
                                                                    rounds__val_rml_151
                                                                     in
                                                                    if
                                                                    Stdlib.(<>)
                                                                    (Stdlib.(!)
                                                                    observed__val_rml_152)
                                                                    expected_sensor_events__val_rml_164
                                                                    then
                                                                    Stdlib.failwith
                                                                    (Stdlib.(^)
                                                                    "supervision sensor mismatch: expected "
                                                                    (Stdlib.(^)
                                                                    (Stdlib.string_of_int
                                                                    expected_sensor_events__val_rml_164)
                                                                    (Stdlib.(^)
                                                                    " got "
                                                                    (Stdlib.string_of_int
                                                                    (Stdlib.(!)
                                                                    observed__val_rml_152)))))
                                                                    else 
                                                                    ();
                                                                    if
                                                                    Stdlib.(<)
                                                                    (Stdlib.(!)
                                                                    alert_count__val_rml_155)
                                                                    (Stdlib.max
                                                                    1
                                                                    (Stdlib.(-)
                                                                    rounds__val_rml_151
                                                                    1)) then
                                                                    Stdlib.failwith
                                                                    (Stdlib.(^)
                                                                    "supervision alert mismatch: expected at least "
                                                                    (Stdlib.(^)
                                                                    (Stdlib.string_of_int
                                                                    (Stdlib.max
                                                                    1
                                                                    (Stdlib.(-)
                                                                    rounds__val_rml_151
                                                                    1)))
                                                                    (Stdlib.(^)
                                                                    " got "
                                                                    (Stdlib.string_of_int
                                                                    (Stdlib.(!)
                                                                    alert_count__val_rml_155)))))
                                                                    else 
                                                                    ();
                                                                    if
                                                                    Stdlib.(<=)
                                                                    (Stdlib.(!)
                                                                    actuator_total__val_rml_154)
                                                                    (0) then
                                                                    Stdlib.failwith
                                                                    (Stdlib.(^)
                                                                    "supervision actuator total mismatch: "
                                                                    (Stdlib.string_of_int
                                                                    (Stdlib.(!)
                                                                    actuator_total__val_rml_154)))
                                                                    else 
                                                                    ();
                                                                    if
                                                                    Stdlib.(<=)
                                                                    (Stdlib.(!)
                                                                    supervisor_total__val_rml_153)
                                                                    (0) then
                                                                    Stdlib.failwith
                                                                    (Stdlib.(^)
                                                                    "supervision supervisor total mismatch: "
                                                                    (Stdlib.string_of_int
                                                                    (Stdlib.(!)
                                                                    supervisor_total__val_rml_153)))
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
type  network_pos
= {  x: float ;   y: float} ;;
type  network_info
= {  info_id: int ;   info_pos: network_pos ;   info_date: int} ;;
type  network_node
= {
   node_id: int ; 
  mutable pos: network_pos ; 
  mutable date: int ; 
   known_x: (float) array ; 
   known_y: (float) array ; 
   known_date: (int) array ;  mutable neighbors: (network_info) list} ;;
let network_distance2 =
      (function
        | a__val_rml_166  ->
            (function
              | b__val_rml_167  ->
                  (let dx__val_rml_168 =
                         Stdlib.(-.) (b__val_rml_167).x (a__val_rml_166).x
                     in
                    let dy__val_rml_169 =
                          Stdlib.(-.) (b__val_rml_167).y (a__val_rml_166).y
                       in
                      Stdlib.(+.)
                        (Stdlib.( *. ) dx__val_rml_168 dx__val_rml_168)
                        (Stdlib.( *. ) dy__val_rml_169 dy__val_rml_169))
              )
        ) 
;;
let network_initial_pos =
      (function
        | nodes__val_rml_171  ->
            (function
              | id__val_rml_172  ->
                  (let side__val_rml_173 =
                         Stdlib.(+.)
                           (Stdlib.( *. )
                             (Stdlib.sqrt
                               (Stdlib.float_of_int nodes__val_rml_171))
                             30.)
                           1.
                     in
                    {x=(Stdlib.float_of_int
                         (Stdlib.(mod)
                           (Stdlib.(+) (Stdlib.( * ) id__val_rml_172 73) 19)
                           (Stdlib.int_of_float side__val_rml_173)));
                     y=(Stdlib.float_of_int
                         (Stdlib.(mod)
                           (Stdlib.(+) (Stdlib.( * ) id__val_rml_172 97) 41)
                           (Stdlib.int_of_float side__val_rml_173)))})
              )
        ) 
;;
let network_move =
      (function
        | nodes__val_rml_175  ->
            (function
              | id__val_rml_176  ->
                  (function
                    | round__val_rml_177  ->
                        (function
                          | pos__val_rml_178  ->
                              (let side__val_rml_179 =
                                     Stdlib.(+.)
                                       (Stdlib.( *. )
                                         (Stdlib.sqrt
                                           (Stdlib.float_of_int
                                             nodes__val_rml_175))
                                         30.)
                                       1.
                                 in
                                let speed__val_rml_180 =
                                      Stdlib.(+.)
                                        1.
                                        (Stdlib.float_of_int
                                          (Stdlib.(mod)
                                            (Stdlib.(+)
                                              id__val_rml_176
                                              round__val_rml_177)
                                            5))
                                   in
                                  let dir__val_rml_181 =
                                        Stdlib.(mod)
                                          (Stdlib.(+)
                                            (Stdlib.( * ) id__val_rml_176 13)
                                            (Stdlib.( * )
                                              round__val_rml_177 7))
                                          8
                                     in
                                    let (dx__val_rml_182, dy__val_rml_183) =
                                          (match dir__val_rml_181 with
                                           | (0)  ->
                                               ((0.), speed__val_rml_180)
                                           | 1  ->
                                               (speed__val_rml_180,
                                                speed__val_rml_180)
                                           | 2  -> (speed__val_rml_180, (0.))
                                           | 3  ->
                                               (speed__val_rml_180,
                                                (Stdlib.(~-.)
                                                  speed__val_rml_180))
                                           | 4  ->
                                               ((0.),
                                                (Stdlib.(~-.)
                                                  speed__val_rml_180))
                                           | 5  ->
                                               ((Stdlib.(~-.)
                                                  speed__val_rml_180),
                                                (Stdlib.(~-.)
                                                  speed__val_rml_180))
                                           | 6  ->
                                               ((Stdlib.(~-.)
                                                  speed__val_rml_180),
                                                (0.))
                                           | _  ->
                                               ((Stdlib.(~-.)
                                                  speed__val_rml_180),
                                                speed__val_rml_180)
                                           )
                                       in
                                      {x=(Stdlib.min
                                           (Stdlib.(-.) side__val_rml_179 1.)
                                           (Stdlib.max
                                             (0.)
                                             (Stdlib.(+.)
                                               (pos__val_rml_178).x
                                               dx__val_rml_182)));
                                       y=(Stdlib.min
                                           (Stdlib.(-.) side__val_rml_179 1.)
                                           (Stdlib.max
                                             (0.)
                                             (Stdlib.(+.)
                                               (pos__val_rml_178).y
                                               dy__val_rml_183)))})
                          )
                    )
              )
        ) 
;;
let network_area_index =
      (function
        | area_cols__val_rml_185  ->
            (function
              | area_size__val_rml_186  ->
                  (function
                    | pos__val_rml_187  ->
                        (let clamp__val_rml_188 =
                               (function
                                 | v__val_rml_189  ->
                                     Stdlib.max
                                       (0)
                                       (Stdlib.min
                                         (Stdlib.(-)
                                           area_cols__val_rml_185 1)
                                         v__val_rml_189)
                                 )
                           in
                          let i__val_rml_190 =
                                clamp__val_rml_188
                                  (Stdlib.int_of_float
                                    (Stdlib.(/.)
                                      (pos__val_rml_187).x
                                      area_size__val_rml_186))
                             in
                            let j__val_rml_191 =
                                  clamp__val_rml_188
                                    (Stdlib.int_of_float
                                      (Stdlib.(/.)
                                        (pos__val_rml_187).y
                                        area_size__val_rml_186))
                               in
                              Stdlib.(+)
                                (Stdlib.( * )
                                  i__val_rml_190 area_cols__val_rml_185)
                                j__val_rml_191)
                    )
              )
        ) 
;;
let network_update_table =
      (function
        | node__val_rml_193  ->
            (function
              | info__val_rml_194  ->
                  Array.set
                    (node__val_rml_193).known_x
                    (info__val_rml_194).info_id
                    (info__val_rml_194).info_pos.x;
                    Array.set
                      (node__val_rml_193).known_y
                      (info__val_rml_194).info_id
                      (info__val_rml_194).info_pos.y;
                    Array.set
                      (node__val_rml_193).known_date
                      (info__val_rml_194).info_id
                      (info__val_rml_194).info_date
              )
        ) 
;;
let network_select_neighbors =
      (function
        | node__val_rml_196  ->
            (function
              | infos__val_rml_197  ->
                  (function
                    | coverage2__val_rml_198  ->
                        List.fold_left
                          (function
                            | acc__val_rml_199  ->
                                (function
                                  | info__val_rml_200  ->
                                      if
                                        Stdlib.(&&)
                                          (Stdlib.(<>)
                                            (info__val_rml_200).info_id
                                            (node__val_rml_196).node_id)
                                          (Stdlib.(<=)
                                            (network_distance2
                                              (node__val_rml_196).pos
                                              (info__val_rml_200).info_pos)
                                            coverage2__val_rml_198)
                                        then
                                        (network_update_table
                                           node__val_rml_196
                                           info__val_rml_200;
                                          info__val_rml_200 ::
                                            acc__val_rml_199)
                                        else acc__val_rml_199
                                  )
                            )
                          ([]) infos__val_rml_197
                    )
              )
        ) 
;;
let network_message_dest =
      (function
        | nodes__val_rml_202  ->
            (function
              | id__val_rml_203  ->
                  (function
                    | round__val_rml_204  ->
                        (let dest__val_rml_205 =
                               Stdlib.(mod)
                                 (Stdlib.(+)
                                   (Stdlib.(+)
                                     id__val_rml_203
                                     (Stdlib.( * ) round__val_rml_204 17))
                                   11)
                                 nodes__val_rml_202
                           in
                          if Stdlib.(=) dest__val_rml_205 id__val_rml_203
                            then
                            Stdlib.(mod)
                              (Stdlib.(+) dest__val_rml_205 1)
                              nodes__val_rml_202
                            else dest__val_rml_205)
                    )
              )
        ) 
;;
let network_has_message =
      (function
        | id__val_rml_207  ->
            (function
              | round__val_rml_208  ->
                  Stdlib.(<)
                    (Stdlib.(mod)
                      (Stdlib.(+)
                        (Stdlib.( * ) id__val_rml_207 31)
                        (Stdlib.( * ) round__val_rml_208 17))
                      100)
                    35
              )
        ) 
;;
let rec network_route_loop =
          (function
            | all_nodes__val_rml_210  ->
                (function
                  | dest_id__val_rml_211  ->
                      (function
                        | current_id__val_rml_212  ->
                            (function
                              | hops__val_rml_213  ->
                                  (function
                                    | checksum__val_rml_214  ->
                                        (let current__val_rml_215 =
                                               Array.get
                                                 all_nodes__val_rml_210
                                                 current_id__val_rml_212
                                           in
                                          if
                                            Stdlib.(=)
                                              current_id__val_rml_212
                                              dest_id__val_rml_211
                                            then
                                            Stdlib.(+)
                                              (Stdlib.(+)
                                                checksum__val_rml_214
                                                hops__val_rml_213)
                                              1
                                            else
                                            if
                                              Stdlib.(>) hops__val_rml_213 16
                                              then
                                              Stdlib.(+)
                                                (Stdlib.(+)
                                                  checksum__val_rml_214
                                                  hops__val_rml_213)
                                                1
                                              else
                                              if
                                                Stdlib.(<)
                                                  (Array.get
                                                    (current__val_rml_215).known_date
                                                    dest_id__val_rml_211)
                                                  (0)
                                                then
                                                Stdlib.(+)
                                                  (Stdlib.(+)
                                                    checksum__val_rml_214
                                                    hops__val_rml_213)
                                                  1
                                                else
                                                (let dest_pos__val_rml_216 =
                                                       {x=(Array.get
                                                            (current__val_rml_215).known_x
                                                            dest_id__val_rml_211);
                                                        y=(Array.get
                                                            (current__val_rml_215).known_y
                                                            dest_id__val_rml_211)}
                                                   in
                                                  let current_dist__val_rml_217
                                                        =
                                                        network_distance2
                                                          (current__val_rml_215).pos
                                                          dest_pos__val_rml_216
                                                     in
                                                    let best__val_rml_218 =
                                                          List.fold_left
                                                            (function
                                                              | best__val_rml_219
                                                                   ->
                                                                  (function
                                                                    | 
                                                                    info__val_rml_220
                                                                     ->
                                                                    (let 
                                                                    d__val_rml_221
                                                                    =
                                                                    network_distance2
                                                                    (info__val_rml_220).info_pos
                                                                    dest_pos__val_rml_216
                                                                     in
                                                                    match 
                                                                    best__val_rml_219 with
                                                                    | 
                                                                    None when
                                                                    Stdlib.(<)
                                                                    d__val_rml_221
                                                                    current_dist__val_rml_217 ->
                                                                    Some
                                                                    ((info__val_rml_220).info_id,
                                                                    d__val_rml_221)
                                                                    | 
                                                                    Some
                                                                    ((_,
                                                                    best_d__val_rml_222))
                                                                    when
                                                                    Stdlib.(<)
                                                                    d__val_rml_221
                                                                    best_d__val_rml_222 ->
                                                                    Some
                                                                    ((info__val_rml_220).info_id,
                                                                    d__val_rml_221)
                                                                    | 
                                                                    Some
                                                                    ((best_id__val_rml_223,
                                                                    best_d__val_rml_224))
                                                                    when
                                                                    Stdlib.(&&)
                                                                    (Stdlib.(=)
                                                                    d__val_rml_221
                                                                    best_d__val_rml_224)
                                                                    (Stdlib.(<)
                                                                    (info__val_rml_220).info_id
                                                                    best_id__val_rml_223) ->
                                                                    Some
                                                                    ((info__val_rml_220).info_id,
                                                                    d__val_rml_221)
                                                                    | 
                                                                    _  ->
                                                                    best__val_rml_219
                                                                    ) )
                                                              )
                                                            None
                                                            (current__val_rml_215).neighbors
                                                       in
                                                      match best__val_rml_218 with
                                                      | None  ->
                                                          Stdlib.(+)
                                                            (Stdlib.(+)
                                                              checksum__val_rml_214
                                                              hops__val_rml_213)
                                                            1
                                                      | Some
                                                          ((next_id__val_rml_225,
                                                            _))
                                                           ->
                                                          network_route_loop
                                                            all_nodes__val_rml_210
                                                            dest_id__val_rml_211
                                                            next_id__val_rml_225
                                                            (Stdlib.(+)
                                                              hops__val_rml_213
                                                              1)
                                                            (Stdlib.(+)
                                                              (Stdlib.(+)
                                                                checksum__val_rml_214
                                                                current_id__val_rml_212)
                                                              next_id__val_rml_225)
                                                      ))
                                    )
                              )
                        )
                  )
            ) 
;;
let network_route =
      (function
        | nodes__val_rml_227  ->
            (function
              | all_nodes__val_rml_228  ->
                  (function
                    | src_id__val_rml_229  ->
                        (function
                          | dest_id__val_rml_230  ->
                              if Stdlib.(<=) nodes__val_rml_227 1 then 
                                (0) else
                                network_route_loop
                                  all_nodes__val_rml_228
                                  dest_id__val_rml_230
                                  src_id__val_rml_229 (0) (0)
                          )
                    )
              )
        ) 
;;
let rec network_node_process =
          (function
            | id__val_rml_232  ->
                (function
                  | round__val_rml_233  ->
                      (function
                        | rounds__val_rml_234  ->
                            (function
                              | nodes__val_rml_235  ->
                                  (function
                                    | area_cols__val_rml_236  ->
                                        (function
                                          | area_size__val_rml_237  ->
                                              (function
                                                | coverage__val_rml_238  ->
                                                    (function
                                                      | coverage2__val_rml_239
                                                           ->
                                                          (function
                                                            | hello__val_rml_240
                                                                 ->
                                                                (function
                                                                  | all_nodes__val_rml_241
                                                                     ->
                                                                    (function
                                                                    | checksum__val_rml_242
                                                                     ->
                                                                    ((function
                                                                    | ()  ->
                                                                    Lco_ctrl_tree_record.rml_if
                                                                    (function
                                                                    | ()  ->
                                                                    Stdlib.(>=)
                                                                    round__val_rml_233
                                                                    rounds__val_rml_234
                                                                    )
                                                                    (Lco_ctrl_tree_record.rml_compute
                                                                    (function
                                                                    | ()  ->
                                                                    () ))
                                                                    (Lco_ctrl_tree_record.rml_def
                                                                    (function
                                                                    | ()  ->
                                                                    Array.get
                                                                    all_nodes__val_rml_241
                                                                    id__val_rml_232
                                                                    )
                                                                    (function
                                                                    | self__val_rml_243
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_seq
                                                                    (Lco_ctrl_tree_record.rml_compute
                                                                    (function
                                                                    | ()  ->
                                                                    self__val_rml_243.date
                                                                    <-
                                                                    Stdlib.(+)
                                                                    (self__val_rml_243).date
                                                                    1;
                                                                    self__val_rml_243.pos
                                                                    <-
                                                                    network_move
                                                                    nodes__val_rml_235
                                                                    id__val_rml_232
                                                                    round__val_rml_233
                                                                    (self__val_rml_243).pos
                                                                    ))
                                                                    (Lco_ctrl_tree_record.rml_def
                                                                    (function
                                                                    | ()  ->
                                                                    {info_id=
                                                                    (id__val_rml_232);
                                                                    info_pos=
                                                                    (self__val_rml_243).pos;
                                                                    info_date=
                                                                    (self__val_rml_243).date}
                                                                    )
                                                                    (function
                                                                    | info__val_rml_244
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_def
                                                                    (function
                                                                    | ()  ->
                                                                    Stdlib.int_of_float
                                                                    (Stdlib.(/.)
                                                                    (Stdlib.(-.)
                                                                    (info__val_rml_244).info_pos.x
                                                                    coverage__val_rml_238)
                                                                    area_size__val_rml_237)
                                                                    )
                                                                    (function
                                                                    | left__val_rml_245
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_def
                                                                    (function
                                                                    | ()  ->
                                                                    Stdlib.int_of_float
                                                                    (Stdlib.(/.)
                                                                    (Stdlib.(+.)
                                                                    (info__val_rml_244).info_pos.x
                                                                    coverage__val_rml_238)
                                                                    area_size__val_rml_237)
                                                                    )
                                                                    (function
                                                                    | right__val_rml_246
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_def
                                                                    (function
                                                                    | ()  ->
                                                                    Stdlib.int_of_float
                                                                    (Stdlib.(/.)
                                                                    (Stdlib.(-.)
                                                                    (info__val_rml_244).info_pos.y
                                                                    coverage__val_rml_238)
                                                                    area_size__val_rml_237)
                                                                    )
                                                                    (function
                                                                    | down__val_rml_247
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_def
                                                                    (function
                                                                    | ()  ->
                                                                    Stdlib.int_of_float
                                                                    (Stdlib.(/.)
                                                                    (Stdlib.(+.)
                                                                    (info__val_rml_244).info_pos.y
                                                                    coverage__val_rml_238)
                                                                    area_size__val_rml_237)
                                                                    )
                                                                    (function
                                                                    | up__val_rml_248
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_seq
                                                                    (Lco_ctrl_tree_record.rml_compute
                                                                    (function
                                                                    | ()  ->
                                                                    for
                                                                    i__val_ml_249 = 
                                                                    Stdlib.max
                                                                    (0)
                                                                    left__val_rml_245
                                                                    to
                                                                    Stdlib.min
                                                                    (Stdlib.(-)
                                                                    area_cols__val_rml_236
                                                                    1)
                                                                    right__val_rml_246
                                                                    do
                                                                    for
                                                                    j__val_ml_250 = 
                                                                    Stdlib.max
                                                                    (0)
                                                                    down__val_rml_247
                                                                    to
                                                                    Stdlib.min
                                                                    (Stdlib.(-)
                                                                    area_cols__val_rml_236
                                                                    1)
                                                                    up__val_rml_248
                                                                    do
                                                                    Lco_ctrl_tree_record.rml_expr_emit_val
                                                                    (Array.get
                                                                    hello__val_rml_240
                                                                    (Stdlib.(+)
                                                                    (Stdlib.( * )
                                                                    i__val_ml_249
                                                                    area_cols__val_rml_236)
                                                                    j__val_ml_250))
                                                                    info__val_rml_244
                                                                    done done
                                                                    ))
                                                                    (Lco_ctrl_tree_record.rml_def
                                                                    (function
                                                                    | ()  ->
                                                                    network_area_index
                                                                    area_cols__val_rml_236
                                                                    area_size__val_rml_237
                                                                    (self__val_rml_243).pos
                                                                    )
                                                                    (function
                                                                    | area__val_rml_251
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_await_all
                                                                    (function
                                                                    | ()  ->
                                                                    Array.get
                                                                    hello__val_rml_240
                                                                    area__val_rml_251
                                                                    )
                                                                    (function
                                                                    | visible__val_rml_252
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_seq
                                                                    (Lco_ctrl_tree_record.rml_seq
                                                                    (Lco_ctrl_tree_record.rml_compute
                                                                    (function
                                                                    | ()  ->
                                                                    self__val_rml_243.neighbors
                                                                    <-
                                                                    network_select_neighbors
                                                                    self__val_rml_243
                                                                    visible__val_rml_252
                                                                    coverage2__val_rml_239
                                                                    ))
                                                                    Lco_ctrl_tree_record.rml_pause)
                                                                    (Lco_ctrl_tree_record.rml_if
                                                                    (function
                                                                    | ()  ->
                                                                    network_has_message
                                                                    id__val_rml_232
                                                                    round__val_rml_233
                                                                    )
                                                                    (Lco_ctrl_tree_record.rml_def
                                                                    (function
                                                                    | ()  ->
                                                                    network_message_dest
                                                                    nodes__val_rml_235
                                                                    id__val_rml_232
                                                                    round__val_rml_233
                                                                    )
                                                                    (function
                                                                    | dest__val_rml_253
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_seq
                                                                    (Lco_ctrl_tree_record.rml_seq
                                                                    (Lco_ctrl_tree_record.rml_compute
                                                                    (function
                                                                    | ()  ->
                                                                    Stdlib.(:=)
                                                                    checksum__val_rml_242
                                                                    (Stdlib.(+)
                                                                    (Stdlib.(!)
                                                                    checksum__val_rml_242)
                                                                    (network_route
                                                                    nodes__val_rml_235
                                                                    all_nodes__val_rml_241
                                                                    id__val_rml_232
                                                                    dest__val_rml_253))
                                                                    ))
                                                                    Lco_ctrl_tree_record.rml_pause)
                                                                    (Lco_ctrl_tree_record.rml_run
                                                                    (function
                                                                    | ()  ->
                                                                    network_node_process
                                                                    id__val_rml_232
                                                                    (Stdlib.(+)
                                                                    round__val_rml_233
                                                                    1)
                                                                    rounds__val_rml_234
                                                                    nodes__val_rml_235
                                                                    area_cols__val_rml_236
                                                                    area_size__val_rml_237
                                                                    coverage__val_rml_238
                                                                    coverage2__val_rml_239
                                                                    hello__val_rml_240
                                                                    all_nodes__val_rml_241
                                                                    checksum__val_rml_242
                                                                    )) ))
                                                                    (Lco_ctrl_tree_record.rml_compute
                                                                    (function
                                                                    | ()  ->
                                                                    () ))) )
                                                                    )) ) ) )
                                                                    ) )) )) ):
                                                                    (_)
                                                                    Lco_ctrl_tree_record.process)
                                                                    )
                                                                  )
                                                            )
                                                      )
                                                )
                                          )
                                    )
                              )
                        )
                  )
            ) 
;;
let rec network_nodes =
          (function
            | id__val_rml_255  ->
                (function
                  | nodes__val_rml_256  ->
                      (function
                        | rounds__val_rml_257  ->
                            (function
                              | area_cols__val_rml_258  ->
                                  (function
                                    | area_size__val_rml_259  ->
                                        (function
                                          | coverage__val_rml_260  ->
                                              (function
                                                | coverage2__val_rml_261  ->
                                                    (function
                                                      | hello__val_rml_262
                                                           ->
                                                          (function
                                                            | kill__val_rml_263
                                                                 ->
                                                                (function
                                                                  | all_nodes__val_rml_264
                                                                     ->
                                                                    (function
                                                                    | checksum__val_rml_265
                                                                     ->
                                                                    ((function
                                                                    | ()  ->
                                                                    Lco_ctrl_tree_record.rml_if
                                                                    (function
                                                                    | ()  ->
                                                                    Stdlib.(>=)
                                                                    id__val_rml_255
                                                                    nodes__val_rml_256
                                                                    )
                                                                    (Lco_ctrl_tree_record.rml_compute
                                                                    (function
                                                                    | ()  ->
                                                                    () ))
                                                                    (Lco_ctrl_tree_record.rml_par
                                                                    (Lco_ctrl_tree_record.rml_until'
                                                                    kill__val_rml_263
                                                                    (Lco_ctrl_tree_record.rml_run
                                                                    (function
                                                                    | ()  ->
                                                                    network_node_process
                                                                    id__val_rml_255
                                                                    (0)
                                                                    rounds__val_rml_257
                                                                    nodes__val_rml_256
                                                                    area_cols__val_rml_258
                                                                    area_size__val_rml_259
                                                                    coverage__val_rml_260
                                                                    coverage2__val_rml_261
                                                                    hello__val_rml_262
                                                                    all_nodes__val_rml_264
                                                                    checksum__val_rml_265
                                                                    )))
                                                                    (Lco_ctrl_tree_record.rml_run
                                                                    (function
                                                                    | ()  ->
                                                                    network_nodes
                                                                    (Stdlib.(+)
                                                                    id__val_rml_255
                                                                    1)
                                                                    nodes__val_rml_256
                                                                    rounds__val_rml_257
                                                                    area_cols__val_rml_258
                                                                    area_size__val_rml_259
                                                                    coverage__val_rml_260
                                                                    coverage2__val_rml_261
                                                                    hello__val_rml_262
                                                                    kill__val_rml_263
                                                                    all_nodes__val_rml_264
                                                                    checksum__val_rml_265
                                                                    ))) ):
                                                                    (_)
                                                                    Lco_ctrl_tree_record.process)
                                                                    )
                                                                  )
                                                            )
                                                      )
                                                )
                                          )
                                    )
                              )
                        )
                  )
            ) 
;;
let bench_network_routing =
      (function
        | n__val_rml_267  ->
            ((function
               | ()  ->
                   Lco_ctrl_tree_record.rml_def
                     (function
                       | ()  -> effective_network_nodes n__val_rml_267 )
                     (function
                       | nodes__val_rml_268  ->
                           Lco_ctrl_tree_record.rml_def
                             (function
                               | ()  ->
                                   effective_network_rounds n__val_rml_267
                               )
                             (function
                               | rounds__val_rml_269  ->
                                   Lco_ctrl_tree_record.rml_def
                                     (function | ()  -> Stdlib.( *. ) 42. 42.
                                       )
                                     (function
                                       | coverage2__val_rml_271  ->
                                           Lco_ctrl_tree_record.rml_def
                                             (function
                                               | ()  -> Stdlib.( *. ) 42. 2.
                                               )
                                             (function
                                               | area_size__val_rml_272  ->
                                                   Lco_ctrl_tree_record.rml_def
                                                     (function
                                                       | ()  ->
                                                           Stdlib.(+.)
                                                             (Stdlib.( *. )
                                                               (Stdlib.sqrt
                                                                 (Stdlib.float_of_int
                                                                   nodes__val_rml_268))
                                                               30.)
                                                             1.
                                                       )
                                                     (function
                                                       | side__val_rml_273
                                                            ->
                                                           Lco_ctrl_tree_record.rml_def
                                                             (function
                                                               | ()  ->
                                                                   Stdlib.max
                                                                    1
                                                                    (Stdlib.int_of_float
                                                                    (Stdlib.ceil
                                                                    (Stdlib.(/.)
                                                                    side__val_rml_273
                                                                    area_size__val_rml_272)))
                                                               )
                                                             (function
                                                               | area_cols__val_rml_274
                                                                    ->
                                                                   Lco_ctrl_tree_record.rml_def
                                                                    (function
                                                                    | ()  ->
                                                                    Stdlib.( * )
                                                                    area_cols__val_rml_274
                                                                    area_cols__val_rml_274
                                                                    )
                                                                    (function
                                                                    | area_count__val_rml_275
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_def
                                                                    (function
                                                                    | ()  ->
                                                                    Array.init
                                                                    nodes__val_rml_268
                                                                    (function
                                                                    | id__val_rml_277
                                                                     ->
                                                                    (let 
                                                                    pos__val_rml_278
                                                                    =
                                                                    network_initial_pos
                                                                    nodes__val_rml_268
                                                                    id__val_rml_277
                                                                     in
                                                                    let 
                                                                    known_x__val_rml_279
                                                                    =
                                                                    Array.make
                                                                    nodes__val_rml_268
                                                                    (0.)  in
                                                                    let 
                                                                    known_y__val_rml_280
                                                                    =
                                                                    Array.make
                                                                    nodes__val_rml_268
                                                                    (0.)  in
                                                                    let 
                                                                    known_date__val_rml_281
                                                                    =
                                                                    Array.make
                                                                    nodes__val_rml_268
                                                                    (-1)  in
                                                                    Array.set
                                                                    known_x__val_rml_279
                                                                    id__val_rml_277
                                                                    (pos__val_rml_278).x;
                                                                    Array.set
                                                                    known_y__val_rml_280
                                                                    id__val_rml_277
                                                                    (pos__val_rml_278).y;
                                                                    Array.set
                                                                    known_date__val_rml_281
                                                                    id__val_rml_277
                                                                    (0);
                                                                    {node_id=
                                                                    (id__val_rml_277);
                                                                    pos=
                                                                    (pos__val_rml_278);
                                                                    date=
                                                                    ((0));
                                                                    known_x=
                                                                    (known_x__val_rml_279);
                                                                    known_y=
                                                                    (known_y__val_rml_280);
                                                                    known_date=
                                                                    (known_date__val_rml_281);
                                                                    neighbors=
                                                                    (([]))})
                                                                    ) )
                                                                    (function
                                                                    | all_nodes__val_rml_276
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_def
                                                                    (function
                                                                    | ()  ->
                                                                    Stdlib.ref
                                                                    (0) )
                                                                    (function
                                                                    | checksum__val_rml_282
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_signal
                                                                    (function
                                                                    | kill__sig_283
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_def
                                                                    (function
                                                                    | ()  ->
                                                                    Array.init
                                                                    area_count__val_rml_275
                                                                    (function
                                                                    | _  ->
                                                                    (let 
                                                                    h__sig_287
                                                                    =
                                                                    Lco_ctrl_tree_record.rml_global_signal_combine
                                                                    ([])
                                                                    (function
                                                                    | info__val_rml_285
                                                                     ->
                                                                    (function
                                                                    | acc__val_rml_286
                                                                     ->
                                                                    info__val_rml_285
                                                                    ::
                                                                    acc__val_rml_286
                                                                    ) )  in
                                                                    h__sig_287)
                                                                    ) )
                                                                    (function
                                                                    | hello__val_rml_284
                                                                     ->
                                                                    Lco_ctrl_tree_record.rml_seq
                                                                    (Lco_ctrl_tree_record.rml_run
                                                                    (function
                                                                    | ()  ->
                                                                    network_nodes
                                                                    (0)
                                                                    nodes__val_rml_268
                                                                    rounds__val_rml_269
                                                                    area_cols__val_rml_274
                                                                    area_size__val_rml_272
                                                                    42.
                                                                    coverage2__val_rml_271
                                                                    hello__val_rml_284
                                                                    kill__sig_283
                                                                    all_nodes__val_rml_276
                                                                    checksum__val_rml_282
                                                                    ))
                                                                    (Lco_ctrl_tree_record.rml_compute
                                                                    (function
                                                                    | ()  ->
                                                                    if
                                                                    Stdlib.(<=)
                                                                    (Stdlib.(!)
                                                                    checksum__val_rml_282)
                                                                    (0) then
                                                                    Stdlib.failwith
                                                                    "network routing checksum mismatch"
                                                                    else 
                                                                    () )) ) )
                                                                    ) ) )
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
                 | "network_routing"  ->
                     Lco_ctrl_tree_record.rml_run
                       (function
                         | ()  -> bench_network_routing (Stdlib.(!) size) )
                 | x__val_rml_289  ->
                     Lco_ctrl_tree_record.rml_compute
                       (function
                         | ()  ->
                             Stdlib.invalid_arg
                               (Stdlib.(^)
                                 "unknown benchmark: " x__val_rml_289)
                         )
                 )
         ):
        (_) Lco_ctrl_tree_record.process) 
;;
let peak_mb =
      (function
        | ()  ->
            (let st__val_rml_291 = Gc.stat ()  in
              Stdlib.(/.)
                (Stdlib.(/.)
                  (Stdlib.( *. )
                    (Stdlib.float_of_int (st__val_rml_291).Gc.heap_words)
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
                     | t0__val_rml_292  ->
                         Lco_ctrl_tree_record.rml_seq
                           (Lco_ctrl_tree_record.rml_run
                             (function | ()  -> selected ))
                           (Lco_ctrl_tree_record.rml_compute
                             (function
                               | ()  ->
                                   (let t1__val_rml_293 =
                                          Unix.gettimeofday ()
                                      in
                                     Gc.full_major ();
                                       (let time_ms__val_rml_294 =
                                              Stdlib.( *. )
                                                (Stdlib.(-.)
                                                  t1__val_rml_293
                                                  t0__val_rml_292)
                                                1000.
                                          in
                                         let instants__val_rml_295 =
                                               instants_for
                                                 (Stdlib.(!) benchmark)
                                                 (Stdlib.(!) size)
                                            in
                                           let line__val_rml_296 =
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
                                                                   time_ms__val_rml_294)
                                                                 (Stdlib.(^)
                                                                   ","
                                                                   (Stdlib.(^)
                                                                    (Stdlib.string_of_int
                                                                    instants__val_rml_295)
                                                                    (Stdlib.(^)
                                                                    ","
                                                                    (Stdlib.string_of_float
                                                                    (peak_mb
                                                                    ()))))))))))))
                                              in
                                             Stdlib.print_endline
                                               line__val_rml_296;
                                               Stdlib.flush Stdlib.stdout))
                               ))
                     ))
           ):
          (_) Lco_ctrl_tree_record.process) 
;;
