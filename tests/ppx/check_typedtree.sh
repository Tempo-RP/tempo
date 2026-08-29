set -eu

compiler=$1
ppx=$2
source=$3

typedtree=$(
  "$compiler" -ppx "$ppx --as-ppx" -dtypedtree -i "$source" 2>&1 >/dev/null
)

check_marker () {
  marker=$1
  expected=$2
  marker_count=$(
    printf '%s\n' "$typedtree" |
      awk -v marker="$marker" 'index($0, "attribute \"" marker "\"") { count++ } END { print count + 0 }'
  )

  if test "$marker_count" -ne "$expected"
  then
    echo "expected $expected typed $marker markers, found $marker_count" >&2
    exit 1
  fi
}

check_marker tempo.parallel_branch 2
check_marker tempo.when_body 1
check_marker tempo.watch_body 1
