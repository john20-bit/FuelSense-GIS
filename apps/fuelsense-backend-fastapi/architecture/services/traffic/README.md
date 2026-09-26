# FuelSense GIS - Traffic Service

## Purpose

The Traffic Service provides current and historical road-condition data for routing, travel-time estimation, fuel-consumption calculations, and location-aware decisions.

## Responsibilities

- Collect traffic observations
- Normalize traffic data from multiple providers
- Track road congestion
- Estimate travel-time impact
- Associate traffic conditions with road segments
- Validate source freshness
- Provide traffic context to routing and forecasting services

## Inputs

- Traffic provider APIs
- Vehicle location
- Road-network data
- Route requests
- Historical traffic observations

## Outputs

- Traffic condition
- Congestion level
- Average speed
- Estimated travel-time impact
- Road-segment status
- Observation timestamp
- Source
- Data freshness

## Provider Strategy

Provider-specific integrations remain inside the `providers/` layer.

The domain layer must remain independent of any individual traffic provider.

## Processing

The `processing/` layer handles:

- Traffic normalization
- Road-segment matching
- Coordinate validation
- Duplicate detection
- Freshness checks
- Traffic condition classification

## Events

### Consumes

- location.updated
- route.requested

### Publishes

- traffic.observation.updated
- traffic.segment.updated
- traffic.data.stale
- traffic.alert.updated

## Domain Usage

Traffic information may support:

- Route planning
- ETA calculation
- Fuel consumption estimation
- Trip fuel-cost estimation
- Station accessibility
- Route condition alerts

Traffic data must be treated as an input to these calculations, not as a guaranteed prediction of future road conditions.

## Storage

MongoDB may store current road-condition state and provider-normalized traffic documents.

ClickHouse may store historical traffic observations and road-segment events for analytics.

Large historical datasets may be retained in object storage/data lake infrastructure.

## Reliability

- Provider timeout handling
- Retry with backoff
- Provider health monitoring
- Freshness validation
- Duplicate event protection
- Rate-limit handling
- Dead-letter event handling
- Graceful degradation when providers are unavailable

If valid traffic data is unavailable, the service must report UNKNOWN rather than inventing a traffic condition.

## Security

- Secure provider credentials
- Authenticated internal APIs
- Role-based access control
- Audit logging for administrative operations
- Controlled access to sensitive location data

## Design Principle

Traffic information must remain source-aware, time-aware, road-segment aware, and transparent about freshness.

FuelSense GIS must distinguish between observed traffic conditions and estimated travel impacts.
