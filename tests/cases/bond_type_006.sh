#!/bin/bash
cd "$(dirname "$0")"

pdbx_file=../inputs/aspartic_acid_006.cif

../programs/bond_type ${pdbx_file} | sort -k 1 -n
