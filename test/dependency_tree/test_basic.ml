open Graphjs_base
open Test

let%test "unknown_file" =
  Analysis.basic "main/unknown.js" @@ Res.unknown_path "main/unknown.js"

let%test "single_file" =
  let single = Fmt.str "%S : {}" "main/single.js" in
  let dep_tree = Fmt.str "{ %s }" single in
  Analysis.basic "main/single.js" @@ Res.ok dep_tree

let%test "double_file" =
  let double = Fmt.str "%S : {}" "main/double.js" in
  let dep_tree = Fmt.str "{ %s }" double in
  Analysis.basic "main/double.js" @@ Res.ok dep_tree

let%test "triple_file" =
  let triple = Fmt.str "%S : {}" "main/triple.js" in
  let dep_tree = Fmt.str "{ %s }" triple in
  Analysis.basic "main/triple.js" @@ Res.ok dep_tree

let%test "recursive_file" =
  let foo = Fmt.str "%S : {}" "recursive/foo.js" in
  let dep_tree = Fmt.str "{ %s }" foo in
  Analysis.basic "recursive/foo.js" @@ Res.ok dep_tree

let%test "directory_path" =
  Analysis.basic "main/" @@ Res.invalid_directory "main/"

let%test "stdlib_dependency" =
  let stdlib = Fmt.str "%S : {}" "stdlib/stdlib.js" in
  let dep_tree = Fmt.str "{ %s }" stdlib in
  Analysis.basic "stdlib/stdlib.js" @@ Res.ok dep_tree
