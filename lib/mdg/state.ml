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

let is_equal (state : state) (state' : state) : bool = 
  Graph.is_equal state.graph state'.graph &&
  Store.is_equal state.store state'.store &&
  LocationSet.equal state.this state'.this
  



