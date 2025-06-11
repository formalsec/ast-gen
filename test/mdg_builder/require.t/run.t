Graph.js MDG Builder: single-file require
  $ graphjs mdg --no-export main.js
  [[sink]] require[#3] -
  [[function]] defineProperty[#5] -
  './foo.js'[#17] --< Arg(1) >--> require(...)[#18]
  require(...)[#18] --< Call >--> [[sink]] require[#3]
  require(...)[#18] --< D >--> foo[#19]
  foo[#19] -
  [[module]] foo[#20] --< P(obj) >--> foo.obj[#25]
  [[module]] foo[#20] --< P(foo) >--> foo.foo[#26]
  [[module]] foo[#20] --< Arg(0) >--> foo.foo(...)[#27]
  './deps/bar.js'[#21] --< Arg(1) >--> require(...)[#22]
  require(...)[#22] --< Call >--> [[sink]] require[#3]
  require(...)[#22] --< D >--> bar[#23]
  bar[#23] -
  [[module]] bar[#24] --< P(bar1) >--> bar.bar1[#29]
  [[module]] bar[#24] --< P(bar3) >--> bar.bar3[#34]
  [[module]] bar[#24] --< P(bar4) >--> bar.bar4[#40]
  [[module]] bar[#24] --< Arg(0) >--> bar.bar4(...)[#41]
  foo.obj[#25] --< Arg(1) >--> foo.foo(...)[#27]
  foo.foo[#26] -
  foo.foo(...)[#27] --< Call >--> foo.foo[#26]
  foo.foo(...)[#27] --< D >--> $v2[#28]
  $v2[#28] -
  bar.bar1[#29] --< P(p) >--> bar.bar1.p[#31]
  bar.bar1[#29] --< Arg(0) >--> bar.bar1.p(...)[#32]
  "abc"[#30] --< Arg(1) >--> bar.bar1.p(...)[#32]
  bar.bar1.p[#31] -
  bar.bar1.p(...)[#32] --< Call >--> bar.bar1.p[#31]
  bar.bar1.p(...)[#32] --< D >--> $v4[#33]
  $v4[#33] -
  bar.bar3[#34] --< P(p) >--> bar.bar3.p[#35]
  bar.bar3.p[#35] --< P(q) >--> bar.bar3.p.q[#37]
  bar.bar3.p[#35] --< Arg(0) >--> bar.bar3.p.q(...)[#38]
  "def"[#36] --< Arg(1) >--> bar.bar3.p.q(...)[#38]
  bar.bar3.p.q[#37] -
  bar.bar3.p.q(...)[#38] --< Call >--> bar.bar3.p.q[#37]
  bar.bar3.p.q(...)[#38] --< D >--> $v7[#39]
  $v7[#39] -
  bar.bar4[#40] -
  bar.bar4(...)[#41] --< Call >--> bar.bar4[#40]
  bar.bar4(...)[#41] --< D >--> $v8[#42]
  $v8[#42] -

Graph.js MDG Builder: multifile require
  $ graphjs mdg --no-export --multifile main.js
  [[sink]] require[#3] -
  [[function]] defineProperty[#5] -
  './foo.js'[#17] --< Arg(1) >--> require(...)[#18]
  require(...)[#18] --< Call >--> [[sink]] require[#3]
  require(...)[#18] --< D >--> foo[#19]
  foo[#19] -
  [[module]] foo.js[#20] --< D >--> module[#21]
  module[#21] --< P(exports) >--> exports[#22]
  module[#21] --< V(exports) >--> module[#34]
  exports[#22] -
  obj[#23] --< V(foo) >--> obj[#25]
  10[#24] -
  obj[#25] --< P(foo) >--> 10[#24]
  obj[#25] --< Arg(1) >--> $v2.foo(...)[#84]
  [[function]] foo[#26] --< Param(0) >--> this[#27]
  [[function]] foo[#26] --< Param(1) >--> x[#28]
  this[#27] -
  x[#28] -
  $v1[#29] --< V(p) >--> $v1[#30]
  $v1[#30] --< P(p) >--> x[#28]
  $v2[#31] --< V(obj) >--> $v2[#32]
  $v2[#31] --< P(foo) >--> $v2.foo[#61]
  $v2[#31] --< P(obj) >--> $v2.obj[#83]
  $v2[#32] --< P(obj) >--> obj[#25]
  $v2[#32] --< V(foo) >--> $v2[#33]
  $v2[#33] --< P(foo) >--> [[function]] foo[#26]
  $v2[#33] --< Arg(0) >--> $v2.foo(...)[#62]
  $v2[#33] --< Arg(0) >--> $v2.foo(...)[#84]
  module[#34] --< P(exports) >--> $v2[#33]
  './deps/bar.js'[#35] --< Arg(1) >--> require(...)[#36]
  require(...)[#36] --< Call >--> [[sink]] require[#3]
  require(...)[#36] --< D >--> bar[#37]
  bar[#37] -
  [[module]] deps/bar.js[#38] --< D >--> module[#39]
  module[#39] --< P(exports) >--> exports[#40]
  exports[#40] --< V(bar1) >--> exports[#80]
  exports[#40] --< P(bar1) >--> exports.bar1[#86]
  exports[#40] --< P(bar3) >--> exports.bar3[#91]
  exports[#40] --< P(bar4) >--> exports.bar4[#97]
  "./baz"[#41] --< Arg(1) >--> require(...)[#42]
  require(...)[#42] --< Call >--> [[sink]] require[#3]
  require(...)[#42] --< D >--> baz[#43]
  baz[#43] -
  [[module]] deps/baz.js[#44] --< D >--> module[#45]
  module[#45] --< P(exports) >--> exports[#46]
  module[#45] --< V(exports) >--> module[#64]
  exports[#46] -
  'path'[#47] --< Arg(1) >--> require(...)[#48]
  require(...)[#48] --< Call >--> [[sink]] require[#3]
  require(...)[#48] --< D >--> npm[#49]
  npm[#49] -
  [[module]] path[#50] --< P(basename) >--> path.basename[#52]
  [[module]] path[#50] --< Arg(0) >--> path.basename(...)[#53]
  "abc"[#51] --< Arg(1) >--> path.basename(...)[#53]
  path.basename[#52] -
  path.basename(...)[#53] --< Call >--> path.basename[#52]
  path.basename(...)[#53] --< D >--> $v3[#54]
  $v3[#54] -
  '../foo'[#55] --< Arg(1) >--> require(...)[#56]
  require(...)[#56] --< Call >--> [[sink]] require[#3]
  require(...)[#56] --< D >--> foo[#57]
  foo[#57] -
  [[function]] $v4[#58] --< Param(0) >--> this[#59]
  [[function]] $v4[#58] --< Param(1) >--> z[#60]
  this[#59] -
  z[#60] --< Arg(1) >--> $v2.foo(...)[#62]
  $v2.foo[#61] -
  $v2.foo(...)[#62] --< Call >--> [[function]] foo[#26]
  $v2.foo(...)[#62] --< D >--> $v5[#63]
  $v5[#63] -
  module[#64] --< P(exports) >--> [[function]] $v4[#58]
  bar1[#65] --< V(p) >--> bar1[#71]
  bar1[#65] --< P(p) >--> bar1.p[#88]
  [[function]] $v6[#66] --< Param(0) >--> this[#67]
  [[function]] $v6[#66] --< Param(1) >--> y[#68]
  this[#67] -
  y[#68] --< Arg(1) >--> baz(...)[#69]
  baz(...)[#69] --< Call >--> [[function]] $v4[#58]
  baz(...)[#69] --< D >--> $v7[#70]
  $v7[#70] -
  bar1[#71] --< P(p) >--> [[function]] $v6[#66]
  bar1[#71] --< Arg(0) >--> bar1.p(...)[#89]
  bar2[#72] --< V(p) >--> bar2[#75]
  [[function]] $v8[#73] --< Param(0) >--> this[#74]
  this[#74] -
  bar2[#75] --< P(p) >--> [[function]] $v8[#73]
  bar3[#76] --< V(p) >--> bar3[#79]
  bar3[#76] --< P(p) >--> bar3.p[#92]
  $v9[#77] --< V(q) >--> $v9[#78]
  $v9[#77] --< P(q) >--> $v9.q[#94]
  $v9[#78] --< P(q) >--> [[function]] $v4[#58]
  $v9[#78] --< Arg(0) >--> $v9.q(...)[#95]
  bar3[#79] --< P(p) >--> $v9[#78]
  exports[#80] --< P(bar1) >--> bar1[#71]
  exports[#80] --< V(bar2) >--> exports[#81]
  exports[#81] --< P(bar2) >--> bar2[#75]
  exports[#81] --< V(bar3) >--> exports[#82]
  exports[#82] --< P(bar3) >--> bar3[#79]
  exports[#82] --< Arg(0) >--> exports.bar4(...)[#98]
  $v2.obj[#83] -
  $v2.foo(...)[#84] --< Call >--> [[function]] foo[#26]
  $v2.foo(...)[#84] --< D >--> $v11[#85]
  $v11[#85] -
  exports.bar1[#86] -
  "abc"[#87] --< Arg(1) >--> bar1.p(...)[#89]
  bar1.p[#88] -
  bar1.p(...)[#89] --< Call >--> [[function]] $v6[#66]
  bar1.p(...)[#89] --< D >--> $v13[#90]
  $v13[#90] -
  exports.bar3[#91] -
  bar3.p[#92] -
  "def"[#93] --< Arg(1) >--> $v9.q(...)[#95]
  $v9.q[#94] -
  $v9.q(...)[#95] --< Call >--> [[function]] $v4[#58]
  $v9.q(...)[#95] --< D >--> $v16[#96]
  $v16[#96] -
  exports.bar4[#97] -
  exports.bar4(...)[#98] --< Call >--> exports.bar4[#97]
  exports.bar4(...)[#98] --< D >--> $v17[#99]
  $v17[#99] -
