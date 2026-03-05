# Helm Scaffold Skill

## Purpose

Generates new Helm module directories following established patterns in Terraform+Helm codebases. Ensures consistency with existing modules and registers the new module across all required files.

## Activation

This skill activates when the user requests:
- Adding a new Helm chart to the platform
- Scaffolding a new module
- Creating module files for a new chart

## Workflow

### Step 1: Gather Inputs

Ask the user for:

| Input | Required | Default | Example |
|-------|----------|---------|---------|
| Chart name | Yes | — | `redis` |
| Helm repository URL | Yes | — | `https://charts.bitnami.com/bitnami` |
| Chart version | Yes | — | `17.11.3` |
| Namespace | Yes | Chart name | `redis` |
| Release name | No | Chart name | `redis` |
| Environments | No | `dev,stg,prd` | `dev,stg,prd` |
| DR support | No | `true` | `true` or `false` |
| Workload identity | No | `false` | `true` (needs SA name + roles) |
| CRDs | No | `false` | `true` if chart needs `installCRDs` |
| Shared namespace | No | `false` | `true` if using existing namespace like `monitoring` |

### Step 2: Select Pattern

Based on inputs, select from 5 module patterns defined in MODULE_PATTERNS.md:

| Pattern | When to Use |
|---------|------------|
| **Simple** | No env-specific config, minimal setup (like keda) |
| **Standard** | Env-specific configs, DR support (like argocd) |
| **Workload Identity** | Needs GCP SA with `yamlencode` injection (like loki) |
| **OCI** | Chart from OCI registry, no `repository` field (like litellm) |
| **Multi-Instance** | Same chart deployed multiple times (like gitlab-runner) |

### Step 3: Generate Module Files

Create `modules/helm/<chart-name>/` with:

#### 3a: `main.tf`
- `helm_release.this` resource (use `this` as resource name per convention)
- Repository URL, chart name, version, namespace
- Values file loading (concat/compact pattern based on DR + workload identity)
- CRD set block if needed
- Timeout for long-deploying charts

#### 3b: `variables.tf`
- `name` — string with default matching chart name
- `namespace` — string with default matching namespace input
- `install_version` — string with default matching version input
- `environment` — string, no default (if env configs needed)
- `dr` — bool, no default (if DR support)
- `project_id` — string, no default (if workload identity)
- Any chart-specific variables

#### 3c: `common.yaml`
- Base Helm values shared across environments
- Resource requests/limits template
- Service account configuration (if applicable)
- Network policy template (if applicable)

#### 3d: `configs-{env}.yaml` (per environment)
- Environment-specific overrides
- Typically: replica counts, resource sizes, ingress hosts
- Placeholder values with TODO comments

#### 3e: `configs-{env}-dr.yaml` (if DR support)
- DR-specific overrides
- Typically: reduced replicas, DR-specific endpoints

### Step 4: Register in `3-gke-package.tf`

Add module block following established pattern:

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
- Workload identity -> add `kubernetes_namespace.workload_identity`
- Depends on keda -> add `module.keda`
- Depends on cert-manager -> add `module.cert-manager`

### Step 5: Register in `helm_install.md`

Add a new section with manual helm install command:

```markdown
# <chart-name>

\`\`\`bash
helm repo add <repo-name> <repo-url>
helm repo update

helm upgrade --install <release-name> <repo-name>/<chart-name> --create-namespace --version <version> -n <namespace> --values common.yaml --values configs-dev.yaml
\`\`\`
```

### Step 6: Update Workload Identity (if needed)

If workload identity is required:

1. Add namespace to `local.workload_namespace` in `3-gke-identity.tf`
2. Add workload identity module block following existing patterns in the file

### Step 7: Summary

List all created/modified files and suggest next steps:
1. Run `terraform validate`
2. Run `terraform plan -target=module.<chart-name>`
3. Review generated values files
4. Test with `terraform apply -target=module.<chart-name>`

## Dependencies

- MODULE_PATTERNS.md — Reference implementations for each pattern
