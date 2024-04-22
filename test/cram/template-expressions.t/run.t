  $ dune exec ast_gen -f input-code-1.js
  const x;
  x = `string`;
  
  $ dune exec ast_gen -f input-code-2.js
  const x;
  x = `string` + `concat`;
  
  $ dune exec ast_gen -f input-code-3.js
  const x;
  x = `template ${expr}`;
  
  $ dune exec ast_gen -f input-code-4.js
  const x;
  x = `string`;
  const temp;
  const v1;
  v1 = x + 2;
  temp = `head template ${v1} end tail`;
  
  $ dune exec ast_gen -f input-code-5.js
  const tag;
  tag = function (strings, personExp, ageExp) {
     let ageStr;
     const v1;
     v1 = ageExp > 99;
     ageStr = (v1) ? 'centenarian' : 'youngster';
     const v2;
     v2 = strings[0];
     const v3;
     v3 = strings[1];
     const v4;
     v4 = strings[2];
     return `${v2}${personExp}${v3}${ageStr}${v4}`;
  }
  const firstName;
  firstName = 'Mike';
  const lastName;
  lastName = 'Wheeler';
  const age;
  age = 28;
  const output;
  const v5;
  v5 = firstName + lastName;
  output = tag`${v5} is a ${age}.`;
  
