Graph.js MDG Builder: static lookup
  $ graphjs mdg --no-export static_lookup.js
  obj[#19] --< P(foo) >--> obj.foo[#20]
  obj[#19] --< P(bar) >--> obj.bar[#21]
  obj[#19] --< P(10) >--> obj.10[#23]
  obj[#19] --< P(abc) >--> obj.abc[#24]
  obj[#19] --< P(null) >--> obj.null[#25]
  obj.foo[#20] -
  obj.bar[#21] --< P(baz) >--> obj.bar.baz[#22]
  obj.bar.baz[#22] -
  obj.10[#23] -
  obj.abc[#24] -
  obj.null[#25] -
  undef[#26] --< P(foo) >--> undef.foo[#27]
  undef.foo[#27] -

Graph.js MDG Builder: dynamic lookup
  $ graphjs mdg --no-export dynamic_lookup.js
  obj[#19] --< P(*) >--> obj.*[#21]
  foo[#20] --< D >--> obj.*[#21]
  obj.*[#21] --< P(*) >--> obj.*.*[#24]
  foo[#22] --< D >--> obj.*[#21]
  bar[#23] --< D >--> obj.*.*[#24]
  obj.*.*[#24] -
  $v4[#25] --< D >--> obj.*[#21]
  10[#26] --< D >--> $v6[#28]
  "abc"[#27] --< D >--> $v6[#28]
  $v6[#28] --< D >--> obj.*[#21]
  bar[#29] --< D >--> obj.*[#21]
  $v9[#30] --< D >--> obj.*.*[#24]
  undef[#31] --< P(*) >--> undef.*[#33]
  bar[#32] --< D >--> undef.*[#33]
  undef.*[#33] -

Graph.js MDG Builder: static update
  $ graphjs mdg --no-export static_update.js
  obj[#19] --< V(foo) >--> obj[#21]
  obj[#19] --< P(bar) >--> obj.bar[#24]
  10[#20] -
  obj[#21] --< P(foo) >--> 10[#20]
  obj[#21] --< V(bar) >--> obj[#23]
  $v1[#22] --< V(baz) >--> $v1[#26]
  obj[#23] --< P(bar) >--> $v1[#22]
  obj[#23] --< V(10) >--> obj[#28]
  obj.bar[#24] -
  10[#25] -
  $v1[#26] --< P(baz) >--> 10[#25]
  10[#27] -
  obj[#28] --< P(10) >--> 10[#27]
  obj[#28] --< V(abc) >--> obj[#30]
  10[#29] -
  obj[#30] --< P(abc) >--> 10[#29]
  obj[#30] --< V(null) >--> obj[#32]
  10[#31] -
  obj[#32] --< P(null) >--> 10[#31]
  undef[#33] --< V(foo) >--> undef[#35]
  10[#34] -
  undef[#35] --< P(foo) >--> 10[#34]

Graph.js MDG Builder: dynamic update
  $ graphjs mdg --no-export dynamic_update.js
  obj[#19] --< V(*) >--> obj[#22]
  obj[#19] --< P(*) >--> obj.*[#27]
  foo[#20] --< D >--> obj[#22]
  10[#21] --< V(*) >--> $v2[#30]
  obj[#22] --< P(*) >--> 10[#21]
  obj[#22] --< V(*) >--> obj[#25]
  $v1[#23] --< V(*) >--> $v2[#30]
  bar[#24] --< D >--> obj[#25]
  obj[#25] --< P(*) >--> $v1[#23]
  obj[#25] --< V(*) >--> obj[#33]
  foo[#26] --< D >--> obj.*[#27]
  obj.*[#27] --< V(*) >--> $v2[#30]
  bar[#28] --< D >--> $v2[#30]
  10[#29] -
  $v2[#30] --< P(*) >--> 10[#29]
  $v2[#30] --< V(*) >--> $v5[#42]
  $v3[#31] --< D >--> obj[#33]
  10[#32] --< V(*) >--> $v5[#42]
  obj[#33] --< P(*) >--> 10[#32]
  obj[#33] --< V(*) >--> obj[#38]
  10[#34] --< D >--> $v4[#36]
  "abc"[#35] --< D >--> $v4[#36]
  $v4[#36] --< D >--> obj[#38]
  true[#37] --< V(*) >--> $v5[#42]
  obj[#38] --< P(*) >--> true[#37]
  baz[#39] --< D >--> obj.*[#27]
  $v6[#40] --< D >--> $v5[#42]
  10[#41] -
  $v5[#42] --< P(*) >--> 10[#41]
  undef[#43] --< V(*) >--> undef[#46]
  foo[#44] --< D >--> undef[#46]
  10[#45] -
  undef[#46] --< P(*) >--> 10[#45]

Graph.js MDG Builder: static access
  $ graphjs mdg --no-export static_access.js
  obj[#19] --< V(foo) >--> obj[#21]
  obj[#19] --< P(baz) >--> obj.baz[#24]
  obj[#19] --< P(foo) >--> obj.foo[#27]
  obj[#19] --< P(bar) >--> obj.bar[#29]
  10[#20] -
  obj[#21] --< P(foo) >--> 10[#20]
  obj[#21] --< V(bar) >--> obj[#23]
  $v1[#22] -
  obj[#23] --< P(bar) >--> $v1[#22]
  obj[#23] --< V(qux) >--> obj[#28]
  obj.baz[#24] --< V(p) >--> obj.baz[#26]
  10[#25] -
  obj.baz[#26] --< P(p) >--> 10[#25]
  obj.foo[#27] -
  obj[#28] --< P(qux) >--> 10[#20]
  obj[#28] --< V(qux) >--> obj[#30]
  obj.bar[#29] -
  obj[#30] --< P(qux) >--> $v1[#22]

Graph.js MDG Builder: dynamic access
  $ graphjs mdg --no-export dynamic_access.js
  obj[#19] --< V(*) >--> obj[#22]
  obj[#19] --< P(*) >--> obj.*[#27]
  foo[#20] --< D >--> obj[#22]
  10[#21] --< V(*) >--> $v2[#30]
  obj[#22] --< P(*) >--> 10[#21]
  obj[#22] --< V(*) >--> obj[#25]
  $v1[#23] --< V(*) >--> $v2[#30]
  bar[#24] --< D >--> obj[#25]
  obj[#25] --< P(*) >--> $v1[#23]
  obj[#25] --< V(*) >--> obj[#33]
  baz[#26] --< D >--> obj.*[#27]
  obj.*[#27] --< V(*) >--> $v2[#30]
  p[#28] --< D >--> $v2[#30]
  10[#29] -
  $v2[#30] --< P(*) >--> 10[#29]
  foo[#31] --< D >--> obj.*[#27]
  qux[#32] --< D >--> obj[#33]
  obj[#33] --< P(*) >--> $v2[#30]
  obj[#33] --< V(*) >--> obj[#36]
  bar[#34] --< D >--> obj.*[#27]
  qux[#35] --< D >--> obj[#36]
  obj[#36] --< P(*) >--> $v2[#30]

Graph.js MDG Builder: static method
  $ graphjs mdg --no-export static_method.js
  [[function]] foo[#19] -
  [[function]] bar[#20] -
  obj[#21] --< V(foo) >--> obj[#22]
  obj[#21] --< P(foo) >--> obj.foo[#25]
  obj[#21] --< P(bar) >--> obj.bar[#31]
  obj[#21] --< P(baz) >--> obj.baz[#37]
  obj[#22] --< P(foo) >--> [[function]] foo[#19]
  obj[#22] --< V(bar) >--> obj[#23]
  obj[#23] --< P(bar) >--> [[function]] bar[#20]
  obj[#23] --< Arg(0) >--> obj.baz(...)[#38]
  10[#24] -
  obj.foo[#25] -
  foo[#26] --< V(x1) >--> foo[#27]
  foo[#27] --< P(x1) >--> 10[#24]
  10[#28] -
  "abc"[#29] -
  true[#30] -
  obj.bar[#31] -
  bar[#32] --< V(y1) >--> bar[#33]
  bar[#33] --< P(y1) >--> 10[#28]
  bar[#33] --< V(y2) >--> bar[#34]
  bar[#34] --< P(y2) >--> "abc"[#29]
  bar[#34] --< V(y3) >--> bar[#35]
  bar[#35] --< P(y3) >--> true[#30]
  10[#36] --< Arg(1) >--> obj.baz(...)[#38]
  obj.baz[#37] -
  obj.baz(...)[#38] --< Call >--> obj.baz[#37]
  obj.baz(...)[#38] --< D >--> $v3[#39]
  $v3[#39] -
  undef[#40] --< P(foo) >--> undef.foo[#41]
  undef.foo[#41] -

Graph.js MDG Builder: dynamic method
  $ graphjs mdg --no-export dynamic_method.js
  [[function]] foo[#19] --< D >--> obj.*[#25]
  [[function]] foo[#19] --< P(*) >--> $v7.*[#76]
  [[function]] foo[#19] --< Arg(0) >--> $v7.*(...)[#79]
  [[function]] bar[#20] --< D >--> obj.*[#25]
  [[function]] bar[#20] --< P(*) >--> $v7.*[#76]
  [[function]] bar[#20] --< Arg(0) >--> $v7.*(...)[#79]
  [[function]] bar[#20] --< D >--> undef.*[#82]
  obj[#21] --< V(foo) >--> obj[#22]
  obj[#21] --< P(*) >--> obj.*[#25]
  obj[#22] --< P(foo) >--> [[function]] foo[#19]
  obj[#22] --< V(bar) >--> obj[#23]
  obj[#23] --< P(bar) >--> [[function]] bar[#20]
  obj[#23] --< Arg(0) >--> obj.*(...)[#34]
  obj[#23] --< Arg(0) >--> obj.*(...)[#45]
  obj[#23] --< Arg(0) >--> obj.*(...)[#57]
  obj[#23] --< Arg(0) >--> obj.*(...)[#71]
  10[#24] --< Arg(1) >--> obj.*(...)[#34]
  obj.*[#25] --< P(*) >--> $v7.*[#76]
  obj.*[#25] --< Arg(0) >--> $v7.*(...)[#79]
  foo[#26] --< V(x1) >--> foo[#27]
  foo[#27] --< P(x1) >--> 10[#24]
  foo[#27] --< P(x1) >--> 10[#36]
  foo[#27] --< P(x1) >--> 10[#48]
  foo[#27] --< P(x1) >--> true[#62]
  bar[#28] --< V(y1) >--> bar[#29]
  bar[#29] --< P(y1) >--> 10[#24]
  bar[#29] --< V(y2) >--> bar[#31]
  bar[#29] --< P(y1) >--> 10[#36]
  bar[#29] --< P(y1) >--> 10[#48]
  bar[#29] --< P(y1) >--> true[#62]
  y2[#30] -
  bar[#31] --< P(y2) >--> y2[#30]
  bar[#31] --< V(y3) >--> bar[#33]
  bar[#31] --< P(y2) >--> "abc"[#37]
  y3[#32] -
  bar[#33] --< P(y3) >--> y3[#32]
  bar[#33] --< P(y3) >--> true[#38]
  obj.*(...)[#34] --< Call >--> obj.*[#25]
  obj.*(...)[#34] --< D >--> $v1[#35]
  $v1[#35] -
  10[#36] --< Arg(1) >--> obj.*(...)[#45]
  "abc"[#37] --< Arg(2) >--> obj.*(...)[#45]
  true[#38] --< Arg(3) >--> obj.*(...)[#45]
  obj.*(...)[#45] --< Call >--> obj.*[#25]
  obj.*(...)[#45] --< D >--> $v2[#46]
  $v2[#46] -
  $v3[#47] --< D >--> obj.*[#25]
  10[#48] --< Arg(1) >--> obj.*(...)[#57]
  obj.*(...)[#57] --< Call >--> obj.*[#25]
  obj.*(...)[#57] --< D >--> $v4[#58]
  $v4[#58] -
  10[#59] --< D >--> $v5[#61]
  "abc"[#60] --< D >--> $v5[#61]
  $v5[#61] --< D >--> obj.*[#25]
  true[#62] --< Arg(1) >--> obj.*(...)[#71]
  obj.*(...)[#71] --< Call >--> obj.*[#25]
  obj.*(...)[#71] --< D >--> $v6[#72]
  $v6[#72] -
  baz[#73] --< D >--> obj.*[#25]
  $v8[#74] --< D >--> $v7.*[#76]
  10[#75] --< Arg(1) >--> $v7.*(...)[#79]
  $v7.*[#76] -
  $v7.*(...)[#79] --< Call >--> $v7.*[#76]
  $v7.*(...)[#79] --< D >--> $v9[#80]
  $v9[#80] -
  undef[#81] --< P(*) >--> undef.*[#82]
  undef.*[#82] -
