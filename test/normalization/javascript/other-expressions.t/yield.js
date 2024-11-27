// yield expression without an argument
(function* () { yield; });
// yield expression with an argument
(function* () { yield 10; });
// delegate yield expression with a literal argument
(function* () { yield* 10; });
// delegate yield expression with with a generator function call
(function* () { yield* (function* () { yield 10 })(); });
