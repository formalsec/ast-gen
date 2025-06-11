Graph.js MDG Builder: simple object
  $ graphjs mdg --no-export object.js
  [[function]] defineProperty[#5] -
  foo[#17] -
  bar[#18] -
  baz[#19] -
  qux[#20] -

Graph.js MDG Builder: simple array
  $ graphjs mdg --no-export array.js
  [[function]] defineProperty[#5] -
  foo[#17] -
  bar[#18] -
  baz[#19] -
  qux[#20] -

Graph.js MDG Builder: this access
  $ graphjs mdg --no-export this.js
  [[function]] defineProperty[#5] -
  [[function]] bar[#17] --< Param(0) >--> this[#18]
  [[function]] bar[#17] --< Param(1) >--> x1[#19]
  this[#18] --< P(foo) >--> this.foo[#20]
  this[#18] --< P(bar) >--> this.bar[#22]
  this[#18] --< Arg(0) >--> this.bar(...)[#23]
  x1[#19] -
  this.foo[#20] -
  "abc"[#21] --< Arg(1) >--> this.bar(...)[#23]
  this.bar[#22] -
  this.bar(...)[#23] --< Call >--> this.bar[#22]
  this.bar(...)[#23] --< D >--> y[#24]
  y[#24] -
  obj[#25] --< V(foo) >--> obj[#27]
  obj[#25] --< P(bar) >--> obj.bar[#33]
  10[#26] -
  obj[#27] --< P(foo) >--> 10[#26]
  obj[#27] --< V(bar) >--> obj[#28]
  obj[#28] --< P(bar) >--> [[function]] bar[#17]
  obj[#28] --< Arg(0) >--> obj.bar(...)[#34]
  10[#29] --< Arg(1) >--> bar(...)[#30]
  bar(...)[#30] --< Call >--> [[function]] bar[#17]
  bar(...)[#30] --< D >--> $v1[#31]
  $v1[#31] -
  10[#32] --< Arg(1) >--> obj.bar(...)[#34]
  obj.bar[#33] -
  obj.bar(...)[#34] --< Call >--> [[function]] bar[#17]
  obj.bar(...)[#34] --< D >--> $v2[#35]
  $v2[#35] -
