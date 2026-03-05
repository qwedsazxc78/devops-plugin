# diff-preview — Branch Diff Visualization Skill

Shows what would change when merging the current branch to main: rendered manifest diffs, resource impact analysis, and risk assessment.

## Usage

```
diff-preview              # Diff current branch vs main
diff-preview dev          # Diff only dev environment
diff-preview --files-only # Show only changed files
```

## Arguments

$ARGUMENTS — Optional: environment filter, `--files-only` for quick file list. Default: full diff with rendered manifests.

## Instructions

### Step 0: Discover Modules and Environments

Discover Kustomize modules by finding directories that contain a `base/` and `overlays/` subdirectory structure. For each discovered module, discover environments by listing subdirectories under that module's `overlays/` directory.

### Step 1: Identify Changed Files

```bash
git diff main...HEAD --name-only
```

Categorize changes:
- **Base resources**: `<module>/base/*.yaml`
- **Overlay patches**: `<module>/overlays/*/*.yaml`
- **Kustomizations**: `*/kustomization.yaml`
- **ArgoCD apps**: `*/argocd/*.yaml`
- **Scripts**: `scripts/*`
- **CI/CD**: `.gitlab-ci.yml`, `.pre-commit-config.yaml`, `.github/workflows/*`
- **Documentation**: `docs/*`
- **Other**: everything else

### Step 2: Determine Affected Environments

Map changed files to environments:
- Changes in `base/` → affects ALL environments
- Changes in `overlays/<env>/` → affects that specific environment only

### Step 3: Rendered Manifest Diff (if not `--files-only`)

For each affected module+environment, use a worktree-based approach to avoid unsafe branch switching:

```bash
# Create a temporary worktree for main (safe -- does not affect working tree)
git worktree add /tmp/diff-worktree-main main --detach 2>/dev/null

# Build from main branch via worktree
kustomize build /tmp/diff-worktree-main/<module>/overlays/<env> > /tmp/diff-main-<module>-<env>.yaml

# Build from current branch (working tree)
kustomize build <module>/overlays/<env> > /tmp/diff-current-<module>-<env>.yaml

# Compare
diff /tmp/diff-main-<module>-<env>.yaml /tmp/diff-current-<module>-<env>.yaml
```

IMPORTANT: Do NOT use `git stash` + `git checkout main` -- this is unsafe and can lose uncommitted work. Always use `git worktree` instead.

### Step 4: Resource Impact Analysis

From the rendered diff, determine:

| Action | Resource | Kind | Namespace | Environment |
|--------|----------|------|-----------|-------------|
| ADD | my-service | Deployment | app-ns | dev |
| MODIFY | app-ingress | Ingress | app-ns | dev, stg |
| REMOVE | old-secret | Secret | app-ns | dev |

### Step 5: Risk Assessment

Assign risk level based on changes:

| Risk Factor | Level | Trigger |
|-------------|-------|---------|
| Production changes | HIGH | Any change in production overlay |
| Secret changes | HIGH | Changes to secretGenerator or .env files |
| Ingress changes | MEDIUM | Changes to ingress resources (DNS/routing) |
| Base changes | MEDIUM | Changes in `base/` (affects all envs) |
| ArgoCD app changes | MEDIUM | Changes to sync policy or destination |
| Dev-only changes | LOW | Changes only in development overlay |
| Doc-only changes | LOW | Changes only in `docs/` |

Overall risk: highest risk factor across all changes.

### Step 6: Diff Report

```
Branch Diff Preview: <branch-name> -> main

## Changed Files (<N> files)
| Category | Files | Risk |
|----------|-------|------|
| Base resources | N | MEDIUM |
| Overlay patches | N | varies |
| Kustomizations | N | varies |
| ArgoCD apps | N | MEDIUM |
| CI/CD | N | LOW |
| Documentation | N | LOW |

## Affected Environments
| Environment | Module | Resources Changed | Risk |
|-------------|--------|-------------------|------|
| dev | module-a | +2 -1 ~3 | LOW |
| stg | module-a | ~3 | MEDIUM |
| prd | module-a | ~3 | HIGH |

## Resource Changes
| Action | Resource | Kind | Envs Affected |
|--------|----------|------|---------------|
| ADD | my-service | Deployment | dev, stg, prd |
| MODIFY | app-ingress | Ingress | dev |
| ... | ... | ... | ... |

## Risk Assessment: <LOW/MEDIUM/HIGH/CRITICAL>
Factors:
- [List risk factors that apply]

## Commit History
[git log main...HEAD --oneline]
```

### Graceful Degradation

- If `kustomize` is not installed, suggest: `brew install kustomize` and fall back to `--files-only` mode (git diff only)
- If `git worktree` fails (e.g., main branch not available locally), fall back to `--files-only` mode
- Steps 1, 2, 4, and 5 require only git and file parsing -- they will always run
- The rendered manifest diff (Step 3) is the only step that requires kustomize

### Cleanup

```bash
git worktree remove /tmp/diff-worktree-main --force 2>/dev/null
rm -f /tmp/diff-*.yaml
```
