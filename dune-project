(lang dune 3.19)

(name tempo)

(version "0.3.0")

(generate_opam_files true)

(source
 (github Tempo-RP/tempo))

(authors "Frederic Dabrowski <frederic.dabrowski@univ-orleans.fr>")

(maintainers "Frederic Dabrowski <frederic.dabrowski@univ-orleans.fr>")

(license "GPL-3.0-or-later")

(documentation https://tempo-rp.github.io/tempo/)

(package
 (name tempo)
 (synopsis "A library for reactive programming in OCaml")
 (description "Tempo is a library for reactive programming in OCaml, based on algebraic effects. It provides constructs for defining and composing reactive processes that can respond to events over time.")
 (depends (ocaml (>= 5.4.1)) (logs (>= 0.10.0)) (mtime (>= 2.1.0))))

(package
 (name tempo-ppx)
 (synopsis "Optional syntax extensions for Tempo")
 (description "A lightweight PPX syntax layer for the Tempo reactive programming library.")
 (depends
  (ocaml (>= 5.4.1))
  (tempo (= :version))
  (ppxlib (>= 0.38.0))))
