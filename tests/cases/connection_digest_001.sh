#!/bin/bash

export PERL5LIB=$(dirname "$0")/../../lib

pdbx_dump_file_1=$(dirname "$0")/../inputs/amino-acids/proline-001.dump
pdbx_dump_file_2=$(dirname "$0")/../inputs/amino-acids/proline-002.dump

$(dirname "$0")/../scripts/connection_digest ${pdbx_dump_file_1} ${pdbx_dump_file_2}
