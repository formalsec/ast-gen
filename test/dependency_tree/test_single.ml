open Test

let%test "unknown_file" =
  Analysis.single "main/unknown.js" @@ Res.unknown_path "main/unknown.js"

let%test "single_file" =
  let f1 = Fmt.str "%S : {}" "main/f1.js" in
  let dt = Fmt.str "{ %s }" f1 in
  Analysis.single "main/f1.js" @@ Res.ok dt

let%test "double_file" =
  let f2 = Fmt.str "%S : {}" "main/f2.js" in
  let dt = Fmt.str "{ %s }" f2 in
  Analysis.single "main/f2.js" @@ Res.ok dt

let%test "triple_file" =
  let f3 = Fmt.str "%S : {}" "main/f3.js" in
  let dt = Fmt.str "{ %s }" f3 in
  Analysis.single "main/f3.js" @@ Res.ok dt

let%test "directory_file" =
  let f3 = Fmt.str "%S : {}" "directories/dir/f3.js" in
  let deptree = Fmt.str "{ %s }" f3 in
  Analysis.single "directories/dir/f3.js" @@ Res.ok deptree

let%test "recursive_file" =
  let f3 = Fmt.str "%S : {}" "recursive/f3.js" in
  let dt = Fmt.str "{ %s }" f3 in
  Analysis.single "recursive/f3.js" @@ Res.ok dt
