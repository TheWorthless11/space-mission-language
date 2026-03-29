// Built-in percent error-path tests
// Expected semantic errors:
// 1. division by zero
// 2. non-numeric argument type
// 3. wrong argument count
mission builtin_percent_error_test start
    transmit percent(30, 0);
    transmit percent("x", 10);
    transmit percent(10);
end
