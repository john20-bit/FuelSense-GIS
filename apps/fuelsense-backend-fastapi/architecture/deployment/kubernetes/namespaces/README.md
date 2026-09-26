# FuelSense GIS Kubernetes Namespaces

## Purpose

FuelSense GIS uses separate Kubernetes namespaces to isolate development, staging, and production workloads.

## Environments

- `fuelsense-dev` - development and local integration
- `fuelsense-staging` - production-like validation
- `fuelsense-prod` - production workloads

## Resource Isolation

Each environment defines:

- ResourceQuota
- LimitRange
- NetworkPolicy

This prevents uncontrolled resource consumption and limits unnecessary network communication.

## Development

Development has smaller resource limits and is intended for active development and integration testing.

## Staging

Staging uses higher limits and production-like configuration for integration, load, and security validation.

## Production

Production has the highest resource allocation and strict network isolation.

Production changes must use controlled CI/CD deployment and audited access.

## Network Security

Each namespace permits:

- Ingress from workloads inside the same namespace
- Egress to workloads inside the same namespace
- DNS traffic required for service discovery

Additional cross-namespace or external communication must be explicitly added through controlled policies.

## Design Principle

Namespace isolation provides infrastructure-level separation.

Application authorization remains the responsibility of FuelSense GIS identity, RBAC, and service-to-service security controls.
