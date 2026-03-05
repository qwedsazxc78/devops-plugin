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
# Use WSL2 with Ubuntu, then follow Linux instructions
wsl --install -d Ubuntu

# Inside WSL2
sudo apt-get update && sudo apt-get install -y git jq
pip3 install yamllint checkov pre-commit

# Install Homebrew for Linux (for remaining tools)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install kustomize kubeconform terraform
```

</details>

Or use the interactive installer:

```bash
./scripts/install-tools.sh          # Interactive check + install
./scripts/install-tools.sh check    # Check only
```

### 3. Detect your repo type

```
/devops:detect
```

### 4. Start an agent

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

### Zeus (GitOps) — Pre-merge check

```
> /devops:zeus

┌─────────────────────────────────────────────────┐
│          Zeus — GitOps Engineer                  │
│          GitOps Command Center                   │
├─────────────────────────────────────────────────┤
│  1. *full         — Full pipeline + YAML/MD     │
│  2. *pre-merge    — Pre-MR essential checks     │
│  ...                                            │
└─────────────────────────────────────────────────┘

Zeus online. What do you need?

> *pre-merge

Step 1/4: [lint] YAML lint + kustomize build
  Discovering modules... found: app-service, monitoring
  Discovering environments... found: dev, stg, prd

  | Module     | Env | yamllint | kustomize build | Status |
  |------------|-----|----------|-----------------|--------|
  | app-service| dev | PASS     | PASS            | OK     |
  | app-service| stg | PASS     | PASS            | OK     |
  | monitoring | dev | PASS     | PASS            | OK     |
  ...

Step 2/4: [validate] Full validation ... PASS
Step 3/4: [security-scan] Quick scan ... PASS (0 HIGH)
Step 4/4: [diff-preview] 3 files changed, risk: LOW

Verdict: READY TO MERGE
```

### Horus (IaC) — Helm upgrade

```
> /devops:horus

┌─────────────────────────────────────────────────┐
│          Horus — IaC Operations Engineer         │
│          Cloud Platform Operations               │
└─────────────────────────────────────────────────┘

> *upgrade

Step 1: Discovering Helm modules...
  Found 8 modules via dynamic discovery

  | Module   | Current | Latest  | Status   |
  |----------|---------|---------|----------|
  | grafana  | 10.5.4  | 10.6.0  | OUTDATED |
  | argocd   | 9.2.4   | 9.2.4   | OK       |
  | redis    | 18.6.1  | 19.0.2  | OUTDATED |

  Select modules to upgrade: [1] grafana [2] redis [3] all
```

---

## Commands

### Which agent should I use?

Run `/devops:detect` — the plugin scans for IaC (`.tf` files, Helm modules) and GitOps (`kustomization.yaml`, `base/` + `overlays/`) indicators.

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

---

## Design Principles

- **Dynamic discovery** — Modules and environments discovered at runtime
- **Portable** — Works on any repo following the expected patterns
- **Safety-first** — Always validates before applying, always scans before deploying
- **Graceful degradation** — Missing tools are skipped with install suggestions

## License

MIT
