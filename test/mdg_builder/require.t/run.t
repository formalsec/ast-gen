Graph.js MDG Builder: single-file require
  $ graphjs mdg --no-export main.js
  [[sink]] require[#3] -
  './foo.js'[#9] --< Arg(1) >--> require(...)[#10]
  require(...)[#10] --< Call >--> [[sink]] require[#3]
  require(...)[#10] --< D >--> foo[#11]
  foo[#11] -
  [[module]] foo[#12] --< P(obj) >--> foo.obj[#17]
  [[module]] foo[#12] --< P(foo) >--> foo.foo[#18]
  [[module]] foo[#12] --< Arg(0) >--> foo.foo(...)[#19]
  './deps/bar.js'[#13] --< Arg(1) >--> require(...)[#14]
  require(...)[#14] --< Call >--> [[sink]] require[#3]
  require(...)[#14] --< D >--> bar[#15]
  bar[#15] -
  [[module]] bar[#16] --< P(bar1) >--> bar.bar1[#21]
  [[module]] bar[#16] --< P(bar3) >--> bar.bar3[#26]
  [[module]] bar[#16] --< P(bar4) >--> bar.bar4[#32]
  [[module]] bar[#16] --< Arg(0) >--> bar.bar4(...)[#33]
  foo.obj[#17] --< Arg(1) >--> foo.foo(...)[#19]
  foo.foo[#18] -
  foo.foo(...)[#19] --< Call >--> foo.foo[#18]
  foo.foo(...)[#19] --< D >--> $v2[#20]
  $v2[#20] -
  bar.bar1[#21] --< P(p) >--> bar.bar1.p[#23]
  bar.bar1[#21] --< Arg(0) >--> bar.bar1.p(...)[#24]
  "abc"[#22] --< Arg(1) >--> bar.bar1.p(...)[#24]
  bar.bar1.p[#23] -
  bar.bar1.p(...)[#24] --< Call >--> bar.bar1.p[#23]
  bar.bar1.p(...)[#24] --< D >--> $v4[#25]
  $v4[#25] -
  bar.bar3[#26] --< P(p) >--> bar.bar3.p[#27]
  bar.bar3.p[#27] --< P(q) >--> bar.bar3.p.q[#29]
  bar.bar3.p[#27] --< Arg(0) >--> bar.bar3.p.q(...)[#30]
  "def"[#28] --< Arg(1) >--> bar.bar3.p.q(...)[#30]
  bar.bar3.p.q[#29] -
  bar.bar3.p.q(...)[#30] --< Call >--> bar.bar3.p.q[#29]
  bar.bar3.p.q(...)[#30] --< D >--> $v7[#31]
  $v7[#31] -
  bar.bar4[#32] -
  bar.bar4(...)[#33] --< Call >--> bar.bar4[#32]
  bar.bar4(...)[#33] --< D >--> $v8[#34]
  $v8[#34] -

Graph.js MDG Builder: multifile require
  $ graphjs mdg --no-export --multifile main.js
  [[sink]] require[#3] -
  './foo.js'[#9] --< Arg(1) >--> require(...)[#10]
  require(...)[#10] --< Call >--> [[sink]] require[#3]
  require(...)[#10] --< D >--> foo[#11]
  foo[#11] -
  [[module]] foo.js[#12] --< D >--> module[#13]
  module[#13] --< P(exports) >--> exports[#14]
  module[#13] --< V(exports) >--> module[#26]
  exports[#14] -
  obj[#15] --< V(foo) >--> obj[#17]
  10[#16] -
  obj[#17] --< P(foo) >--> 10[#16]
  obj[#17] --< Arg(1) >--> $v2.foo(...)[#76]
  [[function]] foo[#18] --< Param(0) >--> this[#19]
  [[function]] foo[#18] --< Param(1) >--> x[#20]
  this[#19] -
  x[#20] -
  $v1[#21] --< V(p) >--> $v1[#22]
  $v1[#22] --< P(p) >--> x[#20]
  $v2[#23] --< V(obj) >--> $v2[#24]
  $v2[#23] --< P(foo) >--> $v2.foo[#53]
  $v2[#23] --< P(obj) >--> $v2.obj[#75]
  $v2[#24] --< P(obj) >--> obj[#17]
  $v2[#24] --< V(foo) >--> $v2[#25]
  $v2[#25] --< P(foo) >--> [[function]] foo[#18]
  $v2[#25] --< Arg(0) >--> $v2.foo(...)[#54]
  $v2[#25] --< Arg(0) >--> $v2.foo(...)[#76]
  module[#26] --< P(exports) >--> $v2[#25]
  './deps/bar.js'[#27] --< Arg(1) >--> require(...)[#28]
  require(...)[#28] --< Call >--> [[sink]] require[#3]
  require(...)[#28] --< D >--> bar[#29]
  bar[#29] -
  [[module]] deps/bar.js[#30] --< D >--> module[#31]
  module[#31] --< P(exports) >--> exports[#32]
  exports[#32] --< V(bar1) >--> exports[#72]
  exports[#32] --< P(bar1) >--> exports.bar1[#78]
  exports[#32] --< P(bar3) >--> exports.bar3[#83]
  exports[#32] --< P(bar4) >--> exports.bar4[#89]
  "./baz"[#33] --< Arg(1) >--> require(...)[#34]
  require(...)[#34] --< Call >--> [[sink]] require[#3]
  require(...)[#34] --< D >--> baz[#35]
  baz[#35] -
  [[module]] deps/baz.js[#36] --< D >--> module[#37]
  module[#37] --< P(exports) >--> exports[#38]
  module[#37] --< V(exports) >--> module[#56]
  exports[#38] -
  'path'[#39] --< Arg(1) >--> require(...)[#40]
  require(...)[#40] --< Call >--> [[sink]] require[#3]
  require(...)[#40] --< D >--> npm[#41]
  npm[#41] -
  [[module]] path[#42] --< P(basename) >--> npm.basename[#44]
  [[module]] path[#42] --< Arg(0) >--> npm.basename(...)[#45]
  "abc"[#43] --< Arg(1) >--> npm.basename(...)[#45]
  npm.basename[#44] -
  npm.basename(...)[#45] --< Call >--> npm.basename[#44]
  npm.basename(...)[#45] --< D >--> $v3[#46]
  $v3[#46] -
  '../foo'[#47] --< Arg(1) >--> require(...)[#48]
  require(...)[#48] --< Call >--> [[sink]] require[#3]
  require(...)[#48] --< D >--> foo[#49]
  foo[#49] -
  [[function]] $v4[#50] --< Param(0) >--> this[#51]
  [[function]] $v4[#50] --< Param(1) >--> z[#52]
  this[#51] -
  z[#52] --< Arg(1) >--> $v2.foo(...)[#54]
  $v2.foo[#53] -
  $v2.foo(...)[#54] --< Call >--> [[function]] foo[#18]
  $v2.foo(...)[#54] --< D >--> $v5[#55]
  $v5[#55] -
  module[#56] --< P(exports) >--> [[function]] $v4[#50]
  bar1[#57] --< V(p) >--> bar1[#63]
  bar1[#57] --< P(p) >--> bar1.p[#80]
  [[function]] $v6[#58] --< Param(0) >--> this[#59]
  [[function]] $v6[#58] --< Param(1) >--> y[#60]
  this[#59] -
  y[#60] --< Arg(1) >--> baz(...)[#61]
  baz(...)[#61] --< Call >--> [[function]] $v4[#50]
  baz(...)[#61] --< D >--> $v7[#62]
  $v7[#62] -
  bar1[#63] --< P(p) >--> [[function]] $v6[#58]
  bar1[#63] --< Arg(0) >--> bar1.p(...)[#81]
  bar2[#64] --< V(p) >--> bar2[#67]
  [[function]] $v8[#65] --< Param(0) >--> this[#66]
  this[#66] -
  bar2[#67] --< P(p) >--> [[function]] $v8[#65]
  bar3[#68] --< V(p) >--> bar3[#71]
  bar3[#68] --< P(p) >--> bar3.p[#84]
  $v9[#69] --< V(q) >--> $v9[#70]
  $v9[#69] --< P(q) >--> $v9.q[#86]
  $v9[#70] --< P(q) >--> [[function]] $v4[#50]
  $v9[#70] --< Arg(0) >--> $v9.q(...)[#87]
  bar3[#71] --< P(p) >--> $v9[#70]
  exports[#72] --< P(bar1) >--> bar1[#63]
  exports[#72] --< V(bar2) >--> exports[#73]
  exports[#73] --< P(bar2) >--> bar2[#67]
  exports[#73] --< V(bar3) >--> exports[#74]
  exports[#74] --< P(bar3) >--> bar3[#71]
  exports[#74] --< Arg(0) >--> exports.bar4(...)[#90]
  $v2.obj[#75] -
  $v2.foo(...)[#76] --< Call >--> [[function]] foo[#18]
  $v2.foo(...)[#76] --< D >--> $v11[#77]
  $v11[#77] -
  exports.bar1[#78] -
  "abc"[#79] --< Arg(1) >--> bar1.p(...)[#81]
  bar1.p[#80] -
  bar1.p(...)[#81] --< Call >--> [[function]] $v6[#58]
  bar1.p(...)[#81] --< D >--> $v13[#82]
  $v13[#82] -
  exports.bar3[#83] -
  bar3.p[#84] -
  "def"[#85] --< Arg(1) >--> $v9.q(...)[#87]
  $v9.q[#86] -
  $v9.q(...)[#87] --< Call >--> [[function]] $v4[#50]
  $v9.q(...)[#87] --< D >--> $v16[#88]
  $v16[#88] -
  exports.bar4[#89] -
  exports.bar4(...)[#90] --< Call >--> exports.bar4[#89]
  exports.bar4(...)[#90] --< D >--> $v17[#91]
  $v17[#91] -
