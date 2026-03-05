# security-scan — Multi-Tool Security Scanning Skill

Comprehensive security scanning using multiple FOSS tools: IaC scanning, vulnerability detection, policy checks, and supply chain analysis.

## Usage

```
security-scan              # Full security scan
security-scan dev          # Scan dev environment only
security-scan supply-chain # Supply chain analysis only
security-scan quick        # Quick scan (checkov + trivy only)
```

## Arguments

$ARGUMENTS — Optional: environment filter, `supply-chain`, `quick`, or blank for full scan.

## Instructions

### Step 0: Discover Modules and Environments

Discover Kustomize modules by finding directories that contain a `base/` and `overlays/` subdirectory structure. For each discovered module, discover environments by listing subdirectories under that module's `overlays/` directory.

### Step 0b: Determine Kubernetes Version

Use the K8s version from `.k8s-version` file if present (read the first line, trimmed), otherwise default to `1.28.0`.

### Step 1: Build Manifests

For each environment in scope:
```bash
kustomize build <module>/overlays/<env> > /tmp/security-<module>-<env>.yaml
```

### Step 2: IaC Security (checkov)

```bash
checkov -f /tmp/security-<module>-<env>.yaml --framework kubernetes --quiet --compact
```

Checks for:
- Privileged containers
- Missing resource limits
- Writable root filesystem
- Missing security contexts
- Capabilities not dropped

If `checkov` is not installed, suggest: `brew install checkov` or `pip install checkov`

### Step 3: Vulnerability Scanning (trivy)

```bash
trivy config /tmp/security-<module>-<env>.yaml --severity HIGH,CRITICAL
```

Checks for:
- Known CVEs in configuration patterns
- Misconfigurations per CIS benchmarks
- Secret exposure risks

If `trivy` is not installed, suggest: `brew install trivy`

### Step 4: Best Practice Security (kube-score)

```bash
kube-score score /tmp/security-<module>-<env>.yaml
```

Security-specific checks:
- Container security context
- Network policies
- Service account tokens

If `kube-score` is not installed, suggest: `brew install kube-score`

### Step 5: Policy Compliance (polaris)

```bash
polaris audit --audit-path /tmp/security-<module>-<env>.yaml --format json
```

Checks against:
- Security (runAsNonRoot, readOnlyRootFilesystem, etc.)
- Reliability (resource requests/limits, probes)
- Efficiency (CPU/memory limits)

If `polaris` is not installed, suggest: `brew install FairwindsOps/tap/polaris`

### Step 6: Security Lint (kube-linter)

```bash
kube-linter lint /tmp/security-<module>-<env>.yaml
```

Additional security checks:
- Default service account usage
- SSH port exposure
- Writable host paths

If `kube-linter` is not installed, suggest: `brew install kube-linter`

### Step 7: Policy Engine (kyverno CLI)

```bash
kyverno apply /path/to/policies/ --resource /tmp/security-<module>-<env>.yaml
```

Only if kyverno policies exist in the repo. If `kyverno` is not installed, suggest: `brew install kyverno`

### Step 8: Supply Chain Analysis (if `supply-chain` mode or full scan)

#### 8a. SBOM Generation (syft)
```bash
syft /tmp/security-<module>-<env>.yaml -o json > /tmp/sbom-<module>-<env>.json
```
If `syft` is not installed, suggest: `brew install syft`

#### 8b. CVE Scan from SBOM (grype)
```bash
grype sbom:/tmp/sbom-<module>-<env>.json
```
If `grype` is not installed, suggest: `brew install grype`

#### 8c. Image Signature Verification (cosign)
Extract image references from manifests and verify signatures:
```bash
cosign verify <image-reference>
```
If `cosign` is not installed, suggest: `brew install cosign`

### Step 9: Secret Scanning (gitleaks)

```bash
gitleaks detect --source . --verbose --no-git
```

Supplementary check for secrets in the repository.

### Step 10: Security Report

```
Security Scan Report

## Summary
| Severity | Count |
|----------|-------|
| CRITICAL | N |
| HIGH | N |
| MEDIUM | N |
| LOW | N |

## Tool Results
| Tool | Status | Critical | High | Medium | Low |
|------|--------|----------|------|--------|-----|
| checkov | RAN | N | N | N | N |
| trivy | RAN | N | N | N | N |
| kube-score | RAN | N | N | N | N |
| polaris | RAN | N | N | N | N |
| kube-linter | RAN | N | N | N | N |
| kyverno | SKIP | - | - | - | - |
| gitleaks | RAN | N | N | N | N |

## Supply Chain (if applicable)
| Check | Status | Details |
|-------|--------|---------|
| SBOM Generated | YES/NO | N components |
| CVE Scan | PASS/FAIL | N vulnerabilities |
| Image Signatures | PASS/FAIL/SKIP | N verified |

## Critical Findings (if any)
1. [Finding description, file, remediation]
2. ...

## Recommendations
1. [Prioritized action items]

Tool Availability:
| Tool | Installed | Install Command |
|------|-----------|-----------------|
| checkov | YES/NO | pip install checkov |
| trivy | YES/NO | brew install trivy |
| kube-score | YES/NO | brew install kube-score |
| polaris | YES/NO | brew install FairwindsOps/tap/polaris |
| kube-linter | YES/NO | brew install kube-linter |
| kyverno | YES/NO | brew install kyverno |
| syft | YES/NO | brew install syft |
| grype | YES/NO | brew install grype |
| cosign | YES/NO | brew install cosign |
| gitleaks | YES/NO | brew install gitleaks |
```

### Graceful Degradation

- Always run available tools and skip missing ones
- Never block the entire scan because one tool is missing
- Show install commands for all missing tools
- Minimum viable scan: checkov + gitleaks

### Cleanup

```bash
rm -f /tmp/security-*.yaml /tmp/sbom-*.json
```
