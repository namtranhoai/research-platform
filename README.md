# Research Platform

Minimal research platform with Infrastructure as Code, CI/CD pipeline, and multi-environment support (dev/staging/prod).

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         CI/CD Pipeline (GitHub Actions)                  │
├─────────────────────────────────────────────────────────────────────────┤
│  lint → test → build (Docker) → push (GHCR) → deploy (Kubernetes)       │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    GitHub Container Registry (ghcr.io)                   │
│              ghcr.io/<org>/research-platform:{dev|staging|prod}           │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         Kubernetes Cluster(s)                            │
├─────────────────┬─────────────────┬────────────────────────────────────┤
│  dev            │  staging        │  prod                                │
│  namespace:     │  namespace:     │  namespace:                          │
│  research-      │  research-      │  research-                           │
│  platform-dev   │  platform-      │  platform-prod                       │
│                 │  staging        │                                      │
└─────────────────┴─────────────────┴────────────────────────────────────┘
```

### Components

| Component | Description |
|-----------|-------------|
| **Terraform** | Minimal IaC (local backend). Generates config per environment. |
| **Flask API** | Python app with `/health` and `/` endpoints. |
| **Docker** | Multi-stage build, pushed to GHCR. |
| **Kustomize** | K8s manifests with overlays for dev/staging/prod. |
| **GitHub Actions** | Lint → Test → Build → Push → Deploy. |

### Directory Structure

```
research-platform/
├── .github/workflows/ci-cd.yml   # CI/CD pipeline
├── infra/terraform/              # IaC (local/mock)
│   ├── main.tf
│   ├── variables.tf
│   ├── dev.tfvars, staging.tfvars, prod.tfvars
├── k8s/
│   ├── base/deployment.yaml      # Deployment + Service
│   └── overlays/{dev,staging,prod}/  # Environment-specific config
├── src/
│   ├── app.py
│   ├── test_app.py
│   └── requirements.txt
├── Dockerfile
├── pyproject.toml
└── README.md
```

---

## How-To

### Prerequisites

- Python 3.12+
- Docker
- Terraform >= 1.0 (for infra)
- kubectl + Kubernetes cluster (for deploy)

### Local Development

```bash
# Create venv and install
python -m venv .venv
.venv\Scripts\activate   # Windows
# source .venv/bin/activate  # Linux/macOS
pip install -r src/requirements-dev.txt

# Run app
cd src && python app.py

# Run tests
pytest src/ -v

# Lint
ruff check src/
```

### Build Docker Image Locally

```bash
docker build -t research-platform:local .
docker run -p 8080:8080 research-platform:local
# curl http://localhost:8080/health
```

### Terraform (Infrastructure)

```bash
cd infra/terraform

# Init
terraform init

# Plan for dev
terraform plan -var-file=dev.tfvars

# Apply
terraform apply -var-file=dev.tfvars
```

### Deploy to Kubernetes (Manual)

```bash
# Set image (replace OWNER with your GitHub org/user)
cd k8s/overlays/dev
kustomize edit set image ghcr.io/PLACEHOLDER_ORG/research-platform=ghcr.io/OWNER/research-platform:dev

# Apply
kustomize build . | kubectl apply -f -
```

### GitHub Actions Setup

1. **Environments**: Create `dev`, `staging`, `prod` in repo Settings → Environments.
2. **Secrets**: For each environment, add `KUBE_CONFIG` (base64-encoded kubeconfig).
3. **Package permissions**: Enable "Write" for packages (Settings → Actions → General).

---

## Security Notes

### Secrets & Credentials

- **Never commit** kubeconfig, API keys, or tokens.
- Use GitHub Secrets for `KUBE_CONFIG`; store base64-encoded kubeconfig.
- Prefer short-lived tokens and OIDC where possible.

### Container Security

- Image: `python:3.12-slim` (minimal attack surface).
- Run as non-root (consider adding `USER` in Dockerfile for production).
- Pin dependency versions in `requirements.txt`.

### Kubernetes

- Use RBAC and least-privilege service accounts.
- Enable network policies to restrict pod-to-pod traffic.
- Use separate namespaces per environment.

### CI/CD

- `GITHUB_TOKEN` has scoped permissions; avoid broad `write` where possible.
- Protect `main` with branch protection and required reviews.
- Use environment protection rules for `staging` and `prod` (e.g. required reviewers).

### Terraform

- State file (`terraform.tfstate`) contains resource metadata; keep it out of version control.
- For production, use remote backend (S3, GCS) with encryption and access controls.
