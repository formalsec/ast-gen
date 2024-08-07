let basic : string = "basic"
let single_file : string = "single_file"
let multi_file : string = "multi_file"
let default : string = single_file

let is_valid (mode : string) : string =  
  if mode = basic || mode = single_file || mode = multi_file 
    then mode
    else failwith "[ERROR] Invalid mode. Try using: basic, single_file or multi_file"


let is_basic (mode : string) : bool = mode = basic
let is_single_file (mode : string) : bool = mode = single_file
let is_multi_file (mode : string) : bool = mode = multi_file