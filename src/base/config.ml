open struct
  type kind =
    | Static
    | Dynamic
    | Constant
end

type !'a t =
  { mutable value : 'a
  ; mutable kind : kind
  }

let static (value : 'a) : 'a t = { value; kind = Static }
let dynamic (value : 'a) : 'a t = { value; kind = Dynamic }
let constant (value : 'a) : 'a t = { value; kind = Constant }

let get (config : 'a t) : 'a =
  (match config.kind with Static -> config.kind <- Constant | _ -> ());
  config.value

let set (config : 'a t) (value : 'a) : unit =
  match config.kind with
  | Static ->
    config.value <- value;
    config.kind <- Constant
  | Dynamic -> config.value <- value
  | Constant -> failwith "invalid update to locked config"

let ( ! ) (config : 'a t) : 'a = get config
let ( $= ) (config : 'a t) (value : 'a) = set config value

(* Generic platform configurations *)
let dflt_buf_sz : int t = constant 512
let dflt_htbl_sz : int t = constant 16
