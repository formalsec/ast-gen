  $ graphjs mdg --no-svg eval.js
  [[literal]] --< Arg(1) >--> eval(...)[l_3]
  eval[s_1] --< [[RefArg]] >--> [[literal]]
  eval[s_1] --< [[RefArg]] >--> x1[p_1]
  foo[f_1] --< Param(0) >--> this[p_0]
  foo[f_1] --< Param(1) >--> x1[p_1]
  this[p_0] -
  x1[p_1] --< Arg(1) >--> eval(...)[l_1]
  eval(...)[l_1] --< Call >--> eval[s_1]
  eval(...)[l_1] --< Ret >--> $v1[l_2]
  $v1[l_2] -
  eval(...)[l_3] --< Call >--> eval[s_1]
  eval(...)[l_3] --< Ret >--> $v2[l_4]
  $v2[l_4] -

  $ graphjs mdg --no-svg stdlib.js
  [[literal]] --< Arg(1) >--> require(...)[l_1]
  [[literal]] --< Arg(1) >--> dep.exec(...)[l_7]
  require[f_1] -
  require(...)[l_1] --< Call >--> require[f_1]
  require(...)[l_1] --< Ret >--> dep[l_2]
  dep[l_2] --< P(exec) >--> dep.exec[l_4]
  dep[l_2] --< Arg(0) >--> dep.exec(...)[l_5]
  dep[l_2] --< Arg(0) >--> dep.exec(...)[l_7]
  require(child_process)[l_3] --< D >--> dep[l_2]
  foo[f_2] --< Param(0) >--> this[p_0]
  foo[f_2] --< Param(1) >--> x1[p_1]
  this[p_0] -
  x1[p_1] --< Arg(1) >--> dep.exec(...)[l_5]
  dep.exec[l_4] -
  dep.exec(...)[l_5] --< Call >--> dep.exec[l_4]
  dep.exec(...)[l_5] --< Ret >--> $v1[l_6]
  $v1[l_6] -
  dep.exec(...)[l_7] --< Call >--> dep.exec[l_4]
  dep.exec(...)[l_7] --< Ret >--> $v2[l_8]
  $v2[l_8] -
