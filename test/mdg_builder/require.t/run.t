  $ graphjs mdg --no-export --mode singlefile main.js
  [warn] TODO: check for npm modules
  [warn] TODO: check for npm modules
  require[#8] -
  './foo.js'[#11] --< Arg(1) >--> require(...)[#12]
  require(...)[#12] --< Call >--> require[#8]
  require(...)[#12] --< D >--> foo[#13]
  foo[#13] -
  './deps/bar.js'[#14] --< Arg(1) >--> require(...)[#15]
  require(...)[#15] --< Call >--> require[#8]
  require(...)[#15] --< D >--> bar[#16]
  bar[#16] -
  foo.foo(...)[#17] --< D >--> $v2[#18]
  $v2[#18] -
  $v3.p(...)[#19] --< D >--> $v5[#20]
  $v5[#20] -
  $v7.q(...)[#21] --< D >--> $v8[#22]
  $v8[#22] -
  bar.bar4(...)[#23] --< D >--> $v9[#24]
  $v9[#24] -

  $ graphjs mdg --no-export --mode multifile main.js
  require[#8] -
  './foo.js'[#11] --< Arg(1) >--> require(...)[#12]
  require(...)[#12] --< Call >--> require[#8]
  require(...)[#12] --< D >--> foo[#13]
  foo[#13] -
  [[module]] foo.js[#14] --< D >--> module[#15]
  module[#15] --< P(exports) >--> exports[#16]
  module[#15] --< V(exports) >--> module[#28]
  exports[#16] -
  obj[#17] --< V(foo) >--> obj[#19]
  10[#18] -
  obj[#19] --< P(foo) >--> 10[#18]
  obj[#19] --< Arg(1) >--> $v2.foo(...)[#73]
  obj[#19] --< Arg(1) >--> bar1.p(...)[#77]
  foo[#20] --< Param(0) >--> this[#21]
  foo[#20] --< Param(1) >--> x[#22]
  this[#21] -
  x[#22] -
  $v1[#23] --< V(p) >--> $v1[#24]
  $v1[#24] --< P(p) >--> x[#22]
  $v2[#25] --< V(obj) >--> $v2[#26]
  $v2[#25] --< P(foo) >--> $v2.foo[#45]
  $v2[#25] --< P(obj) >--> $v2.obj[#72]
  $v2[#26] --< P(obj) >--> obj[#19]
  $v2[#26] --< V(foo) >--> $v2[#27]
  $v2[#27] --< P(foo) >--> foo[#20]
  $v2[#27] --< Arg(0) >--> $v2.foo(...)[#46]
  $v2[#27] --< Arg(0) >--> $v2.foo(...)[#51]
  $v2[#27] --< Arg(0) >--> $v2.foo(...)[#73]
  module[#28] --< P(exports) >--> $v2[#27]
  './deps/bar.js'[#29] --< Arg(1) >--> require(...)[#30]
  require(...)[#30] --< Call >--> require[#8]
  require(...)[#30] --< D >--> bar[#31]
  bar[#31] -
  [[module]] deps/bar.js[#32] --< D >--> module[#33]
  module[#33] --< P(exports) >--> exports[#34]
  exports[#34] --< V(bar1) >--> exports[#69]
  exports[#34] --< P(bar1) >--> exports.bar1[#75]
  exports[#34] --< P(bar3) >--> exports.bar3[#79]
  exports[#34] --< P(bar4) >--> exports.bar4[#84]
  exports[#34] --< Arg(0) >--> exports.bar4(...)[#85]
  "./baz"[#35] --< Arg(1) >--> require(...)[#36]
  require(...)[#36] --< Call >--> require[#8]
  require(...)[#36] --< D >--> baz[#37]
  baz[#37] -
  [[module]] deps/baz.js[#38] --< D >--> module[#39]
  module[#39] --< P(exports) >--> exports[#40]
  module[#39] --< V(exports) >--> module[#53]
  exports[#40] -
  '../foo'[#41] --< Arg(1) >--> require(...)[#42]
  require(...)[#42] --< Call >--> require[#8]
  require(...)[#42] --< D >--> foo[#43]
  foo[#43] -
  $v3[#44] --< Arg(1) >--> $v2.foo(...)[#46]
  $v2.foo[#45] -
  $v2.foo(...)[#46] --< Call >--> foo[#20]
  $v2.foo(...)[#46] --< D >--> $v4[#47]
  $v4[#47] -
  $v5[#48] --< Param(0) >--> this[#49]
  $v5[#48] --< Param(1) >--> z[#50]
  this[#49] -
  z[#50] --< Arg(1) >--> $v2.foo(...)[#51]
  $v2.foo(...)[#51] --< Call >--> foo[#20]
  $v2.foo(...)[#51] --< D >--> $v6[#52]
  $v6[#52] -
  module[#53] --< P(exports) >--> $v5[#48]
  bar1[#54] --< V(p) >--> bar1[#60]
  bar1[#54] --< P(p) >--> bar1.p[#76]
  $v7[#55] --< Param(0) >--> this[#56]
  $v7[#55] --< Param(1) >--> y[#57]
  this[#56] -
  y[#57] --< Arg(1) >--> baz(...)[#58]
  baz(...)[#58] --< Call >--> $v5[#48]
  baz(...)[#58] --< D >--> $v8[#59]
  $v8[#59] -
  bar1[#60] --< P(p) >--> $v7[#55]
  bar1[#60] --< Arg(0) >--> bar1.p(...)[#77]
  bar2[#61] --< V(p) >--> bar2[#64]
  $v9[#62] --< Param(0) >--> this[#63]
  this[#63] -
  bar2[#64] --< P(p) >--> $v9[#62]
  bar3[#65] --< V(p) >--> bar3[#68]
  bar3[#65] --< P(p) >--> bar3.p[#80]
  $v10[#66] --< V(q) >--> $v10[#67]
  $v10[#66] --< P(q) >--> $v10.q[#81]
  $v10[#67] --< P(q) >--> $v5[#48]
  $v10[#67] --< Arg(0) >--> $v10.q(...)[#82]
  bar3[#68] --< P(p) >--> $v10[#67]
  exports[#69] --< P(bar1) >--> bar1[#60]
  exports[#69] --< V(bar2) >--> exports[#70]
  exports[#70] --< P(bar2) >--> bar2[#64]
  exports[#70] --< V(bar3) >--> exports[#71]
  exports[#71] --< P(bar3) >--> bar3[#68]
  $v2.obj[#72] -
  $v2.foo(...)[#73] --< Call >--> foo[#20]
  $v2.foo(...)[#73] --< D >--> $v12[#74]
  $v12[#74] -
  exports.bar1[#75] -
  bar1.p[#76] -
  bar1.p(...)[#77] --< Call >--> $v7[#55]
  bar1.p(...)[#77] --< D >--> $v15[#78]
  $v15[#78] -
  exports.bar3[#79] -
  bar3.p[#80] -
  $v10.q[#81] -
  $v10.q(...)[#82] --< Call >--> $v5[#48]
  $v10.q(...)[#82] --< D >--> $v18[#83]
  $v18[#83] -
  exports.bar4[#84] -
  exports.bar4(...)[#85] --< D >--> $v19[#86]
  $v19[#86] -
