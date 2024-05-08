open Structures

type state = {
  graph : Graph.t;
  store : Store.t;
  this  : LocationSet.t;
}

let empty_state () = { 
  graph = Graph.empty; 
  store = Store.empty; 
  this  = Store.this_loc
}

let copy ({graph; store; _} as state : state) : state = 
  { state with 
     graph = Graph.copy graph;
     store = Store.copy store;
  }
  



