#!/bin/bash
cd "$(dirname "$0")"

pdbx_file=../inputs/serine_001.cif
potential="hard_sphere"
cutoff=0
target_resi="18"
small_angle="0.1*pi"

../programs/generate_library "${potential}" "${cutoff}" "${target_resi}" \
			     "${small_angle}" ${pdbx_file}
