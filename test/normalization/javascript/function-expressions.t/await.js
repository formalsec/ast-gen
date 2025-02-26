// await call with no arguments
async () => { await foo(); }
// await call with a single argument
async () => { await foo(10); }
// await call with multiple arguments
async () => { await foo(10, "abc", true); }
// await call with an expression argument
async () => { await foo(10 + "abc"); }
// await call with a computed callee
async () => { await (10 + "abc")(true); }
// await call nested within another call
async () => { bar(await foo()); }
