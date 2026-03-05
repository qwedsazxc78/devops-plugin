# validate — Full Validation Pipeline Skill

Comprehensive validation: kustomize build, schema validation, best practices, policy checks, and deprecated API detection.

## Usage

```
validate              # Validate everything
validate dev          # Validate dev environment only
validate my-module    # Validate one module, all envs
```

## Arguments

$ARGUMENTS — Optional: environment name, module name, or both. Default: all.

## Instructions

### Step 0: Discover Modules and Environments

Discover Kustomize modules by finding directories that contain a `base/` and `overlays/` subdirectory structure. For each discovered module, discover environments by listing subdirectories under that module's `overlays/` directory.

### Step 0b: Determine Kubernetes Version

Use the K8s version from `.k8s-version` file if present (read the first line, trimmed), otherwise default to `1.28.0`.

### Step 1: Determine Scope

Parse `$ARGUMENTS` to build the list of `<module>/overlays/<env>` paths to validate.
Default: all combinations (all modules x all envs).

### Step 2: Kustomize Build

For each path in scope:
```bash
kustomize build <module>/overlays/<env> > /tmp/manifest-<module>-<env>.yaml
```
Save rendered manifests for subsequent tool analysis. Record PASS/FAIL.

### Step 3: Schema Validation (kubeconform)

For each rendered manifest:
```bash
kubeconform -strict -summary -kubernetes-version <K8S_VERSION> -ignore-missing-schemas /tmp/manifest-<module>-<env>.yaml
```
This validates against the target K8s API schema.

If `kubeconform` is not installed, suggest: `brew install kubeconform`

### Step 4: Best Practices (kube-score)

```bash
kube-score score /tmp/manifest-<module>-<env>.yaml
```
Reports on:
- Container security context
- Resource requests/limits
- Probe configuration
- Network policies

If `kube-score` is not installed, suggest: `brew install kube-score`

### Step 5: Policy Check (polaris)

```bash
polaris audit --audit-path /tmp/manifest-<module>-<env>.yaml --format pretty
```
Checks against Polaris best practice policies.

If `polaris` is not installed, suggest: `brew install FairwindsOps/tap/polaris`

### Step 6: Security Lint (kube-linter)

```bash
kube-linter lint /tmp/manifest-<module>-<env>.yaml
```
Checks for common security misconfigurations.

If `kube-linter` is not installed, suggest: `brew install kube-linter`

### Step 7: Deprecated API Detection (pluto)

```bash
pluto detect-files -d /tmp/manifest-<module>-<env>.yaml -t k8s=v<K8S_VERSION>
```
Detects deprecated or removed APIs for the target K8s version.

If `pluto` is not installed, suggest: `brew install FairwindsOps/tap/pluto`

### Step 8: OPA Policy Testing (conftest)

If `.conftest/` or `policy/` directory exists:
```bash
conftest test /tmp/manifest-<module>-<env>.yaml
```

If `conftest` is not installed, suggest: `brew install conftest`

### Step 9: Results Summary

```
Validation Pipeline Results
| Module | Env | Build | Schema | Score | Polaris | Linter | Pluto | Conftest | Overall |
|--------|-----|-------|--------|-------|---------|--------|-------|----------|---------|
| module-a | dev | PASS | PASS | 8/10 | PASS | 2 WARN | OK | SKIP | PASS |
| module-a | stg | PASS | PASS | 7/10 | 1 WARN | PASS | OK | SKIP | WARN |
| ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |

Tool Availability:
| Tool | Status |
|------|--------|
| kustomize | Installed (v5.3.0) |
| kubeconform | Installed / NOT INSTALLED |
| kube-score | Installed / NOT INSTALLED |
| polaris | Installed / NOT INSTALLED |
| kube-linter | Installed / NOT INSTALLED |
| pluto | Installed / NOT INSTALLED |
| conftest | Installed / NOT INSTALLED |

Overall: PASS / WARN / FAIL
Issues found: N critical, M warnings
```

### Graceful Degradation

For each tool that is NOT installed:
- Mark as `SKIP` in the results table
- Show install command
- Continue with remaining tools (never block the entire pipeline)

### Cleanup

Remove temporary manifests after validation:
```bash
rm -f /tmp/manifest-*.yaml
```
