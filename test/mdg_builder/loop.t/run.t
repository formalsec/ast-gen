  $ graphjs mdg --no-svg while.js
  [[literal]] -
  x1[l_1] --< V(p1) >--> x1[l_2]
  x1[l_2] --< P(p1) >--> [[literal]]
  x1[l_2] --< [[RefParent(p1)]] >--> x1[l_1]
  y1[l_3] --< V(p1) >--> y1[l_4]
  y1[l_4] --< [[RefParent(p1)]] >--> y1[l_3]
  y1[l_4] --< P(p1) >--> y2[l_6]
  y2[l_5] --< V(p2) >--> y2[l_6]
  y2[l_6] --< [[RefParent(p2)]] >--> y2[l_5]
  y2[l_6] --< P(p2) >--> y3[l_8]
  y3[l_7] --< V(p3) >--> y3[l_8]
  y3[l_8] --< P(p3) >--> [[literal]]
  y3[l_8] --< [[RefParent(p3)]] >--> y3[l_7]

  $ graphjs mdg --no-svg forin.js
  [[literal]] -
  $v1[l_1] -
  x1[l_2] --< V(p1) >--> x1[l_3]
  x1[l_3] --< P(p1) >--> [[literal]]
  x1[l_3] --< [[RefParent(p1)]] >--> x1[l_2]
  $v2[l_4] -
  y1[l_5] --< V(p1) >--> y1[l_6]
  y1[l_6] --< [[RefParent(p1)]] >--> y1[l_5]
  y1[l_6] --< P(p1) >--> y2[l_8]
  y2[l_7] --< V(p2) >--> y2[l_8]
  y2[l_8] --< [[RefParent(p2)]] >--> y2[l_7]
  y2[l_8] --< P(p2) >--> y3[l_10]
  y3[l_9] --< V(p3) >--> y3[l_10]
  y3[l_10] --< P(p3) >--> [[literal]]
  y3[l_10] --< [[RefParent(p3)]] >--> y3[l_9]

  $ graphjs mdg --no-svg forof.js
  [[literal]] -
  $v1[l_1] -
  x1[l_2] --< V(p1) >--> x1[l_3]
  x1[l_3] --< P(p1) >--> [[literal]]
  x1[l_3] --< [[RefParent(p1)]] >--> x1[l_2]
  $v2[l_4] -
  y1[l_5] --< V(p1) >--> y1[l_6]
  y1[l_6] --< [[RefParent(p1)]] >--> y1[l_5]
  y1[l_6] --< P(p1) >--> y2[l_8]
  y2[l_7] --< V(p2) >--> y2[l_8]
  y2[l_8] --< [[RefParent(p2)]] >--> y2[l_7]
  y2[l_8] --< P(p2) >--> y3[l_10]
  y3[l_9] --< V(p3) >--> y3[l_10]
  y3[l_10] --< P(p3) >--> [[literal]]
  y3[l_10] --< [[RefParent(p3)]] >--> y3[l_9]
