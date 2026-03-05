# upgrade-check — Version Drift & Deprecation Detection Skill

Detects deprecated APIs, image version drift across environments, outdated annotations, and tool version freshness.

## Usage

```
upgrade-check           # Full check across all environments
upgrade-check images    # Image version drift only
upgrade-check apis      # Deprecated APIs only
```

## Arguments

$ARGUMENTS — Optional: `images`, `apis`, `annotations`, `tools`, or blank for all checks.

## Instructions

### Step 0: Discover Modules and Environments

Discover Kustomize modules by finding directories that contain a `base/` and `overlays/` subdirectory structure. For each discovered module, discover environments by listing subdirectories under that module's `overlays/` directory.

### Step 0b: Determine Kubernetes Version

Use the K8s version from `.k8s-version` file if present (read the first line, trimmed), otherwise default to `1.28.0`. Store as `K8S_VERSION`.

### Step 1: Deprecated API Detection

Build all manifests and scan for deprecated APIs:

```bash
for env in <discovered-envs>; do
  for module in <discovered-modules>; do
    kustomize build $module/overlays/$env > /tmp/upgrade-$module-$env.yaml
  done
done
```

Then for each:
```bash
pluto detect-files -d /tmp/upgrade-<module>-<env>.yaml -t k8s=v<K8S_VERSION>
```

Also check for APIs deprecated in FUTURE versions (next 1-2 minor releases) to proactively catch upcoming issues.

If `pluto` is not installed, fall back to grep-based detection of known deprecated apiVersions.

### Step 2: Image Version Drift

Scan rendered manifests for container images and compare across environments:

```bash
grep -E 'image:' /tmp/upgrade-*.yaml | sort
```

Build a comparison table:
- Same image should have same tag across environments (or intentional version progression)
- Flag images with `latest` tag (anti-pattern)
- Flag images without any tag
- Flag significant version differences between envs

### Step 3: Annotation Deprecation

Scan for deprecated or outdated annotations:

| Deprecated Annotation | Replacement |
|----------------------|-------------|
| `kubernetes.io/ingress.class` | `spec.ingressClassName` |
| `ingress.kubernetes.io/*` | `nginx.ingress.kubernetes.io/*` |
| `scheduler.alpha.kubernetes.io/*` | Various stable replacements |

### Step 4: Tool Version Freshness

Check versions of tools referenced in CI and pre-commit configurations:

Scan `.gitlab-ci.yml`, `.github/workflows/*.yml`, and `.pre-commit-config.yaml` for tool version references. Present a table of discovered tools and their pinned versions.

| Tool | Current | Source | Latest? |
|------|---------|--------|---------|
| (discovered tool) | (version) | (config file) | Check |

Note: Do not make network calls to check latest versions. Instead, flag the current versions and suggest the user verify them.

### Step 5: Cross-Environment Resource Comparison

Compare resource types and counts across environments:
- Resources in one env but not others (or vice versa)
- Significant configuration differences between envs

### Step 6: Report

```
Upgrade Check Report

## Deprecated APIs
| Resource | API Version | Status | Target Removal | Replacement |
|----------|------------|--------|----------------|-------------|
| ... | ... | ... | ... | ... |

## Image Version Drift
| Image | env-1 | env-2 | env-3 | Status |
|-------|-------|-------|-------|--------|
| ... | v1.2 | v1.2 | v1.1 | DRIFT |

## Deprecated Annotations
| File | Annotation | Replacement |
|------|-----------|-------------|
| ... | ... | ... |

## Tool Versions
| Tool | Version | Source |
|------|---------|--------|
| ... | ... | ... |

## Cross-Environment Differences
| Resource | env-1 | env-2 | env-3 | Note |
|----------|-------|-------|-------|------|
| ... | ... | ... | ... | ... |

Overall: N issues found (X critical, Y warnings)
Action Items:
1. [Prioritized list of things to fix]
```

### Graceful Degradation

- If `kustomize` is not installed, suggest: `brew install kustomize` (required -- cannot proceed without it)
- If `pluto` is not installed, suggest: `brew install FairwindsOps/tap/pluto` and fall back to grep-based detection of known deprecated apiVersions
- Always run available checks and skip missing tools
- Never block the entire check because one tool is missing -- skip that step, show the install command, and continue

### Cleanup

```bash
rm -f /tmp/upgrade-*.yaml
```
