# pipeline-check — CI/CD Pipeline Audit Skill

Audits the CI/CD pipeline configuration and pre-commit hooks for completeness, security coverage, and best practices.

## Usage

```
pipeline-check          # Full pipeline audit
pipeline-check ci       # CI pipeline only
pipeline-check hooks    # Pre-commit hooks only
pipeline-check gaps     # Gap analysis only
```

## Arguments

$ARGUMENTS — Optional: `ci`, `hooks`, `gaps`, or blank for full audit.

## Instructions

### Step 0: Detect CI/CD System

Detect which CI/CD system is in use by checking for configuration files:
- `.gitlab-ci.yml` → GitLab CI
- `.github/workflows/*.yml` → GitHub Actions
- `Jenkinsfile` → Jenkins
- `.circleci/config.yml` → CircleCI
- `bitbucket-pipelines.yml` → Bitbucket Pipelines
- `azure-pipelines.yml` → Azure DevOps

Adapt the analysis below to whichever CI system is detected. If multiple are present, audit all of them.

### Step 1: CI Pipeline Analysis

Read the detected CI configuration file(s) and analyze:

#### Stage Coverage
| Stage | Jobs | Purpose |
|-------|------|---------|
| (discovered) | (discovered) | (inferred from job names/commands) |

#### Job Configuration
For each job, check:
- `allow_failure` setting (should be `false` for critical checks)
- Trigger conditions (should trigger on merge/pull requests at minimum)
- Image versions (are they pinned or using `latest`?)
- Tags/runners configuration
- Timeout settings

#### Security Observations
- Identify security scanning jobs and whether they are blocking or non-blocking
- Flag any security jobs with `allow_failure: true` or `continue-on-error: true`
- Note: These should eventually be set to blocking after issue remediation

### Step 2: Pre-commit Hooks Analysis

Read `.pre-commit-config.yaml` and analyze:

#### Hook Coverage
| Category | Hooks | Version |
|----------|-------|---------|
| Formatting | (discovered) | (version) |
| Validation | (discovered) | (version) |
| Security | (discovered) | (version) |
| Safety | (discovered) | (version) |

#### Version Check
- Are hook versions up to date?
- Are there pinned revisions (good practice)?

### Step 3: Coverage Gap Analysis

Compare CI and pre-commit against a comprehensive pipeline:

| Check Type | Pre-commit | CI Pipeline | Gap? |
|------------|-----------|-------------|------|
| YAML format | (found?) | (found?) | (gap?) |
| YAML lint | (found?) | (found?) | (gap?) |
| YAML syntax | (found?) | (found?) | (gap?) |
| Kustomize build | (found?) | (found?) | (gap?) |
| K8s schema | (found?) | (found?) | (gap?) |
| Secret scan | (found?) | (found?) | (gap?) |
| Private key detect | (found?) | (found?) | (gap?) |
| IaC security | (found?) | (found?) | (gap?) |
| Vuln scan | (found?) | (found?) | (gap?) |
| Best practices | (found?) | (found?) | (gap?) |
| Policy check | (found?) | (found?) | (gap?) |
| Deprecated APIs | (found?) | (found?) | (gap?) |

### Step 4: Best Practice Recommendations

Check for CI/CD best practices:
- Branch protection rules mentioned
- MR/PR approval requirements
- Pipeline as code (not UI-configured)
- Artifact retention policies
- Cache configuration
- Runner tag consistency
- Image pinning (avoid `latest` tags in CI)
- Security scanning gates (non-blocking to blocking transition plan)

### Step 5: Pipeline Report

```
CI/CD Pipeline Audit Report

## CI Pipeline (<detected-system>)
| Stage | Job | Status | Blocking? | Image | Notes |
|-------|-----|--------|-----------|-------|-------|
| (discovered) | (discovered) | OK | YES/NO | (version) | (notes) |

## Pre-commit Hooks (.pre-commit-config.yaml)
| Hook | Version | Status | Notes |
|------|---------|--------|-------|
| (discovered) | (version) | OK | (notes) |

## Coverage Gaps
| Gap | Severity | Recommendation |
|-----|----------|----------------|
| (discovered gap) | HIGH/MEDIUM/LOW | (recommendation) |

## Scoring
| Category | Score |
|----------|-------|
| Security | N/10 |
| Validation | N/10 |
| Best Practices | N/10 |
| Overall | N/10 |

## Action Items (Prioritized)
1. [HIGH/MEDIUM/LOW] (action item)
2. ...
```

### Graceful Degradation

- This skill reads configuration files only and requires no external tools
- If a CI configuration file is missing, skip that section and note it in the report
- If `.pre-commit-config.yaml` is missing, skip that section and note it in the report
- All checks are file-parsing based and will always run
