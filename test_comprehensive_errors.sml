// Comprehensive semantic/type/scope/function error test for SML
// Each case is intentionally wrong and should trigger compiler errors.

module int addTwo(int a, int b) start
    return a + b;
end

// ERROR: function with missing return
module int noReturn(int x) start
    int y;
    y = x + 1;
end

// ERROR: function with inconsistent return types
module int mixedReturn(flag useInt) start
    check (useInt) start
        return 1;
    end otherwise start
        return "oops";
    end
end

mission comprehensive_error_test start
    int x;
    int result;
    float f;
    flag cond;

    x = 1;
    cond = true;

    // ERROR: use of undeclared variable
    unknownValue = 10;

    // ERROR: redeclaration of variable in same scope
    int x;

    // ERROR: assigning wrong type (int = string)
    x = "launch";

    // ERROR: invalid operation (number + string)
    x = 5 + "km";

    // ERROR: invalid condition type in check (non-flag)
    check (x) start
        transmit "bad check condition";
    end

    // ERROR: invalid condition type in orbit (non-flag)
    orbit (x) start
        transmit x;
    end

    // ERROR: calling undeclared function
    result = ghost(1);

    // ERROR: wrong number of arguments in function call
    result = addTwo(1);

    // ERROR: wrong argument types in function call
    result = addTwo("one", 2);

    // ERROR: built-in percent division by zero
    f = percent(50, 0);

    // ERROR: built-in ignite wrong argument count
    result = ignite(2, 3);

    // ERROR: built-in ignite wrong argument type
    result = ignite("boost");

    // ERROR: built-in percent wrong argument count
    f = percent(10);

    // ERROR: built-in percent wrong argument type
    f = percent("value", 100);

    // ERROR: scope error (access variable outside its scope)
    check (cond) start
        int localOnly;
        localOnly = 42;
        transmit localOnly;
    end
    transmit localOnly;

    // ERROR: invalid logical operation (int AND int)
    cond = 1 && 0;

    // ERROR: invalid unary operation (NOT on int)
    cond = !5;

    // ERROR: invalid unary operation (minus on string)
    transmit -"text";
end
