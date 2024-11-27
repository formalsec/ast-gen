// function expression with an empty body
(function () { });
// function expression with a single statement body
(function () { let foo = 10; });
// function expression with a multi statement body
(function () { let foo = 10; let bar = "abc"; });
// function expression with a non-empty body and normal parameters
(function (foo) { let bar = "abc"; });
// function expression with a non-empty body and default parameters
(function (foo = 10) { let bar = "abc"; });
