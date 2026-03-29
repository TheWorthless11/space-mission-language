// Recursive function call test (self-call inside function body)
module int countdown(int n) start
    check (n == 0) start
        return 0;
    end otherwise start
        return countdown(n - 1);
    end
end

mission recursive_call_test start
    int result;
    result = countdown(3);
    transmit result;
end
