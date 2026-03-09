# DevOps Plugin — Cloud Integrations Roadmap

[English](#english) | [繁體中文](#繁體中文)

---

<a id="english"></a>

## English

This roadmap outlines **implementable** integrations and enhancements for the DevOps plugin, validated against the current plugin architecture (file analysis + local CLI tool execution).

> **Scope constraint:** The plugin operates via file reading/analysis and local CLI tool execution. Features requiring cloud provider SDK authentication (AWS API, Azure API, GCP API) or live cluster state queries are **out of scope** unless a local CLI tool (e.g., `infracost`, `trivy`, `cosign`) bridges the gap.

---

## Current State

The plugin currently supports:
- **Cloud:** GCP (GKE, workload identity, IAM) with basic AWS/Azure references
- **IaC:** Terraform + Helm
- **GitOps:** Kustomize + ArgoCD
- **CI/CD:** GitLab CI, GitHub Actions, Jenkins, CircleCI, Azure Pipelines, Bitbucket
- **Security:** 15+ scanning tools with graceful degradation

---

## Phase 1 — High Priority (P0)

### 1. AWS EKS Static Analysis

**Why:** AWS is the largest cloud provider; many teams manage EKS via Terraform/Helm.

**Approach:** Analyze Terraform files, Helm values, and Kubernetes manifests for AWS-specific patterns. No AWS API calls required.

| Feature | Description | Implementation |
|---------|-------------|----------------|
| EKS Terraform audit | Validate `aws_eks_cluster`, `aws_eks_node_group` resources against best practices | Read Terraform files + pattern matching |
| IRSA binding analysis | Audit IAM role annotations in ServiceAccount YAML and Terraform `aws_iam_role` | Read YAML/HCL files + cross-reference |
| ALB Controller validation | Validate ALB/NLB ingress annotations and TargetGroupBinding | Read Kubernetes manifest annotations |
| eksctl config validation | Validate eksctl ClusterConfig YAML structure and values | Read + schema validation |
| EKS Add-ons version check | Cross-reference EKS add-on versions in Terraform with latest known versions | Read HCL + known version list |
| AWS security hardening checklist | CIS EKS Benchmark checks on Terraform/manifest level | Extend `terraform-security` skill |

**Implementation:**
- New skill: `eks-security` under `skills/`
- Extend `terraform-security` SKILL.md with AWS-specific hardening checklist
- Add AWS CodePipeline/CodeBuild patterns to `cicd-enhancer`

---

### 2. Cost Estimation (Infracost CLI)

**Why:** FinOps is a top priority; Infracost provides local CLI-based cost estimation without cloud API auth.

| Feature | Description | Implementation |
|---------|-------------|----------------|
| Terraform cost diff | Estimate cost impact of Terraform changes | Run `infracost diff --path .` via Bash |
| Cost breakdown | Show per-resource cost breakdown | Run `infracost breakdown --path .` via Bash |
| PR cost annotation | Include cost delta in pipeline reports | Parse Infracost JSON output |
| Right-sizing hints | Flag resources with known expensive patterns (e.g., oversized instance types) | Read Terraform files + pattern matching |

**Implementation:**
- New skill: `cost-analyzer` under `skills/`
- New pipeline: `*cost` for Horus
- Integrate Infracost into `*full` pipeline diff preview
- Requires: `infracost` CLI pre-installed (graceful degradation if missing)

**Example flow:**
```
User: "How much will this Terraform change cost?"
→ Horus runs: infracost diff --path . --format json
→ Parses JSON output
→ Shows monthly cost delta: +$45.30/month
→ Highlights: new n2-standard-4 instance, increased replica count
```

---

## Phase 2 — High Priority (P1)

### 3. GCP Enhanced Features (Extend Existing)

**Why:** The plugin already has GKE support; deepening it adds immediate value with minimal effort.

| Feature | Description | Implementation |
|---------|-------------|----------------|
| GKE Autopilot audit | Validate Autopilot-specific constraints in Terraform | Extend `GKE_HARDENING.md` checklist |
| Binary Authorization | Validate attestation policy YAML | Read + pattern matching |
| GKE Gateway API | Validate Gateway API resource manifests | Extend Zeus validate pipeline |
| Config Connector | Validate KCC resources in GitOps repo | YAML structure validation |

**Implementation:**
- Extend existing `GKE_HARDENING.md` with Autopilot, Gateway API, Binary Auth sections
- Add Config Connector CRD validation to Zeus's validate pipeline

---

### 4. Azure AKS Static Analysis

**Why:** Azure is the second-largest cloud provider; AKS Terraform/YAML patterns can be analyzed locally.

| Feature | Description | Implementation |
|---------|-------------|----------------|
| AKS Terraform audit | Validate `azurerm_kubernetes_cluster` resources | Read HCL + pattern matching |
| Workload Identity analysis | Audit federated credential annotations in ServiceAccount YAML | Read YAML + cross-reference |
| Azure Policy manifests | Validate Azure Policy assignment YAML | YAML structure validation |
| AGIC validation | Validate Application Gateway Ingress annotations | Read Kubernetes manifest annotations |

**Implementation:**
- New skill: `aks-security` under `skills/`
- Extend `cicd-enhancer` for Azure Pipelines-specific patterns

---

### 5. SLSA & Supply Chain Security

**Why:** Supply chain attacks are increasing; most checks can run locally via CLI tools.

| Feature | Description | Implementation |
|---------|-------------|----------------|
| SLSA level assessment | Evaluate CI/CD pipeline against SLSA requirements | Analyze CI config files + checklist |
| Provenance validation | Validate in-toto/SLSA provenance JSON format | Read + JSON schema validation |
| SBOM analysis | Parse and analyze CycloneDX/SPDX SBOMs | Read SBOM files + pattern matching |
| Sigstore verification | Verify image signatures via `cosign` CLI | Run `cosign verify` via Bash |
| Dependency audit | Scan dependencies for known CVEs | Run `trivy fs .` via Bash |

**Implementation:**
- Extend Zeus's `security-scan` with SLSA assessment steps
- Add provenance checks to the CI/CD pipeline auditor
- Requires: `cosign`, `trivy` CLI pre-installed (graceful degradation if missing)

---

## Phase 3 — Medium Priority (P2)

### 6. OPA / Gatekeeper / Kyverno Policy Management

**Why:** Policy-as-code is essential for governance at scale. `conftest` is already integrated.

| Feature | Description | Implementation |
|---------|-------------|----------------|
| Policy coverage analysis | Map policies to resources, find gaps | Read policy YAML + resource YAML cross-reference |
| Policy conflict detection | Detect overlapping/conflicting rules | Static analysis of policy files |
| Policy dry-run | Test policies against manifests via `conftest` | Run `conftest test` via Bash |
| Policy migration | Generate equivalent Kyverno policies from OPA Rego (or vice versa) | Read + code generation |
| Compliance dashboard | Aggregate policy evaluation results | Parse conftest/kyverno output |

**Implementation:**
- New skill: `policy-manager` for policy validation and analysis
- Extend conftest integration in Zeus's security pipeline
- Add Kyverno ClusterPolicy CRD validation

---

### 7. OpenTelemetry & Observability

**Why:** Observability configs are YAML/JSON files — ideal for static validation and scaffolding.

| Feature | Description | Implementation |
|---------|-------------|----------------|
| OTel Collector config validation | Validate OpenTelemetry Collector YAML | Read + schema validation |
| Instrumentation coverage | Check which deployments have OTel sidecar/annotations | Read manifest YAML + pattern scan |
| Dashboard scaffolding | Generate Grafana dashboard JSON from service manifests | Read manifests + template generation |
| Alert rules validation | Validate PrometheusRule / AlertManager YAML | Read + schema validation |
| SLO definition | Generate SLO specs from service metadata | Template generation |

**Implementation:**
- New skill: `observability-validator`
- Add OTel Collector config validation to Zeus
- Extend scaffolding to generate ServiceMonitor/PodMonitor resources

---

### 8. Crossplane Integration

**Why:** Crossplane resources are Kubernetes CRDs — pure YAML validation.

| Feature | Description | Implementation |
|---------|-------------|----------------|
| XRD validation | Validate Composite Resource Definitions | Read YAML + schema check |
| Composition audit | Check compositions for best practices | Static analysis |
| Provider config check | Validate provider config structure | Read YAML |
| Claim validation | Validate claims match XRD schemas | Cross-reference XRD + Claim YAML |
| Crossplane + ArgoCD | Validate GitOps flow for Crossplane resources | Extend Zeus validation |

**Implementation:**
- Extend Zeus to detect Crossplane resources (XRD, Composition, Claim CRDs)
- Add Crossplane-specific validation rules to the validate pipeline

---

## Phase 4 — Standard Priority (P3)

### 9. Service Mesh Validation (Istio / Cilium / Linkerd)

**Why:** Service mesh configs are Kubernetes CRDs — pure YAML validation.

| Feature | Description | Implementation |
|---------|-------------|----------------|
| Istio config validation | Validate VirtualService, DestinationRule, Gateway | Read YAML + CRD schema validation |
| mTLS audit | Check PeerAuthentication/DestinationRule for mTLS settings | Static YAML analysis |
| Traffic policy review | Review traffic shifting and circuit breaker configs | Read + pattern matching |
| Cilium Network Policy | Validate CiliumNetworkPolicy resources | Read YAML + schema validation |

**Implementation:**
- Extend Zeus's validate pipeline with Istio/Cilium CRD validation
- Add mesh-specific checks to security scanning

---

### 10. Backstage / Internal Developer Platform (IDP)

**Why:** Backstage catalog entries are YAML — pure file validation and scaffolding.

| Feature | Description | Implementation |
|---------|-------------|----------------|
| catalog-info.yaml validation | Validate Backstage entity definitions | Read + schema validation |
| Template scaffolding | Generate Backstage software templates | Template generation |
| TechDocs generation | Auto-generate TechDocs from repo structure | Read repo + Markdown generation |
| Dependency mapping | Map service dependencies from catalog entries | Read YAML + graph generation |

**Implementation:**
- New skill: `backstage-validator` for catalog-info.yaml validation
- Extend Zeus's `add-service` to generate Backstage-compatible catalog entries

---

### 11. Disaster Recovery Validation

**Why:** Velero backup specs are Kubernetes YAML — pure file validation.

| Feature | Description | Implementation |
|---------|-------------|----------------|
| Velero config validation | Validate Velero Schedule/Backup YAML | Read + schema validation |
| DR readiness assessment | Audit backup schedules, retention, and coverage | Static analysis of Velero resources |
| Backup coverage | Cross-reference namespaces with Velero schedules | Read YAML + cross-reference |

**Implementation:**
- New skill: `dr-validator` for Velero/backup configuration validation
- Add DR checks to `*health-check` pipeline

---

### 12. Falco Runtime Security (Rule Validation Only)

**Why:** Falco rules are YAML files — syntax and coverage can be validated statically.

| Feature | Description | Implementation |
|---------|-------------|----------------|
| Falco rules validation | Validate Falco rules YAML syntax | Read + schema validation |
| Rule generation | Generate Falco rules from deployment manifests | Read manifests + template generation |
| Alert rule review | Audit Falco alerting output configs | Static YAML analysis |

> **Note:** Runtime monitoring requires the Falco kernel module running in-cluster. This skill covers **static rule validation only**.

**Implementation:**
- New skill: `runtime-security` for Falco/Tetragon rule validation
- Add rule validation checks to the `*security` pipeline

---

## Phase 5 — Lower Priority (P4)

### 13. GitOps Multi-Tenancy

**Why:** Multi-tenant configs are Kubernetes YAML — namespace isolation and RBAC can be audited statically.

| Feature | Description | Implementation |
|---------|-------------|----------------|
| Tenant isolation audit | Verify namespace isolation, RBAC, and NetworkPolicy | Read YAML + cross-reference |
| Resource quota validation | Validate ResourceQuota/LimitRange per namespace | Read + completeness check |
| ArgoCD AppProject audit | Validate project boundaries and source restrictions | Read ArgoCD YAML |

**Implementation:**
- Extend Zeus with multi-tenancy audit in `*security` and `*health-check` pipelines

---

## Implementation Priority Matrix

| Priority | Phase | Integration | Impact | Effort | Approach |
|----------|-------|------------|--------|--------|----------|
| P0 | 1 | AWS EKS static analysis | Very High | Medium | New skill + extend `terraform-security` |
| P0 | 1 | Cost estimation (Infracost CLI) | Very High | Low | New skill, `infracost` CLI |
| P1 | 2 | GCP enhanced features | High | Low | Extend existing GKE docs |
| P1 | 2 | Azure AKS static analysis | High | Medium | New skill + extend existing |
| P1 | 2 | SLSA & supply chain | High | Medium | Extend security pipeline, `cosign`/`trivy` CLI |
| P2 | 3 | OPA/Kyverno policy management | Medium | Medium | New skill, extend `conftest` |
| P2 | 3 | OpenTelemetry & observability | Medium | Medium | New skill (YAML validation) |
| P2 | 3 | Crossplane integration | Medium | Low | Extend Zeus validation |
| P3 | 4 | Service mesh validation | Medium | Medium | Extend Zeus validation |
| P3 | 4 | Backstage/IDP integration | Medium | Medium | New skill |
| P3 | 4 | DR & backup validation | Medium | Low | New skill |
| P3 | 4 | Falco rule validation | Medium | Low | New skill (static only) |
| P4 | 5 | GitOps multi-tenancy | Medium | Medium | Extend Zeus |

---

## Suggested New Agents

In addition to Horus (IaC) and Zeus (GitOps), these agents are implementable with the current architecture:

| Agent | Domain | Key Capabilities | Implementation Approach |
|-------|--------|-----------------|------------------------|
| **Athena** | Security & Compliance | CIS benchmark checklists, OPA/Kyverno policy analysis, SLSA assessment, cross-provider Terraform audit | File analysis + `conftest`/`cosign`/`trivy` CLI |
| **Hermes** | Cost & Efficiency | Infracost integration, resource right-sizing analysis (Terraform/YAML), over-provisioning detection | `infracost` CLI + Terraform/manifest analysis |
| **Apollo** | Observability & Reliability | OTel Collector config validation, Prometheus rule validation, Grafana dashboard scaffolding, SLO definition | YAML validation + template generation |

---

## Example: What a Full Integration Looks Like

```
User: "Run a full EKS health check on our Terraform"

→ Athena activates
→ Step 1: Read all aws_eks_* Terraform resources
→ Step 2: CIS EKS Benchmark checklist (static)
→ Step 3: IRSA binding cross-reference (Terraform ↔ K8s ServiceAccount YAML)
→ Step 4: EKS add-on version check (known version list)
→ Step 5: Infracost cost estimation (CLI)
→ Step 6: Network policy coverage (manifest analysis)
→ Step 7: Consolidated health report

┌────────────────────────────────────────────┐
│         EKS Health Report                  │
├──────────────┬─────────────────────────────┤
│ Security     │ 3 HIGH, 7 MEDIUM findings   │
│ IRSA         │ 2 over-permissive roles     │
│ Add-ons      │ CoreDNS outdated (1.10→1.11)│
│ Cost         │ +$45/mo from last change    │
│ Networking   │ 2 namespaces without NetPol │
└──────────────┴─────────────────────────────┘
```

---

## Items Removed from Previous Version

The following were removed because they require cloud provider API authentication or live cluster access, which is outside the current plugin architecture:

| Removed Item | Reason |
|-------------|--------|
| ECR/ACR/Artifact Registry **image scanning** | Requires authenticated API calls to container registries |
| AWS Cost Explorer / Azure Cost Management | Requires cloud provider API credentials |
| Kubecost/OpenCost live analysis | Requires Kubernetes cluster API access |
| Multi-cloud management (cross-cloud comparison) | Requires simultaneous authenticated API access to 3+ providers |
| Velero restore validation | Requires cluster state mutation |
| Cloud Armor WAF rule audit | Requires GCP API access |
| Cost anomaly detection / budget alerts | Requires cloud billing API access |

> **Future path:** These features become feasible if MCP (Model Context Protocol) servers are added for cloud provider integration, or if authenticated CLI tools (e.g., `aws`, `az`, `gcloud`) are explicitly included in the execution scope.

---

---

<a id="繁體中文"></a>

## 繁體中文

本 Roadmap 列出 DevOps 外掛**經驗證可實現**的整合方案，已根據目前外掛架構（檔案分析 + 本機 CLI 工具執行）進行校對。

> **範圍限制：** 外掛透過檔案讀取/分析和本機 CLI 工具執行運作。需要雲端供應商 SDK 認證（AWS API、Azure API、GCP API）或即時叢集狀態查詢的功能**不在範圍內**，除非有本機 CLI 工具（如 `infracost`、`trivy`、`cosign`）可作為橋接。

---

## 現狀

外掛目前支援：
- **雲端：** GCP（GKE、workload identity、IAM），附帶基本的 AWS/Azure 參考
- **IaC：** Terraform + Helm
- **GitOps：** Kustomize + ArgoCD
- **CI/CD：** GitLab CI、GitHub Actions、Jenkins、CircleCI、Azure Pipelines、Bitbucket
- **安全：** 15+ 掃描工具，支援優雅降級

---

## 第一階段 — 高優先（P0）

### 1. AWS EKS 靜態分析

**原因：** AWS 是最大的雲端供應商；許多團隊透過 Terraform/Helm 管理 EKS。

**方法：** 分析 Terraform 檔案、Helm values 和 Kubernetes manifest 中的 AWS 特定模式，不需要 AWS API 呼叫。

| 功能 | 說明 | 實作方式 |
|------|------|---------|
| EKS Terraform 稽核 | 驗證 `aws_eks_cluster`、`aws_eks_node_group` 最佳實踐 | 讀取 HCL + 模式比對 |
| IRSA 綁定分析 | 稽核 ServiceAccount YAML 的 IAM role 註解 | 讀取 YAML/HCL + 交叉比對 |
| ALB Controller 驗證 | 驗證 ALB/NLB Ingress 註解 | 讀取 Kubernetes manifest 註解 |
| eksctl 設定驗證 | 驗證 eksctl ClusterConfig YAML 結構 | 讀取 + schema 驗證 |
| EKS Add-ons 版本檢查 | 比對 Terraform 中的 add-on 版本與已知最新版本 | 讀取 HCL + 版本清單 |
| AWS 安全強化檢查表 | CIS EKS Benchmark 的 Terraform/manifest 層級檢查 | 擴展 `terraform-security` skill |

**實作：**
- 新增 skill：`eks-security`
- 擴展 `terraform-security` SKILL.md 加入 AWS 專用強化檢查表
- 在 `cicd-enhancer` 加入 AWS CodePipeline/CodeBuild 模式

---

### 2. 成本估算（Infracost CLI）

**原因：** FinOps 是首要優先事項；Infracost 提供不需雲端 API 認證的本機 CLI 成本估算。

| 功能 | 說明 | 實作方式 |
|------|------|---------|
| Terraform 成本差異 | 估算 Terraform 變更的成本影響 | 執行 `infracost diff` |
| 成本細分 | 顯示每個資源的成本細分 | 執行 `infracost breakdown` |
| PR 成本標註 | 在流水線報告中加入成本差異 | 解析 Infracost JSON 輸出 |
| 資源調整提示 | 標記已知的高成本模式 | 讀取 Terraform + 模式比對 |

**範例流程：**
```
使用者：「我這次的 Terraform 修改會花多少錢？」
→ Horus 執行：infracost diff --path . --format json
→ 解析 JSON 輸出
→ 顯示每月成本差異：+$45.30/月
→ 標示：新增 n2-standard-4 實例、增加 replica 數量
```

---

## 第二階段 — 高優先（P1）

### 3. GCP 增強功能（擴展現有）

**原因：** 外掛已有 GKE 支援；深化可立即產生價值。

| 功能 | 說明 | 實作方式 |
|------|------|---------|
| GKE Autopilot 稽核 | 驗證 Terraform 中的 Autopilot 特定限制 | 擴展 `GKE_HARDENING.md` |
| Binary Authorization | 驗證認證政策 YAML | 讀取 + 模式比對 |
| GKE Gateway API | 驗證 Gateway API 資源 manifest | 擴展 Zeus 驗證流水線 |
| Config Connector | 驗證 GitOps repo 中的 KCC 資源 | YAML 結構驗證 |

---

### 4. Azure AKS 靜態分析

**原因：** Azure 是第二大雲端供應商；AKS 的 Terraform/YAML 模式可在本機分析。

| 功能 | 說明 | 實作方式 |
|------|------|---------|
| AKS Terraform 稽核 | 驗證 `azurerm_kubernetes_cluster` 資源 | 讀取 HCL + 模式比對 |
| Workload Identity 分析 | 稽核 ServiceAccount YAML 中的聯合憑證註解 | 讀取 YAML + 交叉比對 |
| Azure Policy manifest | 驗證 Azure Policy 指派 YAML | YAML 結構驗證 |
| AGIC 驗證 | 驗證 Application Gateway Ingress 註解 | 讀取 manifest 註解 |

---

### 5. SLSA 與供應鏈安全

**原因：** 供應鏈攻擊增加；大部分檢查可透過本機 CLI 工具執行。

| 功能 | 說明 | 實作方式 |
|------|------|---------|
| SLSA 等級評估 | 評估 CI/CD 流水線的 SLSA 要求 | 分析 CI 設定檔 + 檢查表 |
| 來源驗證 | 驗證 in-toto/SLSA provenance JSON 格式 | 讀取 + JSON schema 驗證 |
| SBOM 分析 | 解析和分析 CycloneDX/SPDX SBOM | 讀取 SBOM + 模式比對 |
| Sigstore 驗證 | 透過 `cosign` CLI 驗證映像簽章 | 執行 `cosign verify` |
| 相依性稽核 | 掃描已知 CVE | 執行 `trivy fs .` |

---

## 第三階段 — 中優先（P2）

### 6. OPA / Gatekeeper / Kyverno 政策管理

| 功能 | 說明 | 實作方式 |
|------|------|---------|
| 政策覆蓋率分析 | 比對政策與資源，找出缺口 | 讀取政策 YAML + 交叉比對 |
| 政策衝突偵測 | 偵測重疊/衝突規則 | 靜態分析政策檔案 |
| 政策模擬執行 | 透過 `conftest` 測試政策 | 執行 `conftest test` |
| 政策遷移 | 從 Gatekeeper 生成等效 Kyverno 政策 | 讀取 + 程式碼生成 |
| 合規儀表板 | 彙總政策評估結果 | 解析 conftest/kyverno 輸出 |

---

### 7. OpenTelemetry 與可觀測性

| 功能 | 說明 | 實作方式 |
|------|------|---------|
| OTel Collector 驗證 | 驗證 OpenTelemetry Collector YAML | 讀取 + schema 驗證 |
| 儀表板鷹架 | 從 manifest 產生 Grafana 儀表板 JSON | 讀取 manifest + 模板生成 |
| 告警規則驗證 | 驗證 PrometheusRule / AlertManager YAML | 讀取 + schema 驗證 |
| SLO 定義 | 從服務 metadata 生成 SLO 規格 | 模板生成 |

---

### 8. Crossplane 整合

| 功能 | 說明 | 實作方式 |
|------|------|---------|
| XRD 驗證 | 驗證 Composite Resource Definitions | 讀取 YAML + schema 檢查 |
| Composition 稽核 | 檢查 composition 最佳實踐 | 靜態分析 |
| Claim 驗證 | 驗證 claim 是否符合 XRD schema | 交叉比對 XRD + Claim YAML |

---

## 第四階段 — 標準優先（P3）

### 9. 服務網格驗證（Istio / Cilium / Linkerd）

| 功能 | 說明 | 實作方式 |
|------|------|---------|
| Istio 設定驗證 | 驗證 VirtualService、DestinationRule、Gateway | 讀取 YAML + CRD schema 驗證 |
| mTLS 稽核 | 檢查 PeerAuthentication/DestinationRule 的 mTLS 設定 | 靜態 YAML 分析 |
| Cilium Network Policy | 驗證 CiliumNetworkPolicy 資源 | 讀取 YAML + schema 驗證 |

---

### 10. Backstage / 內部開發者平台（IDP）

| 功能 | 說明 | 實作方式 |
|------|------|---------|
| catalog-info.yaml 驗證 | 驗證 Backstage 實體定義 | 讀取 + schema 驗證 |
| 模板鷹架 | 產生 Backstage 軟體模板 | 模板生成 |
| TechDocs 產生 | 從 repo 結構自動產生文件 | 讀取 repo + Markdown 生成 |

---

### 11. 災難復原驗證

| 功能 | 說明 | 實作方式 |
|------|------|---------|
| Velero 設定驗證 | 驗證 Velero Schedule/Backup YAML | 讀取 + schema 驗證 |
| DR 就緒評估 | 稽核備份排程、保留和覆蓋率 | 靜態分析 Velero 資源 |
| 備份覆蓋率 | 交叉比對 namespace 與 Velero schedule | 讀取 YAML + 交叉比對 |

---

### 12. Falco 規則驗證（僅靜態）

| 功能 | 說明 | 實作方式 |
|------|------|---------|
| Falco 規則驗證 | 驗證 Falco 規則 YAML 語法 | 讀取 + schema 驗證 |
| 規則生成 | 從 deployment manifest 生成 Falco 規則 | 讀取 manifest + 模板生成 |

> **注意：** 執行時監控需要 Falco kernel module 在叢集中執行。此 skill 僅涵蓋**靜態規則驗證**。

---

## 第五階段 — 較低優先（P4）

### 13. GitOps 多租戶

| 功能 | 說明 | 實作方式 |
|------|------|---------|
| 租戶隔離稽核 | 驗證 namespace 隔離、RBAC、NetworkPolicy | 讀取 YAML + 交叉比對 |
| 資源配額驗證 | 驗證各 namespace 的 ResourceQuota/LimitRange | 讀取 + 完整性檢查 |
| ArgoCD AppProject 稽核 | 驗證 project 邊界和來源限制 | 讀取 ArgoCD YAML |

---

## 實作優先順序矩陣

| 優先級 | 階段 | 整合項目 | 影響 | 工作量 | 實作方式 |
|--------|------|---------|------|--------|---------|
| P0 | 1 | AWS EKS 靜態分析 | 非常高 | 中 | 新 skill + 擴展 `terraform-security` |
| P0 | 1 | 成本估算（Infracost CLI） | 非常高 | 低 | 新 skill、`infracost` CLI |
| P1 | 2 | GCP 增強功能 | 高 | 低 | 擴展現有 GKE 文件 |
| P1 | 2 | Azure AKS 靜態分析 | 高 | 中 | 新 skill + 擴展現有 |
| P1 | 2 | SLSA 與供應鏈 | 高 | 中 | 擴展安全流水線、`cosign`/`trivy` CLI |
| P2 | 3 | OPA/Kyverno 政策管理 | 中 | 中 | 新 skill、擴展 `conftest` |
| P2 | 3 | OpenTelemetry 可觀測性 | 中 | 中 | 新 skill（YAML 驗證） |
| P2 | 3 | Crossplane 整合 | 中 | 低 | 擴展 Zeus 驗證 |
| P3 | 4 | 服務網格驗證 | 中 | 中 | 擴展 Zeus 驗證 |
| P3 | 4 | Backstage/IDP 整合 | 中 | 中 | 新 skill |
| P3 | 4 | DR 與備份驗證 | 中 | 低 | 新 skill |
| P3 | 4 | Falco 規則驗證 | 中 | 低 | 新 skill（僅靜態） |
| P4 | 5 | GitOps 多租戶 | 中 | 中 | 擴展 Zeus |

---

## 建議新增代理

除了 Horus（IaC）和 Zeus（GitOps）之外，以下代理在目前架構下可實現：

| 代理 | 領域 | 核心能力 | 實作方式 |
|------|------|---------|---------|
| **Athena** | 安全與合規 | CIS 基準檢查表、OPA/Kyverno 政策分析、SLSA 評估、跨供應商 Terraform 稽核 | 檔案分析 + `conftest`/`cosign`/`trivy` CLI |
| **Hermes** | 成本與效率 | Infracost 整合、資源調整分析（Terraform/YAML）、過度配置偵測 | `infracost` CLI + Terraform/manifest 分析 |
| **Apollo** | 可觀測性與可靠性 | OTel Collector 設定驗證、Prometheus 規則驗證、Grafana 儀表板鷹架、SLO 定義 | YAML 驗證 + 模板生成 |

---

## 範例：完整整合流程

```
使用者：「對我們的 Terraform 做一次完整的 EKS 健康檢查」

→ Athena 啟動
→ 步驟 1：讀取所有 aws_eks_* Terraform 資源
→ 步驟 2：CIS EKS Benchmark 檢查表（靜態）
→ 步驟 3：IRSA 綁定交叉比對（Terraform ↔ K8s ServiceAccount YAML）
→ 步驟 4：EKS add-on 版本檢查（已知版本清單）
→ 步驟 5：Infracost 成本估算（CLI）
→ 步驟 6：NetworkPolicy 覆蓋率（manifest 分析）
→ 步驟 7：彙總健康報告

┌────────────────────────────────────────────┐
│         EKS 健康報告                        │
├──────────────┬─────────────────────────────┤
│ 安全性       │ 3 HIGH、7 MEDIUM 發現        │
│ IRSA         │ 2 個過度授權角色             │
│ Add-ons      │ CoreDNS 過時 (1.10→1.11)    │
│ 成本         │ 上次變更 +$45/月             │
│ 網路         │ 2 個 namespace 缺少 NetPol   │
└──────────────┴─────────────────────────────┘
```

---

## 從前版移除的項目

以下項目因需要雲端供應商 API 認證或即時叢集存取，不在目前外掛架構範圍內：

| 移除項目 | 原因 |
|---------|------|
| ECR/ACR/Artifact Registry **映像掃描** | 需要容器 registry 的認證 API 呼叫 |
| AWS Cost Explorer / Azure Cost Management | 需要雲端供應商 API 憑證 |
| Kubecost/OpenCost 即時分析 | 需要 Kubernetes 叢集 API 存取 |
| 多雲管理（跨雲比較） | 需要同時認證存取 3+ 供應商 API |
| Velero 還原驗證 | 需要叢集狀態變更 |
| Cloud Armor WAF 規則稽核 | 需要 GCP API 存取 |
| 成本異常偵測 / 預算警報 | 需要雲端帳務 API 存取 |

> **未來路徑：** 如果加入 MCP（Model Context Protocol）server 進行雲端供應商整合，或明確將認證 CLI 工具（如 `aws`、`az`、`gcloud`）納入執行範圍，這些功能將變得可行。
