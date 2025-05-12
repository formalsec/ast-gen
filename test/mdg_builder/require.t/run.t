  $ graphjs mdg --no-export main.js
  [[sink]] require[#4] -
  './foo.js'[#10] --< Arg(1) >--> require(...)[#11]
  require(...)[#11] --< Call >--> [[sink]] require[#4]
  require(...)[#11] --< D >--> foo[#12]
  foo[#12] -
  [[module]] foo[#13] --< P(obj) >--> foo.obj[#18]
  [[module]] foo[#13] --< P(foo) >--> foo.foo[#19]
  [[module]] foo[#13] --< Arg(0) >--> foo.foo(...)[#20]
  './deps/bar.js'[#14] --< Arg(1) >--> require(...)[#15]
  require(...)[#15] --< Call >--> [[sink]] require[#4]
  require(...)[#15] --< D >--> bar[#16]
  bar[#16] -
  [[module]] bar[#17] --< P(bar1) >--> bar.bar1[#22]
  [[module]] bar[#17] --< P(bar3) >--> bar.bar3[#26]
  [[module]] bar[#17] --< P(bar4) >--> bar.bar4[#31]
  [[module]] bar[#17] --< Arg(0) >--> bar.bar4(...)[#32]
  foo.obj[#18] --< Arg(1) >--> foo.foo(...)[#20]
  foo.obj[#18] --< Arg(1) >--> bar.bar1.p(...)[#24]
  foo.foo[#19] -
  foo.foo(...)[#20] --< Call >--> foo.foo[#19]
  foo.foo(...)[#20] --< D >--> $v2[#21]
  $v2[#21] -
  bar.bar1[#22] --< P(p) >--> bar.bar1.p[#23]
  bar.bar1[#22] --< Arg(0) >--> bar.bar1.p(...)[#24]
  bar.bar1.p[#23] -
  bar.bar1.p(...)[#24] --< Call >--> bar.bar1.p[#23]
  bar.bar1.p(...)[#24] --< D >--> $v5[#25]
  $v5[#25] -
  bar.bar3[#26] --< P(p) >--> bar.bar3.p[#27]
  bar.bar3.p[#27] --< P(q) >--> bar.bar3.p.q[#28]
  bar.bar3.p[#27] --< Arg(0) >--> bar.bar3.p.q(...)[#29]
  bar.bar3.p.q[#28] -
  bar.bar3.p.q(...)[#29] --< Call >--> bar.bar3.p.q[#28]
  bar.bar3.p.q(...)[#29] --< D >--> $v8[#30]
  $v8[#30] -
  bar.bar4[#31] -
  bar.bar4(...)[#32] --< Call >--> bar.bar4[#31]
  bar.bar4(...)[#32] --< D >--> $v9[#33]
  $v9[#33] -

  $ graphjs mdg --no-export --multifile main.js
  [[sink]] require[#4] -
  './foo.js'[#10] --< Arg(1) >--> require(...)[#11]
  require(...)[#11] --< Call >--> [[sink]] require[#4]
  require(...)[#11] --< D >--> foo[#12]
  foo[#12] -
  [[module]] foo.js[#13] --< D >--> module[#14]
  module[#14] --< P(exports) >--> exports[#15]
  module[#14] --< V(exports) >--> module[#27]
  exports[#15] -
  obj[#16] --< V(foo) >--> obj[#18]
  10[#17] -
  obj[#18] --< P(foo) >--> 10[#17]
  obj[#18] --< Arg(1) >--> $v2.foo(...)[#77]
  obj[#18] --< Arg(1) >--> bar1.p(...)[#81]
  foo[#19] --< Param(0) >--> this[#20]
  foo[#19] --< Param(1) >--> x[#21]
  this[#20] -
  x[#21] -
  $v1[#22] --< V(p) >--> $v1[#23]
  $v1[#23] --< P(p) >--> x[#21]
  $v2[#24] --< V(obj) >--> $v2[#25]
  $v2[#24] --< P(foo) >--> $v2.foo[#54]
  $v2[#24] --< P(obj) >--> $v2.obj[#76]
  $v2[#25] --< P(obj) >--> obj[#18]
  $v2[#25] --< V(foo) >--> $v2[#26]
  $v2[#26] --< P(foo) >--> foo[#19]
  $v2[#26] --< Arg(0) >--> $v2.foo(...)[#55]
  $v2[#26] --< Arg(0) >--> $v2.foo(...)[#77]
  module[#27] --< P(exports) >--> $v2[#26]
  './deps/bar.js'[#28] --< Arg(1) >--> require(...)[#29]
  require(...)[#29] --< Call >--> [[sink]] require[#4]
  require(...)[#29] --< D >--> bar[#30]
  bar[#30] -
  [[module]] deps/bar.js[#31] --< D >--> module[#32]
  module[#32] --< P(exports) >--> exports[#33]
  exports[#33] --< V(bar1) >--> exports[#73]
  exports[#33] --< P(bar1) >--> exports.bar1[#79]
  exports[#33] --< P(bar3) >--> exports.bar3[#83]
  exports[#33] --< P(bar4) >--> exports.bar4[#88]
  exports[#33] --< Arg(0) >--> exports.bar4(...)[#89]
  "./baz"[#34] --< Arg(1) >--> require(...)[#35]
  require(...)[#35] --< Call >--> [[sink]] require[#4]
  require(...)[#35] --< D >--> baz[#36]
  baz[#36] -
  [[module]] deps/baz.js[#37] --< D >--> module[#38]
  module[#38] --< P(exports) >--> exports[#39]
  module[#38] --< V(exports) >--> module[#57]
  exports[#39] -
  'path'[#40] --< Arg(1) >--> require(...)[#41]
  require(...)[#41] --< Call >--> [[sink]] require[#4]
  require(...)[#41] --< D >--> npm[#42]
  npm[#42] -
  [[module]] path[#43] --< P(basename) >--> npm.basename[#45]
  [[module]] path[#43] --< Arg(0) >--> npm.basename(...)[#46]
  "abc"[#44] --< Arg(1) >--> npm.basename(...)[#46]
  npm.basename[#45] -
  npm.basename(...)[#46] --< Call >--> npm.basename[#45]
  npm.basename(...)[#46] --< D >--> $v3[#47]
  $v3[#47] -
  '../foo'[#48] --< Arg(1) >--> require(...)[#49]
  require(...)[#49] --< Call >--> [[sink]] require[#4]
  require(...)[#49] --< D >--> foo[#50]
  foo[#50] -
  $v4[#51] --< Param(0) >--> this[#52]
  $v4[#51] --< Param(1) >--> z[#53]
  this[#52] -
  z[#53] --< Arg(1) >--> $v2.foo(...)[#55]
  $v2.foo[#54] -
  $v2.foo(...)[#55] --< Call >--> foo[#19]
  $v2.foo(...)[#55] --< D >--> $v5[#56]
  $v5[#56] -
  module[#57] --< P(exports) >--> $v4[#51]
  bar1[#58] --< V(p) >--> bar1[#64]
  bar1[#58] --< P(p) >--> bar1.p[#80]
  $v6[#59] --< Param(0) >--> this[#60]
  $v6[#59] --< Param(1) >--> y[#61]
  this[#60] -
  y[#61] --< Arg(1) >--> baz(...)[#62]
  baz(...)[#62] --< Call >--> $v4[#51]
  baz(...)[#62] --< D >--> $v7[#63]
  $v7[#63] -
  bar1[#64] --< P(p) >--> $v6[#59]
  bar1[#64] --< Arg(0) >--> bar1.p(...)[#81]
  bar2[#65] --< V(p) >--> bar2[#68]
  $v8[#66] --< Param(0) >--> this[#67]
  this[#67] -
  bar2[#68] --< P(p) >--> $v8[#66]
  bar3[#69] --< V(p) >--> bar3[#72]
  bar3[#69] --< P(p) >--> bar3.p[#84]
  $v9[#70] --< V(q) >--> $v9[#71]
  $v9[#70] --< P(q) >--> $v9.q[#85]
  $v9[#71] --< P(q) >--> $v4[#51]
  $v9[#71] --< Arg(0) >--> $v9.q(...)[#86]
  bar3[#72] --< P(p) >--> $v9[#71]
  exports[#73] --< P(bar1) >--> bar1[#64]
  exports[#73] --< V(bar2) >--> exports[#74]
  exports[#74] --< P(bar2) >--> bar2[#68]
  exports[#74] --< V(bar3) >--> exports[#75]
  exports[#75] --< P(bar3) >--> bar3[#72]
  $v2.obj[#76] -
  $v2.foo(...)[#77] --< Call >--> foo[#19]
  $v2.foo(...)[#77] --< D >--> $v11[#78]
  $v11[#78] -
  exports.bar1[#79] -
  bar1.p[#80] -
  bar1.p(...)[#81] --< Call >--> $v6[#59]
  bar1.p(...)[#81] --< D >--> $v14[#82]
  $v14[#82] -
  exports.bar3[#83] -
  bar3.p[#84] -
  $v9.q[#85] -
  $v9.q(...)[#86] --< Call >--> $v4[#51]
  $v9.q(...)[#86] --< D >--> $v17[#87]
  $v17[#87] -
  exports.bar4[#88] -
  exports.bar4(...)[#89] --< D >--> $v18[#90]
  $v18[#90] -
