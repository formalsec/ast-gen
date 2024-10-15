(lang dune 3.2)

(using dune_site 0.1)

(generate_opam_files true)

(version 0.1.0)

(name graphjs)

(source
 (github formalsec/ast-gen))

(authors "Tomás Tavares")

(maintainers "Tomás Tavares" "André Nascimento")

(license "MIT")

(documentation https://github.com/formalsec/ast-gen/)

(package
 (name graphjs)
 (synopsis "MDG-based vulnarability detection for JavaScript")
 (description
  "MDG-based static vulnerability scanner specialized in analyzing npm packages and detecting taint-style and prototype pollution vulnerabilities.")
 (depends
  (ocaml
   (>= "4.14.1"))
  ocamlgraph
  dune
  dune-site
  (ppx_inline_test :with-test)
  yojson
  bos
  cmdliner
  conf-npm
  (flow_parser
   (>= "0.229.1")))
 (tags
  ("JavaScript"
   "Node.js"
   "Multiversion Dependency Graph"
   "Vulnerability"
   "Detection"))
 (sites
  (share config)))
