#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DIR="$PROJECT_ROOT/.local/handoff/outbox"
TARGET_DIR="/mnt/d/RubyOnRails/chatdox-curriculum/.local/handoff/inbox"
MIRROR_MODE="false"
DRY_RUN_MODE="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      if [[ $# -lt 2 ]]; then
        echo "--source requires a directory argument" >&2
        exit 1
      fi
      SOURCE_DIR="$2"
      if [[ "$SOURCE_DIR" != /* ]]; then
        SOURCE_DIR="$PROJECT_ROOT/$SOURCE_DIR"
      fi
      shift 2
      ;;
    --mirror)
      MIRROR_MODE="true"
      shift
      ;;
    --dry-run)
      DRY_RUN_MODE="true"
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 [--source <dir>] [--mirror] [--dry-run]" >&2
      exit 1
      ;;
  esac
done

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Source directory not found: $SOURCE_DIR" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

RSYNC_OPTS=("-a")

if [[ "$MIRROR_MODE" == "true" ]]; then
  RSYNC_OPTS+=("--delete")
fi

if [[ "$DRY_RUN_MODE" == "true" ]]; then
  RSYNC_OPTS+=("--dry-run" "--itemize-changes")
fi

rsync "${RSYNC_OPTS[@]}" "$SOURCE_DIR/" "$TARGET_DIR/"

echo "Pushed handoff files to curriculum inbox."
echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_DIR"
echo "Mode: $([[ "$MIRROR_MODE" == "true" ]] && echo "mirror" || echo "copy")"
echo "Dry run: $DRY_RUN_MODE"
