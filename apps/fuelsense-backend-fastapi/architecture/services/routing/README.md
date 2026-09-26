# FuelSense GIS - Routing Service

## Purpose

The Routing Service calculates fuel-aware routes by combining vehicle information, fuel requirements, fuel station locations, traffic conditions, road-network data, and current fuel prices.

## Responsibilities

- Calculate routes between locations
- Find suitable fuel stations along or near a route
- Calculate route distance and ETA
- Estimate fuel required for a trip
- Estimate trip fuel cost
- Compare route alternatives
- Consider compatible fuel types
- Consider station availability when valid data exists
- Provide route and fuel-cost information to the mobile application

## Inputs

- Origin
- Destination
- Vehicle profile
- Fuel type
- Current fuel level
- Vehicle consumption data
- Fuel station locations
- Fuel prices
- Fuel availability
- Traffic conditions
- Road-network data
- Route preferences

## Outputs

- Recommended route options
- Route distance
- Estimated travel time
- Fuel required
- Estimated fuel cost
- Fuel stations along the route
- Station distance from route
- Fuel compatibility
- Data freshness
- Source metadata

## Routing Engine

The `engine/` layer handles:

- Route calculation
- Route comparison
- Station detour calculation
- Fuel requirement calculation
- Fuel-cost calculation
- Route scoring based on user-selected criteria

The routing engine must remain independent from individual map or routing providers.

## Provider Strategy

Provider-specific routing and map integrations remain inside the `providers/` layer.

The system should support replacement or addition of providers without changing the core routing domain.

## Fuel-Aware Routing

The service can evaluate:

- Shortest route
- Fastest route
- Lower fuel-cost route
- Route with suitable fuel stations
- Route considering current fuel range

A route must not claim that a station has available fuel unless valid availability data exists.

## Events

### Consumes

- vehicle.updated
- vehicle.location.updated
- fuel.price.updated
- station.location.updated
- station.availability.updated
- traffic.observation.updated
- route.requested

### Publishes

- route.calculated
- route.updated
- route.station.selected
- route.calculation.failed

## Storage

MongoDB may store route requests, route metadata, and current route-related state.

ClickHouse may store historical route calculations and trip analytics.

Large route datasets may be retained in object storage/data lake infrastructure.

## Reliability

- Provider timeout handling
- Retry with backoff
- Route calculation timeout
- Provider health monitoring
- Input validation
- Duplicate request protection
- Graceful degradation when optional data is unavailable
- Dead-letter event handling

If required route data is unavailable, the service must clearly report the limitation instead of fabricating route or station information.

## Security

- Authenticated route requests
- User-scoped vehicle information
- Protection of location history
- Role-based access control
- Audit logging
- Secure provider credentials

## Design Principle

Routing decisions must be explainable from actual route, vehicle, fuel, station, and traffic inputs.

FuelSense GIS should clearly distinguish between observed data, calculated values, and provider-generated estimates.
