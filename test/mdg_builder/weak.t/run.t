  $ graphjs mdg --no-export property_lookup.js
  [[literal]] -
  $v1[l_1] --< P(foo) >--> obj.foo[l_3]
  $v1[l_1] --< P(bar) >--> obj.bar[l_4]
  $v1[l_1] --< P(10) >--> obj.10[l_6]
  $v1[l_1] --< P(abc) >--> obj.abc[l_7]
  $v1[l_1] --< P(null) >--> obj.null[l_8]
  $v2[l_2] --< P(foo) >--> obj.foo[l_3]
  $v2[l_2] --< P(bar) >--> obj.bar[l_4]
  $v2[l_2] --< P(10) >--> obj.10[l_6]
  $v2[l_2] --< P(abc) >--> obj.abc[l_7]
  $v2[l_2] --< P(null) >--> obj.null[l_8]
  obj.foo[l_3] -
  obj.bar[l_4] --< P(baz) >--> obj.bar.baz[l_5]
  obj.bar.baz[l_5] -
  obj.10[l_6] -
  obj.abc[l_7] -
  obj.null[l_8] -

  $ graphjs mdg --no-export property_update.js
  [[literal]] -
  $v1[l_1] --< V(foo) >--> obj[l_3]
  $v1[l_1] --< P(bar) >--> obj.bar[l_6]
  $v2[l_2] --< V(foo) >--> obj[l_3]
  $v2[l_2] --< P(bar) >--> obj.bar[l_6]
  10[l_0] -
  obj[l_3] --< P(foo) >--> 10[l_0]
  obj[l_3] --< V(bar) >--> obj[l_5]
  $v3[l_4] --< V(baz) >--> $v3[l_7]
  obj[l_5] --< P(bar) >--> $v3[l_4]
  obj[l_5] --< V(10) >--> obj[l_8]
  obj.bar[l_6] -
  10[l_0] -
  $v3[l_7] --< P(baz) >--> 10[l_0]
  10[l_0] -
  obj[l_8] --< P(10) >--> 10[l_0]
  obj[l_8] --< V(abc) >--> obj[l_9]
  10[l_0] -
  obj[l_9] --< P(abc) >--> 10[l_0]
  obj[l_9] --< V(null) >--> obj[l_10]
  10[l_0] -
  obj[l_10] --< P(null) >--> 10[l_0]

  $ graphjs mdg --no-export property_access.js
  [[literal]] -
  $v1[l_1] --< V(foo) >--> obj[l_3]
  $v1[l_1] --< P(foo) >--> obj.foo[l_6]
  $v1[l_1] --< P(bar) >--> obj.bar[l_8]
  $v2[l_2] --< V(foo) >--> obj[l_3]
  $v2[l_2] --< P(foo) >--> obj.foo[l_6]
  $v2[l_2] --< P(bar) >--> obj.bar[l_8]
  10[l_0] -
  obj[l_3] --< P(foo) >--> 10[l_0]
  obj[l_3] --< V(bar) >--> obj[l_5]
  $v3[l_4] -
  obj[l_5] --< P(bar) >--> $v3[l_4]
  obj[l_5] --< V(baz) >--> obj[l_7]
  obj.foo[l_6] -
  obj[l_7] --< P(baz) >--> 10[l_0]
  obj[l_7] --< V(baz) >--> obj[l_9]
  obj.bar[l_8] -
  obj[l_9] --< P(baz) >--> $v3[l_4]

  $ graphjs mdg --no-export method_call.js
  [[literal]] --< Arg(1) >--> obj.foo(...)[l_6]
  [[literal]] --< Arg(1) >--> obj.bar(...)[l_9]
  [[literal]] --< Arg(2) >--> obj.bar(...)[l_9]
  [[literal]] --< Arg(3) >--> obj.bar(...)[l_9]
  [[literal]] --< Arg(1) >--> obj.baz(...)[l_12]
  $v1[l_1] --< V(foo) >--> $v1[l_2]
  $v1[l_1] --< P(foo) >--> obj.foo[l_5]
  $v1[l_1] --< P(bar) >--> obj.bar[l_8]
  $v1[l_1] --< P(baz) >--> obj.baz[l_11]
  $v2[f_1] --< Param(0) >--> this[p_0]
  $v2[f_1] --< Param(1) >--> x1[p_1]
  this[p_0] -
  x1[p_1] -
  $v1[l_2] --< P(foo) >--> $v2[f_1]
  $v1[l_2] --< Arg(0) >--> obj.foo(...)[l_6]
  $v1[l_2] --< Arg(0) >--> obj.bar(...)[l_9]
  $v1[l_2] --< Arg(0) >--> obj.baz(...)[l_12]
  $v3[l_3] --< V(bar) >--> $v3[l_4]
  $v3[l_3] --< P(foo) >--> obj.foo[l_5]
  $v3[l_3] --< P(bar) >--> obj.bar[l_8]
  $v3[l_3] --< P(baz) >--> obj.baz[l_11]
  $v4[f_2] --< Param(0) >--> this[p_0]
  $v4[f_2] --< Param(1) >--> y1[p_1]
  $v4[f_2] --< Param(2) >--> y2[p_2]
  $v4[f_2] --< Param(3) >--> y3[p_3]
  this[p_0] -
  y1[p_1] -
  y2[p_2] -
  y3[p_3] -
  $v3[l_4] --< P(bar) >--> $v4[f_2]
  $v3[l_4] --< Arg(0) >--> obj.foo(...)[l_6]
  $v3[l_4] --< Arg(0) >--> obj.bar(...)[l_9]
  $v3[l_4] --< Arg(0) >--> obj.baz(...)[l_12]
  obj.foo[l_5] -
  obj.foo(...)[l_6] --< Call >--> $v2[f_1]
  obj.foo(...)[l_6] --< Call >--> obj.foo[l_5]
  obj.foo(...)[l_6] --< D >--> $v5[l_7]
  $v5[l_7] -
  obj.bar[l_8] -
  obj.bar(...)[l_9] --< Call >--> $v4[f_2]
  obj.bar(...)[l_9] --< Call >--> obj.bar[l_8]
  obj.bar(...)[l_9] --< D >--> $v6[l_10]
  $v6[l_10] -
  obj.baz[l_11] -
  obj.baz(...)[l_12] --< Call >--> obj.baz[l_11]
  obj.baz(...)[l_12] --< D >--> $v7[l_13]
  $v7[l_13] -

  $ graphjs mdg --no-export property_value.js
  [[literal]] -
  $v1[l_1] --< V(foo) >--> obj[l_3]
  $v1[l_1] --< P(foo) >--> obj.foo[l_8]
  $v2[l_2] --< V(foo) >--> obj[l_3]
  $v2[l_2] --< P(foo) >--> obj.foo[l_8]
  10[l_0] -
  obj[l_3] --< P(foo) >--> 10[l_0]
  obj[l_3] --< V(foo) >--> obj[l_6]
  $v4[l_4] -
  $v5[l_5] -
  obj[l_6] --< P(foo) >--> $v4[l_4]
  obj[l_6] --< P(foo) >--> $v5[l_5]
  obj2[l_7] --< V(bar) >--> obj2[l_9]
  obj.foo[l_8] -
  obj2[l_9] --< P(bar) >--> $v4[l_4]
  obj2[l_9] --< P(bar) >--> $v5[l_5]

  $ graphjs mdg --no-export function_call.js
  [[literal]] --< Arg(1) >--> foo(...)[l_1]
  [[literal]] --< Arg(1) >--> foo(...)[l_3]
  [[literal]] --< Arg(2) >--> foo(...)[l_3]
  [[literal]] --< Arg(3) >--> foo(...)[l_3]
  $v1[f_1] --< Param(0) >--> this[p_0]
  $v1[f_1] --< Param(1) >--> x1[p_1]
  this[p_0] -
  x1[p_1] -
  $v2[f_2] --< Param(0) >--> this[p_0]
  $v2[f_2] --< Param(1) >--> y1[p_1]
  $v2[f_2] --< Param(2) >--> y2[p_2]
  $v2[f_2] --< Param(3) >--> y3[p_3]
  this[p_0] -
  y1[p_1] -
  y2[p_2] -
  y3[p_3] -
  foo(...)[l_1] --< Call >--> $v1[f_1]
  foo(...)[l_1] --< Call >--> $v2[f_2]
  foo(...)[l_1] --< D >--> $v3[l_2]
  $v3[l_2] -
  foo(...)[l_3] --< Call >--> $v1[f_1]
  foo(...)[l_3] --< Call >--> $v2[f_2]
  foo(...)[l_3] --< D >--> $v4[l_4]
  $v4[l_4] -
