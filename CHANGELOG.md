# Changelog

All notable changes to this project will be documented in this file.

This changelog is auto-generated from [Conventional Commits](https://www.conventionalcommits.org/).

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
