#!/usr/bin/env bash
#
# Re-sync the resources this skill copied (and, for golden-examples, adapted) from the
# reshapr repo on GitHub, so future upstream changes are easy to pick up.
#
# Tracked sources (fetched from https://github.com/reshaprio/reshapr at $RESHAPR_REF):
#   - JSON Schemas: control-plane/src/main/resources/schemas/*.json (verbatim copies)
#   - Golden examples: web-ui/src/lib/artifacts/examples.ts (hand-adapted into assets/*.yaml,
#     so this script only detects upstream drift and prompts for a manual review)
#
# Usage:
#   ./sync-resources.sh [ref]
#
# The ref is a branch, tag, or commit in reshaprio/reshapr (defaults to "main", or the
# RESHAPR_REF environment variable when set).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/reshapr-builder-plugin/skills/reshapr-builder" && pwd)"
REFERENCES_DIR="$SKILL_DIR/references"
REVIEWED_HASH_FILE="$SCRIPT_DIR/.examples-ts-reviewed.sha256"

REPO="reshaprio/reshapr"
REF="${1:-${RESHAPR_REF:-main}}"
RAW_BASE="https://raw.githubusercontent.com/$REPO/$REF"

sha256_of() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

fetch() {
  # fetch <raw-path> <dest-file> — downloads a raw GitHub file, failing loudly on error.
  local raw_path="$1" dest="$2"
  curl --fail --silent --show-error --location "$RAW_BASE/$raw_path" --output "$dest"
}

echo "Using reshapr repo: https://github.com/$REPO (ref: $REF)"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

# --- 1. JSON Schemas: verbatim copies, safe to overwrite automatically. ---

SCHEMAS_PATH="control-plane/src/main/resources/schemas"
schema_changed=0

for name in Prompts Resources CustomTools ToolsOutputFilters; do
  dst="$REFERENCES_DIR/${name}-v1alpha1-schema.json"
  tmp_schema="$tmp_dir/${name}-v1alpha1-schema.json"

  if ! fetch "$SCHEMAS_PATH/${name}-v1alpha1-schema.json" "$tmp_schema"; then
    echo "warning: could not fetch ${name}-v1alpha1-schema.json from $REF" >&2
    continue
  fi

  if ! cmp -s "$tmp_schema" "$dst" 2>/dev/null; then
    cp "$tmp_schema" "$dst"
    echo "updated: ${name}-v1alpha1-schema.json"
    schema_changed=1
  fi
done

if [[ "$schema_changed" -eq 0 ]]; then
  echo "schemas: already up to date"
fi

# --- 2. Golden examples: hand-adapted from web-ui/src/lib/artifacts/examples.ts. ---
# Entries there are extracted and wrapped into full artifacts under assets/*.yaml, so a
# blind copy would not make sense. This only flags upstream drift for manual review.

EXAMPLES_PATH="web-ui/src/lib/artifacts/examples.ts"
tmp_examples="$tmp_dir/examples.ts"

if fetch "$EXAMPLES_PATH" "$tmp_examples"; then
  new_hash="$(sha256_of "$tmp_examples")"
  old_hash="$(cat "$REVIEWED_HASH_FILE" 2>/dev/null || true)"

  if [[ "$new_hash" != "$old_hash" ]]; then
    echo
    echo "examples.ts changed upstream since the last reviewed sync."
    echo "  source: https://github.com/$REPO/blob/$REF/$EXAMPLES_PATH"
    echo "  review its PROMPTS_EXAMPLES / RESOURCES_EXAMPLES / CUSTOM_TOOLS_EXAMPLES /"
    echo "  TOOLS_OUTPUT_FILTERS_EXAMPLES arrays and update the matching files under:"
    echo "    $SKILL_DIR/assets/*.yaml"
    echo "    $REFERENCES_DIR/golden-examples.md"
    echo
    read -r -p "Mark this version of examples.ts as reviewed? [y/N] " reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      echo "$new_hash" > "$REVIEWED_HASH_FILE"
      echo "recorded reviewed hash for examples.ts"
    else
      echo "left unmarked; this script will prompt again next run"
    fi
  else
    echo "examples.ts: no changes since last reviewed sync"
  fi
else
  echo "warning: could not fetch examples.ts from $REF" >&2
fi
