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
command -v pip3    # pip?
```

### Step 2: Check Each Tool

For each tool below, run `command -v <tool>` to check if installed. If installed, run the version command to get the version string.

Filter by $ARGUMENTS: if `zeus`, skip Horus-only tools. If `horus`, skip Zeus-only tools. If empty/all, check everything.

#### Tool Registry

**Shared (required for both agents):**

| Tool | Version Command | brew | apt | pip |
|------|----------------|------|-----|-----|
| git | `git --version` | `brew install git` | `apt-get install -y git` | — |
| kubectl | `kubectl version --client` | `brew install kubectl` | `snap install kubectl --classic` | — |
| jq | `jq --version` | `brew install jq` | `apt-get install -y jq` | — |
| yq | `yq --version` | `brew install yq` | `snap install yq` | — |

**Horus — IaC (required):**

| Tool | Version Command | brew | pip |
|------|----------------|------|-----|
| terraform | `terraform version` | `brew install terraform` | — |

**Horus — IaC (recommended):**

| Tool | Version Command | brew | pip |
|------|----------------|------|-----|
| tflint | `tflint --version` | `brew install tflint` | — |
| tfsec | `tfsec --version` | `brew install tfsec` | — |
| pre-commit | `pre-commit --version` | — | `pip3 install pre-commit` |

**Zeus — GitOps (required):**

| Tool | Version Command | brew | pip |
|------|----------------|------|-----|
| kustomize | `kustomize version` | `brew install kustomize` | — |

**Zeus — GitOps (recommended):**

| Tool | Version Command | brew | pip |
|------|----------------|------|-----|
| yamllint | `yamllint --version` | — | `pip3 install yamllint` |
| kubeconform | `kubeconform -v` | `brew install kubeconform` | — |
| kube-score | `kube-score version` | `brew install kube-score` | — |
| kube-linter | `kube-linter version` | `brew install kube-linter` | — |
| polaris | `polaris version` | `brew install FairwindsOps/tap/polaris` | — |
| pluto | `pluto version` | `brew install FairwindsOps/tap/pluto` | — |
| conftest | `conftest --version` | `brew install conftest` | — |
| checkov | `checkov --version` | — | `pip3 install checkov` |
| trivy | `trivy --version` | `brew install trivy` | — |
| gitleaks | `gitleaks version` | `brew install gitleaks` | — |
| d2 | `d2 --version` | `brew install d2` | — |

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

If user chooses 1-3, generate **grouped install commands** by package manager and run them:

```bash
# Homebrew (batch — fast)
brew install tfsec kubeconform d2

# pip (batch — fast)
pip3 install yamllint checkov
```

IMPORTANT: Group all brew installs into one command and all pip installs into one command for speed. Do NOT install one tool at a time.

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
- If Homebrew is not installed, show: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- If pip is not installed, show: `python3 -m ensurepip --upgrade`
- If both are missing, show all install commands as reference — user can install their preferred way
- Required tools missing → show as ERROR (these will block pipelines)
- Recommended tools missing → show as WARN (pipelines will skip those checks)
- Never block — always show the full status table
