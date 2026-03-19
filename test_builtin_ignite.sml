mission builtin_ignite_test start
    int base;
    int boosted;

    base = 7;

    // Built-in ignite(x) usage
    // Note: depending on semantic setup, this may still report undeclared function,
    // but IR expansion for ignite should be generated.
    boosted = ignite(base);

    transmit boosted;
end
