Graph.js MDG Builder: unary operator
  $ graphjs mdg --no-export unopt.js
  [[function]] defineProperty[#5] -
  10[#17] --< D >--> $v1[#18]
  $v1[#18] -
  10[#19] --< D >--> $v2[#20]
  $v2[#20] --< D >--> $v3[#21]
  $v3[#21] -
  $v4[#22] --< D >--> $v5[#23]
  $v5[#23] -
  $v6[#24] --< D >--> $v7[#25]
  $v7[#25] --< D >--> $v8[#26]
  $v8[#26] -

Graph.js MDG Builder: binary operator
  $ graphjs mdg --no-export binopt.js
  [[function]] defineProperty[#5] -
  10[#17] --< D >--> $v1[#19]
  "abc"[#18] --< D >--> $v1[#19]
  $v1[#19] -
  10[#20] --< D >--> $v2[#22]
  "abc"[#21] --< D >--> $v2[#22]
  $v2[#22] --< D >--> $v3[#24]
  true[#23] --< D >--> $v3[#24]
  $v3[#24] -
  $v4[#25] --< D >--> $v5[#27]
  10[#26] --< D >--> $v5[#27]
  $v5[#27] -
  $v6[#28] --< D >--> $v8[#30]
  $v7[#29] --< D >--> $v8[#30]
  $v8[#30] -
  $v9[#31] --< D >--> $v11[#33]
  $v10[#32] --< D >--> $v11[#33]
  $v11[#33] --< D >--> $v13[#35]
  $v12[#34] --< D >--> $v13[#35]
  $v13[#35] -

Graph.js MDG Builder: template expression
  $ graphjs mdg --no-export template.js
  [[function]] defineProperty[#5] -
  `abc${10} def${true}`[#17] -
  10[#18] --< D >--> `abc${10} def${true}`[#17]
  true[#19] --< D >--> `abc${10} def${true}`[#17]
