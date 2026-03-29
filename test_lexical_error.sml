// Lexical error test cases (tokens are intentionally invalid in selected spots)
mission lexical_error_test start
    int fuel;
    string msg;

    fuel = 10;
    msg = "nominal";

    @fuel = fuel + 1;          // Invalid token: @
    | fuel = fuel + 2;         // Invalid token: |
    msg = "Bad escape: \q";   // Invalid escape sequence in string
    $ fuel = fuel + 3;         // Invalid token: $

    transmit msg;
end
