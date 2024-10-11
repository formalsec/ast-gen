open Cmdliner

module ExitCodes = struct
  let ok = Cmd.Exit.ok
  let deptree = 2
  let parsejs = 3
  let normalize = 4
  let term = 122
  let generic = Cmd.Exit.some_error
  let client = Cmd.Exit.cli_error
  let internal = Cmd.Exit.internal_error
end

module Exits = struct
  open Cmd.Exit

  let common = info ~doc:"on terminal error" ExitCodes.term :: defaults

  let parse =
    [ info ~doc:"on Dependency Tree generation error" ExitCodes.deptree
    ; info ~doc:"on JavaScript parsing error" ExitCodes.parsejs
    ; info ~doc:"on JavaScript normalization error" ExitCodes.normalize ]
end

module CommonOpts = struct
  let debug =
    let docs = Manpage.s_common_options in
    let docv = "LEVEL" in
    let doc =
      "Debug level used within the Graph.js application. Options include: (1) \
       'none' for hiding all Graph.js logs; (2) 'warn' [default] for showing \
       Graph.js warnings; (3) 'info' to additionally show the information logs \
       and program execution stage; and (4) 'full' to show all, including \
       debug prints." in
    let levels = Arg.enum Enums.DebugLvl.(args all) in
    Arg.(value & opt levels Warn & info [ "debug" ] ~docs ~docv ~doc)

  let colorless =
    let docs = Manpage.s_common_options in
    let doc =
      "Generate colorless output. This flag might be necessary for terminals \
       lacking 16-ANSI-color support." in
    Arg.(value & flag & info [ "colorless" ] ~docs ~doc)
end

module GraphjsOpts = struct
  let mode =
    let docv = "MODE" in
    let doc =
      "Analysis mode used in a Graph.js execution. Options include (1) 'basic' \
       where the attacker controlls all the parameters from all the functions; \
       (2): 'single-file' where the attacker controlls the functions exported \
       by the input file; and (3) 'multi-file' where the attacker controlls \
       the functions that were exported by the 'main' file of the module." in
    let modes = Arg.enum Enums.AnalysisMode.(args all) in
    Arg.(value & opt modes SingleFile & info [ "m"; "mode" ] ~docv ~doc)
end

module ParseOpts = struct
  let input =
    let open Fs.Parser in
    let docv = "FILE|DIR" in
    let doc = "Path to the JavaScript file." in
    Arg.(required & pos 0 (some valid_fpath) None & info [] ~docv ~doc)

  let output =
    let open Fs.Parser in
    let docv = "FILE" in
    let doc = "Path to store the parsed JavaScript file." in
    Arg.(value & opt (some fpath) None & info [ "o"; "output" ] ~docv ~doc)
end

module ParseCmd = struct
  let name = "parse"
  let sdocs = Manpage.s_common_options
  let doc = "Parses and parses a JavaScript Program"

  let description =
    [| "Given a JavaScript (.js) file, parses the program using the \
        open-source parser of Flow (https://flow.org/) and then parses it, \
        producing a simplified core subset of JavaScript. This process \
        involves reducing complex language constructs and eliminating \
        redundant statements and expressions." |]

  let man = [ `S Manpage.s_description; `P (Array.get description 0) ]
  let man_xrefs = []
  let exits = Exits.parse @ Exits.common
end

module Application = struct
  let name = "graphjs"
  let sdocs = Manpage.s_common_options
  let doc = "MDG-based vulnarability detection for JavaScript"
  let version = "0.1.0"

  let description =
    [| "Graph.js is a static vulnerability scanner specialized in analyzing \
        npm packages and detecting taint-style and prototype pollution \
        vulnerabilities. Its execution flow consists of three phases: program \
        normalization, graph construction, and graph queries."
     ; "In the first phase, Graph.js parses the complete JavaScript program \
        using the open-source parser from Flow (https://flow.org/), a static \
        type checker for JavaScript developed by Meta. Since JavaScript is a \
        notoriously difficult language to analyze, Graph.js parses the \
        resulting AST by simplifying complex language elements and removing \
        all redundant statements and expressions."
     ; "In the second phase, Graph.js builds a Multiversion Dependency Graph \
        (MDG) of the parsed program. This graph-based data structure merges \
        into a single representation the abstract syntax tree, control flow \
        graph, and data dependency graph."
     ; "In the third phase, Graph.js runs several built-in queries on the \
        graph using its internal query engine. These queries aim to identify \
        vulnerable code patterns, such as data dependency paths connecting \
        tainted sources to dangerous sinks. Graph.js allows for the \
        configuration of both program sources and sinks."
     ; "Use graphjs <command> --help for more information on a specific \
        command." |]

  let man =
    [ `S Manpage.s_description; `P (Array.get description 0)
    ; `P (Array.get description 1); `P (Array.get description 2)
    ; `P (Array.get description 3); `P (Array.get description 4)
    ; `S Manpage.s_common_options
    ; `P "These options are common to all commands."; `S Manpage.s_bugs
    ; `P "Check bug reports at https://github.com/formalsec/ast-gen/issues." ]

  let man_xrefs = []
  let exits = Exits.common
end
