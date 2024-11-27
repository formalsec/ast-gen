// class declaration without an alias
var Foo = class { }
// class declaration without an alias (const)
const Foo1 = class { }
// class declaration with an alias
var Foo = class Bar { }
// class declaration with an alias (const)
const Foo2 = class Bar { }
// class declaration with an alias and constructor
var Foo = class Bar { constructor() { } }
// class declaration with an alias and a constructor (const)
const Foo3 = class Bar { constructor() { } }
