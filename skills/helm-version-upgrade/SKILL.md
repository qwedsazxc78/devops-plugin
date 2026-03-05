# Helm Version Upgrade Skill

## Purpose

Manages Helm chart version upgrades across Terraform+Helm platforms. Handles the **atomic 3-file update** pattern: `3-gke-package.tf` + `modules/helm/<name>/variable(s).tf` + `modules/helm/helm_install.md`.

## Activation

This skill activates when the user requests:
- Checking for outdated Helm charts
- Upgrading a specific Helm chart version
- Upgrading all Helm charts
- Checking version consistency across the 3 files

## Dynamic Module Discovery

**Do NOT rely on a static registry file.** Discover modules at runtime:

1. Parse `3-gke-package.tf` for all `module "<name>"` blocks with `source = "./modules/helm/<name>"`
2. For each module, determine the variable file:
   - Check if `modules/helm/<name>/variable.tf` exists (singular)
   - If not, use `modules/helm/<name>/variables.tf` (plural)
3. To find ArtifactHub slugs, read each module's `main.tf` and extract `repository` + `chart` fields from the `helm_release` resource
4. For OCI charts (no `repository` field), extract `chart = "oci://..."` URL
5. Skip commented-out module blocks (lines starting with `#`)

## Workflow

### Step 1: Determine Scope

Ask the user which modules to check:
- **Single module**: e.g., "upgrade grafana"
- **Category**: e.g., "upgrade monitoring stack" — discover by reading module namespaces
- **All**: Discover and check every active module via dynamic discovery

### Step 2: Read Current Versions

Parse `3-gke-package.tf` to extract current `install_version` for each module block. Use dynamic discovery to build the module list.

### Step 3: Verify 3-File Consistency

For each module in scope, verify the version matches across all 3 locations:

| Location | How to find version |
|----------|-------------------|
| `3-gke-package.tf` | `install_version = "X.Y.Z"` in the module block |
| `modules/helm/<name>/variable(s).tf` | `default = "X.Y.Z"` in the `install_version` variable |
| `modules/helm/helm_install.md` | `--version X.Y.Z` in the helm command |

**CRITICAL:** Some modules use `variable.tf` (singular) and others use `variables.tf` (plural). Use dynamic discovery (check file existence) to determine the correct filename.

If any mismatch is found:
1. Report the inconsistency with exact values from each file
2. Ask user whether to fix the mismatch first or proceed with upgrade
3. If fixing, align all 3 files to the version in `3-gke-package.tf` (source of truth)

### Step 4: Query Latest Versions

For each module, derive the ArtifactHub slug from the module's `main.tf`:
- Extract `repository` URL and `chart` name from the `helm_release` resource
- Map repository URL to ArtifactHub owner (e.g., `https://grafana.github.io/helm-charts` → owner `grafana`)
- Query ArtifactHub API:

```
GET https://artifacthub.io/api/v1/packages/helm/{owner}/{chart}
```

**Response parsing:**
- Extract `version` field from the response (this is the latest version)
- Extract `app_version` for informational display
- Note any `deprecated` flags

**For OCI-only charts** where ArtifactHub may not have data:
- Note that manual checking is required
- Provide the OCI registry URL for the user to check manually
- Extract OCI URL from the module's `chart` field in `main.tf`

### Step 5: Present Comparison Table

Display results in a table:

```
| Module               | Current   | Latest    | Change Type | Notes          |
|---------------------|-----------|-----------|-------------|----------------|
| argocd              | 9.2.4     | 9.3.0     | Minor       |                |
| grafana             | 10.5.4    | 10.5.4    | Up to date  |                |
| litellm             | 1.81.8... | ???       | OCI-manual  | Check manually |
```

**Change Type classification:**
- `Up to date` — same version
- `Patch` — only Z changed (X.Y.Z)
- `Minor` — Y changed
- `Major` — X changed (highlight with warning)
- `OCI-manual` — cannot auto-check

### Step 6: User Confirms Updates

Present the list of available upgrades and ask user to confirm:
- Which modules to upgrade
- Whether to accept major version bumps (warn about breaking changes)
- Option to skip specific modules

### Step 7: Atomic 3-File Update

For each confirmed module, update all 3 files atomically:

**File 1: `3-gke-package.tf`**
- Find the module block by matching `source = "./modules/helm/<name>"`
- Update `install_version = "<new_version>"`
- For multi-instance modules (same source, multiple blocks), update ALL instances

**File 2: `modules/helm/<name>/variable(s).tf`**
- Find the `install_version` variable block
- Update `default = "<new_version>"`
- Use the correct filename discovered dynamically

**File 3: `modules/helm/helm_install.md`**
- Find the section for this module (by heading or helm command)
- Update `--version <new_version>` in the helm command

See UPGRADE_PATTERNS.md for exact regex patterns and edge cases per module.

### Step 8: Summary

After all updates:
1. List all modules updated with old -> new versions
2. Provide ArtifactHub links for release notes
3. Remind user to run `terraform validate` and `terraform plan`

## Check-Only Mode

When invoked with check-only (e.g., from `*health` pipeline):
- Execute Steps 1-5 only
- Do NOT modify any files
- Return the comparison table for reporting

## Edge Cases

- **Commented modules**: Skip commented-out module blocks. Note in output.
- **Multi-instance modules**: Multiple module blocks sharing the same `source`. Update ALL instances in `3-gke-package.tf` and the one shared `variables.tf`.
- **OCI charts**: Different helm_release pattern — `chart` field contains full OCI URL instead of `repository` + `chart`.
- **Nightly versions**: Semver parsing needs to handle pre-release suffixes (e.g., `1.81.8-nightly-latest`).
- **Version in module block comment**: Ignore comments, only update the `install_version` value.

## Dependencies

- UPGRADE_PATTERNS.md — File-specific regex patterns and edge cases
