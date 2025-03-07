Flag for using unsafe literal properties
  $ graphjs mdg --no-export unsafe_literal_properties.js
  [[literal]] --< D >--> 10[l_0]
  [[literal]] --< D >--> 20[l_0]
  obj[l_1] --< V(*) >--> obj[l_2]
  obj[l_1] --< P(*) >--> obj.*[l_3]
  10[l_0] --< V(*) >--> $v1[l_4]
  obj[l_2] --< P(*) >--> 10[l_0]
  obj.*[l_3] --< V(*) >--> $v1[l_4]
  20[l_0] -
  $v1[l_4] --< P(*) >--> 20[l_0]

  $ graphjs mdg --no-export unsafe_literal_properties.js --unsafe-literal-properties
  [[literal]] --< V(*) >--> $v1[l_4]
  obj[l_1] --< V(*) >--> obj[l_2]
  obj[l_1] --< P(*) >--> obj.*[l_3]
  obj[l_2] --< P(*) >--> [[literal]]
  obj.*[l_3] --< V(*) >--> $v1[l_4]
  $v1[l_4] --< P(*) >--> [[literal]]
