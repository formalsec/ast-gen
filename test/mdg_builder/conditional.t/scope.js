// object initialization with four unknown fields
let foo = { x, y, z, w };

// let declaration with a string literal initialization
let y = "abc";

// if statement with a consequent object initialization
if (true) {
  // var declaration with an integer literal initialization
  var x = 10;
  // let declaration with a string literal initialization
  let y = "def";
  // const declaration with a boolean literal initialization
  const z = true;
  // variable creation with a null literal initialization
  w = null;
}

// object initialization with one unknown field and three known fields
let bar = { x, y, z, w };
