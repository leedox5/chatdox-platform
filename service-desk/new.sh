#!/usr/bin/env bash
# Create a new service-desk request from requests/_FORM.md with the next ID.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

max=0
for f in requests/[0-9][0-9][0-9][0-9].md; do
  [ -f "$f" ] || continue
  id=$(basename "$f" .md)
  id=$((10#$id))
  [ "$id" -gt "$max" ] && max=$id
done

next=$(printf "%04d" $((max + 1)))
dest="requests/${next}.md"

if [ -e "$dest" ]; then
  echo "이미 존재함: $dest" >&2
  exit 1
fi

sed -e "s/ID : NNNN/ID : ${next}/" \
    -e "s/Date : YYYY.MM.DD/Date : $(date +%Y.%m.%d)/" \
    requests/_FORM.md > "$dest"

echo "Created $dest"
