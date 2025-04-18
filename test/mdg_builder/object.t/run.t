  $ graphjs mdg --no-export object.js
  foo[l_1] -
  bar[l_2] -
  baz[l_3] -
  qux[l_4] -

  $ graphjs mdg --no-export array.js
  foo[l_1] -
  bar[l_2] -
  baz[l_3] -
  qux[l_4] -

  $ graphjs mdg --no-export this.js
  bar[f_1] --< Param(0) >--> this[p_0]
  bar[f_1] --< Param(1) >--> x1[p_1]
  this[p_0] --< P(foo) >--> this.foo[l_1]
  this[p_0] --< P(bar) >--> this.bar[l_2]
  this[p_0] --< Arg(0) >--> this.bar(...)[l_3]
  x1[p_1] -
  this.foo[l_1] -
  "abc"[v_2] --< Arg(1) >--> this.bar(...)[l_3]
  this.bar[l_2] -
  this.bar(...)[l_3] --< Call >--> this.bar[l_2]
  this.bar(...)[l_3] --< D >--> y[l_4]
  y[l_4] -
  obj[l_5] --< V(foo) >--> obj[l_6]
  obj[l_5] --< P(bar) >--> obj.bar[l_10]
  10[v_3] -
  obj[l_6] --< P(foo) >--> 10[v_3]
  obj[l_6] --< V(bar) >--> obj[l_7]
  obj[l_7] --< P(bar) >--> bar[f_1]
  obj[l_7] --< Arg(0) >--> obj.bar(...)[l_11]
  10[v_4] --< Arg(1) >--> bar(...)[l_8]
  bar(...)[l_8] --< Call >--> bar[f_1]
  bar(...)[l_8] --< D >--> $v1[l_9]
  $v1[l_9] -
  10[v_5] --< Arg(1) >--> obj.bar(...)[l_11]
  obj.bar[l_10] -
  obj.bar(...)[l_11] --< Call >--> bar[f_1]
  obj.bar(...)[l_11] --< D >--> $v2[l_12]
  $v2[l_12] -
