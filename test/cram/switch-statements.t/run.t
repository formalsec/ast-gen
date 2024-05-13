  $ dune exec ast_gen -f input-code-1.js
  const v1;
  v1 = 23 + 19;
  switch (v1) {
     case 42: 
        var x;
        const v2;
        v2 = alert("yes!");
        v2;
        break;
  
     default: 
        const v3;
        v3 = alert("huh?");
        v3;
  
  }
  
  $ dune exec ast_gen -f input-code-2.js
  const v1;
  v1 = 23 + 19;
  switch (v1) {
     case 42: 
        var x;
        const v2;
        v2 = alert("yes!");
        v2;
  
     default: 
        const v3;
        v3 = alert("huh?");
        v3;
  
  }
  
  $ dune exec ast_gen -f input-code-3.js
  const v1;
  v1 = 23 + 19;
  switch (v1) {
     default: 
        const v2;
        v2 = alert("huh?");
        v2;
        break;
  
     case 42: 
        var x;
        const v3;
        v3 = alert("yes!");
        v3;
        break;
  
  }
  
  $ dune exec ast_gen -f input-code-4.js
  switch (42) {
  }
  
  $ dune exec ast_gen -f input-code-5.js
  switch (42) {
     case 23: 
  
  }
  
  $ dune exec ast_gen -f input-code-6.js
  switch (x) {
     case 0: 
        const v1;
        v1 = alert(0);
        v1;
        break;
  
     case 1: 
        const v2;
        v2 = alert(1);
        v2;
  
  }
  
  $ dune exec ast_gen -f input-code-7.js
  switch (x) {
     case 0: 
        const v1;
        v1 = alert(0);
        v1;
  
     case 1: 
        const v2;
        v2 = alert(1);
        v2;
  
  }
  
  $ dune exec ast_gen -f input-code-8.js
  switch (x) {
     case 0: 
        const v1;
        v1 = alert(0);
        v1;
  
     case 1: 
        const v2;
        v2 = alert(1);
        v2;
  
     default: 
        const v3;
        v3 = -1;
        const v4;
        v4 = alert(v3);
        v4;
  
  }
  
  $ dune exec ast_gen -f input-code-9.js
  switch (x) {
     case 0: 
        const v1;
        v1 = console.log(0);
        v1;
  
     case 1: 
        const v2;
        v2 = console.log(1);
        v2;
        break;
  
     case 2: 
        const v3;
        v3 = console.log(2);
        v3;
  
     default: 
        const v4;
        v4 = -1;
        const v5;
        v5 = console.log(v4);
        v5;
  
  }
  
  $ dune exec ast_gen -f input-code-10.js
  const v1;
  v1 = 2 + 3;
  const v2;
  v2 = 1 + 4;
  switch (v1) {
     case v2: 
        const v3;
        v3 = console.log("5");
        v3;
        break;
  
     case 6: 
        const v4;
        v4 = console.log("6");
        v4;
        break;
  
     default: 
        const v5;
        v5 = console.log("huh?");
        v5;
        break;
  
  }
  
