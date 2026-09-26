# FuelSense GIS - Event Backbone

## Purpose

The Event Backbone provides asynchronous communication between FuelSense GIS services using Kafka.

## Core Principles

- Event-driven communication
- Loose service coupling
- Durable event delivery
- Replayable events
- Schema versioning
- Idempotent consumers
- Partition-based scalability

## Event Domains

- Vehicle telemetry
- Fuel availability and price
- Station status
- Phase separation
- Weather
- Satellite
- Traffic
- Estimation
- Intelligence
- Notifications

## Event Flow

Data Source
→ Data Ingestion
→ Validation
→ Kafka
→ Domain Services
→ Updated FuelSense GIS state

## Event Requirements

Every event should contain:

- event_id
- event_type
- schema_version
- source
- occurred_at
- received_at
- correlation_id
- payload

## Reliability

- Consumer groups
- Retry handling
- Dead-letter topics
- Idempotent processing
- Offset management
- Backpressure handling
- Event replay

## Ordering

Ordering should be guaranteed where required by the domain, such as:

- Vehicle telemetry
- Station state changes
- Fuel availability changes

Partition keys must be selected according to the required ordering boundary.

## Schema Management

Event schemas must be versioned.

Breaking schema changes require a controlled migration strategy.

Consumers must remain compatible during schema transitions.

## Security

- Authenticated producers
- Authenticated consumers
- Topic-level authorization
- TLS
- Secret management
- Audit logging

## Observability

Track:

- Event throughput
- Consumer lag
- Processing latency
- Failed events
- Retry counts
- Dead-letter volume
- Producer failures

## Design Principle

Kafka carries facts and state-change events.

Business decisions remain inside domain services.

The event backbone must not become a second business-logic layer.
