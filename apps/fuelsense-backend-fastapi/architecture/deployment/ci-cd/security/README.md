# Security Pipeline

The security stage checks FuelSense GIS artifacts before deployment.

## Security Checks

- Dependency vulnerability scanning
- Container image scanning
- Secret detection
- Static security analysis
- Configuration validation
- License validation

## Secrets

The pipeline must detect accidentally committed:

- API keys
- Passwords
- Tokens
- Private keys
- Database credentials

Detected secrets must block the deployment pipeline.

## Container Security

Container images should:

- Use trusted base images
- Run with least privilege
- Minimize unnecessary packages
- Be scanned before release

## Output

Only builds that pass required security gates continue to deployment.
