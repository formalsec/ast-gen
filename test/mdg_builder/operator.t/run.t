Graph.js MDG Builder: unary operator
  $ graphjs mdg --no-export unopt.js
  10[#7] --< D >--> $v1[#8]
  $v1[#8] -
  10[#9] --< D >--> $v2[#10]
  $v2[#10] --< D >--> $v3[#11]
  $v3[#11] -
  $v4[#12] --< D >--> $v5[#13]
  $v5[#13] -
  $v6[#14] --< D >--> $v7[#15]
  $v7[#15] --< D >--> $v8[#16]
  $v8[#16] -

Graph.js MDG Builder: binary operator
  $ graphjs mdg --no-export binopt.js
  10[#7] --< D >--> $v1[#9]
  "abc"[#8] --< D >--> $v1[#9]
  $v1[#9] -
  10[#10] --< D >--> $v2[#12]
  "abc"[#11] --< D >--> $v2[#12]
  $v2[#12] --< D >--> $v3[#14]
  true[#13] --< D >--> $v3[#14]
  $v3[#14] -
  $v4[#15] --< D >--> $v5[#17]
  10[#16] --< D >--> $v5[#17]
  $v5[#17] -
  $v6[#18] --< D >--> $v8[#20]
  $v7[#19] --< D >--> $v8[#20]
  $v8[#20] -
  $v9[#21] --< D >--> $v11[#23]
  $v10[#22] --< D >--> $v11[#23]
  $v11[#23] --< D >--> $v13[#25]
  $v12[#24] --< D >--> $v13[#25]
  $v13[#25] -

Graph.js MDG Builder: template expression
  $ graphjs mdg --no-export template.js
  `abc${10} def${true}`[#7] -
  10[#8] --< D >--> `abc${10} def${true}`[#7]
  true[#9] --< D >--> `abc${10} def${true}`[#7]
