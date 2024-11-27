// function expression with no parameters
(function () { });
// function expression with a single parameter
(function (foo) { });
// function expression with multiple parameters
(function (foo, bar, baz) { });
// function expression with multiple parameters with default values
(function (foo = 10, bar = "abc") { });
// function expression with an object pattern parameter
(function ({ foo, bar: { baz } }) { });
// function expression with an object pattern parameter with default values
(function ({ foo = 10, bar: { baz } = { baz: "abc" } }) { });
// function expression with an array pattern parameter
(function ([foo, [bar, baz]]) { });
// function expression with an array pattern parameter with default values
(function ([foo = 10, [bar, baz] = ["abc", true]]) { });
