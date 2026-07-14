#!/usr/bin/env bash
set -euo pipefail

# Replaces `git subtree pull --prefix docs/curriculum` (REQ 0022, chatdox-curriculum).
# Subtree kept causing large add/add conflicts on pull, and pulled the entire HQ repo
# (QA/, SETUP/, TIPS/, prompts/, internal/, service-desk tooling, etc.) even though
# this app only ever reads three specific folders. This instead exports the exact
# git-tracked snapshot of chatdox-curriculum at a given ref and mirrors ONLY the
# folders actually used at runtime into their own top-level locations:
#
#   HQ docs/                 -> DEV docs/chatdox/
#   HQ claudox/               -> DEV docs/claudox/
#   HQ service-desk/requests/ -> DEV service-desk/
#
# No shared git history, no subtree merge machinery, no unused content. Commit the
# result in this repo like any other change.

SOURCE_REPO="/mnt/d/RubyOnRails/chatdox-curriculum"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
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

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

git -C "$SOURCE_REPO" archive "$REF" | tar -x -C "$TMP_DIR"

RSYNC_OPTS=("-a" "--delete")
if [[ "$DRY_RUN_MODE" == "true" ]]; then
  RSYNC_OPTS+=("--dry-run" "--itemize-changes")
fi

sync_one() {
  local src="$1" dest="$2"
  mkdir -p "$dest"
  rsync "${RSYNC_OPTS[@]}" "$TMP_DIR/$src/" "$dest/"
  echo "  $src -> ${dest#$PROJECT_ROOT/}"
}

echo "Syncing chatdox-curriculum ($REF), runtime folders only:"
sync_one "docs" "$PROJECT_ROOT/docs/chatdox"
sync_one "claudox" "$PROJECT_ROOT/docs/claudox"
sync_one "service-desk/requests" "$PROJECT_ROOT/service-desk"

echo "Dry run: $DRY_RUN_MODE"