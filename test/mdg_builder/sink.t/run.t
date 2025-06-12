Graph.js MDG Builder: eval sink  
  $ graphjs mdg --no-export eval.js
  [[sink]] eval[#2] -
  [[function]] foo[#17] -
  10[#18] --< Arg(1) >--> eval(...)[#19]
  eval(...)[#19] --< Call >--> [[sink]] eval[#2]
  eval(...)[#19] --< D >--> $v1[#20]
  $v1[#20] -
  10[#21] --< Arg(1) >--> eval(...)[#22]
  eval(...)[#22] --< Call >--> [[sink]] eval[#2]
  eval(...)[#22] --< D >--> $v2[#23]
  $v2[#23] -
  "tainted"[#24] --< Arg(1) >--> eval(...)[#19]

Graph.js MDG Builder: npm sink
  $ graphjs mdg --no-export npm.js
  [[sink]] require[#3] -
  "child_process"[#17] --< Arg(1) >--> require(...)[#18]
  require(...)[#18] --< Call >--> [[sink]] require[#3]
  require(...)[#18] --< D >--> dep[#19]
  dep[#19] -
  [[module]] child_process[#20] --< P(exec) >--> [[sink]] exec[#21]
  [[module]] child_process[#20] --< P(execFile) >--> [[sink]] execFile[#22]
  [[module]] child_process[#20] --< P(execSync) >--> [[sink]] execSync[#23]
  [[module]] child_process[#20] --< P(spawn) >--> [[sink]] spawn[#24]
  [[module]] child_process[#20] --< Arg(0) >--> child_process.exec(...)[#27]
  [[module]] child_process[#20] --< Arg(0) >--> child_process.exec(...)[#30]
  [[sink]] exec[#21] -
  [[sink]] execFile[#22] -
  [[sink]] execSync[#23] -
  [[sink]] spawn[#24] -
  [[function]] foo[#25] -
  10[#26] --< Arg(1) >--> child_process.exec(...)[#27]
  child_process.exec(...)[#27] --< Call >--> [[sink]] exec[#21]
  child_process.exec(...)[#27] --< D >--> $v1[#28]
  $v1[#28] -
  10[#29] --< Arg(1) >--> child_process.exec(...)[#30]
  child_process.exec(...)[#30] --< Call >--> [[sink]] exec[#21]
  child_process.exec(...)[#30] --< D >--> $v2[#31]
  $v2[#31] -
  "tainted"[#32] --< Arg(1) >--> child_process.exec(...)[#27]
