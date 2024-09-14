(lang dune 3.12)

(using dune_site 0.1)

(name graphjs2)

(generate_opam_files true)

(source
 (github formalsec/ast-gen))

(authors "Tomás Tavares")

(maintainers "Tomás Tavares")

(license "MIT")

(documentation https://url/to/documentation)

(package
 (name graphjs2)
 (synopsis "Graph.js new and improved")
 (description "MDG-based static vulnerability scanner specialized in analyzing npm packages and detecting taint-style and prototype pollution vulnerabilities.")
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
