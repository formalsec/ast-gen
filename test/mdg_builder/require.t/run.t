Graph.js MDG Builder: single-file require
  $ graphjs mdg --no-export main.js
  [[sink]] require[#3] -
  "./foo.js"[#17] --< Arg(1) >--> require(...)[#18]
  require(...)[#18] --< Call >--> [[sink]] require[#3]
  require(...)[#18] --< D >--> foo[#19]
  foo[#19] -
  [[module]] foo[#20] --< P(obj) >--> foo.obj[#25]
  [[module]] foo[#20] --< P(foo) >--> foo.foo[#26]
  [[module]] foo[#20] --< Arg(0) >--> foo.foo(...)[#27]
  "./deps/bar.js"[#21] --< Arg(1) >--> require(...)[#22]
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
  "./foo.js"[#17] --< Arg(1) >--> require(...)[#18]
  require(...)[#18] --< Call >--> [[sink]] require[#3]
  require(...)[#18] --< D >--> foo[#19]
  foo[#19] -
  [[module]] foo.js[#20] --< D >--> module[#21]
  module[#21] --< P(exports) >--> exports[#22]
  module[#21] --< V(exports) >--> module[#30]
  exports[#22] -
  obj[#23] --< V(foo) >--> obj[#25]
  10[#24] -
  obj[#25] --< P(foo) >--> 10[#24]
  [[function]] foo[#26] -
  $v2[#27] --< V(obj) >--> $v2[#28]
  $v2[#27] --< P(obj) >--> $v2.obj[#69]
  $v2[#27] --< P(foo) >--> $v2.foo[#70]
  $v2[#28] --< P(obj) >--> obj[#25]
  $v2[#28] --< V(foo) >--> $v2[#29]
  $v2[#29] --< P(foo) >--> [[function]] foo[#26]
  module[#30] --< P(exports) >--> $v2[#29]
  "./deps/bar.js"[#31] --< Arg(1) >--> require(...)[#32]
  require(...)[#32] --< Call >--> [[sink]] require[#3]
  require(...)[#32] --< D >--> bar[#33]
  bar[#33] -
  [[module]] deps/bar.js[#34] --< D >--> module[#35]
  module[#35] --< P(exports) >--> exports[#36]
  exports[#36] --< V(bar1) >--> exports[#66]
  exports[#36] --< P(bar1) >--> exports.bar1[#73]
  exports[#36] --< P(bar3) >--> exports.bar3[#79]
  exports[#36] --< P(bar4) >--> exports.bar4[#85]
  "./baz"[#37] --< Arg(1) >--> require(...)[#38]
  require(...)[#38] --< Call >--> [[sink]] require[#3]
  require(...)[#38] --< D >--> baz[#39]
  baz[#39] -
  [[module]] deps/baz.js[#40] --< D >--> module[#41]
  module[#41] --< P(exports) >--> exports[#42]
  module[#41] --< V(exports) >--> module[#55]
  exports[#42] -
  "path"[#43] --< Arg(1) >--> require(...)[#44]
  require(...)[#44] --< Call >--> [[sink]] require[#3]
  require(...)[#44] --< D >--> npm[#45]
  npm[#45] -
  [[module]] path[#46] --< P(basename) >--> path.basename[#48]
  [[module]] path[#46] --< Arg(0) >--> path.basename(...)[#49]
  "abc"[#47] --< Arg(1) >--> path.basename(...)[#49]
  path.basename[#48] -
  path.basename(...)[#49] --< Call >--> path.basename[#48]
  path.basename(...)[#49] --< D >--> $v3[#50]
  $v3[#50] -
  "../foo"[#51] --< Arg(1) >--> require(...)[#52]
  require(...)[#52] --< Call >--> [[sink]] require[#3]
  require(...)[#52] --< D >--> foo[#53]
  foo[#53] -
  [[function]] $v4[#54] -
  module[#55] --< P(exports) >--> [[function]] $v4[#54]
  bar1[#56] --< V(p) >--> bar1[#58]
  bar1[#56] --< P(p) >--> bar1.p[#75]
  [[function]] $v6[#57] -
  bar1[#58] --< P(p) >--> [[function]] $v6[#57]
  bar2[#59] --< V(p) >--> bar2[#61]
  [[function]] $v8[#60] -
  bar2[#61] --< P(p) >--> [[function]] $v8[#60]
  bar3[#62] --< V(p) >--> bar3[#65]
  bar3[#62] --< P(p) >--> bar3.p[#80]
  $v9[#63] --< V(q) >--> $v9[#64]
  $v9[#63] --< P(q) >--> $v9.q[#82]
  $v9[#64] --< P(q) >--> [[function]] $v4[#54]
  bar3[#65] --< P(p) >--> $v9[#64]
  exports[#66] --< P(bar1) >--> bar1[#58]
  exports[#66] --< V(bar2) >--> exports[#67]
  exports[#67] --< P(bar2) >--> bar2[#61]
  exports[#67] --< V(bar3) >--> exports[#68]
  exports[#68] --< P(bar3) >--> bar3[#65]
  exports[#68] --< Arg(0) >--> exports.bar4(...)[#86]
  $v2.obj[#69] -
  $v2.foo[#70] -
  $v1[#71] --< V(p) >--> $v1[#72]
  $v1[#72] --< P(p) >--> obj[#25]
  $v1[#72] --< P(p) >--> "abc"[#74]
  $v1[#72] --< P(p) >--> "def"[#81]
  exports.bar1[#73] -
  "abc"[#74] -
  bar1.p[#75] -
  exports.bar3[#79] -
  bar3.p[#80] -
  "def"[#81] -
  $v9.q[#82] -
  exports.bar4[#85] -
  exports.bar4(...)[#86] --< Call >--> exports.bar4[#85]
  exports.bar4(...)[#86] --< D >--> $v17[#87]
  $v17[#87] -
