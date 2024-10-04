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
    Graph.iter_edges (fun from edge -> 
        result := G.add_vertex !result from;
        let edge = G.E.create from (Graph.Edge.label edge) (Graph.Edge.get_to edge) in 
        result := G.add_edge_e !result edge;
    ) graph;
  
    !result
  
  let output (file_path : Fpath.t) (graph : Graph.t) : unit = 
    let dot_file = Fpath.(to_string @@ (file_path / "graph.dot")) in
    let svg_file = Fpath.(to_string @@ (file_path / "graph.svg")) in 
    
    let file = open_out_bin dot_file in
    
    Dot.set_info graph.nodes;
    Dot.output_graph file (convert_graph graph);
    Out_channel.close file;

    let _  = Sys.command ("dot -Tsvg " ^ dot_file ^ " -o " ^ svg_file ^ "; rm " ^ dot_file) in
    ()
end

module CSV = struct
  let output (file_path : Fpath.t) (graph : Graph.t) : unit =
    let nodes_file  = Fpath.(to_string @@ (file_path / "nodes.csv")) in 
    let edges_file  = Fpath.(to_string @@ (file_path / "rels.csv")) in 
    let graph_stats = Fpath.(to_string @@ (file_path / "graph_stats.json")) in

    (* process node information *)
    let out_channel = open_out nodes_file in
    output_string out_channel "Id:ID¿Type¿SubType¿IdentifierName¿Raw¿InternalStructure¿Location¿Code¿Label:LABEL\n";

    Graph.iter_nodes (fun _ node_info  -> 
      let info = [
        Node.get_id        node_info;  (* node id *)
        Node.get_type      node_info;  (* node type *)
        Node.get_subtype   node_info;  (* node subtype *)
        Node.get_id_name   node_info;  (* node identifier name *)
        Node.get_raw       node_info;  (* node raw *)
        Node.get_structure node_info;  (* node internal structure *)
        Node.get_location  node_info;  (* node location *)
        Node.get_code      node_info;  (* node code *)
        Node.get_label     node_info   (* node label *)
      ] in 
      output_string out_channel ((String.concat "¿" info) ^ "\n");
    ) graph;

    close_out out_channel;

    (* process edge information *)
    let out_channel = open_out edges_file in
    output_string out_channel "FromId:START_ID¿ToId:END_ID¿RelationLabel:TYPE¿RelationType¿IdentifierName¿ArgumentIndex¿ParamIndex¿StmtIndex¿ElementIndex¿ExpressionIndex¿MethodIndex¿SourceObjName¿IsProp\n";
    Graph.iter_edges (fun loc edge -> 
      let from_id = Graph.get_node_id graph loc in 
      let to_id = Graph.get_node_id graph (Edge.get_to edge) in 

      let info = [
        from_id                  ;  (* edge from *)
        to_id                    ;  (* edge to *)
        Edge.get_rel_label   edge;  (* edge relation label *)
        Edge.get_rel_type    edge;  (* edge relation type *)
        Edge.get_id_name     edge;  (* edge identifier name *)
        Edge.get_arg_i       edge;  (* edge argument index *)
        Edge.get_par_i       edge;  (* edge param index *)
        Edge.get_stm_i       edge;  (* edge stmt index *)
        Edge.get_elm_i       edge;  (* edge element index *)
        Edge.get_exp_i       edge;  (* edge expression index *)
        Edge.get_met_i       edge;  (* edge method index *)
        Edge.get_src_obj     edge;  (* edge source obj name *)
        Edge.get_dep_of_prop edge;  (* edge is dependency of property *)
      ] in 
      output_string out_channel ((String.concat "¿" info) ^ "\n")
    ) graph;

    close_out out_channel;

    (* save graph stats *)
    let out_channel = open_out graph_stats in
    let edges = string_of_int (Graph.num_edges graph) in 
    let nodes = string_of_int (Graph.num_nodes graph) in
    output_string out_channel ("{ \"edges\": " ^ edges ^ ", \"nodes\": " ^ nodes ^ "}");

    close_out out_channel
end
