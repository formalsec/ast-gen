  $ graphjs mdg --no-export object.js
  foo[#9] -
  bar[#10] -
  baz[#11] -
  qux[#12] -

  $ graphjs mdg --no-export array.js
  foo[#9] -
  bar[#10] -
  baz[#11] -
  qux[#12] -

  $ graphjs mdg --no-export this.js
  bar[#9] --< Param(0) >--> this[#10]
  bar[#9] --< Param(1) >--> x1[#11]
  this[#10] --< P(foo) >--> this.foo[#12]
  this[#10] --< P(bar) >--> this.bar[#14]
  this[#10] --< Arg(0) >--> this.bar(...)[#15]
  x1[#11] -
  this.foo[#12] -
  "abc"[#13] --< Arg(1) >--> this.bar(...)[#15]
  this.bar[#14] -
  this.bar(...)[#15] --< Call >--> this.bar[#14]
  this.bar(...)[#15] --< D >--> y[#16]
  y[#16] -
  obj[#17] --< V(foo) >--> obj[#19]
  obj[#17] --< P(bar) >--> obj.bar[#25]
  10[#18] -
  obj[#19] --< P(foo) >--> 10[#18]
  obj[#19] --< V(bar) >--> obj[#20]
  obj[#20] --< P(bar) >--> bar[#9]
  obj[#20] --< Arg(0) >--> obj.bar(...)[#26]
  10[#21] --< Arg(1) >--> bar(...)[#22]
  bar(...)[#22] --< Call >--> bar[#9]
  bar(...)[#22] --< D >--> $v1[#23]
  $v1[#23] -
  10[#24] --< Arg(1) >--> obj.bar(...)[#26]
  obj.bar[#25] -
  obj.bar(...)[#26] --< Call >--> bar[#9]
  obj.bar(...)[#26] --< D >--> $v2[#27]
  $v2[#27] -
