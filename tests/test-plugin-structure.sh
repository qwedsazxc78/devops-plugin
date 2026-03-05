#!/usr/bin/env bash
# =============================================================================
# DevOps Plugin — Structure & Quality Tests
# =============================================================================
# Validates plugin structure, file references, frontmatter, and content rules.
#
# Usage:
#   ./tests/test-plugin-structure.sh           # Run all tests
#   ./tests/test-plugin-structure.sh structure  # Run only structure tests
#   ./tests/test-plugin-structure.sh content    # Run only content tests
#   ./tests/test-plugin-structure.sh refs       # Run only reference tests
#   ./tests/test-plugin-structure.sh security   # Run only security tests
#   ./tests/test-plugin-structure.sh changelog  # Run only changelog tests
# =============================================================================

set -uo pipefail

# --- Setup ------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0
WARN=0
ERRORS=()

# Colors
if [[ -t 1 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  BOLD='\033[1m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BOLD=''; NC=''
fi

# --- Helpers ----------------------------------------------------------------
pass() {
  printf "  ${GREEN}[PASS]${NC} %s\n" "$1"
  ((PASS++))
}

fail() {
  printf "  ${RED}[FAIL]${NC} %s\n" "$1"
  ((FAIL++))
  ERRORS+=("$1")
}

warn() {
  printf "  ${YELLOW}[WARN]${NC} %s\n" "$1"
  ((WARN++))
}

section() {
  echo
  printf "${BOLD}%s${NC}\n" "$1"
  printf "%.0s─" {1..50}; echo
}

# =============================================================================
# TEST: Plugin structure
# =============================================================================
test_structure() {
  section "Plugin Structure"

  # plugin.json
  if [[ -f "$PLUGIN_DIR/.claude-plugin/plugin.json" ]]; then
    pass "plugin.json exists"
  else
    fail "plugin.json missing at .claude-plugin/plugin.json"
    return
  fi

  # Validate JSON
  if command -v jq &>/dev/null; then
    if jq empty "$PLUGIN_DIR/.claude-plugin/plugin.json" 2>/dev/null; then
      pass "plugin.json is valid JSON"
    else
      fail "plugin.json is invalid JSON"
    fi

    # Required fields
    local name version description
    name=$(jq -r '.name' "$PLUGIN_DIR/.claude-plugin/plugin.json")
    version=$(jq -r '.version' "$PLUGIN_DIR/.claude-plugin/plugin.json")
    description=$(jq -r '.description' "$PLUGIN_DIR/.claude-plugin/plugin.json")

    [[ -n "$name" && "$name" != "null" ]] && pass "plugin.json has name: $name" || fail "plugin.json missing 'name' field"
    [[ -n "$version" && "$version" != "null" ]] && pass "plugin.json has version: $version" || fail "plugin.json missing 'version' field"
    [[ -n "$description" && "$description" != "null" ]] && pass "plugin.json has description" || fail "plugin.json missing 'description' field"

    # Semver format check
    if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      pass "plugin.json version is valid semver: $version"
    else
      fail "plugin.json version is not valid semver: $version"
    fi
  else
    warn "jq not installed — skipping JSON validation"
  fi

  # Required directories
  for dir in agents commands skills; do
    if [[ -d "$PLUGIN_DIR/$dir" ]]; then
      pass "$dir/ directory exists"
    else
      fail "$dir/ directory missing"
    fi
  done

  # No unexpected files inside .claude-plugin/ (plugin.json + marketplace.json are allowed)
  local extra_files
  extra_files=$(find "$PLUGIN_DIR/.claude-plugin" -type f ! -name "plugin.json" ! -name "marketplace.json" 2>/dev/null)
  if [[ -z "$extra_files" ]]; then
    pass "No unexpected files in .claude-plugin/"
  else
    fail "Unexpected files in .claude-plugin/: $extra_files"
  fi

  # marketplace.json exists and is valid
  if [[ -f "$PLUGIN_DIR/.claude-plugin/marketplace.json" ]]; then
    pass "marketplace.json exists"
    if command -v jq &>/dev/null; then
      if jq empty "$PLUGIN_DIR/.claude-plugin/marketplace.json" 2>/dev/null; then
        pass "marketplace.json is valid JSON"
        # Check required fields
        local mp_name mp_owner mp_plugins
        mp_name=$(jq -r '.name' "$PLUGIN_DIR/.claude-plugin/marketplace.json")
        mp_owner=$(jq -r '.owner.name' "$PLUGIN_DIR/.claude-plugin/marketplace.json")
        mp_plugins=$(jq -r '.plugins | length' "$PLUGIN_DIR/.claude-plugin/marketplace.json")
        [[ -n "$mp_name" && "$mp_name" != "null" ]] && pass "marketplace.json has name: $mp_name" || fail "marketplace.json missing 'name'"
        [[ -n "$mp_owner" && "$mp_owner" != "null" ]] && pass "marketplace.json has owner" || fail "marketplace.json missing 'owner.name'"
        [[ "$mp_plugins" -gt 0 ]] && pass "marketplace.json has $mp_plugins plugin(s)" || fail "marketplace.json has no plugins"
      else
        fail "marketplace.json is invalid JSON"
      fi
    fi
  else
    warn "marketplace.json missing — marketplace distribution not configured"
  fi

  # README exists
  [[ -f "$PLUGIN_DIR/README.md" ]] && pass "README.md exists" || fail "README.md missing"

  # settings.json exists and is valid JSON
  if [[ -f "$PLUGIN_DIR/settings.json" ]]; then
    pass "settings.json exists"
    if command -v jq &>/dev/null; then
      if jq empty "$PLUGIN_DIR/settings.json" 2>/dev/null; then
        pass "settings.json is valid JSON"
      else
        fail "settings.json is invalid JSON"
      fi
    fi
  else
    warn "settings.json missing"
  fi
}

# =============================================================================
# TEST: Expected files
# =============================================================================
test_expected_files() {
  section "Expected Files"

  # Agents
  local expected_agents=("horus" "zeus")
  for agent in "${expected_agents[@]}"; do
    if [[ -f "$PLUGIN_DIR/agents/$agent.md" ]]; then
      pass "agents/$agent.md exists"
    else
      fail "agents/$agent.md missing"
    fi
  done

  # Commands
  local expected_commands=(
    "horus" "zeus" "detect"
    "lint" "validate" "security-scan" "secret-audit"
    "diff-preview" "upgrade-check" "pipeline-check"
    "pre-commit" "k8s-compat"
    "add-service" "add-ingress" "argocd-app"
    "diagram" "flowchart"
    "tf-validate" "tf-security" "helm-upgrade" "helm-scaffold" "cicd-check"
  )
  for cmd in "${expected_commands[@]}"; do
    if [[ -f "$PLUGIN_DIR/commands/$cmd.md" ]]; then
      pass "commands/$cmd.md exists"
    else
      fail "commands/$cmd.md missing"
    fi
  done

  # Skills (each must have SKILL.md)
  local expected_skills=(
    "terraform-validate" "terraform-security"
    "cicd-enhancer" "helm-scaffold" "helm-version-upgrade"
    "yaml-fix-suggestions" "kustomize-resource-validation"
    "repo-detect"
  )
  for skill in "${expected_skills[@]}"; do
    if [[ -f "$PLUGIN_DIR/skills/$skill/SKILL.md" ]]; then
      pass "skills/$skill/SKILL.md exists"
    else
      fail "skills/$skill/SKILL.md missing"
    fi
  done

  # Docs
  [[ -f "$PLUGIN_DIR/docs/runbook.md" ]] && pass "docs/runbook.md exists" || fail "docs/runbook.md missing"
  [[ -f "$PLUGIN_DIR/docs/README.zh-TW.md" ]] && pass "docs/README.zh-TW.md exists" || fail "docs/README.zh-TW.md missing"

  # Scripts
  [[ -f "$PLUGIN_DIR/scripts/install-tools.sh" ]] && pass "scripts/install-tools.sh exists" || fail "scripts/install-tools.sh missing"
  [[ -x "$PLUGIN_DIR/scripts/install-tools.sh" ]] && pass "scripts/install-tools.sh is executable" || fail "scripts/install-tools.sh not executable"
}

# =============================================================================
# TEST: Skill frontmatter (strict — checks within frontmatter block only)
# =============================================================================
test_frontmatter() {
  section "Skill Frontmatter"

  while IFS= read -r -d '' skill_file; do
    local rel_path="${skill_file#$PLUGIN_DIR/}"
    local first_line
    first_line=$(head -1 "$skill_file")

    if [[ "$first_line" == "---" ]]; then
      # Extract frontmatter block (between first and second ---)
      local frontmatter
      frontmatter=$(sed -n '2,/^---$/p' "$skill_file" | sed '$d')

      # Check for name field within frontmatter
      if echo "$frontmatter" | grep -q "^name:"; then
        pass "$rel_path has 'name' in frontmatter"
      else
        fail "$rel_path missing 'name' in frontmatter block"
      fi

      # Check for description field within frontmatter
      if echo "$frontmatter" | grep -q "^description:"; then
        pass "$rel_path has 'description' in frontmatter"
      else
        fail "$rel_path missing 'description' in frontmatter block"
      fi

      # Check frontmatter is closed
      local close_count
      close_count=$(grep -c "^---$" "$skill_file" 2>/dev/null || echo "0")
      if [[ "$close_count" -ge 2 ]]; then
        pass "$rel_path frontmatter is properly closed"
      else
        fail "$rel_path frontmatter is not properly closed (missing closing ---)"
      fi
    else
      fail "$rel_path has no YAML frontmatter (first line is not '---')"
    fi
  done < <(find "$PLUGIN_DIR/skills" -name "SKILL.md" -print0 2>/dev/null)
}

# =============================================================================
# TEST: Command title format
# =============================================================================
test_command_titles() {
  section "Command Title Consistency"

  while IFS= read -r -d '' cmd_file; do
    local rel_path="${cmd_file#$PLUGIN_DIR/}"
    local title
    title=$(head -1 "$cmd_file")

    # Should start with # lowercase
    if [[ "$title" =~ ^#\ [a-z] ]]; then
      pass "$rel_path title is lowercase: $title"
    elif [[ "$title" =~ ^#\  ]]; then
      fail "$rel_path title not lowercase: $title"
    else
      fail "$rel_path has no # title on line 1: $title"
    fi

    # Should NOT contain /devops: prefix
    if echo "$title" | grep -q "/devops:"; then
      fail "$rel_path title contains /devops: prefix"
    else
      pass "$rel_path title has no /devops: prefix"
    fi

    # Title dash format should use em-dash (—) not triple-hyphen (---)
    if echo "$title" | grep -q " --- "; then
      fail "$rel_path title uses '---' instead of '—' (em-dash)"
    else
      pass "$rel_path title dash format OK"
    fi
  done < <(find "$PLUGIN_DIR/commands" -name "*.md" -print0 2>/dev/null)
}

# =============================================================================
# TEST: No hardcoded references
# =============================================================================
test_content_rules() {
  section "Content Rules (No Hardcoded References)"

  local search_dir="$PLUGIN_DIR"

  # Forbidden patterns (should not appear in any file except this test)
  # Format: "pattern|description"
  local forbidden_list=(
    "eye-of-horus|Repo-specific name"
    "awoogitlab|Internal GitLab URL"
    "de514-ia007|Hardcoded GCP project"
    "common\.service/|Repo-specific module path"
    "common\.ingress/|Repo-specific module path"
  )

  for entry in "${forbidden_list[@]}"; do
    IFS='|' read -r pattern desc <<< "$entry"
    local matches
    matches=$(grep -rl "$pattern" "$search_dir" \
      --include="*.md" --include="*.json" --include="*.sh" \
      2>/dev/null | grep -v ".git/" | grep -v "tests/" || true)

    if [[ -z "$matches" ]]; then
      pass "No '$pattern' found ($desc)"
    else
      fail "'$pattern' found in: $matches ($desc)"
    fi
  done

  # /devops: prefix should not appear in command titles (line 1 only)
  local prefix_in_title=0
  while IFS= read -r -d '' f; do
    if head -1 "$f" | grep -q "/devops:"; then
      ((prefix_in_title++))
    fi
  done < <(find "$PLUGIN_DIR/commands" -name "*.md" -print0 2>/dev/null)

  if [[ $prefix_in_title -eq 0 ]]; then
    pass "No /devops: prefix in command titles"
  else
    fail "$prefix_in_title command(s) have /devops: in title"
  fi
}

# =============================================================================
# TEST: Cross-references
# =============================================================================
test_references() {
  section "Cross-references"

  # Each skill that references supporting files — verify they exist
  while IFS= read -r -d '' skill_dir; do
    local skill_name
    skill_name=$(basename "$skill_dir")
    local skill_file="$skill_dir/SKILL.md"

    if [[ ! -f "$skill_file" ]]; then
      continue
    fi

    # Find .md file references in SKILL.md (like UPGRADE_PATTERNS.md, GKE_HARDENING.md)
    local refs
    refs=$(grep -oE '[A-Z_]+\.md' "$skill_file" 2>/dev/null | grep -v "SKILL.md" | sort -u || true)

    for ref in $refs; do
      if [[ -f "$skill_dir/$ref" ]]; then
        pass "skills/$skill_name/$ref referenced and exists"
      else
        fail "skills/$skill_name/$ref referenced in SKILL.md but missing"
      fi
    done
  done < <(find "$PLUGIN_DIR/skills" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)

  # Zeus command references should match actual command files
  if [[ -f "$PLUGIN_DIR/commands/zeus.md" ]]; then
    local zeus_refs
    zeus_refs=$(grep -oE '\b(lint|validate|security-scan|secret-audit|diff-preview|upgrade-check|pipeline-check|pre-commit|k8s-compat|add-service|add-ingress|argocd-app|diagram|flowchart)\b' \
      "$PLUGIN_DIR/commands/zeus.md" 2>/dev/null | sort -u || true)

    for ref in $zeus_refs; do
      if [[ -f "$PLUGIN_DIR/commands/$ref.md" ]]; then
        pass "zeus.md references '$ref' — command file exists"
      else
        warn "zeus.md references '$ref' — no matching command file"
      fi
    done
  fi

  # Horus command references should match actual command files
  if [[ -f "$PLUGIN_DIR/commands/horus.md" ]]; then
    local horus_refs
    horus_refs=$(grep -oE '\b(tf-validate|tf-security|helm-upgrade|helm-scaffold|cicd-check)\b' \
      "$PLUGIN_DIR/commands/horus.md" 2>/dev/null | sort -u || true)

    for ref in $horus_refs; do
      if [[ -f "$PLUGIN_DIR/commands/$ref.md" ]]; then
        pass "horus.md references '$ref' — command file exists"
      else
        warn "horus.md references '$ref' — no matching command file"
      fi
    done
  fi

  # Agent files referenced by commands should exist
  for agent_name in horus zeus; do
    if [[ -f "$PLUGIN_DIR/commands/$agent_name.md" ]]; then
      if grep -q "agents/$agent_name.md" "$PLUGIN_DIR/commands/$agent_name.md" 2>/dev/null; then
        if [[ -f "$PLUGIN_DIR/agents/$agent_name.md" ]]; then
          pass "commands/$agent_name.md references agents/$agent_name.md — exists"
        else
          fail "commands/$agent_name.md references agents/$agent_name.md — missing"
        fi
      fi
    fi
  done
}

# =============================================================================
# TEST: Security audit (no leaked secrets or sensitive data)
# =============================================================================
test_security() {
  section "Security Audit"

  local search_dir="$PLUGIN_DIR"

  # Check for potential hardcoded secrets
  local secret_patterns=(
    "password\s*[:=]\s*['\"][^'\"]+['\"]|Hardcoded password"
    "api[_-]?key\s*[:=]\s*['\"][A-Za-z0-9]{20,}['\"]|Hardcoded API key"
    "token\s*[:=]\s*['\"][A-Za-z0-9]{20,}['\"]|Hardcoded token"
    "AKIA[0-9A-Z]{16}|AWS access key"
  )

  for entry in "${secret_patterns[@]}"; do
    IFS='|' read -r pattern desc <<< "$entry"
    local matches
    matches=$(grep -rEn "$pattern" "$search_dir" \
      --include="*.md" --include="*.json" --include="*.sh" --include="*.yaml" --include="*.yml" \
      2>/dev/null | grep -v ".git/" | grep -v "tests/" || true)

    if [[ -z "$matches" ]]; then
      pass "No $desc detected"
    else
      fail "$desc found: $matches"
    fi
  done

  # Check that reference data files have disclaimer headers
  local ref_files=(
    "skills/terraform-security/GKE_HARDENING.md"
    "skills/terraform-security/HELM_SECURITY.md"
  )
  for ref in "${ref_files[@]}"; do
    local full_path="$PLUGIN_DIR/$ref"
    if [[ -f "$full_path" ]]; then
      if grep -q "reference implementation\|discovered.*dynamically\|runtime" "$full_path" 2>/dev/null; then
        pass "$ref has portability disclaimer"
      else
        fail "$ref missing portability disclaimer (contains repo-specific data)"
      fi
    fi
  done

  # Check for real GCP project IDs (format: project-prefix-env, 3+ digit IDs)
  local gcp_matches
  gcp_matches=$(grep -rEn 'PROJECT_ID.*"[0-9]{3,}"' "$search_dir" \
    --include="*.md" --include="*.yaml" --include="*.yml" \
    2>/dev/null | grep -v ".git/" | grep -v "tests/" | grep -v 'CI_PROJECT_ID' || true)

  if [[ -z "$gcp_matches" ]]; then
    pass "No hardcoded numeric project IDs"
  else
    fail "Hardcoded numeric project IDs found: $gcp_matches"
  fi
}

# =============================================================================
# TEST: Command-skill consistency
# =============================================================================
test_command_skill_consistency() {
  section "Command-Skill Consistency"

  # Horus standalone commands should each reference their corresponding skill
  local horus_command_skills=(
    "tf-validate|terraform-validate"
    "tf-security|terraform-security"
    "helm-upgrade|helm-version-upgrade"
    "helm-scaffold|helm-scaffold"
    "cicd-check|cicd-enhancer"
  )

  for entry in "${horus_command_skills[@]}"; do
    IFS='|' read -r cmd skill <<< "$entry"
    local cmd_file="$PLUGIN_DIR/commands/$cmd.md"
    local skill_file="$PLUGIN_DIR/skills/$skill/SKILL.md"

    if [[ -f "$cmd_file" && -f "$skill_file" ]]; then
      pass "commands/$cmd.md and skills/$skill/SKILL.md both exist"
    elif [[ ! -f "$cmd_file" ]]; then
      fail "commands/$cmd.md missing (paired with skills/$skill/)"
    elif [[ ! -f "$skill_file" ]]; then
      fail "skills/$skill/SKILL.md missing (paired with commands/$cmd.md)"
    fi
  done

  # All commands listed in README should exist
  if [[ -f "$PLUGIN_DIR/README.md" ]]; then
    local readme_cmds
    readme_cmds=$(grep -oE '/devops:[a-z0-9-]+' "$PLUGIN_DIR/README.md" 2>/dev/null | sed 's|/devops:||' | sort -u || true)

    for cmd in $readme_cmds; do
      if [[ -f "$PLUGIN_DIR/commands/$cmd.md" ]]; then
        pass "README references /devops:$cmd — command file exists"
      else
        fail "README references /devops:$cmd — command file missing"
      fi
    done
  fi

  # All commands listed in runbook should exist
  if [[ -f "$PLUGIN_DIR/docs/runbook.md" ]]; then
    local runbook_cmds
    runbook_cmds=$(grep -oE '/devops:[a-z0-9-]+' "$PLUGIN_DIR/docs/runbook.md" 2>/dev/null | sed 's|/devops:||' | sort -u || true)

    for cmd in $runbook_cmds; do
      if [[ -f "$PLUGIN_DIR/commands/$cmd.md" ]]; then
        pass "Runbook references /devops:$cmd — command file exists"
      else
        fail "Runbook references /devops:$cmd — command file missing"
      fi
    done
  fi

  # All commands in zh-TW README should exist
  if [[ -f "$PLUGIN_DIR/docs/README.zh-TW.md" ]]; then
    local zhtw_cmds
    zhtw_cmds=$(grep -oE '/devops:[a-z0-9-]+' "$PLUGIN_DIR/docs/README.zh-TW.md" 2>/dev/null | sed 's|/devops:||' | sort -u || true)

    for cmd in $zhtw_cmds; do
      if [[ -f "$PLUGIN_DIR/commands/$cmd.md" ]]; then
        pass "zh-TW README references /devops:$cmd — command file exists"
      else
        fail "zh-TW README references /devops:$cmd — command file missing"
      fi
    done
  fi
}

# =============================================================================
# TEST: Changelog generation (dry-run)
# =============================================================================
test_changelog() {
  section "Changelog Generation"

  # Check CI workflow exists
  local ci_file="$PLUGIN_DIR/.github/workflows/plugin-ci.yml"
  if [[ -f "$ci_file" ]]; then
    pass "CI workflow exists"
  else
    fail "CI workflow missing at .github/workflows/plugin-ci.yml"
    return
  fi

  # Check CI workflow contains changelog job
  if grep -q "changelog" "$ci_file" 2>/dev/null; then
    pass "CI workflow has changelog job"
  else
    fail "CI workflow missing changelog job"
  fi

  # Check CI workflow references git tag
  if grep -q "git tag" "$ci_file" 2>/dev/null; then
    pass "CI changelog uses git tags"
  else
    warn "CI changelog does not reference git tags"
  fi

  # If we're in a git repo, verify changelog script logic
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    # Simulate changelog generation (dry run)
    local tag_count
    tag_count=$(git -C "$PLUGIN_DIR" tag 2>/dev/null | wc -l | tr -d ' ')
    pass "Git repo accessible, $tag_count tag(s) found"

    local commit_count
    commit_count=$(git -C "$PLUGIN_DIR" log --oneline 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$commit_count" -gt 0 ]]; then
      pass "Git history has $commit_count commit(s) for changelog"
    else
      warn "No git commits found — changelog will be empty"
    fi
  else
    warn "Not in a git repo — skipping changelog dry-run"
  fi
}

# =============================================================================
# TEST: Install script
# =============================================================================
test_install_script() {
  section "Install Script"

  local script="$PLUGIN_DIR/scripts/install-tools.sh"

  if [[ ! -f "$script" ]]; then
    fail "install-tools.sh not found"
    return
  fi

  # Shellcheck (if available)
  if command -v shellcheck &>/dev/null; then
    if shellcheck -S warning "$script" 2>/dev/null; then
      pass "install-tools.sh passes shellcheck"
    else
      warn "install-tools.sh has shellcheck warnings"
    fi
  else
    warn "shellcheck not installed — skipping"
  fi

  # Check mode should run without errors
  if bash "$script" check &>/dev/null; then
    pass "install-tools.sh check runs successfully"
  else
    fail "install-tools.sh check exited with error"
  fi

  # Verify all TOOLS entries have correct pipe-delimited format
  local bad_entries=0
  while IFS= read -r line; do
    # Each entry should have exactly 5 pipes (6 fields)
    local pipe_count
    pipe_count=$(echo "$line" | tr -cd '|' | wc -c | tr -d ' ')
    if [[ "$pipe_count" -ne 5 ]]; then
      ((bad_entries++))
    fi
  done < <(grep '^  "' "$script" | grep '|')

  if [[ $bad_entries -eq 0 ]]; then
    pass "install-tools.sh all TOOLS entries have correct format"
  else
    fail "install-tools.sh has $bad_entries malformed TOOLS entries"
  fi
}

# =============================================================================
# Main
# =============================================================================
main() {
  printf "${BOLD}DevOps Plugin — Test Suite${NC}\n"
  printf "=========================\n"
  printf "Plugin dir: %s\n" "$PLUGIN_DIR"

  local filter="${1:-all}"

  case "$filter" in
    structure)
      test_structure
      test_expected_files
      ;;
    content)
      test_frontmatter
      test_command_titles
      test_content_rules
      ;;
    refs)
      test_references
      test_command_skill_consistency
      ;;
    security)
      test_security
      ;;
    changelog)
      test_changelog
      ;;
    *)
      test_structure
      test_expected_files
      test_frontmatter
      test_command_titles
      test_content_rules
      test_references
      test_command_skill_consistency
      test_security
      test_changelog
      test_install_script
      ;;
  esac

  # Summary
  echo
  printf "%.0s═" {1..50}; echo
  printf "${BOLD}Results:${NC} ${GREEN}%d passed${NC}, ${RED}%d failed${NC}, ${YELLOW}%d warnings${NC}\n" \
    "$PASS" "$FAIL" "$WARN"

  if [[ $FAIL -gt 0 ]]; then
    echo
    printf "${RED}Failures:${NC}\n"
    for err in "${ERRORS[@]}"; do
      printf "  - %s\n" "$err"
    done
    exit 1
  fi

  exit 0
}

main "$@"
