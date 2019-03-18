#!/bin/bash

pdbx_file=$(dirname "$0")/../inputs/synthetic/xaa-001.cif

rotag_scan -p 'cutoff_atom=Inf' ${pdbx_file} \
    | rotag_energy -S
