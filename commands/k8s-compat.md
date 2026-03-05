# k8s-compat — Kubernetes Version Compatibility Check Skill

Validates manifests against a target Kubernetes version, detecting deprecated or removed APIs and incompatible resources.

## Usage

```
k8s-compat 1.29          # Check compatibility with K8s 1.29
k8s-compat 1.30 dev      # Check dev only against K8s 1.30
k8s-compat               # Check against auto-detected target version
```

## Arguments

$ARGUMENTS — Optional: target K8s version (e.g., `1.29`, `1.30`), optional environment filter. Default: auto-detect from CI config (e.g., `.gitlab-ci.yml` kubeconform settings) or use `1.28.0` as fallback.

## Instructions

### Step 1: Parse Arguments

- Extract target K8s version. Auto-detect from CI pipeline config (look for kubeconform `--kubernetes-version` flags in `.gitlab-ci.yml`, `.github/workflows/`, or similar CI config). If not found, use `1.28.0` as fallback.
- Extract optional environment filter
- **Discover Kustomize modules** by finding directories that contain a `base/` and `overlays/` subdirectory structure
- **Discover environments** by listing subdirectories under each module's `overlays/` directory
- Determine scope (all discovered module/environment combinations or filtered subset)

### Step 2: Build Manifests

For each module and environment in scope:
```bash
kustomize build <module>/overlays/<env> > /tmp/compat-<module>-<env>.yaml
```

### Step 3: API Deprecation Check (pluto)

```bash
pluto detect-files -d /tmp/compat-<module>-<env>.yaml -t k8s=v<target-version>
```

Parse output for:
- **Removed APIs** — these will BREAK on the target version
- **Deprecated APIs** — these work but should be migrated
- **Replacement API** — the new apiVersion to use

If `pluto` is not installed, suggest: `brew install FairwindsOps/tap/pluto`

### Step 4: Schema Validation (kubeconform)

```bash
kubeconform -strict -summary -kubernetes-version <target-version> -ignore-missing-schemas /tmp/compat-<module>-<env>.yaml
```

This catches:
- Fields removed in target version
- New required fields
- Schema changes

If `kubeconform` is not installed, suggest: `brew install kubeconform`

### Step 5: Manual API Review

Even without tools, scan the rendered manifests for known deprecations:

| API | Deprecated | Removed | Replacement |
|-----|-----------|---------|-------------|
| `extensions/v1beta1/Ingress` | 1.14 | 1.22 | `networking.k8s.io/v1` |
| `policy/v1beta1/PodDisruptionBudget` | 1.21 | 1.25 | `policy/v1` |
| `autoscaling/v2beta1` | 1.23 | 1.26 | `autoscaling/v2` |
| `flowcontrol.apiserver.k8s.io/v1beta1` | 1.23 | 1.26 | `v1beta3` or `v1` |
| `flowcontrol.apiserver.k8s.io/v1beta2` | 1.26 | 1.29 | `v1` |

### Step 6: Compatibility Report

```
K8s Compatibility Report — Target: v<target-version>
Current: v<detected-version> -> Target: v<target-version>

API Changes:
| Resource | Current API | Status | Replacement | File |
|----------|------------|--------|-------------|------|
| Ingress/foo | networking.k8s.io/v1 | OK | - | <module>/... |
| PDB/bar | policy/v1 | OK | - | <module>/... |

Schema Validation:
| Module | Env | Status | Issues |
|--------|-----|--------|--------|
| <module> | <env> | PASS | 0 |
| ... | ... | ... | ... |

Migration Steps Required:
1. [List specific changes needed, if any]
2. [Include file paths and line numbers]

Overall Compatibility: COMPATIBLE / NEEDS MIGRATION / INCOMPATIBLE
```

### Step 7: Migration Guide

If incompatibilities are found, generate specific migration steps:
- Exact file paths to modify
- Old apiVersion -> new apiVersion
- Any field changes required
- Link to K8s deprecation guide

### Graceful Degradation

- If `kustomize` is not installed, suggest: `brew install kustomize` (required -- cannot proceed without it)
- If `pluto` is not installed, suggest: `brew install FairwindsOps/tap/pluto` and fall back to the manual API review table in Step 5
- If `kubeconform` is not installed, suggest: `brew install kubeconform` and skip schema validation
- Never block the entire check because one tool is missing -- skip that step, show the install command, and continue

### Cleanup

```bash
rm -f /tmp/compat-*.yaml
```
