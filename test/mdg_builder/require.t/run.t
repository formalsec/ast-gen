Graph.js MDG Builder: single-file require
  $ graphjs mdg --no-export main.js
  [[sink]] require[#3] -
  "./foo.js"[#19] --< Arg(1) >--> require(...)[#20]
  require(...)[#20] --< Call >--> [[sink]] require[#3]
  require(...)[#20] --< D >--> foo[#21]
  foo[#21] -
  [[module]] foo[#22] --< P(obj) >--> foo.obj[#27]
  [[module]] foo[#22] --< P(foo) >--> foo.foo[#28]
  [[module]] foo[#22] --< Arg(0) >--> foo.foo(...)[#29]
  "./deps/bar.js"[#23] --< Arg(1) >--> require(...)[#24]
  require(...)[#24] --< Call >--> [[sink]] require[#3]
  require(...)[#24] --< D >--> bar[#25]
  bar[#25] -
  [[module]] bar[#26] --< P(bar1) >--> bar.bar1[#31]
  [[module]] bar[#26] --< P(bar3) >--> bar.bar3[#36]
  [[module]] bar[#26] --< P(bar4) >--> bar.bar4[#42]
  [[module]] bar[#26] --< Arg(0) >--> bar.bar4(...)[#43]
  foo.obj[#27] --< Arg(1) >--> foo.foo(...)[#29]
  foo.foo[#28] -
  foo.foo(...)[#29] --< Call >--> foo.foo[#28]
  foo.foo(...)[#29] --< D >--> $v2[#30]
  $v2[#30] -
  bar.bar1[#31] --< P(p) >--> bar.bar1.p[#33]
  bar.bar1[#31] --< Arg(0) >--> bar.bar1.p(...)[#34]
  "abc"[#32] --< Arg(1) >--> bar.bar1.p(...)[#34]
  bar.bar1.p[#33] -
  bar.bar1.p(...)[#34] --< Call >--> bar.bar1.p[#33]
  bar.bar1.p(...)[#34] --< D >--> $v4[#35]
  $v4[#35] -
  bar.bar3[#36] --< P(p) >--> bar.bar3.p[#37]
  bar.bar3.p[#37] --< P(q) >--> bar.bar3.p.q[#39]
  bar.bar3.p[#37] --< Arg(0) >--> bar.bar3.p.q(...)[#40]
  "def"[#38] --< Arg(1) >--> bar.bar3.p.q(...)[#40]
  bar.bar3.p.q[#39] -
  bar.bar3.p.q(...)[#40] --< Call >--> bar.bar3.p.q[#39]
  bar.bar3.p.q(...)[#40] --< D >--> $v7[#41]
  $v7[#41] -
  bar.bar4[#42] -
  bar.bar4(...)[#43] --< Call >--> bar.bar4[#42]
  bar.bar4(...)[#43] --< D >--> $v8[#44]
  $v8[#44] -

Graph.js MDG Builder: multifile require
  $ graphjs mdg --no-export --multifile main.js
  [[sink]] require[#3] -
  "./foo.js"[#19] --< Arg(1) >--> require(...)[#20]
  require(...)[#20] --< Call >--> [[sink]] require[#3]
  require(...)[#20] --< D >--> foo[#21]
  foo[#21] -
  [[module]] foo.js[#22] --< D >--> module[#23]
  module[#23] --< P(exports) >--> exports[#24]
  module[#23] --< V(exports) >--> module[#32]
  exports[#24] -
  obj[#25] --< V(foo) >--> obj[#27]
  10[#26] -
  obj[#27] --< P(foo) >--> 10[#26]
  [[function]] foo[#28] -
  $v2[#29] --< V(obj) >--> $v2[#30]
  $v2[#29] --< P(obj) >--> $v2.obj[#71]
  $v2[#29] --< P(foo) >--> $v2.foo[#72]
  $v2[#30] --< P(obj) >--> obj[#27]
  $v2[#30] --< V(foo) >--> $v2[#31]
  $v2[#31] --< P(foo) >--> [[function]] foo[#28]
  module[#32] --< P(exports) >--> $v2[#31]
  "./deps/bar.js"[#33] --< Arg(1) >--> require(...)[#34]
  require(...)[#34] --< Call >--> [[sink]] require[#3]
  require(...)[#34] --< D >--> bar[#35]
  bar[#35] -
  [[module]] deps/bar.js[#36] --< D >--> module[#37]
  module[#37] --< P(exports) >--> exports[#38]
  exports[#38] --< V(bar1) >--> exports[#68]
  exports[#38] --< P(bar1) >--> exports.bar1[#75]
  exports[#38] --< P(bar3) >--> exports.bar3[#81]
  exports[#38] --< P(bar4) >--> exports.bar4[#87]
  "./baz"[#39] --< Arg(1) >--> require(...)[#40]
  require(...)[#40] --< Call >--> [[sink]] require[#3]
  require(...)[#40] --< D >--> baz[#41]
  baz[#41] -
  [[module]] deps/baz.js[#42] --< D >--> module[#43]
  module[#43] --< P(exports) >--> exports[#44]
  module[#43] --< V(exports) >--> module[#57]
  exports[#44] -
  "path"[#45] --< Arg(1) >--> require(...)[#46]
  require(...)[#46] --< Call >--> [[sink]] require[#3]
  require(...)[#46] --< D >--> npm[#47]
  npm[#47] -
  [[module]] path[#48] --< P(basename) >--> path.basename[#50]
  [[module]] path[#48] --< Arg(0) >--> path.basename(...)[#51]
  "abc"[#49] --< Arg(1) >--> path.basename(...)[#51]
  path.basename[#50] -
  path.basename(...)[#51] --< Call >--> path.basename[#50]
  path.basename(...)[#51] --< D >--> $v3[#52]
  $v3[#52] -
  "../foo"[#53] --< Arg(1) >--> require(...)[#54]
  require(...)[#54] --< Call >--> [[sink]] require[#3]
  require(...)[#54] --< D >--> foo[#55]
  foo[#55] -
  [[function]] $v4[#56] -
  module[#57] --< P(exports) >--> [[function]] $v4[#56]
  bar1[#58] --< V(p) >--> bar1[#60]
  bar1[#58] --< P(p) >--> bar1.p[#77]
  [[function]] $v6[#59] -
  bar1[#60] --< P(p) >--> [[function]] $v6[#59]
  bar2[#61] --< V(p) >--> bar2[#63]
  [[function]] $v8[#62] -
  bar2[#63] --< P(p) >--> [[function]] $v8[#62]
  bar3[#64] --< V(p) >--> bar3[#67]
  bar3[#64] --< P(p) >--> bar3.p[#82]
  $v9[#65] --< V(q) >--> $v9[#66]
  $v9[#65] --< P(q) >--> $v9.q[#84]
  $v9[#66] --< P(q) >--> [[function]] $v4[#56]
  bar3[#67] --< P(p) >--> $v9[#66]
  exports[#68] --< P(bar1) >--> bar1[#60]
  exports[#68] --< V(bar2) >--> exports[#69]
  exports[#69] --< P(bar2) >--> bar2[#63]
  exports[#69] --< V(bar3) >--> exports[#70]
  exports[#70] --< P(bar3) >--> bar3[#67]
  exports[#70] --< Arg(0) >--> exports.bar4(...)[#88]
  $v2.obj[#71] -
  $v2.foo[#72] -
  $v1[#73] --< V(p) >--> $v1[#74]
  $v1[#74] --< P(p) >--> obj[#27]
  $v1[#74] --< P(p) >--> "abc"[#76]
  $v1[#74] --< P(p) >--> "def"[#83]
  exports.bar1[#75] -
  "abc"[#76] -
  bar1.p[#77] -
  exports.bar3[#81] -
  bar3.p[#82] -
  "def"[#83] -
  $v9.q[#84] -
  exports.bar4[#87] -
  exports.bar4(...)[#88] --< Call >--> exports.bar4[#87]
  exports.bar4(...)[#88] --< D >--> $v17[#89]
  $v17[#89] -
