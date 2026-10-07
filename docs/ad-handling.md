# Ad and Distraction Handling

## Product boundary

Voyager is a learning environment, not a normal video-platform client. The app
should not provide endless discovery, Shorts-style browsing, trending content,
recommendation feeds, social engagement, or autoplay discovery.

## Current state

The app shell uses roadmap-led screens and does not implement discovery feeds.
`ContentFilterService` is an independent, disabled-by-default boundary.
`ContentFilterEngine` can evaluate only requests explicitly scoped as
`applicationManaged`; it always allows YouTube player and extracted-media
requests. `NativeFilterBridge` defines a MethodChannel contract, but no Android
or Rust engine is currently included.

## Future handling

Only filter content the application is permitted to filter. Do not manipulate
YouTube advertising/player requests, claim ad-free YouTube playback, or use
stream extraction as an advertising bypass. Brave `adblock-rust` was reviewed
(MPL-2.0) but is not packaged; native FFI/ABI, filter-list updates, and Android
request-owner integration remain a separately gated task.
