// weak variable declaration with a function property containing an object initialization
let obj = true
  ? {
      foo: function (x1) {
        let foo = { x1 };
      },
    }
  : {
      bar: function (y1, y2, y3) {
        let baz = { y1, y2, y3 };
      },
    };

// static method call on an existing identifier property (single-argument to single-parameter)
obj.foo(10);
// static method call on an existing identifier property (multi-argument to multi-parameter)
obj.bar(10, "abc", true);
// static method call with an undefined caller expression
obj.baz(10);
