# FuelSense GIS - Satellite Service

## Purpose

The Satellite Service manages satellite-derived observations that can support GIS analysis, environmental monitoring, fuel-quality assessment, and phase-separation analysis.

## Responsibilities

- Collect satellite observations
- Normalize satellite data from supported providers
- Process geographic observation data
- Track observation timestamps
- Validate spatial coverage
- Detect relevant environmental changes
- Provide satellite-derived evidence to domain services

## Inputs

- Satellite imagery
- Remote-sensing products
- Geographic coordinates
- Station locations
- Phase-separation observation areas
- Weather observations

## Outputs

- Satellite observations
- Processed geographic features
- Observation timestamps
- Spatial coverage
- Data quality metadata
- Source metadata
- Processing status

## Provider Strategy

Provider-specific integration remains inside the `providers/` layer.

The domain layer must not depend directly on a specific satellite provider.

## Processing

The `processing/` layer handles:

- Data validation
- Coordinate normalization
- Observation filtering
- Spatial extraction
- Feature generation
- Quality checks

Processed observations must retain their original source and timestamp.

## Events

### Consumes

- location.updated
- weather.observation.updated
- phase-separation.observation.created

### Publishes

- satellite.observation.updated
- satellite.processing.completed
- satellite.data.stale
- satellite.coverage.updated

## Domain Usage

Satellite observations may support:

- GIS environmental analysis
- Phase-separation assessment
- Fuel-quality monitoring
- Spatial hotspot detection
- Weather and environmental correlation
- Historical spatial analysis

Satellite data is supporting evidence and must not be treated as direct proof of fuel quality unless validated by appropriate ground or station-level observations.

## Storage

MongoDB may store processed spatial observations and metadata.

ClickHouse may store historical observation events and analytical measurements.

Large imagery and remote-sensing datasets should be stored in object storage/data lake infrastructure.

## Reliability

- Provider timeout handling
- Retry with backoff
- Processing failure isolation
- Source freshness checks
- Spatial coverage validation
- Duplicate observation protection
- Dead-letter event handling
- Provider health monitoring

If valid satellite data is unavailable, the service must report UNKNOWN rather than generating an estimated observation.

## Security

- Secure provider credentials
- Authenticated internal APIs
- Role-based access control
- Audit logging for administrative operations
- Controlled access to sensitive spatial datasets

## Design Principle

Satellite data must remain source-aware, timestamped, spatially validated, and transparent about processing quality.

FuelSense GIS must distinguish between raw satellite observations, processed observations, and domain-level conclusions.
