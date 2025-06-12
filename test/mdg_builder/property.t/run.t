Graph.js MDG Builder: static lookup
  $ graphjs mdg --no-export static_lookup.js
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
  [[function]] foo[#17] -
  [[function]] bar[#18] -
  obj[#19] --< V(foo) >--> obj[#20]
  obj[#19] --< P(foo) >--> obj.foo[#23]
  obj[#19] --< P(bar) >--> obj.bar[#29]
  obj[#19] --< P(baz) >--> obj.baz[#35]
  obj[#20] --< P(foo) >--> [[function]] foo[#17]
  obj[#20] --< V(bar) >--> obj[#21]
  obj[#21] --< P(bar) >--> [[function]] bar[#18]
  obj[#21] --< Arg(0) >--> obj.baz(...)[#36]
  10[#22] -
  obj.foo[#23] -
  foo[#24] --< V(x1) >--> foo[#25]
  foo[#25] --< P(x1) >--> 10[#22]
  10[#26] -
  "abc"[#27] -
  true[#28] -
  obj.bar[#29] -
  bar[#30] --< V(y1) >--> bar[#31]
  bar[#31] --< P(y1) >--> 10[#26]
  bar[#31] --< V(y2) >--> bar[#32]
  bar[#32] --< P(y2) >--> "abc"[#27]
  bar[#32] --< V(y3) >--> bar[#33]
  bar[#33] --< P(y3) >--> true[#28]
  10[#34] --< Arg(1) >--> obj.baz(...)[#36]
  obj.baz[#35] -
  obj.baz(...)[#36] --< Call >--> obj.baz[#35]
  obj.baz(...)[#36] --< D >--> $v3[#37]
  $v3[#37] -
  undef[#38] --< P(foo) >--> undef.foo[#39]
  undef.foo[#39] -

Graph.js MDG Builder: dynamic method
  $ graphjs mdg --no-export dynamic_method.js
  [[function]] foo[#17] --< D >--> obj.*[#23]
  [[function]] foo[#17] --< P(*) >--> $v7.*[#74]
  [[function]] foo[#17] --< Arg(0) >--> $v7.*(...)[#77]
  [[function]] bar[#18] --< D >--> obj.*[#23]
  [[function]] bar[#18] --< P(*) >--> $v7.*[#74]
  [[function]] bar[#18] --< Arg(0) >--> $v7.*(...)[#77]
  [[function]] bar[#18] --< D >--> undef.*[#80]
  obj[#19] --< V(foo) >--> obj[#20]
  obj[#19] --< P(*) >--> obj.*[#23]
  obj[#20] --< P(foo) >--> [[function]] foo[#17]
  obj[#20] --< V(bar) >--> obj[#21]
  obj[#21] --< P(bar) >--> [[function]] bar[#18]
  obj[#21] --< Arg(0) >--> obj.*(...)[#32]
  obj[#21] --< Arg(0) >--> obj.*(...)[#43]
  obj[#21] --< Arg(0) >--> obj.*(...)[#55]
  obj[#21] --< Arg(0) >--> obj.*(...)[#69]
  10[#22] --< Arg(1) >--> obj.*(...)[#32]
  obj.*[#23] --< P(*) >--> $v7.*[#74]
  obj.*[#23] --< Arg(0) >--> $v7.*(...)[#77]
  foo[#24] --< V(x1) >--> foo[#25]
  foo[#25] --< P(x1) >--> 10[#22]
  foo[#25] --< P(x1) >--> 10[#34]
  foo[#25] --< P(x1) >--> 10[#46]
  foo[#25] --< P(x1) >--> true[#60]
  bar[#26] --< V(y1) >--> bar[#27]
  bar[#27] --< P(y1) >--> 10[#22]
  bar[#27] --< V(y2) >--> bar[#29]
  bar[#27] --< P(y1) >--> 10[#34]
  bar[#27] --< P(y1) >--> 10[#46]
  bar[#27] --< P(y1) >--> true[#60]
  y2[#28] -
  bar[#29] --< P(y2) >--> y2[#28]
  bar[#29] --< V(y3) >--> bar[#31]
  bar[#29] --< P(y2) >--> "abc"[#35]
  y3[#30] -
  bar[#31] --< P(y3) >--> y3[#30]
  bar[#31] --< P(y3) >--> true[#36]
  obj.*(...)[#32] --< Call >--> obj.*[#23]
  obj.*(...)[#32] --< D >--> $v1[#33]
  $v1[#33] -
  10[#34] --< Arg(1) >--> obj.*(...)[#43]
  "abc"[#35] --< Arg(2) >--> obj.*(...)[#43]
  true[#36] --< Arg(3) >--> obj.*(...)[#43]
  obj.*(...)[#43] --< Call >--> obj.*[#23]
  obj.*(...)[#43] --< D >--> $v2[#44]
  $v2[#44] -
  $v3[#45] --< D >--> obj.*[#23]
  10[#46] --< Arg(1) >--> obj.*(...)[#55]
  obj.*(...)[#55] --< Call >--> obj.*[#23]
  obj.*(...)[#55] --< D >--> $v4[#56]
  $v4[#56] -
  10[#57] --< D >--> $v5[#59]
  "abc"[#58] --< D >--> $v5[#59]
  $v5[#59] --< D >--> obj.*[#23]
  true[#60] --< Arg(1) >--> obj.*(...)[#69]
  obj.*(...)[#69] --< Call >--> obj.*[#23]
  obj.*(...)[#69] --< D >--> $v6[#70]
  $v6[#70] -
  baz[#71] --< D >--> obj.*[#23]
  $v8[#72] --< D >--> $v7.*[#74]
  10[#73] --< Arg(1) >--> $v7.*(...)[#77]
  $v7.*[#74] -
  $v7.*(...)[#77] --< Call >--> $v7.*[#74]
  $v7.*(...)[#77] --< D >--> $v9[#78]
  $v9[#78] -
  undef[#79] --< P(*) >--> undef.*[#80]
  undef.*[#80] -
