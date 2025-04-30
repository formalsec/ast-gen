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
  module[#14] --< P(exports) >--> exports[#15]
  module[#14] --< V(exports) >--> module[#27]
  exports[#15] -
  obj[#16] --< V(foo) >--> obj[#18]
  10[#17] -
  obj[#18] --< P(foo) >--> 10[#17]
  obj[#18] --< Arg(1) >--> $v2.foo(...)[#70]
  obj[#18] --< Arg(1) >--> bar1.p(...)[#74]
  foo[#19] --< Param(0) >--> this[#20]
  foo[#19] --< Param(1) >--> x[#21]
  this[#20] -
  x[#21] -
  $v1[#22] --< V(p) >--> $v1[#23]
  $v1[#23] --< P(p) >--> x[#21]
  $v2[#24] --< V(obj) >--> $v2[#25]
  $v2[#24] --< P(foo) >--> $v2.foo[#42]
  $v2[#24] --< P(obj) >--> $v2.obj[#69]
  $v2[#25] --< P(obj) >--> obj[#18]
  $v2[#25] --< V(foo) >--> $v2[#26]
  $v2[#26] --< P(foo) >--> foo[#19]
  $v2[#26] --< Arg(0) >--> $v2.foo(...)[#43]
  $v2[#26] --< Arg(0) >--> $v2.foo(...)[#48]
  $v2[#26] --< Arg(0) >--> $v2.foo(...)[#70]
  module[#27] --< P(exports) >--> $v2[#26]
  './deps/bar.js'[#28] --< Arg(1) >--> require(...)[#29]
  require(...)[#29] --< Call >--> require[#8]
  require(...)[#29] --< D >--> bar[#30]
  bar[#30] -
  module[#31] --< P(exports) >--> exports[#32]
  exports[#32] --< V(bar1) >--> exports[#66]
  exports[#32] --< P(bar1) >--> exports.bar1[#72]
  exports[#32] --< P(bar3) >--> exports.bar3[#76]
  exports[#32] --< P(bar4) >--> exports.bar4[#81]
  exports[#32] --< Arg(0) >--> exports.bar4(...)[#82]
  "./baz"[#33] --< Arg(1) >--> require(...)[#34]
  require(...)[#34] --< Call >--> require[#8]
  require(...)[#34] --< D >--> baz[#35]
  baz[#35] -
  module[#36] --< P(exports) >--> exports[#37]
  module[#36] --< V(exports) >--> module[#50]
  exports[#37] -
  '../foo'[#38] --< Arg(1) >--> require(...)[#39]
  require(...)[#39] --< Call >--> require[#8]
  require(...)[#39] --< D >--> foo[#40]
  foo[#40] -
  $v3[#41] --< Arg(1) >--> $v2.foo(...)[#43]
  $v2.foo[#42] -
  $v2.foo(...)[#43] --< Call >--> foo[#19]
  $v2.foo(...)[#43] --< D >--> $v4[#44]
  $v4[#44] -
  $v5[#45] --< Param(0) >--> this[#46]
  $v5[#45] --< Param(1) >--> z[#47]
  this[#46] -
  z[#47] --< Arg(1) >--> $v2.foo(...)[#48]
  $v2.foo(...)[#48] --< Call >--> foo[#19]
  $v2.foo(...)[#48] --< D >--> $v6[#49]
  $v6[#49] -
  module[#50] --< P(exports) >--> $v5[#45]
  bar1[#51] --< V(p) >--> bar1[#57]
  bar1[#51] --< P(p) >--> bar1.p[#73]
  $v7[#52] --< Param(0) >--> this[#53]
  $v7[#52] --< Param(1) >--> y[#54]
  this[#53] -
  y[#54] --< Arg(1) >--> baz(...)[#55]
  baz(...)[#55] --< Call >--> $v5[#45]
  baz(...)[#55] --< D >--> $v8[#56]
  $v8[#56] -
  bar1[#57] --< P(p) >--> $v7[#52]
  bar1[#57] --< Arg(0) >--> bar1.p(...)[#74]
  bar2[#58] --< V(p) >--> bar2[#61]
  $v9[#59] --< Param(0) >--> this[#60]
  this[#60] -
  bar2[#61] --< P(p) >--> $v9[#59]
  bar3[#62] --< V(p) >--> bar3[#65]
  bar3[#62] --< P(p) >--> bar3.p[#77]
  $v10[#63] --< V(q) >--> $v10[#64]
  $v10[#63] --< P(q) >--> $v10.q[#78]
  $v10[#64] --< P(q) >--> $v5[#45]
  $v10[#64] --< Arg(0) >--> $v10.q(...)[#79]
  bar3[#65] --< P(p) >--> $v10[#64]
  exports[#66] --< P(bar1) >--> bar1[#57]
  exports[#66] --< V(bar2) >--> exports[#67]
  exports[#67] --< P(bar2) >--> bar2[#61]
  exports[#67] --< V(bar3) >--> exports[#68]
  exports[#68] --< P(bar3) >--> bar3[#65]
  $v2.obj[#69] -
  $v2.foo(...)[#70] --< Call >--> foo[#19]
  $v2.foo(...)[#70] --< D >--> $v12[#71]
  $v12[#71] -
  exports.bar1[#72] -
  bar1.p[#73] -
  bar1.p(...)[#74] --< Call >--> $v7[#52]
  bar1.p(...)[#74] --< D >--> $v15[#75]
  $v15[#75] -
  exports.bar3[#76] -
  bar3.p[#77] -
  $v10.q[#78] -
  $v10.q(...)[#79] --< Call >--> $v5[#45]
  $v10.q(...)[#79] --< D >--> $v18[#80]
  $v18[#80] -
  exports.bar4[#81] -
  exports.bar4(...)[#82] --< D >--> $v19[#83]
  $v19[#83] -
