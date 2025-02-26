Flag for always generating fresh variables
  $ graphjs parse always_fresh.js
  foo = -10;
  foo = 10 + 20;
  foo = bar.baz;
  foo = bar(10, "abc");
  foo = function (x, y, z) {
    
  }
  let $v1 = {};
  for (let foo in $v1) {
    
  }
  for (let foo of bar) {
    
  }
  try {
    
  } catch (foo) {
    
  }

  $ graphjs parse always_fresh.js --always-fresh
  let $v1 = -10;
  foo = $v1;
  let $v2 = 10 + 20;
  foo = $v2;
  let $v3 = bar.baz;
  foo = $v3;
  let $v4 = bar(10, "abc");
  foo = $v4;
  let $v5 = function (x, y, z) {
    
  }
  foo = $v5;
  let $v6 = {};
  for (let foo in $v6) {
    
  }
  for (let foo of bar) {
    
  }
  try {
    
  } catch (foo) {
    
  }



Flag for disabling function hoisting
  $ graphjs parse disable_hoisting.js
  let foo = function () {
    
  }
  function bar() {
    
  }
  $ graphjs parse disable_hoisting.js --disable-hoisting
  let foo = function () {
    
  }
  var bar = function () {
    
  }
