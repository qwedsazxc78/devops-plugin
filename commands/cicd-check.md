# cicd-check — CI/CD Pipeline Analysis Skill

Analyzes and improves GitLab CI/CD pipelines for Terraform + Helm platforms. Identifies missing stages, recommends quality gates, and generates CI job snippets.

## Usage

```
cicd-check                # Full analysis + recommendations
cicd-check analyze        # Analysis only (no recommendations)
cicd-check recommend      # Recommendations only (skip detailed analysis)
cicd-check full           # Full analysis + recommendations + generate snippets
```

## Arguments

$ARGUMENTS --- Optional: scope (`analyze`, `recommend`, `full`). Default: `full`.

## Instructions

### Step 0: Discover CI/CD Configuration

Dynamically locate all CI/CD configuration files:

1. Find the root CI config:
   ```bash
   find . -maxdepth 1 -name ".gitlab-ci.yml" -o -name ".github" -type d | head -5
   ```
2. Find all included CI files by parsing `include:` directives in the root config:
   ```bash
   grep -r "local:" .gitlab-ci.yml 2>/dev/null
   find . -maxdepth 3 -name "*ci*.yml" -o -name "*ci*.yaml" | head -20
   ```
3. Locate the Terraform root directory (for understanding what the pipeline should cover)
4. Locate `.pre-commit-config.yaml` at the repository root
5. Check for quality gate references: `QUALITY_GATES.md`, `PIPELINE_PATTERNS.md`
6. Identify the CI platform (GitLab CI, GitHub Actions, etc.) from config file format

### Step 1: Pipeline Structure Analysis

*(Skip if scope is `recommend`)*

Map the current pipeline structure:

**File structure:** List all CI config files and their relationships (root, includes, templates).

**Current stages:** For each pipeline file, extract:

| Stage | Job Name | Trigger | Environment |
|-------|----------|---------|-------------|
| (discovered) | (discovered) | (discovered) | (discovered) |

**Current variables:** Extract pipeline-level variables and their purposes.

**Notable patterns:**
- Branch-based deployment strategy (which branches trigger which environments)
- Manual vs automatic deployment gates
- Template usage (shared CI templates)
- Caching configuration
- Security scanning integration

### Step 2: Pipeline Gap Analysis

*(Skip if scope is `recommend`)*

Compare current pipeline against recommended stages:

| Stage | Status | Priority | Description |
|-------|--------|----------|-------------|
| Format check | Present / Partial / Missing | High | `terraform fmt` check |
| Lint | Present / Missing | High | TFLint with provider rules |
| Security scan (IaC) | Present / Missing | High | SAST-IaC, tfsec, checkov, trivy |
| Validate | Present / Missing | Critical | `terraform validate` |
| Cost estimation | Present / Missing | Medium | Infracost or similar |
| Build/Plan | Present / Missing | Critical | `terraform plan` with artifacts |
| Drift detection | Present / Missing | Medium | Scheduled plan comparison |
| Deploy | Present / Missing | Critical | `terraform apply` per environment |
| Post-deploy verify | Present / Missing | Low | Health check after deploy |
| Cleanup | Present / Missing | Low | State cleanup, artifact purge |

For each gap, note:
- Whether the stage is partially implemented (e.g., template exists but not invoked)
- Effort to implement (one-line fix vs new job definition)
- Impact of the gap

### Step 3: Quality Gate Definition

*(Skip if scope is `analyze`)*

Define what should block deployment vs. what only warns:

**Blocking (must pass):**
- `terraform validate` failure
- `terraform plan` failure
- Critical security findings
- Secret detection hits

**Warning (report but do not block):**
- Lint warnings
- Medium/Low security findings
- Cost estimation thresholds
- Best practice violations

### Step 4: Pipeline Optimization Recommendations

*(Skip if scope is `analyze`)*

Analyze and recommend improvements:

**Caching:**
- Terraform provider cache (`TF_PLUGIN_CACHE_DIR`)
- TFLint plugin cache
- `.terraform/` directory caching

**Parallelism:**
- Identify jobs that can run in parallel (format, lint, security)
- Identify sequential dependencies that must remain ordered

**Branch strategy alignment:**
- MR-triggered jobs for feature branches
- Auto-deploy for dev/stg
- Manual gate for prd

**Security hardening:**
- Secret scanning in MR pipelines
- SAST-IaC coverage
- Container image scanning (if applicable)

### Step 5: Generate CI Job Snippets

*(Only if scope is `full`)*

For each recommended missing stage, generate ready-to-use CI job YAML in the format matching the detected CI platform (GitLab CI, GitHub Actions, etc.).

Present each snippet with:
- Job name and stage
- When it triggers (branches, MRs)
- Dependencies on other jobs
- Where to add it (which file)

### Step 6: Results Report

```
## CI/CD Pipeline Analysis Report

### Scope: <analyze/recommend/full>

### Pipeline Structure
- CI Platform: <GitLab CI / GitHub Actions / ...>
- Config files: N files
- Current stages: N stages
- Current jobs: N jobs

### Gap Analysis
- Critical gaps: N
- High priority gaps: N
- Medium priority gaps: N
- Low priority gaps: N

### Recommendations
1. [Priority] [Gap] -- [Effort] -- [Description]
2. ...

### Quality Gates
- Blocking: N checks
- Warning: N checks

### Generated Snippets
- (list of snippets generated, if scope is full)
```

## Graceful Degradation

- If no CI config file is found: report that no CI/CD pipeline exists, provide a starter template for the detected repository structure
- If CI config uses an unsupported format: perform best-effort analysis, note limitations
- If `PIPELINE_PATTERNS.md` does not exist: use built-in recommendations from Steps 2-4
- If `QUALITY_GATES.md` does not exist: use built-in quality gate definitions from Step 3
- If the Terraform root cannot be found: analyze CI config structure only, skip Terraform-specific recommendations
- If included CI files are external (URLs, templates): note them as external dependencies, analyze only local files
- Never block the analysis because a reference file is missing -- use built-in knowledge and note the gap
- Minimum viable analysis: read and parse the root CI config file (no external tools required)
