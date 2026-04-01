// Special feature 1: mission-control keyword coverage.
module int bump(int x) start
    return x + 1;
end

mission special_keywords_demo start
    int fuel;
    flag ready;

    fuel = bump(4);
    ready = fuel > 0;

    check (ready) start
        transmit fuel;
    end otherwise start
        transmit 0;
    end

    orbit (ready) start
        ready = false;
    end
end