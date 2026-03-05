# helm-upgrade — Helm Version Upgrade Skill

Manages Helm chart version upgrades across Terraform+Helm platforms. Handles version discovery via ArtifactHub API and the atomic 3-file update pattern.

## Usage

```
helm-upgrade              # Check all modules for available upgrades
helm-upgrade check        # Check-only mode (no modifications)
helm-upgrade grafana      # Upgrade a specific module
helm-upgrade monitoring   # Upgrade modules in a category
```

## Arguments

$ARGUMENTS --- Optional: module name, category name, or `check` for check-only mode. Default: interactive (check all, then prompt for upgrades).

## Instructions

### Step 0: Discover Modules

Dynamically discover all Helm modules at runtime. Do NOT rely on a static registry file.

1. Find the main Terraform package file that defines Helm module blocks:
   ```bash
   find . -maxdepth 3 -name "*.tf" | xargs grep -l 'source.*modules/helm' 2>/dev/null
   ```
2. Parse that file for all `module "<name>"` blocks with `source = "./modules/helm/<name>"`
3. Skip commented-out module blocks (lines starting with `#`)
4. For each module, determine the variable file:
   - Check if `modules/helm/<name>/variable.tf` exists (singular)
   - If not, use `modules/helm/<name>/variables.tf` (plural)
5. Find the manual install reference file (`helm_install.md`) for the third file in the atomic update
6. For ArtifactHub slugs, read each module's `main.tf` and extract `repository` + `chart` fields from the `helm_release` resource
7. For OCI charts (no `repository` field), extract `chart = "oci://..."` URL

### Step 1: Determine Scope

Parse `$ARGUMENTS`:
- No args or `check` -- all discovered modules
- A module name -- single module matching that name
- A category -- modules matching that namespace/group (discover by reading module namespaces)

If `$ARGUMENTS` is `check`, set **check-only mode** (no file modifications, Steps 5-7 are skipped).

### Step 2: Read Current Versions

For each module in scope, extract the current `install_version` from the package Terraform file.

### Step 3: Verify 3-File Consistency

For each module, verify the version matches across all 3 locations:

| Location | How to find version |
|----------|-------------------|
| Package `.tf` file | `install_version = "X.Y.Z"` in the module block |
| `modules/helm/<name>/variable(s).tf` | `default = "X.Y.Z"` in the `install_version` variable |
| `helm_install.md` | `--version X.Y.Z` in the helm command |

If any mismatch is found:
1. Report the inconsistency with exact values from each file
2. Ask user whether to fix the mismatch first or proceed with upgrade
3. If fixing, align all 3 files to the version in the package `.tf` file (source of truth)

### Step 4: Query Latest Versions

For each module, derive the ArtifactHub query from the module's `main.tf`:
- Extract `repository` URL and `chart` name from `helm_release` resource
- Map repository URL to ArtifactHub owner
- Query ArtifactHub API:

```
GET https://artifacthub.io/api/v1/packages/helm/{owner}/{chart}
```

**Response parsing:**
- Extract `version` field (latest version)
- Extract `app_version` for informational display
- Note any `deprecated` flags

**For OCI-only charts** (ArtifactHub may not have data):
- Note that manual checking is required
- Provide the OCI registry URL for the user

### Step 5: Present Comparison Table

```
| Module          | Current   | Latest    | Change Type | Notes          |
|-----------------|-----------|-----------|-------------|----------------|
| argocd          | 9.2.4     | 9.3.0     | Minor       |                |
| grafana         | 10.5.4    | 10.5.4    | Up to date  |                |
| litellm         | 1.81.8... | ???       | OCI-manual  | Check manually |
```

**Change Type classification:**
- `Up to date` -- same version
- `Patch` -- only Z changed (X.Y.Z)
- `Minor` -- Y changed
- `Major` -- X changed (highlight with warning)
- `OCI-manual` -- cannot auto-check

If in check-only mode, stop here and output the table.

### Step 6: User Confirms Updates

Present the list of available upgrades and ask user to confirm:
- Which modules to upgrade
- Whether to accept major version bumps (warn about breaking changes)
- Option to skip specific modules

### Step 7: Atomic 3-File Update

For each confirmed module, update all 3 files:

**File 1: Package `.tf` file**
- Find the module block by matching `source = "./modules/helm/<name>"`
- Update `install_version = "<new_version>"`
- For multi-instance modules (same source, multiple blocks), update ALL instances

**File 2: `modules/helm/<name>/variable(s).tf`**
- Find the `install_version` variable block
- Update `default = "<new_version>"`
- Use the correct filename discovered in Step 0

**File 3: `helm_install.md`**
- Find the section for this module
- Update `--version <new_version>` in the helm command

### Step 8: Summary

After all updates:
1. List all modules updated with old -> new versions
2. Provide ArtifactHub links for release notes
3. Remind user to run `terraform validate` and `terraform plan`

## Graceful Degradation

- If `curl` or web access is unavailable for ArtifactHub queries: skip Step 4, report versions as "unknown", still perform consistency checks (Steps 2-3)
- If `helm_install.md` does not exist: perform 2-file update instead (package `.tf` + variables file), note the missing file
- If the package `.tf` file cannot be found: FAIL with a message explaining the expected file structure
- If a module's `main.tf` does not contain a `helm_release` resource: skip ArtifactHub lookup for that module, flag as non-standard
- For OCI charts where ArtifactHub has no data: mark as `OCI-manual` and provide the registry URL
- Never block the entire upgrade check because one module fails -- skip that module and continue
- Minimum viable check: parse package `.tf` file + verify 3-file consistency (no network access needed)
