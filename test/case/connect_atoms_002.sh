#!/bin/bash
cd "$(dirname "$0")"

cif_file=../input/5svd_002.cif

bond_length=1.51
bond_length_error=0.15

../programs/connect_atoms ${bond_length} ${bond_length_error} < ${cif_file}
