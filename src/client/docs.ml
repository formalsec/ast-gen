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
  let export_mdg = 3
end

module Exits = struct
  open Cmd.Exit

  let common =
    let terminal = info ~doc:"on terminal error" ExitCodes.term in
    let timeout = info ~doc:"on execution timeout" ExitCodes.timeout in
    terminal :: timeout :: defaults

  let dependencies =
    let dt = info ~doc:"on dependency tree generation error" ExitCodes.deptree in
    [ dt ]

  let parse =
    let parsejs = info ~doc:"on JavaScript parsing error" ExitCodes.parsejs in
    [ parsejs ]

  let mdg =
    let export = info ~doc:"on MDG export error" ExitCodes.export_mdg in
    [ export ]
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

module DependenciesOpts = struct
  let absolute_dependency_paths =
    let doc = "Outputs the dependency tree using absolute paths." in
    Arg.(value & flag & info [ "abs-dep-paths" ] ~doc)
end

module DependenciesCmd = struct
  let name = "dependencies"
  let doc = "Generates the dependency tree of a Node.js package"
  let sdocs = Manpage.s_common_options

  let description =
    [| "Given a Node.js package, generates its dependency tree. This command \
        executes always in multifile mode, since the dependency tree is only \
        meaningful when multiple files are considered." |]

  let man = [ `S Manpage.s_description; `P (Array.get description 0) ]
  let man_xrefs = []
  let exits = Exits.common @ Exits.dependencies
end

module ParseOpts = struct
  let mode =
    let docv = "MODE" in
    let doc =
      "Analysis mode used in a Graph.js execution. Options include: (1) \
       'basic' where the attacker controlls all the parameters from all the \
       functions; (2): 'singlefile' [default] where the attacker controlls the \
       functions exported by the input file; and (3) 'multifile' where the \
       attacker controlls the functions that were exported by the 'main' file \
       of the module." in
    let modes = Arg.enum Enums.AnalysisMode.(args all) in
    Arg.(value & opt modes SingleFile & info [ "mode" ] ~docv ~doc)

  let always_fresh =
    let doc =
      "Always generates a fresh variable when evaluating the result of an \
       expression. During assignments, the normalizer defaults to storing the \
       result of simple expressions directly into the left-hand side variable. \
       Enabling this flag prevents this behavior, ensuring that a fresh \
       variable is always created and then assigned to the left-hand side of \
       the original assignment." in
    Arg.(value & flag & info [ "always-fresh" ] ~doc)

  let disable_hoisting =
    let doc =
      "Disables function hoisting by treating hoisted functions as regular \
       function assignments instead of declarations. Enabling this flag may \
       reduce the complexity of the normalized code but will introduce \
       normalization errors." in
    Arg.(value & flag & info [ "disable-hoisting" ] ~doc)

  let disable_defaults =
    let doc =
      "Disables default value checking and assignment in destructuring \
       assignments and function parameters. Enabling this flag may reduce the \
       complexity of the normalized code but will introduce normalization \
       errors." in
    Arg.(value & flag & info [ "disable-defaults" ] ~doc)

  let disable_short_circuit =
    let doc =
      "Disables short-circuit evaluation of the logical AND, OR, and Nullish \
       Coalescence operators, treating them as standard binary operations \
       instead. Enabling this flag may reduce the complexity of the normalized \
       code but will introduce normalization errors." in
    Arg.(value & flag & info [ "disable-short-circuit" ] ~doc)

  let disable_aliases =
    let doc =
      "Disables function and class aliases during assignment expressions. \
       Enabling this flag may reduce the complexity of the normalized code but \
       will introduce normalization errors." in
    Arg.(value & flag & info [ "disable-aliases" ] ~doc)
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
  let exits = Exits.common @ Exits.dependencies @ Exits.parse
end

module MdgOpts = struct
  let taint_config =
    let docv = "FILE" in
    let doc = "Path to the taint source/sink configuration file." in
    let parser = Fs.Parser.valid_file in
    Arg.(value & opt (some parser) None & info [ "config" ] ~docv ~doc)

  let literal_mode =
    let doc =
      "Configures the handling of literal values in MDG construction. Options \
       include (1) 'single' for a graph with a single literal object; (2) \
       'propwrap' for wrapping literal property values in a new object rather \
       than using the main literal object; and (3) 'multiple' [default] for \
       creating a new literal node for each occurrence of a literal value. \
       Using the 'single' mode may increase construction speed and reduce the \
       graph size, but will introduce graph construction errors." in
    let modes = Arg.enum Enums.LiteralMode.(args all) in
    Arg.(value & opt modes Multiple & info [ "literal-mode" ] ~doc)

  let func_eval_mode =
    let doc =
      "Configures the evaluation of function calls during the MDG \
       construction. Options include: (1) 'opaque' [default] for treating each \
       function as a blackbox, creating a call edge from every call-site to \
       the function's entry point; and (2) 'unfold' for opening each call-site \
       by re-evaluating the function body. The unfold mode also accepts an \
       optional modifier in the form unfold[:<mod>] to control how far to \
       unfold: (1) [absent] for unfolding until the fixpoint is reached; (2) \
       'unfold:rec' for unfolding until a recursive call is reached; (3) \
       'unfold:<depth>' for unfolding until the maximum depth is reached." in
    let parse_f = Enums.FuncEvalMode.parse in
    Arg.(value & opt parse_f Opaque & info [ "eval-func" ] ~doc)

  let no_cleaner_analysis =
    let doc =
      "Run without the cleaner analysis. This analysis removes unused nodes \
       from the graph, according to their type and purpose." in
    Arg.(value & flag & info [ "no-cleaner-analysis" ] ~doc)

  let no_tainted_analysis =
    let doc =
      "Run without the tainted analysis. This analysis marks exported values \
       as tainted sources." in
    Arg.(value & flag & info [ "no-tainted-analysis" ] ~doc)

  let no_export =
    let doc = "Run without generating the .svg graph representation." in
    Arg.(value & flag & info [ "no-export" ] ~doc)

  let no_subgraphs =
    let doc = "Run without generating subgraphs in the .svg representation." in
    Arg.(value & flag & info [ "no-subgraphs" ] ~doc)

  let export_view =
    let doc =
      "Export view when exporting the graph into the .svg representation. \
       Options include: (1) 'full' [default] for exporting the complete graph; \
       (2) 'calls' for exporting the program's call graph; (3) 'object:<#loc>' \
       for exporting the graph of the object at location <#loc>; (4) \
       'function:<#loc>' for exporting the graph of the function at location \
       <#loc>; (5) 'reaches:<#loc>' for exporting the subgraph that reaches \
       the node at location <#loc>; and (6) 'sinks' for exporting the subgraph \
       that reaches every tainted sink of the program." in
    let parse_f = Enums.ExportView.parse in
    Arg.(value & opt parse_f Full & info [ "export-view" ] ~doc)

  let export_timeout =
    let doc = "Timeout for exporting the graph into the .svg representation." in
    Arg.(value & opt int 30 & info [ "export-timeout" ] ~doc)
end

module MdgCmd = struct
  let name = "mdg"
  let doc = "Builds the MDG of a Node.js package"
  let sdocs = Manpage.s_common_options

  let description =
    [| "Given a Node.js package, generates the Multiversion Dependency Graph \
        (MDG) of the package. In addition to the generated graph, this command \
        returns a set of analyses computed on top of that graph. Example \
        analyses include the detection of values exported by the package and \
        tainted locations." |]

  let man = [ `S Manpage.s_description; `P (Array.get description 0) ]
  let man_xrefs = []
  let exits = Exits.common @ Exits.dependencies @ Exits.parse @ Exits.mdg
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
  let exits = Exits.common @ Exits.dependencies @ Exits.parse @ Exits.mdg
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
