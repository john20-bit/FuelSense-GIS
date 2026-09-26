# Kubernetes Monitoring

Monitoring provides visibility into the health and performance of FuelSense GIS workloads.

## Kubernetes Metrics

Monitor:

- Pod CPU usage
- Pod memory usage
- Pod restarts
- Deployment status
- Replica availability
- HPA activity
- Node health

## Application Metrics

Monitor:

- API request rate
- API latency
- Error rate
- Kafka consumer lag
- Data freshness
- Service availability
- External provider availability

## Health Monitoring

Use:

- Readiness probes
- Liveness probes
- Startup probes where required

## Alerting

Alerts should be generated for:

- Pod failures
- Crash loops
- High error rates
- High latency
- Resource exhaustion
- Kafka lag
- Stale data
- Provider outages

## Observability

Kubernetes monitoring integrates with the FuelSense GIS observability architecture for:

- Metrics
- Logs
- Distributed tracing
- Alerts

## Design Principle

Monitoring should provide early detection of service, infrastructure, and data reliability problems.
