#!/usr/bin/env bash
# Create a new service-desk request from 01_new/_FORM.md with the next ID.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

max=0
for f in 01_new/[0-9][0-9][0-9][0-9].md 02_in_progress/[0-9][0-9][0-9][0-9].md 03_completed/[0-9][0-9][0-9][0-9].md; do
  [ -f "$f" ] || continue
  id=$(basename "$f" .md)
  id=$((10#$id))
  [ "$id" -gt "$max" ] && max=$id
done

next=$(printf "%04d" $((max + 1)))
dest="01_new/${next}.md"

if [ -e "$dest" ]; then
  echo "이미 존재함: $dest" >&2
  exit 1
fi

sed -e "s/ID : NNNN/ID : ${next}/" \
    -e "s/Date : YYYY.MM.DD/Date : $(date +%Y.%m.%d)/" \
    01_new/_FORM.md > "$dest"

echo "Created $dest"
