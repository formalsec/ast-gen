// function declaration with a single parameter
function func(obj) {
  // if statement with a consequent object initialization
  if (true) {
    // var declaration with an integer literal initialization
    var x = 10;
    // let declaration with a string literal initialization
    let y = "abc";
    // const declaration with a boolean literal initialization
    const z = true;
    // variable creation with a null literal initialization
    w = null;
  }

  // object initialization with two unknown fields and two known fields
  let foo = { x, y, z, w };
}

// object initialization with four unknown fields
let bar = { x, y, z, w };
// function call of a single-parameter function with a single argument
func(bar);
// object initialization with three unknown fields and one known field
let baz = { x, y, z, w };
