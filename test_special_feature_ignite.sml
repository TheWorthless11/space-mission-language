// Special feature 3a: built-in IR lowering for ignite(x).
mission builtin_ignite_small start
    int base;
    int boosted;

    base = 9;
    boosted = ignite(base);

    transmit boosted;
end