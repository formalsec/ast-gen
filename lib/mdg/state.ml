open Structures
open Normalizer.Structures

type state = {
  graph : Graph.t;
  store : Store.t;
  this  : LocationSet.t;
  functions : FunctionInfo.t;
}

let empty_state (functions : FunctionInfo.t) = { 
  graph = Graph.empty; 
  store = Store.empty; 
  this  = Store.this_loc;
  functions = functions;
}

let copy ({graph; store; _} as state : state) : state = 
  { state with 
     graph = Graph.copy graph;
     store = Store.copy store;
  }
  



