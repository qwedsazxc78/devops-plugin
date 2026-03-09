# DevOps Plugin — Use Cases & Natural Language Examples

[English](#english) | [繁體中文](#繁體中文)

---

<a id="english"></a>

## English

This document provides **real-world use case examples** showing how to drive the DevOps plugin using natural language. You don't need to memorize commands — just describe what you need, and the plugin's agents will activate the right pipelines automatically.

---

### Quick Reference: Natural Language → Pipeline Mapping

| What you say | Agent | Pipeline/Command triggered |
|---|---|---|
| "Scan all Helm chart versions" | Horus | `*upgrade` |
| "Is my Terraform code secure?" | Horus | `*security` |
| "Check if my YAML is valid" | Zeus | `*pre-merge` |
| "Help me add a new microservice" | Zeus | `*onboard` |
| "Show me the architecture diagram" | Zeus | `*diagram` |

---

### Horus (IaC) — Natural Language Use Cases

#### 1. Helm Version Management

**Scenario:** You want to check if any Helm charts in your Terraform project are outdated.

```
User: "幫我掃描所有 Helm package 的版本"
User: "Scan all Helm chart versions and tell me which ones are outdated"
User: "Check if there are newer versions of our Helm charts"
User: "我想升級 Grafana 的 Helm chart 到最新版"
User: "Upgrade the Redis Helm chart to the latest version"
```

**What happens:** Horus dynamically discovers all Helm modules in your Terraform files, queries ArtifactHub for the latest versions, and presents a comparison table. If you choose to upgrade, it performs an atomic 3-file update (orchestrator + module variables + docs).

---

#### 2. Terraform Validation & Consistency

**Scenario:** Before submitting a PR, you want to ensure all Terraform code is clean.

```
User: "Validate all my Terraform code"
User: "幫我檢查 Terraform 格式和語法有沒有問題"
User: "Run a full consistency check on all .tf files"
User: "Check if my Terraform naming conventions are correct"
User: "Are there any cross-file inconsistencies in my Terraform?"
User: "Make sure all my environment configs match the JSON schema"
```

**What happens:** Horus runs `terraform fmt`, `terraform validate`, JSON schema validation, cross-file consistency checks (Helm versions, module paths, environment configs, workload identity), and naming convention audits.

---

#### 3. Security Audit

**Scenario:** You're preparing for a security review and need a comprehensive audit.

```
User: "Run a security audit on our infrastructure"
User: "幫我做 GKE 安全性檢查"
User: "Check if there are any hardcoded secrets in our Terraform"
User: "Is our IAM configuration following least privilege?"
User: "Audit our Helm charts for security issues"
User: "Check our GKE cluster against CIS benchmarks"
```

**What happens:** Horus performs a multi-layer security scan: GKE hardening checklist (network, node, cluster, maintenance, IAM), Terraform code scanning (hardcoded secrets, permissive IAM, insecure defaults), and Helm chart security review (service account config, network policies, image security, secrets management, resource limits).

---

#### 4. CI/CD Pipeline Improvement

**Scenario:** You want to know if your CI/CD pipeline has gaps or can be optimized.

```
User: "Analyze our CI/CD pipeline and suggest improvements"
User: "幫我檢查 GitLab CI 的流水線有哪些可以改善的地方"
User: "Are we missing any important CI stages?"
User: "Generate CI job snippets for security scanning"
User: "Compare our pipeline against best practices"
User: "Help me add a Terraform validation stage to our pipeline"
```

**What happens:** Horus detects your CI system (GitLab CI, GitHub Actions, Jenkins, etc.), performs gap analysis against recommended stages, identifies missing quality gates, and generates ready-to-use CI job snippets.

---

#### 5. New Helm Module Scaffolding

**Scenario:** You need to add a new Helm chart dependency to your infrastructure.

```
User: "I need to add Prometheus to our infrastructure"
User: "幫我建立一個新的 Helm module 給 cert-manager"
User: "Scaffold a new Helm module for external-dns"
User: "Create a Helm module with workload identity support"
User: "Add a new OCI-based Helm chart for Istio"
```

**What happens:** Horus scaffolds the module using one of 5 patterns (simple, standard, workload-identity, OCI, multi-instance), then validates and runs a security check on the new code.

---

#### 6. Platform Health Check

**Scenario:** Monday morning — you want a quick overview of your infrastructure health.

```
User: "Show me the platform health dashboard"
User: "幫我看一下整個平台的健康狀態"
User: "Are there any outdated charts or security issues?"
User: "Give me a summary of our infrastructure status"
User: "Run a full health check on our IaC repo"
```

**What happens:** Horus checks Helm chart versions, runs security scans, validates all Terraform code, and produces a consolidated health dashboard with actionable items.

---

### Zeus (GitOps) — Natural Language Use Cases

#### 7. Pre-Merge Validation

**Scenario:** You've made changes and want to make sure everything is valid before merging.

```
User: "Check if my changes are ready to merge"
User: "幫我做合併前的檢查"
User: "Run all validation checks on my branch"
User: "Validate my Kustomize overlays for all environments"
User: "Is this MR safe to merge?"
User: "Run the pre-merge pipeline"
```

**What happens:** Zeus runs YAML lint, kustomize build, schema validation, security scan, and diff preview with risk assessment. It produces a verdict: READY TO MERGE or NEEDS ATTENTION.

---

#### 8. Security Scanning

**Scenario:** You want a comprehensive security scan of your Kubernetes manifests.

```
User: "Scan my manifests for security issues"
User: "幫我掃描有沒有安全性漏洞"
User: "Are there any hardcoded secrets in my YAML files?"
User: "Check for CVEs in our container images"
User: "Run a supply chain security analysis"
User: "Check if our pods are running as root"
```

**What happens:** Zeus orchestrates 10+ security tools: checkov, trivy, kube-score, polaris, kube-linter, kyverno, gitleaks, plus supply chain analysis (SBOM, CVE scanning, image signature verification). Tools that aren't installed are gracefully skipped.

---

#### 9. Service Onboarding

**Scenario:** A new team needs to deploy a microservice to your Kubernetes cluster.

```
User: "Help me onboard a new service called payment-api"
User: "幫我建立一個新的微服務 user-service"
User: "I need to deploy a new service with an ingress"
User: "Scaffold a new service with HPA and monitoring"
User: "Add a new service to our GitOps repo with ArgoCD"
```

**What happens:** Zeus runs an interactive onboarding flow: discovers repo structure, scaffolds Deployment/Service/Ingress/HPA/ServiceMonitor, creates ArgoCD Application manifest, validates everything, generates architecture diagram, and sets up pre-commit hooks.

---

#### 10. Architecture Visualization

**Scenario:** You need to create or update architecture diagrams for documentation.

```
User: "Generate an architecture diagram of our cluster"
User: "幫我畫架構圖"
User: "Show me the Kustomize dependency tree"
User: "Create an ArgoCD application topology diagram"
User: "Visualize our ingress routing"
User: "Generate a deployment flowchart"
```

**What happens:** Zeus generates diagrams in multiple formats (Mermaid, D2, KubeDiagrams): Kustomize dependency tree, ArgoCD application topology, ingress routing maps, Kubernetes resource topology, CI/CD pipeline flowcharts, and deployment workflow diagrams.

---

#### 11. Deprecated API & Version Drift Detection

**Scenario:** You're planning a Kubernetes version upgrade and need to check compatibility.

```
User: "Check if we're using any deprecated Kubernetes APIs"
User: "幫我檢查有沒有使用到即將棄用的 API"
User: "Is our cluster ready for Kubernetes 1.30?"
User: "Are there any image version drifts between environments?"
User: "What breaking changes should we watch for in the next K8s upgrade?"
```

**What happens:** Zeus uses pluto for deprecated API detection, kubeconform for schema validation against the target K8s version, and performs cross-environment image drift analysis.

---

#### 12. Diff Preview & Risk Assessment

**Scenario:** You want to understand the impact of your changes before deploying.

```
User: "Show me what's changing in this branch"
User: "幫我預覽這次部署的變更"
User: "What's the risk level of my current changes?"
User: "Compare the rendered manifests between my branch and main"
User: "Which environments will be affected by my changes?"
```

**What happens:** Zeus renders manifests for both branches, computes the diff, identifies affected environments, and generates a risk assessment (LOW/MEDIUM/HIGH) based on the scope and nature of changes.

---

#### 13. CI/CD Pipeline Audit

**Scenario:** You want to ensure your GitOps CI/CD pipeline follows best practices.

```
User: "Audit our CI/CD pipeline configuration"
User: "幫我檢查 CI/CD 流水線的設定"
User: "Are we running all the necessary checks in CI?"
User: "Is our pre-commit config complete?"
User: "What CI stages are we missing for GitOps?"
```

**What happens:** Zeus audits your CI/CD pipeline configuration, checks pre-commit setup, identifies missing stages, and recommends improvements.

---

### Combined Workflows — Power User Examples

#### 14. Full Infrastructure Review (Monday Morning Routine)

```
User: "Run a complete health check on everything"
```

Horus runs `*health` → Zeus runs `*health-check` → You get a consolidated dashboard of your entire platform.

---

#### 15. Pre-Release Checklist

```
User: "We're releasing v2.5.0 next week. Help me make sure everything is ready."
```

Zeus runs `*full` pipeline → security scan → diff preview → deprecated API check → architecture diagram update.

---

#### 16. Incident Investigation

```
User: "Something broke in production. Help me check what changed recently."
```

Zeus runs diff-preview against the last known good state, checks for recent image drift, and generates a change impact diagram.

---

#### 17. New Team Member Onboarding

```
User: "A new developer is joining. Help them set up and understand our infrastructure."
```

`/devops:detect` → tool status check → architecture diagram → health dashboard → walkthrough of repo structure.

---

### Tips for Natural Language Usage

1. **Be specific about scope**: "Check security for the payment module" is better than "check security"
2. **Mention the technology**: "Validate my Terraform" vs "Validate my Kustomize" helps route to the right agent
3. **State your goal**: "I'm preparing for a K8s upgrade to 1.30" gives more context than "check compatibility"
4. **Use either language**: The plugin responds to both English and Chinese commands
5. **Chain requests**: "First validate, then scan for security, then show me a diagram" triggers a pipeline

---

---

<a id="繁體中文"></a>

## 繁體中文

本文件提供**實際使用情境範例**，展示如何透過自然語言驅動 DevOps 外掛。你不需要記住指令 — 只需描述你的需求，外掛的代理會自動啟動正確的流水線。

---

### 快速對照：自然語言 → 流水線對應

| 你說的話 | 代理 | 觸發的流水線/指令 |
|---|---|---|
| 「掃描所有 Helm chart 版本」 | Horus | `*upgrade` |
| 「我的 Terraform 安全嗎？」 | Horus | `*security` |
| 「檢查 YAML 是否合法」 | Zeus | `*pre-merge` |
| 「幫我新增一個微服務」 | Zeus | `*onboard` |
| 「顯示架構圖」 | Zeus | `*diagram` |

---

### Horus（IaC）— 自然語言使用案例

#### 1. Helm 版本管理

**情境：** 你想檢查 Terraform 專案中的 Helm chart 是否有過時的版本。

```
「幫我掃描所有 Helm package 的版本」
「哪些 Helm chart 有新版本可以更新？」
「檢查一下我們的 Helm chart 版本是否都是最新的」
「我想把 Grafana 的 Helm chart 升級到最新版」
「升級 Redis Helm chart 到最新版本」
「列出所有 Helm module，並標出哪些需要更新」
```

**發生什麼事：** Horus 動態探索 Terraform 檔案中的所有 Helm 模組，向 ArtifactHub 查詢最新版本，並呈現比較表格。如果你選擇升級，它會執行原子性三檔更新（orchestrator + module variables + docs）。

---

#### 2. Terraform 驗證與一致性檢查

**情境：** 在提交 PR 前，你想確保所有 Terraform 程式碼都是乾淨的。

```
「幫我驗證所有 Terraform 程式碼」
「Terraform 格式和語法有沒有問題？」
「跑一次完整的一致性檢查」
「命名規範有沒有符合標準？」
「各環境設定檔和 JSON schema 是否一致？」
「檢查跨檔案的一致性問題」
```

**發生什麼事：** Horus 執行 `terraform fmt`、`terraform validate`、JSON schema 驗證、跨檔案一致性檢查（Helm 版本、模組路徑、環境設定、workload identity）以及命名規範稽核。

---

#### 3. 安全稽核

**情境：** 你正在準備安全審查，需要全面的稽核報告。

```
「幫我做一次安全稽核」
「GKE 叢集的安全性設定有沒有問題？」
「Terraform 裡有沒有寫死的 secret？」
「IAM 設定有沒有遵循最小權限原則？」
「幫我審查 Helm chart 的安全性」
「用 CIS benchmark 檢查我們的 GKE 設定」
「有沒有不安全的 IAM binding？」
```

**發生什麼事：** Horus 執行多層安全掃描：GKE 強化檢查清單（網路、節點、叢集、維護、IAM）、Terraform 程式碼掃描（硬編碼 secret、過度寬鬆的 IAM、不安全預設值）、以及 Helm chart 安全審查（ServiceAccount 設定、網路政策、映像安全、secret 管理、資源限制）。

---

#### 4. CI/CD 流水線改善

**情境：** 你想知道 CI/CD 流水線是否有缺漏或可以最佳化的地方。

```
「分析我們的 CI/CD 流水線，給出改善建議」
「GitLab CI 的流水線有哪些可以改善的地方？」
「我們是不是少了什麼重要的 CI 階段？」
「幫我產生安全掃描的 CI job snippet」
「跟最佳實踐比較，我們的 pipeline 差在哪？」
「幫我加一個 Terraform validation 階段到 pipeline」
```

**發生什麼事：** Horus 偵測你的 CI 系統（GitLab CI、GitHub Actions、Jenkins 等），對照建議階段執行差距分析，識別缺失的品質門檻，並產生可直接使用的 CI job 程式碼片段。

---

#### 5. 新 Helm 模組建立

**情境：** 你需要在基礎設施中新增一個 Helm chart 依賴。

```
「我要新增 Prometheus 到我們的基礎設施」
「幫我建立一個新的 Helm module 給 cert-manager」
「建立一個支援 workload identity 的 Helm 模組」
「新增一個 OCI-based 的 Helm chart 給 Istio」
「建立 external-dns 的 Helm module 腳手架」
```

**發生什麼事：** Horus 使用 5 種模式之一（simple、standard、workload-identity、OCI、multi-instance）建立模組腳手架，然後驗證並對新程式碼執行安全檢查。

---

#### 6. 平台健康檢查

**情境：** 週一早上 — 你想快速了解基礎設施的健康狀態。

```
「顯示平台健康儀表板」
「幫我看一下整個平台的健康狀態」
「有沒有過時的 chart 或安全問題？」
「給我一個基礎設施狀態總結」
「對 IaC repo 做一次完整的健康檢查」
```

**發生什麼事：** Horus 檢查 Helm chart 版本、執行安全掃描、驗證所有 Terraform 程式碼，並產出包含可操作項目的整合健康儀表板。

---

### Zeus（GitOps）— 自然語言使用案例

#### 7. 合併前驗證

**情境：** 你已經完成修改，想確保合併前一切正常。

```
「幫我做合併前的檢查」
「我的修改可以合併了嗎？」
「對我的分支執行所有驗證檢查」
「驗證所有環境的 Kustomize overlay」
「這個 MR 可以安全合併嗎？」
「跑一次 pre-merge pipeline」
```

**發生什麼事：** Zeus 執行 YAML lint、kustomize build、schema 驗證、安全掃描和差異預覽風險評估。最後產出判定結果：READY TO MERGE 或 NEEDS ATTENTION。

---

#### 8. 安全掃描

**情境：** 你想對 Kubernetes manifest 做全面的安全掃描。

```
「掃描 manifest 有沒有安全問題」
「有沒有安全性漏洞？」
「YAML 檔案裡有沒有寫死的 secret？」
「檢查容器映像有沒有 CVE」
「做一次供應鏈安全分析」
「我們的 Pod 有沒有用 root 執行？」
「幫我做一次完整的安全掃描」
```

**發生什麼事：** Zeus 調度 10+ 安全工具：checkov、trivy、kube-score、polaris、kube-linter、kyverno、gitleaks，加上供應鏈分析（SBOM、CVE 掃描、映像簽章驗證）。未安裝的工具會優雅跳過。

---

#### 9. 服務上線

**情境：** 新團隊需要將一個微服務部署到 Kubernetes 叢集。

```
「幫我上線一個叫 payment-api 的新服務」
「建立一個新的微服務 user-service」
「我需要部署一個有 Ingress 的新服務」
「建立一個包含 HPA 和監控的新服務」
「在 GitOps repo 加入一個新服務，配好 ArgoCD」
```

**發生什麼事：** Zeus 執行互動式上線流程：探索 repo 結構、建立 Deployment/Service/Ingress/HPA/ServiceMonitor 腳手架、建立 ArgoCD Application manifest、驗證所有項目、產生架構圖、設定 pre-commit hooks。

---

#### 10. 架構視覺化

**情境：** 你需要建立或更新文件用的架構圖。

```
「幫我畫架構圖」
「產生叢集的架構圖」
「顯示 Kustomize 相依性樹狀圖」
「建立 ArgoCD 應用拓撲圖」
「視覺化我們的 Ingress 路由」
「產生部署流程圖」
```

**發生什麼事：** Zeus 以多種格式（Mermaid、D2、KubeDiagrams）產生圖表：Kustomize 相依樹、ArgoCD 應用拓撲、Ingress 路由圖、Kubernetes 資源拓撲、CI/CD 流水線流程圖和部署工作流程圖。

---

#### 11. 棄用 API 與版本漂移偵測

**情境：** 你正在規劃 Kubernetes 版本升級，需要檢查相容性。

```
「有沒有使用到即將棄用的 Kubernetes API？」
「我們的叢集準備好升級到 Kubernetes 1.30 了嗎？」
「各環境之間有沒有映像版本漂移？」
「下一個 K8s 版本有哪些 breaking changes 要注意？」
「檢查 API 版本相容性」
```

**發生什麼事：** Zeus 使用 pluto 偵測棄用 API、kubeconform 驗證目標 K8s 版本的 schema，並執行跨環境映像版本漂移分析。

---

#### 12. 差異預覽與風險評估

**情境：** 你想在部署前了解變更的影響。

```
「顯示這個分支改了什麼」
「預覽這次部署的變更」
「我目前的修改風險等級是什麼？」
「比較我的分支和 main 的 rendered manifest」
「哪些環境會受到我的修改影響？」
```

**發生什麼事：** Zeus 渲染兩個分支的 manifest、計算差異、識別受影響的環境，並根據變更的範圍和性質產生風險評估（LOW/MEDIUM/HIGH）。

---

#### 13. CI/CD 流水線稽核

**情境：** 你想確保 GitOps CI/CD 流水線遵循最佳實踐。

```
「稽核我們的 CI/CD 流水線設定」
「CI 裡有沒有跑到所有必要的檢查？」
「pre-commit 設定完整嗎？」
「GitOps 還缺少哪些 CI 階段？」
「檢查流水線設定有沒有問題」
```

**發生什麼事：** Zeus 稽核你的 CI/CD 流水線設定、檢查 pre-commit 設置、識別缺失的階段，並提出改善建議。

---

### 組合工作流程 — 進階使用範例

#### 14. 完整基礎設施審查（週一早晨例行檢查）

```
「對所有東西做一次完整的健康檢查」
「週一報告 — 顯示整個平台狀態」
```

Horus 執行 `*health` → Zeus 執行 `*health-check` → 你得到整個平台的整合儀表板。

---

#### 15. 發版前檢查清單

```
「我們下週要發 v2.5.0，幫我確認所有東西都準備好了」
「Release 前的完整檢查」
```

Zeus 執行 `*full` pipeline → 安全掃描 → 差異預覽 → 棄用 API 檢查 → 架構圖更新。

---

#### 16. 事件調查

```
「Production 出了問題，幫我檢查最近改了什麼」
「有東西壞了，幫我找出最近的變更」
```

Zeus 對最後已知正常狀態執行差異預覽、檢查近期映像版本漂移，並產生變更影響圖。

---

#### 17. 新團隊成員入職

```
「新開發者加入了，幫他了解我們的基礎設施」
「幫新同事熟悉我們的 repo 結構」
```

`/devops:detect` → 工具狀態檢查 → 架構圖 → 健康儀表板 → repo 結構導覽。

---

### 自然語言使用技巧

1. **明確指定範圍**：「檢查 payment 模組的安全性」比「檢查安全性」更好
2. **提及技術**：「驗證我的 Terraform」vs「驗證我的 Kustomize」有助於路由到正確的代理
3. **說明目標**：「我正在準備升級到 K8s 1.30」提供比「檢查相容性」更多的脈絡
4. **中英文皆可**：外掛同時支援英文和中文指令
5. **串連請求**：「先驗證，再做安全掃描，最後畫架構圖」會觸發流水線式執行
