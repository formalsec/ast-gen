  $ graphjs mdg --no-svg while.js
  [[literal]] --< D >--> 10[l_0]
  [[literal]] --< D >--> 10[l_0]
  [[literal]] --< D >--> 10[l_0]
  x1[l_1] --< V(p1) >--> x1[l_2]
  10[l_0] -
  x1[l_2] --< P(p1) >--> 10[l_0]
  y1[l_3] --< V(p1) >--> y1[l_4]
  y1[l_4] --< P(p1) >--> y2[l_6]
  y2[l_5] --< V(p2) >--> y2[l_6]
  y2[l_6] --< P(p2) >--> y3[l_8]
  y3[l_7] --< V(p3) >--> y3[l_8]
  10[l_0] -
  y3[l_8] --< P(p3) >--> 10[l_0]
  y4[l_9] --< V(p4) >--> y4[l_10]
  y4[l_10] --< P(p4) >--> y1[l_4]
  z1[l_11] --< V(p1) >--> z1[l_12]
  z1[l_12] --< P(p1) >--> z2[l_14]
  z2[l_13] --< V(p2) >--> z2[l_14]
  z2[l_14] --< P(p2) >--> z3[l_16]
  z3[l_15] --< V(p3) >--> z3[l_16]
  10[l_0] -
  z3[l_16] --< P(p3) >--> 10[l_0]
  z4[l_17] --< V(p4) >--> z4[l_18]
  z4[l_18] --< P(p4) >--> z1[l_12]

  $ graphjs mdg --no-svg forin.js
  [[literal]] --< D >--> 10[l_0]
  [[literal]] --< D >--> 10[l_0]
  [[literal]] --< D >--> 10[l_0]
  $v1[l_1] -
  x1[l_2] --< V(p1) >--> x1[l_3]
  10[l_0] -
  x1[l_3] --< P(p1) >--> 10[l_0]
  $v2[l_4] -
  y1[l_5] --< V(p1) >--> y1[l_6]
  y1[l_6] --< P(p1) >--> y2[l_8]
  y2[l_7] --< V(p2) >--> y2[l_8]
  y2[l_8] --< P(p2) >--> y3[l_10]
  y3[l_9] --< V(p3) >--> y3[l_10]
  10[l_0] -
  y3[l_10] --< P(p3) >--> 10[l_0]
  y4[l_11] --< V(p4) >--> y4[l_12]
  y4[l_12] --< P(p4) >--> y1[l_6]
  $v3[l_13] -
  $v4[l_14] -
  z1[l_15] --< V(p1) >--> z1[l_16]
  z1[l_16] --< P(p1) >--> z2[l_18]
  z2[l_17] --< V(p2) >--> z2[l_18]
  z2[l_18] --< P(p2) >--> z3[l_20]
  z3[l_19] --< V(p3) >--> z3[l_20]
  10[l_0] -
  z3[l_20] --< P(p3) >--> 10[l_0]
  z4[l_21] --< V(p4) >--> z4[l_22]
  z4[l_22] --< P(p4) >--> z1[l_16]

  $ graphjs mdg --no-svg forof.js
  [[literal]] --< D >--> 10[l_0]
  [[literal]] --< D >--> 10[l_0]
  [[literal]] --< D >--> 10[l_0]
  $v1[l_1] -
  x1[l_2] --< V(p1) >--> x1[l_3]
  10[l_0] -
  x1[l_3] --< P(p1) >--> 10[l_0]
  $v2[l_4] -
  y1[l_5] --< V(p1) >--> y1[l_6]
  y1[l_6] --< P(p1) >--> y2[l_8]
  y2[l_7] --< V(p2) >--> y2[l_8]
  y2[l_8] --< P(p2) >--> y3[l_10]
  y3[l_9] --< V(p3) >--> y3[l_10]
  10[l_0] -
  y3[l_10] --< P(p3) >--> 10[l_0]
  y4[l_11] --< V(p4) >--> y4[l_12]
  y4[l_12] --< P(p4) >--> y1[l_6]
  $v3[l_13] -
  $v4[l_14] -
  z1[l_15] --< V(p1) >--> z1[l_16]
  z1[l_16] --< P(p1) >--> z2[l_18]
  z2[l_17] --< V(p2) >--> z2[l_18]
  z2[l_18] --< P(p2) >--> z3[l_20]
  z3[l_19] --< V(p3) >--> z3[l_20]
  10[l_0] -
  z3[l_20] --< P(p3) >--> 10[l_0]
  z4[l_21] --< V(p4) >--> z4[l_22]
  z4[l_22] --< P(p4) >--> z1[l_16]
