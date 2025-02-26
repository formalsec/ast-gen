// object pattern with no fields
({} = {});
// object pattern with a single field
({ foo } = {});
// object pattern with multiple fields
({ foo, bar } = {});
// object pattern with nested object patterns
({ foo, bar: { baz, qux } } = {});
// object pattern with default fields
({ foo = 10, bar = "abc" } = {});
// object pattern with default nested fields
({ foo = 10, bar: { baz = "abc" } } = {});
// object pattern with default nested object fields
({ foo = 10, bar: { baz } = { baz: "abc" } } = {});
// object pattern with field aliases
({ foo: a, bar: b, baz: c } = {});
// object pattern with field aliases and defaults
({ foo: a = 10, bar: b = "abc" } = {});
// object pattern with computed keys
({ [10 + "abc"]: a } = {});
