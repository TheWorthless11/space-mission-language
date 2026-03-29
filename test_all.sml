// Comprehensive SML test: declarations, assignments, expressions,
// check/otherwise, orbit, function declaration/call, built-ins,
// recursive call, and zero-argument function call.
module int adjust(int value, int delta) start
    return value + delta;
end

module int ping() start
    return 1;
end

module int countdown(int n) start
    check (n == 0) start
        return 0;
    end otherwise start
        return countdown(n - 1);
    end
end

mission all_features_test start
    // Declarations
    int fuel;
    int reserve;
    int signal;
    float speed;
    float pct;
    string status;
    flag ready;

    // Assignments and expressions
    fuel = 100;
    reserve = 20;
    speed = 10.5;
    status = "prepare";
    ready = true;

    fuel = fuel - reserve;
    speed = (speed * 2.0) / 3.0;
    ready = (fuel > reserve) || ready;

    // If/else
    check (ready) start
        transmit status;
    end otherwise start
        transmit "hold";
    end

    // Loop with valid flag condition
    orbit (ready) start
        fuel = fuel - 1;
        transmit fuel;
    end

    // Function call
    reserve = adjust(reserve, 5);
    signal = ping();
    reserve = countdown(3);

    // Built-in function usage
    fuel = ignite(reserve);
    pct = percent(30, 60);

    transmit fuel;
    transmit signal;
    transmit pct;
end
