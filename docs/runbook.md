# DevOps Plugin — Runbook

Complete guide to installing, configuring, and using the DevOps plugin with Horus (IaC) and Zeus (GitOps) agents.

> **Cross-platform:** Works with Claude Code, OpenAI Codex CLI, and Google Gemini CLI via the [Agent Skills](https://agentskills.io/specification) open standard.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Claude Code](#claude-code)
  - [OpenAI Codex CLI](#openai-codex-cli)
  - [Google Gemini CLI](#google-gemini-cli)
  - [Cross-Platform (npx skills)](#cross-platform-npx-skills)
  - [Updating](#updating)
- [Tool Setup](#tool-setup)
- [Getting Started](#getting-started)
- [Agent Reference](#agent-reference)
- [Command Reference](#command-reference)
- [Skill Reference](#skill-reference)
- [Common Workflows](#common-workflows)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

- macOS or Linux (Windows via WSL2)
- Git
- One of: Homebrew (macOS/Linux) or apt (Debian/Ubuntu)
- One of the following AI coding assistants:
  - Claude Code v1.0.33+ (`claude --version`)
  - OpenAI Codex CLI (`codex --version`)
  - Google Gemini CLI (`gemini --version`)

---

## Installation

### Claude Code

#### Option A: Marketplace (recommended)

```bash
# Inside Claude Code — add the marketplace, then install the plugin
/plugin marketplace add qwedsazxc78/devops-plugin
/plugin install devops@devops-go
```

#### Option B: Local development

```bash
git clone https://github.com/qwedsazxc78/devops-plugin.git
claude --plugin-dir ./devops-plugin
```

#### Option C: Project-level auto-install

Add to your project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "devops-go": {
      "source": {
        "source": "github",
        "repo": "qwedsazxc78/devops-plugin"
      }
    }
  },
  "enabledPlugins": {
    "devops@devops-go": true
  }
}
```

Team members will be prompted to install when they trust the project folder.

### OpenAI Codex CLI

```bash
git clone https://github.com/qwedsazxc78/devops-plugin.git
cd devops-plugin && bash codex/setup.sh
```

The setup script:
1. Creates symlinks from `.agents/skills/` → `skills/` (all 8 skills)
2. Copies `codex/AGENTS.md` to your project root as `AGENTS.md`
3. Configures agent routing (Horus for IaC, Zeus for GitOps)

After setup, use Codex with natural language:
```bash
codex "Validate all Terraform code in this repo"
codex "Run a security scan on my Helm charts"
codex "Check if my Kustomize manifests are ready to merge"
```

**Skill scoping:** Codex supports workspace (`.agents/skills/`), user (`~/.agents/skills/`), and admin (`/etc/codex/skills/`) skill locations. The setup script installs to workspace scope by default.

### Google Gemini CLI

```bash
git clone https://github.com/qwedsazxc78/devops-plugin.git
cd devops-plugin && bash gemini/setup.sh
```

The setup script:
1. Creates symlinks from `.gemini/skills/` → `skills/` (all 8 skills)
2. Copies `gemini/GEMINI.md` and `gemini/agents/` to `.gemini/`
3. Configures agent routing (Horus for IaC, Zeus for GitOps)

After setup, use Gemini with natural language:
```bash
gemini "Scan all Helm chart versions for upgrades"
gemini "Run a pre-merge check on my GitOps manifests"
gemini "Generate an architecture diagram"
```

**Note:** Gemini CLI natively reads SKILL.md files from `.gemini/skills/` — no format conversion needed.

### Cross-Platform (npx skills)

[`npx skills`](https://github.com/vercel-labs/skills) auto-detects all installed agents and routes skills to the correct directories:

```bash
# Install all DevOps skills
npx skills add qwedsazxc78/devops-plugin

# Install specific skills only
npx skills add qwedsazxc78/devops-plugin --skill terraform-validate
npx skills add qwedsazxc78/devops-plugin --skill helm-version-upgrade
```

This works for Claude Code, Codex CLI, and Gemini CLI simultaneously.

### Updating

```bash
# Git-based update
cd devops-plugin
git fetch origin main
git log HEAD..origin/main --oneline    # Review changes
git pull origin main

# Re-sync platform adapters after update
bash codex/setup.sh     # If using Codex CLI
bash gemini/setup.sh    # If using Gemini CLI

# Or use npx skills (auto-detects all agents)
npx skills update

# Or use the built-in version check
bash scripts/version-check.sh
```

**Pin to a specific version:**

```bash
git tag -l "v*" --sort=-version:refname    # List versions
git checkout v1.2.0                         # Pin version
```

---

## Tool Setup

### Quick start (interactive)

```bash
# From the plugin directory:
./scripts/install-tools.sh
```

This will:
1. Detect your platform (macOS/Linux, brew/apt/pip)
2. Show all tools with install status
3. Prompt to install missing tools

### Check only

```bash
./scripts/install-tools.sh check          # All tools
./scripts/install-tools.sh check zeus     # GitOps tools only
./scripts/install-tools.sh check horus    # IaC tools only
```

### Install directly

```bash
./scripts/install-tools.sh install          # All tools
./scripts/install-tools.sh install zeus     # GitOps tools only
./scripts/install-tools.sh install horus    # IaC tools only
```

### Manual installation

If the script fails for specific tools, install them manually:

#### Homebrew (macOS/Linux)

```bash
# Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Shared
brew install kubectl jq yq git

# Zeus (GitOps)
brew install kustomize kubeconform kube-score kube-linter
brew install FairwindsOps/tap/polaris FairwindsOps/tap/pluto
brew install conftest trivy gitleaks

# Horus (IaC)
brew install terraform tflint tfsec
```

#### pip (Python tools)

```bash
# Ensure pip is available
python3 -m ensurepip --upgrade

# Zeus tools
pip3 install yamllint checkov

# Horus tools
pip3 install pre-commit checkov
```

#### apt (Debian/Ubuntu)

```bash
sudo apt-get update
sudo apt-get install -y git jq
sudo snap install kubectl --classic
sudo snap install kustomize yq
```

### Tool summary

| Tool | Agent | Tier | macOS | Linux | pip |
|------|-------|------|-------|-------|-----|
| git | Shared | Required | brew | apt | - |
| kubectl | Shared | Required | brew | snap | - |
| jq | Shared | Required | brew | apt | - |
| yq | Shared | Recommended | brew | snap | - |
| kustomize | Zeus | Required | brew | snap | - |
| yamllint | Zeus | Recommended | - | - | pip |
| kubeconform | Zeus | Recommended | brew | - | - |
| kube-score | Zeus | Recommended | brew | - | - |
| kube-linter | Zeus | Recommended | brew | - | - |
| polaris | Zeus | Recommended | brew | - | - |
| pluto | Zeus | Recommended | brew | - | - |
| conftest | Zeus | Recommended | brew | - | - |
| checkov | Both | Recommended | - | - | pip |
| trivy | Zeus | Recommended | brew | - | - |
| gitleaks | Zeus | Recommended | brew | - | - |
| terraform | Horus | Required | brew | - | - |
| tflint | Horus | Recommended | brew | - | - |
| tfsec | Horus | Recommended | brew | - | - |
| pre-commit | Horus | Recommended | - | - | pip |

**Note:** All skills gracefully degrade when recommended tools are missing — they skip the check and show the install command. Only _required_ tools block execution.

---

## Getting Started

### 1. Detect your repo type

```
/devops:detect
```

This scans the repo for IaC (Terraform) and GitOps (Kustomize) indicators and recommends the right agent.

### 2. Start an agent

```
/devops:horus     # IaC repos (Terraform + Helm + GKE)
/devops:zeus      # GitOps repos (Kustomize + ArgoCD)
```

### 3. Run a pipeline

Once inside an agent session, type a pipeline command:

```
*help             # Show available pipelines
*full             # Run the full pipeline
*status           # Check tool availability
*exit             # End session
```

### 4. Or run individual commands

You don't need to start an agent to use individual commands:

```
/devops:lint              # Quick lint (Zeus)
/devops:validate          # Full validation (Zeus)
/devops:security-scan     # Security scan (Zeus)
```

---

## Agent Reference

### Horus — IaC Operations Engineer

**Domain:** Terraform + Helm + GKE platforms

| Pipeline | Steps |
|----------|-------|
| `*full` | terraform fmt → init → validate → helm versions → JSON schema → module paths → env configs → security → report |
| `*upgrade` | version check → atomic update → validate → security → commit |
| `*security` | full audit → cross-reference → findings report → remediation |
| `*validate` | fmt → validate → schema → consistency → security → report |
| `*new-module` | scaffold → validate → security → commit |
| `*cicd` | analyze → recommend → validate → plan |
| `*health` | version check → security → validation → dashboard |

### Zeus — GitOps Engineer

**Domain:** Kustomize + ArgoCD workflows

| Pipeline | Steps |
|----------|-------|
| `*full` | pre-commit → validate → security-scan → upgrade-check → pipeline-check → diff-preview → diagram → report |
| `*pre-merge` | lint → validate → security-scan → diff-preview |
| `*health-check` | validate → security-scan → secret-audit → upgrade-check → pipeline-check → dashboard |
| `*review` | scope → lint → validate → security-scan → upgrade-check → diff-preview → diagram → verdict |
| `*onboard` | discovery → add-service → add-ingress → argocd-app → validate → diagram → pre-commit |
| `*diagram` | diagram (all formats) → flowchart (all types) |
| `*status` | tool installation check |

---

## Command Reference

### Zeus Commands

| Command | Description | Required Tools |
|---------|-------------|----------------|
| `/devops:lint` | YAML lint + kustomize build | kustomize, yamllint |
| `/devops:validate` | 7-tool validation pipeline | kustomize + optional tools |
| `/devops:security-scan` | Multi-tool security scan | kustomize + optional tools |
| `/devops:secret-audit` | Secret inventory + drift | kustomize, gitleaks |
| `/devops:diff-preview` | Branch diff + risk assessment | kustomize, git |
| `/devops:upgrade-check` | Deprecated APIs + version drift | pluto, kubeconform |
| `/devops:pipeline-check` | CI/CD pipeline audit | git |
| `/devops:pre-commit` | Run pre-commit hooks | pre-commit |
| `/devops:k8s-compat` | K8s version compatibility | kubeconform, pluto |
| `/devops:add-service` | Scaffold new service | kustomize |
| `/devops:add-ingress` | Create ingress resources | kustomize |
| `/devops:argocd-app` | Create/validate ArgoCD app | kustomize |
| `/devops:diagram` | Architecture diagrams | git |
| `/devops:flowchart` | Workflow flowcharts | git |

### Horus Commands

| Command | Description | Required Tools |
|---------|-------------|----------------|
| `/devops:tf-validate` | Terraform fmt + validate + consistency | terraform, tflint |
| `/devops:tf-security` | Terraform security audit (GKE + IAM + Helm) | terraform + optional tfsec |
| `/devops:helm-upgrade` | Helm chart version upgrade (atomic 3-file) | terraform |
| `/devops:helm-scaffold` | Scaffold new Helm module | terraform |
| `/devops:cicd-check` | CI/CD pipeline gap analysis + snippets | git |

### Utility Commands

| Command | Description |
|---------|-------------|
| `/devops:detect` | Detect repo type, recommend agent |

---

## Skill Reference

Skills are model-invoked — Claude uses them automatically based on context.

| Skill | Agent | Trigger |
|-------|-------|---------|
| repo-detect | Both | Plugin load, agent selection |
| yaml-fix-suggestions | Zeus | Any `.yaml` edit in Kustomize dirs |
| kustomize-resource-validation | Zeus | Any `kustomization.yaml` edit |
| terraform-validate | Horus | Terraform validation tasks |
| terraform-security | Horus | Security audit tasks |
| helm-version-upgrade | Horus | Helm upgrade tasks |
| helm-scaffold | Horus | New module scaffolding |
| cicd-enhancer | Horus | CI/CD improvement tasks |

---

## Common Workflows

### Pre-merge check (GitOps)

```
/devops:zeus
*pre-merge
```

Or without starting the agent:

```
/devops:lint
/devops:validate
/devops:security-scan quick
/devops:diff-preview
```

### Onboard a new service (GitOps)

```
/devops:zeus
*onboard
```

Follow the interactive prompts to scaffold, configure, and validate.

### Upgrade Helm charts (IaC)

```
/devops:horus
*upgrade
```

### Full health check (either)

```
/devops:horus    # then *health
/devops:zeus     # then *health-check
```

---

## Troubleshooting

### Plugin not loading

```bash
# Verify Claude Code version
claude --version  # Needs v1.0.33+

# Verify plugin structure
ls .claude-plugin/plugin.json  # Must exist
```

### Commands not found

```bash
# Check plugin is loaded
/help  # Should show /devops: namespace

# Restart Claude Code after plugin changes
```

### Tool not installed

All commands show install instructions when a tool is missing. Run:

```bash
./scripts/install-tools.sh check
```

### pip not found

```bash
# macOS
python3 -m ensurepip --upgrade

# Linux
sudo apt-get install python3-pip
```

### Homebrew not found

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Kustomize build fails

```bash
# Check kustomize version
kustomize version  # Needs v5.3.0+

# Upgrade if needed
brew upgrade kustomize
```

### Agent session stuck

Type `*exit` to end the session, or start a new Claude Code session.
