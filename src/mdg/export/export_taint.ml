open Svg_exporter

let node_attr_mod (tainted : Tainted.t) (node : Node.t) (attrs : vertex_attrs) :
    vertex_attrs =
  if Tainted.is_tainted tainted node then `Fontcolor 10027008 :: attrs
  else attrs
