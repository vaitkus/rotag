#!/bin/bash
cd "$(dirname "$0")"

pdbx_file=../inputs/cysteine_008.cif
target_resi="419"
angles="chi0 0"

../programs/generate_rotamer "${target_resi}" "${angles}" ${pdbx_file}
