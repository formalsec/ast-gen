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
  let jsmodel = 3
  let export_mdg = 4
  let validate = 5
end

module Exits = struct
  open Cmd.Exit

  let common =
    let terminal = info ~doc:"on terminal error" ExitCodes.term in
    let timeout = info ~doc:"on execution timeout" ExitCodes.timeout in
    terminal :: timeout :: defaults

  let deptree =
    [ info ~doc:"on dependency tree generation error" ExitCodes.deptree ]

  let parse = [ info ~doc:"on JavaScript parsing error" ExitCodes.parsejs ]

  let mdg =
    [ info ~doc:"on JavaScript model parsing error" ExitCodes.jsmodel
    ; info ~doc:"on MDG export error" ExitCodes.export_mdg ]

  let validate = [ info ~doc:"on query validation error" ExitCodes.validate ]
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

  let timeout =
    let doc =
      "Time (in seconds) allocated for the analysis of each file. This flag \
       may not work exactly as expected due to the way timeouts are \
       implemented in Graph.js." in
    let docs = Manpage.s_common_options in
    Arg.(value & opt float Float.max_float & info [ "timeout" ] ~doc ~docs)

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

  let input_files =
    let docv = "FILE..." in
    let doc = "Path to the input files." in
    let parser = Fs.Parser.valid_file in
    Arg.(non_empty & pos_all parser [] & info [] ~docv ~doc)

  let input_dir =
    let docv = "DIR" in
    let doc = "Path to the input directory." in
    let parser = Fs.Parser.valid_dir in
    Arg.(required & pos 0 (some parser) None & info [] ~docv ~doc)

  let input_dirs =
    let docv = "DIR..." in
    let doc = "Path to the input directories." in
    let parser = Fs.Parser.valid_dir in
    Arg.(non_empty & pos_all parser [] & info [] ~docv ~doc)

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
  let multifile =
    let doc =
      "Enables multifile analysis mode for analysing a Node.js package rather \
       than an individual JavaScript file." in
    Arg.(value & flag & info [ "multifile" ] ~doc)

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
  let exits = Exits.common @ Exits.deptree
end

module ParseOpts = struct
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
  let exits = Exits.common @ Exits.deptree @ Exits.parse
end

module MdgOpts = struct
  let jsmodel =
    let docv = "FILE" in
    let doc = "Path to the JavaScript model configuration file." in
    let parser = Fs.Parser.valid_file in
    Arg.(value & opt (some parser) None & info [ "jsmodel" ] ~docv ~doc)

  let unfold_depth =
    let doc =
      "Sets the maximum recursion depth for unfolding function calls during \
       MDG construction. A depth of 1 [default] unfolds functions only if they \
       are not already in the call stack, effectively preventing recursion. \
       Higher values permit deeper levels of recursive call unfolding." in
    Arg.(value & opt int 1 & info [ "unfold-depth" ] ~doc)

  let no_exported_analysis =
    let doc =
      "Run without the exported analysis. This analysis calculates the nodes \
       that are exported by the module and, therefore, controlled by an \
       attacker." in
    Arg.(value & flag & info [ "no-exported-analysis" ] ~doc)

  let no_httpserver_analysis =
    let doc =
      "Run without the http server analysis. This analysis calculates the \
       nodes that are assessable through an http server and, therefore, \
       controlled by an attacker." in
    Arg.(value & flag & info [ "no-httpserver-analysis" ] ~doc)

  let no_tainted_analysis =
    let doc =
      "Run without the tainted analysis. This analysis marks exported nodes as \
       tainted by adding a dependency edge to the Tainted Source node." in
    Arg.(value & flag & info [ "no-tainted-analysis" ] ~doc)

  let no_cleaner_analysis =
    let doc =
      "Run without the cleaner analysis. This analysis removes unused nodes \
       from the graph, according to their type and purpose." in
    Arg.(value & flag & info [ "no-cleaner-analysis" ] ~doc)

  let no_export =
    let doc = "Run without generating the .svg graph format." in
    Arg.(value & flag & info [ "no-export" ] ~doc)

  let no_subgraphs =
    let doc =
      "Run without generating subgraphs in the .svg format. This flag is \
       equivalent to using both --no-func-subgraphs and --no-module-subgraphs."
    in
    Arg.(value & flag & info [ "no-subgraphs" ] ~doc)

  let no_func_subgraphs =
    let doc = "Run without generating function subgraphs in the .svg format." in
    Arg.(value & flag & info [ "no-func-subgraphs" ] ~doc)

  let no_file_subgraphs =
    let doc = "Run without generating file subgraphs in the .svg format." in
    Arg.(value & flag & info [ "no-file-subgraphs" ] ~doc)

  let export_view =
    let doc =
      "Export view when exporting the graph into the .svg format. Options \
       include: (1) 'full' [default] for exporting the complete graph; (2) \
       'calls' for exporting the program's call graph; (3) 'object:<#loc>' for \
       exporting the graph of the object at location <#loc>; (4) \
       'parent:<#loc>' for exporting the graph of the function/module at \
       location <#loc>; (5) 'reaches:<#loc>' for exporting the subgraph that \
       reaches the node at location <#loc>; and (6) 'sinks' for exporting the \
       subgraph that reaches every tainted sink of the program." in
    let parse_f = Enums.ExportView.parse in
    Arg.(value & opt parse_f Full & info [ "export-view" ] ~doc)

  let export_timeout =
    let doc = "Timeout for exporting the graph into the .svg format." in
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
  let exits = Exits.common @ Exits.deptree @ Exits.parse @ Exits.mdg
end

module QueryCmd = struct
  let name = "query"
  let doc = "Executes pre-defined vulnerability queries on a Node.js package"
  let sdocs = Manpage.s_common_options

  let description =
    [| "Given a Node.js package, executes a set of built-in vulnerability \
        queries on the package. Example vulnerabilities include code and \
        command injection, path traversal, and prototype pollution. Note that \
        these queries require the graph to be constructed using the unfold \
        option." |]

  let man = [ `S Manpage.s_description; `P (Array.get description 0) ]
  let man_xrefs = []
  let exits = Exits.common @ Exits.deptree @ Exits.parse @ Exits.mdg
end

module ValidateCmd = struct
  let name = "validate"
  let doc = "Validates the query results for a Node.js package"
  let sdocs = Manpage.s_common_options

  let description =
    [| "Given a Node.js package, executes a set of built-in vulnerability \
        queries on the package, and validates the obtained results. As input, \
        this command expects a directory containing two subdirectories: \
        'src/', which holds the code to be analyzed, and 'expected/', which \
        contains the expected results." |]

  let man = [ `S Manpage.s_description; `P (Array.get description 0) ]
  let man_xrefs = []

  let exits =
    Exits.common @ Exits.deptree @ Exits.parse @ Exits.mdg @ Exits.validate
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
        combines in a single format the abstract syntax tree, control flow \
        graph, and data dependency graph of the given package."
     ; "In the third phase, Graph.js runs several built-in queries on the \
        graph using its internal query engine. These queries aim to identify \
        vulnerabilities, such as code and command injection, path traversal, \
        and prototype pollution."
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
