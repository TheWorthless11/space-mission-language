mission error_test start
    int a;

    // Undeclared variable usage (semantic error expected)
    b = 10;

    // Redeclaration in same scope (semantic error expected)
    float a;

    // Type mismatch assignment (semantic error expected)
    flag launched;
    launched = 1;
end
