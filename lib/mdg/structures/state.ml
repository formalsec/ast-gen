open Structures
open Ast.Grammar
module Graph = Graph'

let register, setup, was_changed =
  let bs : bool list ref = ref [] in 
 
  let reg = fun () -> match !bs with 
  	| _ :: bs' -> bs := true :: bs'
  	| _ -> () in
  	
  let push = fun () -> bs := false :: !bs in
   
  let pop = fun () -> match !bs with 
  	| b :: bs' -> bs := bs'; b
  	| _ -> failwith "no element to pop" in 
  
  reg, push, pop;;

type state = {
  graph : Graph.t;
  store : Store.t;
  this  : LocationSet.t;
  functions : FunctionInfo.t;
}

let empty_state (functions : FunctionInfo.t) = { 
  graph = Graph.empty register; 
  store = Store.empty; 
  this  = Store.this_loc;
  functions = functions;
}

let copy ({graph; store; _} as state : state) : state = 
  { state with 
     graph = Graph.copy graph;
     store = Store.copy store;
  }
  



