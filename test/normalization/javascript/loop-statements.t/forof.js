// for-of statement with an empty inline body statement
for (let foo of bar);
// for-of statement with an empty block body statement
for (let foo of bar) { }
// for-of statement with an non-empty inline body statement
for (let foo of bar) x;
// for-of statement with an non-empty block body statement
for (let foo of bar) { x; }
// for-of statement with a constant declaration
for (const foo of bar) x;
// for-of statement with an assignment
for (foo of bar) x;
// for-of statement with a nested for-of statement
for (let foo of bar) for (let baz of qux) x;
// for-of statement with an await clause
(async function () { for await (let foo of bar) x; });
// for-of statement with a computed object expression
for (var foo of bar + baz) x;
// for-of with a static property access left-handside
for (foo.bar of baz) x;
// for-of with a dynamic property access left-handside
for (foo[bar] of baz) x;
// for-of statement with an object pattern left-handside
for ({ foo, bar } of qux) x;
// for-of statement with an object pattern left-handside with default values
for ({ foo = 10, bar = { baz: "abc" } } of qux) x;
// for-of statement with an array pattern left-handside
for ([foo, bar] of qux) x;
// for-of statement with an array pattern left-handside with default values
for ([foo = 10, bar = ["abc", true]] of qux) x;
