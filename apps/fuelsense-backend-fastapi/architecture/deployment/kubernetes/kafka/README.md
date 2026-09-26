# Kafka Deployment

Kafka is the event backbone for FuelSense GIS.

## Purpose

Kafka provides reliable asynchronous communication between domain services and data ingestion pipelines.

## Core Events

- vehicle.telemetry
- fuel.availability
- fuel.price
- station.status
- weather.observation
- traffic.observation
- satellite.observation
- fuel.quality
- fuel.news
- phase-separation.alert
- prediction.update
- notification.event

## Responsibilities

- Event streaming
- Service decoupling
- Consumer group management
- Event buffering
- Retry handling
- Failure isolation
- Event replay

## Production Requirements

Production deployment should use:

- Multiple Kafka brokers
- Persistent volumes
- Replication
- Partitioning
- TLS
- Authentication
- Monitoring
- Backup and recovery

The single-broker manifest in this directory is a development architecture template.

## Design Principle

Kafka transports validated events.

Business logic remains inside FuelSense GIS domain services.
