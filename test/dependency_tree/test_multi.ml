open Test

let%test "unknown_file" =
  Analysis.multi "main/unknown.js" @@ Res.unknown_path "main/unknown.js"

let%test "single_file" =
  let f1 = Fmt.str "%S : {}" "main/f1.js" in
  let dt = Fmt.str "{ %s }" f1 in
  Analysis.multi "main/f1.js" @@ Res.ok dt

let%test "double_file" =
  let f1 = Fmt.str "%S : {}" "main/f1.js" in
  let f2 = Fmt.str "%S : { %s }" "main/f2.js" f1 in
  let dt = Fmt.str "{ %s }" f2 in
  Analysis.multi "main/f2.js" @@ Res.ok dt

let%test "triple_file" =
  let f1 = Fmt.str "%S : {}" "main/f1.js" in
  let f2 = Fmt.str "%S : { %s }" "main/f2.js" f1 in
  let f3 = Fmt.str "%S : { %s, %s }" "main/f3.js" f1 f2 in
  let dt = Fmt.str "{ %s }" f3 in
  Analysis.multi "main/f3.js" @@ Res.ok dt

let%test "directory_file" =
  let f1 = Fmt.str "%S : {}" "directories/dir/f1.js" in
  let f2 = Fmt.str "%S : { %s }" "directories/f2.js" f1 in
  let f3 = Fmt.str "%S : { %s, %s }" "directories/dir/f3.js" f1 f2 in
  let dt = Fmt.str "{ %s }" f3 in
  Analysis.multi "directories/dir/f3.js" @@ Res.ok dt

let%test "recursive_file" =
  let f2_rec = Fmt.str "%S : {}" "recursive/f2.js" in
  let f3_rec = Fmt.str "%S : {}" "recursive/f3.js" in
  let f1 = Fmt.str "%S : { %s, %s }" "recursive/f1.js" f2_rec f3_rec in
  let f2 = Fmt.str "%S : { %s }" "recursive/f2.js" f1 in
  let f3 = Fmt.str "%S : { %s, %s }" "recursive/f3.js" f1 f2 in
  let dt = Fmt.str "{ %s }" f3 in
  Analysis.multi "recursive/f3.js" @@ Res.ok dt

let%test "invalid_directory_path" =
  Analysis.multi "main/" @@ Res.bad_directory "main/"

let%test "invalid_package_path" =
  Analysis.multi "package/invalid/"
  @@ Res.bad_package "package/invalid/main.js" "package/invalid/package.json"

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
