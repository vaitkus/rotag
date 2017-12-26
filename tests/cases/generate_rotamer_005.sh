#!/bin/bash
cd "$(dirname "$0")"

pdbx_file=../inputs/lysine_005.cif
target_resi="572"
angles="chi0 0 & chi1 pi & chi2 0 & chi3 pi"

../programs/generate_rotamer "${target_resi}" "${angles}" ${pdbx_file}
