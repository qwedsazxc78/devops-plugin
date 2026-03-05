# Terraform Validate Skill

## Purpose

Comprehensive validation and linting of Terraform configurations for Terraform+Helm platforms. Covers syntax, formatting, schema validation, cross-file consistency, and naming conventions.

## Activation

This skill activates when the user requests:
- Validating Terraform configuration
- Checking formatting / linting
- Verifying cross-file consistency
- Running a pre-commit check
- Auditing naming conventions

## Workflow

### Step 1: Terraform Format Check

Run `terraform fmt -check -recursive` on the `application/` directory.

```bash
cd application && terraform fmt -check -recursive
```

**Output:** List of files that need formatting. Offer to auto-fix with `terraform fmt -recursive`.

### Step 2: Terraform Validate

Run `terraform validate` on the `application/` directory.

```bash
cd application && terraform init -backend=false && terraform validate
```

**Note:** Use `-backend=false` since the HTTP backend requires credentials. Validation checks syntax and internal consistency without needing state access.

**Common errors to watch for:**
- Missing required variables
- Invalid resource references
- Module source path errors
- Type constraint violations

### Step 3: JSON Schema Validation

Validate all `infra/*.json` files against `infra/schema/app-config.schema.json`.

**Files to validate:**
- Discover all `infra/*-app.json` files dynamically

**Validation approach:**
1. Read the schema from `infra/schema/app-config.schema.json`
2. Read each environment JSON file
3. Verify all `required` fields are present
4. Verify field types match schema definitions
5. Verify nested object schemas
6. Verify array items match `$def` definitions

**Report:** List any missing fields, type mismatches, or extra fields not in schema.

### Step 4: Cross-File Consistency Checks

#### 4a: Helm Version Consistency

For each active module in `3-gke-package.tf`, verify the `install_version` matches across:
1. `3-gke-package.tf` -> module block `install_version`
2. `modules/helm/<name>/variable(s).tf` -> `install_version` default
3. `modules/helm/helm_install.md` -> `--version` in helm command

**Dynamic discovery:** For each module, check if `variable.tf` (singular) exists; if not, use `variables.tf` (plural). Do NOT rely on a static registry file.

#### 4b: Module Source Path Consistency

Verify every `source = "./modules/helm/<name>"` path in `3-gke-package.tf` points to a directory that actually exists.

#### 4c: Environment Config Completeness

For modules that use `configs-${var.environment}.yaml`, verify that config files exist for all environments the module claims to support:
- If module has `environment` variable -> check configs-dev.yaml, configs-stg.yaml, configs-prd.yaml exist
- If module has `dr` variable -> check configs-dev-dr.yaml, configs-prd-dr.yaml exist (where applicable)

#### 4d: Workload Identity Alignment

Cross-reference:
- `3-gke-identity.tf` -> `local.workload_namespace` list
- `3-gke-identity.tf` -> workload identity module definitions
- `3-gke-package.tf` -> modules with `depends_on` including `kubernetes_namespace.workload_identity`

Flag any modules that depend on workload identity namespace but aren't in the namespace list, or vice versa.

#### 4e: GKE Module Version Consistency

Verify the `version` in the GKE module (`3-gke.tf`) matches the `version` in all workload identity modules (`3-gke-identity.tf`).

### Step 5: Naming Convention Audit

Run naming convention checks per NAMING_CONVENTIONS.md:
- Resource naming patterns
- Variable naming patterns
- Module naming patterns
- File naming patterns

### Step 6: TFLint Check

Check if `.tflint.hcl` exists at the repository root.

1. Report current rules from the existing `.tflint.hcl` (see TFLINT_RULES.md for details)
2. Suggest additional rules from TFLINT_RULES.md "Recommended Additions" section
3. Check if TFLint is enabled in `.pre-commit-config.yaml`

### Step 7: Pre-Commit Hook Verification

Check `.pre-commit-config.yaml` status:
1. Verify the file exists and is valid YAML
2. Report which hooks are active vs commented out
3. Suggest enabling commented hooks (tflint, tfsec, detect-secrets) if appropriate

### Step 8: Report

Generate a validation report:

```
## Validation Report

### Format Check
- [PASS/FAIL] terraform fmt — N files need formatting

### Syntax Validation
- [PASS/FAIL] terraform validate — N errors found

### Schema Validation
- [PASS/FAIL] <env>-app.json — compliant / missing field X

### Cross-File Consistency
- [PASS/FAIL] Helm versions — N mismatches
- [PASS/FAIL] Module sources — all paths valid
- [PASS/FAIL] Environment configs — N missing files
- [PASS/FAIL] Workload identity — aligned
- [PASS/FAIL] GKE module version — consistent

### Naming Conventions
- [PASS/WARN] N naming issues found

### Recommendations
- Enable tflint in pre-commit
- Enable tfsec in pre-commit
```

## Light Mode

When invoked from the `*validate` pipeline with "light" security scan:
- Skip Steps 6-7 (TFLint and pre-commit checks)
- Only report critical findings

## Auto-Fix Capabilities

The skill can auto-fix:
- Formatting issues (`terraform fmt`)
- Version mismatches (align to `3-gke-package.tf` as source of truth)

The skill CANNOT auto-fix:
- Schema validation errors (require understanding of environment requirements)
- Missing config files (require domain knowledge for values)
- Naming convention violations (may have intentional exceptions)

## Dependencies

- TFLINT_RULES.md — Recommended TFLint rules
- NAMING_CONVENTIONS.md — Extracted naming patterns
