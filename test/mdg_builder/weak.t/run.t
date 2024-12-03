  $ graphjs mdg static_property_lookup.js
  [[literal]] -
  $v1[l_1] --< P(foo) >--> $v3=obj.foo[l_3]
  $v1[l_1] --< P(bar) >--> $v4=obj.bar[l_4]
  $v1[l_1] --< P(null) >--> $v6=obj.null[l_6]
  $v1[l_1] --< P(abc) >--> $v7=obj.abc[l_7]
  $v1[l_1] --< P(10) >--> $v8=obj.10[l_8]
  $v2[l_2] --< P(foo) >--> $v3=obj.foo[l_3]
  $v2[l_2] --< P(bar) >--> $v4=obj.bar[l_4]
  $v2[l_2] --< P(null) >--> $v6=obj.null[l_6]
  $v2[l_2] --< P(abc) >--> $v7=obj.abc[l_7]
  $v2[l_2] --< P(10) >--> $v8=obj.10[l_8]
  $v3=obj.foo[l_3] -
  $v4=obj.bar[l_4] --< P(baz) >--> $v5=obj.bar.baz[l_5]
  $v5=obj.bar.baz[l_5] -
  $v6=obj.null[l_6] -
  $v7=obj.abc[l_7] -
  $v8=obj.10[l_8] -

  $ graphjs mdg static_property_update.js
  [[literal]] -
  $v1[l_1] --< V(foo) >--> obj[l_3]
  $v1[l_1] --< P(bar) >--> $v3=obj.bar[l_6]
  $v2[l_2] --< V(foo) >--> obj[l_3]
  $v2[l_2] --< P(bar) >--> $v3=obj.bar[l_6]
  obj[l_3] --< P(foo) >--> [[literal]]
  obj[l_3] --< [[RefParent(foo)]] >--> $v1[l_1]
  obj[l_3] --< [[RefParent(foo)]] >--> $v2[l_2]
  obj[l_3] --< V(foo) >--> obj[l_5]
  dep[l_4] -
  obj[l_5] --< [[RefParent(foo)]] >--> obj[l_3]
  obj[l_5] --< P(foo) >--> dep[l_4]
  obj[l_5] --< V(null) >--> obj[l_8]
  $v3=obj.bar[l_6] --< V(baz) >--> $v3=obj.bar[l_7]
  $v3=obj.bar[l_7] --< P(baz) >--> [[literal]]
  $v3=obj.bar[l_7] --< [[RefParent(baz)]] >--> $v3=obj.bar[l_6]
  obj[l_8] --< P(null) >--> [[literal]]
  obj[l_8] --< [[RefParent(null)]] >--> obj[l_5]
  obj[l_8] --< V(abc) >--> obj[l_9]
  obj[l_9] --< P(abc) >--> [[literal]]
  obj[l_9] --< [[RefParent(abc)]] >--> obj[l_8]
  obj[l_9] --< V(10) >--> obj[l_10]
  obj[l_10] --< P(10) >--> [[literal]]
  obj[l_10] --< [[RefParent(10)]] >--> obj[l_9]

  $ graphjs mdg static_property_access.js
  [[literal]] -
  $v1[l_1] --< V(foo) >--> obj[l_3]
  $v1[l_1] --< P(foo) >--> $v3=obj.foo[l_4]
  $v1[l_1] --< P(bar) >--> $v4=obj.bar[l_5]
  $v2[l_2] --< V(foo) >--> obj[l_3]
  $v2[l_2] --< P(foo) >--> $v3=obj.foo[l_4]
  $v2[l_2] --< P(bar) >--> $v4=obj.bar[l_5]
  obj[l_3] --< P(foo) >--> [[literal]]
  obj[l_3] --< [[RefParent(foo)]] >--> $v1[l_1]
  obj[l_3] --< [[RefParent(foo)]] >--> $v2[l_2]
  obj[l_3] --< V(foo) >--> obj[l_6]
  $v3=obj.foo[l_4] -
  $v4=obj.bar[l_5] -
  obj[l_6] --< P(foo) >--> [[literal]]
  obj[l_6] --< [[RefParent(foo)]] >--> obj[l_3]
  obj[l_6] --< V(bar) >--> obj[l_7]
  obj[l_7] --< P(bar) >--> [[literal]]
  obj[l_7] --< [[RefParent(bar)]] >--> obj[l_6]

  $ graphjs mdg function_call.js
  [[literal]] --< Arg(1) >--> baz(...)[l_1]
  [[literal]] --< Arg(1) >--> baz(...)[l_3]
  [[literal]] --< Arg(2) >--> baz(...)[l_3]
  [[literal]] --< Arg(3) >--> baz(...)[l_3]
  foo[f_1] --< Param(1) >--> x1[p_1]
  x1[p_1] --< [[RefArg]] >--> [[literal]]
  bar[f_2] --< Param(1) >--> y1[p_1]
  bar[f_2] --< Param(2) >--> y2[p_2]
  bar[f_2] --< Param(3) >--> y3[p_3]
  y1[p_1] --< [[RefArg]] >--> [[literal]]
  y2[p_2] --< [[RefArg]] >--> [[literal]]
  y3[p_3] --< [[RefArg]] >--> [[literal]]
  baz(...)[l_1] --< Call >--> foo[f_1]
  baz(...)[l_1] --< Call >--> bar[f_2]
  baz(...)[l_1] --< Ret >--> $v1[l_2]
  $v1[l_2] -
  baz(...)[l_3] --< Call >--> foo[f_1]
  baz(...)[l_3] --< Call >--> bar[f_2]
  baz(...)[l_3] --< Ret >--> $v2[l_4]
  $v2[l_4] -
