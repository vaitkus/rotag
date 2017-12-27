#!/bin/bash
cd "$(dirname "$0")"

pdbx_file=../inputs/threonine_039.cif
target_resi="340"
angles="chi0 pi & chi1 pi & chi2 pi"

../programs/generate_rotamer "${target_resi}" "${angles}" ${pdbx_file}
