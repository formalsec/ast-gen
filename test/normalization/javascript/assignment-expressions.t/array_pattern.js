// array pattern with a single element
[foo] = [];
// array pattern with multiple elements
[foo, bar] = [];
// array pattern with nested array patterns
[foo, [bar, baz]] = [];
// array pattern with default elements
[foo = 10, bar = "abc"] = [];
// object pattern with default nested elements
[foo = 10, [bar = "abc"]] = [];
// array pattern with default nested array elements
[foo = 10, bar = ["abc"]] = [];
// array pattern with a hole pattern
[foo,,bar] = [];
// array pattern with a trailing comma
[foo, bar,] = [];
