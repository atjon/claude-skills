#!/usr/bin/env bash
# sync-skills.sh — mirror Claude Code skills between this machine and the repo.
#
# Usage:
#   ./scripts/sync-skills.sh            # disk -> repo, commit, push (normal use)
#   ./scripts/sync-skills.sh restore    # repo -> disk (new machine setup)
#
# Source of truth: manifest.tsv in the repo root. Format (tab-separated):
#   skill-name <TAB> category <TAB> source-path
# Lines starting with # and blank lines are ignored. Paths may start with ~/.
#
# See MAINTENANCE.md for the rules governing this repo.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$REPO_DIR/manifest.tsv"
SKILLS_DIR="$REPO_DIR/skills"
MODE="${1:-sync}"

[ -f "$MANIFEST" ] || { echo "ERROR: $MANIFEST not found" >&2; exit 1; }

expand_path() { local p="$1"; echo "${p/#\~/$HOME}"; }

# Read manifest into parallel arrays, validating as we go.
names=(); categories=(); sources=()
lineno=0
while IFS=$'\t' read -r name category source || [ -n "${name:-}" ]; do
    lineno=$((lineno + 1))
    [ -z "$name" ] || [ "${name:0:1}" = "#" ] && continue
    if [ -z "${category:-}" ] || [ -z "${source:-}" ]; then
        echo "ERROR: manifest line $lineno is malformed (need 3 tab-separated fields): $name" >&2
        exit 1
    fi
    names+=("$name"); categories+=("$category"); sources+=("$source")
done < "$MANIFEST"

if [ "$MODE" = "restore" ]; then
    # repo -> disk
    for i in "${!names[@]}"; do
        src="$SKILLS_DIR/${categories[$i]}/${names[$i]}/"
        dst="$(expand_path "${sources[$i]}")/"
        [ -d "$src" ] || { echo "WARN: ${names[$i]} not in repo, skipping" >&2; continue; }
        mkdir -p "$dst"
        rsync -a --delete "$src" "$dst"
        echo "restored ${names[$i]} -> $dst"
    done
    echo "Restore complete."
    exit 0
fi

# --- sync mode: disk -> repo ---

# 1. Copy each manifest entry into skills/<category>/<name>/
for i in "${!names[@]}"; do
    src="$(expand_path "${sources[$i]}")/"
    dst="$SKILLS_DIR/${categories[$i]}/${names[$i]}/"
    if [ ! -d "$src" ]; then
        echo "ERROR: source for '${names[$i]}' does not exist: $src" >&2
        echo "       Fix the manifest or create the skill first." >&2
        exit 1
    fi
    if [ ! -f "${src}SKILL.md" ]; then
        echo "ERROR: '${names[$i]}' has no SKILL.md at $src" >&2
        exit 1
    fi
    mkdir -p "$dst"
    rsync -a --delete "$src" "$dst"
done

# 2. Prune skill folders in the repo that are no longer in the manifest.
if [ -d "$SKILLS_DIR" ]; then
    while IFS= read -r dir; do
        rel="${dir#"$SKILLS_DIR"/}"          # category/name
        cat="${rel%%/*}"; name="${rel#*/}"
        keep=false
        for i in "${!names[@]}"; do
            if [ "${names[$i]}" = "$name" ] && [ "${categories[$i]}" = "$cat" ]; then
                keep=true; break
            fi
        done
        if [ "$keep" = false ]; then
            rm -rf "$dir"
            echo "pruned $rel (not in manifest)"
        fi
    done < <(find "$SKILLS_DIR" -mindepth 2 -maxdepth 2 -type d)
    # remove now-empty category folders
    find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -empty -delete
fi

# 3. Commit and push.
cd "$REPO_DIR"
git add -A
if git diff --cached --quiet; then
    echo "Nothing to sync — repo already matches disk."
    exit 0
fi
msg="${SYNC_MSG:-sync: update skills ($(date +%F))}"
git commit -m "$msg" -m "Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
if git remote get-url origin >/dev/null 2>&1; then
    git pull --rebase origin main && git push origin main
    echo "Synced and pushed."
else
    echo "Committed locally. No 'origin' remote configured yet — push skipped." >&2
fi
