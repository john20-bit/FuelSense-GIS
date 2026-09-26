# FuelSense GIS - Data Ingestion Layer

## Purpose

The Data Ingestion Layer collects external and internal data, validates it, normalizes it into common schemas, and publishes trusted events to the FuelSense GIS event backbone.

## Data Sources

- PPAC
- IOCL
- BPCL
- HPCL
- Jio-bp
- Nayara
- Shell and other authorized operators
- Station telemetry
- Vehicle telemetry
- Weather providers
- Traffic providers
- Satellite data providers
- Fuel quality observations
- Live fuel news sources
- Internal FuelSense GIS services

## Pipeline

Source
→ Connector
→ Schema Validation
→ Normalization
→ Freshness Validation
→ Source Validation
→ Event Streaming
→ Domain Service

## Connectors

The `connectors/` layer isolates provider-specific integration logic.

Each connector must define:

- Source identity
- Authentication method
- Endpoint or transport
- Data format
- Polling or streaming method
- Rate limits
- Retry policy
- Health status

Provider-specific logic must not leak into domain services.

## Normalization

The `normalization/` layer converts different provider formats into common FuelSense GIS schemas.

Examples:

- Fuel availability
- Fuel price
- Station location
- Vehicle telemetry
- Weather observation
- Traffic observation
- Satellite observation
- Fuel quality observation
- News event

## Validation

The `validation/` layer checks:

- Schema validity
- Required fields
- Coordinates
- Timestamp validity
- Source identity
- Data freshness
- Duplicate events
- Invalid values
- Provider consistency

Invalid data must not enter trusted domain streams.

## Freshness

Every live observation must carry:

- observed_at
- received_at
- source
- freshness status

Possible states:

- LIVE
- RECENT
- STALE
- UNKNOWN

If a required source is unavailable, the system must return `UNKNOWN` instead of inventing a value.

## Streaming

Validated events are published to the Kafka event backbone.

Example event topics:

- vehicle.telemetry
- fuel.availability
- fuel.price
- station.status
- weather.observation
- traffic.observation
- satellite.observation
- fuel.quality
- fuel.news

## Scheduling

The `scheduling/` layer manages:

- Scheduled provider polling
- Periodic data refresh
- Retry scheduling
- Backoff
- Provider health checks
- Data freshness checks

Streaming providers should use event-driven ingestion where supported.

## Dead Letter Handling

The `dead-letter/` layer stores events that cannot be processed successfully.

Dead-letter records must include:

- Original event
- Source
- Failure reason
- Timestamp
- Processing attempt
- Service information

Failed events must be recoverable without silently losing data.

## Schemas

The `schemas/` layer defines canonical ingestion contracts shared across connectors and downstream services.

Schemas must be versioned to support controlled evolution.

## Reliability

- Retry with exponential backoff
- Rate-limit protection
- Circuit breakers
- Idempotent processing
- Duplicate detection
- Provider health monitoring
- Dead-letter recovery
- Backpressure handling

## Security

- Secure API credentials
- Secret management
- TLS for external connections
- OAuth/API-key protection
- Provider access auditing
- Least-privilege credentials

## Design Principle

The ingestion layer is the trust boundary between external data and FuelSense GIS.

Raw external data must never be treated as trusted simply because it was received.
