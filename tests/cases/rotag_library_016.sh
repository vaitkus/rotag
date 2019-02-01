#!/bin/bash

pdbx_file=$(dirname "$0")/../inputs/surrounded/aspartic-acid-002.cif

rotag_library \
    -c 40.0 \
    --angles 90.0 \
    --parameters 'lj_k=1.0, c_k=1.0, h_k=1.0, t_k=1.0, cutoff_start=2.5, cutoff_end=5.0' \
    --top-rank 1 \
    ${pdbx_file}
