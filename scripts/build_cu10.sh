#!/bin/bash

SRC="cu10_prefixscan"

for block_dim in 64 128 256 512 1024
do
        SUFFIX="${block_dim}"
        echo "Building: ${SUFFIX}"

        ./comp_define_new.sh "$SRC" "$SUFFIX" "-DMY_BLOCKDIM=${block_dim}"

        if [ $? -ne 0 ]; then
            echo "Error: ${SUFFIX} failed"
        fi
done

echo "Done."
