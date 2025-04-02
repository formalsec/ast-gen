Flag for using unsafe literal properties
  $ graphjs mdg --no-export literal_mode.js
  obj[l_1] --< V(*) >--> obj[l_2]
  obj[l_1] --< P(*) >--> obj.*[l_3]
  10[v_2] --< V(*) >--> $v1[l_4]
  obj[l_2] --< P(*) >--> 10[v_2]
  obj.*[l_3] --< V(*) >--> $v1[l_4]
  20[v_3] -
  $v1[l_4] --< P(*) >--> 20[v_3]
  10[v_4] --< D >--> $v2[l_5]
  "abc"[v_5] --< D >--> $v2[l_5]
  $v2[l_5] -

  $ graphjs mdg --no-export literal_mode.js --literal-mode single
  [[literal]] --< V(*) >--> $v1[l_4]
  [[literal]] --< D >--> $v2[l_5]
  obj[l_1] --< V(*) >--> obj[l_2]
  obj[l_1] --< P(*) >--> obj.*[l_3]
  obj[l_2] --< P(*) >--> [[literal]]
  obj.*[l_3] --< V(*) >--> $v1[l_4]
  $v1[l_4] --< P(*) >--> [[literal]]
  $v2[l_5] -

  $ graphjs mdg --no-export literal_mode.js --literal-mode propwrap
  [[literal]] --< D >--> $v2[l_5]
  obj[l_1] --< V(*) >--> obj[l_2]
  obj[l_1] --< P(*) >--> obj.*[l_3]
  10[v_2] --< V(*) >--> $v1[l_4]
  obj[l_2] --< P(*) >--> 10[v_2]
  obj.*[l_3] --< V(*) >--> $v1[l_4]
  20[v_3] -
  $v1[l_4] --< P(*) >--> 20[v_3]
  $v2[l_5] -
