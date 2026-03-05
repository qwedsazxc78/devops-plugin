# Terraform Security Skill

## Purpose

Security auditing for GKE platforms managed via Terraform + Helm. Covers GKE cluster hardening, Terraform code scanning, Helm chart security review, and CIS benchmark alignment.

## Activation

This skill activates when the user requests:
- Security audit of the infrastructure
- GKE hardening review
- Helm security assessment
- Checking for hardcoded secrets
- CIS benchmark compliance check

## Workflow

### Step 1: GKE Cluster Security Audit

Analyze the GKE cluster configuration file (typically `3-gke.tf`) against the GKE_HARDENING.md checklist:

1. **Network Security**
   - Private cluster configuration (enable_private_nodes, enable_private_endpoint)
   - Network policy status
   - Master authorized networks
   - VPC native networking (ip_range_pods, ip_range_services)

2. **Node Security**
   - Node image type (COS_CONTAINERD preferred)
   - Auto-repair and auto-upgrade status
   - OAuth scopes (least privilege check)
   - Default service account usage (flag if using compute default SA)

3. **Cluster Security**
   - Security posture mode
   - Binary authorization
   - Pod Security Standards
   - Config connector status
   - GKE Backup Agent

4. **Maintenance**
   - Maintenance window configuration
   - Auto-upgrade windows

Report each finding with severity (Critical/High/Medium/Low/Info) and remediation steps from GKE_HARDENING.md.

### Step 2: Terraform Code Security Scan

Scan all `.tf` files in the Terraform root directory for:

1. **Hardcoded Secrets**
   - Search for patterns: `password`, `secret`, `token`, `key`, `credential` in string literals
   - Check `helm_install.md` for exposed secrets (e.g., the grafana OAuth secret)
   - Check values YAML files for sensitive data

2. **Permissive IAM**
   - Flag overly broad roles in `3-gke-identity.tf`:
     - `roles/owner`, `roles/editor` → Critical
     - `roles/storage.admin` (vs objectAdmin) → Medium
     - Excessive cross-project permissions → High
   - Check service account token creator permissions

3. **Insecure Defaults**
   - `create_namespace = true` without RBAC → Info (acceptable in this context)
   - Missing resource limits in Helm values → Medium
   - Missing network policies in Helm values → Medium

4. **State Security**
   - HTTP backend configuration (is it HTTPS?)
   - State file encryption
   - State file access controls

### Step 3: Helm Chart Security Review

For each active module, check against HELM_SECURITY.md:

1. **Service Account Configuration**
   - Does the chart create a service account?
   - Is workload identity properly configured?
   - Are RBAC permissions scoped correctly?

2. **Network Policies**
   - Does the chart support network policies?
   - Are they enabled in the values?
   - Are ingress/egress rules properly scoped?

3. **Image Security**
   - Are images pinned to digests or specific tags?
   - Are images from trusted registries?
   - Is image pull policy set correctly?

4. **Secrets Management**
   - Are secrets managed via external-secrets operator?
   - Any secrets in plain text in values files?
   - Proper secret rotation strategy?

5. **Resource Limits**
   - CPU/memory requests and limits set?
   - PDB (Pod Disruption Budget) configured?

### Step 4: CIS Benchmark Mapping

Map findings to CIS Kubernetes Benchmark controls:

| CIS Control | Description | Status |
|---|---|---|
| 5.1.1 | RBAC enabled | Check |
| 5.2.1 | Pod Security Standards | Check |
| 5.4.1 | Secrets encryption | Check |
| 5.6.1 | Network policies | Check |

Note: `kube-bench` module is deployed for runtime CIS checking. This skill focuses on configuration-level compliance.

### Step 5: Findings Report

Generate report using FINDINGS_TEMPLATE.md format:

```
## Security Audit Report

### Summary
- Critical: N
- High: N
- Medium: N
- Low: N
- Info: N

### Critical Findings
[Details per FINDINGS_TEMPLATE.md]

### Remediation Priority
1. [Highest priority fix]
2. [Next priority fix]
...
```

## Quick Scan Mode

When invoked from `*validate` pipeline:
- Only check for Critical and High findings
- Skip informational items
- Abbreviated report format

## Auto-Fix Capabilities

The skill can offer to auto-fix:
- **Low risk:** Enable network policies in Helm values (if chart supports it)
- **Low risk:** Add resource limits to Helm values
- **Low risk:** Remove hardcoded secrets from `helm_install.md` (replace with `<REDACTED>`)

The skill CANNOT auto-fix (requires user decision):
- IAM role changes (may break functionality)
- GKE cluster-level security settings (requires terraform apply)
- Network policy rules (requires understanding of traffic patterns)

## Dependencies

- GKE_HARDENING.md — GKE security checklist with current state
- HELM_SECURITY.md — Per-chart security patterns
- FINDINGS_TEMPLATE.md — Standard report format
