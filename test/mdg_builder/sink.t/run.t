Graph.js MDG Builder: eval sink  
  $ graphjs mdg --no-export eval.js
  [[sink]] eval[#2] -
  [[function]] foo[#18] -
  10[#19] --< Arg(1) >--> eval(...)[#21]
  eval(...)[#21] --< Call >--> [[sink]] eval[#2]
  eval(...)[#21] --< D >--> $v1[#22]
  $v1[#22] -
  10[#23] --< Arg(1) >--> eval(...)[#24]
  eval(...)[#24] --< Call >--> [[sink]] eval[#2]
  eval(...)[#24] --< D >--> $v2[#25]
  $v2[#25] -
  "tainted"[#26] --< Arg(1) >--> eval(...)[#21]

Graph.js MDG Builder: npm sink
  $ graphjs mdg --no-export npm.js
  [[sink]] require[#3] -
  "child_process"[#18] --< Arg(1) >--> require(...)[#19]
  require(...)[#19] --< Call >--> [[sink]] require[#3]
  require(...)[#19] --< D >--> dep[#20]
  dep[#20] -
  [[module]] child_process[#21] --< P(exec) >--> [[sink]] exec[#22]
  [[module]] child_process[#21] --< P(execFile) >--> [[sink]] execFile[#23]
  [[module]] child_process[#21] --< P(execSync) >--> [[sink]] execSync[#24]
  [[module]] child_process[#21] --< P(spawn) >--> [[sink]] spawn[#25]
  [[module]] child_process[#21] --< Arg(0) >--> child_process.exec(...)[#29]
  [[module]] child_process[#21] --< Arg(0) >--> child_process.exec(...)[#32]
  [[sink]] exec[#22] -
  [[sink]] execFile[#23] -
  [[sink]] execSync[#24] -
  [[sink]] spawn[#25] -
  [[function]] foo[#26] -
  10[#27] --< Arg(1) >--> child_process.exec(...)[#29]
  child_process.exec(...)[#29] --< Call >--> [[sink]] exec[#22]
  child_process.exec(...)[#29] --< D >--> $v1[#30]
  $v1[#30] -
  10[#31] --< Arg(1) >--> child_process.exec(...)[#32]
  child_process.exec(...)[#32] --< Call >--> [[sink]] exec[#22]
  child_process.exec(...)[#32] --< D >--> $v2[#33]
  $v2[#33] -
  "tainted"[#34] --< Arg(1) >--> child_process.exec(...)[#29]
