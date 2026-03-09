<p align="center">
  <img src="docs/images/logo.png" alt="DevOps Plugin Logo" width="128">
</p>

# DevOps Plugin for Claude Code

**English** | [繁體中文](docs/README.zh-TW.md)

> Two AI-powered DevOps agents — **Horus** (IaC) and **Zeus** (GitOps) — with 20+ automated pipeline commands for Terraform, Helm, Kustomize, and ArgoCD.
>
> **Cross-platform:** Works with **Claude Code**, **OpenAI Codex CLI**, and **Google Gemini CLI** via the [Agent Skills](https://agentskills.io/specification) open standard.

## Quick Start

### 1. Install the plugin

Choose the method that matches your AI coding assistant:

<details open>
<summary><b>Claude Code</b> (recommended)</summary>

```bash
# Option A: Marketplace install (recommended)
/plugin marketplace add qwedsazxc78/devops-plugin
/plugin install devops@devops-go

# Option B: Local development
git clone https://github.com/qwedsazxc78/devops-plugin.git
claude --plugin-dir ./devops-plugin
```

</details>

<details>
<summary><b>OpenAI Codex CLI</b></summary>

```bash
git clone https://github.com/qwedsazxc78/devops-plugin.git
cd devops-plugin && bash codex/setup.sh
# Creates .agents/skills/ symlinks + copies AGENTS.md to your project
```

After setup, Codex CLI automatically loads the skills. Use natural language:
```
codex "Validate my Terraform code"
codex "Run a security scan on my Helm charts"
```

</details>

<details>
<summary><b>Google Gemini CLI</b></summary>

```bash
git clone https://github.com/qwedsazxc78/devops-plugin.git
cd devops-plugin && bash gemini/setup.sh
# Creates .gemini/skills/ symlinks + copies GEMINI.md and agent files
```

After setup, Gemini CLI automatically loads the skills. Use natural language:
```
gemini "Check if my Kustomize manifests are ready to merge"
gemini "Scan for security issues in my Terraform modules"
```

</details>

<details>
<summary><b>Cross-Platform (npx skills)</b></summary>

[`npx skills`](https://github.com/vercel-labs/skills) auto-detects installed agents and routes skills to the correct directories:

```bash
# Install all DevOps skills (works with Claude, Codex, and Gemini)
npx skills add qwedsazxc78/devops-plugin

# Install specific skills only
npx skills add qwedsazxc78/devops-plugin --skill terraform-validate
npx skills add qwedsazxc78/devops-plugin --skill terraform-security
```

</details>

### 2. Update to latest version

```bash
# Git-based update
cd devops-plugin && git pull origin main

# Or via npx skills
npx skills update

# Re-sync platform adapters (if using Codex or Gemini)
bash codex/setup.sh    # Codex CLI
bash gemini/setup.sh   # Gemini CLI
```

### 3. Install required tools

<details>
<summary><b>macOS</b></summary>

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Core tools
brew install git kubectl jq yq

# GitOps (Zeus)
brew install kustomize kubeconform kube-score kube-linter trivy gitleaks
brew install FairwindsOps/tap/polaris FairwindsOps/tap/pluto conftest

# IaC (Horus)
brew install terraform tflint tfsec

# Python tools (pick one)
uv tool install yamllint checkov pre-commit   # fast — recommended
# or: pip3 install yamllint checkov pre-commit
```

> **Tip:** Install [uv](https://docs.astral.sh/uv/) for faster Python tool management: `curl -LsSf https://astral.sh/uv/install.sh | sh`

</details>

<details>
<summary><b>Linux (Debian/Ubuntu)</b></summary>

```bash
# Core tools
sudo apt-get update && sudo apt-get install -y git jq
sudo snap install kubectl --classic
sudo snap install kustomize yq

# Python tools (pick one)
uv tool install yamllint checkov pre-commit   # fast — recommended
# or: pip3 install yamllint checkov pre-commit

# Other tools — install via binary releases or Homebrew for Linux
# See docs/runbook.md for detailed instructions
```

</details>

<details>
<summary><b>Windows (WSL2)</b></summary>

```bash
# 1. Install WSL2 with Ubuntu (run in PowerShell as Admin)
wsl --install -d Ubuntu

# 2. Inside WSL2 — core tools via apt/snap
sudo apt-get update && sudo apt-get install -y git jq
sudo snap install kubectl --classic
sudo snap install kustomize terraform --classic

# 3. Python tools (pick one)
curl -LsSf https://astral.sh/uv/install.sh | sh  # install uv first
uv tool install yamllint checkov pre-commit        # fast — recommended
# or: pip3 install yamllint checkov pre-commit

# 4. Install Homebrew for Linux (for tools not in apt/snap)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 5. Remaining tools via Homebrew
# GitOps (Zeus)
brew install kubeconform kube-score kube-linter trivy gitleaks
brew install FairwindsOps/tap/polaris FairwindsOps/tap/pluto conftest

# IaC (Horus)
brew install tflint tfsec
```

> **Note:** If `snap` is unavailable (older WSL2 without systemd), use Homebrew for Linux for all tools.

</details>

Or use the interactive installer:

```bash
./scripts/install-tools.sh          # Interactive check + install
./scripts/install-tools.sh check    # Check only
```

### 4. Check tool installation (Claude Code)

```
/devops:status              # Check all tools + install missing
/devops:status horus        # IaC tools only
/devops:status zeus         # GitOps tools only
```

### 5. Detect your repo type (Claude Code)

```
/devops:detect
```

### 6. Start an agent (Claude Code)

```
/devops:horus     # IaC repos (Terraform + Helm + GKE)
/devops:zeus      # GitOps repos (Kustomize + ArgoCD)
```

---

## Agents

### Horus — IaC Operations Engineer

The all-seeing guardian of infrastructure integrity. Pipeline-driven, safety-first operations for Terraform + Helm + GKE.

| Pipeline | Purpose |
|----------|---------|
| `*full` | Full check with YAML step records + markdown report |
| `*upgrade` | Upgrade Helm chart versions (atomic 3-file update) |
| `*security` | Security audit (GKE + Helm + IAM) |
| `*validate` | Full validation (fmt + schema + consistency) |
| `*new-module` | Scaffold a new Helm module |
| `*cicd` | CI/CD pipeline improvement |
| `*health` | Platform health dashboard |

### Zeus — GitOps Engineer

Pipeline orchestrator for Kustomize + ArgoCD workflows. Validation, security, scaffolding, and visualization.

| Pipeline | Purpose |
|----------|---------|
| `*full` | Full pipeline + YAML/MD reports |
| `*pre-merge` | Pre-MR essential checks |
| `*health-check` | Repository health assessment |
| `*review` | MR review pipeline |
| `*onboard` | Service onboarding (interactive) |
| `*diagram` | Generate architecture diagrams |
| `*status` | Tool installation check |

---

## Example Session

### Zeus (GitOps) — Full Pipeline Check

Activate Zeus and run the `*full` pipeline for a complete GitOps repository validation:

![Zeus Full Pipeline — discovery, tool status, 7-step pipeline with parallel execution](docs/images/zeus-full-pipeline.png)

The `*full` pipeline discovers modules and environments, checks tool availability, then runs 7 steps (pre-commit, validation, security, upgrade check, pipeline audit, diff preview, diagrams) and produces a full report:

> Example report: [`docs/examples/devops-zeus-full-check-2026-03-06.md`](docs/examples/devops-zeus-full-check-2026-03-06.md)

### Horus (IaC) — Full Pipeline Check

Activate Horus and run the `*full` pipeline for a complete infrastructure health check:

![Horus Activation — agent menu and *full pipeline start](docs/images/horus-activation.png)

The `*full` pipeline runs 10 steps (discovery + terraform CLI + file analysis) and produces a dashboard with actionable insights:

![Horus Full Pipeline — results dashboard with insights and next actions](docs/images/horus-full-pipeline.png)

```
  Full Pipeline Complete

  +-----------------------------------------------------+
  |         Horus Full Pipeline — 2026-03-06             |
  +-----------------------------------------------------+
  |  Overall: NEEDS ATTENTION                            |
  +-----------------------------------------------------+
  |  Step 1: Terraform Format        PASS                |
  |  Step 2: Terraform Init          PASS                |
  |  Step 3: Terraform Validate      PASS                |
  |  Step 4: Helm Version Check      FAIL (5 issues)     |
  |  Step 5: JSON Schema             PASS                |
  |  Step 6: Module Paths            PASS                |
  |  Step 7: Env Configs             WARN (litellm DR)   |
  |  Step 8: Security Scan           WARN (14 findings)  |
  +-----------------------------------------------------+

  ★ Insight ─────────────────────────────────────
  - Step 4 FAIL is cosmetic — TF + variable files are consistent;
    only helm_install.md is stale for 5 entries. Quick auto-fix available.
  - Step 7 WARN on litellm is a latent bug — DR workspace deploys
    will crash on missing file. Creating stub DR configs is critical.
  - Step 8 — 4 high-severity hardcoded secrets (ArgoCD Slack tokens,
    Airflow key) are the highest-risk items in version control.
  ─────────────────────────────────────────────────

  Reports written to:
  - Step YAMLs: docs/reports/2026-03-06/*.yaml
  - Summary:    docs/reports/devops-horus-full-check-2026-03-06.md

  What would you like to do next?
  1. Auto-fix helm_install.md (update 2 versions + add 3 missing entries)
  2. Create litellm DR config stubs
  3. Deep-dive on security findings
  4. Something else
```

> Example report: [`docs/examples/devops-horus-full-check-2026-03-06.md`](docs/examples/devops-horus-full-check-2026-03-06.md)

---

## Use Cases — Just Say What You Need

You don't need to memorize commands. Describe your goal in natural language (English or 中文), and the plugin routes to the right pipeline automatically.

### Horus (IaC) Examples

| What you say | Pipeline |
|---|---|
| "Scan all Helm chart versions" / 「掃描所有 Helm chart 版本」 | `*upgrade` |
| "Validate all my Terraform code" / 「驗證所有 Terraform 程式碼」 | `*validate` |
| "Run a security audit" / 「做一次安全稽核」 | `*security` |
| "Analyze CI/CD pipeline" / 「分析 CI/CD 流水線」 | `*cicd` |
| "Add a new Helm module for cert-manager" / 「建立 cert-manager 的 Helm module」 | `*new-module` |
| "Show platform health dashboard" / 「顯示平台健康儀表板」 | `*health` |

### Zeus (GitOps) Examples

| What you say | Pipeline |
|---|---|
| "Check if my changes are ready to merge" / 「我的修改可以合併了嗎？」 | `*pre-merge` |
| "Scan manifests for security issues" / 「掃描有沒有安全漏洞」 | `*full` (security) |
| "Help me onboard a new service" / 「幫我上線新服務」 | `*onboard` |
| "Generate architecture diagram" / 「幫我畫架構圖」 | `*diagram` |
| "Check for deprecated K8s APIs" / 「檢查棄用的 API」 | `*full` (upgrade-check) |
| "Preview the deployment diff" / 「預覽部署變更」 | `*full` (diff-preview) |

### Combined Workflows

```
# Monday morning routine — full platform health check
User: "Run a complete health check on everything"
→ Horus *health + Zeus *health-check → consolidated dashboard

# Pre-release checklist
User: "We're releasing v2.5.0 next week. Make sure everything is ready."
→ Zeus *full → security scan → diff preview → deprecated API check

# Incident investigation
User: "Something broke in production. Check what changed recently."
→ diff-preview → image drift check → change impact diagram

# New team member onboarding
User: "A new developer is joining. Help them understand our infra."
→ /devops:detect → tool status → architecture diagram → health dashboard
```

> **Tips:** Be specific about scope ("check security for payment module"), mention the technology (Terraform vs Kustomize), and state your goal ("preparing for K8s 1.30 upgrade") for best results.

For the full list of 17 use cases with detailed examples, see [`docs/use-cases.md`](docs/use-cases.md).

---

## Commands

### Getting Started

| Command | Usage |
|---------|-------|
| `/devops:detect` | Scan repo to determine IaC or GitOps type and recommend agent |
| `/devops:status` | Check tool installation status + install missing tools |

### Horus Commands (IaC)

| Command | Usage |
|---------|-------|
| `/devops:tf-validate` | Terraform fmt + validate + consistency |
| `/devops:tf-security` | Terraform security audit |
| `/devops:helm-upgrade` | Helm chart version upgrade |
| `/devops:helm-scaffold` | Scaffold new Helm module |
| `/devops:cicd-check` | CI/CD pipeline analysis |

### Zeus Commands (GitOps)

| Command | Usage |
|---------|-------|
| `/devops:lint` | Quick YAML lint + kustomize build |
| `/devops:validate` | Full validation (7 tools) |
| `/devops:security-scan` | Multi-tool security scan |
| `/devops:secret-audit` | Secret inventory + hardcoded detection |
| `/devops:diff-preview` | Branch diff with risk assessment |
| `/devops:upgrade-check` | Deprecated APIs + image drift |
| `/devops:pipeline-check` | CI/CD pipeline audit |
| `/devops:pre-commit` | Run all pre-commit hooks |
| `/devops:k8s-compat` | K8s version compatibility check |
| `/devops:add-service` | Scaffold new service |
| `/devops:add-ingress` | Create ingress resources |
| `/devops:argocd-app` | Create/validate ArgoCD application |
| `/devops:diagram` | Architecture diagrams (Mermaid/D2) |
| `/devops:flowchart` | Workflow flowcharts |

### Auto-trigger Skills

These activate automatically — no invocation needed:

| Skill | Trigger |
|-------|---------|
| yaml-fix-suggestions | YAML edits in Kustomize directories |
| kustomize-resource-validation | `kustomization.yaml` edits |
| repo-detect | Plugin load / agent selection |

---

## Documentation

See [`docs/`](docs/) for detailed guides:

| File | Description |
|------|-------------|
| [`docs/runbook.md`](docs/runbook.md) | Complete runbook: installation, tool setup, agent reference, command reference, common workflows, troubleshooting |
| [`docs/use-cases.md`](docs/use-cases.md) | 17 real-world use cases with natural language examples (EN/ZH-TW) |
| [`docs/cloud-integrations-roadmap.md`](docs/cloud-integrations-roadmap.md) | Cloud integration roadmap: AWS EKS, Azure AKS, GCP enhancements, cost optimization, and more (EN/ZH-TW) |
| [`docs/cross-platform-migration-plan.md`](docs/cross-platform-migration-plan.md) | Cross-platform migration plan: Claude Code + Codex + Gemini CLI support, version upgrade strategy (EN/ZH-TW) |
| [`docs/README.zh-TW.md`](docs/README.zh-TW.md) | Traditional Chinese documentation |
| [`docs/examples/devops-horus-full-check-2026-03-06.md`](docs/examples/devops-horus-full-check-2026-03-06.md) | Example: Horus `*full` pipeline report |
| [`docs/examples/devops-zeus-full-check-2026-03-06.md`](docs/examples/devops-zeus-full-check-2026-03-06.md) | Example: Zeus `*full` pipeline report |

---

## Cross-Platform Support

This plugin uses the [Agent Skills](https://agentskills.io/specification) open standard. All 8 skills work natively on:

| Platform | Skills | Agents | Commands |
|----------|--------|--------|----------|
| **Claude Code** | Native (SKILL.md) | Native (`agents/*.md`) | `/devops:*` slash commands |
| **OpenAI Codex CLI** | Native (`.agents/skills/`) | Via `AGENTS.md` routing | Natural language |
| **Google Gemini CLI** | Native (`.gemini/skills/`) | Via `GEMINI.md` routing | Natural language |

For cross-platform setup details, see [`docs/cross-platform-migration-plan.md`](docs/cross-platform-migration-plan.md).

---

## Design Principles

- **Dynamic discovery** — Modules and environments discovered at runtime
- **Portable** — Works on any repo following the expected patterns
- **Cross-platform** — Same skills on Claude Code, Codex CLI, and Gemini CLI
- **Safety-first** — Always validates before applying, always scans before deploying
- **Graceful degradation** — Missing tools are skipped with install suggestions

## License

MIT
