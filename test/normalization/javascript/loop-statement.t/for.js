// for statement with an empty inline body statement
for (let i = 10; i < 20; i++);
// for statement with an empty block body statement
for (let i = 10; i < 20; i++) { }
// for statement with an non-empty inline body statement
for (let i = 10; i < 20; i++) x;
// for statement with an non-empty block body statement
for (let i = 10; i < 20; i++) { x; }
// for statement with a constant initializer
for (const i = 10; i < 20; i++) x;
// for statement with an assignment initializer
for (i = 10; i < 20; i++) x;
// for statement with a missing initializer
for (; i < 20; i++) x;
// for statement with a missing test expression
for (let i = 10; ; i++) x;
// for statement with a missing update expression
for (let i = 10; i < 20;) x;
// for statement with all components missing
for (; ;) x;
// for statement with a nested for statement
for (let i = 10; i < 20; i++) for (j = i; j < 20; j++) x;
// for statement with a multi-declaration initializer and update expression
for (let i = 10, j = 20; i < 20; i++, j++) x;
// for statement with a computed initializer
for (let i = 10 + 20; i < 30; i++) x;
// for statement with a computed test expression
for (let i = 10; i > 10 && i < 20; i++) x;
