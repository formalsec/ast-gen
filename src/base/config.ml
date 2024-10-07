open struct
  type kind =
    | Static
    | Flexible
    | Constant
end

type !'a t =
  { mutable value : 'a
  ; mutable kind : kind
  }

let static (value : 'a) : 'a t = { value; kind = Static } [@@inline]
let flexible (value : 'a) : 'a t = { value; kind = Flexible } [@@inline]
let constant (value : 'a) : 'a t = { value; kind = Constant } [@@inline]

let get (config : 'a t) : 'a =
  (match config.kind with Static -> config.kind <- Constant | _ -> ());
  config.value

let set (config : 'a t) (value : 'a) : unit =
  match config.kind with
  | Static ->
    config.value <- value;
    config.kind <- Constant
  | Flexible -> config.value <- value
  | Constant -> failwith "invalid update to locked config"

let ( ! ) (config : 'a t) : 'a = get config [@@inline]

(* Platform base configurations *)
let dflt_buf_sz : int t = constant 512
let dflt_htbl_sz : int t = constant 16
