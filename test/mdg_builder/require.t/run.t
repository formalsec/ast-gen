  $ graphjs mdg --no-svg --mode=single-file main.js
  [[literal]] --< Arg(1) >--> require(...)[l_1]
  require[f_8] -
  require(...)[l_1] --< Call >--> require[f_8]
  require(...)[l_1] --< Ret >--> dep[l_2]
  dep[l_2] --< P(foo) >--> dep.foo[l_4]
  dep[l_2] --< Arg(0) >--> dep.foo(...)[l_5]
  require(dependency.js)[l_3] --< D >--> dep[l_2]
  dep.foo[l_4] -
  dep.foo(...)[l_5] --< Call >--> dep.foo[l_4]
  dep.foo(...)[l_5] --< Ret >--> $v1[l_6]
  $v1[l_6] -

  $ graphjs mdg --no-svg --mode=multi-file main.js

  $ graphjs mdg --no-svg --mode=single-file stdlib.js
  [[literal]] --< Arg(1) >--> require(...)[l_1]
  [[literal]] --< Arg(1) >--> dep.exec(...)[l_5]
  require[f_8] -
  require(...)[l_1] --< Call >--> require[f_8]
  require(...)[l_1] --< Ret >--> dep[l_2]
  dep[l_2] --< P(exec) >--> dep.exec[l_4]
  dep[l_2] --< Arg(0) >--> dep.exec(...)[l_5]
  require(child_process)[l_3] --< D >--> dep[l_2]
  dep.exec[l_4] -
  dep.exec(...)[l_5] --< Call >--> dep.exec[l_4]
  dep.exec(...)[l_5] --< Ret >--> $v1[l_6]
  $v1[l_6] -

  $ graphjs mdg --no-svg --mode=multi-file stdlib.js
  [[literal]] --< Arg(1) >--> require(...)[l_1]
  [[literal]] --< Arg(1) >--> dep.exec(...)[l_5]
  require[f_8] -
  require(...)[l_1] --< Call >--> require[f_8]
  require(...)[l_1] --< Ret >--> dep[l_2]
  dep[l_2] --< P(exec) >--> dep.exec[l_4]
  dep[l_2] --< Arg(0) >--> dep.exec(...)[l_5]
  require(child_process)[l_3] --< D >--> dep[l_2]
  dep.exec[l_4] -
  dep.exec(...)[l_5] --< Call >--> dep.exec[l_4]
  dep.exec(...)[l_5] --< Ret >--> $v1[l_6]
  $v1[l_6] -
