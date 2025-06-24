Graph.js MDG Builder: single-file require
  $ graphjs mdg --no-export main.js
  [[sink]] require[#3] -
  "./foo.js"[#18] --< Arg(1) >--> require(...)[#19]
  require(...)[#19] --< Call >--> [[sink]] require[#3]
  require(...)[#19] --< D >--> foo[#20]
  foo[#20] -
  [[module]] foo[#21] --< P(obj) >--> foo.obj[#26]
  [[module]] foo[#21] --< P(foo) >--> foo.foo[#27]
  [[module]] foo[#21] --< Arg(0) >--> foo.foo(...)[#28]
  "./deps/bar.js"[#22] --< Arg(1) >--> require(...)[#23]
  require(...)[#23] --< Call >--> [[sink]] require[#3]
  require(...)[#23] --< D >--> bar[#24]
  bar[#24] -
  [[module]] bar[#25] --< P(bar1) >--> bar.bar1[#30]
  [[module]] bar[#25] --< P(bar3) >--> bar.bar3[#35]
  [[module]] bar[#25] --< P(bar4) >--> bar.bar4[#41]
  [[module]] bar[#25] --< Arg(0) >--> bar.bar4(...)[#42]
  foo.obj[#26] --< Arg(1) >--> foo.foo(...)[#28]
  foo.foo[#27] -
  foo.foo(...)[#28] --< Call >--> foo.foo[#27]
  foo.foo(...)[#28] --< D >--> $v2[#29]
  $v2[#29] -
  bar.bar1[#30] --< P(p) >--> bar.bar1.p[#32]
  bar.bar1[#30] --< Arg(0) >--> bar.bar1.p(...)[#33]
  "abc"[#31] --< Arg(1) >--> bar.bar1.p(...)[#33]
  bar.bar1.p[#32] -
  bar.bar1.p(...)[#33] --< Call >--> bar.bar1.p[#32]
  bar.bar1.p(...)[#33] --< D >--> $v4[#34]
  $v4[#34] -
  bar.bar3[#35] --< P(p) >--> bar.bar3.p[#36]
  bar.bar3.p[#36] --< P(q) >--> bar.bar3.p.q[#38]
  bar.bar3.p[#36] --< Arg(0) >--> bar.bar3.p.q(...)[#39]
  "def"[#37] --< Arg(1) >--> bar.bar3.p.q(...)[#39]
  bar.bar3.p.q[#38] -
  bar.bar3.p.q(...)[#39] --< Call >--> bar.bar3.p.q[#38]
  bar.bar3.p.q(...)[#39] --< D >--> $v7[#40]
  $v7[#40] -
  bar.bar4[#41] -
  bar.bar4(...)[#42] --< Call >--> bar.bar4[#41]
  bar.bar4(...)[#42] --< D >--> $v8[#43]
  $v8[#43] -

Graph.js MDG Builder: multifile require
  $ graphjs mdg --no-export --multifile main.js
  [[sink]] require[#3] -
  "./foo.js"[#18] --< Arg(1) >--> require(...)[#19]
  require(...)[#19] --< Call >--> [[sink]] require[#3]
  require(...)[#19] --< D >--> foo[#20]
  foo[#20] -
  [[module]] foo.js[#21] --< D >--> module[#22]
  module[#22] --< P(exports) >--> exports[#23]
  module[#22] --< V(exports) >--> module[#31]
  exports[#23] -
  obj[#24] --< V(foo) >--> obj[#26]
  10[#25] -
  obj[#26] --< P(foo) >--> 10[#25]
  [[function]] foo[#27] -
  $v2[#28] --< V(obj) >--> $v2[#29]
  $v2[#28] --< P(obj) >--> $v2.obj[#70]
  $v2[#28] --< P(foo) >--> $v2.foo[#71]
  $v2[#29] --< P(obj) >--> obj[#26]
  $v2[#29] --< V(foo) >--> $v2[#30]
  $v2[#30] --< P(foo) >--> [[function]] foo[#27]
  module[#31] --< P(exports) >--> $v2[#30]
  "./deps/bar.js"[#32] --< Arg(1) >--> require(...)[#33]
  require(...)[#33] --< Call >--> [[sink]] require[#3]
  require(...)[#33] --< D >--> bar[#34]
  bar[#34] -
  [[module]] deps/bar.js[#35] --< D >--> module[#36]
  module[#36] --< P(exports) >--> exports[#37]
  exports[#37] --< V(bar1) >--> exports[#67]
  exports[#37] --< P(bar1) >--> exports.bar1[#74]
  exports[#37] --< P(bar3) >--> exports.bar3[#80]
  exports[#37] --< P(bar4) >--> exports.bar4[#86]
  "./baz"[#38] --< Arg(1) >--> require(...)[#39]
  require(...)[#39] --< Call >--> [[sink]] require[#3]
  require(...)[#39] --< D >--> baz[#40]
  baz[#40] -
  [[module]] deps/baz.js[#41] --< D >--> module[#42]
  module[#42] --< P(exports) >--> exports[#43]
  module[#42] --< V(exports) >--> module[#56]
  exports[#43] -
  "path"[#44] --< Arg(1) >--> require(...)[#45]
  require(...)[#45] --< Call >--> [[sink]] require[#3]
  require(...)[#45] --< D >--> npm[#46]
  npm[#46] -
  [[module]] path[#47] --< P(basename) >--> path.basename[#49]
  [[module]] path[#47] --< Arg(0) >--> path.basename(...)[#50]
  "abc"[#48] --< Arg(1) >--> path.basename(...)[#50]
  path.basename[#49] -
  path.basename(...)[#50] --< Call >--> path.basename[#49]
  path.basename(...)[#50] --< D >--> $v3[#51]
  $v3[#51] -
  "../foo"[#52] --< Arg(1) >--> require(...)[#53]
  require(...)[#53] --< Call >--> [[sink]] require[#3]
  require(...)[#53] --< D >--> foo[#54]
  foo[#54] -
  [[function]] $v4[#55] -
  module[#56] --< P(exports) >--> [[function]] $v4[#55]
  bar1[#57] --< V(p) >--> bar1[#59]
  bar1[#57] --< P(p) >--> bar1.p[#76]
  [[function]] $v6[#58] -
  bar1[#59] --< P(p) >--> [[function]] $v6[#58]
  bar2[#60] --< V(p) >--> bar2[#62]
  [[function]] $v8[#61] -
  bar2[#62] --< P(p) >--> [[function]] $v8[#61]
  bar3[#63] --< V(p) >--> bar3[#66]
  bar3[#63] --< P(p) >--> bar3.p[#81]
  $v9[#64] --< V(q) >--> $v9[#65]
  $v9[#64] --< P(q) >--> $v9.q[#83]
  $v9[#65] --< P(q) >--> [[function]] $v4[#55]
  bar3[#66] --< P(p) >--> $v9[#65]
  exports[#67] --< P(bar1) >--> bar1[#59]
  exports[#67] --< V(bar2) >--> exports[#68]
  exports[#68] --< P(bar2) >--> bar2[#62]
  exports[#68] --< V(bar3) >--> exports[#69]
  exports[#69] --< P(bar3) >--> bar3[#66]
  exports[#69] --< Arg(0) >--> exports.bar4(...)[#87]
  $v2.obj[#70] -
  $v2.foo[#71] -
  $v1[#72] --< V(p) >--> $v1[#73]
  $v1[#73] --< P(p) >--> obj[#26]
  $v1[#73] --< P(p) >--> "abc"[#75]
  $v1[#73] --< P(p) >--> "def"[#82]
  exports.bar1[#74] -
  "abc"[#75] -
  bar1.p[#76] -
  exports.bar3[#80] -
  bar3.p[#81] -
  "def"[#82] -
  $v9.q[#83] -
  exports.bar4[#86] -
  exports.bar4(...)[#87] --< Call >--> exports.bar4[#86]
  exports.bar4(...)[#87] --< D >--> $v17[#88]
  $v17[#88] -
