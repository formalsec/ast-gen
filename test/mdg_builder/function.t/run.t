  $ graphjs mdg header.js
  [[literal]] -
  foo[f_1] --< Param(1) >--> x1[p_1]
  x1[p_1] -
  bar[f_2] --< Param(1) >--> w1[p_1]
  bar[f_2] --< Param(2) >--> w2[p_2]
  bar[f_2] --< Param(3) >--> w3[p_3]
  w1[p_1] -
  w2[p_2] -
  w3[p_3] -
  bar[f_3] --< Param(1) >--> y1[p_1]
  y1[p_1] -
  foo[f_4] --< Param(1) >--> z1[p_1]
  foo[f_4] --< Param(2) >--> z2[p_2]
  foo[f_4] --< Param(3) >--> z3[p_3]
  z1[p_1] -
  z2[p_2] -
  z3[p_3] -

  $ graphjs mdg body.js
  [[literal]] -
  foo[f_1] --< Param(1) >--> x1[p_1]
  x1[p_1] -
  $v1[l_1] --< V(p1) >--> $v1[l_2]
  $v1[l_2] --< P(p1) >--> x1[p_1]
  $v1[l_2] --< [[RefParent(p1)]] >--> $v1[l_1]
  bar[f_2] --< Param(1) >--> y1[p_1]
  bar[f_2] --< Param(2) >--> y2[p_2]
  bar[f_2] --< Param(3) >--> y3[p_3]
  y1[p_1] -
  y2[p_2] -
  y3[p_3] -
  $v2[l_3] --< V(p1) >--> $v2[l_4]
  $v2[l_4] --< P(p1) >--> y1[p_1]
  $v2[l_4] --< [[RefParent(p1)]] >--> $v2[l_3]
  $v2[l_4] --< V(p2) >--> $v2[l_5]
  $v2[l_5] --< P(p2) >--> y2[p_2]
  $v2[l_5] --< [[RefParent(p2)]] >--> $v2[l_4]
  $v2[l_5] --< V(p3) >--> $v2[l_6]
  $v2[l_6] --< P(p3) >--> y3[p_3]
  $v2[l_6] --< [[RefParent(p3)]] >--> $v2[l_5]
  baz[f_3] --< Param(1) >--> z1[p_1]
  z1[p_1] --< P(p1) >--> $v3=z1.p1[l_7]
  $v3=z1.p1[l_7] -
  $v4[l_8] --< V(p) >--> $v4[l_9]
  $v4[l_9] --< P(p) >--> $v3=z1.p1[l_7]
  $v4[l_9] --< [[RefParent(p)]] >--> $v4[l_8]
  qux[f_4] --< Param(1) >--> w1[p_1]
  w1[p_1] -
  $v5[l_10] --< V(p1) >--> $v5[l_11]
  $v5[l_10] --< P(p1) >--> $v6=$v5.p1[l_12]
  $v5[l_11] --< P(p1) >--> w1[p_1]
  $v5[l_11] --< [[RefParent(p1)]] >--> $v5[l_10]
  $v6=$v5.p1[l_12] -
  $v7[l_13] --< V(p) >--> $v7[l_14]
  $v7[l_14] --< P(p) >--> w1[p_1]
  $v7[l_14] --< P(p) >--> $v6=$v5.p1[l_12]
  $v7[l_14] --< [[RefParent(p)]] >--> $v7[l_13]

  $ graphjs mdg return.js
  [[literal]] -
  foo[f_1] --< Param(1) >--> x1[p_1]
  x1[p_1] -
  bar[f_2] --< [[RefRet]] >--> [[literal]]
  bar[f_2] --< Param(1) >--> y1[p_1]
  y1[p_1] -
  baz[f_3] --< Param(1) >--> z1[p_1]
  baz[f_3] --< [[RefRet]] >--> z1[p_1]
  z1[p_1] -
  qux[f_4] --< Param(1) >--> w1[p_1]
  qux[f_4] --< [[RefRet]] >--> w1[p_1]
  w1[p_1] -

  $ graphjs mdg scope.js
  [[literal]] -
  foo[f_1] --< Param(1) >--> x[p_1]
  x[p_1] -

  $ graphjs mdg call.js
  [[literal]] --< Arg(1) >--> foo(...)[l_1]
  [[literal]] --< Arg(1) >--> bar(...)[l_3]
  [[literal]] --< Arg(1) >--> bar(...)[l_5]
  [[literal]] --< Arg(2) >--> bar(...)[l_5]
  [[literal]] --< Arg(3) >--> bar(...)[l_5]
  [[literal]] --< Arg(1) >--> foo(...)[l_7]
  [[literal]] --< Arg(2) >--> foo(...)[l_7]
  [[literal]] --< Arg(3) >--> foo(...)[l_7]
  [[literal]] --< Arg(1) >--> baz(...)[l_9]
  foo[f_1] --< Param(1) >--> x1[p_1]
  x1[p_1] --< [[RefArg]] >--> [[literal]]
  bar[f_2] --< Param(1) >--> y1[p_1]
  bar[f_2] --< Param(2) >--> y2[p_2]
  bar[f_2] --< Param(3) >--> y3[p_3]
  y1[p_1] --< [[RefArg]] >--> [[literal]]
  y2[p_2] --< [[RefArg]] >--> [[literal]]
  y3[p_3] --< [[RefArg]] >--> [[literal]]
  foo(...)[l_1] --< Call >--> foo[f_1]
  foo(...)[l_1] --< Ret >--> $v1[l_2]
  $v1[l_2] -
  bar(...)[l_3] --< Call >--> bar[f_2]
  bar(...)[l_3] --< Ret >--> $v2[l_4]
  $v2[l_4] -
  bar(...)[l_5] --< Call >--> bar[f_2]
  bar(...)[l_5] --< Ret >--> $v3[l_6]
  $v3[l_6] -
  foo(...)[l_7] --< Call >--> foo[f_1]
  foo(...)[l_7] --< Ret >--> $v4[l_8]
  $v4[l_8] -
  baz(...)[l_9] --< Ret >--> $v5[l_10]
  $v5[l_10] -

  $ graphjs mdg sink.js
  [[literal]] --< Arg(1) >--> eval(...)[l_1]
  eval[s_1] --< [[RefArg]] >--> x1[p_1]
  foo[f_1] --< Param(1) >--> x1[p_1]
  x1[p_1] --< Arg(1) >--> eval(...)[l_3]
  eval(...)[l_1] --< Call >--> eval[s_1]
  eval(...)[l_1] --< Ret >--> $v1[l_2]
  $v1[l_2] -
  eval(...)[l_3] --< Call >--> eval[s_1]
  eval(...)[l_3] --< Ret >--> $v2[l_4]
  $v2[l_4] -
