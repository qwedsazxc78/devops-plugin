# argocd-app — ArgoCD Application Create & Validate Skill

Creates or validates ArgoCD Application manifests following the repository's established patterns.

## Usage

```
argocd-app validate          # Validate all existing ArgoCD apps
argocd-app validate dev      # Validate dev apps only
argocd-app create my-app     # Create new ArgoCD app
argocd-app create my-app dev # Create for specific env
```

## Arguments

$ARGUMENTS — Required: `validate` or `create`, optional: app name and environment.

## Instructions

### Step 0: Discover Repository Structure

- **Discover Kustomize modules** by finding directories that contain a `base/` and `overlays/` subdirectory structure
- **Discover environments** by listing subdirectories under each module's `overlays/` directory
- **Discover ArgoCD app manifests** by finding YAML files in `*/argocd/` directories
- **Detect repository URL** by running `git remote get-url origin`

### Mode: Validate

#### 11-Point Checklist

For each ArgoCD Application YAML found in `*/argocd/*.yaml`:

| # | Check | Expected |
|---|-------|----------|
| 1 | File exists | Yes |
| 2 | Valid YAML syntax | parseable |
| 3 | `apiVersion` | `argoproj.io/v1alpha1` |
| 4 | `kind` | `Application` |
| 5 | `metadata.name` | Non-empty, follows naming convention |
| 6 | `metadata.namespace` | `argocd` |
| 7 | `spec.source.repoURL` | Matches repository URL from git remote |
| 8 | `spec.source.path` | Exists as directory in repo |
| 9 | `spec.destination.server` | Contains `kubernetes` |
| 10 | `spec.syncPolicy.automated.prune` | `true` |
| 11 | `spec.syncPolicy.automated.selfHeal` | `true` |

Additional checks beyond the basic checklist:
- `finalizers` includes `resources-finalizer.argocd.argoproj.io`
- `syncOptions` includes `PruneLast=true` and `CreateNamespace=true`
- `targetRevision` is `HEAD` (or a valid branch/tag)
- Path follows pattern: `<module>/overlays/<env>`

#### Validation Report

```
ArgoCD Application Validation

| App | File | Checks | Status |
|-----|------|--------|--------|
| <app-name> | <module>/argocd/<env>.yaml | 11/11 | PASS |
| ... | ... | ... | ... |

Overall: PASS / FAIL
Failed checks: [details if any]
```

### Mode: Create

Generate a new ArgoCD Application manifest.

#### Gather Information

1. **Application name** (required) — e.g., `dev-my-app`
2. **Module path** (required) — e.g., `<module>/overlays/<env>` (discovered from repo structure)
3. **Environment** (required) — one of the discovered environments
4. **Destination server** (default: `https://kubernetes.default.svc`)
5. **Project** (default: `default`)

#### Generate Manifest

**`<module>/argocd/<env>.yaml`** (or custom path)

```yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <env>-<app-name>
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: <project>
  source:
    repoURL: <repository-url-from-git-remote>
    targetRevision: HEAD
    path: <module>/overlays/<env>
  destination:
    server: <destination-server>
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - PruneLast=true
      - CreateNamespace=true
```

#### Post-Create Validation

After creating, immediately run the 11-point checklist on the new file.

#### Summary

```
ArgoCD Application Created: <env>-<app-name>

File: <module>/argocd/<env>.yaml
Source Path: <module>/overlays/<env>
Destination: <destination-server>
Sync Policy: automated (prune + selfHeal)

Validation: PASS (11/11 checks)

Next Steps:
  1. Verify the overlay path builds: kustomize build <module>/overlays/<env>
  2. Commit and push to trigger ArgoCD sync
  3. Monitor sync status in ArgoCD UI
```

### Graceful Degradation

- Validate mode requires no external tools (YAML file parsing only)
- Create mode requires no external tools (file generation only)
- If `kustomize` is available, use it to verify the overlay path builds after creation
- If `kustomize` is not installed, suggest: `brew install kustomize` and skip the build verification
