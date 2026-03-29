// Zero-argument function declaration and call test
module int missionCode() start
    return 42;
end

mission zero_arg_function_test start
    int code;
    code = missionCode();
    transmit code;
end
