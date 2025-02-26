// array pattern no elements
var [] = [];
// array pattern no elements (const)
const [] = [];
// array pattern a single element
var [foo] = [];
// array pattern a single element (const)
const [foo1] = [];
// array pattern with multiple elements
var [foo, bar] = [];
// array pattern with multiple elements (const)
const [foo2, bar2] = [];
// array pattern with nested array patterns
var [foo, [bar, baz]] = [];
// array pattern with nested array patterns (const)
const [foo3, [bar3, baz3]] = [];
// array pattern with default elements
var [foo = 10, bar = "abc"] = [];
// array pattern with default elements (const)
const [foo4 = 10, bar4 = "abc"] = [];
// object pattern with default nested elements
var [foo = 10, [bar = "abc"]] = [];
// object pattern with default nested elements (const)
const [foo5 = 10, [bar5 = "abc"]] = [];
// array pattern with default nested array elements
var [foo = 10, bar = ["abc"]] = [];
// array pattern with default nested array elements (const)
const [foo6 = 10, bar6 = ["abc"]] = [];
// array pattern with a hole pattern
var [foo, , bar] = [];
// array pattern with a hole pattern (const)
const [foo, , bar] = [];
// array pattern with a trailing comma
var [foo, bar,] = [];
// array pattern with a trailing comma(const)
const [foo, bar,] = [];
