(lang dune 3.2)

(using dune_site 0.1)

(generate_opam_files true)

(version 0.1.0)

(name graphjs)

(source
 (github formalsec/ast-gen))

(authors "André Nascimento" "Tomás Tavares")

(maintainers "André Nascimento")

(license "MIT")

(documentation https://github.com/formalsec/ast-gen/)

(package
 (name graphjs)
 (synopsis "MDG-based vulnarability detection for JavaScript")
 (description
  "MDG-based static vulnerability scanner specialized in analyzing npm packages and detecting taint-style and prototype pollution vulnerabilities.")
 (depends
  bos
  cmdliner
  conf-npm
  dune
  dune-site
  (flow_parser
   (>= 0.257.0))
  (ocaml
   (>= "5.2.1"))
  ocamlformat
  ocamlgraph
  ocaml-lsp-server
  (ppx_inline_test :with-test)
  yojson)
 (tags
  ("JavaScript"
   "Node.js"
   "Multiversion Dependency Graph"
   "Vulnerability"
   "Detection"))
 (sites
  (share config)))
