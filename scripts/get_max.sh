#!/bin/bash
awk -F',' '{
    n = $2 + 0;
    flops = $4 + 0;
    if (n > 0 && flops > max[n]) {
        max[n] = flops;
        line[n] = $0;
    }
}
END {
    for (i in line) print line[i];
}' | sort -t',' -k2,2n
