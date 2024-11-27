// object pattern a single field
var { foo } = {};
// object pattern a single field (const)
const { foo1 } = {};
// object pattern with multiple fields
var { foo, bar } = {};
// object pattern with multiple fields (const)
const { foo2, bar2 } = {};
// object pattern with nested object patterns
var { foo, bar: { baz, qux } } = {};
// object pattern with nested object patterns (const)
const { foo3, bar: { baz3, qux3 } } = {};
// object pattern with default fields
var { foo = 10, bar = "abc" } = {};
// object pattern with default fields (const)
const { foo4 = 10, bar4 = "abc" } = {};
// object pattern with default nested fields
var { foo = 10, bar: { baz = "abc" } } = {};
// object pattern with default nested fields (const)
const { foo5 = 10, bar: { baz5 = "abc" } } = {};
// object pattern with default nested object fields
var { foo = 10, bar: { baz } = { baz: "abc" } } = {};
// object pattern with default nested object fields (const)
const { foo6 = 10, bar: { baz6 } = { baz: "abc" } } = {};
// object pattern with field aliases
var { foo: a, bar: b, baz: c } = {};
// object pattern with field aliases (const)
const { foo: a7, bar: b7, baz: c7 } = {};
// object pattern with field aliases and defaults
var { foo: a = 10, bar: b = "abc" } = {};
// object pattern with field aliases and defaults (const)
const { foo: a8 = 10, bar: b8 = "abc" } = {};
// object pattern with computed keys
var { ["foo"]: a } = {};
