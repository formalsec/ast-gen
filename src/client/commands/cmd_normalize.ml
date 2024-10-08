module Options = struct
  type t =
    { input : Fpath.t
    ; output : Fpath.t option
    }

  let set (input : Fpath.t) (output : Fpath.t option) : t = { input; output }
  [@@inline]
end

let run () (_opts : Options.t) : Status.t = Ok ()
