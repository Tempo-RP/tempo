set -eu

compiler=$1
ppx=$2
source=$3

typedtree=$(
  "$compiler" -ppx "$ppx --as-ppx" -dtypedtree -i "$source" 2>&1 >/dev/null
)
marker_count=$(
  printf '%s\n' "$typedtree" |
    awk '/attribute "tempo.parallel_branch"/ { count++ } END { print count + 0 }'
)

if test "$marker_count" -ne 2
then
  echo "expected two typed parallel branch markers, found $marker_count" >&2
  exit 1
fi
