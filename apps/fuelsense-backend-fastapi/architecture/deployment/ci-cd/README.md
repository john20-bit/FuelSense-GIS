# FuelSense GIS CI/CD

## Pipeline Flow

Code Push / Pull Request
        |
        v
CI Validation
        |
        +--> Backend Tests
        |
        +--> Kubernetes YAML Validation
        |
        v
Security Scan
        |
        v
Docker Build
        |
        v
Manual Deployment
        |
        +--> Development
        |
        +--> Staging
        |
        +--> Production

## Workflows

- ci.yml: Backend tests and Kubernetes YAML validation
- docker.yml: Docker image build
- security.yml: Trivy security scan
- deploy.yml: Manual Kubernetes deployment workflow

## Deployment Principles

- Pull requests must pass validation.
- Security scanning is part of the delivery pipeline.
- Container images are built from version-controlled source.
- Production deployment is manually triggered.
- Kubernetes is the deployment platform.
- Secrets must use GitHub Secrets or an external secret manager.
- Production credentials must never be committed.
