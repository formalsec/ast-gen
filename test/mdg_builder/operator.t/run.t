  $ graphjs mdg --no-svg unopt.js
  [[literal]] --< D >--> $v1[l_1]
  [[literal]] --< D >--> $v2[l_2]
  $v1[l_1] -
  $v2[l_2] --< D >--> $v3[l_3]
  $v3[l_3] -
  $v4[l_4] --< D >--> $v5[l_5]
  $v5[l_5] -
  $v6[l_6] --< D >--> $v7[l_7]
  $v7[l_7] --< D >--> $v8[l_8]
  $v8[l_8] -

  $ graphjs mdg --no-svg binopt.js
  [[literal]] --< D >--> $v1[l_1]
  [[literal]] --< D >--> $v2[l_2]
  [[literal]] --< D >--> $v3[l_3]
  [[literal]] --< D >--> $v5[l_5]
  $v1[l_1] -
  $v2[l_2] --< D >--> $v3[l_3]
  $v3[l_3] -
  $v4[l_4] --< D >--> $v5[l_5]
  $v5[l_5] -
  $v6[l_6] --< D >--> $v8[l_8]
  $v7[l_7] --< D >--> $v8[l_8]
  $v8[l_8] -
  $v9[l_9] --< D >--> $v11[l_11]
  $v10[l_10] --< D >--> $v11[l_11]
  $v11[l_11] --< D >--> $v13[l_13]
  $v12[l_12] --< D >--> $v13[l_13]
  $v13[l_13] -
