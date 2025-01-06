  $ graphjs mdg --no-svg --mode=singlefile main.js
  [[literal]] --< Arg(1) >--> require(...)[l_1]
  [[literal]] --< Arg(1) >--> require(...)[l_4]
  require[f_1] -
  require(...)[l_1] --< Call >--> require[f_1]
  require(...)[l_1] --< Ret >--> foo[l_2]
  foo[l_2] --< P(obj) >--> foo.obj[l_7]
  foo[l_2] --< P(foo) >--> foo.foo[l_8]
  foo[l_2] --< Arg(0) >--> foo.foo(...)[l_9]
  require(./foo.js)[l_3] --< D >--> foo[l_2]
  require(...)[l_4] --< Call >--> require[f_1]
  require(...)[l_4] --< Ret >--> bar[l_5]
  bar[l_5] --< P(bar1) >--> bar.bar1[l_11]
  bar[l_5] --< P(bar3) >--> bar.bar3[l_15]
  bar[l_5] --< P(bar4) >--> bar.bar4[l_20]
  bar[l_5] --< Arg(0) >--> bar.bar4(...)[l_21]
  require(./deps/bar.js)[l_6] --< D >--> bar[l_5]
  foo.obj[l_7] --< Arg(1) >--> foo.foo(...)[l_9]
  foo.obj[l_7] --< Arg(1) >--> bar.bar1.p(...)[l_13]
  foo.foo[l_8] -
  foo.foo(...)[l_9] --< Call >--> foo.foo[l_8]
  foo.foo(...)[l_9] --< Ret >--> $v2[l_10]
  $v2[l_10] -
  bar.bar1[l_11] --< P(p) >--> bar.bar1.p[l_12]
  bar.bar1[l_11] --< Arg(0) >--> bar.bar1.p(...)[l_13]
  bar.bar1.p[l_12] -
  bar.bar1.p(...)[l_13] --< Call >--> bar.bar1.p[l_12]
  bar.bar1.p(...)[l_13] --< Ret >--> $v5[l_14]
  $v5[l_14] -
  bar.bar3[l_15] --< P(p) >--> bar.bar3.p[l_16]
  bar.bar3.p[l_16] --< P(q) >--> bar.bar3.p.q[l_17]
  bar.bar3.p[l_16] --< Arg(0) >--> bar.bar3.p.q(...)[l_18]
  bar.bar3.p.q[l_17] -
  bar.bar3.p.q(...)[l_18] --< Call >--> bar.bar3.p.q[l_17]
  bar.bar3.p.q(...)[l_18] --< Ret >--> $v8[l_19]
  $v8[l_19] -
  bar.bar4[l_20] -
  bar.bar4(...)[l_21] --< Call >--> bar.bar4[l_20]
  bar.bar4(...)[l_21] --< Ret >--> $v9[l_22]
  $v9[l_22] -

  $ graphjs mdg --no-svg --mode=multifile main.js
  [[literal]] --< D >--> 10[l_0]
  module[l_8] --< V(exports) >--> module[l_9]
  foo[f_1] --< Param(0) >--> this[p_0]
  foo[f_1] --< Param(1) >--> x[p_1]
  this[p_0] -
  x[p_1] -
  obj[l_1] --< V(foo) >--> obj[l_2]
  10[l_0] -
  obj[l_2] --< P(foo) >--> 10[l_0]
  obj[l_2] --< Arg(1) >--> foo.foo(...)[l_48]
  obj[l_2] --< Arg(1) >--> bar.bar1.p(...)[l_52]
  $v1[l_3] --< V(p) >--> $v1[l_4]
  $v1[l_4] --< P(p) >--> x[p_1]
  $v2[l_5] --< V(obj) >--> $v2[l_6]
  $v2[l_6] --< P(obj) >--> obj[l_2]
  $v2[l_6] --< V(foo) >--> $v2[l_7]
  $v2[l_7] --< P(foo) >--> foo[f_1]
  $v2[l_7] --< P(obj) >--> obj[l_2]
  $v2[l_7] --< Arg(0) >--> foo.foo(...)[l_15]
  $v2[l_7] --< Arg(0) >--> foo.foo(...)[l_17]
  $v2[l_7] --< Arg(0) >--> foo.foo(...)[l_48]
  module[l_9] --< P(exports) >--> $v2[l_7]
  module[l_19] --< V(exports) >--> module[l_20]
  $v3[l_13] --< Arg(1) >--> foo.foo(...)[l_15]
  foo.foo(...)[l_15] --< Call >--> foo[f_1]
  foo.foo(...)[l_15] --< Ret >--> $v4[l_16]
  $v4[l_16] -
  $v5[f_3] --< Param(0) >--> this[p_0]
  $v5[f_3] --< Param(1) >--> x[p_1]
  this[p_0] -
  x[p_1] --< Arg(1) >--> foo.foo(...)[l_17]
  foo.foo(...)[l_17] --< Call >--> foo[f_1]
  foo.foo(...)[l_17] --< Ret >--> $v6[l_18]
  $v6[l_18] -
  module[l_20] --< P(exports) >--> $v5[f_3]
  module[l_38] --< V(exports) >--> module[l_39]
  bar1[l_24] --< V(p) >--> bar1[l_27]
  $v7[f_5] --< Param(0) >--> this[p_0]
  $v7[f_5] --< Param(1) >--> x[p_1]
  this[p_0] -
  x[p_1] --< Arg(1) >--> baz(...)[l_25]
  baz(...)[l_25] --< Call >--> $v5[f_3]
  baz(...)[l_25] --< Ret >--> $v8[l_26]
  $v8[l_26] -
  bar1[l_27] --< P(p) >--> $v7[f_5]
  bar1[l_27] --< Arg(0) >--> bar.bar1.p(...)[l_52]
  bar2[l_28] --< V(p) >--> bar2[l_29]
  $v9[f_6] --< Param(0) >--> this[p_0]
  this[p_0] -
  bar2[l_29] --< P(p) >--> $v9[f_6]
  bar3[l_30] --< V(p) >--> bar3[l_33]
  $v10[l_31] --< V(q) >--> $v10[l_32]
  $v10[l_32] --< P(q) >--> $v5[f_3]
  $v10[l_32] --< Arg(0) >--> bar.bar3.p.q(...)[l_57]
  bar3[l_33] --< P(p) >--> $v10[l_32]
  $v11[l_34] --< V(bar1) >--> $v11[l_35]
  $v11[l_35] --< P(bar1) >--> bar1[l_27]
  $v11[l_35] --< V(bar2) >--> $v11[l_36]
  $v11[l_36] --< P(bar2) >--> bar2[l_29]
  $v11[l_36] --< V(bar3) >--> $v11[l_37]
  $v11[l_37] --< P(bar1) >--> bar1[l_27]
  $v11[l_37] --< P(bar3) >--> bar3[l_33]
  $v11[l_37] --< Arg(0) >--> bar.bar4(...)[l_60]
  module[l_39] --< P(exports) >--> $v11[l_37]
  foo.foo(...)[l_48] --< Call >--> foo[f_1]
  foo.foo(...)[l_48] --< Ret >--> $v13[l_49]
  $v13[l_49] -
  bar.bar1.p(...)[l_52] --< Call >--> $v7[f_5]
  bar.bar1.p(...)[l_52] --< Ret >--> $v16[l_53]
  $v16[l_53] -
  bar.bar3.p.q(...)[l_57] --< Call >--> $v5[f_3]
  bar.bar3.p.q(...)[l_57] --< Ret >--> $v19[l_58]
  $v19[l_58] -
  bar.bar4(...)[l_60] --< Ret >--> $v20[l_61]
  $v20[l_61] -
