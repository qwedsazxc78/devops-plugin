# lint — Quick Lint Skill

Quick YAML linting and Kustomize build validation across all discovered modules and environments.

## Usage

```
lint              # Lint everything
lint dev          # Lint only dev environment
lint my-module    # Lint only a specific module
```

## Arguments

$ARGUMENTS — Optional: environment name or module name. Default: all.

## Instructions

### Step 0: Discover Modules and Environments

Discover Kustomize modules by finding directories that contain a `base/` and `overlays/` subdirectory structure. For each discovered module, discover environments by listing subdirectories under that module's `overlays/` directory.

Example discovery:
```bash
# Find all Kustomize modules (directories with base/ and overlays/ children)
for dir in $(find . -maxdepth 2 -type d -name overlays); do
  module="$(dirname "$dir")"
  if [ -d "$module/base" ]; then
    echo "Module: $module"
    ls "$module/overlays/"  # Lists environments
  fi
done
```

### Step 1: Determine Scope

Parse `$ARGUMENTS` to determine scope:
- No args → all overlays (all modules x all envs)
- An environment name (matches an `overlays/` subdirectory) → all modules for that env
- A module name (matches a discovered module) → all envs for that module

### Step 2: YAML Lint

Run yamllint on all YAML files in scope:

```bash
yamllint -c .yamllint.yml <module>/base/ <module>/overlays/<env>/
```

If no `.yamllint.yml` exists, run with default config: `yamllint <module>/base/ <module>/overlays/<env>/`

Collect results per file. Categorize as ERROR or WARNING.

### Step 3: Kustomize Build

For each environment in scope, run:

```bash
kustomize build <module>/overlays/<env> > /dev/null
```

Record PASS or FAIL for each.

### Step 4: Results Table

Present results in this format:

```
Lint Results
| Module | Env | yamllint | kustomize build | Status |
|--------|-----|----------|-----------------|--------|
| module-a | dev | PASS (0 warn) | PASS | OK |
| module-a | stg | WARN (2 warn) | PASS | WARN |
| module-a | prd | PASS | PASS | OK |
| module-b | dev | PASS | PASS | OK |
| module-b | stg | PASS | PASS | OK |
| module-b | prd | PASS | FAIL | FAIL |

Overall: PASS / WARN / FAIL
```

### Step 5: Auto-fix Suggestions

If any yamllint errors are formatting-related, suggest:
```bash
pre-commit run yamlfmt --all-files
```

If kustomize build fails, show the error output and suggest checking:
1. Missing resources in `kustomization.yaml`
2. Invalid YAML syntax in referenced files
3. Missing base directory reference

### Graceful Degradation

- If `yamllint` is not installed, suggest: `pip install yamllint`
- If `kustomize` is not installed, suggest: `brew install kustomize`
- Never block the entire lint because one tool is missing -- skip that check and show the install command
- Minimum viable lint: kustomize build (kustomize is required for any meaningful validation)
