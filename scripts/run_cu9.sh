#!/bin/bash

# y = READPERTHREAD, x = BLOCKDIM
for y in 1 2 4 8 16 32 64
do
    for x in 64 128 256 512 1024
    do
        BIN="./bin/cu9_reduction_add_to1_${x}_${y}"
        
        if [ -f "$BIN" ]; then
            echo "Executing: $BIN"
            echo "Executing: $BIN" >&2
            ./range_run.sh "$BIN" -st 8 -fn 28
        else
            echo "Error: $BIN not found"
        fi
    done
done
