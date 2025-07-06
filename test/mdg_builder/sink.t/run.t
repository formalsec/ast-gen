Graph.js MDG Builder: eval sink  
  $ graphjs mdg --no-export eval.js
  [[sink]] eval[#2] -
  [[function]] foo[#19] -
  10[#20] --< Arg(1) >--> eval(...)[#22]
  eval(...)[#22] --< Call >--> [[sink]] eval[#2]
  eval(...)[#22] --< D >--> $v1[#23]
  $v1[#23] -
  10[#24] --< Arg(1) >--> eval(...)[#25]
  eval(...)[#25] --< Call >--> [[sink]] eval[#2]
  eval(...)[#25] --< D >--> $v2[#26]
  $v2[#26] -
  "tainted"[#27] --< Arg(1) >--> eval(...)[#22]

Graph.js MDG Builder: npm sink
  $ graphjs mdg --no-export npm.js
  [[sink]] require[#3] -
  "child_process"[#19] --< Arg(1) >--> require(...)[#20]
  require(...)[#20] --< Call >--> [[sink]] require[#3]
  require(...)[#20] --< D >--> dep[#21]
  dep[#21] -
  [[module]] child_process[#22] --< P(exec) >--> [[sink]] exec[#23]
  [[module]] child_process[#22] --< P(execFile) >--> [[sink]] execFile[#24]
  [[module]] child_process[#22] --< P(execSync) >--> [[sink]] execSync[#25]
  [[module]] child_process[#22] --< P(spawn) >--> [[sink]] spawn[#26]
  [[module]] child_process[#22] --< Arg(0) >--> child_process.exec(...)[#30]
  [[module]] child_process[#22] --< Arg(0) >--> child_process.exec(...)[#33]
  [[sink]] exec[#23] -
  [[sink]] execFile[#24] -
  [[sink]] execSync[#25] -
  [[sink]] spawn[#26] -
  [[function]] foo[#27] -
  10[#28] --< Arg(1) >--> child_process.exec(...)[#30]
  child_process.exec(...)[#30] --< Call >--> [[sink]] exec[#23]
  child_process.exec(...)[#30] --< D >--> $v1[#31]
  $v1[#31] -
  10[#32] --< Arg(1) >--> child_process.exec(...)[#33]
  child_process.exec(...)[#33] --< Call >--> [[sink]] exec[#23]
  child_process.exec(...)[#33] --< D >--> $v2[#34]
  $v2[#34] -
  "tainted"[#35] --< Arg(1) >--> child_process.exec(...)[#30]
