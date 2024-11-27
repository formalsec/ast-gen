// default export statement with a literal expression
// export default 10;
// default export statement with an identifier expression
// export default foo1;
// default export statement with a computed expression
// export default foo2 + bar;
// default export statement with an anonymous function declaration
// export default function () { };
// default export statement with a named function declaration
// export default function foo3() { };
// default export statement with an anonymous class declaration
// export default class { };
// default export statement with a named class declaration
// export default class Foo4 { };

// export statement with a single uninitialized variable declaration 
export var foo5;
// export statement with a single initialized variable declaration 
export var foo6 = 10;
// export statement with multiple variable declaration 
export var foo7 = 10, bar7;
// export statement with an object pattern 
export var { foo8, bar8 } = { foo8: 10, bar8: "abc" };
// export statement with an array pattern 
export var [foo9, bar9] = [10, "abc"];
// export statement with a function declaration 
export function foo10() { };
// export statement with a class declaration 
export class Foo11 { };

// export statement with no named specifiers
export { };
// export statement with a single named specifier
export { foo12 };
// export statement with multiple named specifiers
export { foo13, bar13, baz13 };
// export statement with a single renamed specifier
export { foo14 as bar14 };
// export statement with named, and renamed specifiers
export { foo15, bar15 as baz15 };
// export statement with a default specifier
// export { foo16 as default };


// aggregate export statement with no named specifiers
export { } from "module";
// aggregate export statement with a single named specifier
export { foo17 } from "module";
// aggregate export statement with multiple named specifiers
export { foo18, bar18, baz18 } from "module";
// aggregate export statement with a single renamed specifier
export { foo19 as bar19 } from "module";
// aggregate export statement with named, and renamed specifiers
export { foo20, bar20 as baz20 } from "module";
// aggregate export statement with a default specifier
export { foo21 as default } from "module";
// aggregate default export statement
// export { default } from "module";
// export default export statement with a renamed specifier
export { default as foo22 } from "module";
// aggregate export statement with a batch export
export * from "module";
// aggregate export statement with a named batch export
export * as foo23 from "module";
