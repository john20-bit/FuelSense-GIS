# FuelSense GIS - Analytics Service

## Purpose

The Analytics Service transforms historical FuelSense GIS data into measurable insights about fuel usage, vehicle operation, stations, routes, costs, and system activity.

## Responsibilities

- Analyze vehicle fuel consumption
- Analyze fuel costs
- Analyze station activity
- Analyze route performance
- Analyze fuel availability patterns
- Analyze phase-separation observations
- Calculate operational metrics
- Support ROI calculations
- Provide historical trends

## Inputs

- Vehicle telemetry
- Fuel records
- Fuel prices
- Station observations
- Fuel availability events
- Route history
- Traffic observations
- Weather observations
- Phase-separation observations
- Notification events

## Outputs

- Fuel consumption trends
- Cost trends
- Cost per kilometre
- Fuel usage summaries
- Station activity metrics
- Route performance metrics
- Availability trends
- Phase-separation trends
- ROI calculations
- Historical comparisons

## Queries

The `queries/` layer provides optimized analytical queries against historical datasets.

## Aggregations

The `aggregations/` layer handles:

- Daily summaries
- Weekly summaries
- Monthly summaries
- Vehicle-level metrics
- Station-level metrics
- Geographic aggregations
- Fuel-type comparisons

## Events

### Consumes

- vehicle.telemetry.updated
- vehicle.fuel-record.created
- fuel.price.updated
- station.availability.updated
- route.calculated
- traffic.observation.updated
- weather.observation.updated
- phase-separation.assessment.updated

### Publishes

- analytics.vehicle.updated
- analytics.station.updated
- analytics.route.updated
- analytics.roi.updated

## Storage

ClickHouse is the primary analytical store for high-volume historical events and time-series analysis.

MongoDB may store current analytical summaries and user-facing aggregates.

Object storage/data lake infrastructure may retain large historical datasets.

## ROI Calculator

The Analytics Service supports data-driven ROI calculations using:

- Actual fuel consumption
- Current fuel prices
- Historical fuel costs
- Distance travelled
- Fuel-type comparison
- Operating period

The calculator must expose its input assumptions and calculation method.

## Reliability

- Query timeout protection
- Aggregation validation
- Idempotent event processing
- Late-event handling
- Data-quality checks
- Retry handling
- Monitoring
- Graceful degradation

## Security

- Authenticated analytics access
- User-scoped vehicle analytics
- Role-based access control
- Aggregated data access controls
- Audit logging
- Protection of sensitive telemetry

## Design Principle

Analytics must be derived from recorded data and clearly distinguish historical observations, calculated metrics, and estimates.

No analytical result should be presented as real-time unless its underlying data meets the required freshness threshold.
