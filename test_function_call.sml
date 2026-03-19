// Function call tests: valid call, wrong arity, wrong argument type
module int sum2(int x, int y) start
    return x + y;
end

mission function_call_test start
    int result;

    // Valid function call
    result = sum2(4, 6);

    // Wrong argument count (semantic error expected)
    result = sum2(4);

    // Wrong argument type (semantic error expected)
    result = sum2(4, true);

    transmit result;
end
