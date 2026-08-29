set -eu

public_dir=$(dirname "$1")

for module in \
  Tempo_types \
  Tempo_log \
  Tempo_thread \
  Tempo_signal \
  Tempo_task \
  Tempo_low_level \
  Tempo_core \
  Tempo_engine
do
  for extension in cmi cmti
  do
    artifact="$public_dir/tempo__${module}.${extension}"
    if test -e "$artifact"
    then
      echo "private module artifact exposed: $artifact" >&2
      exit 1
    fi
  done
done

for artifact in \
  "$public_dir"/tempo_constructs.* \
  "$public_dir"/tempo__Tempo_constructs.* \
  "$public_dir"/.private/tempo__Tempo_constructs.*
do
  if test -e "$artifact"
  then
    echo "removed module artifact still installed: $artifact" >&2
    exit 1
  fi
done
