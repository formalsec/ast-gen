open Graphjs_parser.Dependency_tree

let expected (exp : string) (res : string) : bool =
  Log.stderr "Expected:@\n%s@\nResult:@\n%s@\n@." exp res;
  false

let exec (multi : bool) (path : string) : (t, string) Result.t =
  match generate multi (Fpath.v path) with
  | dt -> Ok dt
  | exception Exn fmt -> Error (Fmt.str "%t" fmt)

let test (multi : bool) (path : string) (exp : (t, string) Result.t) : bool =
  let res = exec multi path in
  match (exp, res) with
  | (Ok dt_exp, Ok dt_res) ->
    if equal dt_exp dt_res then true else expected (str dt_exp) (str dt_res)
  | (Error err_exp, Error err_res) ->
    if String.equal err_exp err_res then true else expected err_exp err_res
  | (Ok dt_exp, Error err_res) -> expected (str dt_exp) err_res
  | (Error err_exp, Ok dt_res) -> expected err_exp (str dt_res)

module Analysis = struct
  let single (path : string) (res : (t, string) Result.t) = test false path res
  let multi (path : string) (res : (t, string) Result.t) = test true path res
end

module Res = struct
  let err (fmt : ('a, Fmt.t, unit, 'b) format4) : 'a =
    Fmt.kdly (Fmt.str "[%t] %t@\n" Log.Config.(fst !error)) fmt

  let ok (structure : string) : (t, string) Result.t =
    create (Json.from_string structure) |> Result.ok

  let unknown_path (path : string) : (t, string) Result.t =
    Error (err "Unable to find the provided path %S." path)

  let invalid_directory (path : string) : (t, string) Result.t =
    Error (err "Unable to perform singlefile analysis in directory %S." path)

  let bad_directory (path : string) : (t, string) Result.t =
    Error (err "Unable to find main module of directory %S." path)

  let bad_package (path : string) (package : string) : (t, string) Result.t =
    Error (err "Unable to find %S described in %S." path package)

  let bad_index (path : string) : (t, string) Result.t =
    Error (err "Unable to find 'index.js' in directory %S." path)
end
