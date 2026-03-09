# DevOps Plugin — Cross-Platform Migration Plan

[English](#english) | [繁體中文](#繁體中文)

---

<a id="english"></a>

## English

This document outlines the migration plan for extending the DevOps plugin from a Claude Code-only plugin to a cross-platform AI agent skill pack supporting **Claude Code**, **OpenAI Codex CLI**, and **Google Gemini CLI**.

> **Goal:** One source of truth for DevOps skills, agents, and workflows — distributed to three AI coding assistants with platform-native experiences and seamless version upgrades.

> **Key Finding:** [Agent Skills](https://agentskills.io/specification) is now an **open standard** (released Dec 2025, adopted by 25+ tools including all three target platforms). All three platforms natively read `SKILL.md` files — no adapter layer needed for skills.

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
| **Skills standard** | [Open Agent Skills](https://agentskills.io/specification) (SKILL.md) | All 3 platforms natively support the same standard |
| **Gemini approach** | Native SKILL.md + GEMINI.md for agent routing | Gemini CLI reads SKILL.md natively; only agent routing needs adapter |
| **Version source** | `VERSION` file + `plugin.json` + SKILL.md `version:` field | Single source of truth, easy to bump |
| **Distribution** | Git + `npx skills` + marketplace | Multiple channels for different user preferences |

---

## Platform Compatibility Matrix

### Skills Sharing Strategy

All three platforms now natively support the [Agent Skills open standard](https://agentskills.io/specification):

```
skills/terraform-validate/SKILL.md
(Open Agent Skills standard — YAML frontmatter + Markdown body)
                │
   ┌────────────┼────────────┐
   │            │            │
Claude Code  Codex CLI   Gemini CLI
(native)     (native)    (native)
   │            │            │
.claude/     .agents/     .gemini/
skills/      skills/      skills/
(or plugin)  (symlink)    (symlink)
```

**All three platforms** implement the Agent Skills specification. The `SKILL.md` format with `name:` and `description:` frontmatter works identically across Claude Code, Codex CLI, and Gemini CLI. No adapter layer is needed for skills — only symlinks or file copies to each platform's expected directory.

**Differences remain in:** agent definitions (routing logic), command invocation syntax, and configuration files. These are handled by thin adapter files per platform.

### Feature Parity Table

| Feature | Claude Code | Codex CLI | Gemini CLI |
|---------|-------------|-----------|------------|
| SKILL.md loading | Native | Native | Native |
| Skills directory | `.claude/skills/` | `.agents/skills/` | `.gemini/skills/` or `.agents/skills/` |
| Agent switching | `agents/*.md` | Via AGENTS.md routing | `agents/*.md` (subagents) |
| Command invocation | `/devops:command` | `$command` or natural language | Natural language |
| Auto-trigger skills | Yes (SKILL.md config) | Yes (allow_implicit_invocation) | Via GEMINI.md instructions |
| Bash execution | Yes | Yes | Yes (run_shell_command) |
| Pipeline workflows | Commands → skills chain | AGENTS.md workflows | GEMINI.md workflows |
| Hot reload | Yes (immediate) | On session start | On session start |

---

## Distribution Channels

### Channel Comparison

| Channel | Versioning | Cross-platform | Auto-update | Best For |
|---------|-----------|----------------|-------------|----------|
| **`npx skills`** (Vercel) | Git-based | All agents | `npx skills update` | Individual developers |
| **npm package** | Semver | All (with install hooks) | `npm update` | Enterprise / private registry |
| **Git clone** | Tag-based | All | `git pull` | Development / contribution |
| **Git submodule** | SHA pinning | All | `git submodule update` | Team repos (small teams) |
| **Claude Marketplace** | Marketplace-managed | Claude only | Automatic | Claude Code users |
| **Gemini Extensions** | Git-based | Gemini only | `gemini extensions update` | Gemini CLI users |

### Recommended: `npx skills` (Primary) + Git (Developers)

**[`npx skills`](https://github.com/vercel-labs/skills)** (by Vercel Labs) is the emerging standard package manager for agent skills. It auto-detects installed agents and routes SKILL.md files to the correct directories:

```bash
# Install specific skills from this repo
npx skills add qwedsazxc78/devops-plugin --skill terraform-validate
npx skills add qwedsazxc78/devops-plugin --skill terraform-security

# Install all skills
npx skills add qwedsazxc78/devops-plugin

# Check for updates
npx skills check

# Update all installed skills
npx skills update
```

**Git clone** remains the primary channel for developers who want to contribute or customize:

```bash
git clone https://github.com/qwedsazxc78/devops-plugin.git
```

### Future: npm Package Distribution

For enterprise teams with private registries, publishing as an npm package with install hooks:

```bash
npm install @awoo/devops-plugin
# postinstall hook copies SKILL.md files to detected agent directories
```

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

**Version is tracked in four places (kept in sync by CI):**
1. `VERSION` file (single source of truth)
2. `.claude-plugin/plugin.json` → `"version"` field
3. `CHANGELOG.md` → latest entry header
4. Each `SKILL.md` → `version:` field in YAML frontmatter (per-skill versioning)

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

#### Option C: `npx skills` Package Manager

```bash
# Check for updates across all installed skills
npx skills check

# Update all skills to latest
npx skills update

# Update specific skill
npx skills update qwedsazxc78/devops-plugin --skill terraform-validate
```

#### Option D: Version Check Script

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

**Setup:** `codex/setup.sh` creates symlinks from `.agents/skills/` → `skills/`

**Skill scoping (Codex):** `.agents/skills/` (workspace), `~/.agents/skills/` (user), `/etc/codex/skills/` (admin/org-wide)

### Gemini CLI Adapter (`gemini/GEMINI.md`)

```markdown
# DevOps Agent Pack

@agents/horus.md
@agents/zeus.md

You are a DevOps assistant. Use the imported agent definitions above.

## Agent Selection
- For Terraform, Helm, GKE → follow Horus workflows
- For Kustomize, ArgoCD, GitOps → follow Zeus workflows
- Unsure → scan for .tf files (Horus) or kustomization.yaml (Zeus)
```

**Setup:** `gemini/setup.sh` symlinks skills to `.gemini/skills/` and copies agent/GEMINI.md files

**Note:** Gemini CLI natively reads SKILL.md (Agent Skills standard) from `.gemini/skills/` or `.agents/skills/` — no format conversion needed. Only agent routing (GEMINI.md) and subagent definitions need Gemini-specific format.

### `npx skills` Compatibility

For `npx skills add` to work, skills should follow the standard directory layout:

```
skills/
  terraform-validate/
    SKILL.md              ← Required (with name: and description: in frontmatter)
    scripts/              ← Optional executables
    references/           ← Optional documentation
    assets/               ← Optional templates
```

All 8 existing skills already conform to this layout.

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
- [x] `npx skills` as cross-platform package manager channel
- [x] Claude Code marketplace as secondary channel
- [x] npm package for enterprise / private registry distribution
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

### Skill Authoring

- [x] SKILL.md with YAML frontmatter (`name:`, `description:`, `version:`)
- [x] Standard directory layout (`scripts/`, `references/`, `assets/`)
- [x] Progressive disclosure (only name+description loaded at startup, ~30-50 tokens per skill)
- [x] Bundle all resources for offline/air-gapped use
- [x] Skills are immutable artifacts (content-addressed for reproducibility)

### Missing Parts to Address

- [ ] GitHub Releases automation (tag → release → changelog → assets)
- [ ] Version check at agent startup (non-blocking notification)
- [ ] `MIGRATION.md` template for major version upgrades
- [ ] End-to-end testing on Codex CLI
- [ ] End-to-end testing on Gemini CLI
- [ ] Add `version:` field to all SKILL.md frontmatter
- [ ] `npx skills` compatibility testing
- [ ] npm package publishing setup (package.json with postinstall hooks)
- [ ] Codex AGENTS.md + `.agents/skills/` setup script
- [ ] Gemini GEMINI.md + `.gemini/skills/` setup script
- [ ] Multi-language skill descriptions (EN + ZH-TW)
- [ ] `.well-known/skills/` web discovery endpoint (for documentation site)

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Agent Skills spec evolves with breaking changes | High | Pin to spec version in SKILL.md, test all 3 platforms in CI |
| Platform-specific SKILL.md extensions diverge | Medium | Use only the common subset of frontmatter fields |
| Version drift across platforms | Medium | Single VERSION file, CI enforces consistency |
| `npx skills` changes install behavior | Medium | Git clone remains as fallback; setup scripts are independent |
| Symlinks not supported on Windows | Low | `setup.sh` falls back to file copy on Windows/WSL2 |
| User forgets to update | Low | Version check notification at startup, `npx skills check` |

---

## Quick Reference: User Install Flow

### Cross-Platform (npx skills)

```bash
# Install all DevOps skills to any detected agent (Claude/Codex/Gemini)
npx skills add qwedsazxc78/devops-plugin

# Update
npx skills update
```

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
# Creates .agents/skills/ symlinks + copies AGENTS.md
```

### Google Gemini CLI

```bash
git clone https://github.com/qwedsazxc78/devops-plugin.git
cd devops-plugin && bash gemini/setup.sh
# Creates .gemini/skills/ symlinks + copies GEMINI.md + agents/
```

### Update (All Platforms)

```bash
cd devops-plugin
bash scripts/version-check.sh       # Check if update available
git pull origin main                 # Update to latest
bash codex/setup.sh                  # Re-sync Codex (if using)
bash gemini/setup.sh                 # Re-sync Gemini (if using)

# Or via npx skills (auto-detects all installed agents)
npx skills update
```

---

---

<a id="繁體中文"></a>

## 繁體中文

本文件說明將 DevOps 外掛從 Claude Code 專屬外掛，遷移為支援 **Claude Code**、**OpenAI Codex CLI** 和 **Google Gemini CLI** 的跨平台 AI Agent 技能包的計劃。

> **目標：** 一份 DevOps 技能、Agent 和工作流程的單一真相來源，分發至三個 AI 編程助手，提供平台原生體驗和無縫版本升級。

> **關鍵發現：** [Agent Skills](https://agentskills.io/specification) 現在是一個**開放標準**（2025 年 12 月發布，已被 25+ 工具採用，包括所有三個目標平台）。三個平台都原生讀取 `SKILL.md` 檔案 — skills 不需要適配層。

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
| **Skills 標準** | [Open Agent Skills](https://agentskills.io/specification)（SKILL.md） | 三個平台都原生支援同一標準 |
| **Gemini 方式** | 原生 SKILL.md + GEMINI.md 做 agent 路由 | Gemini CLI 原生讀取 SKILL.md；僅 agent 路由需適配 |
| **版本來源** | `VERSION` 檔案 + `plugin.json` + SKILL.md `version:` 欄位 | 單一真相來源，易於升版 |
| **分發方式** | Git + `npx skills` + marketplace | 多管道滿足不同使用者偏好 |

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
（原生）      （原生）     （原生）
   │            │            │
.claude/     .agents/     .gemini/
skills/      skills/      skills/
（或外掛）    （symlink）   （symlink）
```

**三個平台**都實作 Agent Skills 規範。`SKILL.md` 格式的 `name:` 和 `description:` frontmatter 在 Claude Code、Codex CLI 和 Gemini CLI 上運作完全相同。Skills 不需要適配層 — 只需要符號連結或檔案複製到各平台的預期目錄。

**差異僅在於：** agent 定義（路由邏輯）、命令呼叫語法和設定檔。這些由各平台的薄適配檔案處理。

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

**版本在四處追蹤（由 CI 保持同步）：**
1. `VERSION` 檔案（單一真相來源）
2. `.claude-plugin/plugin.json` → `"version"` 欄位
3. `CHANGELOG.md` → 最新條目標題
4. 各 `SKILL.md` → frontmatter 中的 `version:` 欄位（各 skill 獨立版本）

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

#### 方式 C：`npx skills` 套件管理器

```bash
# 檢查所有已安裝 skills 的更新
npx skills check

# 更新所有 skills 至最新版
npx skills update

# 更新特定 skill
npx skills update qwedsazxc78/devops-plugin --skill terraform-validate
```

#### 方式 D：版本檢查腳本

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
- [x] `npx skills` 作為跨平台套件管理器管道
- [x] Claude Code marketplace 作為次要管道
- [x] npm 套件用於企業 / 私有 registry 分發
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

### Skill 撰寫

- [x] SKILL.md + YAML frontmatter（`name:`、`description:`、`version:`）
- [x] 標準目錄佈局（`scripts/`、`references/`、`assets/`）
- [x] 漸進式揭露（啟動時僅載入 name+description，每個 skill 約 30-50 tokens）
- [x] 打包所有資源供離線/隔離環境使用
- [x] Skills 為不可變工件（內容定址，確保可重現性）

### 待處理項目

- [ ] GitHub Releases 自動化（tag → release → changelog → assets）
- [ ] Agent 啟動時的版本檢查（非阻塞通知）
- [ ] 重大版本升級的 `MIGRATION.md` 模板
- [ ] 在 Codex CLI 上的端到端測試
- [ ] 在 Gemini CLI 上的端到端測試
- [ ] 在所有 SKILL.md frontmatter 中新增 `version:` 欄位
- [ ] `npx skills` 相容性測試
- [ ] npm 套件發布設定（package.json + postinstall hooks）
- [ ] Codex AGENTS.md + `.agents/skills/` 設定腳本
- [ ] Gemini GEMINI.md + `.gemini/skills/` 設定腳本
- [ ] 多語言 skill 描述（EN + ZH-TW）
- [ ] `.well-known/skills/` 網頁探索端點（用於文件網站）

---

## 風險評估

| 風險 | 影響 | 緩解措施 |
|------|------|---------|
| Agent Skills 規範發生破壞性變更 | 高 | 在 SKILL.md 中固定規範版本，CI 中測試三個平台 |
| 各平台的 SKILL.md 擴展欄位分歧 | 中 | 僅使用 frontmatter 欄位的共同子集 |
| 平台間版本漂移 | 中 | 單一 VERSION 檔案，CI 強制一致性 |
| `npx skills` 變更安裝行為 | 中 | Git clone 作為備用方案；setup 腳本獨立運作 |
| Windows 不支援符號連結 | 低 | `setup.sh` 在 Windows/WSL2 上降級為檔案複製 |
| 使用者忘記更新 | 低 | 啟動時版本檢查通知、`npx skills check` |

---

## 快速參考：使用者安裝流程

### 跨平台（npx skills）

```bash
# 安裝所有 DevOps skills 至任何偵測到的 agent（Claude/Codex/Gemini）
npx skills add qwedsazxc78/devops-plugin

# 更新
npx skills update
```

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
# 建立 .agents/skills/ 符號連結 + 複製 AGENTS.md
```

### Google Gemini CLI

```bash
git clone https://github.com/qwedsazxc78/devops-plugin.git
cd devops-plugin && bash gemini/setup.sh
# 建立 .gemini/skills/ 符號連結 + 複製 GEMINI.md + agents/
```

### 更新（所有平台）

```bash
cd devops-plugin
bash scripts/version-check.sh       # 檢查是否有更新
git pull origin main                 # 更新至最新
bash codex/setup.sh                  # 重新同步 Codex（如有使用）
bash gemini/setup.sh                 # 重新同步 Gemini（如有使用）

# 或透過 npx skills（自動偵測所有已安裝的 agent）
npx skills update
```
