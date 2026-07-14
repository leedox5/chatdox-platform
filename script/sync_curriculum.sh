#!/usr/bin/env bash
set -euo pipefail

# Replaces `git subtree pull --prefix docs/curriculum` (REQ 0022, chatdox-curriculum).
# Subtree kept causing large add/add conflicts on pull. This instead exports the
# exact git-tracked snapshot of chatdox-curriculum at a given ref and mirrors it
# into docs/curriculum/ as plain files — no shared git history, no merge machinery.
# Commit the result in this repo like any other change.

SOURCE_REPO="/mnt/d/RubyOnRails/chatdox-curriculum"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="$PROJECT_ROOT/docs/curriculum"
REF="main"
DRY_RUN_MODE="false"

for arg in "$@"; do
  case "$arg" in
    --ref=*)
      REF="${arg#--ref=}"
      ;;
    --dry-run)
      DRY_RUN_MODE="true"
      ;;
    *)
      echo "Unknown option: $arg" >&2
      echo "Usage: $0 [--ref=<git-ref>] [--dry-run]" >&2
      exit 1
      ;;
  esac
done

if [[ ! -d "$SOURCE_REPO/.git" ]]; then
  echo "Source repo not found: $SOURCE_REPO" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

git -C "$SOURCE_REPO" archive "$REF" | tar -x -C "$TMP_DIR"

RSYNC_OPTS=("-a" "--delete")

if [[ "$DRY_RUN_MODE" == "true" ]]; then
  RSYNC_OPTS+=("--dry-run" "--itemize-changes")
fi

rsync "${RSYNC_OPTS[@]}" "$TMP_DIR/" "$TARGET_DIR/"

echo "Synced chatdox-curriculum ($REF) into docs/curriculum/."
echo "Source: $SOURCE_REPO ($REF, git-tracked snapshot only)"
echo "Target: $TARGET_DIR"
echo "Dry run: $DRY_RUN_MODE"