# Test Pipeline

The test stage validates FuelSense GIS changes before deployment.

## Validation

- Unit tests
- Integration tests
- API tests
- Contract tests
- Data validation tests
- Service health checks

## Quality Gates

A deployment should stop when critical tests fail.

The pipeline should record:

- Test results
- Coverage
- Failed test details
- Build version
- Commit SHA

## Environment Testing

Testing should run against isolated development or staging environments.

Production data must not be used for automated development testing.

## Output

Only validated builds continue to the security and deployment stages.
