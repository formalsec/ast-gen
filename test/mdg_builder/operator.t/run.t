Graph.js MDG Builder: unary operator
  $ graphjs mdg --no-export unopt.js
  10[#19] --< D >--> $v1[#20]
  $v1[#20] -
  10[#21] --< D >--> $v2[#22]
  $v2[#22] --< D >--> $v3[#23]
  $v3[#23] -
  $v4[#24] --< D >--> $v5[#25]
  $v5[#25] -
  $v6[#26] --< D >--> $v7[#27]
  $v7[#27] --< D >--> $v8[#28]
  $v8[#28] -

Graph.js MDG Builder: binary operator
  $ graphjs mdg --no-export binopt.js
  10[#19] --< D >--> $v1[#21]
  "abc"[#20] --< D >--> $v1[#21]
  $v1[#21] -
  10[#22] --< D >--> $v2[#24]
  "abc"[#23] --< D >--> $v2[#24]
  $v2[#24] --< D >--> $v3[#26]
  true[#25] --< D >--> $v3[#26]
  $v3[#26] -
  $v4[#27] --< D >--> $v5[#29]
  10[#28] --< D >--> $v5[#29]
  $v5[#29] -
  $v6[#30] --< D >--> $v8[#32]
  $v7[#31] --< D >--> $v8[#32]
  $v8[#32] -
  $v9[#33] --< D >--> $v11[#35]
  $v10[#34] --< D >--> $v11[#35]
  $v11[#35] --< D >--> $v13[#37]
  $v12[#36] --< D >--> $v13[#37]
  $v13[#37] -

Graph.js MDG Builder: template expression
  $ graphjs mdg --no-export template.js
  `abc${10} def${true}`[#19] -
  10[#20] --< D >--> `abc${10} def${true}`[#19]
  true[#21] --< D >--> `abc${10} def${true}`[#19]
