// break statement
while (true) break;
// break statement with label
foo: while (true) break foo;
// break statement with a double label
foo: bar: while (true) break foo;
// continue statement
while (true) continue;
// continue statement with a double label
foo: bar: while (true) continue foo;
