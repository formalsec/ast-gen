Graph.js MDG Builder: static lookup
  $ graphjs mdg --no-export static_lookup.js
  obj[#9] --< P(foo) >--> obj.foo[#10]
  obj[#9] --< P(bar) >--> obj.bar[#11]
  obj[#9] --< P(10) >--> obj.10[#13]
  obj[#9] --< P(abc) >--> obj.abc[#14]
  obj[#9] --< P(null) >--> obj.null[#15]
  obj.foo[#10] -
  obj.bar[#11] --< P(baz) >--> obj.bar.baz[#12]
  obj.bar.baz[#12] -
  obj.10[#13] -
  obj.abc[#14] -
  obj.null[#15] -
  undef[#16] --< P(foo) >--> undef.foo[#17]
  undef.foo[#17] -

Graph.js MDG Builder: dynamic lookup
  $ graphjs mdg --no-export dynamic_lookup.js
  obj[#9] --< P(*) >--> obj.*[#11]
  foo[#10] --< D >--> obj.*[#11]
  obj.*[#11] --< P(*) >--> obj.*.*[#14]
  foo[#12] --< D >--> obj.*[#11]
  bar[#13] --< D >--> obj.*.*[#14]
  obj.*.*[#14] -
  $v4[#15] --< D >--> obj.*[#11]
  10[#16] --< D >--> $v6[#18]
  "abc"[#17] --< D >--> $v6[#18]
  $v6[#18] --< D >--> obj.*[#11]
  bar[#19] --< D >--> obj.*[#11]
  $v9[#20] --< D >--> obj.*.*[#14]
  undef[#21] --< P(*) >--> undef.*[#23]
  bar[#22] --< D >--> undef.*[#23]
  undef.*[#23] -

Graph.js MDG Builder: static update
  $ graphjs mdg --no-export static_update.js
  obj[#9] --< V(foo) >--> obj[#11]
  obj[#9] --< P(bar) >--> obj.bar[#14]
  10[#10] -
  obj[#11] --< P(foo) >--> 10[#10]
  obj[#11] --< V(bar) >--> obj[#13]
  $v1[#12] --< V(baz) >--> $v1[#16]
  obj[#13] --< P(bar) >--> $v1[#12]
  obj[#13] --< V(10) >--> obj[#18]
  obj.bar[#14] -
  10[#15] -
  $v1[#16] --< P(baz) >--> 10[#15]
  10[#17] -
  obj[#18] --< P(10) >--> 10[#17]
  obj[#18] --< V(abc) >--> obj[#20]
  10[#19] -
  obj[#20] --< P(abc) >--> 10[#19]
  obj[#20] --< V(null) >--> obj[#22]
  10[#21] -
  obj[#22] --< P(null) >--> 10[#21]
  undef[#23] --< V(foo) >--> undef[#25]
  10[#24] -
  undef[#25] --< P(foo) >--> 10[#24]

Graph.js MDG Builder: dynamic update
  $ graphjs mdg --no-export dynamic_update.js
  obj[#9] --< V(*) >--> obj[#12]
  obj[#9] --< P(*) >--> obj.*[#17]
  foo[#10] --< D >--> obj[#12]
  10[#11] --< V(*) >--> $v2[#20]
  obj[#12] --< P(*) >--> 10[#11]
  obj[#12] --< V(*) >--> obj[#15]
  $v1[#13] --< V(*) >--> $v2[#20]
  bar[#14] --< D >--> obj[#15]
  obj[#15] --< P(*) >--> $v1[#13]
  obj[#15] --< V(*) >--> obj[#23]
  foo[#16] --< D >--> obj.*[#17]
  obj.*[#17] --< V(*) >--> $v2[#20]
  bar[#18] --< D >--> $v2[#20]
  10[#19] -
  $v2[#20] --< P(*) >--> 10[#19]
  $v2[#20] --< V(*) >--> $v5[#32]
  $v3[#21] --< D >--> obj[#23]
  10[#22] --< V(*) >--> $v5[#32]
  obj[#23] --< P(*) >--> 10[#22]
  obj[#23] --< V(*) >--> obj[#28]
  10[#24] --< D >--> $v4[#26]
  "abc"[#25] --< D >--> $v4[#26]
  $v4[#26] --< D >--> obj[#28]
  true[#27] --< V(*) >--> $v5[#32]
  obj[#28] --< P(*) >--> true[#27]
  baz[#29] --< D >--> obj.*[#17]
  $v6[#30] --< D >--> $v5[#32]
  10[#31] -
  $v5[#32] --< P(*) >--> 10[#31]
  undef[#33] --< V(*) >--> undef[#36]
  foo[#34] --< D >--> undef[#36]
  10[#35] -
  undef[#36] --< P(*) >--> 10[#35]

Graph.js MDG Builder: static access
  $ graphjs mdg --no-export static_access.js
  obj[#9] --< V(foo) >--> obj[#11]
  obj[#9] --< P(baz) >--> obj.baz[#14]
  obj[#9] --< P(foo) >--> obj.foo[#17]
  obj[#9] --< P(bar) >--> obj.bar[#19]
  10[#10] -
  obj[#11] --< P(foo) >--> 10[#10]
  obj[#11] --< V(bar) >--> obj[#13]
  $v1[#12] -
  obj[#13] --< P(bar) >--> $v1[#12]
  obj[#13] --< V(qux) >--> obj[#18]
  obj.baz[#14] --< V(p) >--> obj.baz[#16]
  10[#15] -
  obj.baz[#16] --< P(p) >--> 10[#15]
  obj.foo[#17] -
  obj[#18] --< P(qux) >--> 10[#10]
  obj[#18] --< V(qux) >--> obj[#20]
  obj.bar[#19] -
  obj[#20] --< P(qux) >--> $v1[#12]

Graph.js MDG Builder: dynamic access
  $ graphjs mdg --no-export dynamic_access.js
  obj[#9] --< V(*) >--> obj[#12]
  obj[#9] --< P(*) >--> obj.*[#17]
  foo[#10] --< D >--> obj[#12]
  10[#11] --< V(*) >--> $v2[#20]
  obj[#12] --< P(*) >--> 10[#11]
  obj[#12] --< V(*) >--> obj[#15]
  $v1[#13] --< V(*) >--> $v2[#20]
  bar[#14] --< D >--> obj[#15]
  obj[#15] --< P(*) >--> $v1[#13]
  obj[#15] --< V(*) >--> obj[#23]
  baz[#16] --< D >--> obj.*[#17]
  obj.*[#17] --< V(*) >--> $v2[#20]
  p[#18] --< D >--> $v2[#20]
  10[#19] -
  $v2[#20] --< P(*) >--> 10[#19]
  foo[#21] --< D >--> obj.*[#17]
  qux[#22] --< D >--> obj[#23]
  obj[#23] --< P(*) >--> $v2[#20]
  obj[#23] --< V(*) >--> obj[#26]
  bar[#24] --< D >--> obj.*[#17]
  qux[#25] --< D >--> obj[#26]
  obj[#26] --< P(*) >--> $v2[#20]

Graph.js MDG Builder: static method
  $ graphjs mdg --no-export static_method.js
  obj[#9] --< V(foo) >--> obj[#13]
  obj[#9] --< P(foo) >--> obj.foo[#21]
  obj[#9] --< P(bar) >--> obj.bar[#27]
  obj[#9] --< P(baz) >--> obj.baz[#31]
  [[function]] $v1[#10] --< Param(0) >--> this[#11]
  [[function]] $v1[#10] --< Param(1) >--> x1[#12]
  this[#11] -
  x1[#12] -
  obj[#13] --< P(foo) >--> [[function]] $v1[#10]
  obj[#13] --< V(bar) >--> obj[#19]
  [[function]] $v2[#14] --< Param(0) >--> this[#15]
  [[function]] $v2[#14] --< Param(1) >--> y1[#16]
  [[function]] $v2[#14] --< Param(2) >--> y2[#17]
  [[function]] $v2[#14] --< Param(3) >--> y3[#18]
  this[#15] -
  y1[#16] -
  y2[#17] -
  y3[#18] -
  obj[#19] --< P(bar) >--> [[function]] $v2[#14]
  obj[#19] --< Arg(0) >--> obj.foo(...)[#22]
  obj[#19] --< Arg(0) >--> obj.bar(...)[#28]
  obj[#19] --< Arg(0) >--> obj.baz(...)[#32]
  10[#20] --< Arg(1) >--> obj.foo(...)[#22]
  obj.foo[#21] -
  obj.foo(...)[#22] --< Call >--> [[function]] $v1[#10]
  obj.foo(...)[#22] --< D >--> $v3[#23]
  $v3[#23] -
  10[#24] --< Arg(1) >--> obj.bar(...)[#28]
  "abc"[#25] --< Arg(2) >--> obj.bar(...)[#28]
  true[#26] --< Arg(3) >--> obj.bar(...)[#28]
  obj.bar[#27] -
  obj.bar(...)[#28] --< Call >--> [[function]] $v2[#14]
  obj.bar(...)[#28] --< D >--> $v4[#29]
  $v4[#29] -
  10[#30] --< Arg(1) >--> obj.baz(...)[#32]
  obj.baz[#31] -
  obj.baz(...)[#32] --< Call >--> obj.baz[#31]
  obj.baz(...)[#32] --< D >--> $v5[#33]
  $v5[#33] -
  undef[#34] --< P(foo) >--> undef.foo[#35]
  undef.foo[#35] -

Graph.js MDG Builder: dynamic method
  $ graphjs mdg --no-export dynamic_method.js
  obj[#9] --< V(foo) >--> obj[#13]
  obj[#9] --< P(*) >--> foo[#20]
  [[function]] $v1[#10] --< Param(0) >--> this[#11]
  [[function]] $v1[#10] --< Param(1) >--> x1[#12]
  [[function]] $v1[#10] --< P(*) >--> $v9.*[#43]
  [[function]] $v1[#10] --< Arg(0) >--> $v9.*(...)[#44]
  this[#11] -
  x1[#12] -
  obj[#13] --< P(foo) >--> [[function]] $v1[#10]
  obj[#13] --< V(bar) >--> obj[#19]
  [[function]] $v2[#14] --< Param(0) >--> this[#15]
  [[function]] $v2[#14] --< Param(1) >--> y1[#16]
  [[function]] $v2[#14] --< Param(2) >--> y2[#17]
  [[function]] $v2[#14] --< Param(3) >--> y3[#18]
  [[function]] $v2[#14] --< P(*) >--> $v9.*[#43]
  [[function]] $v2[#14] --< Arg(0) >--> $v9.*(...)[#44]
  this[#15] -
  y1[#16] -
  y2[#17] -
  y3[#18] -
  obj[#19] --< P(bar) >--> [[function]] $v2[#14]
  obj[#19] --< Arg(0) >--> obj.*(...)[#22]
  obj[#19] --< Arg(0) >--> obj.*(...)[#28]
  obj[#19] --< Arg(0) >--> obj.*(...)[#32]
  obj[#19] --< Arg(0) >--> obj.*(...)[#38]
  foo[#20] --< D >--> foo[#20]
  foo[#20] --< P(*) >--> $v9.*[#43]
  foo[#20] --< Arg(0) >--> $v9.*(...)[#44]
  10[#21] --< Arg(1) >--> obj.*(...)[#22]
  obj.*(...)[#22] --< Call >--> [[function]] $v1[#10]
  obj.*(...)[#22] --< Call >--> [[function]] $v2[#14]
  obj.*(...)[#22] --< Call >--> foo[#20]
  obj.*(...)[#22] --< D >--> $v3[#23]
  $v3[#23] -
  bar[#24] --< D >--> foo[#20]
  10[#25] --< Arg(1) >--> obj.*(...)[#28]
  "abc"[#26] --< Arg(2) >--> obj.*(...)[#28]
  true[#27] --< Arg(3) >--> obj.*(...)[#28]
  obj.*(...)[#28] --< Call >--> [[function]] $v1[#10]
  obj.*(...)[#28] --< Call >--> [[function]] $v2[#14]
  obj.*(...)[#28] --< Call >--> foo[#20]
  obj.*(...)[#28] --< D >--> $v4[#29]
  $v4[#29] -
  $v5[#30] --< D >--> foo[#20]
  10[#31] --< Arg(1) >--> obj.*(...)[#32]
  obj.*(...)[#32] --< Call >--> [[function]] $v1[#10]
  obj.*(...)[#32] --< Call >--> [[function]] $v2[#14]
  obj.*(...)[#32] --< Call >--> foo[#20]
  obj.*(...)[#32] --< D >--> $v6[#33]
  $v6[#33] -
  10[#34] --< D >--> $v7[#36]
  "abc"[#35] --< D >--> $v7[#36]
  $v7[#36] --< D >--> foo[#20]
  true[#37] --< Arg(1) >--> obj.*(...)[#38]
  obj.*(...)[#38] --< Call >--> [[function]] $v1[#10]
  obj.*(...)[#38] --< Call >--> [[function]] $v2[#14]
  obj.*(...)[#38] --< Call >--> foo[#20]
  obj.*(...)[#38] --< D >--> $v8[#39]
  $v8[#39] -
  baz[#40] --< D >--> foo[#20]
  $v10[#41] --< D >--> $v9.*[#43]
  10[#42] --< Arg(1) >--> $v9.*(...)[#44]
  $v9.*[#43] -
  $v9.*(...)[#44] --< Call >--> $v9.*[#43]
  $v9.*(...)[#44] --< D >--> $v11[#45]
  $v11[#45] -
  undef[#46] --< P(*) >--> undef.*[#48]
  bar[#47] --< D >--> undef.*[#48]
  undef.*[#48] -
