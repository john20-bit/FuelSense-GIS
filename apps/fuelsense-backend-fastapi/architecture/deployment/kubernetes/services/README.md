# Domain Services Kubernetes Deployment

This directory defines the common Kubernetes deployment model for FuelSense GIS domain services.

## Services

- Identity
- Vehicle
- Fuel
- Station
- Phase Separation
- Telemetry
- Location
- Weather
- Satellite
- Traffic
- Forecasting
- Routing
- Notification
- Analytics

## Deployment Model

Each service runs as an independently deployable Kubernetes workload.

Kubernetes provides:

- Pod lifecycle management
- Service discovery
- Health checks
- Load balancing
- Horizontal autoscaling
- Resource limits
- Rolling updates
- Failure recovery

## Internal Communication

Services communicate through:

- HTTP/gRPC for synchronous operations
- Kafka for event-driven communication

## Scaling

Services can scale independently according to:

- CPU utilization
- Memory utilization
- Request volume
- Event processing load
- Kafka consumer lag

## Health

Every production service should expose:

- `/health/live`
- `/health/ready`

Readiness determines whether a Pod can receive traffic.

Liveness determines whether a Pod should be restarted.

## Configuration

Environment-specific configuration is managed separately under:

`architecture/deployment/configuration/`

Secrets must not be stored directly in deployment manifests.

## Design Principle

Kubernetes manages how services run.

Domain services manage FuelSense GIS business logic.
