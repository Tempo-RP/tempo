let () =
  Ppxlib.Driver.register_transformation "tempo_ppx_test_driver"
    ~rules:
      [
        Ppxlib.Context_free.Rule.extension Tempo_ppx_expander.parallel_extension
      ; Ppxlib.Context_free.Rule.extension Tempo_ppx_expander.when_extension
      ; Ppxlib.Context_free.Rule.extension Tempo_ppx_expander.watch_extension
      ];
  Ppxlib.Driver.standalone ()
