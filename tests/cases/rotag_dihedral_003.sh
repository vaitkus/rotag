#!/bin/bash

pdbx_file=$(dirname "$0")/../inputs/amino-acids/leucine-001.cif

rotag_dihedral ${pdbx_file}
