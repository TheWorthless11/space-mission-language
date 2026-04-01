// Special feature 7: parser recovery after a malformed statement.
mission parser_recovery_small start
    int x;

    x = ;
    x = 42;
    transmit x;
end