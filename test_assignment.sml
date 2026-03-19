mission assignment_test start
    // Valid declarations
    int a;
    float b;
    string msg;
    flag ok;

    // Valid assignments
    a = 10;
    b = 3.5;
    msg = "launch";
    ok = true;
    b = a;

    // Invalid assignments (semantic errors expected)
    a = 2.7;
    msg = false;
    ok = 1;
end
