// Syntax error test cases (lexically valid, grammatically invalid in selected spots)
mission syntax_error_test start
    int fuel;
    string status;

    fuel = 10;
    status = "ok";

    fuel = ;                   // Syntax error: missing expression after ASSIGN
    transmit ;                 // Syntax error: missing expression after TRANSMIT

    check (fuel > 0) start
        transmit "running";
    otherwise start            // Syntax error: missing END before OTHERWISE
        transmit "fallback";
    end
end
