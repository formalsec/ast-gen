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
