open Cmdliner

module ExitCodes = struct
  let ok = Cmd.Exit.ok
  let term = 122
  let generic = Cmd.Exit.some_error
  let client = Cmd.Exit.cli_error
  let internal = Cmd.Exit.internal_error
  let timeout = 126

  (* graphjs specific errors *)
  let deptree = 1
  let parsejs = 2
  let build_mdg = 3
  let export_mdg = 4
end

module Exits = struct
  open Cmd.Exit

  let common =
    let terminal = info ~doc:"on terminal error" ExitCodes.term in
    let timeout = info ~doc:"on execution timeout" ExitCodes.timeout in
    terminal :: timeout :: defaults

  let parse =
    let dt = info ~doc:"on dependency tree generation error" ExitCodes.deptree in
    let parsejs = info ~doc:"on JavaScript parsing error" ExitCodes.parsejs in
    [ dt; parsejs ]

  let mdg =
    let build = info ~doc:"on MDG construction error" ExitCodes.build_mdg in
    let export = info ~doc:"on MDG export error" ExitCodes.export_mdg in
    [ build; export ]
end

module CommonOpts = struct
  let colorless =
    let doc =
      "Generate colorless output. This flag may be required for terminals \
       lacking 16-ANSI-color support." in
    let docs = Manpage.s_common_options in
    Arg.(value & flag & info [ "colorless" ] ~doc ~docs)

  let debug =
    let docv = "LEVEL" in
    let doc =
      "Debug level used within the Graph.js application. Options include: (1) \
       'none' for hiding all Graph.js logs; (2) 'warn' [default] for showing \
       Graph.js warnings; (3) 'info' to additionally show the information logs \
       and program execution stage; and (4) 'full' to show all, including \
       debug prints." in
    let docs = Manpage.s_common_options in
    let debug_lvls = Arg.enum Enums.DebugLvl.(args all) in
    Arg.(value & opt debug_lvls Warn & info [ "debug" ] ~docv ~doc ~docs)

  let verbose =
    let doc = "Run in verbose mode, printing all information generated." in
    let docs = Manpage.s_common_options in
    Arg.(value & flag & info [ "v"; "verbose" ] ~doc ~docs)

  let override =
    let doc = "Override existing files when outputing to the provided path." in
    let docs = Manpage.s_common_options in
    Arg.(value & flag & info [ "override" ] ~doc ~docs)
end

module FileOpts = struct
  let input_file =
    let docv = "FILE" in
    let doc = "Path to the input file." in
    let parser = Fs.Parser.valid_file in
    Arg.(required & pos 0 (some parser) None & info [] ~docv ~doc)

  let input_dir =
    let docv = "FILE" in
    let doc = "Path to the input directory." in
    let parser = Fs.Parser.valid_dir in
    Arg.(required & pos 0 (some parser) None & info [] ~docv ~doc)

  let input_path =
    let docv = "FILE|DIR" in
    let doc = "Path to the input file or directory." in
    let parser = Fs.Parser.valid_fpath in
    Arg.(required & pos 0 (some parser) None & info [] ~docv ~doc)

  let input_paths =
    let docv = "FILE|DIR..." in
    let doc = "Path to the input files or directories." in
    let parser = Fs.Parser.valid_fpath in
    Arg.(non_empty & pos_all parser [] & info [] ~docv ~doc)

  let output_file =
    let docv = "FILE" in
    let doc = "Path to the output file." in
    let parser = Fs.Parser.file in
    Arg.(value & opt (some parser) None & info [ "o"; "output" ] ~docv ~doc)

  let output_dir =
    let docv = "DIR" in
    let doc = "Path to the output directory." in
    let parser = Fs.Parser.dir in
    Arg.(value & opt (some parser) None & info [ "o"; "output" ] ~docv ~doc)

  let output_path =
    let docv = "FILE|DIR" in
    let doc = "Path to the output file or directory." in
    let parser = Fs.Parser.fpath in
    Arg.(value & opt (some parser) None & info [ "o"; "output" ] ~docv ~doc)
end

module ParseOpts = struct
  let mode =
    let docv = "MODE" in
    let doc =
      "Analysis mode used in a Graph.js execution. Options include (1) 'basic' \
       where the attacker controlls all the parameters from all the functions; \
       (2): 'singlefile' where the attacker controlls the functions exported \
       by the input file; and (3) 'multifile' where the attacker controlls the \
       functions that were exported by the 'main' file of the module." in
    let modes = Arg.enum Enums.AnalysisMode.(args all) in
    Arg.(value & opt modes SingleFile & info [ "mode" ] ~docv ~doc)

  let test262_conform_hoisted =
    let doc =
      "Normalizes function hoisting by representing hoisted functions as \
       declarations instead of assignments. This flag is required for testing \
       the normalizer against the Test262 conformance test suite." in
    Arg.(value & flag & info [ "test262-conform-hoisted" ] ~doc)
end

module ParseCmd = struct
  let name = "parse"
  let doc = "Parses and normalizes a Node.js package"
  let sdocs = Manpage.s_common_options

  let description =
    [| "Given a Node.js package, generates its dependency tree. Then parses \
        each dependency using the open-source TypeScript/React parser from \
        Flow (https://flow.org/). Finally, for each parsed dependency, \
        normalizes the resulting AST, in a core subset of JavaScript." |]

  let man = [ `S Manpage.s_description; `P (Array.get description 0) ]
  let man_xrefs = []
  let exits = Exits.common @ Exits.parse
end

module MdgOpts = struct
  let taint_config =
    let docv = "FILE" in
    let doc = "Path to the taint source/sink configuration file." in
    let parser = Fs.Parser.valid_file in
    Arg.(value & opt (some parser) None & info [ "config" ] ~docv ~doc)

  let no_svg =
    let doc = "Run without generating the .svg graph representation." in
    Arg.(value & flag & info [ "no-svg" ] ~doc)

  let no_literal_property_wrapping =
    let doc =
      "Builds the MDG without wrapping property updates on literal values in a \
       new object node. Enabling this flag increases construction speed and \
       reduces the graph size, but may introduce errors in the resulting graph \
       and subsequent analysis." in
    Arg.(value & flag & info [ "no-literal-property-wrapping" ] ~doc)
end

module MdgCmd = struct
  let name = "mdg"
  let doc = "Builds the MDG of a Node.js package"
  let sdocs = Manpage.s_common_options

  let description =
    [| "Given a Node.js package, generates the Multiversion Dependency Graph \
        (MDG) of each module of the package. Then merges all generated MDGs \
        into a single graph that describes the entire package." |]

  let man = [ `S Manpage.s_description; `P (Array.get description 0) ]
  let man_xrefs = []
  let exits = Exits.common @ Exits.parse @ Exits.mdg
end

module AnalyzeCmd = struct
  let name = "analyze"
  let doc = "Performs various static analyzes in a Node.js package"
  let sdocs = Manpage.s_common_options

  let description =
    [| "Given a Node.js package, performs multiple static analyzes to the \
        package. These analyzes include: caller analyses, exported values \
        analyses, taint-style vulnerability detection, and prototype pollution \
        detection." |]

  let man = [ `S Manpage.s_description; `P (Array.get description 0) ]
  let man_xrefs = []
  let exits = Exits.common @ Exits.parse @ Exits.mdg
end

module Application = struct
  let name = "graphjs"
  let sdocs = Manpage.s_common_options
  let doc = "MDG-based vulnerability detection for JavaScript"
  let version = "0.1.0"

  let description =
    [| "Graph.js is a static vulnerability scanner specialized in analyzing \
        Node.js packages and detecting taint-style and prototype pollution \
        vulnerabilities. Its execution flow consists of three phases: program \
        normalization, graph construction, and graph queries."
     ; "In the first phase, Graph.js parses the complete JavaScript program \
        using the open-source parser from Flow (https://flow.org/), a static \
        type checker for JavaScript developed by Meta. Since JavaScript is a \
        notoriously difficult language to analyze, Graph.js normalizes the \
        resulting AST by simplifying complex language constructs and removing \
        all redundant statements and expressions."
     ; "In the second phase, Graph.js builds a Multiversion Dependency Graph \
        (MDG) of the normalized package. This graph-based data structure \
        merges into a single representation the abstract syntax tree, control \
        flow graph, and data dependency graph."
     ; "In the third phase, Graph.js runs several built-in analyzes on the \
        graph using its internal analysis engine. These analyzes aim to \
        identify vulnerable code patterns, such as data dependency paths \
        connecting tainted sources to dangerous sinks. Graph.js allows for the \
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
