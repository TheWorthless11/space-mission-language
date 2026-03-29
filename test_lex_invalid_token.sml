// Single lexical error: invalid token '@'
mission lex_invalid_token_test start
    int fuel;
    fuel = 10;
    @fuel = fuel + 1;
    transmit fuel;
end
