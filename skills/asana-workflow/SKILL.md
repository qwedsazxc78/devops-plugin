---
name: asana-workflow
description: >
  Integrates Asana project management with DevOps pipeline workflows.
  Creates, updates, and tracks Asana tasks based on pipeline results,
  security findings, upgrade recommendations, and health check outcomes.
  Use when syncing DevOps pipeline outputs to Asana for team tracking.
---

# Asana Workflow Skill

## Purpose

Bridges DevOps pipeline results with Asana project management. Converts pipeline findings (security issues, upgrade recommendations, health check failures, CI/CD gaps) into actionable Asana tasks with proper prioritization, assignees, and due dates.

## Activation

This skill activates when the user requests:
- Creating Asana tasks from pipeline results
- Syncing DevOps findings to Asana
- Tracking remediation work in Asana
- Generating Asana task templates from audit reports

## Prerequisites

### Asana CLI or API Access

This skill uses the Asana REST API via `curl`. The user must provide:

1. **Asana Personal Access Token (PAT)** — stored as environment variable `ASANA_ACCESS_TOKEN`
2. **Asana Workspace GID** — stored as environment variable `ASANA_WORKSPACE_GID`
3. **Asana Project GID** (optional) — stored as environment variable `ASANA_PROJECT_GID`

```bash
# Verify Asana API access
curl -s -H "Authorization: Bearer $ASANA_ACCESS_TOKEN" \
  "https://app.asana.com/api/1.0/users/me" | jq '.data.name'
```

> **Security:** Never hardcode tokens in files. Always use environment variables. This skill will refuse to execute if tokens appear in any file content.

## Step 0: Verify Asana Configuration

Check that required environment variables are set:

```bash
# Check token exists (do NOT print the value)
[ -n "$ASANA_ACCESS_TOKEN" ] && echo "ASANA_ACCESS_TOKEN: set" || echo "ASANA_ACCESS_TOKEN: NOT SET"
[ -n "$ASANA_WORKSPACE_GID" ] && echo "ASANA_WORKSPACE_GID: set" || echo "ASANA_WORKSPACE_GID: NOT SET"
[ -n "$ASANA_PROJECT_GID" ] && echo "ASANA_PROJECT_GID: set (optional)" || echo "ASANA_PROJECT_GID: not set (will prompt)"
```

If `ASANA_ACCESS_TOKEN` is not set, show setup instructions:

```
Asana API access required. Set up:

1. Go to https://app.asana.com/0/my-apps → Create a Personal Access Token
2. Export the token:
   export ASANA_ACCESS_TOKEN="your-token-here"
3. Find your workspace GID:
   curl -s -H "Authorization: Bearer $ASANA_ACCESS_TOKEN" \
     "https://app.asana.com/api/1.0/workspaces" | jq '.data[] | {gid, name}'
4. Export the workspace GID:
   export ASANA_WORKSPACE_GID="your-workspace-gid"
5. (Optional) Export a default project GID:
   export ASANA_PROJECT_GID="your-project-gid"
```

## Step 1: Parse Pipeline Results

Accept pipeline output from any DevOps plugin pipeline and extract actionable items:

### Input Sources

| Source Pipeline | Finding Type | Default Priority |
|----------------|-------------|-----------------|
| `*security` / `security-scan` | Security vulnerabilities | HIGH |
| `*upgrade` / `upgrade-check` | Outdated versions, deprecated APIs | MEDIUM |
| `*health` / `*health-check` | Health check failures | HIGH |
| `*full` | Combined findings | Varies |
| `*validate` | Validation errors | MEDIUM |
| `cicd-check` | CI/CD pipeline gaps | LOW |

### Extraction Rules

For each finding, extract:
- **Title**: Concise summary (max 100 chars)
- **Description**: Full finding details with remediation steps
- **Priority**: HIGH / MEDIUM / LOW (mapped to Asana custom field or tag)
- **Category**: security / upgrade / health / validation / cicd
- **Source**: Pipeline name and step that produced the finding

## Step 2: Generate Asana Task Payloads

For each extracted finding, build an Asana API task payload:

```json
{
  "data": {
    "name": "[DevOps] {category}: {title}",
    "notes": "## Finding\n\n{description}\n\n## Source\n\nPipeline: {pipeline}\nStep: {step}\nDate: {date}\n\n## Remediation\n\n{remediation_steps}",
    "workspace": "{ASANA_WORKSPACE_GID}",
    "projects": ["{ASANA_PROJECT_GID}"],
    "tags": [],
    "due_on": "{calculated_due_date}"
  }
}
```

### Priority → Due Date Mapping

| Priority | Due Date | Asana Tag |
|----------|----------|-----------|
| HIGH | +3 business days | `urgent`, `devops-high` |
| MEDIUM | +7 business days | `devops-medium` |
| LOW | +14 business days | `devops-low` |

## Step 3: Create Tasks via Asana API

For each task payload, create the task:

```bash
curl -s -X POST "https://app.asana.com/api/1.0/tasks" \
  -H "Authorization: Bearer $ASANA_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{payload_json}' | jq '{gid: .data.gid, name: .data.name, permalink_url: .data.permalink_url}'
```

### Rate Limiting

Asana API has rate limits (150 requests/minute for PAT). Respect them:
- Batch task creation with 0.5s delay between requests
- If 429 response received, wait for `Retry-After` header value
- Maximum 50 tasks per execution to prevent spam

## Step 4: Present Summary

After all tasks are created, show a summary dashboard:

```
+-------------------------------------------------------------+
| Asana Task Sync — Summary                                   |
+-------------------------------------------------------------+
| Pipeline: *security (2026-03-09)                            |
| Project:  DevOps Remediation                                |
+-------------------------------------------------------------+
| Created Tasks:                                              |
|   HIGH:   3 tasks (due: 2026-03-12)                        |
|   MEDIUM: 5 tasks (due: 2026-03-16)                        |
|   LOW:    2 tasks (due: 2026-03-23)                        |
|   Total:  10 tasks                                          |
+-------------------------------------------------------------+
| Links:                                                      |
|   https://app.asana.com/0/{project_gid}/list                |
+-------------------------------------------------------------+
```

Then list each created task with its Asana link:

```
| # | Priority | Task | Asana Link |
|---|----------|------|------------|
| 1 | HIGH | [DevOps] security: Pod running as root in payment-api | https://app.asana.com/0/0/{gid} |
| 2 | HIGH | [DevOps] security: Hardcoded secret in config.yaml | https://app.asana.com/0/0/{gid} |
| 3 | MEDIUM | [DevOps] upgrade: CoreDNS outdated (1.10→1.11) | https://app.asana.com/0/0/{gid} |
| ...
```

## Supported Workflows

### Workflow A: Pipeline → Asana (Auto-Sync)

After any pipeline run, automatically offer to sync findings to Asana:

```
Pipeline complete. 8 findings detected.
Would you like to create Asana tasks for these findings?
  1. Create all 8 tasks
  2. Create HIGH priority only (3 tasks)
  3. Review findings first, then choose
  4. Skip — do not create tasks
```

### Workflow B: Batch Sync (Manual)

User explicitly requests sync of existing pipeline report:

```
User: "Sync the last security scan results to Asana"
→ Read the most recent pipeline report from docs/examples/
→ Parse findings
→ Create tasks
```

### Workflow C: Task Status Update

Update existing Asana tasks based on new pipeline results:

```bash
# Search for existing DevOps tasks in the project
curl -s -H "Authorization: Bearer $ASANA_ACCESS_TOKEN" \
  "https://app.asana.com/api/1.0/tasks?project=$ASANA_PROJECT_GID&opt_fields=name,completed,tags" \
  | jq '.data[] | select(.name | startswith("[DevOps]"))'
```

If a finding from the current run matches an existing open task:
- **Still present**: Add a comment with the latest scan date
- **Resolved**: Mark the task as complete with a resolution comment

### Workflow D: Sprint Planning Helper

Generate a prioritized task list for sprint planning:

```
User: "Create a DevOps sprint plan in Asana"
→ Run *health (Horus) + *health-check (Zeus)
→ Aggregate all findings
→ Sort by priority
→ Create an Asana section "DevOps Sprint — {date}"
→ Add tasks under the section
```

## Graceful Degradation

- If `ASANA_ACCESS_TOKEN` is not set → show setup instructions, do not block pipeline
- If `ASANA_PROJECT_GID` is not set → prompt user to select from available projects
- If Asana API is unreachable → save task payloads to `docs/asana-tasks-{date}.json` for manual import
- If rate limited → pause, complete remaining tasks, report partial results
- Never fail the parent pipeline due to Asana sync issues

## Security

- **NEVER** log or display the Asana access token
- **NEVER** store tokens in any file in the repository
- All API calls use HTTPS only
- Task descriptions should not include raw secrets found during security scans — reference the finding location only
