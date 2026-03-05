#!/usr/bin/env bash
# generate-changelog.sh — Auto-generate CHANGELOG.md from git tags & conventional commits
#
# Usage:
#   ./scripts/generate-changelog.sh              # generate full changelog
#   ./scripts/generate-changelog.sh v1.0.0       # generate for a specific tag only
#
# Conventional Commit prefixes detected:
#   feat:     → Features
#   fix:      → Bug Fixes
#   docs:     → Documentation
#   chore:    → Chores
#   refactor: → Refactoring
#   test:     → Tests
#   perf:     → Performance
#   ci:       → CI/CD
#   style:    → Style
#   build:    → Build

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
CHANGELOG_FILE="${REPO_ROOT}/CHANGELOG.md"
SINGLE_TAG="${1:-}"

# Map conventional commit prefix to section header
get_section() {
  local prefix="$1"
  case "$prefix" in
    feat)     echo "Features" ;;
    fix)      echo "Bug Fixes" ;;
    docs)     echo "Documentation" ;;
    chore)    echo "Chores" ;;
    refactor) echo "Refactoring" ;;
    test)     echo "Tests" ;;
    perf)     echo "Performance" ;;
    ci)       echo "CI/CD" ;;
    style)    echo "Style" ;;
    build)    echo "Build" ;;
    *)        echo "Other" ;;
  esac
}

# Get all version tags sorted by version descending
get_tags() {
  git tag -l 'v*' --sort=-version:refname
}

# Get the date a tag was created
tag_date() {
  git log -1 --format="%cd" --date=short "$1" 2>/dev/null
}

# Generate changelog entries for a range of commits
generate_section() {
  local from="$1"
  local to="$2"

  local log_range
  if [ -z "$from" ]; then
    log_range="$to"
  else
    log_range="${from}..${to}"
  fi

  # Temporary files for section collection
  local tmpdir
  tmpdir="$(mktemp -d)"
  trap "rm -rf '$tmpdir'" RETURN

  # Process each commit individually
  git log --format="---COMMIT_START---%n%s%n%b%n---COMMIT_END---" "$log_range" | \
  while IFS= read -r line; do
    if [ "$line" = "---COMMIT_START---" ]; then
      subject=""
      body=""
      reading_subject=true
      continue
    fi
    if [ "$line" = "---COMMIT_END---" ]; then
      [ -z "$subject" ] && continue

      # Parse conventional commit prefix
      local prefix title
      if [[ "$subject" =~ ^([a-z]+)(\(.+\))?!?:\ (.+)$ ]]; then
        prefix="${BASH_REMATCH[1]}"
        title="${BASH_REMATCH[3]}"
      else
        prefix="other"
        title="$subject"
      fi

      local section_name
      section_name="$(get_section "$prefix")"
      local section_file="${tmpdir}/${section_name}"

      # Write entry
      echo "- ${title}" >> "$section_file"

      # Add body lines as sub-bullets
      if [ -n "$body" ]; then
        echo "$body" | while IFS= read -r bline; do
          bline="$(echo "$bline" | sed 's/^[[:space:]]*//')"
          [ -z "$bline" ] && continue
          [[ "$bline" == Co-Authored-By:* ]] && continue
          echo "  ${bline}" >> "$section_file"
        done
      fi

      continue
    fi

    if [ "${reading_subject:-false}" = "true" ]; then
      subject="$line"
      reading_subject=false
    else
      if [ -n "$body" ]; then
        body="${body}
${line}"
      else
        body="$line"
      fi
    fi
  done

  # Output sections in preferred order
  local order="Features Bug_Fixes Performance Refactoring Documentation Tests CI/CD Build Style Chores Other"
  for section_key in $order; do
    local section_name="${section_key//_/ }"
    local section_file="${tmpdir}/${section_name}"
    if [ -f "$section_file" ]; then
      echo ""
      echo "### ${section_name}"
      echo ""
      cat "$section_file"
    fi
  done
}

# --- Main ---

# Read tags into array (compatible with macOS bash/zsh)
tags=()
while IFS= read -r tag; do
  [ -n "$tag" ] && tags+=("$tag")
done < <(get_tags)

{
  echo "# Changelog"
  echo ""
  echo "All notable changes to this project will be documented in this file."
  echo ""
  echo "This changelog is auto-generated from [Conventional Commits](https://www.conventionalcommits.org/)."

  if [ ${#tags[@]} -eq 0 ]; then
    echo ""
    echo "No version tags found."
    exit 0
  fi

  for i in "${!tags[@]}"; do
    local_tag="${tags[$i]}"

    # If single tag mode, skip others
    if [ -n "$SINGLE_TAG" ] && [ "$local_tag" != "$SINGLE_TAG" ]; then
      continue
    fi

    local_date="$(tag_date "$local_tag")"

    echo ""
    echo "## [${local_tag}] - ${local_date}"

    # Determine the range
    if [ $((i + 1)) -lt ${#tags[@]} ]; then
      prev_tag="${tags[$((i + 1))]}"
      generate_section "$prev_tag" "$local_tag"
    else
      # First tag — all commits up to this tag
      generate_section "" "$local_tag"
    fi
  done
} > "$CHANGELOG_FILE"

echo "Changelog generated: ${CHANGELOG_FILE}"
