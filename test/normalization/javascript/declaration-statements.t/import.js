// import statement with a default specifier
import foo from "module";
// import statement with no bindings (side effects only)
import "module";
// import statement with no named specifiers
import { } from "module";
// import statement with a single named specifier
import { foo } from "module";
// import statement with multiple named specifiers
import { foo, bar, baz } from "module";
// import statement with a single renamed specifier
import { foo as bar } from "module";
// import statement with a default specifier
import { default as foo } from "module";
// import statement with default and named specifiers
import foo, { bar } from "module";
// import statement with default, named, and renamed specifiers
import foo, { bar, baz as qux } from "module";
// import statement with a batch import
import * as foo from "module";
// import statement with default and batch specifiers
import foo, * as bar from "module";
// import statement with a relative import path
import foo from "./path/to/module.js";
// import statement with an absolute import path
import foo from "/path/to/module.js";