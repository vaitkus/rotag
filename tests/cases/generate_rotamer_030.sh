#!/bin/bash

export PERL5LIB=$(dirname "$0")/../../lib

pdbx_dump_file=$(dirname "$0")/../inputs/amino-acids/isoleucine-H-rotation-only-001.dump
residue_id="555"
angle_values="chi0 0 & chi1 pi & chi2 pi & chi3 pi"

$(dirname "$0")/../scripts/generate_rotamer "${residue_id}" \
	                                    "${angle_values}" \
					    ${pdbx_dump_file}
