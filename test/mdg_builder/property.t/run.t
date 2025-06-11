Graph.js MDG Builder: static lookup
  $ graphjs mdg --no-export static_lookup.js
  [[function]] defineProperty[#5] -
  obj[#17] --< P(foo) >--> obj.foo[#18]
  obj[#17] --< P(bar) >--> obj.bar[#19]
  obj[#17] --< P(10) >--> obj.10[#21]
  obj[#17] --< P(abc) >--> obj.abc[#22]
  obj[#17] --< P(null) >--> obj.null[#23]
  obj.foo[#18] -
  obj.bar[#19] --< P(baz) >--> obj.bar.baz[#20]
  obj.bar.baz[#20] -
  obj.10[#21] -
  obj.abc[#22] -
  obj.null[#23] -
  undef[#24] --< P(foo) >--> undef.foo[#25]
  undef.foo[#25] -

Graph.js MDG Builder: dynamic lookup
  $ graphjs mdg --no-export dynamic_lookup.js
  [[function]] defineProperty[#5] -
  obj[#17] --< P(*) >--> obj.*[#19]
  foo[#18] --< D >--> obj.*[#19]
  obj.*[#19] --< P(*) >--> obj.*.*[#22]
  foo[#20] --< D >--> obj.*[#19]
  bar[#21] --< D >--> obj.*.*[#22]
  obj.*.*[#22] -
  $v4[#23] --< D >--> obj.*[#19]
  10[#24] --< D >--> $v6[#26]
  "abc"[#25] --< D >--> $v6[#26]
  $v6[#26] --< D >--> obj.*[#19]
  bar[#27] --< D >--> obj.*[#19]
  $v9[#28] --< D >--> obj.*.*[#22]
  undef[#29] --< P(*) >--> undef.*[#31]
  bar[#30] --< D >--> undef.*[#31]
  undef.*[#31] -

Graph.js MDG Builder: static update
  $ graphjs mdg --no-export static_update.js
  [[function]] defineProperty[#5] -
  obj[#17] --< V(foo) >--> obj[#19]
  obj[#17] --< P(bar) >--> obj.bar[#22]
  10[#18] -
  obj[#19] --< P(foo) >--> 10[#18]
  obj[#19] --< V(bar) >--> obj[#21]
  $v1[#20] --< V(baz) >--> $v1[#24]
  obj[#21] --< P(bar) >--> $v1[#20]
  obj[#21] --< V(10) >--> obj[#26]
  obj.bar[#22] -
  10[#23] -
  $v1[#24] --< P(baz) >--> 10[#23]
  10[#25] -
  obj[#26] --< P(10) >--> 10[#25]
  obj[#26] --< V(abc) >--> obj[#28]
  10[#27] -
  obj[#28] --< P(abc) >--> 10[#27]
  obj[#28] --< V(null) >--> obj[#30]
  10[#29] -
  obj[#30] --< P(null) >--> 10[#29]
  undef[#31] --< V(foo) >--> undef[#33]
  10[#32] -
  undef[#33] --< P(foo) >--> 10[#32]

Graph.js MDG Builder: dynamic update
  $ graphjs mdg --no-export dynamic_update.js
  [[function]] defineProperty[#5] -
  obj[#17] --< V(*) >--> obj[#20]
  obj[#17] --< P(*) >--> obj.*[#25]
  foo[#18] --< D >--> obj[#20]
  10[#19] --< V(*) >--> $v2[#28]
  obj[#20] --< P(*) >--> 10[#19]
  obj[#20] --< V(*) >--> obj[#23]
  $v1[#21] --< V(*) >--> $v2[#28]
  bar[#22] --< D >--> obj[#23]
  obj[#23] --< P(*) >--> $v1[#21]
  obj[#23] --< V(*) >--> obj[#31]
  foo[#24] --< D >--> obj.*[#25]
  obj.*[#25] --< V(*) >--> $v2[#28]
  bar[#26] --< D >--> $v2[#28]
  10[#27] -
  $v2[#28] --< P(*) >--> 10[#27]
  $v2[#28] --< V(*) >--> $v5[#40]
  $v3[#29] --< D >--> obj[#31]
  10[#30] --< V(*) >--> $v5[#40]
  obj[#31] --< P(*) >--> 10[#30]
  obj[#31] --< V(*) >--> obj[#36]
  10[#32] --< D >--> $v4[#34]
  "abc"[#33] --< D >--> $v4[#34]
  $v4[#34] --< D >--> obj[#36]
  true[#35] --< V(*) >--> $v5[#40]
  obj[#36] --< P(*) >--> true[#35]
  baz[#37] --< D >--> obj.*[#25]
  $v6[#38] --< D >--> $v5[#40]
  10[#39] -
  $v5[#40] --< P(*) >--> 10[#39]
  undef[#41] --< V(*) >--> undef[#44]
  foo[#42] --< D >--> undef[#44]
  10[#43] -
  undef[#44] --< P(*) >--> 10[#43]

Graph.js MDG Builder: static access
  $ graphjs mdg --no-export static_access.js
  [[function]] defineProperty[#5] -
  obj[#17] --< V(foo) >--> obj[#19]
  obj[#17] --< P(baz) >--> obj.baz[#22]
  obj[#17] --< P(foo) >--> obj.foo[#25]
  obj[#17] --< P(bar) >--> obj.bar[#27]
  10[#18] -
  obj[#19] --< P(foo) >--> 10[#18]
  obj[#19] --< V(bar) >--> obj[#21]
  $v1[#20] -
  obj[#21] --< P(bar) >--> $v1[#20]
  obj[#21] --< V(qux) >--> obj[#26]
  obj.baz[#22] --< V(p) >--> obj.baz[#24]
  10[#23] -
  obj.baz[#24] --< P(p) >--> 10[#23]
  obj.foo[#25] -
  obj[#26] --< P(qux) >--> 10[#18]
  obj[#26] --< V(qux) >--> obj[#28]
  obj.bar[#27] -
  obj[#28] --< P(qux) >--> $v1[#20]

Graph.js MDG Builder: dynamic access
  $ graphjs mdg --no-export dynamic_access.js
  [[function]] defineProperty[#5] -
  obj[#17] --< V(*) >--> obj[#20]
  obj[#17] --< P(*) >--> obj.*[#25]
  foo[#18] --< D >--> obj[#20]
  10[#19] --< V(*) >--> $v2[#28]
  obj[#20] --< P(*) >--> 10[#19]
  obj[#20] --< V(*) >--> obj[#23]
  $v1[#21] --< V(*) >--> $v2[#28]
  bar[#22] --< D >--> obj[#23]
  obj[#23] --< P(*) >--> $v1[#21]
  obj[#23] --< V(*) >--> obj[#31]
  baz[#24] --< D >--> obj.*[#25]
  obj.*[#25] --< V(*) >--> $v2[#28]
  p[#26] --< D >--> $v2[#28]
  10[#27] -
  $v2[#28] --< P(*) >--> 10[#27]
  foo[#29] --< D >--> obj.*[#25]
  qux[#30] --< D >--> obj[#31]
  obj[#31] --< P(*) >--> $v2[#28]
  obj[#31] --< V(*) >--> obj[#34]
  bar[#32] --< D >--> obj.*[#25]
  qux[#33] --< D >--> obj[#34]
  obj[#34] --< P(*) >--> $v2[#28]

Graph.js MDG Builder: static method
  $ graphjs mdg --no-export static_method.js
  [[function]] defineProperty[#5] -
  obj[#17] --< V(foo) >--> obj[#21]
  obj[#17] --< P(foo) >--> obj.foo[#29]
  obj[#17] --< P(bar) >--> obj.bar[#35]
  obj[#17] --< P(baz) >--> obj.baz[#39]
  [[function]] $v1[#18] --< Param(0) >--> this[#19]
  [[function]] $v1[#18] --< Param(1) >--> x1[#20]
  this[#19] -
  x1[#20] -
  obj[#21] --< P(foo) >--> [[function]] $v1[#18]
  obj[#21] --< V(bar) >--> obj[#27]
  [[function]] $v2[#22] --< Param(0) >--> this[#23]
  [[function]] $v2[#22] --< Param(1) >--> y1[#24]
  [[function]] $v2[#22] --< Param(2) >--> y2[#25]
  [[function]] $v2[#22] --< Param(3) >--> y3[#26]
  this[#23] -
  y1[#24] -
  y2[#25] -
  y3[#26] -
  obj[#27] --< P(bar) >--> [[function]] $v2[#22]
  obj[#27] --< Arg(0) >--> obj.foo(...)[#30]
  obj[#27] --< Arg(0) >--> obj.bar(...)[#36]
  obj[#27] --< Arg(0) >--> obj.baz(...)[#40]
  10[#28] --< Arg(1) >--> obj.foo(...)[#30]
  obj.foo[#29] -
  obj.foo(...)[#30] --< Call >--> [[function]] $v1[#18]
  obj.foo(...)[#30] --< D >--> $v3[#31]
  $v3[#31] -
  10[#32] --< Arg(1) >--> obj.bar(...)[#36]
  "abc"[#33] --< Arg(2) >--> obj.bar(...)[#36]
  true[#34] --< Arg(3) >--> obj.bar(...)[#36]
  obj.bar[#35] -
  obj.bar(...)[#36] --< Call >--> [[function]] $v2[#22]
  obj.bar(...)[#36] --< D >--> $v4[#37]
  $v4[#37] -
  10[#38] --< Arg(1) >--> obj.baz(...)[#40]
  obj.baz[#39] -
  obj.baz(...)[#40] --< Call >--> obj.baz[#39]
  obj.baz(...)[#40] --< D >--> $v5[#41]
  $v5[#41] -
  undef[#42] --< P(foo) >--> undef.foo[#43]
  undef.foo[#43] -

Graph.js MDG Builder: dynamic method
  $ graphjs mdg --no-export dynamic_method.js
  [[function]] defineProperty[#5] -
  obj[#17] --< V(foo) >--> obj[#21]
  obj[#17] --< P(*) >--> foo[#28]
  [[function]] $v1[#18] --< Param(0) >--> this[#19]
  [[function]] $v1[#18] --< Param(1) >--> x1[#20]
  [[function]] $v1[#18] --< P(*) >--> $v9.*[#52]
  [[function]] $v1[#18] --< Arg(0) >--> $v9.*(...)[#55]
  this[#19] -
  x1[#20] -
  obj[#21] --< P(foo) >--> [[function]] $v1[#18]
  obj[#21] --< V(bar) >--> obj[#27]
  [[function]] $v2[#22] --< Param(0) >--> this[#23]
  [[function]] $v2[#22] --< Param(1) >--> y1[#24]
  [[function]] $v2[#22] --< Param(2) >--> y2[#25]
  [[function]] $v2[#22] --< Param(3) >--> y3[#26]
  [[function]] $v2[#22] --< P(*) >--> $v9.*[#52]
  [[function]] $v2[#22] --< Arg(0) >--> $v9.*(...)[#55]
  this[#23] -
  y1[#24] -
  y2[#25] -
  y3[#26] -
  obj[#27] --< P(bar) >--> [[function]] $v2[#22]
  obj[#27] --< Arg(0) >--> obj.*(...)[#31]
  obj[#27] --< Arg(0) >--> obj.*(...)[#37]
  obj[#27] --< Arg(0) >--> obj.*(...)[#41]
  obj[#27] --< Arg(0) >--> obj.*(...)[#47]
  foo[#28] --< D >--> foo[#28]
  foo[#28] --< P(*) >--> $v9.*[#52]
  foo[#28] --< Arg(0) >--> $v9.*(...)[#55]
  10[#29] --< Arg(1) >--> obj.*(...)[#31]
  obj.*(...)[#31] --< Call >--> [[function]] $v1[#18]
  obj.*(...)[#31] --< Call >--> [[function]] $v2[#22]
  obj.*(...)[#31] --< Call >--> foo[#28]
  obj.*(...)[#31] --< D >--> $v3[#32]
  $v3[#32] -
  bar[#33] --< D >--> foo[#28]
  10[#34] --< Arg(1) >--> obj.*(...)[#37]
  "abc"[#35] --< Arg(2) >--> obj.*(...)[#37]
  true[#36] --< Arg(3) >--> obj.*(...)[#37]
  obj.*(...)[#37] --< Call >--> [[function]] $v1[#18]
  obj.*(...)[#37] --< Call >--> [[function]] $v2[#22]
  obj.*(...)[#37] --< Call >--> foo[#28]
  obj.*(...)[#37] --< D >--> $v4[#38]
  $v4[#38] -
  $v5[#39] --< D >--> foo[#28]
  10[#40] --< Arg(1) >--> obj.*(...)[#41]
  obj.*(...)[#41] --< Call >--> [[function]] $v1[#18]
  obj.*(...)[#41] --< Call >--> [[function]] $v2[#22]
  obj.*(...)[#41] --< Call >--> foo[#28]
  obj.*(...)[#41] --< D >--> $v6[#42]
  $v6[#42] -
  10[#43] --< D >--> $v7[#45]
  "abc"[#44] --< D >--> $v7[#45]
  $v7[#45] --< D >--> foo[#28]
  true[#46] --< Arg(1) >--> obj.*(...)[#47]
  obj.*(...)[#47] --< Call >--> [[function]] $v1[#18]
  obj.*(...)[#47] --< Call >--> [[function]] $v2[#22]
  obj.*(...)[#47] --< Call >--> foo[#28]
  obj.*(...)[#47] --< D >--> $v8[#48]
  $v8[#48] -
  baz[#49] --< D >--> foo[#28]
  $v10[#50] --< D >--> $v9.*[#52]
  10[#51] --< Arg(1) >--> $v9.*(...)[#55]
  $v9.*[#52] -
  $v9.*(...)[#55] --< Call >--> $v9.*[#52]
  $v9.*(...)[#55] --< D >--> $v11[#56]
  $v11[#56] -
  undef[#57] --< P(*) >--> undef.*[#59]
  bar[#58] --< D >--> undef.*[#59]
  undef.*[#59] -
