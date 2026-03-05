# tf-security — Terraform Security Audit Skill

Security auditing for GKE platforms managed via Terraform + Helm. Covers GKE cluster hardening, IAM review, Helm chart security, Terraform code scanning, and CIS benchmark alignment.

## Usage

```
tf-security              # Full security audit
tf-security quick        # Critical and High findings only
tf-security gke          # GKE hardening review only
tf-security iam          # IAM and permissions review only
tf-security helm         # Helm chart security review only
```

## Arguments

$ARGUMENTS --- Optional: scope (`full`, `quick`, `gke`, `iam`, `helm`). Default: `full`.

## Instructions

### Step 0: Discover Infrastructure Layout

Dynamically locate key files and directories:

1. Find the Terraform root by searching for directories with `*.tf` files containing backend configuration:
   ```bash
   find . -maxdepth 3 -name "*.tf" | head -20
   ```
2. Locate GKE cluster definitions (files matching `*gke*.tf`)
3. Locate identity/IAM definitions (files matching `*identity*.tf` or `*iam*.tf`)
4. Locate Helm module directories (`modules/helm/*/`)
5. Locate values files (`*.yaml` in module directories)
6. Locate the manual install reference (`helm_install.md` if present)
7. Check for security reference files: `GKE_HARDENING.md`, `HELM_SECURITY.md`, `FINDINGS_TEMPLATE.md`

### Step 1: GKE Cluster Security Audit

*(Skip if scope is `iam` or `helm`)*

Analyze the GKE cluster configuration file against hardening best practices:

**Network Security:**
- Private cluster configuration (`enable_private_nodes`, `enable_private_endpoint`)
- Network policy status
- Master authorized networks
- VPC native networking (`ip_range_pods`, `ip_range_services`)

**Node Security:**
- Node image type (COS_CONTAINERD preferred)
- Auto-repair and auto-upgrade status
- OAuth scopes (least privilege check)
- Default service account usage (flag if using compute default SA)

**Cluster Security:**
- Security posture mode
- Binary authorization
- Pod Security Standards
- Config connector status
- GKE Backup Agent

**Maintenance:**
- Maintenance window configuration
- Auto-upgrade windows

Report each finding with severity (Critical / High / Medium / Low / Info) and remediation steps.

### Step 2: Terraform Code Security Scan

*(Skip if scope is `gke` or `helm`)*

Scan all `.tf` files in the Terraform root for:

**Hardcoded Secrets:**
- Search for patterns: `password`, `secret`, `token`, `key`, `credential` in string literals
- Check `helm_install.md` for exposed secrets
- Check values YAML files for sensitive data

**Permissive IAM:**
- Flag overly broad roles:
  - `roles/owner`, `roles/editor` -- Critical
  - `roles/storage.admin` (vs objectAdmin) -- Medium
  - Excessive cross-project permissions -- High
- Check service account token creator permissions

**Insecure Defaults:**
- `create_namespace = true` without RBAC -- Info
- Missing resource limits in Helm values -- Medium
- Missing network policies in Helm values -- Medium

**State Security:**
- HTTP backend configuration (is it HTTPS?)
- State file encryption
- State file access controls

### Step 3: Helm Chart Security Review

*(Skip if scope is `gke` or `iam`)*

For each active Helm module discovered in Step 0:

**Service Account Configuration:**
- Does the chart create a service account?
- Is workload identity properly configured?
- Are RBAC permissions scoped correctly?

**Network Policies:**
- Does the chart support network policies?
- Are they enabled in the values?
- Are ingress/egress rules properly scoped?

**Image Security:**
- Are images pinned to digests or specific tags?
- Are images from trusted registries?
- Is image pull policy set correctly?

**Secrets Management:**
- Are secrets managed via external-secrets operator?
- Any secrets in plain text in values files?
- Proper secret rotation strategy?

**Resource Limits:**
- CPU/memory requests and limits set?
- PDB (Pod Disruption Budget) configured?

### Step 4: CIS Benchmark Mapping

*(Skip if scope is `quick`)*

Map findings to CIS Kubernetes Benchmark controls:

| CIS Control | Description | Status |
|---|---|---|
| 5.1.1 | RBAC enabled | Check |
| 5.2.1 | Pod Security Standards | Check |
| 5.4.1 | Secrets encryption | Check |
| 5.6.1 | Network policies | Check |

### Step 5: Security Audit Report

Generate the final report:

```
## Security Audit Report

### Scope: <full/quick/gke/iam/helm>

### Summary
- Critical: N
- High: N
- Medium: N
- Low: N
- Info: N

### Critical Findings
[ID] [Severity] [Category] [Description]
  Location: <file>:<line>
  Remediation: <steps>

### High Findings
...

### Remediation Priority
1. [Highest priority fix]
2. [Next priority fix]
...
```

In `quick` mode, only report Critical and High findings with abbreviated format.

## Graceful Degradation

- If `terraform` is not installed: skip `terraform` commands, perform file-based static analysis only
- If `tfsec` is available: run `tfsec <TF_ROOT>` as an additional scan in Step 2. If not installed, suggest `brew install tfsec`
- If `checkov` is available: run `checkov -d <TF_ROOT>` as an additional scan. If not installed, suggest `pip install checkov`
- If `trivy` is available: run `trivy config <TF_ROOT>` for misconfig scanning. If not installed, suggest `brew install trivy`
- If GKE hardening reference (`GKE_HARDENING.md`) does not exist: use built-in checklist from Step 1
- If Helm security reference (`HELM_SECURITY.md`) does not exist: use built-in checklist from Step 3
- Never block the entire audit because one tool is missing -- skip that check and show the install command
- Minimum viable audit: file-based static analysis (grep for secrets, IAM review, config review) requires no external tools
