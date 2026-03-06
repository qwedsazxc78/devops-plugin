# Horus Full Pipeline Check — 2026-03-06

| Key | Value |
|-----|-------|
| **Date** | 2026-03-06 |
| **Branch** | dev |
| **Overall** | **NEEDS ATTENTION** |
| **Steps** | 8 total: 5 PASS, 1 FAIL, 2 WARN |

---

## Summary

| # | Step | Type | Status |
|---|------|------|--------|
| 1 | Terraform Format | exec | PASS |
| 2 | Terraform Init | exec | PASS |
| 3 | Terraform Validate | exec | PASS |
| 4 | Helm Version Consistency | read | **FAIL** |
| 5 | JSON Schema Validation | read | PASS |
| 6 | Module Source Paths | read | PASS |
| 7 | Environment Config Completeness | read | **WARN** |
| 8 | Security Scan | read | **WARN** |

---

## FAIL: Step 4 — Helm Version Consistency

**17/22 modules consistent** — 3 missing from `helm_install.md`, 2 version mismatches.

### Version Mismatches (helm_install.md outdated)

| Module | 3-gke-package.tf | variable(s).tf | helm_install.md | Issue |
|--------|------------------|----------------|-----------------|-------|
| uptime-kuma | 2.24.0 | 2.24.0 | 2.22.0 | md outdated |
| metabase | 2.24.0 | 2.24.0 | 2.22.0 | md outdated |

### Missing from helm_install.md

| Module | Version | Issue |
|--------|---------|-------|
| argo-rollouts | 2.40.5 | Not listed in helm_install.md |
| cert-manager | 1.19.2 | Not listed in helm_install.md |
| cert-exporter | 3.14.0 | Not listed in helm_install.md |

### Auto-fix Available

- Update `helm_install.md` with correct versions for uptime-kuma (2.24.0) and metabase (2.24.0)
- Add argo-rollouts, cert-manager, cert-exporter entries to `helm_install.md`

---

## WARN: Step 7 — Environment Config Completeness

**1 module missing DR config files.**

| Module | Missing Files | Impact |
|--------|---------------|--------|
| litellm | `configs-dev-dr.yaml`, `configs-prd-dr.yaml` | `terraform apply` will fail for dev-dr and prd-dr workspaces (`file()` error on missing file) |

### Auto-fix Available

- Create `configs-dev-dr.yaml` and `configs-prd-dr.yaml` for litellm (can copy from base configs with DR overrides)

---

## WARN: Step 8 — Security Scan

**14 findings** — 4 high, 6 medium, 4 low.

### High Severity (4)

| File | Line | Finding | Recommendation |
|------|------|---------|----------------|
| `modules/helm/argocd/configs-dev.yaml` | 111 | Hardcoded Slack bot token (xoxb-...) | Move to GCP Secret Manager + external-secrets |
| `modules/helm/argocd/configs-stg.yaml` | 111 | Hardcoded Slack bot token (xoxb-...) | Move to GCP Secret Manager + external-secrets |
| `modules/helm/argocd/configs-prd.yaml` | 111 | Hardcoded Slack bot token (xoxb-...) | Move to GCP Secret Manager + external-secrets |
| `modules/helm/airflow/common.yaml` | 8 | Hardcoded webserverSecretKey | Move to GCP Secret Manager + external-secrets |

### Medium Severity (6)

| File | Finding |
|------|---------|
| `modules/helm/postgresql-ha/common.yaml` | Hardcoded PostgreSQL/repmgr/admin passwords |
| `modules/helm/mlflow/configs-{dev,stg,prd}.yaml` | Hardcoded database passwords (3 files) |
| `modules/helm/metabase/configs-dev.yaml` | Hardcoded database password |
| `modules/helm/langfuse/configs-dev.yaml` | Hardcoded rootPassword, postgres/redis/clickhouse passwords |

### Low Severity (4)

| File | Finding |
|------|---------|
| `modules/helm/kube-prometheus-stack/common.yaml` | Hardcoded auth_password for Prometheus |
| `3-gke.tf:29` | GKE uses compute default SA (no dedicated node SA) |
| `3-gke.tf:126` | Node pool OAuth scope: cloud-platform (overly broad) |
| `3-gke-identity.tf:69` | external-secrets SA has serviceAccountTokenCreator across 12 projects |

---

<details>
<summary>PASS: Step 1 — Terraform Format</summary>

All files properly formatted. 0 files need formatting.

**Step YAML:** `docs/reports/2026-03-06/01-terraform-fmt.yaml`
</details>

<details>
<summary>PASS: Step 2 — Terraform Init</summary>

Successfully initialized with 7 providers (backend=false). Providers: google v7.15.0, google-beta v7.15.0, kubernetes v2.38.0, null v3.2.4, helm v3.1.1, random v3.7.2, external v2.3.5.

**Step YAML:** `docs/reports/2026-03-06/02-terraform-init.yaml`
</details>

<details>
<summary>PASS: Step 3 — Terraform Validate</summary>

Configuration is valid.

**Step YAML:** `docs/reports/2026-03-06/03-terraform-validate.yaml`
</details>

<details>
<summary>PASS: Step 5 — JSON Schema Validation</summary>

6/6 files valid. Schema: `infra/schema/app-config.schema.json`. All 5 app-config files pass schema validation + 1 tags file is valid JSON.

**Step YAML:** `docs/reports/2026-03-06/05-json-schema.yaml`
</details>

<details>
<summary>PASS: Step 6 — Module Source Paths</summary>

All 22 module paths exist (21 local Helm + 1 remote GKE registry). n8n module path exists but is commented out.

**Step YAML:** `docs/reports/2026-03-06/06-module-paths.yaml`
</details>

---

## Step YAML Files

All per-step records are stored at:

```
docs/reports/2026-03-06/
  01-terraform-fmt.yaml
  02-terraform-init.yaml
  03-terraform-validate.yaml
  04-helm-versions.yaml
  05-json-schema.yaml
  06-module-paths.yaml
  07-env-configs.yaml
  08-security-scan.yaml
```

---

## Recommended Next Actions

1. **[Quick Fix]** Update `helm_install.md` — fix 2 outdated versions + add 3 missing entries
2. **[Quick Fix]** Create litellm DR config files (`configs-dev-dr.yaml`, `configs-prd-dr.yaml`)
3. **[Priority]** Migrate hardcoded secrets (4 high-severity) to GCP Secret Manager + external-secrets
4. **[Planned]** Create dedicated GKE node service account (replace compute default SA)
5. **[Planned]** Restrict node pool OAuth scopes from `cloud-platform` to minimal set

---

*Generated by Horus IaC Operations Agent*
