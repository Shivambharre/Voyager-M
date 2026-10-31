# Design System

VoyagerM uses a Classical Archive style. It uses warm surfaces, dark text,
antique colors, serif headings, and sans-serif interface text.

## Colors

| Name | Hex | Main use |
| --- | --- | --- |
| Parchment | `#E8DDC7` | Light page background |
| Sandstone | `#B49B78` | Borders and quiet accents |
| Pompeian red | `#6C3028` | Light-mode primary action |
| Roman olive | `#263B35` | Selected navigation and contrast |
| Antique gold | `#A8894E` | Highlights and progress |
| Charcoal umber | `#292724` | Main text and dark background |
| Marble grey | `#D6D0C3` | Raised surfaces |
| Fresco blue | `#8796A0` | Secondary accents |

`DesignTokens` also defines light and dark surfaces, text colors, dividers,
borders, spacing, and tap-target sizes. Use these tokens instead of adding
screen-specific values.

## Type

- Use **Cormorant Garamond** for editorial headings and screen titles.
- Use **Inter** for body text, labels, buttons, and controls.
- The app includes regular and italic variable font files in `assets/fonts/`.
- The font license notices are in the same folder.

## Components and accessibility

Shared controls are in
[`brutalist_components.dart`](../lib/core/design/brutalist_components.dart).
The file name is historical; the active theme uses the Classical Archive
style.

Keep controls easy to read and operate:

- Use a tap area of at least 48 logical pixels when practical.
- Keep keyboard focus visible.
- Add useful semantic labels.
- Show loading, empty, and error states.
- Check layouts on narrow screens.

Home quick actions are disabled. The player Share link control is also
disabled. The Save moment control is active, but it does not save data. Do not
give these controls new behavior unless the feature is approved and
implemented. See [`TODO.md`](../TODO.md).

## Source files

- Colors and spacing: `lib/core/design/design_tokens.dart`
- Light and dark themes: `lib/core/design/app_theme.dart`
- Shared controls: `lib/core/design/brutalist_components.dart`
- Component showcase: `lib/core/design/design_system_showcase.dart`
- App shell and main pages: `lib/features/home/presentation/app_shell.dart`
- Roadmaps: `lib/features/roadmap/presentation/roadmaps_page.dart`
- Player: `lib/features/player/presentation/learning_player_screen.dart`
