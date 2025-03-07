  $ graphjs mdg --no-export static_lookup.js
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

  $ graphjs mdg --no-export dynamic_lookup.js
  [[literal]] --< D >--> $v6[l_5]
  obj[l_1] --< P(*) >--> obj.*[l_2]
  obj.*[l_2] --< P(*) >--> obj.*.*[l_3]
  obj.*.*[l_3] -
  $v4[l_4] --< D >--> obj.*[l_2]
  $v6[l_5] --< D >--> obj.*[l_2]
  $v9[l_6] --< D >--> obj.*.*[l_3]

  $ graphjs mdg --no-export static_update.js
  [[literal]] --< D >--> 10[l_0]
  [[literal]] --< D >--> 10[l_0]
  [[literal]] --< D >--> 10[l_0]
  [[literal]] --< D >--> 10[l_0]
  [[literal]] --< D >--> 10[l_0]
  [[literal]] --< D >--> 10[l_0]
  obj[l_1] --< V(foo) >--> obj[l_2]
  obj[l_1] --< P(bar) >--> obj.bar[l_5]
  10[l_0] -
  obj[l_2] --< P(foo) >--> 10[l_0]
  obj[l_2] --< V(bar) >--> obj[l_4]
  $v1[l_3] --< V(baz) >--> $v1[l_6]
  obj[l_4] --< P(bar) >--> $v1[l_3]
  obj[l_4] --< V(10) >--> obj[l_7]
  obj.bar[l_5] -
  10[l_0] -
  $v1[l_6] --< P(baz) >--> 10[l_0]
  10[l_0] -
  obj[l_7] --< P(10) >--> 10[l_0]
  obj[l_7] --< V(abc) >--> obj[l_8]
  10[l_0] -
  obj[l_8] --< P(abc) >--> 10[l_0]
  obj[l_8] --< V(null) >--> obj[l_9]
  10[l_0] -
  obj[l_9] --< P(null) >--> 10[l_0]
  10[l_0] -

  $ graphjs mdg --no-export dynamic_update.js
  [[literal]] --< D >--> 10[l_0]
  [[literal]] --< D >--> 10[l_0]
  [[literal]] --< D >--> 10[l_0]
  [[literal]] --< D >--> $v4[l_9]
  [[literal]] --< D >--> true[l_0]
  [[literal]] --< D >--> 10[l_0]
  [[literal]] --< D >--> 10[l_0]
  obj[l_1] --< V(*) >--> obj[l_2]
  obj[l_1] --< P(*) >--> obj.*[l_5]
  10[l_0] --< V(*) >--> $v2[l_6]
  10[l_0] --< V(*) >--> $v5[l_12]
  obj[l_2] --< P(*) >--> 10[l_0]
  obj[l_2] --< V(*) >--> obj[l_4]
  $v1[l_3] --< V(*) >--> $v2[l_6]
  $v1[l_3] --< V(*) >--> $v5[l_12]
  obj[l_4] --< P(*) >--> $v1[l_3]
  obj[l_4] --< V(*) >--> obj[l_8]
  obj.*[l_5] --< V(*) >--> $v2[l_6]
  obj.*[l_5] --< V(*) >--> $v5[l_12]
  10[l_0] -
  $v2[l_6] --< P(*) >--> 10[l_0]
  $v3[l_7] --< D >--> obj[l_8]
  10[l_0] --< V(*) >--> $v5[l_12]
  obj[l_8] --< P(*) >--> 10[l_0]
  obj[l_8] --< V(*) >--> obj[l_10]
  $v4[l_9] --< D >--> obj[l_10]
  true[l_0] --< V(*) >--> $v5[l_12]
  obj[l_10] --< P(*) >--> true[l_0]
  $v6[l_11] --< D >--> $v5[l_12]
  10[l_0] -
  $v5[l_12] --< P(*) >--> 10[l_0]
  10[l_0] -

  $ graphjs mdg --no-export static_access.js
  [[literal]] --< D >--> 10[l_0]
  [[literal]] --< D >--> 10[l_0]
  obj[l_1] --< V(foo) >--> obj[l_2]
  obj[l_1] --< P(baz) >--> obj.baz[l_5]
  obj[l_1] --< P(foo) >--> obj.foo[l_7]
  obj[l_1] --< P(bar) >--> obj.bar[l_9]
  10[l_0] -
  obj[l_2] --< P(foo) >--> 10[l_0]
  obj[l_2] --< V(bar) >--> obj[l_4]
  $v1[l_3] -
  obj[l_4] --< P(bar) >--> $v1[l_3]
  obj[l_4] --< V(qux) >--> obj[l_8]
  obj.baz[l_5] --< V(p) >--> obj.baz[l_6]
  10[l_0] -
  obj.baz[l_6] --< P(p) >--> 10[l_0]
  obj.foo[l_7] -
  obj[l_8] --< P(qux) >--> 10[l_0]
  obj[l_8] --< V(qux) >--> obj[l_10]
  obj.bar[l_9] -
  obj[l_10] --< P(qux) >--> $v1[l_3]

  $ graphjs mdg --no-export dynamic_access.js
  [[literal]] --< D >--> 10[l_0]
  [[literal]] --< D >--> 10[l_0]
  obj[l_1] --< V(*) >--> obj[l_2]
  obj[l_1] --< P(*) >--> obj.*[l_5]
  10[l_0] --< V(*) >--> $v2[l_6]
  obj[l_2] --< P(*) >--> 10[l_0]
  obj[l_2] --< V(*) >--> obj[l_4]
  $v1[l_3] --< V(*) >--> $v2[l_6]
  obj[l_4] --< P(*) >--> $v1[l_3]
  obj[l_4] --< V(*) >--> obj[l_7]
  obj.*[l_5] --< V(*) >--> $v2[l_6]
  10[l_0] -
  $v2[l_6] --< P(*) >--> 10[l_0]
  obj[l_7] --< P(*) >--> 10[l_0]
  obj[l_7] --< P(*) >--> $v1[l_3]
  obj[l_7] --< P(*) >--> obj.*[l_5]
  obj[l_7] --< V(*) >--> obj[l_8]
  obj[l_8] --< P(*) >--> 10[l_0]
  obj[l_8] --< P(*) >--> $v1[l_3]
  obj[l_8] --< P(*) >--> obj.*[l_5]

  $ graphjs mdg --no-export static_method.js
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
  obj.foo(...)[l_5] --< D >--> $v3[l_6]
  $v3[l_6] -
  obj.bar[l_7] -
  obj.bar(...)[l_8] --< Call >--> $v2[f_2]
  obj.bar(...)[l_8] --< D >--> $v4[l_9]
  $v4[l_9] -
  obj.baz[l_10] -
  obj.baz(...)[l_11] --< Call >--> obj.baz[l_10]
  obj.baz(...)[l_11] --< D >--> $v5[l_12]
  $v5[l_12] -

  $ graphjs mdg --no-export dynamic_method.js
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
  obj.*(...)[l_5] --< D >--> $v3[l_6]
  $v3[l_6] -
  obj.*(...)[l_7] --< Call >--> $v1[f_1]
  obj.*(...)[l_7] --< Call >--> $v2[f_2]
  obj.*(...)[l_7] --< Call >--> obj.*[l_4]
  obj.*(...)[l_7] --< D >--> $v4[l_8]
  $v4[l_8] -
  $v5[l_9] --< D >--> obj.*[l_4]
  obj.*(...)[l_10] --< Call >--> $v1[f_1]
  obj.*(...)[l_10] --< Call >--> $v2[f_2]
  obj.*(...)[l_10] --< Call >--> obj.*[l_4]
  obj.*(...)[l_10] --< D >--> $v6[l_11]
  $v6[l_11] -
  $v7[l_12] --< D >--> obj.*[l_4]
  obj.*(...)[l_13] --< Call >--> $v1[f_1]
  obj.*(...)[l_13] --< Call >--> $v2[f_2]
  obj.*(...)[l_13] --< Call >--> obj.*[l_4]
  obj.*(...)[l_13] --< D >--> $v8[l_14]
  $v8[l_14] -
  $v10[l_15] --< D >--> $v9.*[l_16]
  $v9.*[l_16] -
  $v9.*(...)[l_17] --< Call >--> $v9.*[l_16]
  $v9.*(...)[l_17] --< D >--> $v11[l_18]
  $v11[l_18] -
