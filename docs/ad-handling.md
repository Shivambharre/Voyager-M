# Ad and Distraction Handling

## Product boundary

Voyager is a learning environment, not a normal video-platform client. The app
should not provide endless discovery, Shorts-style browsing, trending content,
recommendation feeds, social engagement, or autoplay discovery.

## Current state

The current app shell uses roadmap-led screens and does not implement discovery
feeds. `ContentPolicy` is a small, unconnected mock. No ad blocking, ad
interception, DRM circumvention, hidden provider-specific bypass, or equivalent
behavior has been implemented.

## Future handling

Only implement controls supported by the selected provider/player architecture
and permitted by applicable service restrictions. Keep provider-specific
behavior inside replaceable media adapters; explain limitations directly to the
user rather than implying unsupported ad-free playback.
