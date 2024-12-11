  $ graphjs mdg static_lookup.js
  [[literal]] -
  obj[l_1] --< P(foo) >--> obj.foo[l_2]
  obj[l_1] --< P(bar) >--> obj.bar[l_3]
  obj[l_1] --< P(null) >--> obj.null[l_5]
  obj[l_1] --< P(abc) >--> obj.abc[l_6]
  obj[l_1] --< P(10) >--> obj.10[l_7]
  obj.foo[l_2] -
  obj.bar[l_3] --< P(baz) >--> obj.bar.baz[l_4]
  obj.bar.baz[l_4] -
  obj.null[l_5] -
  obj.abc[l_6] -
  obj.10[l_7] -

  $ graphjs mdg static_update.js
  [[literal]] -
  obj[l_1] --< V(foo) >--> obj[l_2]
  obj[l_1] --< P(bar) >--> obj.bar[l_5]
  obj[l_2] --< P(foo) >--> [[literal]]
  obj[l_2] --< [[RefParent(foo)]] >--> obj[l_1]
  obj[l_2] --< V(foo) >--> obj[l_4]
  dep[l_3] -
  obj[l_4] --< [[RefParent(foo)]] >--> obj[l_2]
  obj[l_4] --< P(foo) >--> dep[l_3]
  obj[l_4] --< V(null) >--> obj[l_6]
  obj.bar[l_5] -
  obj[l_6] --< P(null) >--> [[literal]]
  obj[l_6] --< [[RefParent(null)]] >--> obj[l_4]
  obj[l_6] --< V(abc) >--> obj[l_7]
  obj[l_7] --< P(abc) >--> [[literal]]
  obj[l_7] --< [[RefParent(abc)]] >--> obj[l_6]
  obj[l_7] --< V(10) >--> obj[l_8]
  obj[l_8] --< P(10) >--> [[literal]]
  obj[l_8] --< [[RefParent(10)]] >--> obj[l_7]

  $ graphjs mdg static_access.js
  [[literal]] -
  obj[l_1] --< V(foo) >--> obj[l_2]
  obj[l_1] --< P(foo) >--> obj.foo[l_3]
  obj[l_1] --< P(bar) >--> obj.bar[l_4]
  obj[l_2] --< P(foo) >--> [[literal]]
  obj[l_2] --< [[RefParent(foo)]] >--> obj[l_1]
  obj[l_2] --< V(foo) >--> obj[l_5]
  obj.foo[l_3] -
  obj.bar[l_4] -
  obj[l_5] --< P(foo) >--> [[literal]]
  obj[l_5] --< [[RefParent(foo)]] >--> obj[l_2]
  obj[l_5] --< V(bar) >--> obj[l_6]
  obj[l_6] --< P(bar) >--> [[literal]]
  obj[l_6] --< [[RefParent(bar)]] >--> obj[l_5]

  $ graphjs mdg static_method.js
  [[literal]] --< Arg(1) >--> obj.foo(...)[l_5]
  [[literal]] --< Arg(1) >--> obj.bar(...)[l_8]
  [[literal]] --< Arg(1) >--> obj.bar(...)[l_10]
  [[literal]] --< Arg(2) >--> obj.bar(...)[l_10]
  [[literal]] --< Arg(3) >--> obj.bar(...)[l_10]
  [[literal]] --< Arg(1) >--> obj.foo(...)[l_12]
  [[literal]] --< Arg(2) >--> obj.foo(...)[l_12]
  [[literal]] --< Arg(3) >--> obj.foo(...)[l_12]
  [[literal]] --< Arg(1) >--> obj.baz(...)[l_15]
  obj[l_1] --< V(foo) >--> obj[l_2]
  obj[l_1] --< P(foo) >--> obj.foo[l_4]
  obj[l_1] --< P(bar) >--> obj.bar[l_7]
  obj[l_1] --< P(baz) >--> obj.baz[l_14]
  $v1[f_1] --< Param(0) >--> this[p_0]
  $v1[f_1] --< Param(1) >--> x1[p_1]
  this[p_0] -
  x1[p_1] -
  obj[l_2] --< [[RefParent(foo)]] >--> obj[l_1]
  obj[l_2] --< P(foo) >--> $v1[f_1]
  obj[l_2] --< V(bar) >--> obj[l_3]
  $v2[f_2] --< Param(0) >--> this[p_0]
  $v2[f_2] --< Param(1) >--> y1[p_1]
  $v2[f_2] --< Param(2) >--> y2[p_2]
  $v2[f_2] --< Param(3) >--> y3[p_3]
  this[p_0] --< [[RefArg]] >--> obj[l_3]
  y1[p_1] --< [[RefArg]] >--> [[literal]]
  y2[p_2] --< [[RefArg]] >--> [[literal]]
  y3[p_3] --< [[RefArg]] >--> [[literal]]
  obj[l_3] --< [[RefParent(bar)]] >--> obj[l_2]
  obj[l_3] --< P(bar) >--> $v2[f_2]
  obj[l_3] --< Arg(0) >--> obj.foo(...)[l_5]
  obj[l_3] --< Arg(0) >--> obj.bar(...)[l_8]
  obj[l_3] --< Arg(0) >--> obj.bar(...)[l_10]
  obj[l_3] --< Arg(0) >--> obj.foo(...)[l_12]
  obj[l_3] --< Arg(0) >--> obj.baz(...)[l_15]
  obj.foo[l_4] -
  obj.foo(...)[l_5] --< Ret >--> $v3[l_6]
  $v3[l_6] -
  obj.bar[l_7] -
  obj.bar(...)[l_8] --< Call >--> $v2[f_2]
  obj.bar(...)[l_8] --< Ret >--> $v4[l_9]
  $v4[l_9] -
  obj.bar(...)[l_10] --< Call >--> $v2[f_2]
  obj.bar(...)[l_10] --< Ret >--> $v5[l_11]
  $v5[l_11] -
  obj.foo(...)[l_12] --< Ret >--> $v6[l_13]
  $v6[l_13] -
  obj.baz[l_14] -
  obj.baz(...)[l_15] --< Ret >--> $v7[l_16]
  $v7[l_16] -

  $ graphjs mdg dynamic_lookup.js
  [[literal]] --< D >--> $v3[l_4]
  [[literal]] --< D >--> $v6[l_5]
  obj[l_1] --< P(*) >--> obj.*[l_2]
  obj.*[l_2] --< P(*) >--> obj.*.*[l_6]
  bar[l_3] --< D >--> obj.*[l_2]
  $v3[l_4] --< D >--> obj.*[l_2]
  $v6[l_5] --< D >--> obj.*.*[l_6]
  obj.*.*[l_6] -

  $ graphjs mdg dynamic_update.js
  [[literal]] --< D >--> $v1[l_6]
  [[literal]] --< D >--> $v3[l_9]
  [[literal]] --< V(*) >--> $v2[l_10]
  obj[l_1] --< V(*) >--> obj[l_2]
  obj[l_1] --< P(*) >--> obj.*[l_8]
  obj[l_2] --< P(*) >--> [[literal]]
  obj[l_2] --< [[RefParent(*)]] >--> obj[l_1]
  obj[l_2] --< V(*) >--> obj[l_5]
  bar[l_3] --< D >--> obj[l_5]
  bar[l_3] --< D >--> obj.*[l_8]
  dep[l_4] -
  obj[l_5] --< [[RefParent(*)]] >--> obj[l_2]
  obj[l_5] --< P(*) >--> dep[l_4]
  obj[l_5] --< V(*) >--> obj[l_7]
  $v1[l_6] --< D >--> obj[l_7]
  obj[l_7] --< P(*) >--> [[literal]]
  obj[l_7] --< [[RefParent(*)]] >--> obj[l_5]
  obj.*[l_8] -
  $v3[l_9] --< D >--> $v2[l_10]
  $v2[l_10] --< P(*) >--> [[literal]]
  $v2[l_10] --< [[RefParent(*)]] >--> [[literal]]

  $ graphjs mdg dynamic_access.js
  [[literal]] -
  obj[l_1] --< V(*) >--> obj[l_2]
  obj[l_1] --< P(*) >--> obj.*[l_3]
  obj[l_2] --< P(*) >--> [[literal]]
  obj[l_2] --< [[RefParent(*)]] >--> obj[l_1]
  obj[l_2] --< V(*) >--> obj[l_4]
  obj.*[l_3] -
  obj[l_4] --< P(*) >--> [[literal]]
  obj[l_4] --< [[RefParent(*)]] >--> obj[l_2]
  obj[l_4] --< V(*) >--> obj[l_5]
  obj[l_5] --< P(*) >--> [[literal]]
  obj[l_5] --< [[RefParent(*)]] >--> obj[l_4]

  $ graphjs mdg dynamic_method.js
  [[literal]] --< Arg(1) >--> obj.*(...)[l_5]
  [[literal]] --< Arg(1) >--> obj.*(...)[l_8]
  [[literal]] --< Arg(2) >--> obj.*(...)[l_8]
  [[literal]] --< Arg(3) >--> obj.*(...)[l_8]
  [[literal]] --< D >--> $v5[l_10]
  [[literal]] --< Arg(1) >--> obj.*(...)[l_11]
  [[literal]] --< D >--> $v8[l_13]
  [[literal]] --< Arg(1) >--> $v2.*(...)[l_15]
  obj[l_1] --< V(foo) >--> obj[l_2]
  obj[l_1] --< P(*) >--> obj.*[l_4]
  $v1[f_1] --< Param(0) >--> this[p_0]
  $v1[f_1] --< Param(1) >--> x1[p_1]
  this[p_0] -
  x1[p_1] -
  obj[l_2] --< [[RefParent(foo)]] >--> obj[l_1]
  obj[l_2] --< P(foo) >--> $v1[f_1]
  obj[l_2] --< V(bar) >--> obj[l_3]
  $v2[f_2] --< Param(0) >--> this[p_0]
  $v2[f_2] --< Param(1) >--> y1[p_1]
  $v2[f_2] --< Param(2) >--> y2[p_2]
  $v2[f_2] --< Param(3) >--> y3[p_3]
  $v2[f_2] --< P(*) >--> $v2.*[l_14]
  $v2[f_2] --< Arg(0) >--> $v2.*(...)[l_15]
  this[p_0] --< [[RefArg]] >--> obj[l_3]
  y1[p_1] --< [[RefArg]] >--> [[literal]]
  y2[p_2] --< [[RefArg]] >--> [[literal]]
  y3[p_3] --< [[RefArg]] >--> [[literal]]
  obj[l_3] --< [[RefParent(bar)]] >--> obj[l_2]
  obj[l_3] --< P(bar) >--> $v2[f_2]
  obj[l_3] --< Arg(0) >--> obj.*(...)[l_5]
  obj[l_3] --< Arg(0) >--> obj.*(...)[l_8]
  obj[l_3] --< Arg(0) >--> obj.*(...)[l_11]
  obj.*[l_4] -
  obj.*(...)[l_5] --< Call >--> $v2[f_2]
  obj.*(...)[l_5] --< Ret >--> $v3[l_6]
  $v3[l_6] -
  bar[l_7] --< D >--> obj.*[l_4]
  obj.*(...)[l_8] --< Call >--> $v2[f_2]
  obj.*(...)[l_8] --< Ret >--> $v4[l_9]
  $v4[l_9] -
  $v5[l_10] --< D >--> obj.*[l_4]
  obj.*(...)[l_11] --< Call >--> $v2[f_2]
  obj.*(...)[l_11] --< Ret >--> $v6[l_12]
  $v6[l_12] -
  $v8[l_13] --< D >--> $v2.*[l_14]
  $v2.*[l_14] -
  $v2.*(...)[l_15] --< Call >--> $v2.*[l_14]
  $v2.*(...)[l_15] --< Ret >--> $v9[l_16]
  $v9[l_16] -
