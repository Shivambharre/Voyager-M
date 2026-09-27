# Media Provider Boundary

## Contract

`MediaProvider` resolves a source URL to the app-owned `MediaAsset` model. UI and
feature code should use this model rather than provider-specific SDK objects.

## Current state

`MockMediaProvider` validates that the source parses as a URI and returns a
placeholder asset. It does not contact a media site, extract metadata, retrieve
playable streams, or validate whether a URL is actually supported.

The Library screen's sample rows are not resolved through this provider yet.

## Production integration is deferred

Before selecting an implementation, evaluate Android integration options,
project/license obligations, maintenance and compatibility, supported content,
network failures, service terms, and restrictions. Keep all provider-specific
code inside its adapter and map results into app-owned models.

## Error behavior

Invalid input should remain an explicit format/validation error. Provider
failures should eventually map to documented domain-level outcomes such as
unsupported source, unavailable item, or network failure; avoid success-shaped
placeholder assets in production.
