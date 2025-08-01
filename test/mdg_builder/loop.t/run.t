Graph.js MDG Builder: while loop
  $ graphjs mdg --no-export while.js
  x1[#18] --< V(p1) >--> x1[#20]
  10[#19] -
  x1[#20] --< P(p1) >--> 10[#19]
  y1[#24] --< V(p1) >--> y1[#26]
  y2[#25] -
  y1[#26] --< P(p1) >--> y2[#25]
  y1[#26] --< P(p1) >--> y2[#29]
  y2[#27] --< V(p2) >--> y2[#29]
  y3[#28] -
  y2[#29] --< P(p2) >--> y3[#28]
  y2[#29] --< P(p2) >--> y3[#32]
  y3[#30] --< V(p3) >--> y3[#32]
  10[#31] -
  y3[#32] --< P(p3) >--> 10[#31]
  y4[#33] --< V(p4) >--> y4[#34]
  y4[#34] --< P(p4) >--> y1[#26]
  z1[#44] --< V(p1) >--> z1[#46]
  z2[#45] -
  z1[#46] --< P(p1) >--> z2[#45]
  z1[#46] --< P(p1) >--> z2[#49]
  z2[#47] --< V(p2) >--> z2[#49]
  z3[#48] -
  z2[#49] --< P(p2) >--> z3[#48]
  z2[#49] --< P(p2) >--> z3[#57]
  z3[#55] --< V(p3) >--> z3[#57]
  10[#56] -
  z3[#57] --< P(p3) >--> 10[#56]
  z4[#58] --< V(p4) >--> z4[#59]
  z4[#59] --< P(p4) >--> z1[#46]
  w1[#73] --< P(p1) >--> w1.p1[#74]
  w1[#73] --< V(p1) >--> w1[#77]
  w1.p1[#74] --< D >--> $v2[#76]
  10[#75] --< D >--> $v2[#76]
  $v2[#76] --< D >--> $v2[#76]
  w1[#77] --< P(p1) >--> $v2[#76]
  w1[#77] --< V(p1) >--> w1[#77]

Graph.js MDG Builder: forin loop
  $ graphjs mdg --no-export forin.js
  $v1[#18] --< D >--> x[#19]
  x[#19] -
  x1[#20] --< V(p1) >--> x1[#22]
  10[#21] -
  x1[#22] --< P(p1) >--> 10[#21]
  $v2[#26] --< D >--> y[#27]
  y[#27] -
  y1[#28] --< V(p1) >--> y1[#30]
  y2[#29] -
  y1[#30] --< P(p1) >--> y2[#29]
  y1[#30] --< P(p1) >--> y2[#33]
  y2[#31] --< V(p2) >--> y2[#33]
  y3[#32] -
  y2[#33] --< P(p2) >--> y3[#32]
  y2[#33] --< P(p2) >--> y3[#36]
  y3[#34] --< V(p3) >--> y3[#36]
  10[#35] -
  y3[#36] --< P(p3) >--> 10[#35]
  y4[#37] --< V(p4) >--> y4[#38]
  y4[#38] --< P(p4) >--> y1[#30]
  $v3[#48] --< D >--> z[#49]
  z[#49] -
  $v4[#50] --< D >--> z0[#51]
  z0[#51] -
  z1[#52] --< V(p1) >--> z1[#54]
  z2[#53] -
  z1[#54] --< P(p1) >--> z2[#53]
  z1[#54] --< P(p1) >--> z2[#57]
  z2[#55] --< V(p2) >--> z2[#57]
  z3[#56] -
  z2[#57] --< P(p2) >--> z3[#56]
  z2[#57] --< P(p2) >--> z3[#65]
  z3[#63] --< V(p3) >--> z3[#65]
  10[#64] -
  z3[#65] --< P(p3) >--> 10[#64]
  z4[#66] --< V(p4) >--> z4[#67]
  z4[#67] --< P(p4) >--> z1[#54]
  w1[#83] --< P(p1) >--> w1.p1[#86]
  w1[#83] --< V(p1) >--> w1[#89]
  $v5[#84] --< D >--> w[#85]
  w[#85] -
  w1.p1[#86] --< D >--> $v7[#88]
  10[#87] --< D >--> $v7[#88]
  $v7[#88] --< D >--> $v7[#88]
  w1[#89] --< P(p1) >--> $v7[#88]
  w1[#89] --< V(p1) >--> w1[#89]

Graph.js MDG Builder: forof loop
  $ graphjs mdg --no-export forof.js
  $v1[#18] --< D >--> x[#19]
  x[#19] -
  x1[#20] --< V(p1) >--> x1[#22]
  10[#21] -
  x1[#22] --< P(p1) >--> 10[#21]
  $v2[#26] --< D >--> y[#27]
  y[#27] -
  y1[#28] --< V(p1) >--> y1[#30]
  y2[#29] -
  y1[#30] --< P(p1) >--> y2[#29]
  y1[#30] --< P(p1) >--> y2[#33]
  y2[#31] --< V(p2) >--> y2[#33]
  y3[#32] -
  y2[#33] --< P(p2) >--> y3[#32]
  y2[#33] --< P(p2) >--> y3[#36]
  y3[#34] --< V(p3) >--> y3[#36]
  10[#35] -
  y3[#36] --< P(p3) >--> 10[#35]
  y4[#37] --< V(p4) >--> y4[#38]
  y4[#38] --< P(p4) >--> y1[#30]
  $v3[#48] --< D >--> z[#49]
  z[#49] -
  $v4[#50] --< D >--> z0[#51]
  z0[#51] -
  z1[#52] --< V(p1) >--> z1[#54]
  z2[#53] -
  z1[#54] --< P(p1) >--> z2[#53]
  z1[#54] --< P(p1) >--> z2[#57]
  z2[#55] --< V(p2) >--> z2[#57]
  z3[#56] -
  z2[#57] --< P(p2) >--> z3[#56]
  z2[#57] --< P(p2) >--> z3[#65]
  z3[#63] --< V(p3) >--> z3[#65]
  10[#64] -
  z3[#65] --< P(p3) >--> 10[#64]
  z4[#66] --< V(p4) >--> z4[#67]
  z4[#67] --< P(p4) >--> z1[#54]
  w1[#83] --< P(p1) >--> w1.p1[#86]
  w1[#83] --< V(p1) >--> w1[#89]
  $v5[#84] --< D >--> w[#85]
  w[#85] -
  w1.p1[#86] --< D >--> $v7[#88]
  10[#87] --< D >--> $v7[#88]
  $v7[#88] --< D >--> $v7[#88]
  w1[#89] --< P(p1) >--> $v7[#88]
  w1[#89] --< V(p1) >--> w1[#89]
