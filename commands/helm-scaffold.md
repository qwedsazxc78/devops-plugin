# helm-scaffold — Helm Module Scaffolding Skill

Generates new Helm module directories following established patterns. Ensures consistency with existing modules and registers the new module across all required files.

## Usage

```
helm-scaffold redis       # Scaffold a new Helm module named "redis"
helm-scaffold my-chart    # Scaffold with interactive prompts for details
```

## Arguments

$ARGUMENTS --- Required: chart name for the new Helm module.

## Instructions

### Step 0: Discover Repository Structure

Dynamically locate the key files and directories:

1. Find the Terraform root by searching for the main package file:
   ```bash
   find . -maxdepth 3 -name "*.tf" | xargs grep -l 'source.*modules/helm' 2>/dev/null
   ```
2. Locate the Helm modules directory (e.g., `modules/helm/`)
3. Locate the manual install reference (`helm_install.md`)
4. Locate the identity/workload identity file (e.g., `*identity*.tf` or `*iam*.tf`)
5. Check for pattern reference files: `MODULE_PATTERNS.md`
6. Examine 2-3 existing modules in `modules/helm/*/` to learn the established patterns:
   - File naming: `main.tf`, `variable.tf` vs `variables.tf`, `common.yaml`, `configs-*.yaml`
   - Resource naming conventions (e.g., `helm_release.this`)
   - Values loading patterns (concat/compact)
   - Variable definitions

### Step 1: Gather Inputs

Ask the user for the following (use defaults where sensible):

| Input | Required | Default | Example |
|-------|----------|---------|---------|
| Chart name | Yes (from $ARGUMENTS) | -- | `redis` |
| Helm repository URL | Yes | -- | `https://charts.bitnami.com/bitnami` |
| Chart version | Yes | -- | `17.11.3` |
| Namespace | Yes | Chart name | `redis` |
| Release name | No | Chart name | `redis` |
| Environments | No | `dev,stg,prd` | `dev,stg,prd` |
| DR support | No | `true` | `true` or `false` |
| Workload identity | No | `false` | `true` (needs SA name + roles) |
| CRDs | No | `false` | `true` if chart needs `installCRDs` |
| Shared namespace | No | `false` | `true` if using existing namespace like `monitoring` |

### Step 2: Select Pattern

Based on inputs, select the appropriate module pattern:

| Pattern | When to Use |
|---------|------------|
| **Simple** | No env-specific config, minimal setup |
| **Standard** | Env-specific configs, DR support |
| **Workload Identity** | Needs GCP SA with `yamlencode` injection |
| **OCI** | Chart from OCI registry, no `repository` field |
| **Multi-Instance** | Same chart deployed multiple times |

If a `MODULE_PATTERNS.md` reference exists, use it. Otherwise, infer the pattern from examining existing modules discovered in Step 0.

### Step 3: Generate Module Files

Create `modules/helm/<chart-name>/` with the following files:

**3a: `main.tf`**
- `helm_release.this` resource (use `this` as resource name per convention)
- Repository URL, chart name, version, namespace
- Values file loading (concat/compact pattern matching existing modules)
- CRD set block if needed
- Timeout for long-deploying charts

**3b: `variables.tf`**
- `name` -- string with default matching chart name
- `namespace` -- string with default matching namespace input
- `install_version` -- string with default matching version input
- `environment` -- string, no default (if env configs needed)
- `dr` -- bool, no default (if DR support)
- `project_id` -- string, no default (if workload identity)
- Any chart-specific variables

**3c: `common.yaml`**
- Base Helm values shared across environments
- Resource requests/limits template
- Service account configuration (if applicable)
- Network policy template (if applicable)

**3d: `configs-{env}.yaml` (per environment)**
- Environment-specific overrides
- Placeholder values with TODO comments
- Typically: replica counts, resource sizes, ingress hosts

**3e: `configs-{env}-dr.yaml` (if DR support)**
- DR-specific overrides
- Typically: reduced replicas, DR-specific endpoints

### Step 4: Register in Package Terraform File

Add module block to the main package file following established patterns:

```hcl
module "<chart-name>" {
  name            = "<release-name>"
  source          = "./modules/helm/<chart-name>"
  install_version = "<version>"
  namespace       = "<namespace>"
  environment     = local.environment
  dr              = local.dr
  depends_on      = [module.gke]
}
```

Adjust `depends_on` based on:
- Workload identity -- add workload identity namespace resource
- Depends on keda -- add `module.keda`
- Depends on cert-manager -- add `module.cert-manager`

### Step 5: Register in helm_install.md

Add a new section with manual helm install command:

```markdown
# <chart-name>

\`\`\`bash
helm repo add <repo-name> <repo-url>
helm repo update

helm upgrade --install <release-name> <repo-name>/<chart-name> \
  --create-namespace --version <version> -n <namespace> \
  --values common.yaml --values configs-dev.yaml
\`\`\`
```

### Step 6: Update Workload Identity (if needed)

If workload identity is required:
1. Add namespace to the workload namespace list in the identity file
2. Add workload identity module block following existing patterns

### Step 7: Summary

List all created and modified files, then suggest next steps:
1. Run `terraform validate` to check syntax
2. Run `terraform plan -target=module.<chart-name>` to preview changes
3. Review generated values files and fill in TODO placeholders
4. Test with `terraform apply -target=module.<chart-name>`

## Graceful Degradation

- If the Helm modules directory does not exist: FAIL with a message explaining the expected directory structure
- If the package Terraform file cannot be found: create module files only (Steps 3), skip registration (Steps 4-6), warn the user
- If `helm_install.md` does not exist: skip Step 5, note the missing file in the summary
- If no existing modules exist to learn patterns from: use the Standard pattern with sensible defaults
- If the identity file cannot be found and workload identity is requested: create module files only, provide manual instructions for identity registration
- If `terraform` is not installed: create all files but skip the validation suggestion, suggest `brew install terraform`
- Never block scaffolding because a registration target is missing -- create what can be created and report what was skipped
- Minimum viable scaffold: create the module directory with `main.tf` + `variables.tf` + `common.yaml`
