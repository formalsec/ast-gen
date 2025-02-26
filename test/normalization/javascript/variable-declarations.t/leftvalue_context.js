// assignment with a template expression evaluation
var foo = `abc${10 + 20} def${true}`;
// assignment with a template expression evaluation (const)
const foo1 = `abc${10 + 20} def${true}`;
// assignment with a sequence expression evaluation
var foo = (10 + 20, "abc" + "def");
// assignment with a sequence expression evaluation (const)
const foo2 = (10 + 20, "abc" + "def");
// object assignment with field expressions evaluation
var foo = { bar: 10 + 20, baz: "abc" + "def" };
// object assignment with field expressions evaluation (const)
const foo3 = { bar: 10 + 20, baz: "abc" + "def" };
// array assignment with element expressions evaluation
var foo = [10 + 20, "abc" + "def"]
// array assignment with element expressions evaluation (const)
const foo4 = [10 + 20, "abc" + "def"]
// unary operator assignment with expression evaluation
var foo = -(-10);
// unary operator assignment with expression evaluation (const)
const foo5 = -(-10);
// binary operator assignment with expression evaluation
var foo = 10 + 20 + 30;
// binary operator assignment with expression evaluation (const)
const foo6 = 10 + 20 + 30;
// member lookup assignment with expression evaluation
var foo = {}.bar + {}.baz;
// member lookup assignment with expression evaluation (const)
const foo7 = {}.bar + {}.baz;
// new call assignment with expression evaluation
var foo = new bar(10 + 20, "abc" + "def");
// new call assignment with expression evaluation (const)
const foo8 = new bar(10 + 20, "abc" + "def");
// function call assignment with expression evaluation
var foo = bar(10 + 20, "abc" + "def");
// function call assignment with expression evaluation (const)
const foo9 = bar(10 + 20, "abc" + "def");
// optional function call assignment with expression evaluation
var foo = bar?.(10 + 20, "abc" + "def");
// optional function call assignment with expression evaluation (const)
const foo10 = bar?.(10 + 20, "abc" + "def");
// tag template assignment with expression evaluation
var foo = (10 + 20)`${"abc" + "def"}`;
// tag template assignment with expression evaluation (const)
const foo11 = (10 + 20)`${"abc" + "def"}`;
// dynamic import assignment with expression evaluation
var foo = import("abc" + "def");
// dynamic import assignment with expression evaluation (const)
const foo12 = import("abc" + "def");
