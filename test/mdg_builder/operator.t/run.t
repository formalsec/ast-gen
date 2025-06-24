Graph.js MDG Builder: unary operator
  $ graphjs mdg --no-export unopt.js
  10[#18] --< D >--> $v1[#19]
  $v1[#19] -
  10[#20] --< D >--> $v2[#21]
  $v2[#21] --< D >--> $v3[#22]
  $v3[#22] -
  $v4[#23] --< D >--> $v5[#24]
  $v5[#24] -
  $v6[#25] --< D >--> $v7[#26]
  $v7[#26] --< D >--> $v8[#27]
  $v8[#27] -

Graph.js MDG Builder: binary operator
  $ graphjs mdg --no-export binopt.js
  10[#18] --< D >--> $v1[#20]
  "abc"[#19] --< D >--> $v1[#20]
  $v1[#20] -
  10[#21] --< D >--> $v2[#23]
  "abc"[#22] --< D >--> $v2[#23]
  $v2[#23] --< D >--> $v3[#25]
  true[#24] --< D >--> $v3[#25]
  $v3[#25] -
  $v4[#26] --< D >--> $v5[#28]
  10[#27] --< D >--> $v5[#28]
  $v5[#28] -
  $v6[#29] --< D >--> $v8[#31]
  $v7[#30] --< D >--> $v8[#31]
  $v8[#31] -
  $v9[#32] --< D >--> $v11[#34]
  $v10[#33] --< D >--> $v11[#34]
  $v11[#34] --< D >--> $v13[#36]
  $v12[#35] --< D >--> $v13[#36]
  $v13[#36] -

Graph.js MDG Builder: template expression
  $ graphjs mdg --no-export template.js
  `abc${10} def${true}`[#18] -
  10[#19] --< D >--> `abc${10} def${true}`[#18]
  true[#20] --< D >--> `abc${10} def${true}`[#18]
