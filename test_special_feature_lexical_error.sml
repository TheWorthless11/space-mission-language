// Special feature 6: lexical diagnostic (invalid token).
mission lexical_error_small start
    int x;

    x = 10;
    @
    transmit x;
end