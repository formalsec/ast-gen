  $ graphjs mdg --no-export if.js
  x1[l_1] --< V(p1) >--> x1[l_2]
  10[v_2] -
  x1[l_2] --< P(p1) >--> 10[v_2]
  x[l_3] --< V(q1) >--> x[l_4]
  x[l_4] --< P(q1) >--> x1[l_2]
  y1[l_5] --< V(p1) >--> y1[l_6]
  10[v_3] -
  y1[l_6] --< P(p1) >--> 10[v_3]
  y2[l_7] --< V(p2) >--> y2[l_8]
  "abc"[v_4] -
  y2[l_8] --< P(p2) >--> "abc"[v_4]
  y[l_9] --< V(q1) >--> y[l_10]
  y[l_10] --< P(q1) >--> y1[l_6]
  y[l_10] --< V(q2) >--> y[l_11]
  y[l_11] --< P(q2) >--> y2[l_8]
  z1[l_12] --< V(p1) >--> z1[l_13]
  10[v_5] -
  z1[l_13] --< P(p1) >--> 10[v_5]
  z1[l_14] --< V(p2) >--> z1[l_15]
  "abc"[v_6] -
  z1[l_15] --< P(p2) >--> "abc"[v_6]
  z[l_16] --< V(q1) >--> z[l_17]
  z[l_17] --< P(q1) >--> z1[l_13]
  z[l_17] --< P(q1) >--> z1[l_15]
  w1[l_18] --< V(p1) >--> w1[l_19]
  w1[l_18] --< V(p2) >--> w1[l_20]
  10[v_7] -
  w1[l_19] --< P(p1) >--> 10[v_7]
  "abc"[v_8] -
  w1[l_20] --< P(p2) >--> "abc"[v_8]
  w[l_21] --< V(q1) >--> w[l_22]
  w[l_22] --< P(q1) >--> w1[l_19]
  w[l_22] --< P(q1) >--> w1[l_20]

  $ graphjs mdg --no-export switch.js
  x1[l_1] --< V(p1) >--> x1[l_2]
  10[v_2] -
  x1[l_2] --< P(p1) >--> 10[v_2]
  y1[l_3] --< V(p1) >--> y1[l_4]
  10[v_3] -
  y1[l_4] --< P(p1) >--> 10[v_3]
  y2[l_5] --< V(p2) >--> y2[l_6]
  "abc"[v_4] -
  y2[l_6] --< P(p2) >--> "abc"[v_4]
  y3[l_7] --< V(p3) >--> y3[l_8]
  true[v_5] -
  y3[l_8] --< P(p3) >--> true[v_5]
  z1[l_9] --< V(p1) >--> z1[l_10]
  10[v_6] -
  z1[l_10] --< P(p1) >--> 10[v_6]
  z1[l_10] --< V(p2) >--> z1[l_11]
  "abc"[v_7] -
  z1[l_11] --< P(p2) >--> "abc"[v_7]
  z1[l_11] --< V(p3) >--> z1[l_12]
  true[v_8] -
  z1[l_12] --< P(p3) >--> true[v_8]
