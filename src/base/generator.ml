type 'a t =
  { next : unit -> 'a
  ; reset : unit -> unit
  }

open struct
  let next (counter : int ref) (step : int) () =
    let n = !counter in
    counter := n + step;
    n

  let reset (counter : int ref) (init : int) () = counter := init
end

let of_numbers ?(init : int = 0) ?(step : int = 1) () : int t =
  let counter = ref init in
  { next = next counter step; reset = reset counter init }

let of_strings ?(init : int = 0) ?(step : int = 1) (base : string) : string t =
  let gen = of_numbers ~init ~step () in
  let next' () = base ^ string_of_int (gen.next ()) in
  { gen with next = next' }
