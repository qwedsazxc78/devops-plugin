# DevOps Plugin for Claude Code

DevOps operations agents for Infrastructure-as-Code platforms using Terraform + Helm + GKE.

## Agents

### Horus — IaC Operations Engineer

The all-seeing guardian of infrastructure integrity. Pipeline-driven, safety-first operations.

## Installation

### Option 1: From Marketplace (recommended)

```
/plugin install devops
```

The plugin auto-updates when new versions are published to the marketplace.

### Option 2: From Git Repository

```bash
# Clone the plugin
git clone https://github.com/<org>/devops-plugin.git

# Run Claude Code with the plugin
claude --plugin-dir ./devops-plugin
```

### Option 3: Project-level (shared with team)

Add to your project's `.claude/plugins.json`:

```json
{
  "plugins": [
    {
      "name": "devops",
      "source": "marketplace"
    }
  ]
}
```

Or for Git-based installation, add to `.claude/plugins.json`:

```json
{
  "plugins": [
    {
      "name": "devops",
      "source": "git",
      "url": "https://github.com/<org>/devops-plugin.git"
    }
  ]
}
```

## Quick Start

```
/devops:horus          # Start Horus agent
*help                  # Show available pipelines
```

### Horus Pipelines

| Command | Purpose |
|---------|---------|
| `*full` | Full pipeline check with YAML step records + markdown report |
| `*upgrade` | Upgrade Helm chart versions (atomic 3-file update) |
| `*security` | Security audit (GKE + Helm + IAM) |
| `*validate` | Full validation (fmt + schema + consistency) |
| `*new-module` | Scaffold a new Helm module |
| `*cicd` | CI/CD pipeline improvement |
| `*health` | Platform health dashboard |

### Skills (auto-invoked by agent)

| Skill | Purpose |
|-------|---------|
| helm-version-upgrade | Check/upgrade Helm versions across 3 files |
| terraform-validate | Format, schema, consistency checks |
| terraform-security | GKE hardening, IAM, Helm security |
| cicd-enhancer | CI/CD analysis and improvement |
| helm-scaffold | Generate new Helm modules (5 patterns) |

## Requirements

- Claude Code v1.0.33+
- Terraform CLI (for `*full` pipeline exec steps)
- Repository with Terraform + Helm module structure:
  - `3-gke-package.tf` — Helm deployments as modules
  - `modules/helm/*/` — Individual Helm chart modules
  - `modules/helm/helm_install.md` — Manual install docs

## Updating

### Marketplace installs

Auto-updates are handled by Claude Code. New versions are picked up automatically.

To check your current version:
```
/plugin list
```

### Git-based installs

```bash
cd devops-plugin && git pull
```

Restart Claude Code to pick up changes.

## Design Principles

- **Dynamic discovery** — Modules are discovered at runtime from `3-gke-package.tf`, no static registry needed
- **Portable** — Works on any Terraform+Helm repo following the module pattern
- **Safety-first** — Always validates before applying, always scans before deploying

## Future Agents

- **Zeus** — GitOps operations (planned)

## License

MIT
