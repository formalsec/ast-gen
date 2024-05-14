module OcamlGraph = Graph
module Graph = Graph'
open Graph
open Structures

module Dot = struct
  module Node = struct
    type t = location
  
    let compare = String.compare
    let hash = Hashtbl.hash
    let equal = String.equal
  end
  
  module Edge = struct
    type t = string
    let compare = String.compare
    let default = "!!!TODO!!!"
  end
  
  module G = OcamlGraph.Persistent.Digraph.ConcreteBidirectionalLabeled(Node)(Edge)
  
  module Dot = OcamlGraph.Graphviz.Dot(struct
     include G (* use the graph module from above *)
     let edge_attributes (_, e, _) = [`Label e; `Color 4711]
     let default_edge_attributes _ = []
     let get_subgraph _ = None
     let vertex_attributes _ = [`Shape `Box]
     let vertex_name v = v
     let default_vertex_attributes _ = []
    let graph_attributes _ = []
  end)
  
  let convert_graph (graph : Graph.t) : G.t =
    let result = ref G.empty in 
    Graph.iter_edges (fun from edegs -> 
        result := G.add_vertex !result from;
        EdgeSet.iter (fun ({_to ; _} as edge) -> 
          let edge = G.E.create from (Graph.Edge.label edge) _to in 
          result := G.add_edge_e !result edge;
        ) edegs
    ) graph;
  
    !result
  
  let output (filename : string) (graph : Graph.t) : unit = 
    let dot_file = filename ^ ".dot" in
    let svg_file = filename ^ ".svg" in 
    let file = open_out_bin dot_file in
    Dot.output_graph file (convert_graph graph);
    let _  = Sys.command ("dot -Tsvg " ^ dot_file ^ " -o " ^ svg_file) in
    ()
end
