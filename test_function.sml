// Function tests: one valid function and one with return mismatch
module int addOne(int x) start
    // Correct return type (int)
    return x + 1;
end

module int brokenReturn(int x) start
    // Incorrect return type for declared int function (returns float)
    return 2.5;
end

mission function_test start
    int a;
    a = addOne(5);
    transmit a;
end
