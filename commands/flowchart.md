# flowchart — Workflow Flowchart Generation Skill

Generates workflow flowcharts for CI/CD pipelines, deployment processes, incident runbooks, and operational procedures using Mermaid.

## Usage

```
flowchart                  # All flowchart types
flowchart cicd             # CI/CD pipeline flow
flowchart deployment       # Deployment workflow
flowchart incident         # Incident response runbook
flowchart onboarding       # Developer onboarding flow
flowchart secret-rotation  # Secret rotation procedure
flowchart all              # Generate all types
```

## Arguments

$ARGUMENTS — Optional: flowchart type. Default: `all`.

## Instructions

### Step 0: Discover Repository Structure

- **Discover Kustomize modules** by finding directories that contain a `base/` and `overlays/` subdirectory structure
- **Discover environments** by listing subdirectories under each module's `overlays/` directory
- **Detect CI/CD config** by looking for `.gitlab-ci.yml`, `.github/workflows/`, `Jenkinsfile`, or similar CI configuration files
- Use discovered structure to build accurate, repo-specific flowcharts

### Type 1: CI/CD Pipeline Flow (`cicd`)

Parse the CI/CD configuration file (e.g., `.gitlab-ci.yml`, GitHub Actions workflows) and generate a flowchart of the pipeline:

```mermaid
flowchart TD
    START([MR/PR Created]) --> SECURITY_STAGE

    subgraph SECURITY_STAGE["Security Stage"]
        GITLEAKS["gitleaks\nSecret Detection"]
        CHECKOV["checkov\nIaC Security"]
        TRIVY["trivy\nVuln Scanning"]
    end

    SECURITY_STAGE --> VALIDATE_STAGE

    subgraph VALIDATE_STAGE["Validation Stage"]
        YAMLLINT["yaml-lint\nYAML Validation"]
        KUSTOMIZE["kustomize-validate\nBuild Validation"]
        KUBECONFORM["kubeconform\nAPI Schema"]
    end

    VALIDATE_STAGE --> TEST_STAGE

    subgraph TEST_STAGE["Test Stage"]
        TESTPLAN["tests\nIntegration Tests"]
    end

    TEST_STAGE --> MERGE([Merge to Branch])
    MERGE --> ARGOCD["ArgoCD Auto-Sync"]
    ARGOCD --> DEPLOY([Deployed])
```

Build stages and jobs dynamically from the actual CI config. Annotate each job with:
- `allow_failure` status
- Image used
- Trigger conditions

### Type 2: Deployment Workflow (`deployment`)

Look for deployment documentation (e.g., `docs/deployment-workflow.md`). If found, base the flowchart on it. Otherwise, generate a generic Kustomize + ArgoCD deployment flow:

```mermaid
flowchart TD
    A[Edit YAML] --> B{Which layer?}
    B -->|Base| C[<module>/base/]
    B -->|Overlay| D[<module>/overlays/<env>/]

    C --> E[Affects ALL envs]
    D --> F[Affects single env]

    E --> G[kustomize build validation]
    F --> G

    G --> H{Build passes?}
    H -->|No| I[Fix errors]
    I --> A
    H -->|Yes| J[pre-commit hooks]

    J --> K{Hooks pass?}
    K -->|No| L[Auto-fix + re-run]
    L --> J
    K -->|Yes| M[Create MR/PR]

    M --> N[CI Pipeline runs]
    N --> O{Pipeline passes?}
    O -->|No| P[Fix issues]
    P --> A
    O -->|Yes| Q[Code Review]

    Q --> R{Approved?}
    R -->|No| S[Address feedback]
    S --> A
    R -->|Yes| T[Merge to branch]

    T --> U[ArgoCD detects change]
    U --> V[Auto-sync to cluster]
    V --> W([Deployed])
```

### Type 3: Incident Response Runbook (`incident`)

```mermaid
flowchart TD
    ALERT([Alert Triggered]) --> ASSESS{Severity?}

    ASSESS -->|P1 Critical| P1[Immediate response]
    ASSESS -->|P2 High| P2[30min response]
    ASSESS -->|P3 Medium| P3[4hr response]

    P1 --> DIAG[Diagnose]
    P2 --> DIAG
    P3 --> DIAG

    DIAG --> CHECK{ArgoCD sync status?}
    CHECK -->|Out of Sync| SYNC[Force sync or rollback]
    CHECK -->|Synced| PODS{Pod status?}

    PODS -->|CrashLoop| LOGS[Check pod logs]
    PODS -->|Pending| RESOURCES[Check resource quotas]
    PODS -->|Running| METRICS[Check metrics/monitoring]

    SYNC --> VERIFY[Verify resolution]
    LOGS --> FIX[Fix configuration]
    RESOURCES --> SCALE[Adjust quotas/limits]
    METRICS --> INVESTIGATE[Deep investigation]

    FIX --> COMMIT[Commit fix to Git]
    SCALE --> COMMIT
    INVESTIGATE --> COMMIT

    COMMIT --> ARGOCD[ArgoCD syncs fix]
    ARGOCD --> VERIFY
    VERIFY --> POSTMORTEM([Write postmortem])
```

### Type 4: Developer Onboarding Flow (`onboarding`)

Look for onboarding documentation (e.g., `docs/developer-onboarding.md`). If found, base the flowchart on it. Otherwise, generate a generic GitOps onboarding flow:

```mermaid
flowchart TD
    START([New Developer]) --> PREREQ[Install Prerequisites]

    PREREQ --> TOOLS["Install tools:\nkustomize, kubectl,\npre-commit, yamllint"]
    TOOLS --> CLONE[Clone repository]
    CLONE --> HOOKS[pre-commit install]

    HOOKS --> LEARN{Learn patterns}
    LEARN --> BASE[Understand base/overlay]
    LEARN --> ARGOCD_LEARN[Understand ArgoCD apps]
    LEARN --> SECRETS[Understand secret management]

    BASE --> FIRST_TASK[First task: add resource]
    ARGOCD_LEARN --> FIRST_TASK
    SECRETS --> FIRST_TASK

    FIRST_TASK --> VALIDATE[Run validation]
    VALIDATE --> MR[Create MR/PR]
    MR --> REVIEW[Get review]
    REVIEW --> MERGED([First contribution!])
```

### Type 5: Secret Rotation Procedure (`secret-rotation`)

Generate dynamically using discovered environments:

```mermaid
flowchart TD
    START([Rotation Triggered]) --> IDENTIFY[Identify secrets to rotate]

    IDENTIFY --> GEN[Generate new credentials]
    GEN --> UPDATE_ENV[Update secret files]
```

Then for each discovered environment (in promotion order, e.g., dev -> stg -> prd):

```mermaid
    UPDATE_ENV --> ENV1[Update <env1> overlay]
    ENV1 --> TEST_ENV1[Validate <env1> build]
    TEST_ENV1 --> DEPLOY_ENV1[Deploy to <env1>]
    DEPLOY_ENV1 --> VERIFY_ENV1{<env1> working?}

    VERIFY_ENV1 -->|Yes| ENV2[Update <env2> overlay]
    VERIFY_ENV1 -->|No| ROLLBACK_ENV1[Rollback <env1>]
```

End with:
```mermaid
    VERIFY_LAST -->|Yes| REVOKE[Revoke old credentials]
    REVOKE --> DONE([Rotation complete])
```

### Output

Save all flowcharts to `docs/diagrams/`:
- `flowchart-cicd-pipeline.md`
- `flowchart-deployment-workflow.md`
- `flowchart-incident-runbook.md`
- `flowchart-onboarding.md`
- `flowchart-secret-rotation.md`

### Rendering (optional)

If `mmdc` is installed:
```bash
mmdc -i docs/diagrams/flowchart-cicd-pipeline.md -o docs/diagrams/flowchart-cicd-pipeline.png
```

If not installed, suggest: `npm install -g @mermaid-js/mermaid-cli`

### Graceful Degradation

- This skill generates Mermaid source files (plain text) and requires no external tools
- The `cicd` type reads CI config files -- if none are found, skip that flowchart and note which CI configs were searched for
- The `deployment` type reads deployment docs -- if missing, generate a generic deployment flow based on repo structure
- The `onboarding` type reads onboarding docs -- if missing, generate a generic onboarding flow based on repo structure
- If `mmdc` is not installed, skip PNG rendering -- the Mermaid source files render natively in GitLab/GitHub markdown

### Summary

```
Flowcharts Generated

| Flowchart | File | Rendered? |
|-----------|------|-----------|
| CI/CD Pipeline | docs/diagrams/flowchart-cicd-pipeline.md | PNG (if mmdc) |
| Deployment Workflow | docs/diagrams/flowchart-deployment-workflow.md | PNG (if mmdc) |
| Incident Runbook | docs/diagrams/flowchart-incident-runbook.md | PNG (if mmdc) |
| Onboarding | docs/diagrams/flowchart-onboarding.md | PNG (if mmdc) |
| Secret Rotation | docs/diagrams/flowchart-secret-rotation.md | PNG (if mmdc) |

All files use Mermaid syntax -- renders natively in GitLab/GitHub markdown.
```
