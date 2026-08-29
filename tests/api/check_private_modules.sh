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
  Tempo_constructs \
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
