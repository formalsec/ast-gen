module Const = struct
  let bin_name = "dt"
  let target = "node18"
end

module Commands = struct
  let check_npm_cmd : string = "npm -v > /dev/null 2>&1"
  let check_pkg_cmd : string = "npm exec -- pkg -v > /dev/null 2>&1"
  let install_pkg_cmd : string = "npm i pkg > /dev/null 2>&1"
  let install_npm_deps : string = "npm i -s > /dev/null 2>&1"

  let exec_cmd : string =
    Format.sprintf "npm exec -- pkg %s -t %s -o %s > /dev/null 2>&1"
      Sys.argv.(1) Const.target Const.bin_name
end

open struct
  open Format

  let error (code : int) (format : ('a, formatter, unit, unit) format4) : 'b =
    let pp_log fmt = eprintf "[dt] %t@." fmt |> fun () -> exit code in
    kdprintf pp_log format
end

let () =
  (* Entry point / argument validation *)
  if Array.length Sys.argv < 2 then
    Format.ksprintf failwith "Usage: %s <main_file>@." Sys.argv.(0)

let () =
  (* Installation script *)
  let code = Sys.command Commands.check_npm_cmd in
  if code <> 0 then error code "Please install 'npm'";
  let code = Sys.command Commands.check_pkg_cmd in
  if code <> 0 then begin
    let code = Sys.command Commands.install_pkg_cmd in
    if code <> 0 then error code "Failed to install 'pkg'";
    assert (Sys.command Commands.check_pkg_cmd = 0)
  end

let () =
  (* Execution script *)
  let code = Sys.command Commands.install_npm_deps in
  if code <> 0 then error code "Failed to install project dependencies";
  let code = Sys.command Commands.exec_cmd in
  if code <> 0 then error code "Failed to compile '%s'" Const.bin_name;
  exit 0
