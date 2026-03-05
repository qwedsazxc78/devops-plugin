# add-service — Service Scaffolding Skill

Scaffolds a new service following the Kustomize base/overlay pattern, creating base resources and environment overlays following repo conventions. If a `templates/service-template/` directory exists in the repo, uses it as the source template.

## Usage

```
add-service                    # Interactive mode
add-service my-api             # Quick scaffold with defaults
add-service my-api --full      # Full scaffold with all components
```

## Arguments

$ARGUMENTS — Optional: service name, `--full` for all components. Default: interactive mode.

## Instructions

### Step 0: Discover Repository Structure

- **Discover Kustomize modules** by finding directories that contain a `base/` and `overlays/` subdirectory structure
- **Discover environments** by listing subdirectories under each module's `overlays/` directory
- Identify the most appropriate module to place the new service in (typically a service-oriented module). If multiple modules exist, ask the user which module to target.
- Check if `templates/service-template/` exists for golden path templates

### Step 1: Gather Service Information

If interactive mode (no args or missing info), ask the user for:

1. **Service name** (required) — lowercase, kebab-case (e.g., `my-api`)
2. **Target module** (required if multiple modules found) — which Kustomize module to use
3. **Team** (required) — owning team (e.g., `data-engineering`, `platform`, `sre`)
4. **Namespace** (required) — target namespace
5. **Container image** (required) — full image path with tag
6. **Port** (required) — container port (e.g., `8080`)
7. **Components** (optional) — which components to include:
   - Deployment (always included)
   - Service (default: yes)
   - Ingress (default: no — use add-ingress separately)
   - HPA (default: no)
   - ServiceMonitor (default: no)

### Step 2: Create Base Resources

If `templates/service-template/` exists, copy and customize from there. Otherwise, generate from the inline templates below.

**`<module>/base/<service-name>-deployment.yaml`**
```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <service-name>
  labels:
    app.kubernetes.io/name: <service-name>
    app.kubernetes.io/component: server
    app.kubernetes.io/part-of: <team>-platform
    app.kubernetes.io/managed-by: kustomize
    team: <team>
    cost-center: <team>
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: <service-name>
  template:
    metadata:
      labels:
        app.kubernetes.io/name: <service-name>
        app.kubernetes.io/component: server
        team: <team>
    spec:
      containers:
        - name: <service-name>
          image: <image>
          ports:
            - containerPort: <port>
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
```

**`<module>/base/<service-name>-service.yaml`** (if Service component selected)
```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: <service-name>
  labels:
    app.kubernetes.io/name: <service-name>
    app.kubernetes.io/managed-by: kustomize
    team: <team>
spec:
  selector:
    app.kubernetes.io/name: <service-name>
  ports:
    - port: <port>
      targetPort: <port>
```

### Step 3: Update Base Kustomization

Add new resources to `<module>/base/kustomization.yaml`:
```yaml
resources:
  # ... existing resources ...
  - <service-name>-deployment.yaml
  - <service-name>-service.yaml
```

### Step 4: Create Environment Overlays

For each discovered environment, create overlay patches if needed.

**`<module>/overlays/<env>/<service-name>-deployment.yaml`** (if env-specific config needed)
```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <service-name>
spec:
  replicas: <env-specific-replicas>  # Scale appropriately per environment
```

Add to each overlay's `kustomization.yaml` patches section:
```yaml
patches:
  # ... existing patches ...
  - path: <service-name>-deployment.yaml
```

### Step 5: Apply Repo Conventions

Ensure all generated files follow:
- Check if the module's overlays use `namePrefix` (inspect existing `kustomization.yaml`). If so, do NOT hardcode env prefix in base.
- **Labels** — include standard Kubernetes recommended labels
- **`---`** YAML document start marker on every file
- **No trailing whitespace**, LF line endings

### Step 6: Validate

Run kustomize build for each discovered environment:
```bash
kustomize build <module>/overlays/<env>
```

### Step 7: Summary

```
Service Scaffolded: <service-name>

Files Created:
  <module>/base/<service-name>-deployment.yaml
  <module>/base/<service-name>-service.yaml
  <module>/overlays/<env>/<service-name>-deployment.yaml (per environment, if applicable)

Files Modified:
  <module>/base/kustomization.yaml (added resources)
  <module>/overlays/<env>/kustomization.yaml (added patches, per environment)

Next Steps:
  1. Review generated files and adjust resource limits
  2. Add environment-specific secrets if needed (manually add secretGenerator entries to overlay kustomization.yaml)
  3. Add ingress if needed: add-ingress <service-name>
  4. Create ArgoCD app: argocd-app create <service-name>
  5. Run validation
  6. Run pre-commit hooks
```

### Graceful Degradation

- If `kustomize` is not installed, suggest: `brew install kustomize` (required for Step 6 validation)
- If `templates/service-template/` does not exist, generate resources from the inline templates in Step 2 instead
- Scaffolding steps (Steps 2-5) are file creation only and require no external tools
