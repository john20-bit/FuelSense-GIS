# FuelSense GIS - Security Architecture

## Purpose

The Security Architecture protects FuelSense GIS users, services, data, APIs, and infrastructure.

## OAuth 2.0 / OpenID Connect

The `oauth2-oidc/` layer manages:

- User authentication
- Access tokens
- Refresh tokens
- Identity provider integration
- Token validation
- Session lifecycle

Authentication should use standards-based OAuth 2.0 and OpenID Connect.

## Role-Based Access Control

The `rbac/` layer manages permissions for:

- Public Users
- Petrol Bunk Operators
- Government Users
- System Administrators
- Internal Services

Permissions must follow least-privilege principles.

Protected operational roles must not depend on unrestricted public self-registration.

## Audit

The `audit/` layer records security-sensitive actions such as:

- Login attempts
- Authentication failures
- Permission changes
- Role changes
- Administrative actions
- Access denials
- Sensitive data access
- Security configuration changes

Audit records must be tamper-resistant and retained according to policy.

## Secrets

The `secrets/` layer manages:

- API credentials
- Database credentials
- Kafka credentials
- OAuth secrets
- Provider credentials
- Signing keys
- Encryption keys

Secrets must never be committed to source control or stored in application code.

## API Security

All protected APIs must enforce:

- Authentication
- Authorization
- Input validation
- Rate limiting
- TLS
- Secure headers
- Request tracing

## Service Security

Internal services must authenticate with each other.

Service accounts must receive only the permissions required for their operations.

## Data Protection

- Encryption in transit
- Encryption at rest
- Sensitive-field protection
- Access auditing
- Secure backups
- Data minimization

## Threat Protection

The platform should protect against:

- Credential attacks
- Token theft
- Brute-force authentication
- Unauthorized access
- Injection attacks
- Replay attacks
- Abuse of public APIs
- Compromised service identities

## Design Principle

Security must be enforced at every trust boundary.

Authentication proves identity.

Authorization determines what that identity is allowed to access.
