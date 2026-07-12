#!/usr/bin/env bash
# Regenerate dashboard.md by scanning requests/*.md
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

new=0; inprog=0; comp=0; conf=0; total=0
rows=""

for f in requests/[0-9][0-9][0-9][0-9].md; do
  [ -f "$f" ] || continue
  id=$(grep -m1 'ID :' "$f" | sed -E 's/^[[:space:]]*ID[[:space:]]*:[[:space:]]*//')
  date=$(grep -m1 'Date :' "$f" | sed -E 's/^[[:space:]]*Date[[:space:]]*:[[:space:]]*//')
  subject=$(grep -m1 'Subject :' "$f" | sed -E 's/^[[:space:]]*Subject[[:space:]]*:[[:space:]]*//')
  status=$(grep -m1 'Status :' "$f" | sed -E 's/^[[:space:]]*Status[[:space:]]*:[[:space:]]*//')

  case "$status" in
    New) new=$((new+1)) ;;
    "In Progress") inprog=$((inprog+1)) ;;
    Completed) comp=$((comp+1)) ;;
    Confirmed) conf=$((conf+1)) ;;
  esac
  total=$((total+1))

  rows="${rows}| ${id} | ${date} | ${subject} | ${status} |"$'\n'
done

rate=0
if [ "$total" -gt 0 ]; then
  rate=$(( (comp + conf) * 100 / total ))
fi

{
  echo "# 종합현황"
  echo
  echo "완료율: **${rate}%** · 요청 ${total} · 신규 ${new} · 진행중 ${inprog} · 완료 ${comp} · 확인 ${conf}"
  echo
  echo "| ID | Date | Subject | Status |"
  echo "|---|---|---|---|"
  printf '%s' "$rows"
  echo
  echo "---"
  echo
  echo "*새 요청이 생기거나 상태가 바뀌면 이 표도 같이 갱신한다.*"
} > dashboard.md

echo "dashboard.md regenerated ($total requests)"
