// object expression with no fields
({});
// object expression a single field
({ foo: 10 });
// object expression with multiple fields
({ foo: 10, bar: "abc", baz: true });
// object expression with nested object fields
({ foo: 10, bar: { baz: "abc", qux: true } });
// object expression with literal field keys
({ "foo": 10, 20: "abc", 30n: true });
// object expression with a computed field key
({ [10 + "abc"]: true });
