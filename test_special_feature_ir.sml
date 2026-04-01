// Special feature: compact IR coverage (temps + labels + branch + loop).
mission ir_demo start
    int a;
    int b;
    int c;
    flag cond;

    a = 10;
    b = 4;
    c = (a + b) * 2
    cond = c > 20;

    check (cond) start
        c = c - 1;
    end otherwise start
        c = c + 1;
    end

    orbit (cond) start
        c = c - 5;
        cond = c > 20;
    end

    transmit c;
end