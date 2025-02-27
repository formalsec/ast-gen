// destructuring object assignment with default fields
var { foo = 10, bar = "abc" } = {};
// destructuring array assignment with default elements
var [foo = 10, bar = "abc"] = [];
// for-in statement with an object pattern left-handside with default values
for ({ foo = 10, bar = { baz: "abc" } } in qux) { };
// for-of statement with an object pattern left-handside with default values
for ({ foo = 10, bar = { baz: "abc" } } of qux) { };
// function expression with multiple parameters with default values
(function (foo = 10, bar = "abc") { });
// arrow function with multiple parameters with default values
(foo = 10, bar = "abc") => { };
