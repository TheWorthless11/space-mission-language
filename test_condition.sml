mission condition_test start
    int altitude;
    flag safe;

    altitude = 100;
    safe = true;

    // Valid if/else condition (flag)
    check (safe) start
        transmit "safe orbit";
    end otherwise start
        transmit "unsafe orbit";
    end

    // Invalid condition type (int instead of flag)
    check (altitude) start
        transmit "this should report condition type error";
    end
end
