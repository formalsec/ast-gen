Graph.js MDG Builder: eval sink  
  $ graphjs mdg --no-export eval.js
  [[sink]] eval[#2] -
  [[function]] foo[#7] --< Param(0) >--> this[#8]
  [[function]] foo[#7] --< Param(1) >--> x1[#9]
  this[#8] -
  x1[#9] --< Arg(1) >--> eval(...)[#10]
  eval(...)[#10] --< Call >--> [[sink]] eval[#2]
  eval(...)[#10] --< D >--> $v1[#11]
  $v1[#11] -
  10[#12] --< Arg(1) >--> eval(...)[#13]
  eval(...)[#13] --< Call >--> [[sink]] eval[#2]
  eval(...)[#13] --< D >--> $v2[#14]
  $v2[#14] -

Graph.js MDG Builder: npm sink
  $ graphjs mdg --no-export npm.js
  [[sink]] require[#4] -
  'child_process'[#7] --< Arg(1) >--> require(...)[#8]
  require(...)[#8] --< Call >--> [[sink]] require[#4]
  require(...)[#8] --< D >--> dep[#9]
  dep[#9] -
  [[module]] child_process[#10] --< P(exec) >--> [[sink]] exec[#11]
  [[module]] child_process[#10] --< P(execFile) >--> [[sink]] execFile[#12]
  [[module]] child_process[#10] --< P(execSync) >--> [[sink]] execSync[#13]
  [[module]] child_process[#10] --< P(spawn) >--> [[sink]] spawn[#14]
  [[module]] child_process[#10] --< Arg(0) >--> dep.exec(...)[#18]
  [[module]] child_process[#10] --< Arg(0) >--> dep.exec(...)[#21]
  [[sink]] exec[#11] -
  [[sink]] execFile[#12] -
  [[sink]] execSync[#13] -
  [[sink]] spawn[#14] -
  [[function]] foo[#15] --< Param(0) >--> this[#16]
  [[function]] foo[#15] --< Param(1) >--> x1[#17]
  this[#16] -
  x1[#17] --< Arg(1) >--> dep.exec(...)[#18]
  dep.exec(...)[#18] --< Call >--> [[sink]] exec[#11]
  dep.exec(...)[#18] --< D >--> $v1[#19]
  $v1[#19] -
  10[#20] --< Arg(1) >--> dep.exec(...)[#21]
  dep.exec(...)[#21] --< Call >--> [[sink]] exec[#11]
  dep.exec(...)[#21] --< D >--> $v2[#22]
  $v2[#22] -
