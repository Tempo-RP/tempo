set -eu

compiler=$1
ppx=$2
source=$3
expected=$4

set +e
diagnostic=$(
  "$compiler" -ppx "$ppx --as-ppx" -i "$source" 2>&1 >/dev/null
)
status=$?
set -e

if test "$status" -eq 0
then
  echo "expected PPX compilation to fail: $source" >&2
  exit 1
fi

case "$diagnostic" in
  *"$expected"*) ;;
  *)
    echo "missing expected diagnostic: $expected" >&2
    printf '%s\n' "$diagnostic" >&2
    exit 1
    ;;
esac
