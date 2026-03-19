// Comprehensive SML test: declarations, assignments, expressions,
// check/otherwise, orbit, function declaration/call, and ignite usage.
module int adjust(int value, int delta) start
    return value + delta;
end

mission all_features_test start
    // Declarations
    int fuel;
    int reserve;
    float speed;
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

    // Built-in ignite usage
    fuel = ignite(reserve);

    transmit fuel;
end
