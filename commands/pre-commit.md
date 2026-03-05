# pre-commit — Run Pre-commit Hooks Skill

Runs all pre-commit hooks and provides a structured summary with fix suggestions.

## Usage

```
pre-commit           # Run all hooks on all files
pre-commit staged    # Run only on staged files
pre-commit <file>    # Run on specific file
```

## Arguments

$ARGUMENTS — Optional: `staged` for staged files only, or a specific file path. Default: `--all-files`.

## Instructions

### Step 1: Check Pre-commit Installation

Verify pre-commit is installed:
```bash
pre-commit --version
```

If not installed, suggest: `pip install pre-commit && pre-commit install`

### Step 2: Run Hooks

Based on arguments:
- Default: `pre-commit run --all-files`
- `staged`: `pre-commit run`
- Specific file: `pre-commit run --files <file>`

Capture full output including per-hook results.

### Step 3: Parse Results

Read `.pre-commit-config.yaml` from the repository root to discover which hooks are configured. Build the results table dynamically from the hooks found in the config file. Common hooks include:

| Hook | Purpose | Auto-fix? |
|------|---------|-----------|
| trailing-whitespace | Trim trailing whitespace | Yes |
| end-of-file-fixer | Fix end of files | Yes |
| check-yaml | Check YAML syntax | No |
| check-added-large-files | Check for large files | No |
| check-merge-conflict | Check for merge markers | No |
| mixed-line-ending | Enforce LF line endings | Yes |
| detect-private-key | Detect private keys | No |
| yamlfmt | Format YAML files | Yes |
| yamllint | Lint YAML files | No |
| gitleaks | Scan for secrets | No |

Additionally, discover any kustomize-build hooks dynamically. These are typically named `kustomize-build-<env>` for each environment in the repository.

### Step 4: Results Summary

```
Pre-commit Results
| Hook | Status | Files Affected | Auto-fixable? |
|------|--------|----------------|---------------|
| trailing-whitespace | PASS/FAIL | N files | Yes |
| yamlfmt | PASS/FAIL | N files | Yes |
| yamllint | PASS/FAIL | N files | No |
| gitleaks | PASS/FAIL | N files | No |
| kustomize-build-* | PASS/FAIL | - | No |
| ... | ... | ... | ... |

Overall: PASS / FAIL (N hooks passed, M failed)
```

### Step 5: Fix Suggestions

For each failed hook, provide specific fix instructions:

- **Auto-fixable hooks** (trailing-whitespace, end-of-file-fixer, mixed-line-ending, yamlfmt): These hooks auto-fix on first run. Just re-run: `pre-commit run --all-files` and then `git add .`
- **yamllint failures**: Run `pre-commit run yamlfmt --all-files` first, then re-check
- **gitleaks failures**: Review flagged files, add to `.gitleaks.toml` allowlist if false positive
- **kustomize-build failures**: Check kustomization.yaml references and YAML validity
- **check-yaml failures**: Fix YAML syntax errors in reported files
- **detect-private-key**: Review flagged files, add to exclude pattern in `.pre-commit-config.yaml` if false positive

### Step 6: Re-run Suggestion

If any auto-fixable hooks failed:
```
Some hooks auto-fixed files. Run again to verify:
  pre-commit run --all-files
  git add -u  # Stage the auto-fixed files
```

### Graceful Degradation

- If `pre-commit` is not installed, suggest: `pip install pre-commit && pre-commit install`
- If hooks are not installed in the repo, suggest: `pre-commit install`
- If a specific hook binary is missing (e.g., kustomize, gitleaks), that hook will fail but others will still run
- Never block the entire check because one hook fails -- report all results
