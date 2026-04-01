// Special feature 6: lexical diagnostic (invalid string escape).
mission lex_escape_small start
    string msg;

    msg = "bad\qescape";
    transmit msg;
end