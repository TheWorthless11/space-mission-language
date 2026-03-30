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
    // Declarations: plain declarations + declaration with initializer
    int fuel;
    int reserve;
    int signal;
    int steps = 3;
    float speed;
    float pct;
    float mixed;
    string status;
    flag ready;
    flag lessCheck;
    flag notEqCheck;
    flag leCheck;
    flag geCheck;

    // Basic assignments and literals (true + false)
    fuel = 100;
    reserve = 20;
    speed = 10.5;
    status = "prepare";
    ready = false;
    ready = true;

    // Arithmetic expressions + unary minus
    fuel = fuel - reserve;
    speed = (speed * 2.0) / 3.0;
    speed = -speed;

    // Relational operators coverage: <, !=, <=, >= (and > already used later)
    lessCheck = reserve < fuel;
    notEqCheck = fuel != reserve;
    leCheck = reserve <= fuel;
    geCheck = fuel >= reserve;

    // Logical operators coverage: OR, AND, NOT
    ready = (fuel > reserve) || ready;
    ready = lessCheck && notEqCheck;
    ready = !false;

    // If/else
    check (ready) start
        transmit status;
    end otherwise start
        transmit "hold";
    end

    // If without otherwise
    check (geCheck) start
        transmit "ge branch";
    end

    // Loop with valid flag condition
    // Keep updating ready from a comparison so the condition remains type-correct.
    ready = true;
    orbit (ready) start
        fuel = fuel - 1;
        transmit fuel;
        ready = fuel > reserve;
    end

    // Function calls: normal, zero-arg, recursive
    reserve = adjust(reserve, 5);
    signal = ping();
    reserve = countdown(3);

    // Built-in function usage
    fuel = ignite(reserve);
    pct = percent(30, 60);

    // Implicit conversion coverage: int -> float
    mixed = fuel;

    // Use initialized declaration variable in expression
    fuel = fuel + steps;

    transmit fuel;
    transmit signal;
    transmit pct;
    transmit mixed;
end
