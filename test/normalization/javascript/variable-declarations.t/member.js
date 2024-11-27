// member assignment with a property
var foo = ({}).foo;
// member assignment with a property (const)
const foo1 = ({}).foo;
// member assignment with nested properties
var foo = ({}).foo.bar;
// member assignment with nested properties (const)
const foo2 = ({}).foo.bar;
// optional member assignment with a property
var foo = ({}).foo?.bar;
// optional member assignment with a property (const)
const foo3 = ({}).foo?.bar;
// optional member assignment with a property chain 
var foo = ({}).foo?.bar?.baz;
// optional member assignment with a property chain (const)
const foo4 = ({}).foo?.bar?.baz;
