#!/bin/bash

export PERL5LIB=$(dirname "$0")/../../lib

pdbx_dump_file=$(dirname "$0")/../inputs/amino-acids/aspartic-acid-002.dump

$(dirname "$0")/../scripts/connect_atoms ${pdbx_dump_file} | sort -k 1 -n
