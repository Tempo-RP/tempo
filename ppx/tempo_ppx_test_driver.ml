let () =
  Ppxlib.Driver.register_transformation "tempo_ppx_test_driver"
    ~rules:
      [
        Ppxlib.Context_free.Rule.extension Tempo_ppx_expander.parallel_extension
      ];
  Ppxlib.Driver.standalone ()
