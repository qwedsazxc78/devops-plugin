# DevOps Plugin — Cloud Integrations & Future Roadmap

[English](#english) | [繁體中文](#繁體中文)

---

<a id="english"></a>

## English

This document outlines recommended integrations and enhancements for the DevOps plugin, based on research into current cloud-native ecosystem trends and DevOps best practices.

---

## Current State

The plugin currently supports:
- **Cloud:** GCP (GKE, workload identity, IAM) with basic AWS/Azure references
- **IaC:** Terraform + Helm
- **GitOps:** Kustomize + ArgoCD
- **CI/CD:** GitLab CI, GitHub Actions, Jenkins, CircleCI, Azure Pipelines, Bitbucket
- **Security:** 15+ scanning tools with graceful degradation

---

## Tier 1 — High-Impact Cloud Provider Integrations

### 1. AWS EKS Deep Integration

**Why:** AWS is the largest cloud provider; EKS is the most widely deployed managed Kubernetes.

**Suggested capabilities for a new `Athena` agent or Horus extension:**

| Feature | Description | Natural Language Trigger |
|---------|-------------|------------------------|
| EKS cluster audit | Validate EKS config against AWS best practices | "Check our EKS cluster security" |
| IAM Roles for Service Accounts (IRSA) | Audit IRSA bindings, detect over-permissive roles | "Are our IRSA bindings least privilege?" |
| ECR image scanning | Integrate with Amazon ECR vulnerability scanning | "Scan our ECR images for CVEs" |
| AWS Load Balancer Controller | Validate ALB/NLB ingress annotations | "Check our ALB ingress configuration" |
| EKS Add-ons management | Detect outdated EKS add-ons (CoreDNS, kube-proxy, VPC CNI) | "Are our EKS add-ons up to date?" |
| eksctl config validation | Validate eksctl cluster config files | "Validate my eksctl config" |
| AWS Cost Explorer integration | Query cost data for K8s workloads via tags | "How much is our dev cluster costing?" |

**Implementation approach:**
- New skill: `eks-security` under `skills/`
- Extend `terraform-security` SKILL.md with AWS-specific hardening checklist
- Add AWS-specific patterns to `cicd-enhancer` for CodePipeline/CodeBuild

---

### 2. GCP Enhanced Features (Extend Existing)

**Why:** The plugin already has GKE support; deepening it adds immediate value.

| Feature | Description | Natural Language Trigger |
|---------|-------------|------------------------|
| GKE Autopilot audit | Validate Autopilot-specific constraints | "Check our GKE Autopilot config" |
| Cloud Armor WAF rules | Audit WAF rules and backend policies | "Review our Cloud Armor rules" |
| Binary Authorization | Validate attestation policies | "Check our Binary Authorization setup" |
| GKE Gateway API | Validate Gateway API resources | "Validate our GKE Gateway config" |
| Config Connector | Validate KCC resources in GitOps repo | "Check our Config Connector resources" |
| Artifact Registry | Scan AR images, check retention policies | "Scan our Artifact Registry for vulnerabilities" |

**Implementation approach:**
- Extend existing `GKE_HARDENING.md` with Autopilot, Gateway API, Binary Auth sections
- Add Config Connector validation to Zeus's validate pipeline

---

### 3. Azure AKS Integration

**Why:** Azure is the second-largest cloud provider; AKS has strong enterprise adoption.

| Feature | Description | Natural Language Trigger |
|---------|-------------|------------------------|
| AKS cluster audit | Validate AKS config against Microsoft best practices | "Check our AKS security config" |
| Azure AD Workload Identity | Audit federated credentials | "Are our Azure workload identities secure?" |
| ACR image scanning | Integrate with Azure Defender for Containers | "Scan our ACR images" |
| Azure Policy for AKS | Validate Azure Policy assignments | "Check our Azure Policy compliance" |
| AKS cost analysis | Query Azure Cost Management for K8s workloads | "How much is our AKS cluster costing?" |
| AGIC validation | Validate Application Gateway Ingress config | "Check our AGIC ingress setup" |

**Implementation approach:**
- New skill: `aks-security` under `skills/`
- Extend `cicd-enhancer` for Azure Pipelines-specific patterns

---

## Tier 2 — Platform Engineering & Cost Optimization

### 4. Cost Optimization (Infracost / Kubecost / OpenCost)

**Why:** FinOps is a top priority for every organization running cloud infrastructure.

| Feature | Description | Natural Language Trigger |
|---------|-------------|------------------------|
| Infracost integration | Estimate cost impact of Terraform changes | "How much will this Terraform change cost?" |
| Kubecost analysis | Analyze namespace/workload cost breakdown | "Show me the cost breakdown by namespace" |
| Right-sizing recommendations | Detect over-provisioned resources | "Are any of our deployments over-provisioned?" |
| Cost anomaly detection | Compare current costs to historical baseline | "Are there any cost anomalies this month?" |
| Budget alerts | Check if workloads are within budget | "Are we within budget for the dev environment?" |

**Implementation approach:**
- New skill: `cost-analyzer` under `skills/`
- New pipeline: `*cost` for Horus
- Integrate Infracost into PR diff preview

**Example natural language flow:**
```
User: "我這次的 Terraform 修改會花多少錢？"
→ Horus runs infracost diff on the current branch
→ Shows monthly cost delta: +$45.30/month
→ Highlights: new n2-standard-4 instance, increased replica count
```

---

### 5. Crossplane Integration

**Why:** Crossplane is the fastest-growing cloud-native IaC tool, enabling Kubernetes-native infrastructure provisioning.

| Feature | Description | Natural Language Trigger |
|---------|-------------|------------------------|
| XRD validation | Validate Composite Resource Definitions | "Validate my Crossplane XRDs" |
| Composition audit | Check compositions for best practices | "Audit our Crossplane compositions" |
| Provider config check | Validate provider configs and credentials | "Check our Crossplane provider setup" |
| Claim validation | Validate claims against XRDs | "Are our Crossplane claims valid?" |
| Crossplane + ArgoCD | Validate GitOps flow for Crossplane resources | "Check our Crossplane GitOps setup" |

**Implementation approach:**
- Extend Zeus to detect Crossplane resources (XRD, Composition, Claim CRDs)
- Add Crossplane-specific validation rules to the validate pipeline

---

### 6. Backstage / Internal Developer Platform (IDP)

**Why:** Platform engineering is the dominant trend in DevOps; Backstage is the de facto standard for IDPs.

| Feature | Description | Natural Language Trigger |
|---------|-------------|------------------------|
| catalog-info.yaml validation | Validate Backstage entity definitions | "Validate our Backstage catalog entries" |
| Template scaffolding | Generate Backstage software templates | "Create a Backstage template for our service" |
| TechDocs generation | Auto-generate TechDocs from repo structure | "Generate TechDocs for this service" |
| Dependency mapping | Map service dependencies from catalog | "Show our service dependency graph" |

**Implementation approach:**
- New skill: `backstage-validator` for catalog-info.yaml validation
- Extend Zeus's `add-service` to generate Backstage-compatible catalog entries

---

## Tier 3 — Advanced Security & Compliance

### 7. SLSA & Supply Chain Security

**Why:** Supply chain attacks are increasing; SLSA framework adoption is accelerating.

| Feature | Description | Natural Language Trigger |
|---------|-------------|------------------------|
| SLSA level assessment | Check current SLSA compliance level | "What SLSA level are we at?" |
| Provenance validation | Validate build provenance attestations | "Check our build provenance" |
| SBOM generation & analysis | Generate and analyze SBOMs for all images | "Generate SBOMs for our deployments" |
| Sigstore verification | Verify image signatures via cosign/Sigstore | "Are all our images signed?" |
| Dependency audit | Check for known vulnerabilities in dependencies | "Audit our supply chain dependencies" |

**Implementation approach:**
- Extend Zeus's `security-scan` with SLSA assessment steps
- Add provenance checks to the CI/CD pipeline auditor

---

### 8. OPA / Gatekeeper / Kyverno Policy Management

**Why:** Policy-as-code is essential for governance at scale.

| Feature | Description | Natural Language Trigger |
|---------|-------------|------------------------|
| Policy coverage analysis | Check which resources have policy coverage | "What's our policy coverage?" |
| Policy conflict detection | Detect conflicting policies | "Are there any policy conflicts?" |
| Policy dry-run | Test policies against current manifests | "Dry-run our policies against staging" |
| Policy migration | Help migrate from Gatekeeper to Kyverno (or vice versa) | "Help me migrate from Gatekeeper to Kyverno" |
| Compliance dashboard | Show compliance status across all policies | "Show our compliance dashboard" |

**Implementation approach:**
- New skill: `policy-manager` for policy validation and analysis
- Integrate into Zeus's security pipeline

---

### 9. Runtime Security (Falco / Tetragon)

**Why:** Shift-left is important, but runtime security catches what static analysis misses.

| Feature | Description | Natural Language Trigger |
|---------|-------------|------------------------|
| Falco rules validation | Validate Falco rules syntax and coverage | "Validate our Falco rules" |
| Runtime policy generation | Generate Falco/Tetragon policies from manifests | "Generate runtime security policies for our services" |
| Alert rule review | Audit alerting rules for security events | "Review our runtime security alerts" |

**Implementation approach:**
- New skill: `runtime-security` for Falco/Tetragon rule validation
- Add runtime security checks to the `*security` pipeline

---

## Tier 4 — Observability & Service Mesh

### 10. OpenTelemetry & Observability

**Why:** Observability is critical for production reliability; OTel is the industry standard.

| Feature | Description | Natural Language Trigger |
|---------|-------------|------------------------|
| OTel Collector config validation | Validate OpenTelemetry Collector configs | "Validate our OTel Collector config" |
| Instrumentation coverage | Check which services have tracing/metrics | "Which services are missing observability?" |
| Dashboard scaffolding | Generate Grafana dashboard JSON from manifests | "Create a Grafana dashboard for payment-api" |
| Alert rules validation | Validate Prometheus/AlertManager rules | "Check our Prometheus alert rules" |
| SLO definition | Help define and validate SLOs | "Help me define SLOs for our payment service" |

**Implementation approach:**
- New skill: `observability-validator`
- Add OTel Collector config validation to Zeus
- Extend scaffolding commands to generate ServiceMonitor/PodMonitor resources

---

### 11. Service Mesh (Istio / Cilium / Linkerd)

**Why:** Service mesh adoption is growing; misconfiguration is a common source of outages.

| Feature | Description | Natural Language Trigger |
|---------|-------------|------------------------|
| Istio config validation | Validate VirtualService, DestinationRule, Gateway | "Validate our Istio configuration" |
| mTLS audit | Check mTLS coverage across the mesh | "Is mTLS enabled for all our services?" |
| Traffic policy review | Review traffic shifting and circuit breaker configs | "Review our traffic management policies" |
| Cilium Network Policy | Validate CiliumNetworkPolicy resources | "Check our Cilium network policies" |

**Implementation approach:**
- Extend Zeus's validate pipeline with Istio/Cilium CRD validation
- Add mesh-specific checks to security scanning

---

## Tier 5 — Multi-Cloud & Advanced Patterns

### 12. Multi-Cloud Management

**Why:** Most enterprises run workloads across multiple clouds.

| Feature | Description | Natural Language Trigger |
|---------|-------------|------------------------|
| Cross-cloud consistency | Compare configs across AWS/GCP/Azure clusters | "Compare our EKS and GKE configurations" |
| Unified cost view | Aggregate costs across cloud providers | "Show total K8s costs across all clouds" |
| Federation validation | Validate multi-cluster federation configs | "Check our multi-cluster federation setup" |
| DNS & traffic routing | Validate multi-cloud DNS and traffic policies | "Review our cross-cloud traffic routing" |

---

### 13. Disaster Recovery & Backup

**Why:** DR planning is often neglected until it's too late.

| Feature | Description | Natural Language Trigger |
|---------|-------------|------------------------|
| Velero config validation | Validate Velero backup configurations | "Check our Velero backup setup" |
| DR readiness assessment | Audit DR procedures and RTO/RPO compliance | "Are we ready for a disaster recovery scenario?" |
| Backup coverage | Check which resources are backed up | "Which namespaces are not being backed up?" |
| Restore validation | Validate restore procedures | "Test our backup restore procedure" |

---

### 14. GitOps Multi-Tenancy

**Why:** As organizations grow, multi-tenancy in GitOps repos becomes complex.

| Feature | Description | Natural Language Trigger |
|---------|-------------|------------------------|
| Tenant isolation audit | Verify namespace isolation and RBAC | "Check our multi-tenant isolation" |
| Resource quota validation | Validate quotas across tenants | "Are our resource quotas properly configured?" |
| Network policy coverage | Check inter-tenant network policies | "Can tenant A access tenant B's services?" |
| ArgoCD AppProject audit | Validate ArgoCD project boundaries | "Audit our ArgoCD project configurations" |

---

## Implementation Priority Matrix

| Priority | Integration | Impact | Effort | Dependencies |
|----------|------------|--------|--------|-------------|
| P0 | AWS EKS deep integration | Very High | Medium | New skill + extend existing |
| P0 | Cost optimization (Infracost) | Very High | Low | New skill, CLI tool |
| P1 | Azure AKS integration | High | Medium | New skill + extend existing |
| P1 | GCP enhanced features | High | Low | Extend existing docs |
| P1 | SLSA & supply chain | High | Medium | Extend security pipeline |
| P2 | OPA/Kyverno policy management | Medium | Medium | New skill |
| P2 | OpenTelemetry & observability | Medium | Medium | New skill |
| P2 | Crossplane integration | Medium | Low | Extend Zeus validation |
| P3 | Service mesh validation | Medium | Medium | Extend Zeus validation |
| P3 | Backstage/IDP integration | Medium | Medium | New skill |
| P3 | DR & backup validation | Medium | Low | New skill |
| P4 | Multi-cloud management | Low | High | Multiple new skills |
| P4 | Runtime security (Falco) | Low | Medium | New skill |
| P4 | GitOps multi-tenancy | Low | Medium | Extend Zeus |

---

## Suggested New Agents

In addition to Horus (IaC) and Zeus (GitOps), consider these future agents:

| Agent | Domain | Key Capabilities |
|-------|--------|-----------------|
| **Athena** | Cloud Security & Compliance | Cross-cloud security audits, CIS benchmarks, compliance reporting, policy management |
| **Hermes** | Cost & Performance | FinOps analysis, right-sizing, performance profiling, capacity planning |
| **Apollo** | Observability & Reliability | OTel config, SLO management, alert rules, incident analysis, dashboard generation |

---

## Example: What a Full Cloud Integration Looks Like

```
User: "幫我做一次完整的 AWS EKS 健康檢查"

→ Athena activates
→ Step 1: EKS cluster config audit (CIS benchmark)
→ Step 2: IRSA bindings review (least privilege check)
→ Step 3: EKS add-ons version check (CoreDNS, kube-proxy, VPC CNI)
→ Step 4: ECR image vulnerability scan
→ Step 5: Cost analysis (Kubecost/OpenCost)
→ Step 6: Network policy coverage
→ Step 7: Consolidated health dashboard

┌────────────────────────────────────────────┐
│         EKS Health Dashboard               │
├──────────────┬─────────────────────────────┤
│ Security     │ 3 HIGH, 7 MEDIUM findings   │
│ IRSA         │ 2 over-permissive roles     │
│ Add-ons      │ CoreDNS outdated (1.10→1.11)│
│ Images       │ 5 CVEs (2 Critical)         │
│ Cost         │ $2,450/mo (15% over budget) │
│ Networking   │ 2 namespaces without NetPol │
└──────────────┴─────────────────────────────┘
```

---

---

<a id="繁體中文"></a>

## 繁體中文

本文件概述 DevOps 外掛的建議整合方案與未來發展藍圖，基於當前雲端原生生態系統趨勢和 DevOps 最佳實踐的研究。

---

## 現狀

外掛目前支援：
- **雲端：** GCP（GKE、workload identity、IAM），附帶基本的 AWS/Azure 參考
- **IaC：** Terraform + Helm
- **GitOps：** Kustomize + ArgoCD
- **CI/CD：** GitLab CI、GitHub Actions、Jenkins、CircleCI、Azure Pipelines、Bitbucket
- **安全：** 15+ 掃描工具，支援優雅降級

---

## 第一層 — 高影響力雲端供應商整合

### 1. AWS EKS 深度整合

**原因：** AWS 是最大的雲端供應商；EKS 是部署最廣泛的受管 Kubernetes。

| 功能 | 說明 | 自然語言觸發 |
|------|------|-------------|
| EKS 叢集稽核 | 根據 AWS 最佳實踐驗證 EKS 設定 | 「檢查我們的 EKS 叢集安全性」 |
| IRSA 稽核 | 稽核 IRSA 綁定，偵測過度授權 | 「我們的 IRSA 是最小權限嗎？」 |
| ECR 映像掃描 | 整合 Amazon ECR 弱點掃描 | 「掃描 ECR 映像的 CVE」 |
| ALB Controller 驗證 | 驗證 ALB/NLB Ingress 註解 | 「檢查 ALB Ingress 設定」 |
| EKS Add-ons 管理 | 偵測過時的 EKS 附加元件 | 「EKS Add-ons 是最新的嗎？」 |
| 成本查詢 | 透過標籤查詢 K8s 工作負載成本 | 「我們的 dev 叢集花了多少錢？」 |

---

### 2. GCP 增強功能（擴展現有）

**原因：** 外掛已有 GKE 支援；深化可立即產生價值。

| 功能 | 說明 | 自然語言觸發 |
|------|------|-------------|
| GKE Autopilot 稽核 | 驗證 Autopilot 特定限制 | 「檢查 GKE Autopilot 設定」 |
| Cloud Armor WAF | 稽核 WAF 規則和後端政策 | 「檢視 Cloud Armor 規則」 |
| Binary Authorization | 驗證認證政策 | 「檢查 Binary Authorization 設定」 |
| GKE Gateway API | 驗證 Gateway API 資源 | 「驗證 GKE Gateway 設定」 |
| Config Connector | 驗證 GitOps repo 中的 KCC 資源 | 「檢查 Config Connector 資源」 |
| Artifact Registry | 掃描 AR 映像，檢查保留政策 | 「掃描 Artifact Registry 弱點」 |

---

### 3. Azure AKS 整合

**原因：** Azure 是第二大雲端供應商；AKS 在企業市場有強勁的採用率。

| 功能 | 說明 | 自然語言觸發 |
|------|------|-------------|
| AKS 叢集稽核 | 根據 Microsoft 最佳實踐驗證 | 「檢查 AKS 安全設定」 |
| Azure AD Workload Identity | 稽核聯合憑證 | 「Azure workload identity 安全嗎？」 |
| ACR 映像掃描 | 整合 Azure Defender for Containers | 「掃描 ACR 映像」 |
| Azure Policy | 驗證 AKS 的 Azure Policy | 「檢查 Azure Policy 合規性」 |
| AKS 成本分析 | 查詢 Azure Cost Management | 「AKS 叢集花了多少錢？」 |

---

## 第二層 — 平台工程與成本最佳化

### 4. 成本最佳化（Infracost / Kubecost / OpenCost）

**原因：** FinOps 是每個組織的首要優先事項。

| 功能 | 說明 | 自然語言觸發 |
|------|------|-------------|
| Infracost 整合 | 估算 Terraform 變更的成本影響 | 「這次 Terraform 修改會花多少錢？」 |
| Kubecost 分析 | 按命名空間/工作負載分析成本 | 「顯示各 namespace 的成本」 |
| 資源調整建議 | 偵測過度配置的資源 | 「有沒有 deployment 過度配置？」 |
| 成本異常偵測 | 與歷史基線比較 | 「這個月有成本異常嗎？」 |
| 預算警報 | 檢查工作負載是否在預算內 | 「dev 環境有超出預算嗎？」 |

**範例自然語言流程：**
```
使用者：「我這次的 Terraform 修改會花多少錢？」
→ Horus 對目前分支執行 infracost diff
→ 顯示每月成本差異：+$45.30/月
→ 標示：新增 n2-standard-4 實例、增加 replica 數量
```

---

### 5. Crossplane 整合

**原因：** Crossplane 是成長最快的雲端原生 IaC 工具。

| 功能 | 說明 | 自然語言觸發 |
|------|------|-------------|
| XRD 驗證 | 驗證 Composite Resource Definitions | 「驗證 Crossplane XRD」 |
| Composition 稽核 | 檢查 composition 最佳實踐 | 「稽核 Crossplane composition」 |
| Provider 設定檢查 | 驗證 provider 設定和憑證 | 「檢查 Crossplane provider 設定」 |

---

### 6. Backstage / 內部開發者平台（IDP）

**原因：** 平台工程是 DevOps 的主流趨勢；Backstage 是 IDP 的事實標準。

| 功能 | 說明 | 自然語言觸發 |
|------|------|-------------|
| catalog-info.yaml 驗證 | 驗證 Backstage 實體定義 | 「驗證 Backstage catalog」 |
| 模板鷹架 | 產生 Backstage 軟體模板 | 「建立 Backstage 服務模板」 |
| TechDocs 產生 | 從 repo 結構自動產生文件 | 「產生這個服務的 TechDocs」 |

---

## 第三層 — 進階安全與合規

### 7. SLSA 與供應鏈安全

| 功能 | 說明 | 自然語言觸發 |
|------|------|-------------|
| SLSA 等級評估 | 檢查目前的 SLSA 合規等級 | 「我們在 SLSA 幾級？」 |
| 來源驗證 | 驗證建置來源證明 | 「檢查建置來源」 |
| SBOM 產生與分析 | 產生並分析所有映像的 SBOM | 「產生部署的 SBOM」 |
| Sigstore 驗證 | 透過 cosign 驗證映像簽章 | 「所有映像都有簽章嗎？」 |

---

### 8. OPA / Gatekeeper / Kyverno 政策管理

| 功能 | 說明 | 自然語言觸發 |
|------|------|-------------|
| 政策覆蓋率分析 | 檢查哪些資源有政策覆蓋 | 「我們的政策覆蓋率如何？」 |
| 政策衝突偵測 | 偵測衝突的政策 | 「有政策衝突嗎？」 |
| 政策模擬執行 | 測試政策是否影響現有 manifest | 「對 staging 模擬執行政策」 |
| 合規儀表板 | 顯示所有政策的合規狀態 | 「顯示合規儀表板」 |

---

## 第四層 — 可觀測性與服務網格

### 9. OpenTelemetry 與可觀測性

| 功能 | 說明 | 自然語言觸發 |
|------|------|-------------|
| OTel Collector 驗證 | 驗證 OpenTelemetry Collector 設定 | 「驗證 OTel Collector 設定」 |
| 儀表板鷹架 | 從 manifest 產生 Grafana 儀表板 | 「建立 payment-api 的 Grafana 儀表板」 |
| 告警規則驗證 | 驗證 Prometheus/AlertManager 規則 | 「檢查 Prometheus 告警規則」 |
| SLO 定義 | 協助定義和驗證 SLO | 「幫我定義 payment 服務的 SLO」 |

---

### 10. 服務網格（Istio / Cilium / Linkerd）

| 功能 | 說明 | 自然語言觸發 |
|------|------|-------------|
| Istio 設定驗證 | 驗證 VirtualService、DestinationRule | 「驗證 Istio 設定」 |
| mTLS 稽核 | 檢查整個 mesh 的 mTLS 覆蓋率 | 「所有服務都有啟用 mTLS 嗎？」 |
| Cilium Network Policy | 驗證 CiliumNetworkPolicy 資源 | 「檢查 Cilium 網路政策」 |

---

## 第五層 — 多雲與進階模式

### 11. 災難復原與備份

| 功能 | 說明 | 自然語言觸發 |
|------|------|-------------|
| Velero 設定驗證 | 驗證 Velero 備份設定 | 「檢查 Velero 備份設定」 |
| DR 就緒評估 | 稽核 DR 程序和 RTO/RPO | 「我們準備好做災難復原了嗎？」 |
| 備份覆蓋率 | 檢查哪些資源有被備份 | 「哪些 namespace 沒有被備份？」 |

### 12. GitOps 多租戶

| 功能 | 說明 | 自然語言觸發 |
|------|------|-------------|
| 租戶隔離稽核 | 驗證 namespace 隔離和 RBAC | 「檢查多租戶隔離」 |
| 資源配額驗證 | 驗證各租戶的配額 | 「資源配額設定正確嗎？」 |
| ArgoCD AppProject 稽核 | 驗證 ArgoCD 專案邊界 | 「稽核 ArgoCD 專案設定」 |

---

## 實作優先順序矩陣

| 優先級 | 整合項目 | 影響 | 工作量 | 依賴 |
|--------|---------|------|--------|------|
| P0 | AWS EKS 深度整合 | 非常高 | 中 | 新 skill + 擴展現有 |
| P0 | 成本最佳化（Infracost） | 非常高 | 低 | 新 skill、CLI 工具 |
| P1 | Azure AKS 整合 | 高 | 中 | 新 skill + 擴展現有 |
| P1 | GCP 增強功能 | 高 | 低 | 擴展現有文件 |
| P1 | SLSA 與供應鏈 | 高 | 中 | 擴展安全流水線 |
| P2 | OPA/Kyverno 政策管理 | 中 | 中 | 新 skill |
| P2 | OpenTelemetry 可觀測性 | 中 | 中 | 新 skill |
| P2 | Crossplane 整合 | 中 | 低 | 擴展 Zeus 驗證 |
| P3 | 服務網格驗證 | 中 | 中 | 擴展 Zeus 驗證 |
| P3 | Backstage/IDP 整合 | 中 | 中 | 新 skill |
| P3 | DR 與備份驗證 | 中 | 低 | 新 skill |
| P4 | 多雲管理 | 低 | 高 | 多個新 skill |
| P4 | 執行時安全（Falco） | 低 | 中 | 新 skill |
| P4 | GitOps 多租戶 | 低 | 中 | 擴展 Zeus |

---

## 建議新增代理

除了 Horus（IaC）和 Zeus（GitOps）之外，考慮未來新增：

| 代理 | 領域 | 核心能力 |
|------|------|---------|
| **Athena** | 雲端安全與合規 | 跨雲安全稽核、CIS 基準、合規報告、政策管理 |
| **Hermes** | 成本與效能 | FinOps 分析、資源調整、效能剖析、容量規劃 |
| **Apollo** | 可觀測性與可靠性 | OTel 設定、SLO 管理、告警規則、事件分析、儀表板產生 |
