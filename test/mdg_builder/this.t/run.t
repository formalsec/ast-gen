  $ graphjs mdg this.js
  [[literal]] --< Arg(1) >--> this.bar(...)[l_3]
  [[literal]] --< Arg(1) >--> bar(...)[l_8]
  [[literal]] --< Arg(1) >--> obj.bar(...)[l_11]
  bar[f_1] --< Param(0) >--> this[p_0]
  bar[f_1] --< Param(1) >--> x1[p_1]
  this[p_0] --< P(foo) >--> this.foo[l_1]
  this[p_0] --< P(bar) >--> this.bar[l_2]
  this[p_0] --< Arg(0) >--> this.bar(...)[l_3]
  this[p_0] --< [[RefArg]] >--> obj[l_7]
  x1[p_1] --< [[RefArg]] >--> [[literal]]
  this.foo[l_1] -
  this.bar[l_2] -
  this.bar(...)[l_3] --< Call >--> this.bar[l_2]
  this.bar(...)[l_3] --< Ret >--> y[l_4]
  y[l_4] -
  obj[l_5] --< V(foo) >--> obj[l_6]
  obj[l_5] --< P(bar) >--> obj.bar[l_10]
  obj[l_6] --< P(foo) >--> [[literal]]
  obj[l_6] --< [[RefParent(foo)]] >--> obj[l_5]
  obj[l_6] --< V(bar) >--> obj[l_7]
  obj[l_7] --< P(bar) >--> bar[f_1]
  obj[l_7] --< [[RefParent(bar)]] >--> obj[l_6]
  obj[l_7] --< Arg(0) >--> obj.bar(...)[l_11]
  bar(...)[l_8] --< Call >--> bar[f_1]
  bar(...)[l_8] --< Ret >--> $v1[l_9]
  $v1[l_9] -
  obj.bar[l_10] -
  obj.bar(...)[l_11] --< Call >--> bar[f_1]
  obj.bar(...)[l_11] --< Ret >--> $v2[l_12]
  $v2[l_12] -
