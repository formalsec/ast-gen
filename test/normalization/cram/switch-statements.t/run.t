  $ graphjs2 input-code-1.js -o out; cat out/code/input-code-1.js; echo; rm -fr out;
  let v1;
  v1 = 23 + 19;
  switch (v1) {
     case 42: 
        var x;
        let v2;
        v2 = alert("yes!");
        v2;
        break;
  
     default: 
        let v3;
        v3 = alert("huh?");
        v3;
  
  }
  
  $ graphjs2 input-code-2.js -o out; cat out/code/input-code-2.js; echo; rm -fr out;
  let v1;
  v1 = 23 + 19;
  switch (v1) {
     case 42: 
        var x;
        let v2;
        v2 = alert("yes!");
        v2;
  
     default: 
        let v3;
        v3 = alert("huh?");
        v3;
  
  }
  
  $ graphjs2 input-code-3.js -o out; cat out/code/input-code-3.js; echo; rm -fr out;
  let v1;
  v1 = 23 + 19;
  switch (v1) {
     default: 
        let v2;
        v2 = alert("huh?");
        v2;
        break;
  
     case 42: 
        var x;
        let v3;
        v3 = alert("yes!");
        v3;
        break;
  
  }
  
  $ graphjs2 input-code-4.js -o out; cat out/code/input-code-4.js; echo; rm -fr out;
  switch (42) {
  }
  
  $ graphjs2 input-code-5.js -o out; cat out/code/input-code-5.js; echo; rm -fr out;
  switch (42) {
     case 23: 
  
  }
  
  $ graphjs2 input-code-6.js -o out; cat out/code/input-code-6.js; echo; rm -fr out;
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
  
  $ graphjs2 input-code-7.js -o out; cat out/code/input-code-7.js; echo; rm -fr out;
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
  
  $ graphjs2 input-code-8.js -o out; cat out/code/input-code-8.js; echo; rm -fr out;
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
        let v3;
        v3 = -1;
        let v4;
        v4 = alert(v3);
        v4;
  
  }
  
  $ graphjs2 input-code-9.js -o out; cat out/code/input-code-9.js; echo; rm -fr out;
  switch (x) {
     case 0: 
        let v1;
        v1 = console.log(0);
        v1;
  
     case 1: 
        let v2;
        v2 = console.log(1);
        v2;
        break;
  
     case 2: 
        let v3;
        v3 = console.log(2);
        v3;
  
     default: 
        let v4;
        v4 = -1;
        let v5;
        v5 = console.log(v4);
        v5;
  
  }
  
  $ graphjs2 input-code-10.js -o out; cat out/code/input-code-10.js; echo; rm -fr out;
  let v1;
  v1 = 2 + 3;
  let v2;
  v2 = 1 + 4;
  switch (v1) {
     case v2: 
        let v3;
        v3 = console.log("5");
        v3;
        break;
  
     case 6: 
        let v4;
        v4 = console.log("6");
        v4;
        break;
  
     default: 
        let v5;
        v5 = console.log("huh?");
        v5;
        break;
  
  }
  
