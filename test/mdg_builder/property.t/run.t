Graph.js MDG Builder: static lookup
  $ graphjs mdg --no-export static_lookup.js
  obj[#18] --< P(foo) >--> obj.foo[#19]
  obj[#18] --< P(bar) >--> obj.bar[#20]
  obj[#18] --< P(10) >--> obj.10[#22]
  obj[#18] --< P(abc) >--> obj.abc[#23]
  obj[#18] --< P(null) >--> obj.null[#24]
  obj.foo[#19] -
  obj.bar[#20] --< P(baz) >--> obj.bar.baz[#21]
  obj.bar.baz[#21] -
  obj.10[#22] -
  obj.abc[#23] -
  obj.null[#24] -
  undef[#25] --< P(foo) >--> undef.foo[#26]
  undef.foo[#26] -

Graph.js MDG Builder: dynamic lookup
  $ graphjs mdg --no-export dynamic_lookup.js
  obj[#18] --< P(*) >--> obj.*[#20]
  foo[#19] --< D >--> obj.*[#20]
  obj.*[#20] --< P(*) >--> obj.*.*[#23]
  foo[#21] --< D >--> obj.*[#20]
  bar[#22] --< D >--> obj.*.*[#23]
  obj.*.*[#23] -
  $v4[#24] --< D >--> obj.*[#20]
  10[#25] --< D >--> $v6[#27]
  "abc"[#26] --< D >--> $v6[#27]
  $v6[#27] --< D >--> obj.*[#20]
  bar[#28] --< D >--> obj.*[#20]
  $v9[#29] --< D >--> obj.*.*[#23]
  undef[#30] --< P(*) >--> undef.*[#32]
  bar[#31] --< D >--> undef.*[#32]
  undef.*[#32] -

Graph.js MDG Builder: static update
  $ graphjs mdg --no-export static_update.js
  obj[#18] --< V(foo) >--> obj[#20]
  obj[#18] --< P(bar) >--> obj.bar[#23]
  10[#19] -
  obj[#20] --< P(foo) >--> 10[#19]
  obj[#20] --< V(bar) >--> obj[#22]
  $v1[#21] --< V(baz) >--> $v1[#25]
  obj[#22] --< P(bar) >--> $v1[#21]
  obj[#22] --< V(10) >--> obj[#27]
  obj.bar[#23] -
  10[#24] -
  $v1[#25] --< P(baz) >--> 10[#24]
  10[#26] -
  obj[#27] --< P(10) >--> 10[#26]
  obj[#27] --< V(abc) >--> obj[#29]
  10[#28] -
  obj[#29] --< P(abc) >--> 10[#28]
  obj[#29] --< V(null) >--> obj[#31]
  10[#30] -
  obj[#31] --< P(null) >--> 10[#30]
  undef[#32] --< V(foo) >--> undef[#34]
  10[#33] -
  undef[#34] --< P(foo) >--> 10[#33]

Graph.js MDG Builder: dynamic update
  $ graphjs mdg --no-export dynamic_update.js
  obj[#18] --< V(*) >--> obj[#21]
  obj[#18] --< P(*) >--> obj.*[#26]
  foo[#19] --< D >--> obj[#21]
  10[#20] --< V(*) >--> $v2[#29]
  obj[#21] --< P(*) >--> 10[#20]
  obj[#21] --< V(*) >--> obj[#24]
  $v1[#22] --< V(*) >--> $v2[#29]
  bar[#23] --< D >--> obj[#24]
  obj[#24] --< P(*) >--> $v1[#22]
  obj[#24] --< V(*) >--> obj[#32]
  foo[#25] --< D >--> obj.*[#26]
  obj.*[#26] --< V(*) >--> $v2[#29]
  bar[#27] --< D >--> $v2[#29]
  10[#28] -
  $v2[#29] --< P(*) >--> 10[#28]
  $v2[#29] --< V(*) >--> $v5[#41]
  $v3[#30] --< D >--> obj[#32]
  10[#31] --< V(*) >--> $v5[#41]
  obj[#32] --< P(*) >--> 10[#31]
  obj[#32] --< V(*) >--> obj[#37]
  10[#33] --< D >--> $v4[#35]
  "abc"[#34] --< D >--> $v4[#35]
  $v4[#35] --< D >--> obj[#37]
  true[#36] --< V(*) >--> $v5[#41]
  obj[#37] --< P(*) >--> true[#36]
  baz[#38] --< D >--> obj.*[#26]
  $v6[#39] --< D >--> $v5[#41]
  10[#40] -
  $v5[#41] --< P(*) >--> 10[#40]
  undef[#42] --< V(*) >--> undef[#45]
  foo[#43] --< D >--> undef[#45]
  10[#44] -
  undef[#45] --< P(*) >--> 10[#44]

Graph.js MDG Builder: static access
  $ graphjs mdg --no-export static_access.js
  obj[#18] --< V(foo) >--> obj[#20]
  obj[#18] --< P(baz) >--> obj.baz[#23]
  obj[#18] --< P(foo) >--> obj.foo[#26]
  obj[#18] --< P(bar) >--> obj.bar[#28]
  10[#19] -
  obj[#20] --< P(foo) >--> 10[#19]
  obj[#20] --< V(bar) >--> obj[#22]
  $v1[#21] -
  obj[#22] --< P(bar) >--> $v1[#21]
  obj[#22] --< V(qux) >--> obj[#27]
  obj.baz[#23] --< V(p) >--> obj.baz[#25]
  10[#24] -
  obj.baz[#25] --< P(p) >--> 10[#24]
  obj.foo[#26] -
  obj[#27] --< P(qux) >--> 10[#19]
  obj[#27] --< V(qux) >--> obj[#29]
  obj.bar[#28] -
  obj[#29] --< P(qux) >--> $v1[#21]

Graph.js MDG Builder: dynamic access
  $ graphjs mdg --no-export dynamic_access.js
  obj[#18] --< V(*) >--> obj[#21]
  obj[#18] --< P(*) >--> obj.*[#26]
  foo[#19] --< D >--> obj[#21]
  10[#20] --< V(*) >--> $v2[#29]
  obj[#21] --< P(*) >--> 10[#20]
  obj[#21] --< V(*) >--> obj[#24]
  $v1[#22] --< V(*) >--> $v2[#29]
  bar[#23] --< D >--> obj[#24]
  obj[#24] --< P(*) >--> $v1[#22]
  obj[#24] --< V(*) >--> obj[#32]
  baz[#25] --< D >--> obj.*[#26]
  obj.*[#26] --< V(*) >--> $v2[#29]
  p[#27] --< D >--> $v2[#29]
  10[#28] -
  $v2[#29] --< P(*) >--> 10[#28]
  foo[#30] --< D >--> obj.*[#26]
  qux[#31] --< D >--> obj[#32]
  obj[#32] --< P(*) >--> $v2[#29]
  obj[#32] --< V(*) >--> obj[#35]
  bar[#33] --< D >--> obj.*[#26]
  qux[#34] --< D >--> obj[#35]
  obj[#35] --< P(*) >--> $v2[#29]

Graph.js MDG Builder: static method
  $ graphjs mdg --no-export static_method.js
  [[function]] foo[#18] -
  [[function]] bar[#19] -
  obj[#20] --< V(foo) >--> obj[#21]
  obj[#20] --< P(foo) >--> obj.foo[#24]
  obj[#20] --< P(bar) >--> obj.bar[#30]
  obj[#20] --< P(baz) >--> obj.baz[#36]
  obj[#21] --< P(foo) >--> [[function]] foo[#18]
  obj[#21] --< V(bar) >--> obj[#22]
  obj[#22] --< P(bar) >--> [[function]] bar[#19]
  obj[#22] --< Arg(0) >--> obj.baz(...)[#37]
  10[#23] -
  obj.foo[#24] -
  foo[#25] --< V(x1) >--> foo[#26]
  foo[#26] --< P(x1) >--> 10[#23]
  10[#27] -
  "abc"[#28] -
  true[#29] -
  obj.bar[#30] -
  bar[#31] --< V(y1) >--> bar[#32]
  bar[#32] --< P(y1) >--> 10[#27]
  bar[#32] --< V(y2) >--> bar[#33]
  bar[#33] --< P(y2) >--> "abc"[#28]
  bar[#33] --< V(y3) >--> bar[#34]
  bar[#34] --< P(y3) >--> true[#29]
  10[#35] --< Arg(1) >--> obj.baz(...)[#37]
  obj.baz[#36] -
  obj.baz(...)[#37] --< Call >--> obj.baz[#36]
  obj.baz(...)[#37] --< D >--> $v3[#38]
  $v3[#38] -
  undef[#39] --< P(foo) >--> undef.foo[#40]
  undef.foo[#40] -

Graph.js MDG Builder: dynamic method
  $ graphjs mdg --no-export dynamic_method.js
  [[function]] foo[#18] --< D >--> obj.*[#24]
  [[function]] foo[#18] --< P(*) >--> $v7.*[#75]
  [[function]] foo[#18] --< Arg(0) >--> $v7.*(...)[#78]
  [[function]] bar[#19] --< D >--> obj.*[#24]
  [[function]] bar[#19] --< P(*) >--> $v7.*[#75]
  [[function]] bar[#19] --< Arg(0) >--> $v7.*(...)[#78]
  [[function]] bar[#19] --< D >--> undef.*[#81]
  obj[#20] --< V(foo) >--> obj[#21]
  obj[#20] --< P(*) >--> obj.*[#24]
  obj[#21] --< P(foo) >--> [[function]] foo[#18]
  obj[#21] --< V(bar) >--> obj[#22]
  obj[#22] --< P(bar) >--> [[function]] bar[#19]
  obj[#22] --< Arg(0) >--> obj.*(...)[#33]
  obj[#22] --< Arg(0) >--> obj.*(...)[#44]
  obj[#22] --< Arg(0) >--> obj.*(...)[#56]
  obj[#22] --< Arg(0) >--> obj.*(...)[#70]
  10[#23] --< Arg(1) >--> obj.*(...)[#33]
  obj.*[#24] --< P(*) >--> $v7.*[#75]
  obj.*[#24] --< Arg(0) >--> $v7.*(...)[#78]
  foo[#25] --< V(x1) >--> foo[#26]
  foo[#26] --< P(x1) >--> 10[#23]
  foo[#26] --< P(x1) >--> 10[#35]
  foo[#26] --< P(x1) >--> 10[#47]
  foo[#26] --< P(x1) >--> true[#61]
  bar[#27] --< V(y1) >--> bar[#28]
  bar[#28] --< P(y1) >--> 10[#23]
  bar[#28] --< V(y2) >--> bar[#30]
  bar[#28] --< P(y1) >--> 10[#35]
  bar[#28] --< P(y1) >--> 10[#47]
  bar[#28] --< P(y1) >--> true[#61]
  y2[#29] -
  bar[#30] --< P(y2) >--> y2[#29]
  bar[#30] --< V(y3) >--> bar[#32]
  bar[#30] --< P(y2) >--> "abc"[#36]
  y3[#31] -
  bar[#32] --< P(y3) >--> y3[#31]
  bar[#32] --< P(y3) >--> true[#37]
  obj.*(...)[#33] --< Call >--> obj.*[#24]
  obj.*(...)[#33] --< D >--> $v1[#34]
  $v1[#34] -
  10[#35] --< Arg(1) >--> obj.*(...)[#44]
  "abc"[#36] --< Arg(2) >--> obj.*(...)[#44]
  true[#37] --< Arg(3) >--> obj.*(...)[#44]
  obj.*(...)[#44] --< Call >--> obj.*[#24]
  obj.*(...)[#44] --< D >--> $v2[#45]
  $v2[#45] -
  $v3[#46] --< D >--> obj.*[#24]
  10[#47] --< Arg(1) >--> obj.*(...)[#56]
  obj.*(...)[#56] --< Call >--> obj.*[#24]
  obj.*(...)[#56] --< D >--> $v4[#57]
  $v4[#57] -
  10[#58] --< D >--> $v5[#60]
  "abc"[#59] --< D >--> $v5[#60]
  $v5[#60] --< D >--> obj.*[#24]
  true[#61] --< Arg(1) >--> obj.*(...)[#70]
  obj.*(...)[#70] --< Call >--> obj.*[#24]
  obj.*(...)[#70] --< D >--> $v6[#71]
  $v6[#71] -
  baz[#72] --< D >--> obj.*[#24]
  $v8[#73] --< D >--> $v7.*[#75]
  10[#74] --< Arg(1) >--> $v7.*(...)[#78]
  $v7.*[#75] -
  $v7.*(...)[#78] --< Call >--> $v7.*[#75]
  $v7.*(...)[#78] --< D >--> $v9[#79]
  $v9[#79] -
  undef[#80] --< P(*) >--> undef.*[#81]
  undef.*[#81] -
