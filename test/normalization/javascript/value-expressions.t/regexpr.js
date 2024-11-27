// identifiers
/^[a-zA-Z_$][a-zA-Z0-9_$]*$/;
// number literals
/^(0[xX][0-9a-fA-F]+|0[bB][01]+|0[oO][0-7]+|\d+(\.\d+)?([eE][+-]?\d+)?|\.\d+([eE][+-]?\d+)?)$/;
// string literals
/(['"])(?:(?=(\\?))\2.)*?\1/;
// comments (single-line and multi-line)
/(\/\/[^\n]*|\/\*[\s\S]*?\*\/)/;
// whitespace
/\s+/;
// braces, brackets, and parentheses
/[\(\)\[\]\{\}]/;
// global digit match
/\d+/g;
