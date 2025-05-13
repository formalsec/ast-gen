Graph.js MDG Builder: eval sink  
  $ graphjs mdg --no-export eval.js
  [[sink]] eval[#1] -
  [[function]] foo[#9] --< Param(0) >--> this[#10]
  [[function]] foo[#9] --< Param(1) >--> x1[#11]
  this[#10] -
  x1[#11] --< Arg(1) >--> eval(...)[#12]
  eval(...)[#12] --< Call >--> [[sink]] eval[#1]
  eval(...)[#12] --< D >--> $v1[#13]
  $v1[#13] -
  10[#14] --< Arg(1) >--> eval(...)[#15]
  eval(...)[#15] --< Call >--> [[sink]] eval[#1]
  eval(...)[#15] --< D >--> $v2[#16]
  $v2[#16] -

Graph.js MDG Builder: npm sink
  $ graphjs mdg --no-export npm.js
  [[sink]] require[#3] -
  'child_process'[#9] --< Arg(1) >--> require(...)[#10]
  require(...)[#10] --< Call >--> [[sink]] require[#3]
  require(...)[#10] --< D >--> dep[#11]
  dep[#11] -
  [[module]] child_process[#12] --< P(spawn) >--> [[sink]] spawn[#13]
  [[module]] child_process[#12] --< P(execFile) >--> [[sink]] execFile[#14]
  [[module]] child_process[#12] --< P(execSync) >--> [[sink]] execSync[#15]
  [[module]] child_process[#12] --< P(exec) >--> [[sink]] exec[#16]
  [[module]] child_process[#12] --< Arg(0) >--> dep.exec(...)[#20]
  [[module]] child_process[#12] --< Arg(0) >--> dep.exec(...)[#23]
  [[sink]] spawn[#13] -
  [[sink]] execFile[#14] -
  [[sink]] execSync[#15] -
  [[sink]] exec[#16] -
  [[function]] foo[#17] --< Param(0) >--> this[#18]
  [[function]] foo[#17] --< Param(1) >--> x1[#19]
  this[#18] -
  x1[#19] --< Arg(1) >--> dep.exec(...)[#20]
  dep.exec(...)[#20] --< Call >--> [[sink]] exec[#16]
  dep.exec(...)[#20] --< D >--> $v1[#21]
  $v1[#21] -
  10[#22] --< Arg(1) >--> dep.exec(...)[#23]
  dep.exec(...)[#23] --< Call >--> [[sink]] exec[#16]
  dep.exec(...)[#23] --< D >--> $v2[#24]
  $v2[#24] -
