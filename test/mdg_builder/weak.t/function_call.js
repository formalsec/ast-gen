// weak function assignment with an object initialization
let foo = true
  ? function (x1) {
      let bar = { x1 };
    }
  : function (y1, y2, y3) {
      let baz = { y1, y2, y3 };
    };

// function call on a weak function identifier (single-argument)
foo(10);
// function call on a weak function identifier (multi-argument)
foo(10, "abc", true);
