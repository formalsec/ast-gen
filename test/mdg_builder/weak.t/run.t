  $ graphjs mdg --no-svg static_property_lookup.js
  [[literal]] -
  $v1[l_1] --< P(foo) >--> obj.foo[l_3]
  $v1[l_1] --< P(bar) >--> obj.bar[l_4]
  $v1[l_1] --< P(null) >--> obj.null[l_6]
  $v1[l_1] --< P(abc) >--> obj.abc[l_7]
  $v1[l_1] --< P(10) >--> obj.10[l_8]
  $v2[l_2] --< P(foo) >--> obj.foo[l_3]
  $v2[l_2] --< P(bar) >--> obj.bar[l_4]
  $v2[l_2] --< P(null) >--> obj.null[l_6]
  $v2[l_2] --< P(abc) >--> obj.abc[l_7]
  $v2[l_2] --< P(10) >--> obj.10[l_8]
  obj.foo[l_3] -
  obj.bar[l_4] --< P(baz) >--> obj.bar.baz[l_5]
  obj.bar.baz[l_5] -
  obj.null[l_6] -
  obj.abc[l_7] -
  obj.10[l_8] -

  $ graphjs mdg --no-svg static_property_update.js
  [[literal]] -
  $v1[l_1] --< V(foo) >--> obj[l_3]
  $v1[l_1] --< P(bar) >--> obj.bar[l_6]
  $v2[l_2] --< V(foo) >--> obj[l_3]
  $v2[l_2] --< P(bar) >--> obj.bar[l_6]
  obj[l_3] --< P(foo) >--> [[literal]]
  obj[l_3] --< [[RefParent(foo)]] >--> $v1[l_1]
  obj[l_3] --< [[RefParent(foo)]] >--> $v2[l_2]
  obj[l_3] --< V(bar) >--> obj[l_5]
  dep[l_4] --< V(baz) >--> dep[l_7]
  obj[l_5] --< [[RefParent(bar)]] >--> obj[l_3]
  obj[l_5] --< P(bar) >--> dep[l_4]
  obj[l_5] --< V(null) >--> obj[l_8]
  obj.bar[l_6] -
  dep[l_7] --< P(baz) >--> [[literal]]
  dep[l_7] --< [[RefParent(baz)]] >--> dep[l_4]
  obj[l_8] --< P(null) >--> [[literal]]
  obj[l_8] --< [[RefParent(null)]] >--> obj[l_5]
  obj[l_8] --< V(abc) >--> obj[l_9]
  obj[l_9] --< P(abc) >--> [[literal]]
  obj[l_9] --< [[RefParent(abc)]] >--> obj[l_8]
  obj[l_9] --< V(10) >--> obj[l_10]
  obj[l_10] --< P(10) >--> [[literal]]
  obj[l_10] --< [[RefParent(10)]] >--> obj[l_9]

  $ graphjs mdg --no-svg static_property_access.js
  [[literal]] -
  $v1[l_1] --< V(foo) >--> obj[l_3]
  $v1[l_1] --< P(foo) >--> obj.foo[l_4]
  $v1[l_1] --< P(bar) >--> obj.bar[l_5]
  $v2[l_2] --< V(foo) >--> obj[l_3]
  $v2[l_2] --< P(foo) >--> obj.foo[l_4]
  $v2[l_2] --< P(bar) >--> obj.bar[l_5]
  obj[l_3] --< P(foo) >--> [[literal]]
  obj[l_3] --< [[RefParent(foo)]] >--> $v1[l_1]
  obj[l_3] --< [[RefParent(foo)]] >--> $v2[l_2]
  obj[l_3] --< V(foo) >--> obj[l_6]
  obj.foo[l_4] -
  obj.bar[l_5] -
  obj[l_6] --< P(foo) >--> [[literal]]
  obj[l_6] --< [[RefParent(foo)]] >--> obj[l_3]
  obj[l_6] --< V(bar) >--> obj[l_7]
  obj[l_7] --< P(bar) >--> [[literal]]
  obj[l_7] --< [[RefParent(bar)]] >--> obj[l_6]

  $ graphjs mdg --no-svg static_property_value.js
  [[literal]] -
  $v1[l_1] --< V(foo) >--> obj[l_3]
  $v1[l_1] --< P(foo) >--> obj.foo[l_8]
  $v2[l_2] --< V(foo) >--> obj[l_3]
  $v2[l_2] --< P(foo) >--> obj.foo[l_8]
  obj[l_3] --< P(foo) >--> [[literal]]
  obj[l_3] --< [[RefParent(foo)]] >--> $v1[l_1]
  obj[l_3] --< [[RefParent(foo)]] >--> $v2[l_2]
  obj[l_3] --< V(foo) >--> obj[l_6]
  $v4[l_4] -
  $v5[l_5] -
  obj[l_6] --< [[RefParent(foo)]] >--> obj[l_3]
  obj[l_6] --< P(foo) >--> $v4[l_4]
  obj[l_6] --< P(foo) >--> $v5[l_5]
  obj2[l_7] --< V(bar) >--> obj2[l_9]
  obj.foo[l_8] -
  obj2[l_9] --< P(bar) >--> $v4[l_4]
  obj2[l_9] --< P(bar) >--> $v5[l_5]
  obj2[l_9] --< [[RefParent(bar)]] >--> obj2[l_7]

  $ graphjs mdg --no-svg function_call.js
  [[literal]] --< Arg(1) >--> baz(...)[l_1]
  [[literal]] --< Arg(1) >--> baz(...)[l_3]
  [[literal]] --< Arg(2) >--> baz(...)[l_3]
  [[literal]] --< Arg(3) >--> baz(...)[l_3]
  foo[f_2] --< Param(0) >--> this[p_0]
  foo[f_2] --< Param(1) >--> x1[p_1]
  this[p_0] -
  x1[p_1] --< [[RefArg]] >--> [[literal]]
  bar[f_3] --< Param(0) >--> this[p_0]
  bar[f_3] --< Param(1) >--> y1[p_1]
  bar[f_3] --< Param(2) >--> y2[p_2]
  bar[f_3] --< Param(3) >--> y3[p_3]
  this[p_0] -
  y1[p_1] --< [[RefArg]] >--> [[literal]]
  y2[p_2] --< [[RefArg]] >--> [[literal]]
  y3[p_3] --< [[RefArg]] >--> [[literal]]
  baz(...)[l_1] --< Call >--> foo[f_2]
  baz(...)[l_1] --< Call >--> bar[f_3]
  baz(...)[l_1] --< Ret >--> $v1[l_2]
  $v1[l_2] -
  baz(...)[l_3] --< Call >--> foo[f_2]
  baz(...)[l_3] --< Call >--> bar[f_3]
  baz(...)[l_3] --< Ret >--> $v2[l_4]
  $v2[l_4] -
