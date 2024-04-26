open Auxiliary.GraphJS
type m = Location.t
type state = {
  graph : Graph.t;
  store : Store.t;
}

let program (_ : m Program.t) : unit * unit = (), ()