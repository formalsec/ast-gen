// for-in statement with an empty inline body statement
for (let foo in bar);
// for-in statement with an empty block body statement
for (let foo in bar) { }
// for-in statement with an non-empty inline body statement
for (let foo in bar) x;
// for-in statement with an non-empty block body statement
for (let foo in bar) { x; }
// for-in statement with a constant declaration
for (const foo in bar) x;
// for-in statement with an assignment
for (foo in bar) x;
// for-in statement with a nested for-in statement
for (let foo in bar) for (let baz in qux) x;
// for-in statement with a computed object expression
for (var foo in bar + baz) x;
// for-in with a static property access left-handside
for (foo.bar in baz) x;
// for-in with a dynamic property access left-handside
for (foo[bar] in baz) x;
// for-in statement with an object pattern left-handside
for ({ foo, bar } of qux) x;
// for-in statement with an object pattern left-handside with default values
for ({ foo = 10, bar = { baz: "abc" } } of qux) x;
// for-in statement with an array pattern left-handside
for ([foo, bar] of qux) x;
// for-in statement with an array pattern left-handside with default values
for ([foo = 10, bar = ["abc", true]] of qux) x;