# asana — Asana Task Sync for DevOps Pipelines

Syncs DevOps pipeline findings to Asana as actionable tasks. Creates, updates, and tracks remediation work items with proper prioritization and due dates.

## Usage

```
/devops:asana                    # Interactive: choose pipeline results to sync
/devops:asana sync               # Sync latest pipeline report to Asana
/devops:asana sync security      # Sync security findings only
/devops:asana sync upgrade       # Sync upgrade recommendations only
/devops:asana status             # Show Asana connection status + open DevOps tasks
/devops:asana sprint             # Create sprint plan from health check results
/devops:asana close-resolved     # Mark resolved findings as complete in Asana
```

## Arguments

$ARGUMENTS — Optional: action (`sync`, `status`, `sprint`, `close-resolved`) and scope filter. Default: interactive mode.

## Instructions

### Step 0: Verify Asana API Access

Check required environment variables:

```bash
[ -n "$ASANA_ACCESS_TOKEN" ] && echo "OK" || echo "MISSING"
[ -n "$ASANA_WORKSPACE_GID" ] && echo "OK" || echo "MISSING"
[ -n "$ASANA_PROJECT_GID" ] && echo "OK" || echo "MISSING"
```

If `ASANA_ACCESS_TOKEN` is missing, show setup guide:

```
Asana integration requires API access. Quick setup:

1. Create a Personal Access Token:
   https://app.asana.com/0/my-apps

2. Set environment variables:
   export ASANA_ACCESS_TOKEN="your-token"
   export ASANA_WORKSPACE_GID="your-workspace-gid"
   export ASANA_PROJECT_GID="your-project-gid"

3. Verify:
   /devops:asana status
```

If token is set, verify connectivity:

```bash
curl -s -H "Authorization: Bearer $ASANA_ACCESS_TOKEN" \
  "https://app.asana.com/api/1.0/users/me" | jq '.data | {name, email}'
```

### Step 1: Determine Action

Based on $ARGUMENTS:

| Argument | Action |
|----------|--------|
| (none) | Interactive mode — show menu |
| `sync` | Sync latest pipeline report |
| `sync security` | Sync security findings only |
| `sync upgrade` | Sync upgrade findings only |
| `sync health` | Sync health check findings only |
| `status` | Show connection status + open tasks |
| `sprint` | Create sprint plan |
| `close-resolved` | Close resolved tasks |

#### Interactive Mode (no arguments)

```
Asana Task Sync — What would you like to do?

  1. Sync latest pipeline results to Asana
  2. Check Asana connection & open DevOps tasks
  3. Create a DevOps sprint plan
  4. Close resolved findings in Asana
  5. View sync history
```

### Step 2: Find Pipeline Results

Search for the most recent pipeline report:

```bash
# Find recent pipeline reports
find docs/examples -name "devops-*-check-*.md" -type f 2>/dev/null | sort -r | head -5
```

If no report files found, offer to run a pipeline first:

```
No recent pipeline reports found. Run a pipeline first:
  /devops:horus   → then *full or *security
  /devops:zeus    → then *full or *health-check
```

If reports exist, parse findings from the most recent one. Extract:
- Security vulnerabilities (HIGH/MEDIUM/LOW)
- Outdated versions and deprecated APIs
- Validation errors
- CI/CD gaps and recommendations

### Step 3: Create Asana Tasks

For each finding, create an Asana task via API:

```bash
curl -s -X POST "https://app.asana.com/api/1.0/tasks" \
  -H "Authorization: Bearer $ASANA_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "name": "[DevOps] {category}: {title}",
      "notes": "{description_with_remediation}",
      "workspace": "'"$ASANA_WORKSPACE_GID"'",
      "projects": ["'"$ASANA_PROJECT_GID"'"],
      "due_on": "{due_date}"
    }
  }'
```

**Priority → Due Date:**
- HIGH → +3 business days
- MEDIUM → +7 business days
- LOW → +14 business days

**Rate limiting:** 0.5s delay between API calls. Max 50 tasks per run.

Before creating, show the user a preview:

```
Found 12 findings to sync:
  HIGH:   4 (security vulnerabilities)
  MEDIUM: 5 (outdated versions, validation issues)
  LOW:    3 (CI/CD recommendations)

Create these as Asana tasks?
  1. Create all 12 tasks
  2. Create HIGH only (4 tasks)
  3. Create HIGH + MEDIUM (9 tasks)
  4. Review each finding first
  5. Cancel
```

### Step 4: Present Results

Show summary dashboard:

```
+-------------------------------------------------------------+
| Asana Sync Complete                                         |
+-------------------------------------------------------------+
| Source: devops-zeus-full-check-2026-03-09.md                |
| Project: DevOps Remediation                                 |
+-------------------------------------------------------------+
| Tasks Created:                                              |
|   HIGH:   4 tasks (due: 2026-03-12)                        |
|   MEDIUM: 5 tasks (due: 2026-03-16)                        |
|   LOW:    3 tasks (due: 2026-03-23)                        |
|   Total:  12 tasks                                          |
+-------------------------------------------------------------+
```

Then show task list with links:

```
| # | Priority | Category | Task | Link |
|---|----------|----------|------|------|
| 1 | HIGH | security | Pod running as root | https://app.asana.com/... |
| 2 | HIGH | security | Missing NetworkPolicy | https://app.asana.com/... |
| ...
```

### Action: `status`

Show Asana connection info and open DevOps tasks:

```bash
# Get workspace info
curl -s -H "Authorization: Bearer $ASANA_ACCESS_TOKEN" \
  "https://app.asana.com/api/1.0/workspaces/$ASANA_WORKSPACE_GID" | jq '.data.name'

# Get open DevOps tasks
curl -s -H "Authorization: Bearer $ASANA_ACCESS_TOKEN" \
  "https://app.asana.com/api/1.0/tasks?project=$ASANA_PROJECT_GID&completed_since=now&opt_fields=name,due_on,completed" \
  | jq '[.data[] | select(.name | startswith("[DevOps]"))] | length'
```

Present:

```
+-------------------------------------------------------------+
| Asana Connection Status                                     |
+-------------------------------------------------------------+
| User:      John Doe                                         |
| Workspace: My Team                                          |
| Project:   DevOps Remediation                               |
+-------------------------------------------------------------+
| Open DevOps Tasks:                                          |
|   HIGH:   3 overdue, 2 on track                            |
|   MEDIUM: 4 on track                                        |
|   LOW:    1 on track                                        |
|   Total:  10 open tasks                                     |
+-------------------------------------------------------------+
```

### Action: `sprint`

1. Run both `*health` (Horus) and `*health-check` (Zeus) if not recently run
2. Aggregate all findings
3. Sort by priority
4. Create an Asana section for the sprint
5. Add tasks under the section

```bash
# Create a section for the sprint
curl -s -X POST "https://app.asana.com/api/1.0/sections" \
  -H "Authorization: Bearer $ASANA_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "name": "DevOps Sprint — 2026-03-09",
      "project": "'"$ASANA_PROJECT_GID"'"
    }
  }'
```

### Action: `close-resolved`

1. Fetch all open `[DevOps]` tasks from Asana
2. Run relevant pipeline checks to see which findings are resolved
3. For resolved findings, mark the Asana task as complete:

```bash
curl -s -X PUT "https://app.asana.com/api/1.0/tasks/{task_gid}" \
  -H "Authorization: Bearer $ASANA_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"data": {"completed": true}}'
```

4. Add a completion comment noting the resolution

### Graceful Degradation

- `ASANA_ACCESS_TOKEN` missing → show setup guide, do not block
- `ASANA_PROJECT_GID` missing → list available projects and let user choose
- API unreachable → save tasks as JSON to `docs/asana-tasks-{date}.json`
- Rate limited (429) → pause and retry with backoff
- No pipeline reports → suggest running a pipeline first
- Never fail silently — always show what happened and next steps
