# detect — Repository Type Detection

Analyzes the current repository to determine whether it is an IaC (Terraform+Helm) or GitOps (Kustomize+ArgoCD) repo, and recommends the appropriate agent.

## Usage

```
/devops:detect              # Detect repo type and recommend agent
```

## Arguments

$ARGUMENTS — None required.

## Instructions

### Step 1: Identify Repository

Report the current working directory and git remote origin (if available):

```bash
git remote get-url origin 2>/dev/null || echo "(no remote)"
```

### Step 2: Scan for IaC Indicators

Check for Terraform + Helm patterns:

```bash
# Terraform files
find . -maxdepth 3 -name "*.tf" -not -path "./.terraform/*" | head -20

# Helm module directory
ls -d modules/helm/ 2>/dev/null

# Terraform lock file
ls .terraform.lock.hcl 2>/dev/null

# Environment config files
ls infra/*.json 2>/dev/null
```

Score each indicator:
- `*.tf` files found → +3 (HIGH)
- `modules/helm/` exists → +3 (HIGH)
- `.terraform.lock.hcl` exists → +2 (MEDIUM)
- `infra/*.json` exists → +1 (LOW)
- `.tflint.hcl` exists → +1 (LOW)

### Step 3: Scan for GitOps Indicators

Check for Kustomize + ArgoCD patterns:

```bash
# Kustomization files
find . -maxdepth 4 -name "kustomization.yaml" | head -20

# Base + overlays structure
find . -maxdepth 3 -type d -name "overlays" | head -10
find . -maxdepth 3 -type d -name "base" | head -10

# ArgoCD application manifests
grep -rl "kind: Application" --include="*.yaml" -l 2>/dev/null | head -10
```

Score each indicator:
- `kustomization.yaml` files found → +3 (HIGH)
- `base/` + `overlays/` structure → +3 (HIGH)
- ArgoCD Application manifests → +3 (HIGH)
- `.pre-commit-config.yaml` with kustomize → +1 (LOW)

### Step 4: Present Results

Show a detection summary table with scores and the recommended agent.

If only IaC detected → recommend `/devops:horus`
If only GitOps detected → recommend `/devops:zeus`
If both detected → show both with scores, let user choose
If neither detected → show both agents as options

### Graceful Degradation

- If `git` is not available, skip remote detection
- If `find` or `grep` fail, fall back to manual file checks using Glob tool
- Never block — always produce a recommendation even with partial data
