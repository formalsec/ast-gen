// assignment expression with an unary operator
foo = -10;
// assignment expression with a binary operator
foo = 10 + 20;
// assignment expression with an object member
foo = bar.baz;
// assignment expression with a function call
foo = bar(10, "abc");

// assignment expression with a function expression with multiple parameters
foo = function (x, y, z) { }
// for-of statement with an empty inline body statement
for (let foo in {});
// for-of statement with an empty inline body statement
for (let foo of bar);
// try-catch statement with a catch parameter
try { } catch (foo) { };