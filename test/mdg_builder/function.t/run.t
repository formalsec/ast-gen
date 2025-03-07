  $ graphjs mdg --no-export header.js
  [[literal]] -
  foo[f_1] --< Param(0) >--> this[p_0]
  this[p_0] -
  bar[f_2] --< Param(0) >--> this[p_0]
  bar[f_2] --< Param(1) >--> y1[p_1]
  this[p_0] -
  y1[p_1] -
  baz[f_3] --< Param(0) >--> this[p_0]
  baz[f_3] --< Param(1) >--> z1[p_1]
  baz[f_3] --< Param(2) >--> z2[p_2]
  baz[f_3] --< Param(3) >--> z3[p_3]
  this[p_0] -
  z1[p_1] -
  z2[p_2] -
  z3[p_3] -
  baz[f_4] --< Param(0) >--> this[p_0]
  baz[f_4] --< Param(1) >--> w1[p_1]
  this[p_0] -
  w1[p_1] -

  $ graphjs mdg --no-export body.js
  [[literal]] -
  foo[f_1] --< Param(0) >--> this[p_0]
  foo[f_1] --< Param(1) >--> x1[p_1]
  this[p_0] -
  x1[p_1] -
  $v1[l_1] --< V(p1) >--> $v1[l_2]
  $v1[l_2] --< P(p1) >--> x1[p_1]
  bar[f_2] --< Param(0) >--> this[p_0]
  bar[f_2] --< Param(1) >--> y1[p_1]
  bar[f_2] --< Param(2) >--> y2[p_2]
  bar[f_2] --< Param(3) >--> y3[p_3]
  this[p_0] -
  y1[p_1] -
  y2[p_2] -
  y3[p_3] -
  $v2[l_3] --< V(p1) >--> $v2[l_4]
  $v2[l_4] --< P(p1) >--> y1[p_1]
  $v2[l_4] --< V(p2) >--> $v2[l_5]
  $v2[l_5] --< P(p2) >--> y2[p_2]
  $v2[l_5] --< V(p3) >--> $v2[l_6]
  $v2[l_6] --< P(p3) >--> y3[p_3]
  baz[f_3] --< Param(0) >--> this[p_0]
  baz[f_3] --< Param(1) >--> z1[p_1]
  this[p_0] -
  z1[p_1] --< P(p1) >--> z1.p1[l_8]
  $v3[l_7] --< V(p) >--> $v3[l_9]
  z1.p1[l_8] -
  $v3[l_9] --< P(p) >--> z1.p1[l_8]
  qux[f_4] --< Param(0) >--> this[p_0]
  qux[f_4] --< Param(1) >--> w1[p_1]
  this[p_0] -
  w1[p_1] --< P(p1) >--> w1.p1[l_11]
  $v5[l_10] --< V(p) >--> $v5[l_12]
  $v5[l_10] --< P(p) >--> $v5.p[l_13]
  w1.p1[l_11] -
  $v5[l_12] --< P(p) >--> w1.p1[l_11]
  $v5.p[l_13] -
  $v8[l_14] --< V(q) >--> $v8[l_15]
  $v8[l_15] --< P(q) >--> w1.p1[l_11]

  $ graphjs mdg --no-export return.js
  [[literal]] -
  foo[f_1] --< Param(0) >--> this[p_0]
  foo[f_1] --< Param(1) >--> x1[p_1]
  this[p_0] -
  x1[p_1] -
  bar[f_2] --< Retn >--> [[literal]]
  bar[f_2] --< Param(0) >--> this[p_0]
  bar[f_2] --< Param(1) >--> y1[p_1]
  this[p_0] -
  y1[p_1] -
  baz[f_3] --< Param(0) >--> this[p_0]
  baz[f_3] --< Param(1) >--> z1[p_1]
  baz[f_3] --< Retn >--> $v1[l_1]
  this[p_0] -
  z1[p_1] -
  $v1[l_1] -
  qux[f_4] --< Param(0) >--> this[p_0]
  qux[f_4] --< Param(1) >--> w1[p_1]
  qux[f_4] --< Retn >--> w1[p_1]
  this[p_0] -
  w1[p_1] -

  $ graphjs mdg --no-export scope.js
  [[literal]] -
  foo[f_1] --< Param(0) >--> this[p_0]
  foo[f_1] --< Param(1) >--> x[p_1]
  this[p_0] -
  x[p_1] -
  bar[f_2] --< Param(0) >--> this[p_0]
  bar[f_2] --< Param(1) >--> y[p_1]
  this[p_0] -
  y[p_1] -
  $v1[l_1] --< V(p1) >--> $v1[l_2]
  $v1[l_2] --< P(p1) >--> x[p_1]
  $v1[l_2] --< V(p2) >--> $v1[l_3]
  $v1[l_3] --< P(p2) >--> y[p_1]

  $ graphjs mdg --no-export call.js
  [[literal]] --< Arg(1) >--> foo(...)[l_1]
  [[literal]] --< Arg(1) >--> bar(...)[l_3]
  [[literal]] --< Arg(1) >--> foo(...)[l_5]
  [[literal]] --< Arg(2) >--> foo(...)[l_5]
  [[literal]] --< Arg(3) >--> foo(...)[l_5]
  [[literal]] --< Arg(1) >--> bar(...)[l_7]
  [[literal]] --< Arg(2) >--> bar(...)[l_7]
  [[literal]] --< Arg(3) >--> bar(...)[l_7]
  [[literal]] --< Arg(1) >--> baz(...)[l_9]
  foo[f_1] --< Param(0) >--> this[p_0]
  foo[f_1] --< Param(1) >--> x1[p_1]
  this[p_0] -
  x1[p_1] -
  bar[f_2] --< Param(0) >--> this[p_0]
  bar[f_2] --< Param(1) >--> y1[p_1]
  bar[f_2] --< Param(2) >--> y2[p_2]
  bar[f_2] --< Param(3) >--> y3[p_3]
  this[p_0] -
  y1[p_1] -
  y2[p_2] -
  y3[p_3] -
  foo(...)[l_1] --< Call >--> foo[f_1]
  foo(...)[l_1] --< D >--> $v1[l_2]
  $v1[l_2] -
  bar(...)[l_3] --< Call >--> bar[f_2]
  bar(...)[l_3] --< D >--> $v2[l_4]
  $v2[l_4] -
  foo(...)[l_5] --< Call >--> foo[f_1]
  foo(...)[l_5] --< D >--> $v3[l_6]
  $v3[l_6] -
  bar(...)[l_7] --< Call >--> bar[f_2]
  bar(...)[l_7] --< D >--> $v4[l_8]
  $v4[l_8] -
  baz(...)[l_9] --< D >--> $v5[l_10]
  $v5[l_10] -

  $ graphjs mdg --no-export new.js
  [[literal]] --< Arg(1) >--> foo(...)[l_1]
  [[literal]] --< Arg(1) >--> bar(...)[l_3]
  [[literal]] --< Arg(1) >--> foo(...)[l_5]
  [[literal]] --< Arg(2) >--> foo(...)[l_5]
  [[literal]] --< Arg(3) >--> foo(...)[l_5]
  [[literal]] --< Arg(1) >--> bar(...)[l_7]
  [[literal]] --< Arg(2) >--> bar(...)[l_7]
  [[literal]] --< Arg(3) >--> bar(...)[l_7]
  [[literal]] --< Arg(1) >--> baz(...)[l_9]
  foo[f_1] --< Param(0) >--> this[p_0]
  foo[f_1] --< Param(1) >--> x1[p_1]
  this[p_0] -
  x1[p_1] -
  bar[f_2] --< Param(0) >--> this[p_0]
  bar[f_2] --< Param(1) >--> y1[p_1]
  bar[f_2] --< Param(2) >--> y2[p_2]
  bar[f_2] --< Param(3) >--> y3[p_3]
  this[p_0] -
  y1[p_1] -
  y2[p_2] -
  y3[p_3] -
  foo(...)[l_1] --< Call >--> foo[f_1]
  foo(...)[l_1] --< D >--> $v1[l_2]
  $v1[l_2] -
  bar(...)[l_3] --< Call >--> bar[f_2]
  bar(...)[l_3] --< D >--> $v2[l_4]
  $v2[l_4] -
  foo(...)[l_5] --< Call >--> foo[f_1]
  foo(...)[l_5] --< D >--> $v3[l_6]
  $v3[l_6] -
  bar(...)[l_7] --< Call >--> bar[f_2]
  bar(...)[l_7] --< D >--> $v4[l_8]
  $v4[l_8] -
  baz(...)[l_9] --< D >--> $v5[l_10]
  $v5[l_10] -

  $ graphjs mdg --no-export hoisted.js
  [[literal]] --< Arg(1) >--> foo(...)[l_1]
  [[literal]] --< Arg(1) >--> bar(...)[l_3]
  [[literal]] --< Arg(1) >--> foo(...)[l_17]
  [[literal]] --< Arg(1) >--> bar(...)[l_19]
  foo[f_1] --< Param(0) >--> this[p_0]
  foo[f_1] --< Param(1) >--> x[p_1]
  this[p_0] -
  x[p_1] --< Arg(1) >--> foo(...)[l_5]
  x[p_1] --< Arg(1) >--> bar(...)[l_7]
  bar[f_2] --< Param(0) >--> this[p_0]
  bar[f_2] --< Param(1) >--> w[p_1]
  this[p_0] -
  w[p_1] --< Arg(1) >--> bar(...)[l_13]
  w[p_1] --< Arg(1) >--> foo(...)[l_15]
  foo(...)[l_1] --< Call >--> foo[f_1]
  foo(...)[l_1] --< D >--> $v1[l_2]
  $v1[l_2] -
  bar(...)[l_3] --< Call >--> bar[f_2]
  bar(...)[l_3] --< D >--> $v2[l_4]
  $v2[l_4] -
  foo(...)[l_5] --< Call >--> foo[f_1]
  foo(...)[l_5] --< D >--> $v3[l_6]
  $v3[l_6] -
  bar(...)[l_7] --< Call >--> bar[f_2]
  bar(...)[l_7] --< D >--> $v4[l_8]
  $v4[l_8] -
  foo[f_3] --< Param(0) >--> this[p_0]
  foo[f_3] --< Param(1) >--> y[p_1]
  this[p_0] -
  y[p_1] --< Arg(1) >--> foo(...)[l_9]
  foo(...)[l_9] --< Call >--> foo[f_3]
  foo(...)[l_9] --< D >--> $v5[l_10]
  $v5[l_10] -
  bar[f_4] --< Param(0) >--> this[p_0]
  bar[f_4] --< Param(1) >--> z[p_1]
  this[p_0] -
  z[p_1] --< Arg(1) >--> bar(...)[l_11]
  bar(...)[l_11] --< Call >--> bar[f_4]
  bar(...)[l_11] --< D >--> $v6[l_12]
  $v6[l_12] -
  bar(...)[l_13] --< Call >--> bar[f_4]
  bar(...)[l_13] --< D >--> $v7[l_14]
  $v7[l_14] -
  foo(...)[l_15] --< Call >--> foo[f_3]
  foo(...)[l_15] --< D >--> $v8[l_16]
  $v8[l_16] -
  foo(...)[l_17] --< Call >--> foo[f_3]
  foo(...)[l_17] --< D >--> $v9[l_18]
  $v9[l_18] -
  bar(...)[l_19] --< Call >--> bar[f_4]
  bar(...)[l_19] --< D >--> $v10[l_20]
  $v10[l_20] -
