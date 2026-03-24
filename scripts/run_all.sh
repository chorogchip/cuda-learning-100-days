#!/bin/bash

PREFIX=${1}

for filepath in ./bin/cu${PREFIX}*; do
    
    if [ ! -e "$filepath" ]; then
        echo "No files matching ./bin/cu${PREFIX}* found."
        exit 1
    fi

    NAME=$(basename "$filepath")

    echo "run $NAME" >&2

    ./range_run.sh "$filepath" -st 8 -fn 28

done
