  $ graphjs mdg --no-export --mode=singlefile main.js
  require[f_1] -
  './foo.js'[v_2] --< Arg(1) >--> require(...)[l_1]
  require(...)[l_1] --< Call >--> require[f_1]
  require(...)[l_1] --< D >--> foo[l_2]
  foo[l_2] --< P(obj) >--> foo.obj[l_7]
  foo[l_2] --< P(foo) >--> foo.foo[l_8]
  foo[l_2] --< Arg(0) >--> foo.foo(...)[l_9]
  import(./foo.js)[l_3] --< D >--> foo[l_2]
  './deps/bar.js'[v_3] --< Arg(1) >--> require(...)[l_4]
  require(...)[l_4] --< Call >--> require[f_1]
  require(...)[l_4] --< D >--> bar[l_5]
  bar[l_5] --< P(bar1) >--> bar.bar1[l_11]
  bar[l_5] --< P(bar3) >--> bar.bar3[l_15]
  bar[l_5] --< P(bar4) >--> bar.bar4[l_20]
  bar[l_5] --< Arg(0) >--> bar.bar4(...)[l_21]
  import(./deps/bar.js)[l_6] --< D >--> bar[l_5]
  foo.obj[l_7] --< Arg(1) >--> foo.foo(...)[l_9]
  foo.obj[l_7] --< Arg(1) >--> bar.bar1.p(...)[l_13]
  foo.foo[l_8] -
  foo.foo(...)[l_9] --< Call >--> foo.foo[l_8]
  foo.foo(...)[l_9] --< D >--> $v2[l_10]
  $v2[l_10] -
  bar.bar1[l_11] --< P(p) >--> bar.bar1.p[l_12]
  bar.bar1[l_11] --< Arg(0) >--> bar.bar1.p(...)[l_13]
  bar.bar1.p[l_12] -
  bar.bar1.p(...)[l_13] --< Call >--> bar.bar1.p[l_12]
  bar.bar1.p(...)[l_13] --< D >--> $v5[l_14]
  $v5[l_14] -
  bar.bar3[l_15] --< P(p) >--> bar.bar3.p[l_16]
  bar.bar3.p[l_16] --< P(q) >--> bar.bar3.p.q[l_17]
  bar.bar3.p[l_16] --< Arg(0) >--> bar.bar3.p.q(...)[l_18]
  bar.bar3.p.q[l_17] -
  bar.bar3.p.q(...)[l_18] --< Call >--> bar.bar3.p.q[l_17]
  bar.bar3.p.q(...)[l_18] --< D >--> $v8[l_19]
  $v8[l_19] -
  bar.bar4[l_20] -
  bar.bar4(...)[l_21] --< Call >--> bar.bar4[l_20]
  bar.bar4(...)[l_21] --< D >--> $v9[l_22]
  $v9[l_22] -

  $ graphjs mdg --no-export --mode=multifile main.js
  module[l_8] --< V(exports) >--> module[l_9]
  obj[l_1] --< V(foo) >--> obj[l_2]
  10[v_2] -
  obj[l_2] --< P(foo) >--> 10[v_2]
  obj[l_2] --< Arg(1) >--> foo.foo(...)[l_46]
  obj[l_2] --< Arg(1) >--> bar.bar1.p(...)[l_50]
  foo[f_1] --< Param(0) >--> this[p_0]
  foo[f_1] --< Param(1) >--> x[p_1]
  this[p_0] -
  x[p_1] -
  $v1[l_3] --< V(p) >--> $v1[l_4]
  $v1[l_4] --< P(p) >--> x[p_1]
  $v2[l_5] --< V(obj) >--> $v2[l_6]
  $v2[l_6] --< P(obj) >--> obj[l_2]
  $v2[l_6] --< V(foo) >--> $v2[l_7]
  $v2[l_7] --< P(obj) >--> obj[l_2]
  $v2[l_7] --< P(foo) >--> foo[f_1]
  $v2[l_7] --< Arg(0) >--> foo.foo(...)[l_15]
  $v2[l_7] --< Arg(0) >--> foo.foo(...)[l_17]
  $v2[l_7] --< Arg(0) >--> foo.foo(...)[l_46]
  module[l_9] --< P(exports) >--> $v2[l_7]
  module[l_19] --< V(exports) >--> module[l_20]
  '../foo'[v_3] -
  $v3[l_13] --< Arg(1) >--> foo.foo(...)[l_15]
  foo.foo(...)[l_15] --< Call >--> foo[f_1]
  foo.foo(...)[l_15] --< D >--> $v4[l_16]
  $v4[l_16] -
  $v5[f_3] --< Param(0) >--> this[p_0]
  $v5[f_3] --< Param(1) >--> z[p_1]
  this[p_0] -
  z[p_1] --< Arg(1) >--> foo.foo(...)[l_17]
  foo.foo(...)[l_17] --< Call >--> foo[f_1]
  foo.foo(...)[l_17] --< D >--> $v6[l_18]
  $v6[l_18] -
  module[l_20] --< P(exports) >--> $v5[f_3]
  module.exports[l_34] --< P(bar1) >--> bar1[l_27]
  module.exports[l_34] --< P(bar3) >--> bar3[l_33]
  module.exports[l_34] --< V(bar1) >--> module.exports[l_35]
  module.exports[l_34] --< Arg(0) >--> bar.bar4(...)[l_58]
  "./baz"[v_4] -
  bar1[l_24] --< V(p) >--> bar1[l_27]
  $v7[f_5] --< Param(0) >--> this[p_0]
  $v7[f_5] --< Param(1) >--> y[p_1]
  this[p_0] -
  y[p_1] --< Arg(1) >--> baz(...)[l_25]
  baz(...)[l_25] --< Call >--> $v5[f_3]
  baz(...)[l_25] --< D >--> $v8[l_26]
  $v8[l_26] -
  bar1[l_27] --< P(p) >--> $v7[f_5]
  bar1[l_27] --< Arg(0) >--> bar.bar1.p(...)[l_50]
  bar2[l_28] --< V(p) >--> bar2[l_29]
  $v9[f_6] --< Param(0) >--> this[p_0]
  this[p_0] -
  bar2[l_29] --< P(p) >--> $v9[f_6]
  bar3[l_30] --< V(p) >--> bar3[l_33]
  $v10[l_31] --< V(q) >--> $v10[l_32]
  $v10[l_32] --< P(q) >--> $v5[f_3]
  $v10[l_32] --< Arg(0) >--> bar.bar3.p.q(...)[l_55]
  bar3[l_33] --< P(p) >--> $v10[l_32]
  module.exports[l_35] --< P(bar1) >--> bar1[l_27]
  module.exports[l_35] --< V(bar2) >--> module.exports[l_36]
  module.exports[l_36] --< P(bar2) >--> bar2[l_29]
  module.exports[l_36] --< V(bar3) >--> module.exports[l_37]
  module.exports[l_37] --< P(bar3) >--> bar3[l_33]
  './foo.js'[v_5] -
  './deps/bar.js'[v_6] -
  foo.foo(...)[l_46] --< Call >--> foo[f_1]
  foo.foo(...)[l_46] --< D >--> $v12[l_47]
  $v12[l_47] -
  bar.bar1.p(...)[l_50] --< Call >--> $v7[f_5]
  bar.bar1.p(...)[l_50] --< D >--> $v15[l_51]
  $v15[l_51] -
  bar.bar3.p.q(...)[l_55] --< Call >--> $v5[f_3]
  bar.bar3.p.q(...)[l_55] --< D >--> $v18[l_56]
  $v18[l_56] -
  bar.bar4(...)[l_58] --< D >--> $v19[l_59]
  $v19[l_59] -
