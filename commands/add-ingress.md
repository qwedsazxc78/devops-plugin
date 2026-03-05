# add-ingress — Ingress Resource Creation Skill

Creates ingress resources following the nginx-ingress pattern: base definition + environment-specific overlay patches.

## Usage

```
add-ingress                      # Interactive mode
add-ingress my-api               # Quick create with defaults
add-ingress my-api --rate-limit  # Include rate limiting
```

## Arguments

$ARGUMENTS — Optional: service name, `--rate-limit` for rate limiting annotations. Default: interactive mode.

## Instructions

### Step 0: Discover Repository Structure

- **Discover Kustomize modules** by finding directories that contain a `base/` and `overlays/` subdirectory structure
- **Discover environments** by listing subdirectories under each module's `overlays/` directory
- Identify the most appropriate module for the ingress resource. If multiple modules exist, ask the user which module to target.
- Inspect existing ingress resources in the repo to learn the naming and annotation patterns used

### Step 1: Gather Ingress Information

If interactive mode, ask:

1. **Service name** (required) — must match existing service name
2. **Target module** (required if multiple modules found) — which Kustomize module to use
3. **Service port** (required) — the port the service listens on
4. **Domain pattern** (required) — the base domain and subdomain pattern, e.g.:
   - For `my-api` with domain `example.com`: generates `dev-my-api.example.com`, `stg-my-api.example.com`, `my-api.example.com` (production has no prefix)
   - Discover domain patterns from existing ingress resources in the repo
5. **TLS enabled** (default: yes)
6. **Rate limiting** (default: no)
7. **Custom annotations** (optional)

### Step 2: Create Base Ingress

**`<module>/base/<service-name>-nginx-ingress.yaml`**

```yaml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: <service-name>-nginx-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  labels:
    app.kubernetes.io/name: <service-name>
    app.kubernetes.io/component: ingress
    app.kubernetes.io/part-of: infrastructure
    app.kubernetes.io/managed-by: kustomize
    team: <team>
    cost-center: <cost-center>
spec:
  ingressClassName: nginx
  rules:
    - host: PLACEHOLDER_HOST
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: <service-name>
                port:
                  number: <port>
  tls:
    - hosts:
        - PLACEHOLDER_HOST
      secretName: <service-name>-tls
```

If rate limiting requested, add annotations:
```yaml
    nginx.ingress.kubernetes.io/limit-rps: "10"
    nginx.ingress.kubernetes.io/limit-burst-multiplier: "5"
```

### Step 3: Add Base Resource

Add to `<module>/base/kustomization.yaml` resources:
```yaml
resources:
  - <service-name>-nginx-ingress.yaml
```

### Step 4: Create Environment Overlay Patches

For each discovered environment, create a strategic merge patch with the appropriate hostname:

**`<module>/overlays/<env>/<service-name>-nginx-ingress.yaml`**
```yaml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: <service-name>-nginx-ingress
  labels:
    environment: <env>
spec:
  rules:
    - host: <env-specific-hostname>
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: <service-name>
                port:
                  number: <port>
  tls:
    - hosts:
        - <env-specific-hostname>
      secretName: <service-name>-tls
```

Use the domain pattern discovered in Step 1 to generate hostnames per environment. For production environments (commonly named `prd` or `prod`), omit the environment prefix from the hostname.

### Step 5: Update Overlay Kustomizations

Add patch to each overlay's `kustomization.yaml`:
```yaml
patches:
  - path: <service-name>-nginx-ingress.yaml
```

**IMPORTANT**: Check if the module's overlays use `namePrefix` by inspecting each overlay's `kustomization.yaml`. If `namePrefix` is configured, the ingress `metadata.name` will get the prefix automatically. Ensure the `backend.service.name` does NOT include the env prefix — kustomize applies namePrefix to service references automatically.

### Step 6: Validate

```bash
kustomize build <module>/overlays/<env>
```

Run for each discovered environment. Verify:
- Hostnames are correct per environment
- Backend service names resolve correctly (accounting for namePrefix if used)
- TLS configuration is valid

### Step 7: Summary

```
Ingress Created: <service-name>-nginx-ingress

Files Created:
  <module>/base/<service-name>-nginx-ingress.yaml
  <module>/overlays/<env>/<service-name>-nginx-ingress.yaml (per environment)

Files Modified:
  <module>/base/kustomization.yaml
  <module>/overlays/<env>/kustomization.yaml (per environment)

DNS Records Needed:
  <env>-<service-name>.<domain> -> <env> ingress IP (per non-production environment)
  <service-name>.<domain> -> production ingress IP

Next Steps:
  1. Create DNS records for all environments
  2. Verify TLS certificate provisioning
  3. Run validation
  4. Run pre-commit hooks
```

### Graceful Degradation

- If `kustomize` is not installed, suggest: `brew install kustomize` (required for Step 6 validation)
- Scaffolding steps (Steps 2-5) are file creation only and require no external tools
