  $ dune exec ast_gen -f input-code-1.js
  const v1;
  v1 = 23 + 19;
  switch (v1) {
     case 42: 
        let v2;
        v2 = alert("yes!");
        v2;
        break;
  
     default: 
        let v3;
        v3 = alert("huh?");
        v3;
  
  }
  
  $ dune exec ast_gen -f input-code-2.js
  const v1;
  v1 = 23 + 19;
  switch (v1) {
     case 42: 
        let v2;
        v2 = alert("yes!");
        v2;
  
     default: 
        let v3;
        v3 = alert("huh?");
        v3;
  
  }
  
  $ dune exec ast_gen -f input-code-3.js
  const v1;
  v1 = 23 + 19;
  switch (v1) {
     default: 
        let v2;
        v2 = alert("huh?");
        v2;
        break;
  
     case 42: 
        let v3;
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
        let v1;
        v1 = alert(0);
        v1;
        break;
  
     case 1: 
        let v2;
        v2 = alert(1);
        v2;
  
  }
  
  $ dune exec ast_gen -f input-code-7.js
  switch (x) {
     case 0: 
        let v1;
        v1 = alert(0);
        v1;
  
     case 1: 
        let v2;
        v2 = alert(1);
        v2;
  
  }
  
  $ dune exec ast_gen -f input-code-8.js
  switch (x) {
     case 0: 
        let v1;
        v1 = alert(0);
        v1;
  
     case 1: 
        let v2;
        v2 = alert(1);
        v2;
  
     default: 
        const v3;
        v3 = -1;
        let v4;
        v4 = alert(v3);
        v4;
  
  }
  
  $ dune exec ast_gen -f input-code-9.js
  switch (x) {
     case 0: 
        let v1;
        v1 = console.log;
        let v2;
        v2 = v1(0);
        v2;
  
     case 1: 
        let v3;
        v3 = console.log;
        let v4;
        v4 = v3(1);
        v4;
        break;
  
     case 2: 
        let v5;
        v5 = console.log;
        let v6;
        v6 = v5(2);
        v6;
  
     default: 
        let v7;
        v7 = console.log;
        const v8;
        v8 = -1;
        let v9;
        v9 = v7(v8);
        v9;
  
  }
  
  $ dune exec ast_gen -f input-code-10.js
  const v1;
  v1 = 2 + 3;
  const v2;
  v2 = 1 + 4;
  switch (v1) {
     case v2: 
        let v3;
        v3 = console.log;
        let v4;
        v4 = v3("5");
        v4;
        break;
  
     case 6: 
        let v5;
        v5 = console.log;
        let v6;
        v6 = v5("6");
        v6;
        break;
  
     default: 
        let v7;
        v7 = console.log;
        let v8;
        v8 = v7("huh?");
        v8;
        break;
  
  }
  
