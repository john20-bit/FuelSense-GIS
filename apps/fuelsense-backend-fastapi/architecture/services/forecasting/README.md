# FuelSense GIS - Forecasting & Estimation Service

## Purpose

The Forecasting & Estimation Service provides deterministic, data-driven calculations for fuel consumption, vehicle range, fuel cost, and fuel demand.

It does not depend on AI or machine learning.

## Responsibilities

- Estimate vehicle fuel consumption
- Estimate remaining driving range
- Calculate trip fuel requirements
- Calculate trip fuel cost
- Compare fuel options such as E10 and E20
- Estimate station-level fuel demand
- Generate short-term fuel demand estimates from historical and live observations
- Combine vehicle telemetry, fuel prices, route distance, traffic, and fuel data
- Provide confidence and data-freshness metadata with calculated results

## Inputs

- Vehicle profile
- Fuel type
- Tank capacity
- Current fuel level
- Historical fuel consumption
- Vehicle telemetry
- Route distance
- Traffic conditions
- Current fuel price
- Station fuel availability
- Historical station demand
- Location
- Timestamp

## Outputs

- Estimated consumption
- Estimated remaining range
- Required fuel quantity
- Estimated trip cost
- Fuel-option comparison
- Station demand estimate
- Data freshness
- Calculation inputs
- Calculation method
- Confidence metadata

## Calculation Principles

1. Prefer live telemetry over stale historical data.
2. Use validated station and fuel-price data.
3. Never fabricate unavailable values.
4. Mark unavailable inputs as UNKNOWN.
5. Preserve the timestamp and source of important inputs.
6. Every estimate must be reproducible from its recorded inputs.
7. Calculations must remain explainable and deterministic.

## Main Calculation Areas

### Vehicle Consumption

Uses recent verified fuel records and telemetry to estimate practical fuel consumption.

### Range Estimation

Uses:

- Current fuel level
- Tank capacity
- Recent consumption
- Route conditions

### Trip Fuel Cost

Uses:

- Trip distance
- Estimated consumption
- Current fuel price

### Fuel Comparison

Supports comparison between compatible fuels such as E10 and E20 using:

- Fuel price
- Vehicle compatibility
- Consumption data
- Expected trip distance

### Demand Estimation

Uses historical and live station observations to estimate short-term demand.

## API Responsibilities

The API layer exposes calculation requests and returns structured results with:

- Input values
- Calculated values
- Units
- Timestamp
- Data freshness
- Source metadata
- Calculation method

## Events

The service can consume:

- vehicle.telemetry.updated
- vehicle.fuel-record.created
- station.price.updated
- station.availability.updated
- route.calculated
- traffic.updated

It can publish:

- forecast.range.updated
- forecast.consumption.updated
- forecast.cost.updated
- forecast.demand.updated

## Storage

Operational calculation inputs and current estimates may be stored in MongoDB.

Historical analytical events and time-series observations may be stored in ClickHouse.

Large historical datasets may be retained in object storage/data lake infrastructure.

## Reliability

- Idempotent event processing
- Input validation
- Source freshness checks
- Calculation timeout protection
- Retry handling
- Dead-letter event handling
- Structured logging
- Metrics and tracing
- Graceful degradation when optional data sources are unavailable

## Security

- Authenticated API access
- User-scoped vehicle data
- Role-based access control
- Audit logging for sensitive operations
- No exposure of private telemetry to unauthorized users

## Design Principle

FuelSense GIS intelligence comes from real-world data, domain calculations, deterministic rules, and validated observations rather than requiring an AI/ML model.
