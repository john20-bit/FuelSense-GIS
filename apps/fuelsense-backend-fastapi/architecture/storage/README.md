# FuelSense GIS - Storage Layer

## Purpose

The Storage Layer provides specialized storage for operational data, analytics, historical events, and large-scale raw data.

## MongoDB

MongoDB is the primary operational document database.

Used for:

- Vehicle profiles
- Fuel stations
- Fuel prices
- Fuel availability
- Fuel quality observations
- Locations
- Route data
- Weather observations
- Satellite observations
- User-facing operational state

Geospatial indexes should support nearby and map-based queries.

## ClickHouse

ClickHouse is the analytical store for high-volume historical data.

Used for:

- Vehicle telemetry history
- Fuel consumption history
- Fuel price history
- Station availability history
- Traffic history
- Weather history
- Route analytics
- Event analytics
- System metrics

Analytical workloads must not overload operational MongoDB workloads.

## Data Lake

The data lake stores large historical and raw datasets.

Examples:

- Raw provider feeds
- Historical telemetry
- Satellite datasets
- Weather archives
- Traffic datasets
- News archives
- Processed analytical datasets

Raw data should remain available for reprocessing and validation.

## Object Storage

Object storage holds large files and artifacts.

Examples:

- Satellite imagery
- Export files
- Data snapshots
- Reports
- Archived datasets
- Model artifacts if ML is introduced later

## Data Lifecycle

External Source
→ Ingestion
→ Raw Storage
→ Validation
→ Normalization
→ Operational Storage
→ Analytical Storage

## Retention

Retention policies must be defined separately for:

- Current operational data
- Historical events
- Raw source data
- Audit records
- Large binary datasets

Retention must consider legal, operational, and storage requirements.

## Reliability

- Replication
- Automated backups
- Point-in-time recovery where supported
- Disaster recovery
- Storage monitoring
- Capacity monitoring
- Data integrity checks

## Security

- Encryption in transit
- Encryption at rest
- Role-based database access
- Secret management
- Network isolation
- Audit logging

## Design Principle

Use each storage system for the workload it is designed to handle.

MongoDB serves operational state, ClickHouse serves analytical workloads, and the data lake/object storage preserves large-scale historical and raw data.

PostgreSQL is not part of the FuelSense GIS target architecture.
