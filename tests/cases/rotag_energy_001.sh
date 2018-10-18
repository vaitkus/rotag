#!/bin/bash

pdbx_file=$(dirname "$0")/../inputs/surrounded/serine-H-bonding-001.cif

rotag_energy \
    --potential composite ${pdbx_file} \
    --parameters 'lj_epsilon=1.0, c_k=1.0, h_epsilon=1.0, r_sigma=2.0, cutoff_atom=0.5, cutoff_residue=1.0, cutoff_start=2.5, cutoff_end=5.0'
