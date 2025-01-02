  $ graphjs mdg --no-svg static_lookup.js
  [[literal]] -
  obj[l_1] --< P(foo) >--> obj.foo[l_2]
  obj[l_1] --< P(bar) >--> obj.bar[l_3]
  obj[l_1] --< P(10) >--> obj.10[l_5]
  obj[l_1] --< P(abc) >--> obj.abc[l_6]
  obj[l_1] --< P(null) >--> obj.null[l_7]
  obj.foo[l_2] -
  obj.bar[l_3] --< P(baz) >--> obj.bar.baz[l_4]
  obj.bar.baz[l_4] -
  obj.10[l_5] -
  obj.abc[l_6] -
  obj.null[l_7] -

  $ graphjs mdg --no-svg static_update.js
  [[literal]] -
  obj[l_1] --< V(foo) >--> obj[l_2]
  obj[l_1] --< P(bar) >--> obj.bar[l_5]
  obj[l_2] --< P(foo) >--> [[literal]]
  obj[l_2] --< V(bar) >--> obj[l_4]
  $v1[l_3] --< V(baz) >--> $v1[l_6]
  obj[l_4] --< P(bar) >--> $v1[l_3]
  obj[l_4] --< V(10) >--> obj[l_7]
  obj.bar[l_5] -
  $v1[l_6] --< P(baz) >--> [[literal]]
  obj[l_7] --< P(10) >--> [[literal]]
  obj[l_7] --< V(abc) >--> obj[l_8]
  obj[l_8] --< P(abc) >--> [[literal]]
  obj[l_8] --< V(null) >--> obj[l_9]
  obj[l_9] --< P(null) >--> [[literal]]

  $ graphjs mdg --no-svg static_access.js
  [[literal]] -
  obj[l_1] --< V(foo) >--> obj[l_2]
  obj[l_1] --< P(foo) >--> obj.foo[l_5]
  obj[l_1] --< P(bar) >--> obj.bar[l_7]
  obj[l_2] --< P(foo) >--> [[literal]]
  obj[l_2] --< V(bar) >--> obj[l_4]
  $v1[l_3] -
  obj[l_4] --< P(bar) >--> $v1[l_3]
  obj[l_4] --< V(baz) >--> obj[l_6]
  obj.foo[l_5] -
  obj[l_6] --< P(baz) >--> [[literal]]
  obj[l_6] --< V(baz) >--> obj[l_8]
  obj.bar[l_7] -
  obj[l_8] --< P(baz) >--> $v1[l_3]

  $ graphjs mdg --no-svg static_method.js
  [[literal]] --< Arg(1) >--> obj.foo(...)[l_5]
  [[literal]] --< Arg(1) >--> obj.bar(...)[l_8]
  [[literal]] --< Arg(2) >--> obj.bar(...)[l_8]
  [[literal]] --< Arg(3) >--> obj.bar(...)[l_8]
  [[literal]] --< Arg(1) >--> obj.baz(...)[l_11]
  obj[l_1] --< V(foo) >--> obj[l_2]
  obj[l_1] --< P(foo) >--> obj.foo[l_4]
  obj[l_1] --< P(bar) >--> obj.bar[l_7]
  obj[l_1] --< P(baz) >--> obj.baz[l_10]
  $v1[f_1] --< Param(0) >--> this[p_0]
  $v1[f_1] --< Param(1) >--> x1[p_1]
  this[p_0] -
  x1[p_1] -
  obj[l_2] --< P(foo) >--> $v1[f_1]
  obj[l_2] --< V(bar) >--> obj[l_3]
  $v2[f_2] --< Param(0) >--> this[p_0]
  $v2[f_2] --< Param(1) >--> y1[p_1]
  $v2[f_2] --< Param(2) >--> y2[p_2]
  $v2[f_2] --< Param(3) >--> y3[p_3]
  this[p_0] -
  y1[p_1] -
  y2[p_2] -
  y3[p_3] -
  obj[l_3] --< P(bar) >--> $v2[f_2]
  obj[l_3] --< Arg(0) >--> obj.foo(...)[l_5]
  obj[l_3] --< Arg(0) >--> obj.bar(...)[l_8]
  obj[l_3] --< Arg(0) >--> obj.baz(...)[l_11]
  obj.foo[l_4] -
  obj.foo(...)[l_5] --< Call >--> $v1[f_1]
  obj.foo(...)[l_5] --< Ret >--> $v3[l_6]
  $v3[l_6] -
  obj.bar[l_7] -
  obj.bar(...)[l_8] --< Call >--> $v2[f_2]
  obj.bar(...)[l_8] --< Ret >--> $v4[l_9]
  $v4[l_9] -
  obj.baz[l_10] -
  obj.baz(...)[l_11] --< Call >--> obj.baz[l_10]
  obj.baz(...)[l_11] --< Ret >--> $v5[l_12]
  $v5[l_12] -

  $ graphjs mdg --no-svg dynamic_lookup.js
  [[literal]] --< D >--> $v4[l_4]
  obj[l_1] --< P(*) >--> obj.*[l_2]
  obj.*[l_2] --< P(*) >--> obj.*.*[l_6]
  $v2[l_3] --< D >--> obj.*[l_2]
  $v4[l_4] --< D >--> obj.*[l_2]
  $v7[l_5] --< D >--> obj.*.*[l_6]
  obj.*.*[l_6] -

  $ graphjs mdg --no-svg dynamic_update.js
  [[literal]] --< D >--> $v3[l_7]
  [[literal]] --< V(*) >--> $v4[l_11]
  obj[l_1] --< V(*) >--> obj[l_2]
  obj[l_1] --< P(*) >--> obj.*[l_9]
  obj[l_2] --< P(*) >--> [[literal]]
  obj[l_2] --< V(*) >--> obj[l_4]
  $v1[l_3] --< V(*) >--> $v4[l_11]
  obj[l_4] --< P(*) >--> $v1[l_3]
  obj[l_4] --< V(*) >--> obj[l_6]
  $v2[l_5] --< D >--> obj[l_6]
  obj[l_6] --< P(*) >--> [[literal]]
  obj[l_6] --< V(*) >--> obj[l_8]
  $v3[l_7] --< D >--> obj[l_8]
  obj[l_8] --< P(*) >--> [[literal]]
  obj.*[l_9] --< V(*) >--> $v4[l_11]
  $v5[l_10] --< D >--> $v4[l_11]
  $v4[l_11] --< P(*) >--> [[literal]]

  $ graphjs mdg --no-svg dynamic_access.js
  [[literal]] -
  obj[l_1] --< V(*) >--> obj[l_2]
  obj[l_1] --< P(*) >--> obj.*[l_5]
  obj[l_2] --< P(*) >--> [[literal]]
  obj[l_2] --< V(*) >--> obj[l_4]
  $v1[l_3] -
  obj[l_4] --< P(*) >--> $v1[l_3]
  obj[l_4] --< V(*) >--> obj[l_6]
  obj.*[l_5] -
  obj[l_6] --< P(*) >--> [[literal]]
  obj[l_6] --< P(*) >--> $v1[l_3]
  obj[l_6] --< P(*) >--> obj.*[l_5]
  obj[l_6] --< V(*) >--> obj[l_7]
  obj[l_7] --< P(*) >--> [[literal]]
  obj[l_7] --< P(*) >--> $v1[l_3]
  obj[l_7] --< P(*) >--> obj.*[l_5]

  $ graphjs mdg --no-svg dynamic_method.js
  [[literal]] --< Arg(1) >--> obj.*(...)[l_5]
  [[literal]] --< Arg(1) >--> obj.*(...)[l_7]
  [[literal]] --< Arg(2) >--> obj.*(...)[l_7]
  [[literal]] --< Arg(3) >--> obj.*(...)[l_7]
  [[literal]] --< Arg(1) >--> obj.*(...)[l_10]
  [[literal]] --< D >--> $v7[l_12]
  [[literal]] --< Arg(1) >--> obj.*(...)[l_13]
  [[literal]] --< Arg(1) >--> $v9.*(...)[l_17]
  obj[l_1] --< V(foo) >--> obj[l_2]
  obj[l_1] --< P(*) >--> obj.*[l_4]
  $v1[f_1] --< Param(0) >--> this[p_0]
  $v1[f_1] --< Param(1) >--> x1[p_1]
  $v1[f_1] --< P(*) >--> $v9.*[l_16]
  $v1[f_1] --< Arg(0) >--> $v9.*(...)[l_17]
  this[p_0] -
  x1[p_1] -
  obj[l_2] --< P(foo) >--> $v1[f_1]
  obj[l_2] --< V(bar) >--> obj[l_3]
  $v2[f_2] --< Param(0) >--> this[p_0]
  $v2[f_2] --< Param(1) >--> y1[p_1]
  $v2[f_2] --< Param(2) >--> y2[p_2]
  $v2[f_2] --< Param(3) >--> y3[p_3]
  $v2[f_2] --< P(*) >--> $v9.*[l_16]
  $v2[f_2] --< Arg(0) >--> $v9.*(...)[l_17]
  this[p_0] -
  y1[p_1] -
  y2[p_2] -
  y3[p_3] -
  obj[l_3] --< P(bar) >--> $v2[f_2]
  obj[l_3] --< Arg(0) >--> obj.*(...)[l_5]
  obj[l_3] --< Arg(0) >--> obj.*(...)[l_7]
  obj[l_3] --< Arg(0) >--> obj.*(...)[l_10]
  obj[l_3] --< Arg(0) >--> obj.*(...)[l_13]
  obj.*[l_4] --< P(*) >--> $v9.*[l_16]
  obj.*[l_4] --< Arg(0) >--> $v9.*(...)[l_17]
  obj.*(...)[l_5] --< Call >--> $v1[f_1]
  obj.*(...)[l_5] --< Call >--> $v2[f_2]
  obj.*(...)[l_5] --< Call >--> obj.*[l_4]
  obj.*(...)[l_5] --< Ret >--> $v3[l_6]
  $v3[l_6] -
  obj.*(...)[l_7] --< Call >--> $v1[f_1]
  obj.*(...)[l_7] --< Call >--> $v2[f_2]
  obj.*(...)[l_7] --< Call >--> obj.*[l_4]
  obj.*(...)[l_7] --< Ret >--> $v4[l_8]
  $v4[l_8] -
  $v5[l_9] --< D >--> obj.*[l_4]
  obj.*(...)[l_10] --< Call >--> $v1[f_1]
  obj.*(...)[l_10] --< Call >--> $v2[f_2]
  obj.*(...)[l_10] --< Call >--> obj.*[l_4]
  obj.*(...)[l_10] --< Ret >--> $v6[l_11]
  $v6[l_11] -
  $v7[l_12] --< D >--> obj.*[l_4]
  obj.*(...)[l_13] --< Call >--> $v1[f_1]
  obj.*(...)[l_13] --< Call >--> $v2[f_2]
  obj.*(...)[l_13] --< Call >--> obj.*[l_4]
  obj.*(...)[l_13] --< Ret >--> $v8[l_14]
  $v8[l_14] -
  $v10[l_15] --< D >--> $v9.*[l_16]
  $v9.*[l_16] -
  $v9.*(...)[l_17] --< Call >--> $v9.*[l_16]
  $v9.*(...)[l_17] --< Ret >--> $v11[l_18]
  $v11[l_18] -
