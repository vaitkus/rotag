#!/bin/bash

pdbx_file=$(dirname "$0")/../inputs/surrounded/serine-001.cif

rotag_scan \
    --parameters 'cutoff_atom=40.0, lj_k=1.0, c_k=1.0, h_k=1.0, t_k=1.0, cutoff_start=2.5, cutoff_end=5.0' \
    ${pdbx_file}
