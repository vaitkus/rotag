#!/bin/bash
cd "$(dirname "$0")"

matrices=../inputs/matrices_006.dat

../programs/matrix_product < ${matrices}
