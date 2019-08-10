#!/bin/bash

pdbx_file=$(dirname "$0")/../inputs/models/aspartic-acid-model-004.cif

rotag_rmsd -S -c '1,2' --tags '_[local]_rmsd' ${pdbx_file}
