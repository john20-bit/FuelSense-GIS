# Development Configuration

Development configuration is used for local development and engineering testing.

## Characteristics

- Debug-friendly logging
- Development service endpoints
- Local Kafka configuration
- Relaxed resource limits
- Test data sources where explicitly labelled
- Development-only credentials through environment secrets

## Rules

- Never use production credentials
- Never connect development services to production data
- Never store secrets in Git
- Keep configuration environment-specific

## Purpose

Development configuration allows engineers to build and test FuelSense GIS services without affecting staging or production environments.
