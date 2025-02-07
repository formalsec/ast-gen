type 'a t =
  { next : unit -> 'a
  ; reset : unit -> unit
  }

open struct
  let next (gen : int ref) (step : int) () =
    let counter = !gen in
    gen := counter + step;
    counter

  let reset (counter : int ref) (init : int) () = counter := init
end

let of_numbers ?(init : int = 0) ?(step : int = 1) () : int t =
  let gen = ref init in
  { next = next gen step; reset = reset gen init }

let of_strings ?(init : int = 0) ?(step : int = 1) (base : string) : string t =
  let gen = of_numbers ~init ~step () in
  let next' () = base ^ string_of_int (gen.next ()) in
  { gen with next = next' }
