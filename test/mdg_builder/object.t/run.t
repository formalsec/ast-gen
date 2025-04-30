  $ graphjs mdg --no-export object.js
  foo[#11] -
  bar[#12] -
  baz[#13] -
  qux[#14] -

  $ graphjs mdg --no-export array.js
  foo[#11] -
  bar[#12] -
  baz[#13] -
  qux[#14] -

  $ graphjs mdg --no-export this.js
  bar[#11] --< Param(0) >--> this[#12]
  bar[#11] --< Param(1) >--> x1[#13]
  this[#12] --< P(foo) >--> this.foo[#14]
  this[#12] --< P(bar) >--> this.bar[#16]
  this[#12] --< Arg(0) >--> this.bar(...)[#17]
  x1[#13] -
  this.foo[#14] -
  "abc"[#15] --< Arg(1) >--> this.bar(...)[#17]
  this.bar[#16] -
  this.bar(...)[#17] --< Call >--> this.bar[#16]
  this.bar(...)[#17] --< D >--> y[#18]
  y[#18] -
  obj[#19] --< V(foo) >--> obj[#21]
  obj[#19] --< P(bar) >--> obj.bar[#27]
  10[#20] -
  obj[#21] --< P(foo) >--> 10[#20]
  obj[#21] --< V(bar) >--> obj[#22]
  obj[#22] --< P(bar) >--> bar[#11]
  obj[#22] --< Arg(0) >--> obj.bar(...)[#28]
  10[#23] --< Arg(1) >--> bar(...)[#24]
  bar(...)[#24] --< Call >--> bar[#11]
  bar(...)[#24] --< D >--> $v1[#25]
  $v1[#25] -
  10[#26] --< Arg(1) >--> obj.bar(...)[#28]
  obj.bar[#27] -
  obj.bar(...)[#28] --< Call >--> bar[#11]
  obj.bar(...)[#28] --< D >--> $v2[#29]
  $v2[#29] -
