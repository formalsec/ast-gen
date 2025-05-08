  $ graphjs mdg --no-export eval.js
  [[sink]] eval[#2] -
  foo[#10] --< Param(0) >--> this[#11]
  foo[#10] --< Param(1) >--> x1[#12]
  this[#11] -
  x1[#12] --< Arg(1) >--> eval(...)[#13]
  eval(...)[#13] --< Call >--> [[sink]] eval[#2]
  eval(...)[#13] --< D >--> $v1[#14]
  $v1[#14] -
  10[#15] --< Arg(1) >--> eval(...)[#16]
  eval(...)[#16] --< Call >--> [[sink]] eval[#2]
  eval(...)[#16] --< D >--> $v2[#17]
  $v2[#17] -

$ graphjs mdg --no-export stdlib.js
[[literal]] --< Arg(1) >--> require(...)[l_1]
[[literal]] --< Arg(1) >--> dep.exec(...)[l_7]
require[f_1] -
require(...)[l_1] --< Call >--> require[f_1]
require(...)[l_1] --< D >--> dep[l_2]
dep[l_2] --< P(exec) >--> dep.exec[l_4]
dep[l_2] --< Arg(0) >--> dep.exec(...)[l_5]
dep[l_2] --< Arg(0) >--> dep.exec(...)[l_7]
import(child_process)[l_3] --< D >--> dep[l_2]
foo[f_2] --< Param(0) >--> this[p_0]
foo[f_2] --< Param(1) >--> x1[p_1]
this[p_0] -
x1[p_1] --< Arg(1) >--> dep.exec(...)[l_5]
dep.exec[l_4] -
dep.exec(...)[l_5] --< Call >--> dep.exec[l_4]
dep.exec(...)[l_5] --< D >--> $v1[l_6]
$v1[l_6] -
dep.exec(...)[l_7] --< Call >--> dep.exec[l_4]
dep.exec(...)[l_7] --< D >--> $v2[l_8]
$v2[l_8] -
