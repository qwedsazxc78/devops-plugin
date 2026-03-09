# DevOps Plugin — Cross-Platform Migration Plan

[English](#english) | [繁體中文](#繁體中文)

---

<a id="english"></a>

## English

This document outlines the migration plan for extending the DevOps plugin from a Claude Code-only plugin to a cross-platform AI agent skill pack supporting **Claude Code**, **OpenAI Codex CLI**, and **Google Gemini CLI**.

> **Goal:** One source of truth for DevOps skills, agents, and workflows — distributed to three AI coding assistants with platform-native experiences and seamless version upgrades.

---

## Current State

| Dimension | Status |
|-----------|--------|
| **Platform** | Claude Code only |
| **Distribution** | Claude Code plugin marketplace + git clone |
| **Version** | v1.0.0 (semver, conventional commits) |
| **Agents** | 2 (Horus IaC, Zeus GitOps) |
| **Skills** | 8 (SKILL.md with YAML frontmatter) |
| **Commands** | 22 |
| **CI/CD** | GitHub Actions (structure tests + auto-changelog) |

---

## Target Architecture

### Directory Structure

```
devops-plugin/                            ← Same repo, extended
│
├── .claude-plugin/                       ← Claude Code plugin manifest
│   ├── plugin.json
│   └── marketplace.json
│
├── agents/                               ← Agent definitions (Claude Code native)
│   ├── horus.md
│   └── zeus.md
│
├── skills/                               ← Shared skills (Open Agent Skills standard)
│   ├── terraform-validate/SKILL.md       ← Claude + Codex use directly
│   ├── terraform-security/SKILL.md
│   ├── helm-version-upgrade/SKILL.md
│   ├── helm-scaffold/SKILL.md
│   ├── cicd-enhancer/SKILL.md
│   ├── kustomize-resource-validation/SKILL.md
│   ├── yaml-fix-suggestions/SKILL.md
│   └── repo-detect/SKILL.md
│
├── commands/                             ← Claude Code commands (22 files)
│   └── *.md
│
├── codex/                                ← OpenAI Codex CLI adapter
│   ├── AGENTS.md                         ← Codex entry point (references shared skills)
│   └── setup.sh                          ← Symlink installer for .codex/skills/
│
├── gemini/                               ← Google Gemini CLI adapter
│   ├── GEMINI.md                         ← Gemini entry point (uses @import syntax)
│   ├── agents/                           ← Gemini-format subagent definitions
│   │   ├── horus.md
│   │   └── zeus.md
│   └── setup.sh                          ← Extension installer for .gemini/
│
├── scripts/
│   ├── install-tools.sh                  ← Existing tool installer
│   ├── generate-changelog.sh             ← Existing changelog generator
│   └── sync-platforms.sh                 ← NEW: Generate platform-specific files from shared source
│
├── tests/
│   ├── test-plugin-structure.sh          ← Existing (extended for cross-platform)
│   └── test-cross-platform.sh            ← NEW: Validate all platform adapters
│
├── docs/
│   ├── runbook.md                        ← Updated with multi-platform setup
│   ├── use-cases.md
│   ├── cloud-integrations-roadmap.md
│   ├── cross-platform-migration-plan.md  ← This file
│   └── README.zh-TW.md
│
├── settings.json
├── CHANGELOG.md
├── VERSION                               ← NEW: Single source of truth for version
└── README.md                             ← Updated with multi-platform quick start
```

### Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Repo strategy** | Single repo with platform adapters | Avoids sync issues, one PR covers all platforms |
| **Skills standard** | Open Agent Skills (SKILL.md) | Claude + Codex share the same standard natively |
| **Gemini approach** | Adapter layer (GEMINI.md + subagents) | Gemini uses different format; thin adapter needed |
| **Version source** | `VERSION` file + `plugin.json` | Single source of truth, easy to bump |
| **Distribution** | Git-based (clone/submodule) + marketplace | Most reliable for cross-platform |

---

## Platform Compatibility Matrix

### Skills Sharing Strategy

```
skills/terraform-validate/SKILL.md
(Open Agent Skills standard — YAML frontmatter + Markdown body)
                │
   ┌────────────┼────────────┐
   │            │            │
Claude Code  Codex CLI   Gemini CLI
(native)     (native)    (adapter)
   │            │            │
reads from   symlink →    GEMINI.md
skills/      .codex/      @imports
directly     skills/      references
```

**Claude Code + Codex CLI** both implement the Open Agent Skills specification. The `SKILL.md` format with `name:` and `description:` frontmatter works identically on both platforms.

**Gemini CLI** uses a different system (extensions + subagents). The adapter layer translates shared content into Gemini-native formats via `GEMINI.md` with `@import` references.

### Feature Parity Table

| Feature | Claude Code | Codex CLI | Gemini CLI |
|---------|-------------|-----------|------------|
| SKILL.md loading | Native | Native (symlink) | Via @import in GEMINI.md |
| Agent switching | `agents/*.md` | Via AGENTS.md routing | `agents/*.md` (subagents) |
| Command invocation | `/devops:command` | `$command` or natural language | Natural language |
| Auto-trigger skills | Yes (SKILL.md config) | Yes (allow_implicit_invocation) | Via GEMINI.md instructions |
| Bash execution | Yes | Yes | Yes (run_shell_command) |
| Pipeline workflows | Commands → skills chain | AGENTS.md workflows | GEMINI.md workflows |

---

## Version Upgrade Strategy

### Versioning Scheme

```
MAJOR.MINOR.PATCH
  │     │     │
  │     │     └── Bug fixes, typo corrections, checklist updates
  │     └──────── New skills, new commands, new platform support
  └────────────── Breaking changes (skill rename, removed commands, restructure)
```

**Version is tracked in three places (kept in sync by CI):**
1. `VERSION` file (single source of truth)
2. `.claude-plugin/plugin.json` → `"version"` field
3. `CHANGELOG.md` → latest entry header

### Live Update Mechanism

#### Option A: Git-Based Updates (Recommended)

Users install the plugin via git, enabling pull-based updates:

```bash
# Initial install (any platform)
git clone https://github.com/qwedsazxc78/devops-plugin.git

# Check for updates
cd devops-plugin && git fetch origin main
git log HEAD..origin/main --oneline    # See what changed

# Update to latest
git pull origin main

# Or pin to a specific version
git checkout v1.2.0
```

**For projects using the plugin as a dependency:**

```bash
# As git submodule (recommended for team repos)
git submodule add https://github.com/qwedsazxc78/devops-plugin.git .devops-plugin
git submodule update --remote    # Update to latest

# As git subtree (alternative — no submodule overhead)
git subtree pull --prefix=.devops-plugin https://github.com/qwedsazxc78/devops-plugin.git main --squash
```

#### Option B: Claude Code Marketplace Updates

```bash
# Marketplace install (auto-updates via marketplace)
/plugin marketplace add qwedsazxc78/devops-plugin
/plugin install devops@devops-go

# Check version
/plugin info devops
```

#### Option C: Version Check Script

A built-in version check command that works across all platforms:

```bash
# scripts/version-check.sh
# Compares local VERSION against latest GitHub release tag
# Outputs: current version, latest version, upgrade available (yes/no)
# Shows changelog diff between versions
```

### Update Notification Flow

```
User starts plugin
       │
       ▼
┌──────────────────┐     ┌─────────────────────┐
│ Read local        │────▶│ Compare with remote  │
│ VERSION file      │     │ (GitHub API / tag)   │
└──────────────────┘     └──────────┬────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
              Up to date     Minor update      Major update
              (silent)       (info message)    (warning + changelog)
                             │                 │
                             ▼                 ▼
                    "v1.1.0 available.     "v2.0.0 available.
                     Run: git pull"        BREAKING CHANGES:
                                           - skill X renamed
                                           - command Y removed
                                           Run: git pull"
```

### Breaking Change Protocol

| Severity | Example | Action |
|----------|---------|--------|
| **Patch** (1.0.x) | Fix typo in checklist, improve prompt wording | Silent update, no user action |
| **Minor** (1.x.0) | Add new skill, add new command, extend checklist | Info notification, backward compatible |
| **Major** (x.0.0) | Rename skill directory, remove command, change frontmatter schema | Warning with migration guide |

**For major version upgrades, provide:**
1. `MIGRATION.md` file in the release
2. `scripts/migrate.sh` automated migration script
3. Deprecation warnings one minor version before removal

### Pinning and Rollback

```bash
# Pin to specific version (for production stability)
git checkout v1.2.0

# List all available versions
git tag -l "v*" --sort=-version:refname

# Rollback to previous version
git checkout v1.1.0

# Auto-update with safety (fetch + review before merge)
git fetch origin main
git diff HEAD..origin/main -- skills/ agents/ commands/
git merge origin/main
```

---

## Migration Phases

### Phase 1: Foundation (Current Sprint)

| Task | Description | Status |
|------|-------------|--------|
| Create `VERSION` file | Single source of truth for version | Planned |
| Add `codex/AGENTS.md` | Codex CLI entry point referencing shared skills | Planned |
| Add `codex/setup.sh` | Symlink installer for `.codex/skills/` | Planned |
| Add `gemini/GEMINI.md` | Gemini CLI entry point with @import references | Planned |
| Add `gemini/agents/*.md` | Gemini-format subagent definitions | Planned |
| Add `gemini/setup.sh` | Extension installer for `.gemini/` | Planned |
| Add `scripts/version-check.sh` | Cross-platform version check utility | Planned |
| Update `README.md` | Multi-platform quick start section | Planned |
| Update `docs/runbook.md` | Multi-platform installation guides | Planned |
| Add `tests/test-cross-platform.sh` | Validate all platform adapters | Planned |

### Phase 2: Stabilization

| Task | Description |
|------|-------------|
| Validate on Codex CLI | End-to-end testing with OpenAI Codex |
| Validate on Gemini CLI | End-to-end testing with Google Gemini |
| Version check integration | Integrate version check into agent startup |
| CI pipeline extension | Add cross-platform tests to GitHub Actions |
| Documentation | Platform-specific setup guides |

### Phase 3: Distribution Optimization

| Task | Description |
|------|-------------|
| GitHub Releases | Automated releases with changelogs and migration notes |
| Tag-based versioning | Semantic version tags (v1.0.0, v1.1.0, ...) |
| Marketplace sync | Keep Claude Code marketplace in sync with git tags |
| Community templates | Example integration for common DevOps repos |

---

## Cross-Platform Adapter Specifications

### Codex CLI Adapter (`codex/AGENTS.md`)

```markdown
# DevOps Agent Pack

You are a DevOps assistant with two specialized agents: Horus (IaC) and Zeus (GitOps).

## Agent Selection
- For Terraform, Helm, GKE → use Horus workflows
- For Kustomize, ArgoCD, GitOps → use Zeus workflows
- Unsure → scan for .tf files (Horus) or kustomization.yaml (Zeus)

## Available Skills
Use $terraform-validate, $terraform-security, $helm-version-upgrade, etc.

## Workflows
[... shared workflow definitions ...]
```

**Setup:** `codex/setup.sh` creates symlinks from `.codex/skills/` → `skills/`

### Gemini CLI Adapter (`gemini/GEMINI.md`)

```markdown
# DevOps Agent Pack

@agents/horus.md
@agents/zeus.md

You are a DevOps assistant. Use the imported agent definitions above.

## Workflow Reference
@../../skills/terraform-validate/SKILL.md
@../../skills/terraform-security/SKILL.md
[... import all skills ...]
```

**Setup:** `gemini/setup.sh` copies adapter files to `.gemini/`

---

## Best Practices Checklist

### Architecture

- [x] Single repo for all platforms (avoids drift)
- [x] Shared skills in Open Agent Skills standard (SKILL.md)
- [x] Platform-specific adapters in isolated directories
- [x] VERSION file as single source of truth
- [x] Semantic versioning with conventional commits

### Distribution

- [x] Git clone / submodule as primary distribution
- [x] Claude Code marketplace as secondary channel
- [x] Version check script for update awareness
- [x] Tag-based releases for pinning
- [x] Rollback capability via git checkout

### Quality

- [x] Automated structure tests (existing 260+ tests)
- [x] Cross-platform adapter tests (new)
- [x] CI/CD pipeline with auto-changelog
- [x] Security scanning (no hardcoded secrets)
- [x] Cross-reference validation

### User Experience

- [x] One-line install per platform
- [x] Interactive tool installer (existing)
- [x] Auto-detect repo type (existing)
- [x] Natural language interaction (existing)
- [x] Graceful degradation when tools missing (existing)

### Versioning

- [x] Semver (MAJOR.MINOR.PATCH)
- [x] Conventional commits for changelog generation
- [x] Breaking change protocol (deprecate → migrate → remove)
- [x] Migration scripts for major versions
- [x] Pinning and rollback support

### Missing Parts to Address

- [ ] GitHub Releases automation (tag → release → changelog → assets)
- [ ] Version check at agent startup (non-blocking notification)
- [ ] `MIGRATION.md` template for major version upgrades
- [ ] End-to-end testing on Codex CLI
- [ ] End-to-end testing on Gemini CLI
- [ ] Gemini extension auto-generation script
- [ ] Codex config.toml template
- [ ] Multi-language skill descriptions (EN + ZH-TW)

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| SKILL.md format diverges between Claude/Codex | High | Pin to Open Agent Skills spec, test both platforms in CI |
| Gemini CLI changes extension format | Medium | Adapter layer isolates changes; only `gemini/` needs update |
| Version drift across platforms | Medium | Single VERSION file, CI enforces consistency |
| Symlinks not supported on Windows | Low | `setup.sh` falls back to file copy on Windows/WSL2 |
| User forgets to update | Low | Version check notification at startup |

---

## Quick Reference: User Install Flow

### Claude Code

```bash
# Marketplace (recommended)
/plugin marketplace add qwedsazxc78/devops-plugin
/plugin install devops@devops-go

# Or git
git clone https://github.com/qwedsazxc78/devops-plugin.git
claude --plugin-dir ./devops-plugin
```

### OpenAI Codex CLI

```bash
git clone https://github.com/qwedsazxc78/devops-plugin.git
cd devops-plugin && bash codex/setup.sh
# Creates .codex/skills/ symlinks + copies AGENTS.md
```

### Google Gemini CLI

```bash
git clone https://github.com/qwedsazxc78/devops-plugin.git
cd devops-plugin && bash gemini/setup.sh
# Copies GEMINI.md + agents/ to .gemini/
```

### Update (All Platforms)

```bash
cd devops-plugin
bash scripts/version-check.sh       # Check if update available
git pull origin main                 # Update to latest
bash codex/setup.sh                  # Re-sync Codex (if using)
bash gemini/setup.sh                 # Re-sync Gemini (if using)
```

---

---

<a id="繁體中文"></a>

## 繁體中文

本文件說明將 DevOps 外掛從 Claude Code 專屬外掛，遷移為支援 **Claude Code**、**OpenAI Codex CLI** 和 **Google Gemini CLI** 的跨平台 AI Agent 技能包的計劃。

> **目標：** 一份 DevOps 技能、Agent 和工作流程的單一真相來源，分發至三個 AI 編程助手，提供平台原生體驗和無縫版本升級。

---

## 現狀

| 維度 | 狀態 |
|------|------|
| **平台** | 僅 Claude Code |
| **分發** | Claude Code 外掛市場 + git clone |
| **版本** | v1.0.0（語意版本控制、約定式提交） |
| **Agent** | 2 個（Horus IaC、Zeus GitOps） |
| **Skills** | 8 個（SKILL.md + YAML frontmatter） |
| **命令** | 22 個 |
| **CI/CD** | GitHub Actions（結構測試 + 自動變更日誌） |

---

## 目標架構

### 目錄結構

```
devops-plugin/                            ← 同一 repo，擴展
│
├── .claude-plugin/                       ← Claude Code 外掛 manifest
│   ├── plugin.json
│   └── marketplace.json
│
├── agents/                               ← Agent 定義（Claude Code 原生）
│   ├── horus.md
│   └── zeus.md
│
├── skills/                               ← 共用 Skills（Open Agent Skills 標準）
│   ├── terraform-validate/SKILL.md       ← Claude + Codex 直接使用
│   ├── terraform-security/SKILL.md
│   └── ...（8 個 skills）
│
├── commands/                             ← Claude Code 命令（22 個檔案）
│
├── codex/                                ← OpenAI Codex CLI 適配器
│   ├── AGENTS.md                         ← Codex 入口（引用共用 skills）
│   └── setup.sh                          ← .codex/skills/ 符號連結安裝器
│
├── gemini/                               ← Google Gemini CLI 適配器
│   ├── GEMINI.md                         ← Gemini 入口（使用 @import 語法）
│   ├── agents/                           ← Gemini 格式的 subagent 定義
│   │   ├── horus.md
│   │   └── zeus.md
│   └── setup.sh                          ← .gemini/ 擴展安裝器
│
├── scripts/
│   ├── install-tools.sh                  ← 既有工具安裝器
│   ├── generate-changelog.sh             ← 既有變更日誌產生器
│   └── sync-platforms.sh                 ← 新增：從共用來源生成平台特定檔案
│
├── VERSION                               ← 新增：版本單一真相來源
└── ...
```

### 關鍵設計決策

| 決策 | 選擇 | 原因 |
|------|------|------|
| **Repo 策略** | 單一 repo + 平台適配器 | 避免同步問題，一個 PR 涵蓋所有平台 |
| **Skills 標準** | Open Agent Skills（SKILL.md） | Claude + Codex 原生共用同一標準 |
| **Gemini 方式** | 適配層（GEMINI.md + subagents） | Gemini 使用不同格式，需要薄適配層 |
| **版本來源** | `VERSION` 檔案 + `plugin.json` | 單一真相來源，易於升版 |
| **分發方式** | Git（clone/submodule）+ marketplace | 跨平台最可靠 |

---

## 平台相容性矩陣

### Skills 共用策略

```
skills/terraform-validate/SKILL.md
（Open Agent Skills 標準 — YAML frontmatter + Markdown 內容）
                │
   ┌────────────┼────────────┐
   │            │            │
Claude Code  Codex CLI   Gemini CLI
（原生）      （原生）     （適配器）
   │            │            │
直接從       symlink →    GEMINI.md
skills/      .codex/      @imports
讀取         skills/      引用
```

**Claude Code + Codex CLI** 都實作 Open Agent Skills 規範。`SKILL.md` 格式的 `name:` 和 `description:` frontmatter 在兩個平台上運作完全相同。

**Gemini CLI** 使用不同系統（extensions + subagents）。適配層透過 `GEMINI.md` 的 `@import` 引用將共用內容轉譯為 Gemini 原生格式。

---

## 版本升級策略

### 版本控制方案

```
MAJOR.MINOR.PATCH
  │     │     │
  │     │     └── 修正錯誤、修改錯字、更新檢查表
  │     └──────── 新增 skill、新增命令、新增平台支援
  └────────────── 破壞性變更（skill 重新命名、移除命令、重組結構）
```

**版本在三處追蹤（由 CI 保持同步）：**
1. `VERSION` 檔案（單一真相來源）
2. `.claude-plugin/plugin.json` → `"version"` 欄位
3. `CHANGELOG.md` → 最新條目標題

### 即時更新機制

#### 方式 A：Git 更新（建議）

使用者透過 git 安裝外掛，啟用 pull-based 更新：

```bash
# 初次安裝（任何平台）
git clone https://github.com/qwedsazxc78/devops-plugin.git

# 檢查更新
cd devops-plugin && git fetch origin main
git log HEAD..origin/main --oneline    # 查看變更內容

# 更新至最新
git pull origin main

# 或固定特定版本
git checkout v1.2.0
```

**專案作為相依性使用：**

```bash
# 作為 git submodule（建議團隊 repo 使用）
git submodule add https://github.com/qwedsazxc78/devops-plugin.git .devops-plugin
git submodule update --remote    # 更新至最新

# 作為 git subtree（替代方案 — 無 submodule 開銷）
git subtree pull --prefix=.devops-plugin https://github.com/qwedsazxc78/devops-plugin.git main --squash
```

#### 方式 B：Claude Code 市場更新

```bash
# 市場安裝（透過市場自動更新）
/plugin marketplace add qwedsazxc78/devops-plugin
/plugin install devops@devops-go

# 檢查版本
/plugin info devops
```

#### 方式 C：版本檢查腳本

跨平台的內建版本檢查命令：

```bash
# scripts/version-check.sh
# 比較本機 VERSION 與最新 GitHub release tag
# 輸出：目前版本、最新版本、是否有可用更新
# 顯示版本間的變更日誌差異
```

### 更新通知流程

```
使用者啟動外掛
       │
       ▼
┌──────────────────┐     ┌─────────────────────┐
│ 讀取本機          │────▶│ 與遠端比較           │
│ VERSION 檔案      │     │（GitHub API / tag）  │
└──────────────────┘     └──────────┬────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
              已是最新       次要更新          重大更新
              （靜默）       （資訊訊息）      （警告 + 變更日誌）
                             │                 │
                             ▼                 ▼
                    "v1.1.0 可用。         "v2.0.0 可用。
                     執行：git pull"       破壞性變更：
                                           - skill X 已重新命名
                                           - command Y 已移除
                                           執行：git pull"
```

### 破壞性變更協議

| 嚴重程度 | 範例 | 處理方式 |
|---------|------|---------|
| **Patch** (1.0.x) | 修正檢查表錯字、改善提示詞 | 靜默更新，無需使用者操作 |
| **Minor** (1.x.0) | 新增 skill、新增命令、擴展檢查表 | 資訊通知，向後相容 |
| **Major** (x.0.0) | 重新命名 skill 目錄、移除命令、變更 frontmatter schema | 警告 + 遷移指南 |

**重大版本升級需提供：**
1. Release 中的 `MIGRATION.md` 檔案
2. `scripts/migrate.sh` 自動遷移腳本
3. 在移除前一個次要版本中發出棄用警告

### 固定版本與回滾

```bash
# 固定特定版本（用於生產環境穩定性）
git checkout v1.2.0

# 列出所有可用版本
git tag -l "v*" --sort=-version:refname

# 回滾到上一版本
git checkout v1.1.0

# 安全自動更新（fetch + 審查後再合併）
git fetch origin main
git diff HEAD..origin/main -- skills/ agents/ commands/
git merge origin/main
```

---

## 遷移階段

### 第一階段：基礎（當前衝刺）

| 任務 | 說明 | 狀態 |
|------|------|------|
| 建立 `VERSION` 檔案 | 版本單一真相來源 | 計劃中 |
| 新增 `codex/AGENTS.md` | Codex CLI 入口，引用共用 skills | 計劃中 |
| 新增 `codex/setup.sh` | `.codex/skills/` 符號連結安裝器 | 計劃中 |
| 新增 `gemini/GEMINI.md` | Gemini CLI 入口，使用 @import 引用 | 計劃中 |
| 新增 `gemini/agents/*.md` | Gemini 格式的 subagent 定義 | 計劃中 |
| 新增 `gemini/setup.sh` | `.gemini/` 擴展安裝器 | 計劃中 |
| 新增 `scripts/version-check.sh` | 跨平台版本檢查工具 | 計劃中 |
| 更新 `README.md` | 多平台快速入門區段 | 計劃中 |
| 更新 `docs/runbook.md` | 多平台安裝指南 | 計劃中 |
| 新增 `tests/test-cross-platform.sh` | 驗證所有平台適配器 | 計劃中 |

### 第二階段：穩定化

| 任務 | 說明 |
|------|------|
| Codex CLI 驗證 | 在 OpenAI Codex 上端到端測試 |
| Gemini CLI 驗證 | 在 Google Gemini 上端到端測試 |
| 版本檢查整合 | 在 agent 啟動時整合版本檢查 |
| CI 流水線擴展 | 在 GitHub Actions 中新增跨平台測試 |
| 文件完善 | 各平台專屬設定指南 |

### 第三階段：分發優化

| 任務 | 說明 |
|------|------|
| GitHub Releases | 自動化 release（tag → release → changelog → assets） |
| 基於 Tag 的版本控制 | 語意版本 tag（v1.0.0、v1.1.0 ...） |
| Marketplace 同步 | 保持 Claude Code marketplace 與 git tag 同步 |
| 社群模板 | 常見 DevOps repo 的範例整合 |

---

## 最佳實踐檢查表

### 架構

- [x] 所有平台使用單一 repo（避免漂移）
- [x] 使用 Open Agent Skills 標準的共用 skills（SKILL.md）
- [x] 平台特定適配器在隔離目錄中
- [x] VERSION 檔案作為版本單一真相來源
- [x] 語意版本控制 + 約定式提交

### 分發

- [x] Git clone / submodule 作為主要分發方式
- [x] Claude Code marketplace 作為次要管道
- [x] 版本檢查腳本用於更新感知
- [x] 基於 tag 的 release 用於固定版本
- [x] 透過 git checkout 支援回滾

### 品質

- [x] 自動化結構測試（既有 260+ 測試）
- [x] 跨平台適配器測試（新增）
- [x] CI/CD 流水線 + 自動變更日誌
- [x] 安全掃描（無硬編碼密鑰）
- [x] 交叉引用驗證

### 使用者體驗

- [x] 每個平台一行安裝指令
- [x] 互動式工具安裝器（既有）
- [x] 自動偵測 repo 類型（既有）
- [x] 自然語言互動（既有）
- [x] 工具缺失時優雅降級（既有）

### 版本控制

- [x] Semver（MAJOR.MINOR.PATCH）
- [x] 約定式提交用於變更日誌生成
- [x] 破壞性變更協議（棄用 → 遷移 → 移除）
- [x] 重大版本遷移腳本
- [x] 固定版本和回滾支援

### 待處理項目

- [ ] GitHub Releases 自動化（tag → release → changelog → assets）
- [ ] Agent 啟動時的版本檢查（非阻塞通知）
- [ ] 重大版本升級的 `MIGRATION.md` 模板
- [ ] 在 Codex CLI 上的端到端測試
- [ ] 在 Gemini CLI 上的端到端測試
- [ ] Gemini extension 自動生成腳本
- [ ] Codex config.toml 模板
- [ ] 多語言 skill 描述（EN + ZH-TW）

---

## 風險評估

| 風險 | 影響 | 緩解措施 |
|------|------|---------|
| SKILL.md 格式在 Claude/Codex 間分歧 | 高 | 固定 Open Agent Skills 規範，CI 中測試兩個平台 |
| Gemini CLI 變更 extension 格式 | 中 | 適配層隔離變更；僅 `gemini/` 需更新 |
| 平台間版本漂移 | 中 | 單一 VERSION 檔案，CI 強制一致性 |
| Windows 不支援符號連結 | 低 | `setup.sh` 在 Windows/WSL2 上降級為檔案複製 |
| 使用者忘記更新 | 低 | 啟動時版本檢查通知 |

---

## 快速參考：使用者安裝流程

### Claude Code

```bash
# Marketplace（建議）
/plugin marketplace add qwedsazxc78/devops-plugin
/plugin install devops@devops-go

# 或 git
git clone https://github.com/qwedsazxc78/devops-plugin.git
claude --plugin-dir ./devops-plugin
```

### OpenAI Codex CLI

```bash
git clone https://github.com/qwedsazxc78/devops-plugin.git
cd devops-plugin && bash codex/setup.sh
# 建立 .codex/skills/ 符號連結 + 複製 AGENTS.md
```

### Google Gemini CLI

```bash
git clone https://github.com/qwedsazxc78/devops-plugin.git
cd devops-plugin && bash gemini/setup.sh
# 複製 GEMINI.md + agents/ 到 .gemini/
```

### 更新（所有平台）

```bash
cd devops-plugin
bash scripts/version-check.sh       # 檢查是否有更新
git pull origin main                 # 更新至最新
bash codex/setup.sh                  # 重新同步 Codex（如有使用）
bash gemini/setup.sh                 # 重新同步 Gemini（如有使用）
```
