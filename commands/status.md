# status — Tool Installation Status & Installer

Check which DevOps tools are installed and optionally install missing ones. Works standalone — no agent session needed. Does NOT depend on `scripts/install-tools.sh` (plugin users may not have it).

## Usage

```
/devops:status              # Check all tools (both agents)
/devops:status zeus         # Check Zeus (GitOps) tools only
/devops:status horus        # Check Horus (IaC) tools only
```

## Arguments

$ARGUMENTS — Optional: `zeus` or `horus` to filter by agent. Default: all.

## Instructions

### Step 1: Detect Platform

Run these to determine the available package manager:

```bash
uname -s          # OS (Darwin / Linux)
command -v brew    # Homebrew?
command -v apt-get # apt?
command -v uv      # uv? (preferred over pip)
command -v pip3    # pip? (fallback)
```

### Step 2: Check Each Tool

For each tool below, run `command -v <tool>` to check if installed. If installed, run the version command to get the version string.

Filter by $ARGUMENTS: if `zeus`, skip Horus-only tools. If `horus`, skip Zeus-only tools. If empty/all, check everything.

#### Tool Registry

Each tool lists install commands for macOS (brew), Linux/WSL2 (apt/snap or brew), and Python (uv or pip). Use the platform detected in Step 1. **Prefer `uv` over `pip3`** if available — it is significantly faster.

**Shared (required for both agents):**

| Tool | Version Command | brew (macOS) | apt/snap (Linux/WSL2) | uv / pip |
|------|----------------|-------------|----------------------|----------|
| git | `git --version` | `brew install git` | `sudo apt-get install -y git` | — |
| kubectl | `kubectl version --client` | `brew install kubectl` | `sudo snap install kubectl --classic` | — |
| jq | `jq --version` | `brew install jq` | `sudo apt-get install -y jq` | — |
| yq | `yq --version` | `brew install yq` | `sudo snap install yq` | — |

**Horus — IaC (required):**

| Tool | Version Command | brew (macOS) | apt/snap (Linux/WSL2) | uv / pip |
|------|----------------|-------------|----------------------|----------|
| terraform | `terraform version` | `brew install terraform` | `sudo snap install terraform --classic` | — |

**Horus — IaC (recommended):**

| Tool | Version Command | brew (macOS) | apt/snap (Linux/WSL2) | uv / pip |
|------|----------------|-------------|----------------------|----------|
| tflint | `tflint --version` | `brew install tflint` | `brew install tflint` | — |
| tfsec | `tfsec --version` | `brew install tfsec` | `brew install tfsec` | — |
| pre-commit | `pre-commit --version` | — | — | `uv tool install pre-commit` / `pip3 install pre-commit` |

**Zeus — GitOps (required):**

| Tool | Version Command | brew (macOS) | apt/snap (Linux/WSL2) | uv / pip |
|------|----------------|-------------|----------------------|----------|
| kustomize | `kustomize version` | `brew install kustomize` | `sudo snap install kustomize` | — |

**Zeus — GitOps (recommended):**

| Tool | Version Command | brew (macOS) | apt/snap (Linux/WSL2) | uv / pip |
|------|----------------|-------------|----------------------|----------|
| yamllint | `yamllint --version` | — | — | `uv tool install yamllint` / `pip3 install yamllint` |
| kubeconform | `kubeconform -v` | `brew install kubeconform` | `brew install kubeconform` | — |
| kube-score | `kube-score version` | `brew install kube-score` | `brew install kube-score` | — |
| kube-linter | `kube-linter version` | `brew install kube-linter` | `brew install kube-linter` | — |
| polaris | `polaris version` | `brew install FairwindsOps/tap/polaris` | `brew install FairwindsOps/tap/polaris` | — |
| pluto | `pluto version` | `brew install FairwindsOps/tap/pluto` | `brew install FairwindsOps/tap/pluto` | — |
| conftest | `conftest --version` | `brew install conftest` | `brew install conftest` | — |
| checkov | `checkov --version` | — | — | `uv tool install checkov` / `pip3 install checkov` |
| trivy | `trivy --version` | `brew install trivy` | `sudo snap install trivy` | — |
| gitleaks | `gitleaks version` | `brew install gitleaks` | `brew install gitleaks` | — |
| d2 | `d2 --version` | `brew install d2` | `brew install d2` | — |

> **Linux/WSL2 note:** Many tools show `brew install` for Linux because they are not in apt/snap repos. Homebrew works on Linux/WSL2 — install it first if missing (see Graceful Degradation below).

### Step 3: Present Results

Show a summary dashboard (match this format):

```
+-------------------------------------------------------------+
| DevOps Plugin — Tool Status                                 |
+-------------------------------------------------------------+
| Tool Status:                                                |
|   OK:      kustomize kubectl git kube-score kube-linter     |
|            gitleaks trivy polaris pluto conftest pre-commit  |
|   MISSING: yamllint checkov d2 kubeconform                  |
+-------------------------------------------------------------+
```

Then show the full table with version details:

```
Shared Tools (required)
─────────────────────────────────────────────
  [OK]  git               git version 2.43.0
  [OK]  kubectl           v1.29.0
  [OK]  jq                jq-1.7.1
  [OK]  yq                v4.40.5

Horus — IaC (required)
─────────────────────────────────────────────
  [OK]  terraform          Terraform v1.7.0

Horus — IaC (recommended)
─────────────────────────────────────────────
  [OK]  tflint             TFLint v0.50.0
  [--]  tfsec              not installed
  [OK]  pre-commit         pre-commit 3.6.0

Zeus — GitOps (required)
─────────────────────────────────────────────
  [OK]  kustomize          v5.3.0

Zeus — GitOps (recommended)
─────────────────────────────────────────────
  [--]  yamllint           not installed
  [--]  kubeconform        not installed
  [OK]  kube-score         v1.17.0
  ...

Summary: 15 installed, 4 missing
```

### Step 4: Offer Installation

If there are missing tools, present install options:

```
Missing tools detected. Would you like to install them?
  1. Install all missing tools
  2. Install Horus (IaC) tools only
  3. Install Zeus (GitOps) tools only
  4. Skip — I'll install manually
```

If user chooses 1-3, generate **grouped install commands** by the detected platform's package manager and run them:

**macOS (brew detected):**

```bash
# Homebrew (batch — fast)
brew install tfsec kubeconform d2

# Python tools — use uv if available (much faster), otherwise pip3
uv tool install yamllint checkov
# or: pip3 install yamllint checkov
```

**Linux/WSL2 (apt detected, brew available):**

```bash
# apt/snap first (for tools that have native packages)
sudo apt-get install -y git jq
sudo snap install kubectl --classic terraform --classic kustomize trivy

# Homebrew for Linux (tools without apt/snap packages)
brew install kubeconform kube-score kube-linter gitleaks d2

# Python tools — use uv if available, otherwise pip3
uv tool install yamllint checkov pre-commit
# or: pip3 install yamllint checkov pre-commit
```

**Linux/WSL2 (apt detected, NO brew):**

```bash
# apt/snap
sudo apt-get install -y git jq
sudo snap install kubectl --classic terraform --classic kustomize trivy

# Python tools
uv tool install yamllint checkov pre-commit
# or: pip3 install yamllint checkov pre-commit

# For remaining tools (kubeconform, kube-score, etc.), recommend installing Homebrew for Linux:
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

IMPORTANT:
- **Prefer `uv tool install`** over `pip3 install` when `uv` is detected — it installs each tool in an isolated environment and is significantly faster.
- Group all brew installs into one command, all apt installs into one, all snap into one, and all uv/pip installs into one command for speed. Do NOT install one tool at a time.

### Step 5: Verify After Install

If any tools were installed, re-check only the tools that were missing:

```bash
command -v yamllint && yamllint --version
command -v checkov && checkov --version
# ...
```

Show updated status for each:

```
  [OK]  yamllint           yamllint 1.33.0  (just installed)
  [OK]  checkov            checkov 3.2.0    (just installed)
  [--]  d2                 install failed — run manually: brew install d2
```

### Graceful Degradation

- This command runs `command -v` directly — it does NOT require `scripts/install-tools.sh`
- **Platform detection**: Use `uname -s` to detect Darwin (macOS) vs Linux (includes WSL2). To detect WSL2 specifically, check: `grep -qi microsoft /proc/version 2>/dev/null`
- **macOS without Homebrew**: Show `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- **Linux/WSL2 without Homebrew**: First use apt/snap for tools that have native packages. For remaining tools, recommend installing Homebrew for Linux: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- **Without uv or pip**: Recommend installing uv first: `curl -LsSf https://astral.sh/uv/install.sh | sh`. If user prefers pip: `python3 -m ensurepip --upgrade` (macOS/Linux) or `sudo apt-get install python3-pip` (Debian/Ubuntu/WSL2)
- **WSL2 users**: Note that `snap` requires systemd; if snap is unavailable, fall back to Homebrew for Linux or direct binary downloads
- If all package managers are missing, show all install commands as reference — user can install their preferred way
- Required tools missing → show as ERROR (these will block pipelines)
- Recommended tools missing → show as WARN (pipelines will skip those checks)
- Never block — always show the full status table
