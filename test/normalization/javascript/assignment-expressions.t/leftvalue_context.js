// assignment with a template expression evaluation
foo = `abc${10 + 20} def${true}`;
// assignment with a sequence expression evaluation
foo = (10 + 20, "abc" + "def");
// object assignment with field expressions evaluation
foo = { bar: 10 + 20, baz: "abc" + "def" };
// array assignment with element expressions evaluation
foo = [10 + 20, "abc" + "def"]
// unary operator assignment with expression evaluation
foo = -(-10);
// binary operator assignment with expression evaluation
foo = 10 + 20 + 30;
// member lookup assignment with expression evaluation
foo = {}.bar + {}.baz;
// new call assignment with expression evaluation
foo = new bar(10 + 20, "abc" + "def");
// function call assignment with expression evaluation
foo = bar(10 + 20, "abc" + "def");
// optional call assignment with expression evaluation
foo = bar?.(10 + 20, "abc" + "def");
// tag template assignment with expression evaluation
foo = (10 + 20)`${"abc" + "def"}`;
// dynamic import assignment with expression evaluation
foo = import("abc" + "def");
