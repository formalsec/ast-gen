  $ graphjs mdg --no-export --mode=singlefile main.js
  [warn] TODO: check for npm modules
  [warn] TODO: check for npm modules
  require[f_1] -
  './foo.js'[v_2] --< Arg(1) >--> require(...)[l_1]
  require(...)[l_1] --< Call >--> require[f_1]
  require(...)[l_1] --< D >--> foo[l_2]
  foo[l_2] -
  './deps/bar.js'[v_3] --< Arg(1) >--> require(...)[l_3]
  require(...)[l_3] --< Call >--> require[f_1]
  require(...)[l_3] --< D >--> bar[l_4]
  bar[l_4] -
  foo.foo(...)[l_5] --< D >--> $v2[l_6]
  $v2[l_6] -
  $v3.p(...)[l_7] --< D >--> $v5[l_8]
  $v5[l_8] -
  $v7.q(...)[l_9] --< D >--> $v8[l_10]
  $v8[l_10] -
  bar.bar4(...)[l_11] --< D >--> $v9[l_12]
  $v9[l_12] -

  $ graphjs mdg --no-export --mode=multifile main.js
  require[f_4] -
  './foo.js'[v_2] --< Arg(1) >--> require(...)[l_1]
  require(...)[l_1] --< Call >--> require[f_1]
  require(...)[l_1] --< D >--> foo[l_2]
  foo[l_2] -
  module[l_10] --< V(exports) >--> module[l_11]
  obj[l_3] --< V(foo) >--> obj[l_4]
  10[v_3] -
  obj[l_4] --< P(foo) >--> 10[v_3]
  obj[l_4] --< Arg(1) >--> $v2.foo(...)[l_41]
  obj[l_4] --< Arg(1) >--> bar1.p(...)[l_45]
  foo[f_2] --< Param(0) >--> this[p_0]
  foo[f_2] --< Param(1) >--> x[p_1]
  this[p_0] -
  x[p_1] -
  $v1[l_5] --< V(p) >--> $v1[l_6]
  $v1[l_6] --< P(p) >--> x[p_1]
  $v2[l_7] --< V(obj) >--> $v2[l_8]
  $v2[l_7] --< P(foo) >--> $v2.foo[l_19]
  $v2[l_7] --< P(obj) >--> $v2.obj[l_40]
  $v2[l_8] --< P(obj) >--> obj[l_4]
  $v2[l_8] --< V(foo) >--> $v2[l_9]
  $v2[l_9] --< P(foo) >--> foo[f_2]
  $v2[l_9] --< Arg(0) >--> $v2.foo(...)[l_20]
  $v2[l_9] --< Arg(0) >--> $v2.foo(...)[l_22]
  $v2[l_9] --< Arg(0) >--> $v2.foo(...)[l_41]
  module[l_11] --< P(exports) >--> $v2[l_9]
  './deps/bar.js'[v_4] --< Arg(1) >--> require(...)[l_12]
  require(...)[l_12] --< Call >--> require[f_1]
  require(...)[l_12] --< D >--> bar[l_13]
  bar[l_13] -
  module.exports[l_36] --< V(bar1) >--> module.exports[l_37]
  module.exports[l_36] --< P(bar1) >--> module.exports.bar1[l_43]
  module.exports[l_36] --< P(bar3) >--> module.exports.bar3[l_47]
  module.exports[l_36] --< P(bar4) >--> module.exports.bar4[l_52]
  module.exports[l_36] --< Arg(0) >--> module.exports.bar4(...)[l_53]
  "./baz"[v_5] --< Arg(1) >--> require(...)[l_14]
  require(...)[l_14] --< Call >--> require[f_3]
  require(...)[l_14] --< D >--> baz[l_15]
  baz[l_15] -
  module[l_24] --< V(exports) >--> module[l_25]
  '../foo'[v_6] --< Arg(1) >--> require(...)[l_16]
  require(...)[l_16] --< Call >--> require[f_4]
  require(...)[l_16] --< D >--> foo[l_17]
  foo[l_17] -
  $v3[l_18] --< Arg(1) >--> $v2.foo(...)[l_20]
  $v2.foo[l_19] -
  $v2.foo(...)[l_20] --< Call >--> foo[f_2]
  $v2.foo(...)[l_20] --< D >--> $v4[l_21]
  $v4[l_21] -
  $v5[f_5] --< Param(0) >--> this[p_0]
  $v5[f_5] --< Param(1) >--> z[p_1]
  this[p_0] -
  z[p_1] --< Arg(1) >--> $v2.foo(...)[l_22]
  $v2.foo(...)[l_22] --< Call >--> foo[f_2]
  $v2.foo(...)[l_22] --< D >--> $v6[l_23]
  $v6[l_23] -
  module[l_25] --< P(exports) >--> $v5[f_5]
  bar1[l_26] --< V(p) >--> bar1[l_29]
  bar1[l_26] --< P(p) >--> bar1.p[l_44]
  $v7[f_6] --< Param(0) >--> this[p_0]
  $v7[f_6] --< Param(1) >--> y[p_1]
  this[p_0] -
  y[p_1] --< Arg(1) >--> baz(...)[l_27]
  baz(...)[l_27] --< Call >--> $v5[f_5]
  baz(...)[l_27] --< D >--> $v8[l_28]
  $v8[l_28] -
  bar1[l_29] --< P(p) >--> $v7[f_6]
  bar1[l_29] --< Arg(0) >--> bar1.p(...)[l_45]
  bar2[l_30] --< V(p) >--> bar2[l_31]
  $v9[f_7] --< Param(0) >--> this[p_0]
  this[p_0] -
  bar2[l_31] --< P(p) >--> $v9[f_7]
  bar3[l_32] --< V(p) >--> bar3[l_35]
  bar3[l_32] --< P(p) >--> bar3.p[l_48]
  $v10[l_33] --< V(q) >--> $v10[l_34]
  $v10[l_33] --< P(q) >--> $v10.q[l_49]
  $v10[l_34] --< P(q) >--> $v5[f_5]
  $v10[l_34] --< Arg(0) >--> $v10.q(...)[l_50]
  bar3[l_35] --< P(p) >--> $v10[l_34]
  module.exports[l_37] --< P(bar1) >--> bar1[l_29]
  module.exports[l_37] --< V(bar2) >--> module.exports[l_38]
  module.exports[l_38] --< P(bar2) >--> bar2[l_31]
  module.exports[l_38] --< V(bar3) >--> module.exports[l_39]
  module.exports[l_39] --< P(bar3) >--> bar3[l_35]
  $v2.obj[l_40] -
  $v2.foo(...)[l_41] --< Call >--> foo[f_2]
  $v2.foo(...)[l_41] --< D >--> $v12[l_42]
  $v12[l_42] -
  module.exports.bar1[l_43] -
  bar1.p[l_44] -
  bar1.p(...)[l_45] --< Call >--> $v7[f_6]
  bar1.p(...)[l_45] --< D >--> $v15[l_46]
  $v15[l_46] -
  module.exports.bar3[l_47] -
  bar3.p[l_48] -
  $v10.q[l_49] -
  $v10.q(...)[l_50] --< Call >--> $v5[f_5]
  $v10.q(...)[l_50] --< D >--> $v18[l_51]
  $v18[l_51] -
  module.exports.bar4[l_52] -
  module.exports.bar4(...)[l_53] --< D >--> $v19[l_54]
  $v19[l_54] -
