open Svg_exporter

let node_attr_mod (tainted : Node.Set.t) (node : Node.t) (attrs : vertex_attrs)
    : vertex_attrs =
  if Node.Set.mem node tainted then `Fontcolor 10027008 :: attrs else attrs
