#!/bin/bash

export PERL5LIB=$(dirname "$0")/../../lib

pdbx_dump_file=$(dirname "$0")/../inputs/synthetic/single-atoms-002.dump
atom_i_id=1
atom_j_id=3

$(dirname "$0")/../scripts/coulomb ${atom_i_id} \
                                   ${atom_j_id} \
			           ${pdbx_dump_file}
