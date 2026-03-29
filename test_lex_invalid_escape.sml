// Single lexical error: invalid escape sequence \q
mission lex_invalid_escape_test start
    string msg;
    msg = "Bad escape: \q";
    transmit msg;
end
