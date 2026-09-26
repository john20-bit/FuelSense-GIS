# Autoscaling

FuelSense GIS uses Kubernetes autoscaling to dynamically adjust service capacity.

## Horizontal Pod Autoscaling

HPA can scale services based on:

- CPU utilization
- Memory utilization
- Request load
- Event processing load
- Kafka consumer lag

## Scaling Model

Minimum replicas:

- 2

Maximum replicas:

- 10

This provides baseline availability while allowing services to handle increased workloads.

## Scale Up

Scaling should respond quickly to sustained workload increases.

## Scale Down

Scaling should happen gradually to avoid unnecessary Pod churn.

## Production Scaling

Production deployments should additionally consider:

- Kafka consumer lag
- API request rate
- Response latency
- Queue depth
- Data ingestion volume
- Service-specific workload

## Reliability

Autoscaling works together with:

- Readiness probes
- Liveness probes
- Resource requests
- Resource limits
- Rolling deployments
- Failure recovery

## Design Principle

Scaling decisions should reflect actual workload and service health.

Autoscaling must not replace proper capacity planning and performance testing.
