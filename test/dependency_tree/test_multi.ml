open Graphjs_base
open Test

let%test "unknown_file" =
  Analysis.multi "main/unknown.js" @@ Res.unknown_path "main/unknown.js"

let%test "single_file" =
  let single = Fmt.str "%S : {}" "main/single.js" in
  let dep_tree = Fmt.str "{ %s }" single in
  Analysis.multi "main/single.js" @@ Res.ok dep_tree

let%test "double_file" =
  let single = Fmt.str "%S : {}" "main/single.js" in
  let double = Fmt.str "%S : { %s }" "main/double.js" single in
  let dep_tree = Fmt.str "{ %s }" double in
  Analysis.multi "main/double.js" @@ Res.ok dep_tree

let%test "triple_file" =
  let single = Fmt.str "%S : {}" "main/single.js" in
  let double = Fmt.str "%S : { %s }" "main/double.js" single in
  let triple = Fmt.str "%S : { %s, %s }" "main/triple.js" single double in
  let dep_tree = Fmt.str "{ %s }" triple in
  Analysis.multi "main/triple.js" @@ Res.ok dep_tree

let%test "recursive_file" =
  let foo_rec = Fmt.str "%S : {}" "recursive/foo.js" in
  let bar_rec = Fmt.str "%S : {}" "recursive/bar.js" in
  let baz = Fmt.str "%S : { %s, %s }" "recursive/baz.js" foo_rec bar_rec in
  let bar = Fmt.str "%S : { %s }" "recursive/bar.js" baz in
  let foo = Fmt.str "%S : { %s, %s }" "recursive/foo.js" bar baz in
  let dep_tree = Fmt.str "{ %s }" foo in
  Analysis.multi "recursive/foo.js" @@ Res.ok dep_tree

let%test "invalid_directory_path" =
  Analysis.multi "main/" @@ Res.bad_directory "main/"

let%test "invalid_package_path" =
  Analysis.multi "package/invalid/" @@ Res.bad_package "package/invalid/main.js"

let%test "valid_package_path" =
  let main = Fmt.str "%S : {}" "package/valid/main.js" in
  let dep_tree = Fmt.str "{ %s }" main in
  Analysis.multi "package/valid/" @@ Res.ok dep_tree

let%test "invalid_index_path" =
  Analysis.multi "index/invalid/" @@ Res.bad_index "index/invalid/main"

let%test "valid_index_path" =
  let index = Fmt.str "%S : {}" "index/valid/main/index.js" in
  let dep_tree = Fmt.str "{ %s }" index in
  Analysis.multi "index/valid/" @@ Res.ok dep_tree
