// Special feature 2: compact AST-friendly nested control flow.
module int inc(int x) start
    return x + 1;
end

mission ast_demo start
    int count;
    flag keepGoing;

    count = 0;
    keepGoing = true;

    orbit (keepGoing) start
        count = inc(count);
        check (count < 2) start
            transmit count;
        end otherwise start
            keepGoing = false;
        end
    end
end