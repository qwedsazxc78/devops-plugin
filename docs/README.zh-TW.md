# DevOps Plugin for Claude Code

[English](../README.md) | **繁體中文**

> 兩個 AI 驅動的 DevOps 代理 — **Horus**（IaC）和 **Zeus**（GitOps）— 提供 20+ 自動化流水線指令，支援 Terraform、Helm、Kustomize 和 ArgoCD。

## 快速開始

### 1. 安裝外掛

```bash
# 方式 A：透過 Marketplace 安裝（推薦）
/plugin marketplace add qwedsazxc78/devops-plugin
/plugin install devops@devops-go

# 方式 B：本地開發
claude --plugin-dir ./devops-plugin
```

### 2. 安裝必要工具

<details>
<summary><b>macOS</b></summary>

```bash
# 安裝 Homebrew（如尚未安裝）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 基礎工具
brew install git kubectl jq yq

# GitOps (Zeus)
brew install kustomize kubeconform kube-score kube-linter trivy gitleaks
brew install FairwindsOps/tap/polaris FairwindsOps/tap/pluto conftest
pip3 install yamllint checkov

# IaC (Horus)
brew install terraform tflint tfsec
pip3 install pre-commit
```

</details>

<details>
<summary><b>Linux (Debian/Ubuntu)</b></summary>

```bash
# 基礎工具
sudo apt-get update && sudo apt-get install -y git jq
sudo snap install kubectl --classic
sudo snap install kustomize yq

# Python 工具
pip3 install yamllint checkov pre-commit
```

</details>

<details>
<summary><b>Windows (WSL2)</b></summary>

```bash
# 使用 WSL2 搭配 Ubuntu，然後依照 Linux 指示操作
wsl --install -d Ubuntu
```

</details>

或使用互動式安裝腳本：

```bash
./scripts/install-tools.sh          # 互動式檢查 + 安裝
./scripts/install-tools.sh check    # 僅檢查
```

### 3. 偵測你的 Repo 類型

```
/devops:detect
```

### 4. 啟動代理

```
/devops:horus     # IaC Repo（Terraform + Helm + GKE）
/devops:zeus      # GitOps Repo（Kustomize + ArgoCD）
```

---

## 代理介紹

### Horus — IaC 維運工程師

荷魯斯之眼 — 基礎設施完整性的全能守護者。以流水線驅動、安全優先的方式管理 Terraform + Helm + GKE 平台。

| 流水線 | 用途 |
|--------|------|
| `*full` | 完整檢查 + YAML 步驟記錄 + Markdown 報告 |
| `*upgrade` | 升級 Helm Chart 版本（原子性三檔更新）|
| `*security` | 安全稽核（GKE + Helm + IAM）|
| `*validate` | 完整驗證（格式 + Schema + 一致性）|
| `*new-module` | 建立新的 Helm 模組 |
| `*cicd` | CI/CD 流水線改善 |
| `*health` | 平台健康儀表板 |

### Zeus — GitOps 工程師

Kustomize + ArgoCD 工作流程的流水線協調器。驗證、安全掃描、腳手架和視覺化。

| 流水線 | 用途 |
|--------|------|
| `*full` | 完整流水線 + YAML/MD 報告 |
| `*pre-merge` | 合併前必要檢查 |
| `*health-check` | Repository 健康評估 |
| `*review` | MR 審查流水線 |
| `*onboard` | 服務上線引導（互動式）|
| `*diagram` | 產生架構圖 |
| `*status` | 工具安裝狀態檢查 |

---

## 指令一覽

### 偵測 Repo 類型

執行 `/devops:detect` — 外掛會掃描 IaC（`.tf` 檔、`modules/helm/`）和 GitOps（`kustomization.yaml`、`base/` + `overlays/`）指標。

### Zeus 指令（GitOps）

| 指令 | 說明 |
|------|------|
| `/devops:lint` | 快速 YAML 檢查 + kustomize build |
| `/devops:validate` | 完整驗證（7 個工具）|
| `/devops:security-scan` | 多工具安全掃描 |
| `/devops:secret-audit` | Secret 盤點 + 硬編碼偵測 |
| `/devops:diff-preview` | 分支差異 + 風險評估 |
| `/devops:upgrade-check` | 棄用 API + 映像版本漂移 |
| `/devops:pipeline-check` | CI/CD 流水線稽核 |
| `/devops:pre-commit` | 執行所有 Pre-commit Hooks |
| `/devops:k8s-compat` | Kubernetes 版本相容性檢查 |
| `/devops:add-service` | 建立新服務腳手架 |
| `/devops:add-ingress` | 建立 Ingress 資源 |
| `/devops:argocd-app` | 建立/驗證 ArgoCD Application |
| `/devops:diagram` | 架構圖（Mermaid/D2）|
| `/devops:flowchart` | 工作流程圖 |

### Horus 指令（IaC）

| 指令 | 說明 |
|------|------|
| `/devops:tf-validate` | Terraform 格式 + 驗證 + 一致性檢查 |
| `/devops:tf-security` | Terraform 安全稽核 |
| `/devops:helm-upgrade` | Helm Chart 版本升級 |
| `/devops:helm-scaffold` | 建立新的 Helm 模組腳手架 |
| `/devops:cicd-check` | CI/CD 流水線分析 |

### 自動觸發技能

這些會自動啟動 — 無需手動觸發：

| 技能 | 觸發條件 |
|------|----------|
| yaml-fix-suggestions | 編輯 Kustomize 目錄下的 YAML 檔案 |
| kustomize-resource-validation | 編輯 `kustomization.yaml` |
| repo-detect | 外掛載入 / 選擇代理時 |

---

## 文件說明

`docs/` 目錄包含以下詳細指南：

| 檔案 | 說明 |
|------|------|
| [`runbook.md`](runbook.md) | 完整操作手冊：安裝、工具設定、代理參考、指令參考、常見工作流程、故障排除 |
| [`use-cases.md`](use-cases.md) | 17 個實際使用案例與自然語言範例（中英對照） |
| [`cloud-integrations-roadmap.md`](cloud-integrations-roadmap.md) | 雲端整合藍圖：AWS EKS、Azure AKS、GCP 增強、成本最佳化等（中英對照） |
| [`README.zh-TW.md`](README.zh-TW.md) | 繁體中文文件（本檔案）|

---

## 工具需求

### 必要工具

| 工具 | 代理 | 安裝方式 |
|------|------|----------|
| `git` | 共用 | `brew install git` / `apt install git` |
| `kubectl` | 共用 | `brew install kubectl` |
| `kustomize` | Zeus | `brew install kustomize` |
| `terraform` | Horus | `brew install terraform` |

### 建議工具

| 工具 | 代理 | 安裝方式 |
|------|------|----------|
| `yamllint` | Zeus | `pip3 install yamllint` |
| `kubeconform` | Zeus | `brew install kubeconform` |
| `kube-score` | Zeus | `brew install kube-score` |
| `checkov` | 兩者 | `pip3 install checkov` |
| `trivy` | Zeus | `brew install trivy` |
| `gitleaks` | Zeus | `brew install gitleaks` |
| `tflint` | Horus | `brew install tflint` |
| `tfsec` | Horus | `brew install tfsec` |
| `pre-commit` | Horus | `pip3 install pre-commit` |

**注意：** 所有技能在建議工具缺失時會優雅降級 — 跳過該檢查並顯示安裝指令。僅必要工具會阻斷執行。

---

## 設計原則

- **動態探索** — 模組和環境在執行時動態發現，無硬編碼路徑
- **可移植性** — 適用於任何符合預期模式的 Repo
- **安全優先** — 套用前必先驗證，部署前必先掃描
- **優雅降級** — 缺少工具時跳過並顯示安裝建議

## 授權

MIT
