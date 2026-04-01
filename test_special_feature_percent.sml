// Built-in percent test: percent(a, b) = (a / b) * 100
mission builtin_percent_test start
    float pct;

    // Required sample call
    pct = percent(30, 60);

    transmit pct;
end
