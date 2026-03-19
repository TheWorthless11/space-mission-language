mission loop_test start
    // Loop with valid flag condition
    int counter;
    flag keepRunning;

    counter = 0;
    keepRunning = true;

    orbit (keepRunning) start
        counter = counter + 1;
        transmit counter;
    end
end
