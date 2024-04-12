(lang dune 3.12)

(cram enable)

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
 (depends ocaml dune (flow_parser (>= "0.229.1")) cmdliner yojson)
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
