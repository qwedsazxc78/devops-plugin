# secret-audit — Secret Management Audit Skill

Audits secret management practices: inventories secretGenerators, detects hardcoded secrets, checks cross-environment consistency, and validates secret hygiene.

## Usage

```
secret-audit            # Full audit
secret-audit inventory  # List all secrets only
secret-audit scan       # Scan for hardcoded secrets only
secret-audit drift      # Cross-env consistency only
```

## Arguments

$ARGUMENTS — Optional: `inventory`, `scan`, `drift`, or blank for full audit.

## Instructions

### Step 0: Discover Modules and Environments

Discover Kustomize modules by finding directories that contain a `base/` and `overlays/` subdirectory structure. For each discovered module, discover environments by listing subdirectories under that module's `overlays/` directory.

### Step 1: Secret Inventory

Parse all `kustomization.yaml` files in overlay directories to build a secret inventory:

For each `secretGenerator` entry, extract:
- Secret name
- Namespace
- Source file(s) (`.env` files or literal values)
- Environment (derived from the overlay subdirectory name)

Present as:
```
Secret Inventory
| Secret Name | Namespace | Env | Source | Type |
|------------|-----------|-----|--------|------|
| my-secret | app-ns | dev | env/my-secret.env | envs |
| my-secret | app-ns | stg | env/my-secret.env | envs |
| my-secret | app-ns | prd | env/my-secret.env | envs |
| ... | ... | ... | ... | ... |

Total: N secrets across M environments
```

### Step 2: Cross-Environment Consistency

Compare secrets across all discovered environments:
- Secrets that exist in one env but not others (may be intentional)
- Secrets with different source file names across envs
- Secrets in different namespaces across envs

```
Cross-Environment Secret Comparison
| Secret | env-1 | env-2 | env-3 | Status |
|--------|-------|-------|-------|--------|
| my-secret | YES | YES | YES | CONSISTENT |
| dev-only-secret | YES | NO | NO | SINGLE-ENV |
| ... | ... | ... | ... | ... |
```

### Step 3: Source File Validation

For every `.env` file referenced by a secretGenerator:
- Verify the file exists
- Check file is not empty
- Verify file is listed in `.gitignore` (env files with actual secrets should be gitignored)
- Check file permissions are restrictive

### Step 4: Hardcoded Secret Detection

#### 4a. Gitleaks Scan
```bash
gitleaks detect --source . --verbose --no-git
```

#### 4b. Pattern-Based Scan
Search for common hardcoded secret patterns in YAML files:
- `password:`, `secret:`, `token:`, `key:` with inline values
- Base64-encoded data in `data:` fields (Kubernetes Secrets)
- URLs with embedded credentials (`://user:pass@`)
- API keys matching common patterns (AWS, GCP, etc.)

Exclude false positives:
- References to secret objects (e.g., `secretKeyRef`)
- Kustomize secretGenerator references
- Comments

### Step 5: GeneratorOptions Check

Verify all secretGenerators have:
- `generatorOptions.disableNameSuffixHash: true` (common convention)
- `namespace` specified

### Step 6: Secret Rotation Readiness

Check if the secret management approach supports rotation:
- Are secrets managed via external secret operators (e.g., External Secrets, Sealed Secrets)?
- Are secrets directly committed as `.env` files?
- Is there a secret rotation process documented?

### Step 7: Audit Report

```
Secret Audit Report

## Inventory Summary
- Total secrets: N
- Environments covered: [list]
- Namespaces: [list]

## Cross-Environment Consistency
| Status | Count |
|--------|-------|
| Consistent (all envs) | N |
| Partial (some envs) | N |
| Single env only | N |

## Security Findings
| Severity | Finding | File | Recommendation |
|----------|---------|------|----------------|
| HIGH | Hardcoded credential | path/to/file:line | Use secretGenerator |
| MEDIUM | .env not gitignored | path/to/file | Add to .gitignore |
| LOW | Missing namespace | kustomization.yaml | Add namespace field |

## Missing Source Files
| Secret | Env | Expected File | Status |
|--------|-----|---------------|--------|
| ... | ... | ... | MISSING |

## Recommendations
1. [Prioritized action items]
2. Consider External Secrets Operator for production secret management
3. Implement secret rotation policy
```

### Graceful Degradation

- If `gitleaks` is not installed, suggest: `brew install gitleaks` and fall back to pattern-based scan only (Step 4b)
- Steps 1-3 and 5-6 require no external tools (file parsing only) and will always run
- Never block the entire audit because gitleaks is missing -- the pattern-based scan provides useful coverage
