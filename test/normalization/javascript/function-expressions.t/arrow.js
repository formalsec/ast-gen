// arrow function with no parameters
() => { };
// arrow function with a single parameter
(foo) => { }
// arrow function with multiple parameters
(foo, bar, baz) => { };
// arrow function with multiple parameters with default values
(foo = 10, bar = "abc") => { };
// arrow function with an object pattern parameter
({ foo, bar: { baz } }) => { };
// arrow function with an object pattern parameter with default values
({ foo = 10, bar: { baz } = { baz: "abc" } }) => { };
// arrow function with an array pattern parameter
([foo, [bar, baz]]) => { };
// arrow function with an array pattern parameter with default values
([foo = 10, bar = ["abc"]]) => { };
// arrow function with a single statement body
() => { let foo = 10; };
// arrow function with a multi statement body
() => { let foo = 10; let bar = "abc"; };
// arrow function with an expression body
() => 10 + "abc";
// async arrow function
async () => { };
// nested arrow functions
foo => bar => foo + bar;
