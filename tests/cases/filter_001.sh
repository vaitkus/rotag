#!/bin/bash

export PERL5LIB=$(dirname "$0")/../../lib

pdbx_dump_file=
include_specifier=
exclude_specifier=
data_specifier=

"$(dirname "$0")"/../scripts/filter "${include_specifier}" \
		                    "${exclude_specifier}" \
                		    "${data_specifier}"    \
		                    "${pdbx_dump_file}"
