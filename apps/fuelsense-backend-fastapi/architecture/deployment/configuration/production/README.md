# Production Configuration

Production configuration defines the secure and highly available runtime environment for FuelSense GIS.

## Characteristics

- High availability
- Production resource limits
- Secure external integrations
- Strict access control
- TLS-enabled communication
- Centralized observability
- Automated deployment and rollback

## Rules

- Production credentials must never be stored in Git
- Secrets must use approved secret management
- Production data must remain isolated
- All external integrations require validation
- Configuration changes must be audited
- Deployments must support rollback

## Reliability

Production deployment should provide:

- Multiple service replicas
- Health checks
- Autoscaling
- Failure recovery
- Rolling updates
- Monitoring and alerting
- Backup and disaster recovery

## Purpose

Production configuration provides the secure runtime environment for national-scale FuelSense GIS operations.
