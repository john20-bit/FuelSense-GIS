# FuelSense GIS - Identity & Access Service

## Purpose

The Identity & Access Service manages authentication, authorization, user identity, roles, sessions, and access policies across FuelSense GIS.

## Responsibilities

- User authentication
- Token/session management
- Role-based access control
- Permission management
- User identity management
- Service-to-service authentication
- Account lifecycle management
- Security audit events

## Roles

- Public User
- Petrol Bunk Operator
- Government User
- System Administrator
- Internal Service

Protected operational roles must not use unrestricted public self-registration.

## Authentication

The service should support standards-based authentication using OAuth 2.0 and OpenID Connect.

External identity providers may be integrated through the `providers/` layer.

## Authorization

The `policies/` layer defines:

- Role permissions
- Resource ownership
- API access policies
- Service permissions
- Administrative permissions

Authorization must be enforced at the API and service boundaries.

## Events

### Publishes

- identity.user.created
- identity.user.updated
- identity.user.disabled
- identity.role.updated
- identity.session.created
- identity.session.revoked
- security.authorization.denied

## Security

- Secure token validation
- Passwords must never be stored in plaintext
- Credential protection
- Token expiry and revocation
- Least-privilege access
- Role-based authorization
- Audit logging
- Protection against brute-force authentication attempts

## Service-to-Service Access

Internal services must authenticate when communicating with other protected services.

Service identities must receive only the permissions required for their operations.

## Privacy

Identity data must be isolated from unnecessary business data.

Sensitive personal information must only be accessible to authorized services and users.

## Reliability

- Provider failure handling
- Token validation resilience
- Rate limiting
- Session protection
- Audit event durability
- Monitoring
- Security alerting

## Design Principle

Identity and authorization are security boundaries, not merely login features.

Every protected FuelSense GIS resource must have an explicit authentication and authorization policy.
