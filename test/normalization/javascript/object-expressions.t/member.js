// object member expression with an identifier property
({}).foo;
// object member expression with nested identifier properties
({}).foo.bar;
// object member expression with a null property
({})[null];
// object member expression with a string property
({})["foo"];
// object member expression with a number property
({})[10];
// object member expression with a bigint property
({})[10n];
// object member expression with a boolean property
({})[true];
// object member expression with a computed property
({})[10 + "abc"];
// object optional member expression
({}).foo?.bar;
// object optional member expression chain
({}).foo?.bar?.baz;
