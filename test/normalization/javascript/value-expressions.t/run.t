  $ graphjs parse null.js
  null;

  $ graphjs parse string.js
  "";
  'abc';
  "def";
  'abc \' def';
  "abc \" def";
  "Line\nBreak";
  "\x41";
  "\u0041";
  "😊";

  $ graphjs parse number.js
  10;
  10.1;
  5.;
  .5;
  1.01e1;
  1.01e+1;
  1.01e-1;
  0b1010;
  0o12;
  0xA;
  1_000_000;
  NaN;
  Infinity;

  $ graphjs parse bigint.js
  10n;
  0b1010n;
  0o12n;
  0xAn;
  1_000_000n;

  $ graphjs parse boolean.js
  true;
  false;

  $ graphjs parse regexpr.js
  /^$/;
  /^[a-zA-Z_$][a-zA-Z0-9_$]*$/;
  /^(0[xX][0-9a-fA-F]+|0[bB][01]+|0[oO][0-7]+|\d+(\.\d+)?([eE][+-]?\d+)?|\.\d+([eE][+-]?\d+)?)$/;
  /(['"])(?:(?=(\\?))\2.)*?\1/;
  /(\/\/[^\n]*|\/\*[\s\S]*?\*\/)/;
  /\s+/;
  /[\(\)\[\]\{\}]/;
  /\d+/g;
  /\\/g;
  /\d{2}/;
  /\w+/;
  /^abc/;
  /abc$/;
  /\bword\b/;
  /(?:abc|def)/;
  /(?<digit>\d+)/;
  /(?=\d)/;
  /(?!\d)/;

  $ graphjs parse template.js
  `abc`;
  `abc
   def`;
  `${""}`;
  `abc${10} def`;
  `abc${10} def${true}`;
  `${foo}`;
  `\`escaped backtick\``;
  `abc\ndef`;
  `${`abc ${10}`}`;

  $ graphjs parse reference.js
  foo;
  this;
