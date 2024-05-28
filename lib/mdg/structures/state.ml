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
  (* function information *)
  functions : FunctionsInfo.t;
  context   : FunctionsInfo.t list;
}

let empty_state = { 
  graph = Graph.empty register; 
  store = Store.empty; 
  this  = Store.this_loc;
  (* function information *)
  functions =  FunctionsInfo.create 1;
  context   = [];
}

let copy ({graph; store; _} as state : state) : state = 
  { state with 
     graph = Graph.copy graph;
     store = Store.copy store;
  }
  



