// Single syntax error: missing END before OTHERWISE
mission syntax_missing_end_test start
    flag ready;
    ready = true;

    check (ready) start
        transmit "ok";
    otherwise start
        transmit "fallback";
    end
end
