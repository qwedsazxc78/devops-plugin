# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A **Claude Code plugin** (`devops` namespace) providing two AI-powered DevOps agents and 20+ pipeline commands. Published to the Claude Code marketplace as `devops@devops-go`.

## Architecture

```
.claude-plugin/          # Plugin manifest + marketplace config
  plugin.json            # Plugin name, version, description
  marketplace.json       # Marketplace listing (name: devops-go)
agents/                  # Agent definitions (YAML frontmatter + markdown)
  horus.md               # IaC agent — Terraform + Helm + GKE
  zeus.md                # GitOps agent — Kustomize + ArgoCD
commands/                # User-invocable /devops:* commands
  horus.md               # Activates Horus agent + defines all pipelines (*full, *upgrade, etc.)
  zeus.md                # Activates Zeus agent + defines all pipelines (*full, *pre-merge, etc.)
  status.md              # Standalone tool checker (no agent needed)
  detect.md              # Repo type detection
  *.md                   # Individual skill commands (lint, validate, security-scan, etc.)
skills/                  # Model-invoked skills (auto-triggered by context)
  <skill-name>/SKILL.md  # Skill definition with YAML frontmatter
  <skill-name>/*.md      # Supporting reference data for the skill
settings.json            # Default agent selection
```

### Key Relationships

- **`commands/horus.md`** and **`commands/zeus.md`** are the core files — they define agent personas AND all pipeline step sequences. Most feature changes happen here.
- **`agents/*.md`** define which skills each agent can use. They reference `skills/` by name.
- **`skills/*/SKILL.md`** are self-contained workflows. Commands orchestrate them; agents route to them.
- **`commands/status.md`** is fully self-contained — it has its own inline tool registry and does NOT depend on `scripts/install-tools.sh`.

### Naming Conventions

- Command titles: `# <command-name> — <Description>` (em-dash, lowercase command name, no `/devops:` prefix)
- Skill frontmatter must have `name` and `description` fields, properly closed `---`
- Pipeline reports: `devops-{agent}-full-check-YYYY-MM-DD.md`
- Commit messages: Conventional Commits (`feat(helm):`, `fix(security):`, `docs:`)

## Testing

```bash
# Run all tests (285 tests)
bash tests/test-plugin-structure.sh

# Run specific test category
bash tests/test-plugin-structure.sh structure   # Plugin file structure
bash tests/test-plugin-structure.sh content     # Frontmatter, titles, content rules
bash tests/test-plugin-structure.sh refs        # Cross-file references, images
bash tests/test-plugin-structure.sh security    # Hardcoded secrets/IDs
bash tests/test-plugin-structure.sh changelog   # CI changelog validation
bash tests/test-plugin-structure.sh pipeline    # Horus pipeline definition consistency
```

## Content Rules (Enforced by Tests)

Repo-specific names, internal GitLab URLs, hardcoded GCP project IDs, passwords, API keys, tokens, and AWS access keys must NOT appear in plugin files. The test suite checks for these automatically (see `test_content_rules` in the test file for the exact patterns). Excluded from scanning: `tests/`, `CHANGELOG.md`, `docs/examples/`, `CLAUDE.md`.

## Version Bumping

Three files must be updated together:
1. `.claude-plugin/plugin.json` — `version`
2. `.claude-plugin/marketplace.json` — `metadata.version` AND `plugins[0].version`
3. `CHANGELOG.md` — add version entry

## Key Design Constraints

- **No hardcoded paths**: Horus discovers TF directories dynamically (`find . -name "*.tf"`), Zeus discovers Kustomize modules dynamically. Never hardcode `application/` or specific module paths.
- **Graceful degradation**: Missing tools skip the check and show install commands. Only "required" tools block execution.
- **`/devops:status` is standalone**: Plugin marketplace users don't have `scripts/install-tools.sh`. The status command uses `command -v` directly with an inline tool registry.
- **User-controlled terraform init**: Step 2 of Horus `*full` pipeline always asks the user (a/b/c options) because init behavior varies by project.
