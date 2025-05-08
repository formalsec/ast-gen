  $ graphjs mdg --no-export object.js
  foo[#10] -
  bar[#11] -
  baz[#12] -
  qux[#13] -

  $ graphjs mdg --no-export array.js
  foo[#10] -
  bar[#11] -
  baz[#12] -
  qux[#13] -

  $ graphjs mdg --no-export this.js
  bar[#10] --< Param(0) >--> this[#11]
  bar[#10] --< Param(1) >--> x1[#12]
  this[#11] --< P(foo) >--> this.foo[#13]
  this[#11] --< P(bar) >--> this.bar[#15]
  this[#11] --< Arg(0) >--> this.bar(...)[#16]
  x1[#12] -
  this.foo[#13] -
  "abc"[#14] --< Arg(1) >--> this.bar(...)[#16]
  this.bar[#15] -
  this.bar(...)[#16] --< Call >--> this.bar[#15]
  this.bar(...)[#16] --< D >--> y[#17]
  y[#17] -
  obj[#18] --< V(foo) >--> obj[#20]
  obj[#18] --< P(bar) >--> obj.bar[#26]
  10[#19] -
  obj[#20] --< P(foo) >--> 10[#19]
  obj[#20] --< V(bar) >--> obj[#21]
  obj[#21] --< P(bar) >--> bar[#10]
  obj[#21] --< Arg(0) >--> obj.bar(...)[#27]
  10[#22] --< Arg(1) >--> bar(...)[#23]
  bar(...)[#23] --< Call >--> bar[#10]
  bar(...)[#23] --< D >--> $v1[#24]
  $v1[#24] -
  10[#25] --< Arg(1) >--> obj.bar(...)[#27]
  obj.bar[#26] -
  obj.bar(...)[#27] --< Call >--> bar[#10]
  obj.bar(...)[#27] --< D >--> $v2[#28]
  $v2[#28] -
