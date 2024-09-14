(lang dune 3.12)

(using dune_site 0.1)

(name ast_gen)

(generate_opam_files true)

(source
 (github formalsec/ast-gen))

(authors "Author Name")

(maintainers "Maintainer Name")

(license "GPL-3.0-only")

(documentation https://url/to/documentation)

(package
 (name ast_gen)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends
  bos
  conf-npm
  cmdliner
  dune
  dune-site
  (flow_parser
   (>= "0.229.1"))
  ocaml
  ocamlgraph
  ppx_import
  yojson)
 (sites
  (share config))
 (tags
  (topics "to describe" your project)))
