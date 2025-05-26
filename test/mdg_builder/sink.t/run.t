Graph.js MDG Builder: eval sink  
  $ graphjs mdg --no-export eval.js
  [[sink]] eval[#2] -
  [[function]] foo[#10] --< Param(0) >--> this[#11]
  [[function]] foo[#10] --< Param(1) >--> x1[#12]
  this[#11] -
  x1[#12] --< Arg(1) >--> eval(...)[#13]
  eval(...)[#13] --< Call >--> [[sink]] eval[#2]
  eval(...)[#13] --< D >--> $v1[#14]
  $v1[#14] -
  10[#15] --< Arg(1) >--> eval(...)[#16]
  eval(...)[#16] --< Call >--> [[sink]] eval[#2]
  eval(...)[#16] --< D >--> $v2[#17]
  $v2[#17] -

Graph.js MDG Builder: npm sink
  $ graphjs mdg --no-export npm.js
  [[sink]] require[#4] -
  'child_process'[#10] --< Arg(1) >--> require(...)[#11]
  require(...)[#11] --< Call >--> [[sink]] require[#4]
  require(...)[#11] --< D >--> dep[#12]
  dep[#12] -
  [[module]] child_process[#13] --< P(spawn) >--> [[sink]] spawn[#14]
  [[module]] child_process[#13] --< P(execFile) >--> [[sink]] execFile[#15]
  [[module]] child_process[#13] --< P(execSync) >--> [[sink]] execSync[#16]
  [[module]] child_process[#13] --< P(exec) >--> [[sink]] exec[#17]
  [[module]] child_process[#13] --< Arg(0) >--> dep.exec(...)[#21]
  [[module]] child_process[#13] --< Arg(0) >--> dep.exec(...)[#24]
  [[sink]] spawn[#14] -
  [[sink]] execFile[#15] -
  [[sink]] execSync[#16] -
  [[sink]] exec[#17] -
  [[function]] foo[#18] --< Param(0) >--> this[#19]
  [[function]] foo[#18] --< Param(1) >--> x1[#20]
  this[#19] -
  x1[#20] --< Arg(1) >--> dep.exec(...)[#21]
  dep.exec(...)[#21] --< Call >--> [[sink]] exec[#17]
  dep.exec(...)[#21] --< D >--> $v1[#22]
  $v1[#22] -
  10[#23] --< Arg(1) >--> dep.exec(...)[#24]
  dep.exec(...)[#24] --< Call >--> [[sink]] exec[#17]
  dep.exec(...)[#24] --< D >--> $v2[#25]
  $v2[#25] -
