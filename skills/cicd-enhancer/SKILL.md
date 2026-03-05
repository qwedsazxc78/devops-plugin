# CI/CD Enhancer Skill

## Purpose

Analyzes and improves the GitLab CI/CD pipeline for the eye-of-horus platform. Identifies missing stages, recommends quality gates, and generates CI job YAML snippets.

## Activation

This skill activates when the user requests:
- CI/CD pipeline review or improvement
- Adding new pipeline stages (lint, security, cost estimation)
- Pipeline optimization
- Quality gate configuration

## Current Pipeline Analysis

### File Structure

```
.gitlab-ci.yml                            # Root CI config — includes SAST, Secret Detection, app-ci, pr-agent
application/app-ci.yml                    # Application pipeline (validate → build → deploy)
ci/terraform-gitlab-ci.yml               # Shared Terraform CI template (included by app-ci.yml)
ci/pr-agent-gitlab-ci.yml                # PR agent CI template (included by root .gitlab-ci.yml)
```

The root `.gitlab-ci.yml` includes:
- `Security/SAST.gitlab-ci.yml` (GitLab template)
- `Security/SAST-IaC.gitlab-ci.yml` (GitLab template — already active at root level)
- `Security/Secret-Detection.gitlab-ci.yml` (GitLab template)
- `application/app-ci.yml` (application Terraform pipeline)
- `ci/pr-agent-gitlab-ci.yml` (PR review agent)

### Current Stages

From `app-ci.yml`:

| Stage | Job Name | Trigger | Environment |
|-------|----------|---------|-------------|
| Validate | `app-validate` | All branches | — |
| Build | `app-build` | After validate | — |
| Deploy Dev | `app-deploy-dev` | Auto on `dev`, `dev-dr` | dev |
| Deploy Stg | `app-deploy-stg` | Auto on `stg` | stg |
| Deploy Prd | `app-deploy-prd` | Manual on `prd`, `prd-dr` | prd |
| Cleanup | `app-cleanup` | Manual | — |

### Current Variables

```yaml
TF_ROOT: ${CI_PROJECT_DIR}/application
TF_VAR_WORKSPACE_ENV: ${CI_COMMIT_BRANCH}
TF_VAR_GCP_PROJECT: monitoring-${CI_COMMIT_BRANCH}-de514-ia007  # Cleaned in before_script
```

### Notable Patterns

- DR branches (`dev-dr`, `prd-dr`) strip `-dr` suffix for GCP project name
- SAST-IaC template is included at root `.gitlab-ci.yml` level (but commented out in `app-ci.yml`)
- Security/SAST and Secret-Detection templates are active at root level
- No explicit lint or cost estimation stages in the application pipeline
- Production deploy requires manual approval
- Uses GitLab Terraform templates (`.terraform:validate`, `.terraform:build`, `.terraform:deploy`)

## Workflow

### Step 1: Pipeline Gap Analysis

Compare current pipeline against recommended stages:

| Stage | Status | Priority | Description |
|-------|--------|----------|-------------|
| Format check | **Partial** (template exists) | High | `.terraform:fmt` job defined in `ci/terraform-gitlab-ci.yml` but never invoked from `app-ci.yml`. One-line fix: `app-fmt: extends: .terraform:fmt` |
| Lint | Missing | High | TFLint with GCP rules. `.tflint.hcl` already exists at repo root. |
| Security scan (IaC) | **Present** (root level) | Low | `Security/SAST-IaC.gitlab-ci.yml` active in root `.gitlab-ci.yml`. Consider adding trivy for additional coverage. |
| Validate | Present | — | Already exists via `app-validate` |
| Cost estimation | Missing | Medium | Infracost or similar |
| Build/Plan | Present | — | Already exists via `app-build`. Caching already configured in shared template. |
| Drift detection | Missing | Medium | Scheduled plan comparison |
| Deploy | Present | — | Already exists for dev/stg/prd |
| Post-deploy verify | Missing | Low | Health check after deploy |
| Cleanup | Present | — | `app-cleanup` with manual trigger |

**Note:** The root `.gitlab-ci.yml` defines stages: `[validate, test, pr_agent, build, deploy, cleanup]`. Any new stages (e.g., `cost`, `verify`) must be added to this root stages list.

### Step 2: Generate CI Job Snippets

For each recommended stage, generate ready-to-use GitLab CI job YAML. See PIPELINE_PATTERNS.md for full snippets.

### Step 3: Quality Gate Definition

Define what blocks deployment vs. what only warns. See QUALITY_GATES.md.

### Step 4: Pipeline Optimization

Analyze and recommend:

1. **Caching** (`.terraform/` caching already configured in `ci/terraform-gitlab-ci.yml` with key `${TF_ROOT}`)
   - Add TFLint plugin cache
   - Add Terraform provider plugin cache (`TF_PLUGIN_CACHE_DIR`)

2. **Parallelism**
   - Run format, lint, and security in parallel
   - Run cost estimation in parallel with plan

3. **Branch strategy alignment**
   - MR-triggered jobs for feature branches
   - Auto-deploy for dev/stg
   - Manual gate for prd

### Step 5: Generate Updated Pipeline

Produce a complete updated `app-ci.yml` incorporating:
- All recommended stages
- Quality gates
- Optimizations
- Preserved existing behavior

Present as a diff for user review.

## Dependencies

- PIPELINE_PATTERNS.md — CI job YAML snippets
- QUALITY_GATES.md — Quality gate definitions
- terraform-validate skill — Validation rules integrated into CI
- terraform-security skill — Security scan rules integrated into CI
