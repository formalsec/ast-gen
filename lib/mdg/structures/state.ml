open Structures
open Ast.Grammar
module Graph = Graph'


type state = {
  graph : Graph.t;
  store : Store.t;
  this  : LocationSet.t;
  functions : FunctionInfo.t;
}

let empty_state (register : unit -> unit) (functions : FunctionInfo.t) = { 
  graph = Graph.empty register; 
  store = Store.empty register; 
  this  = Store.this_loc;
  functions = functions;
}

let copy ({graph; store; _} as state : state) : state = 
  { state with 
     graph = Graph.copy graph;
     store = Store.copy store;
  }
  



