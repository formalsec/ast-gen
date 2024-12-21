open Graphjs_base
open Graphjs_share
open Graphjs_parser.Dependency_tree

open struct
  let pwd = Fpath.v (Console.pwd ())

  let expected (exp : string) (res : string) : bool =
    Log.stderr "Expected:@\n%s@\nResult:@\n%s@\n@." exp res;
    false

  let exec (mode : Mode.t) (path : string) : (t, string) Result.t =
    match generate_with_mode mode path with
    | dt -> Ok dt
    | exception Exn fmt -> Error (Fmt.str "%t" fmt)

  let test (mode : Mode.t) (path : string) (exp : (t, string) Result.t) : bool =
    let res = exec mode path in
    match (exp, res) with
    | (Ok dt_exp, Ok dt_res) ->
      if equal dt_exp dt_res then true else expected (str dt_exp) (str dt_res)
    | (Error err_exp, Error err_res) ->
      if String.equal err_exp err_res then true else expected err_exp err_res
    | (Ok dt_exp, Error err_res) -> expected (str dt_exp) err_res
    | (Error err_exp, Ok dt_res) -> expected err_exp (str dt_res)
end

module Analysis = struct
  let basic : string -> (t, string) Result.t -> bool = test Mode.Basic
  let single : string -> (t, string) Result.t -> bool = test Mode.SingleFile
  let multi : string -> (t, string) Result.t -> bool = test Mode.MultiFile
end

module Res = struct
  let err : ('a, Fmt.t, unit, 'b) format4 -> 'a =
    Fmt.kdly (Fmt.str "[%t] %t@\n" Log.Config.(fst !error))

  let ok (structure : string) : (t, string) Result.t =
    create (Json.from_string structure)
    |> map (fun abs -> Fpath.(pwd // abs))
    |> Result.ok

  let unknown_path (path : string) : (t, string) Result.t =
    Error (err "Unable to find the provided path %S." path)

  let invalid_directory (path : string) : (t, string) Result.t =
    Error (err "Unable to perform Single-file analysis in directory %S." path)

  let bad_directory (path : string) : (t, string) Result.t =
    Error (err "Unable to find main module of directory %S." path)

  let bad_package (path : string) : (t, string) Result.t =
    Error (err "Unable to find main module %S of 'package.json'." path)

  let bad_index (path : string) : (t, string) Result.t =
    Error (err "Unable to find 'index.js' in directory %S." path)
end
