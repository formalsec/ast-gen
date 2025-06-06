Graph.js MDG Builder: single-file require
  $ graphjs mdg --no-export main.js
  [[sink]] require[#4] -
  './foo.js'[#7] --< Arg(1) >--> require(...)[#8]
  require(...)[#8] --< Call >--> [[sink]] require[#4]
  require(...)[#8] --< D >--> foo[#9]
  foo[#9] -
  [[module]] foo[#10] --< P(obj) >--> foo.obj[#15]
  [[module]] foo[#10] --< P(foo) >--> foo.foo[#16]
  [[module]] foo[#10] --< Arg(0) >--> foo.foo(...)[#17]
  './deps/bar.js'[#11] --< Arg(1) >--> require(...)[#12]
  require(...)[#12] --< Call >--> [[sink]] require[#4]
  require(...)[#12] --< D >--> bar[#13]
  bar[#13] -
  [[module]] bar[#14] --< P(bar1) >--> bar.bar1[#19]
  [[module]] bar[#14] --< P(bar3) >--> bar.bar3[#24]
  [[module]] bar[#14] --< P(bar4) >--> bar.bar4[#30]
  [[module]] bar[#14] --< Arg(0) >--> bar.bar4(...)[#31]
  foo.obj[#15] --< Arg(1) >--> foo.foo(...)[#17]
  foo.foo[#16] -
  foo.foo(...)[#17] --< Call >--> foo.foo[#16]
  foo.foo(...)[#17] --< D >--> $v2[#18]
  $v2[#18] -
  bar.bar1[#19] --< P(p) >--> bar.bar1.p[#21]
  bar.bar1[#19] --< Arg(0) >--> bar.bar1.p(...)[#22]
  "abc"[#20] --< Arg(1) >--> bar.bar1.p(...)[#22]
  bar.bar1.p[#21] -
  bar.bar1.p(...)[#22] --< Call >--> bar.bar1.p[#21]
  bar.bar1.p(...)[#22] --< D >--> $v4[#23]
  $v4[#23] -
  bar.bar3[#24] --< P(p) >--> bar.bar3.p[#25]
  bar.bar3.p[#25] --< P(q) >--> bar.bar3.p.q[#27]
  bar.bar3.p[#25] --< Arg(0) >--> bar.bar3.p.q(...)[#28]
  "def"[#26] --< Arg(1) >--> bar.bar3.p.q(...)[#28]
  bar.bar3.p.q[#27] -
  bar.bar3.p.q(...)[#28] --< Call >--> bar.bar3.p.q[#27]
  bar.bar3.p.q(...)[#28] --< D >--> $v7[#29]
  $v7[#29] -
  bar.bar4[#30] -
  bar.bar4(...)[#31] --< Call >--> bar.bar4[#30]
  bar.bar4(...)[#31] --< D >--> $v8[#32]
  $v8[#32] -

Graph.js MDG Builder: multifile require
  $ graphjs mdg --no-export --multifile main.js
  [[sink]] require[#4] -
  './foo.js'[#7] --< Arg(1) >--> require(...)[#8]
  require(...)[#8] --< Call >--> [[sink]] require[#4]
  require(...)[#8] --< D >--> foo[#9]
  foo[#9] -
  [[module]] foo.js[#10] --< D >--> module[#11]
  module[#11] --< P(exports) >--> exports[#12]
  module[#11] --< V(exports) >--> module[#24]
  exports[#12] -
  obj[#13] --< V(foo) >--> obj[#15]
  10[#14] -
  obj[#15] --< P(foo) >--> 10[#14]
  obj[#15] --< Arg(1) >--> $v2.foo(...)[#74]
  [[function]] foo[#16] --< Param(0) >--> this[#17]
  [[function]] foo[#16] --< Param(1) >--> x[#18]
  this[#17] -
  x[#18] -
  $v1[#19] --< V(p) >--> $v1[#20]
  $v1[#20] --< P(p) >--> x[#18]
  $v2[#21] --< V(obj) >--> $v2[#22]
  $v2[#21] --< P(foo) >--> $v2.foo[#51]
  $v2[#21] --< P(obj) >--> $v2.obj[#73]
  $v2[#22] --< P(obj) >--> obj[#15]
  $v2[#22] --< V(foo) >--> $v2[#23]
  $v2[#23] --< P(foo) >--> [[function]] foo[#16]
  $v2[#23] --< Arg(0) >--> $v2.foo(...)[#52]
  $v2[#23] --< Arg(0) >--> $v2.foo(...)[#74]
  module[#24] --< P(exports) >--> $v2[#23]
  './deps/bar.js'[#25] --< Arg(1) >--> require(...)[#26]
  require(...)[#26] --< Call >--> [[sink]] require[#4]
  require(...)[#26] --< D >--> bar[#27]
  bar[#27] -
  [[module]] deps/bar.js[#28] --< D >--> module[#29]
  module[#29] --< P(exports) >--> exports[#30]
  exports[#30] --< V(bar1) >--> exports[#70]
  exports[#30] --< P(bar1) >--> exports.bar1[#76]
  exports[#30] --< P(bar3) >--> exports.bar3[#81]
  exports[#30] --< P(bar4) >--> exports.bar4[#87]
  "./baz"[#31] --< Arg(1) >--> require(...)[#32]
  require(...)[#32] --< Call >--> [[sink]] require[#4]
  require(...)[#32] --< D >--> baz[#33]
  baz[#33] -
  [[module]] deps/baz.js[#34] --< D >--> module[#35]
  module[#35] --< P(exports) >--> exports[#36]
  module[#35] --< V(exports) >--> module[#54]
  exports[#36] -
  'path'[#37] --< Arg(1) >--> require(...)[#38]
  require(...)[#38] --< Call >--> [[sink]] require[#4]
  require(...)[#38] --< D >--> npm[#39]
  npm[#39] -
  [[module]] path[#40] --< P(basename) >--> npm.basename[#42]
  [[module]] path[#40] --< Arg(0) >--> npm.basename(...)[#43]
  "abc"[#41] --< Arg(1) >--> npm.basename(...)[#43]
  npm.basename[#42] -
  npm.basename(...)[#43] --< Call >--> npm.basename[#42]
  npm.basename(...)[#43] --< D >--> $v3[#44]
  $v3[#44] -
  '../foo'[#45] --< Arg(1) >--> require(...)[#46]
  require(...)[#46] --< Call >--> [[sink]] require[#4]
  require(...)[#46] --< D >--> foo[#47]
  foo[#47] -
  [[function]] $v4[#48] --< Param(0) >--> this[#49]
  [[function]] $v4[#48] --< Param(1) >--> z[#50]
  this[#49] -
  z[#50] --< Arg(1) >--> $v2.foo(...)[#52]
  $v2.foo[#51] -
  $v2.foo(...)[#52] --< Call >--> [[function]] foo[#16]
  $v2.foo(...)[#52] --< D >--> $v5[#53]
  $v5[#53] -
  module[#54] --< P(exports) >--> [[function]] $v4[#48]
  bar1[#55] --< V(p) >--> bar1[#61]
  bar1[#55] --< P(p) >--> bar1.p[#78]
  [[function]] $v6[#56] --< Param(0) >--> this[#57]
  [[function]] $v6[#56] --< Param(1) >--> y[#58]
  this[#57] -
  y[#58] --< Arg(1) >--> baz(...)[#59]
  baz(...)[#59] --< Call >--> [[function]] $v4[#48]
  baz(...)[#59] --< D >--> $v7[#60]
  $v7[#60] -
  bar1[#61] --< P(p) >--> [[function]] $v6[#56]
  bar1[#61] --< Arg(0) >--> bar1.p(...)[#79]
  bar2[#62] --< V(p) >--> bar2[#65]
  [[function]] $v8[#63] --< Param(0) >--> this[#64]
  this[#64] -
  bar2[#65] --< P(p) >--> [[function]] $v8[#63]
  bar3[#66] --< V(p) >--> bar3[#69]
  bar3[#66] --< P(p) >--> bar3.p[#82]
  $v9[#67] --< V(q) >--> $v9[#68]
  $v9[#67] --< P(q) >--> $v9.q[#84]
  $v9[#68] --< P(q) >--> [[function]] $v4[#48]
  $v9[#68] --< Arg(0) >--> $v9.q(...)[#85]
  bar3[#69] --< P(p) >--> $v9[#68]
  exports[#70] --< P(bar1) >--> bar1[#61]
  exports[#70] --< V(bar2) >--> exports[#71]
  exports[#71] --< P(bar2) >--> bar2[#65]
  exports[#71] --< V(bar3) >--> exports[#72]
  exports[#72] --< P(bar3) >--> bar3[#69]
  exports[#72] --< Arg(0) >--> exports.bar4(...)[#88]
  $v2.obj[#73] -
  $v2.foo(...)[#74] --< Call >--> [[function]] foo[#16]
  $v2.foo(...)[#74] --< D >--> $v11[#75]
  $v11[#75] -
  exports.bar1[#76] -
  "abc"[#77] --< Arg(1) >--> bar1.p(...)[#79]
  bar1.p[#78] -
  bar1.p(...)[#79] --< Call >--> [[function]] $v6[#56]
  bar1.p(...)[#79] --< D >--> $v13[#80]
  $v13[#80] -
  exports.bar3[#81] -
  bar3.p[#82] -
  "def"[#83] --< Arg(1) >--> $v9.q(...)[#85]
  $v9.q[#84] -
  $v9.q(...)[#85] --< Call >--> [[function]] $v4[#48]
  $v9.q(...)[#85] --< D >--> $v16[#86]
  $v16[#86] -
  exports.bar4[#87] -
  exports.bar4(...)[#88] --< Call >--> exports.bar4[#87]
  exports.bar4(...)[#88] --< D >--> $v17[#89]
  $v17[#89] -
