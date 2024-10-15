open Graphjs_base
open Test

let%test "unknown_file" =
  Analysis.single "main/unknown.js" @@ Res.unknown_path "main/unknown.js"

let%test "single_file" =
  let single = Fmt.str "%S : {}" "main/single.js" in
  let dep_tree = Fmt.str "{ %s }" single in
  Analysis.single "main/single.js" @@ Res.ok dep_tree

let%test "double_file" =
  let double = Fmt.str "%S : {}" "main/double.js" in
  let dep_tree = Fmt.str "{ %s }" double in
  Analysis.single "main/double.js" @@ Res.ok dep_tree

let%test "triple_file" =
  let triple = Fmt.str "%S : {}" "main/triple.js" in
  let dep_tree = Fmt.str "{ %s }" triple in
  Analysis.single "main/triple.js" @@ Res.ok dep_tree

let%test "recursive_file" =
  let foo = Fmt.str "%S : {}" "recursive/foo.js" in
  let dep_tree = Fmt.str "{ %s }" foo in
  Analysis.single "recursive/foo.js" @@ Res.ok dep_tree

let%test "directory_path" =
  Analysis.single "main/" @@ Res.invalid_directory "main/"
