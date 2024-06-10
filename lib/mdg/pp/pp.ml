module OcamlGraph = Graph
module Graph = Graph'
open Graph
open Structures
open Auxiliary.Structures
open Auxiliary.Functions

module Dot = struct
  module DotNode = struct
    type t = location
  
    let compare = String.compare
    let hash = Hashtbl.hash
    let equal = String.equal
  end
  
  module DotEdge = struct
    type t = string
    let compare = String.compare
    let default = "!!!TODO!!!"
  end
  
  module G = OcamlGraph.Persistent.Digraph.ConcreteBidirectionalLabeled(DotNode)(DotEdge)
  
  module Dot = struct 
    let node_info : (Node.t HashTable.t) option ref = ref None 
    let set_info (info : Node.t HashTable.t) : unit =  node_info := Some info 

    module Dot' = OcamlGraph.Graphviz.Dot(struct
     include G (* use the graph module from above *)

     let edge_attributes (_, e, _) = [`Label e; `Color 4711]
     let default_edge_attributes _ = []
     let get_subgraph _ = None
     let vertex_attributes _ = [`Shape `Box]
     let vertex_name v = 
      let node_info = Option.get !node_info in 
      let node = Graph.find_node_opt' node_info v in 
      "\"" ^ map_default ((^) (v ^ " : ") << Node.label) v node ^ "\""

     let default_vertex_attributes _ = []
    let graph_attributes _ = []
  end)
  include Dot'
end
  
  let convert_graph (graph : Graph.t) : G.t =
    let result = ref G.empty in 
    Graph.iter (fun from edegs _ -> 
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
    
    let file = Out_channel.open_bin dot_file in
    Dot.set_info graph.nodes;
    Dot.output_graph file (convert_graph graph);
    Out_channel.close file;

    let _  = Sys.command ("dot -Tsvg " ^ dot_file ^ " -o " ^ svg_file ^ "; rm " ^ dot_file) in
    ()
end
