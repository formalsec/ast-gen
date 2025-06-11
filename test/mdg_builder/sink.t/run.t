Graph.js MDG Builder: eval sink  
  $ graphjs mdg --no-export eval.js
  [[sink]] eval[#2] -
  [[function]] defineProperty[#5] -
  [[function]] foo[#17] --< Param(0) >--> this[#18]
  [[function]] foo[#17] --< Param(1) >--> x1[#19]
  this[#18] -
  x1[#19] --< Arg(1) >--> eval(...)[#20]
  eval(...)[#20] --< Call >--> [[sink]] eval[#2]
  eval(...)[#20] --< D >--> $v1[#21]
  $v1[#21] -
  10[#22] --< Arg(1) >--> eval(...)[#23]
  eval(...)[#23] --< Call >--> [[sink]] eval[#2]
  eval(...)[#23] --< D >--> $v2[#24]
  $v2[#24] -

Graph.js MDG Builder: npm sink
  $ graphjs mdg --no-export npm.js
  [[sink]] require[#3] -
  [[function]] defineProperty[#5] -
  'child_process'[#17] --< Arg(1) >--> require(...)[#18]
  require(...)[#18] --< Call >--> [[sink]] require[#3]
  require(...)[#18] --< D >--> dep[#19]
  dep[#19] -
  [[module]] child_process[#20] --< P(exec) >--> [[sink]] exec[#21]
  [[module]] child_process[#20] --< P(execFile) >--> [[sink]] execFile[#22]
  [[module]] child_process[#20] --< P(execSync) >--> [[sink]] execSync[#23]
  [[module]] child_process[#20] --< P(spawn) >--> [[sink]] spawn[#24]
  [[module]] child_process[#20] --< Arg(0) >--> child_process.exec(...)[#28]
  [[module]] child_process[#20] --< Arg(0) >--> child_process.exec(...)[#31]
  [[sink]] exec[#21] -
  [[sink]] execFile[#22] -
  [[sink]] execSync[#23] -
  [[sink]] spawn[#24] -
  [[function]] foo[#25] --< Param(0) >--> this[#26]
  [[function]] foo[#25] --< Param(1) >--> x1[#27]
  this[#26] -
  x1[#27] --< Arg(1) >--> child_process.exec(...)[#28]
  child_process.exec(...)[#28] --< Call >--> [[sink]] exec[#21]
  child_process.exec(...)[#28] --< D >--> $v1[#29]
  $v1[#29] -
  10[#30] --< Arg(1) >--> child_process.exec(...)[#31]
  child_process.exec(...)[#31] --< Call >--> [[sink]] exec[#21]
  child_process.exec(...)[#31] --< D >--> $v2[#32]
  $v2[#32] -
