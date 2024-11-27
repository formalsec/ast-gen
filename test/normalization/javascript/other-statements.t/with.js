// with statement with an empty inline body statement
with (foo);
// with statement with an empty block body statement
with (foo) { }
// with statement with a non-empty inline body statement
with (foo) x;
// with statement with a non-empty block body statement
with (foo) { x; }
// with statement with a nested with statement
with (foo) with (bar) x;
// with statement with a computed expression
with (foo[bar]) x;
