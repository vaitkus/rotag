#!/bin/bash
cd "$(dirname "$0")"

pdbx_file=../inputs/histidine_004.cif
target_resi="94"
angles="chi0 0 & chi1 pi"

../programs/generate_rotamer "${target_resi}" "${angles}" ${pdbx_file}
