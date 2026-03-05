# tf-validate — Terraform Validation & Linting Skill

Comprehensive validation and linting of Terraform configurations. Covers syntax, formatting, schema validation, cross-file consistency, and naming conventions.

## Usage

```
tf-validate                # Validate entire Terraform root
tf-validate path/to/root   # Validate a specific Terraform root directory
```

## Arguments

$ARGUMENTS --- Optional: path to Terraform root directory. Default: auto-discovered.

## Instructions

### Step 0: Discover Terraform Root

Dynamically locate the Terraform root directory:

1. If `$ARGUMENTS` provides a path, use that directly.
2. Otherwise, search for directories containing `*.tf` files with a `main.tf` or `versions.tf`:
   ```bash
   find . -maxdepth 3 -name "main.tf" -o -name "versions.tf" | head -20
   ```
3. Look for common patterns: `application/`, `terraform/`, `infra/`, or the repository root.
4. Identify the Terraform root as the directory containing backend configuration (`backend` block in `*.tf`).

Also discover:
- Module directories: `modules/helm/*/` under the Terraform root
- JSON config files: `infra/*.json` (if `infra/` directory exists)
- Pre-commit config: `.pre-commit-config.yaml` at repository root
- TFLint config: `.tflint.hcl` at repository root

### Step 1: Terraform Format Check

Run `terraform fmt -check -recursive` on the Terraform root:

```bash
cd <TF_ROOT> && terraform fmt -check -recursive
```

**Output:** List files that need formatting. Offer to auto-fix with `terraform fmt -recursive`.

### Step 2: Terraform Validate

Run `terraform validate` on the Terraform root:

```bash
cd <TF_ROOT> && terraform init -backend=false && terraform validate
```

**Note:** Use `-backend=false` since backends may require credentials. Validation checks syntax and internal consistency without needing state access.

**Common errors to watch for:**
- Missing required variables
- Invalid resource references
- Module source path errors
- Type constraint violations

### Step 3: JSON Schema Validation

If an `infra/schema/` directory exists with a JSON schema file:

1. Discover all JSON config files (e.g., `infra/*-app.json`)
2. Read the schema file
3. Verify all `required` fields are present in each config
4. Verify field types match schema definitions
5. Verify nested object and array schemas

**Report:** List any missing fields, type mismatches, or extra fields not in schema. If no schema directory exists, skip this step.

### Step 4: Cross-File Consistency Checks

#### 4a: Helm Version Consistency

For each active module in the main GKE package file (e.g., `3-gke-package.tf`), verify `install_version` matches across:
1. The module block `install_version`
2. `modules/helm/<name>/variable(s).tf` default value
3. `modules/helm/helm_install.md` `--version` value

**Dynamic discovery:** Check if `variable.tf` (singular) exists; if not, use `variables.tf` (plural).

#### 4b: Module Source Path Consistency

Verify every `source = "./modules/helm/<name>"` path points to a directory that actually exists.

#### 4c: Environment Config Completeness

For modules that use `configs-${var.environment}.yaml`, verify config files exist for all environments:
- If module has `environment` variable, check for configs-dev.yaml, configs-stg.yaml, configs-prd.yaml
- If module has `dr` variable, check for DR config variants

#### 4d: Workload Identity Alignment

Cross-reference workload identity definitions with module dependencies. Flag modules that depend on workload identity namespace but are not registered, or vice versa.

#### 4e: GKE Module Version Consistency

Verify the `version` in GKE modules matches across identity and cluster definitions.

### Step 5: Naming Convention Audit

If a `NAMING_CONVENTIONS.md` exists in the skill or repository, audit:
- Resource naming patterns
- Variable naming patterns
- Module naming patterns
- File naming patterns

Report violations as warnings.

### Step 6: TFLint Check

1. Check if `.tflint.hcl` exists at the repository root
2. Report current rules from the config
3. Check if TFLint is enabled in `.pre-commit-config.yaml`
4. If `tflint` is installed, run it:
   ```bash
   cd <TF_ROOT> && tflint --init && tflint
   ```

### Step 7: Pre-Commit Hook Verification

Check `.pre-commit-config.yaml` status:
1. Verify the file exists and is valid YAML
2. Report which hooks are active vs commented out
3. Suggest enabling commented hooks (tflint, tfsec, detect-secrets) if appropriate

### Step 8: Results Report

Generate a validation report:

```
## Terraform Validation Report

### Format Check
- [PASS/FAIL] terraform fmt -- N files need formatting

### Syntax Validation
- [PASS/FAIL] terraform validate -- N errors found

### Schema Validation
- [PASS/FAIL] <env>-app.json -- compliant / missing field X

### Cross-File Consistency
- [PASS/FAIL] Helm versions -- N mismatches
- [PASS/FAIL] Module sources -- all paths valid
- [PASS/FAIL] Environment configs -- N missing files
- [PASS/FAIL] Workload identity -- aligned
- [PASS/FAIL] GKE module version -- consistent

### Naming Conventions
- [PASS/WARN] N naming issues found

### TFLint
- [PASS/SKIP] N issues / not installed

### Recommendations
- (list of actionable next steps)
```

## Graceful Degradation

- If `terraform` is not installed: FAIL immediately with install instructions (`brew install terraform` or `brew install tfenv`)
- If `tflint` is not installed: skip Step 6 TFLint execution, suggest `brew install tflint`
- If `yamllint` is not installed for pre-commit check: skip YAML portion, suggest `pip install yamllint`
- If JSON schema file does not exist: skip Step 3 entirely
- Never block the entire validation because one optional tool is missing -- skip that check and show the install command
- Minimum viable validation: `terraform fmt -check` + `terraform validate` (terraform binary is required)
