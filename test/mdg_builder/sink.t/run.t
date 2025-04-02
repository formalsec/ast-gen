  $ graphjs mdg --no-export eval.js
  eval[s_1] -
  foo[f_1] --< Param(0) >--> this[p_0]
  foo[f_1] --< Param(1) >--> x1[p_1]
  this[p_0] -
  x1[p_1] --< Arg(1) >--> eval(...)[l_1]
  eval(...)[l_1] --< Call >--> eval[s_1]
  eval(...)[l_1] --< D >--> $v1[l_2]
  $v1[l_2] -
  10[v_2] --< Arg(1) >--> eval(...)[l_3]
  eval(...)[l_3] --< Call >--> eval[s_1]
  eval(...)[l_3] --< D >--> $v2[l_4]
  $v2[l_4] -

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
