Graph.js MDG Builder: simple object
  $ graphjs mdg --no-export object.js
  foo[#7] -
  bar[#8] -
  baz[#9] -
  qux[#10] -

Graph.js MDG Builder: simple array
  $ graphjs mdg --no-export array.js
  foo[#7] -
  bar[#8] -
  baz[#9] -
  qux[#10] -

Graph.js MDG Builder: this access
  $ graphjs mdg --no-export this.js
  [[function]] bar[#7] --< Param(0) >--> this[#8]
  [[function]] bar[#7] --< Param(1) >--> x1[#9]
  this[#8] --< P(foo) >--> this.foo[#10]
  this[#8] --< P(bar) >--> this.bar[#12]
  this[#8] --< Arg(0) >--> this.bar(...)[#13]
  x1[#9] -
  this.foo[#10] -
  "abc"[#11] --< Arg(1) >--> this.bar(...)[#13]
  this.bar[#12] -
  this.bar(...)[#13] --< Call >--> this.bar[#12]
  this.bar(...)[#13] --< D >--> y[#14]
  y[#14] -
  obj[#15] --< V(foo) >--> obj[#17]
  obj[#15] --< P(bar) >--> obj.bar[#23]
  10[#16] -
  obj[#17] --< P(foo) >--> 10[#16]
  obj[#17] --< V(bar) >--> obj[#18]
  obj[#18] --< P(bar) >--> [[function]] bar[#7]
  obj[#18] --< Arg(0) >--> obj.bar(...)[#24]
  10[#19] --< Arg(1) >--> bar(...)[#20]
  bar(...)[#20] --< Call >--> [[function]] bar[#7]
  bar(...)[#20] --< D >--> $v1[#21]
  $v1[#21] -
  10[#22] --< Arg(1) >--> obj.bar(...)[#24]
  obj.bar[#23] -
  obj.bar(...)[#24] --< Call >--> [[function]] bar[#7]
  obj.bar(...)[#24] --< D >--> $v2[#25]
  $v2[#25] -
