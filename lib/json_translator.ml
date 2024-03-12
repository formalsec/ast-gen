module Json_impl = struct
  type t = Yojson.t

  let string s = `String s
  let bool b = `Bool b
  let obj o = `Assoc o
  let array lst = `List lst
  let number f = `Float f
  let int i = `Int i
  let null = `Null
  let regexp _ = assert false
end

module Json_impl' : Translator_intf.S with type t = Yojson.t = Json_impl

module M =
  Estree_translator.Translate
    (Json_impl')
    (struct
      let include_locs = false
    end)

include M
