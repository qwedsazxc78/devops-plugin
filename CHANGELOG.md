# Changelog

All notable changes to this project will be documented in this file.

This changelog is auto-generated from [Conventional Commits](https://www.conventionalcommits.org/).

## [v1.1.0] - 2026-03-06

### Features

- 新增 `/devops:status` 指令 — 獨立工具安裝檢查與安裝器
  - 不依賴 `scripts/install-tools.sh`，適用所有安裝方式（marketplace、git clone、local）
  - 自動偵測平台（brew/apt/pip），批次安裝缺少的工具
  - 完整工具清單包含 Shared / Horus / Zeus 分類與 required / recommended 分級
- 新增 Horus `*full` 流水線 Step 0 動態目錄探索
  - 不再硬編碼 `application/` 路徑，改為 `find` 動態探索 Terraform 根目錄
  - Step 2 (terraform init) 改為使用者控制，提供 skip 選項
  - Step 3 (terraform validate) 在 init 跳過時自動 SKIP
- 新增 README 實際截圖（Horus activation + full pipeline 結果儀表板）
- 新增 marketplace logo 支援
- 測試套件從 260 增至 285 項（新增 README 圖片驗證、Horus 流水線定義一致性測試）

### Bug Fixes

- 修正 `*full` 流水線步驟數描述（8 → 10 步）
- 修正 `*validate` 指令描述與實際行為不一致（標記為 "no CLI exec" 但實際執行 terraform fmt）
- 修正 CHANGELOG 內容觸發 hardcoded reference 測試的誤報
- 修正 `*upgrade` 流水線缺少 TF_DIR 動態探索

### Documentation

- 更新 Runbook：新增 `/devops:status` 至 Getting Started 流程與 Tool Setup 章節
- 更新 README（EN/zh-TW）：新增 Getting Started 區塊、工具安裝步驟、實際截圖
- 圖片搬移至 `docs/images/` 並重新命名（horus-activation.png、horus-full-pipeline.png）

---

## [v1.0.0] - 2026-03-06

### Features

- 完成插件代碼審查、自動修復、市場發布配置與強化測試套件
  - 修復 14 項代碼審查問題（安全性、一致性、文件完整性）
  - 新增 marketplace.json 支援 Claude Code 插件市場發布
  - 測試套件從 135 增至 260 項（新增安全稽核、前置資料嚴格解析、指令一致性、變更日誌驗證）
  - CI changelog 支援 Conventional Commits 分類（feat/fix/refactor/docs）
  - 統一所有指令標題格式為 em-dash（—）
  - 修補中文文件和操作手冊缺少的 Horus 指令表
  - 移除參考檔案中硬編碼的專案 ID 並加入可攜性聲明
- initial devops plugin with Horus IaC Operations agent
  - Plugin manifest (devops namespace) with 5 skills and 1 agent
  - Horus agent: pipeline-driven IaC operations (/devops:horus)
  - Skills: helm-version-upgrade, terraform-validate, terraform-security,
  cicd-enhancer, helm-scaffold
  - Dynamic module discovery (no static CHART_REGISTRY dependency)
  - Secret-scanned and safe for public repository

### Bug Fixes

- remove project-specific references, add install runbook
  - Replace all "eye-of-horus" hardcoded references with generic terms
  - Replace project-specific CI values (monitoring-*-de514-ia007) with
  configurable variables (GCP_PROJECT_PREFIX, CLUSTER_NAME)
  - Remove CHART_REGISTRY.md reference from UPGRADE_PATTERNS.md
  - Remove hardcoded application/ paths from supporting docs
  - Remove incorrect homepage/repository URLs from plugin.json
  - Expand README with installation runbook (marketplace, git, project-level)
  - Add auto-update and version check instructions

### Documentation

- 新增中英文版本切換連結至 README
  - README.md 頂部加入 English | 繁體中文 切換連結
  - docs/README.zh-TW.md 頂部加入對應返回連結
