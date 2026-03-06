<p align="center">
  <img src="docs/images/logo.png" alt="DevOps Plugin Logo" width="128">
</p>

# DevOps Plugin for Claude Code

**English** | [繁體中文](docs/README.zh-TW.md)

> Two AI-powered DevOps agents — **Horus** (IaC) and **Zeus** (GitOps) — with 20+ automated pipeline commands for Terraform, Helm, Kustomize, and ArgoCD.

## Quick Start

### 1. Install the plugin

```bash
# Option A: Add marketplace + install (recommended)
/plugin marketplace add qwedsazxc78/devops-plugin
/plugin install devops@devops-go

# Option B: Local development
claude --plugin-dir ./devops-plugin
```

### 2. Install required tools

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
pip3 install yamllint checkov

# IaC (Horus)
brew install terraform tflint tfsec
pip3 install pre-commit
```

</details>

<details>
<summary><b>Linux (Debian/Ubuntu)</b></summary>

```bash
# Core tools
sudo apt-get update && sudo apt-get install -y git jq
sudo snap install kubectl --classic
sudo snap install kustomize yq

# Python tools
pip3 install yamllint checkov pre-commit

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
sudo apt-get update && sudo apt-get install -y git jq python3-pip
sudo snap install kubectl --classic
sudo snap install kustomize terraform --classic

# 3. Python tools
pip3 install yamllint checkov pre-commit

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

### 3. Check tool installation

```
/devops:status              # Check all tools + install missing
/devops:status horus        # IaC tools only
/devops:status zeus         # GitOps tools only
```

### 4. Detect your repo type

```
/devops:detect
```

### 5. Start an agent

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
| [`docs/README.zh-TW.md`](docs/README.zh-TW.md) | Traditional Chinese documentation |
| [`docs/examples/devops-horus-full-check-2026-03-06.md`](docs/examples/devops-horus-full-check-2026-03-06.md) | Example: Horus `*full` pipeline report |
| [`docs/examples/devops-zeus-full-check-2026-03-06.md`](docs/examples/devops-zeus-full-check-2026-03-06.md) | Example: Zeus `*full` pipeline report |

---

## Design Principles

- **Dynamic discovery** — Modules and environments discovered at runtime
- **Portable** — Works on any repo following the expected patterns
- **Safety-first** — Always validates before applying, always scans before deploying
- **Graceful degradation** — Missing tools are skipped with install suggestions

## License

MIT
