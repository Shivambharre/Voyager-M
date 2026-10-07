# Neo-Brutalist Design System

The presentation layer follows the supplied Neo-Brutalist UI direction: warm paper backgrounds, near-black outlines, tactile hard-offset shadows, editorial type hierarchy, and a restrained yellow/blue accent palette.

## Implementation

- Tokens: `lib/core/design/design_tokens.dart`
- Shared components: `lib/core/design/brutalist_components.dart`
- Light/dark themes: `lib/core/design/app_theme.dart`
- Component reference screen: `lib/core/design/design_system_showcase.dart`
- Application shell and primary navigation: `lib/features/home/presentation/app_shell.dart`
- Mock learning player: `lib/features/player/presentation/learning_player_screen.dart`

## UI boundaries

The screens use real repository contracts for Home, Library, Notes, and the player. The presentation layer still avoids direct SQLite or provider SDK calls, but the app shell and player now load and persist user data through their domain adapters.

## Review notes

- Common controls use strong borders and offset, zero-blur shadows.
- Contrast, touch target sizes, descriptive semantics, text progress values, and visible focus borders are considered in reusable controls.
- Layouts scroll on small screens and are width-constrained on larger displays.
- Dark appearance has a separate palette and keeps the outline-and-shadow character.
- The Design System Showcase is available from the palette icon in the app bar.
- Player controls expose accessible labeling for fullscreen, seeking, and quality selection.

The app shell and player remain intentionally focused, but the repository-backed library and note flows are no longer only mock UI state.
