#!/bin/bash
cd "$(dirname "$0")"

pdbx_file=../inputs/5svd_002.cif
atom_specifier="Cartn_x 3.060 & Cartn_y 6.003 & Cartn_z 69.486"

../programs/filter_atoms "${atom_specifier}" ${pdbx_file}
