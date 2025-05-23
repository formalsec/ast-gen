Graph.js MDG Builder: unary operator
  $ graphjs mdg --no-export unopt.js
  10[#9] --< D >--> $v1[#10]
  $v1[#10] -
  10[#11] --< D >--> $v2[#12]
  $v2[#12] --< D >--> $v3[#13]
  $v3[#13] -
  $v4[#14] --< D >--> $v5[#15]
  $v5[#15] -
  $v6[#16] --< D >--> $v7[#17]
  $v7[#17] --< D >--> $v8[#18]
  $v8[#18] -

Graph.js MDG Builder: binary operator
  $ graphjs mdg --no-export binopt.js
  10[#9] --< D >--> $v1[#11]
  "abc"[#10] --< D >--> $v1[#11]
  $v1[#11] -
  10[#12] --< D >--> $v2[#14]
  "abc"[#13] --< D >--> $v2[#14]
  $v2[#14] --< D >--> $v3[#16]
  true[#15] --< D >--> $v3[#16]
  $v3[#16] -
  $v4[#17] --< D >--> $v5[#19]
  10[#18] --< D >--> $v5[#19]
  $v5[#19] -
  $v6[#20] --< D >--> $v8[#22]
  $v7[#21] --< D >--> $v8[#22]
  $v8[#22] -
  $v9[#23] --< D >--> $v11[#25]
  $v10[#24] --< D >--> $v11[#25]
  $v11[#25] --< D >--> $v13[#27]
  $v12[#26] --< D >--> $v13[#27]
  $v13[#27] -

Graph.js MDG Builder: template expression
  $ graphjs mdg --no-export template.js
  `abc${10} def${true}`[#9] -
  10[#10] --< D >--> `abc${10} def${true}`[#9]
  true[#11] --< D >--> `abc${10} def${true}`[#9]
