# Design Export Context

- Generated at: `2026-09-27T16:17:53.995Z`
- Document ID: `e122a3ab-6120-40a6-bf9a-23ba62885df7`
- Page count: 9

## Original Prompt

```text
# UI/UX DESIGN PROMPT — NEO-BRUTALIST LEARNING APP

You are designing the UI/UX for a personal, distraction-free learning application.

The application helps users learn from educational videos and playlists without the distractions normally associated with video platforms. Users can create custom learning roadmaps, watch videos, track progress, and attach notes, handwritten notes, images, and PDFs to learning topics.

The architecture, domain layer, repositories, media system, database layer, and other foundational modules already exist or are being developed separately.

Your task in this phase is **UI/UX design only**.

Do not redesign the application architecture.
Do not introduce unnecessary backend services.
Do not implement production media extraction.
Do not add social features.
Do not add recommendation feeds.
Do not add gamification unless explicitly requested later.

---

# 1. DESIGN DIRECTION

Use a **Neo-Brutalist / Neubrutalist Web UI-inspired visual language**, adapted carefully for a modern Android learning application.

The design should feel:

* Simple
* Bold
* Functional
* Academic
* Playful but not childish
* High contrast
* Direct
* Slightly raw
* Tactile
* Easy to scan
* Distraction-free

The interface should look intentionally designed rather than looking like a generic Material Design application.

Avoid making the UI unnecessarily complex.

The primary goal is:

> Help the user start learning quickly and stay focused.

---

# 2. NEO-BRUTALIST VISUAL PRINCIPLES

Use these principles consistently throughout the application.

## Borders

Use strong visible borders.

Preferred:

* 2px–3px borders
* Dark/black primary outlines
* Clearly defined cards
* Strong separation between sections

Avoid:

* Invisible card boundaries
* Excessive glassmorphism
* Thin low-contrast borders
* Excessive gradients

---

# 3. SHADOWS

Use **hard offset shadows** rather than soft elevation.

Example visual direction:

```text
┌─────────────────────────────┐
│                             │
│        CONTENT              │
│                             │
└─────────────────────────────┘
        █████████
        █████████
```

Typical shadow:

```text
offsetX: 4–6
offsetY: 4–6
blur: 0
spread: 0
```

The shadow should feel physical and tactile.

Avoid:

```text
blur: 20
opacity: 0.15
```

Do not use typical soft Material elevation as the primary visual language.

---

# 4. COLOR SYSTEM

Create a small, reusable color system.

Use a mostly neutral base:

* Off-white / cream background
* Near-black text
* White or slightly tinted surfaces

Use **one or two bold accent colors**.

Possible accent direction:

* Electric yellow
* Bright blue
* Acid green
* Orange
* Pink

Do not use every accent color simultaneously.

The interface should remain visually controlled.

Example:

```text
Background: warm off-white
Surface: white
Primary text: near-black
Border: black
Primary accent: bold yellow
Secondary accent: blue
```

Create these as design tokens rather than hardcoding colors throughout widgets.

---

# 5. TYPOGRAPHY

Typography should feel bold and editorial.

Use:

* Strong headings
* Bold section titles
* Clear hierarchy
* Comfortable body text
* Monospace or semi-monospace styling selectively for metadata if appropriate

Example hierarchy:

```text
PAGE TITLE
24–32px / Bold

SECTION TITLE
18–22px / Bold

CARD TITLE
16–18px / Bold

BODY
14–16px / Regular

METADATA
12–13px / Medium
```

Do not use excessive font sizes.

Do not make every piece of text bold.

---

# 6. COMPONENT DESIGN

Create a reusable Neo-Brutalist design system.

Build reusable components such as:

* BrutalistButton
* BrutalistIconButton
* BrutalistCard
* BrutalistInput
* BrutalistSearchBar
* BrutalistChip
* BrutalistTag
* BrutalistProgressBar
* BrutalistDialog
* BrutalistBottomSheet
* BrutalistAppBar
* BrutalistSectionHeader
* BrutalistListItem
* BrutalistEmptyState
* BrutalistErrorState
* BrutalistLoadingState
* BrutalistCheckbox
* BrutalistSwitch
* BrutalistTab
* BrutalistPlayerControls

Components must be reusable and configurable.

Do not create separate custom styling for every screen.

---

# 7. BUTTON STYLE

Buttons should feel tactile.

Example:

```text
┌──────────────────────┐
│     START LEARNING   │
└──────────────────────┘
        ███████
        ███████
```

Use:

* Strong border
* Hard shadow
* Bold label
* Clear pressed state

When pressed:

```text
shadow decreases
button moves slightly toward shadow
```

For example:

```text
Normal:
offset = 5px

Pressed:
offset = 2px
```

This should create a physical button feeling.

---

# 8. CARDS

Cards should be simple.

Example:

```text
┌─────────────────────────────┐
│ MACHINE LEARNING             │
│                             │
│ 12 VIDEOS                   │
│ 42% COMPLETE                │
│                             │
│ [ CONTINUE ]                │
└─────────────────────────────┘
       █████████
       █████████
```

Cards should contain only useful information.

Avoid:

* Excessive decorative elements
* Large shadows
* Gradients
* Floating glass effects
* Unnecessary icons

---

# 9. HOME SCREEN

Design a focused learning dashboard.

The Home screen should prioritize:

1. Continue Learning
2. Active Roadmaps
3. Recently Added
4. Recently Watched
5. Quick actions

Possible structure:

```text
HOME

Good evening.

┌─────────────────────────────┐
│ CONTINUE LEARNING           │
│                             │
│ Neural Networks             │
│ Video 07                    │
│                             │
│ ███████████░░░  72%         │
│                             │
│ [ CONTINUE ]                │
└─────────────────────────────┘

YOUR ROADMAPS

[ ML FUNDAMENTALS ]
[ DEEP LEARNING   ]

RECENTLY ADDED

[ Video ] [ Video ] [ Video ]

+ ADD CONTENT
```

Do not create a YouTube-style homepage.

There must be:

* No endless feed
* No trending section
* No recommended content feed
* No Shorts-style section
* No engagement-oriented UI

---

# 10. ROADMAP SCREEN

Roadmaps are a core feature.

Design them like a visual study plan.

Example:

```text
MACHINE LEARNING

████████████░░░  68%

01 — FOUNDATIONS
────────────────────────

✓ Linear Algebra
✓ Probability
○ Statistics

02 — MACHINE LEARNING
────────────────────────

✓ Regression
✓ Classification
○ Decision Trees

03 — DEEP LEARNING
────────────────────────

○ Neural Networks
○ CNN
○ Transformers
```

Make completion visually obvious.

Use simple checkmarks, progress indicators, and strong section headings.

---

# 11. ROADMAP BUILDER

The roadmap builder should feel like organizing study material rather than managing a playlist.

Users should be able to:

* Add videos
* Add playlists
* Reorder items
* Create sections
* Rename sections
* Remove items
* Mark topics
* View progress

Use drag-and-drop where it genuinely improves usability.

Do not overdesign the builder.

---

# 12. LIBRARY SCREEN

Library should provide a simple content collection.

Possible categories:

```text
LIBRARY

[ ALL ] [ VIDEOS ] [ PLAYLISTS ] [ SAVED ]

SEARCH...

┌─────────────────────────────┐
│ Video title                 │
│ Creator                     │
│ 18:32                       │
│ ML Fundamentals             │
└─────────────────────────────┘
```

Use compact list layouts when possible.

The user should be able to quickly locate content.

---

# 13. LEARNING PLAYER

The player is extremely important.

The player should prioritize the video and learning controls.

Structure:

```text
┌─────────────────────────────┐
│                             │
│                             │
│          VIDEO              │
│                             │
│                             │
└─────────────────────────────┘

Video Title

──────────────────────────────

01:32 ─────────────── 18:42

[ -10 ] [ PLAY ] [ +10 ]

[ SPEED ] [ NOTES ] [ SAVE ]

──────────────────────────────

NOTES

[ Add a note... ]
```

Avoid adding unnecessary video-platform UI.

Do not include:

* Recommended videos
* Comments
* Like/dislike systems
* Creator feed
* Trending content
* Social interactions
* Endless autoplay discovery

The player should feel like a **study tool**, not a video social platform.

---

# 14. NOTES UI

Notes should be first-class learning objects.

Allow:

* Typed notes
* Timestamped notes
* Handwritten note images
* PDFs
* Attachments

Example:

```text
NOTES

┌─────────────────────────────┐
│ 12:42                       │
│                             │
│ Gradient descent minimizes  │
│ the cost function.          │
│                             │
│ [ EDIT ]                    │
└─────────────────────────────┘

ATTACHMENTS

[ handwritten.png ]
[ lecture-notes.pdf ]
```

Keep the interface clean and document-like.

---

# 15. SEARCH

Search should be functional rather than visually dominant.

Use:

```text
┌─────────────────────────────┐
│ 🔎 Search videos, notes...  │
└─────────────────────────────┘
```

Allow searching across:

* Videos
* Playlists
* Roadmaps
* Notes

Use simple filters.

Avoid search suggestions designed to encourage endless browsing.

---

# 16. SETTINGS

Keep settings extremely simple.

Sections:

```text
SETTINGS

APPEARANCE
  Theme
  Text size

PLAYBACK
  Default speed
  Resume playback

STORAGE
  Storage usage
  Clear cached files

LEARNING
  Completion behavior

ABOUT
  Version
  Open-source licenses
```

Do not create unnecessary settings.

---

# 17. NAVIGATION

Use simple navigation.

Preferred primary navigation:

```text
Home
Roadmaps
Library
Notes
Settings
```

Use bottom navigation on mobile if appropriate.

Do not create a complicated navigation hierarchy.

The user should always understand:

* Where they are
* What they are studying
* How to return
* What they should do next

---

# 18. EMPTY STATES

Empty states should be useful and friendly.

Example:

```text
NO ROADMAPS YET

Build your first learning roadmap.

[ CREATE ROADMAP ]
```

Do not use large decorative illustrations unless they improve usability.

---

# 19. ERROR STATES

Errors should be direct and understandable.

Example:

```text
VIDEO UNAVAILABLE

This video could not be loaded.

[ TRY AGAIN ]

[ VIEW DETAILS ]
```

Avoid technical errors such as:

```text
MediaProviderException: HTTP 403...
```

unless the user explicitly opens technical details.

---

# 20. LOADING STATES

Use simple skeletons or minimal loading indicators.

Do not create elaborate loading animations.

The UI should feel fast.

---

# 21. RESPONSIVE DESIGN

Although the initial target is Android, structure the design so it can later adapt to:

* Phones
* Tablets
* Desktop/web

Do not hardcode screen-specific layouts unnecessarily.

Use:

* Responsive spacing
* Flexible containers
* Reusable components
* Breakpoints where appropriate

---

# 22. DARK MODE

Support dark mode through design tokens.

Do not simply invert colors.

Define a separate dark theme that maintains:

* Strong borders
* High contrast
* Neo-Brutalist character
* Readability
* Accessible text contrast

Keep the accent colors controlled.

---

# 23. ACCESSIBILITY

Neo-Brutalism must not sacrifice usability.

Ensure:

* Sufficient contrast
* Large enough touch targets
* Clear focus states
* Semantic buttons
* Screen-reader labels
* Accessible form fields
* Error states understandable without color
* Progress indicators understandable without color alone

Do not use color as the only way to communicate state.

---

# 24. MOTION

Keep animations minimal.

Use motion only when it improves interaction.

Examples:

* Button press
* Navigation transition
* Expand/collapse
* Drag/reorder
* Progress update

Avoid:

* Constant animations
* Attention-grabbing motion
* Auto-playing visual effects
* Excessive bouncing

The app is designed for concentration.

---

# 25. DESIGN SYSTEM ARCHITECTURE

Create the design system independently from individual screens.

Suggested structure:

```text
presentation/
├── design_system/
│   ├── theme/
│   ├── tokens/
│   │   ├── colors.dart
│   │   ├── spacing.dart
│   │   ├── typography.dart
│   │   ├── borders.dart
│   │   ├── shadows.dart
│   │   └── radii.dart
│   ├── components/
│   │   ├── buttons/
│   │   ├── cards/
│   │   ├── inputs/
│   │   ├── navigation/
│   │   ├── feedback/
│   │   └── player/
│   └── design_system.dart
```

Keep all reusable visual decisions here.

Screens should consume the design system instead of defining their own visual language.

---

# 26. DESIGN TOKENS

Create tokens for:

```text
Colors
Typography
Spacing
Border width
Border radius
Shadow offset
Icon size
Button height
Touch target size
Animation duration
```

Prefer a small number of consistent values.

For example:

```text
spacing:
4
8
12
16
24
32
48

border:
2
3

radius:
0
4
8
```

Neo-Brutalism generally benefits from restrained corner radii.

Avoid making every component extremely rounded.

---

# 27. VISUAL CONSISTENCY RULE

Every screen must look like it belongs to the same application.

Do not allow:

Screen A → Neo-Brutalist

Screen B → Material 3

Screen C → Glassmorphism

Screen D → iOS-style minimalism

The entire product should share one visual language.

---

# 28. IMPLEMENTATION RULES

Before implementing screens:

1. Define design tokens.
2. Define the theme.
3. Define reusable components.
4. Build component previews/examples.
5. Build the app shell.
6. Build screens using those components.
7. Verify responsive behavior.
8. Verify dark mode.
9. Verify accessibility.

Do not begin by creating individual screens with hardcoded styling.

---

# 29. ARCHITECTURE BOUNDARY

UI must not directly access:

* SQLite
* Media extractor
* Provider-specific APIs
* File system implementation
* Low-level player implementation

The UI should interact through application/domain interfaces.

For example:

```text
UI
 ↓
Application layer
 ↓
Domain interfaces
 ↓
Infrastructure implementations
```

Never:

```text
Widget
 ↓
SQLite
```

or:

```text
Widget
 ↓
NewPipe Extractor
```

or:

```text
Widget
 ↓
Media3 implementation
```

---

# 30. DO NOT OVERENGINEER

This is a personal learning application.

Prefer:

* Simple layouts
* Few screens
* Clear interactions
* Reusable components
* Local-first behavior
* Fast startup
* Minimal dependencies

Avoid:

* Design-system complexity for its own sake
* Excessive animations
* Complex navigation
* Social features
* Engagement mechanics
* Unnecessary abstractions in the UI

---

# 31. FIRST IMPLEMENTATION TASK

Start with the design system.

Do NOT immediately implement every screen.

First create:

1. Color tokens
2. Typography tokens
3. Spacing tokens
4. Border tokens
5. Shadow tokens
6. Radius tokens
7. Theme
8. Buttons
9. Cards
10. Inputs
11. Chips
12. Progress indicators
13. Navigation components
14. Loading states
15. Error states
16. Empty states

Then create a **Design System Showcase screen** containing examples of all components.

This screen will become the visual reference for the entire application.

---

# 32. SECOND IMPLEMENTATION TASK

After the design system is stable, create the application shell:

```text
Home
Roadmaps
Library
Notes
Settings
```

Use placeholder/mock data where necessary.

Do not connect production database/media functionality yet unless the existing architecture already exposes the required interfaces.

---

# 33. THIRD IMPLEMENTATION TASK

Create the Learning Player UI using mock player state.

The player should demonstrate:

* Video area
* Play/pause
* Seek
* Progress
* Playback speed
* Notes
* Timestamp
* Save/bookmark
* Loading
* Error
* Unavailable state

Keep the player UI independent from the actual player implementation.

---

# 34. DESIGN REVIEW

After implementation, perform a UI audit.

Check:

### Neo-Brutalist consistency

* Borders consistent
* Hard shadows consistent
* Typography consistent
* Accent colors controlled
* Corner radii consistent

### UX

* User can understand every screen quickly
* No unnecessary interactions
* No distracting content
* Clear primary action

### Architecture

* No UI → SQLite coupling
* No UI → extractor coupling
* No UI → Media3 coupling
* No provider-specific UI assumptions

### Accessibility

* Touch targets
* Contrast
* Focus states
* Semantic labels

### Responsive behavior

* Small phones
* Large phones
* Tablets

Fix inconsistencies before moving to the next implementation phase.

---

# 35. IMPORTANT PRODUCT PRINCIPLE

The application is a **learning environment**, not a content-consumption platform.

Every UI decision should answer:

> "Does this help the user learn?"

If a UI element exists primarily to increase browsing, engagement, or time spent inside the application, question whether it belongs.

Prioritize:

**Learning → Focus → Progress → Notes → Organization**

over:

**Discovery → Engagement → Consumption → Social interaction**

---

# FINAL CURSOR INSTRUCTION

Before changing code, inspect the existing project structure and architecture documentation.

Then:

1. Identify the current presentation/design-system structure.
2. Preserve existing architectural boundaries.
3. Implement the Neo-Brutalist design tokens.
4. Implement reusable UI components.
5. Build the Design System Showcase.
6. Build the app shell.
7. Build screen layouts using mock/application interfaces.
8. Run tests/analyzer.
9. Check accessibility.
10. Check responsive layouts.
11. Update the relevant UI/design documentation.
12. Summarize what was implemented and identify any architectural issues discovered.

Do not implement unrelated features.

Do not replace existing architecture merely to make UI implementation easier.

Keep every visual decision centralized and replaceable.
```

## Theme (JSON)

```json
{
  "schema_version": 2,
  "fonts": {
    "primary": "google:Inter",
    "secondary": "google:Inter",
    "mono": "google:JetBrains Mono"
  },
  "colors": {
    "light": {
      "primary": "#0051BA",
      "on_primary": "#FFFFFF",
      "primary_container": "#0051BA1A",
      "on_primary_container": "#1A1A1A",
      "secondary": "#1A1A1A",
      "on_secondary": "#FFFFFF",
      "secondary_container": "#1A1A1A1A",
      "on_secondary_container": "#1A1A1A",
      "accent": "#FFD700",
      "on_accent": "#000000",
      "accent_container": "#FFD7001A",
      "on_accent_container": "#1A1A1A",
      "background": "#FDFCF8",
      "on_background": "#1A1A1A",
      "secondary_background": "#F7F7F7",
      "surface": "#FFFFFF",
      "on_surface": "#1A1A1A",
      "surface_variant": "#E0E0E0",
      "on_surface_variant": "#4A4A4A",
      "primary_text": "#1A1A1A",
      "secondary_text": "#4A4A4A",
      "hint": "#8E8E8E",
      "outline": "#1A1A1A",
      "divider": "#1A1A1A",
      "success": "#00873E",
      "on_success": "#FFFFFF",
      "warning": "#FF8C00",
      "on_warning": "#FFFFFF",
      "error": "#D0021B",
      "on_error": "#FFFFFF",
      "info": "#0051BA",
      "on_info": "#FFFFFF",
      "transparent": "#00000000",
      "full_contrast": "#000000"
    },
    "dark": {
      "primary": "#3B82F6",
      "on_primary": "#FFFFFF",
      "primary_container": "#3B82F624",
      "on_primary_container": "#F7F7F7",
      "secondary": "#F7F7F7",
      "on_secondary": "#000000",
      "secondary_container": "#F7F7F724",
      "on_secondary_container": "#F7F7F7",
      "accent": "#FACC15",
      "on_accent": "#000000",
      "accent_container": "#FACC1524",
      "on_accent_container": "#F7F7F7",
      "background": "#121212",
      "on_background": "#F7F7F7",
      "secondary_background": "#1E1E1E",
      "surface": "#1A1A1A",
      "on_surface": "#F7F7F7",
      "surface_variant": "#2D2D2D",
      "on_surface_variant": "#A1A1A1",
      "primary_text": "#F7F7F7",
      "secondary_text": "#A1A1A1",
      "hint": "#666666",
      "outline": "#F7F7F7",
      "divider": "#333333",
      "success": "#22C55E",
      "on_success": "#FFFFFF",
      "warning": "#F59E0B",
      "on_warning": "#FFFFFF",
      "error": "#EF4444",
      "on_error": "#FFFFFF",
      "info": "#3B82F6",
      "on_info": "#FFFFFF",
      "transparent": "#00000000",
      "full_contrast": "#FFFFFF"
    }
  },
  "text_styles": {
    "display_large": {
      "font": "primary",
      "size": 56,
      "weight": 800,
      "height": 1.1
    },
    "display_medium": {
      "font": "primary",
      "size": 44,
      "weight": 800,
      "height": 1.1
    },
    "display_small": {
      "font": "primary",
      "size": 36,
      "weight": 800,
      "height": 1.2
    },
    "headline_large": {
      "font": "primary",
      "size": 32,
      "weight": 800,
      "height": 1.2
    },
    "headline_medium": {
      "font": "primary",
      "size": 26,
      "weight": 700,
      "height": 1.2
    },
    "headline_small": {
      "font": "primary",
      "size": 24,
      "weight": 700,
      "height": 1.2
    },
    "title_large": {
      "font": "primary",
      "size": 20,
      "weight": 700,
      "height": 1.3
    },
    "title_medium": {
      "font": "primary",
      "size": 17,
      "weight": 700,
      "height": 1.3
    },
    "title_small": {
      "font": "primary",
      "size": 14,
      "weight": 700,
      "height": 1.4
    },
    "body_large": {
      "font": "secondary",
      "size": 16,
      "weight": 400,
      "height": 1.5
    },
    "body_medium": {
      "font": "secondary",
      "size": 14,
      "weight": 400,
      "height": 1.5
    },
    "body_small": {
      "font": "secondary",
      "size": 12,
      "weight": 400,
      "height": 1.4
    },
    "label_large": {
      "font": "mono",
      "size": 14,
      "weight": 600,
      "height": 1.3
    },
    "label_medium": {
      "font": "mono",
      "size": 12,
      "weight": 600,
      "height": 1.3
    },
    "label_small": {
      "font": "mono",
      "size": 10,
      "weight": 600,
      "height": 1.3
    }
  },
  "spacing": {
    "none": 0,
    "xs": 4,
    "sm": 8,
    "md": 16,
    "lg": 24,
    "xl": 32,
    "xxl": 48,
    "xxxl": 64
  },
  "radii": {
    "none": 0,
    "xs": 0,
    "sm": 0,
    "md": 0,
    "lg": 0,
    "xl": 0,
    "xxl": 0,
    "full": 9999
  },
  "shadows": {
    "none": {
      "color": "#00000000",
      "dx": 0,
      "dy": 0,
      "blur": 0,
      "spread": 0
    },
    "xs": {
      "color": "#1A1A1A",
      "dx": 2,
      "dy": 2,
      "blur": 0,
      "spread": 0
    },
    "sm": {
      "color": "#1A1A1A",
      "dx": 4,
      "dy": 4,
      "blur": 0,
      "spread": 0
    },
    "md": {
      "color": "#1A1A1A",
      "dx": 6,
      "dy": 6,
      "blur": 0,
      "spread": 0
    },
    "lg": {
      "color": "#1A1A1A",
      "dx": 8,
      "dy": 8,
      "blur": 0,
      "spread": 0
    },
    "xl": {
      "color": "#1A1A1A",
      "dx": 10,
      "dy": 10,
      "blur": 0,
      "spread": 0
    },
    "xxl": {
      "color": "#1A1A1A",
      "dx": 12,
      "dy": 12,
      "blur": 0,
      "spread": 0
    }
  },
  "gradients": {}
}
```

## Pages

### 1. Design System Showcase

- Frame ID: `frame8`
- Original page prompt: "A reference page displaying all Neo-Brutalist components: buttons with hard shadows, bordered cards, typography hierarchy, and accent color chips."
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "scroll": {
            "boolVal": {
              "value": true
            }
          },
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "accent"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "xl",
                  "rightToken": "lg",
                  "bottomToken": "xl",
                  "leftToken": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 3,
                  "color": "outline"
                }
              }
            },
            "children": [
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "xs"
                    }
                  }
                },
                "children": [
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "DESIGN SYSTEM"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "headline_large"
                        }
                      },
                      "font_weight": {
                        "numberVal": {
                          "value": 900
                        }
                      }
                    },
                    "editorId": "text36"
                  },
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "NEO-BRUTALIST V1.0"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "title_medium"
                        }
                      },
                      "font_weight": {
                        "stringVal": {
                          "value": "bold"
                        }
                      }
                    },
                    "editorId": "text37"
                  }
                ],
                "editorId": "column17"
              }
            ],
            "editorId": "container30"
          },
          {
            "type": "column",
            "properties": {
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "spacing": {
                "stringVal": {
                  "value": "xl"
                }
              },
              "cross_align": {
                "align": {
                  "named": "stretch"
                }
              }
            },
            "children": [
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  }
                },
                "children": [
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "TYPOGRAPHY"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_small"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary"
                        }
                      },
                      "font_weight": {
                        "numberVal": {
                          "value": 900
                        }
                      }
                    },
                    "editorId": "text38"
                  },
                  {
                    "type": "divider",
                    "properties": {
                      "thickness": {
                        "numberVal": {
                          "value": 3
                        }
                      },
                      "color": {
                        "color": {
                          "color": "outline"
                        }
                      }
                    },
                    "editorId": "divider1"
                  },
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Headline Large"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "headline_large"
                        }
                      },
                      "font_weight": {
                        "numberVal": {
                          "value": 900
                        }
                      }
                    },
                    "editorId": "text39"
                  },
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Title Large Bold"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "title_large"
                        }
                      },
                      "font_weight": {
                        "stringVal": {
                          "value": "bold"
                        }
                      }
                    },
                    "editorId": "text40"
                  },
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Body Medium Regular"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "body_medium"
                        }
                      }
                    },
                    "editorId": "text41"
                  },
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "METADATA MONO"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_small"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      }
                    },
                    "editorId": "text42"
                  }
                ],
                "editorId": "column19"
              },
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  }
                },
                "children": [
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "COLOR PALETTE"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_small"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary"
                        }
                      },
                      "font_weight": {
                        "numberVal": {
                          "value": 900
                        }
                      }
                    },
                    "editorId": "text43"
                  },
                  {
                    "type": "divider",
                    "properties": {
                      "thickness": {
                        "numberVal": {
                          "value": 3
                        }
                      },
                      "color": {
                        "color": {
                          "color": "outline"
                        }
                      }
                    },
                    "editorId": "divider2"
                  },
                  {
                    "type": "grid",
                    "properties": {
                      "columns": {
                        "numberVal": {
                          "value": 1
                        }
                      },
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "shrink_wrap": {
                        "boolVal": {
                          "value": true
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "@color_chip",
                        "properties": {
                          "name": {
                            "stringVal": {
                              "value": "Primary (Electric Yellow)"
                            }
                          },
                          "color": {
                            "stringVal": {
                              "value": "primary"
                            }
                          },
                          "hex": {
                            "stringVal": {
                              "value": "#F4FF4D"
                            }
                          }
                        },
                        "editorId": "colorchip1"
                      },
                      {
                        "type": "@color_chip",
                        "properties": {
                          "name": {
                            "stringVal": {
                              "value": "Accent (Bright Blue)"
                            }
                          },
                          "color": {
                            "stringVal": {
                              "value": "accent"
                            }
                          },
                          "hex": {
                            "stringVal": {
                              "value": "#4D7BFF"
                            }
                          }
                        },
                        "editorId": "colorchip2"
                      },
                      {
                        "type": "@color_chip",
                        "properties": {
                          "name": {
                            "stringVal": {
                              "value": "Success (Acid Green)"
                            }
                          },
                          "color": {
                            "stringVal": {
                              "value": "success"
                            }
                          },
                          "hex": {
                            "stringVal": {
                              "value": "#00FF66"
                            }
                          }
                        },
                        "editorId": "colorchip3"
                      },
                      {
                        "type": "@color_chip",
                        "properties": {
                          "name": {
                            "stringVal": {
                              "value": "Surface (Pure White)"
                            }
                          },
                          "color": {
                            "stringVal": {
                              "value": "surface"
                            }
                          },
                          "hex": {
                            "stringVal": {
                              "value": "#FFFFFF"
                            }
                          }
                        },
                        "editorId": "colorchip4"
                      }
                    ],
                    "editorId": "grid1"
                  }
                ],
                "editorId": "column20"
              },
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  }
                },
                "children": [
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "INTERACTIVE COMPONENTS"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_small"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary"
                        }
                      },
                      "font_weight": {
                        "numberVal": {
                          "value": 900
                        }
                      }
                    },
                    "editorId": "text44"
                  },
                  {
                    "type": "divider",
                    "properties": {
                      "thickness": {
                        "numberVal": {
                          "value": 3
                        }
                      },
                      "color": {
                        "color": {
                          "color": "outline"
                        }
                      }
                    },
                    "editorId": "divider3"
                  },
                  {
                    "type": "row",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "@brutalist_button",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "PRIMARY"
                            }
                          },
                          "bg": {
                            "stringVal": {
                              "value": "primary"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "bolt_rounded"
                            }
                          }
                        },
                        "editorId": "brutalistbutton1"
                      },
                      {
                        "type": "@brutalist_button",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "PRESSED"
                            }
                          },
                          "bg": {
                            "stringVal": {
                              "value": "primary"
                            }
                          },
                          "is_pressed": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "editorId": "brutalistbutton2"
                      }
                    ],
                    "editorId": "row18"
                  },
                  {
                    "type": "@brutalist_button",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "SECONDARY ACTION"
                        }
                      },
                      "bg": {
                        "stringVal": {
                          "value": "surface"
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "arrow_forward_rounded"
                        }
                      }
                    },
                    "editorId": "brutalistbutton3"
                  }
                ],
                "editorId": "column21"
              },
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  }
                },
                "children": [
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "CARDS & HARD SHADOWS"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_small"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary"
                        }
                      },
                      "font_weight": {
                        "numberVal": {
                          "value": 900
                        }
                      }
                    },
                    "editorId": "text45"
                  },
                  {
                    "type": "divider",
                    "properties": {
                      "thickness": {
                        "numberVal": {
                          "value": 3
                        }
                      },
                      "color": {
                        "color": {
                          "color": "outline"
                        }
                      }
                    },
                    "editorId": "divider4"
                  },
                  {
                    "type": "@brutalist_card",
                    "properties": {
                      "title": {
                        "stringVal": {
                          "value": "Neural Networks"
                        }
                      },
                      "subtitle": {
                        "stringVal": {
                          "value": "VIDEO 07"
                        }
                      },
                      "accent_color": {
                        "stringVal": {
                          "value": "success"
                        }
                      }
                    },
                    "editorId": "brutalistcard1"
                  },
                  {
                    "type": "@brutalist_card",
                    "properties": {
                      "title": {
                        "stringVal": {
                          "value": "Linear Algebra"
                        }
                      },
                      "subtitle": {
                        "stringVal": {
                          "value": "FOUNDATIONS"
                        }
                      },
                      "accent_color": {
                        "stringVal": {
                          "value": "accent"
                        }
                      }
                    },
                    "editorId": "brutalistcard2"
                  }
                ],
                "editorId": "column22"
              },
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  }
                },
                "children": [
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "FORM ELEMENTS"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_small"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary"
                        }
                      },
                      "font_weight": {
                        "numberVal": {
                          "value": 900
                        }
                      }
                    },
                    "editorId": "text46"
                  },
                  {
                    "type": "divider",
                    "properties": {
                      "thickness": {
                        "numberVal": {
                          "value": 3
                        }
                      },
                      "color": {
                        "color": {
                          "color": "outline"
                        }
                      }
                    },
                    "editorId": "divider5"
                  },
                  {
                    "type": "container",
                    "properties": {
                      "bg": {
                        "color": {
                          "color": "surface"
                        }
                      },
                      "border": {
                        "border": {
                          "width": 3,
                          "color": "outline"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "topToken": "sm",
                          "rightToken": "md",
                          "bottomToken": "sm",
                          "leftToken": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "row",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          },
                          "cross_align": {
                            "align": {
                              "named": "center"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "icon",
                            "properties": {
                              "name": {
                                "icon": {
                                  "name": "search_rounded"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "primary_text"
                                }
                              }
                            },
                            "editorId": "icon14"
                          },
                          {
                            "type": "expanded",
                            "children": [
                              {
                                "type": "@std.textfield",
                                "properties": {
                                  "variant": {
                                    "stringVal": {
                                      "value": "ghost"
                                    }
                                  },
                                  "hint": {
                                    "stringVal": {
                                      "value": "Search roadmaps..."
                                    }
                                  },
                                  "hint_color": {
                                    "stringVal": {
                                      "value": "secondary_text"
                                    }
                                  }
                                },
                                "editorId": "stdtextfield2"
                              }
                            ],
                            "editorId": "expanded7"
                          }
                        ],
                        "editorId": "row19"
                      }
                    ],
                    "editorId": "container31"
                  },
                  {
                    "type": "row",
                    "properties": {
                      "align": {
                        "align": {
                          "named": "space_between"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Notifications"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "body_large"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text47"
                      },
                      {
                        "type": "@std.switch",
                        "properties": {
                          "active": {
                            "boolVal": {
                              "value": true
                            }
                          },
                          "variant": {
                            "stringVal": {
                              "value": "Android"
                            }
                          }
                        },
                        "editorId": "stdswitch1"
                      }
                    ],
                    "editorId": "row20"
                  }
                ],
                "editorId": "column23"
              },
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  }
                },
                "children": [
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "PROGRESS INDICATORS"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_small"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary"
                        }
                      },
                      "font_weight": {
                        "numberVal": {
                          "value": 900
                        }
                      }
                    },
                    "editorId": "text48"
                  },
                  {
                    "type": "divider",
                    "properties": {
                      "thickness": {
                        "numberVal": {
                          "value": 3
                        }
                      },
                      "color": {
                        "color": {
                          "color": "outline"
                        }
                      }
                    },
                    "editorId": "divider6"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "row",
                        "properties": {
                          "align": {
                            "align": {
                              "named": "space_between"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Learning Progress"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_medium"
                                }
                              },
                              "font_weight": {
                                "stringVal": {
                                  "value": "bold"
                                }
                              }
                            },
                            "editorId": "text49"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "72%"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_medium"
                                }
                              },
                              "font_weight": {
                                "stringVal": {
                                  "value": "bold"
                                }
                              }
                            },
                            "editorId": "text50"
                          }
                        ],
                        "editorId": "row21"
                      },
                      {
                        "type": "container",
                        "properties": {
                          "height": {
                            "px": {
                              "value": 24,
                              "isInfinity": false
                            }
                          },
                          "bg": {
                            "color": {
                              "color": "surface"
                            }
                          },
                          "border": {
                            "border": {
                              "width": 3,
                              "color": "outline"
                            }
                          },
                          "clip": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "row",
                            "children": [
                              {
                                "type": "container",
                                "properties": {
                                  "width": {
                                    "px": {
                                      "value": 280,
                                      "isInfinity": false
                                    }
                                  },
                                  "height": {
                                    "px": {
                                      "value": 24,
                                      "isInfinity": false
                                    }
                                  },
                                  "bg": {
                                    "color": {
                                      "color": "success"
                                    }
                                  },
                                  "border": {
                                    "borderSided": {
                                      "side": "right",
                                      "width": 3,
                                      "color": "outline"
                                    }
                                  }
                                },
                                "editorId": "container33"
                              },
                              {
                                "type": "spacer",
                                "editorId": "spacer1"
                              }
                            ],
                            "editorId": "row22"
                          }
                        ],
                        "editorId": "container32"
                      }
                    ],
                    "editorId": "column25"
                  }
                ],
                "editorId": "column24"
              }
            ],
            "editorId": "column18"
          },
          {
            "type": "sizedbox",
            "properties": {
              "height": {
                "stringVal": {
                  "value": "lg"
                }
              }
            },
            "editorId": "sizedbox1"
          }
        ],
        "editorId": "column16"
      }
    ],
    "editorId": "scaffold1"
  }
}
```

### 2. Home Dashboard

- Frame ID: `frame5`
- Original page prompt: "A focused dashboard showing 'Continue Learning' card, active roadmaps, and quick actions to add content."
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "#FDFCF0"
        }
      },
      "safe_area": {
        "boolVal": {
          "value": true
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 3,
                  "color": "outline"
                }
              },
              "bg": {
                "color": {
                  "color": "surface"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "align": {
                    "align": {
                      "named": "space_between"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Good evening,"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "body_medium"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text51"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Alex Rivera"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "headline_medium"
                            }
                          },
                          "font_weight": {
                            "numberVal": {
                              "value": 900
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "text52"
                      }
                    ],
                    "editorId": "column27"
                  },
                  {
                    "type": "container",
                    "properties": {
                      "width": {
                        "px": {
                          "value": 48,
                          "isInfinity": false
                        }
                      },
                      "height": {
                        "px": {
                          "value": 48,
                          "isInfinity": false
                        }
                      },
                      "bg": {
                        "color": {
                          "color": "accent"
                        }
                      },
                      "border": {
                        "border": {
                          "width": 2,
                          "color": "outline"
                        }
                      },
                      "shadow": {
                        "shadow": {
                          "color": "on_accent",
                          "dx": 4,
                          "dy": 4,
                          "blur": 0,
                          "spread": 0
                        }
                      },
                      "align_child": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "icon",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "person_rounded"
                            }
                          },
                          "size": {
                            "numberVal": {
                              "value": 28
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "icon15"
                      }
                    ],
                    "editorId": "container35"
                  }
                ],
                "editorId": "row23"
              }
            ],
            "editorId": "container34"
          },
          {
            "type": "expanded",
            "children": [
              {
                "type": "column",
                "properties": {
                  "scroll": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "spacing": {
                    "stringVal": {
                      "value": "xl"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "stretch"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "CONTINUE LEARNING"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_large"
                            }
                          },
                          "font_weight": {
                            "numberVal": {
                              "value": 900
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text53"
                      },
                      {
                        "type": "@brutal_card",
                        "properties": {
                          "title": {
                            "stringVal": {
                              "value": "Neural Networks"
                            }
                          },
                          "subtitle": {
                            "stringVal": {
                              "value": "Video 07 · Deep Learning Specialization"
                            }
                          },
                          "tone": {
                            "stringVal": {
                              "value": "on_primary"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "column",
                            "properties": {
                              "spacing": {
                                "stringVal": {
                                  "value": "md"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "row",
                                "properties": {
                                  "align": {
                                    "align": {
                                      "named": "space_between"
                                    }
                                  }
                                },
                                "children": [
                                  {
                                    "type": "text",
                                    "properties": {
                                      "content": {
                                        "stringVal": {
                                          "value": "72% Complete"
                                        }
                                      },
                                      "style": {
                                        "textStyle": {
                                          "styleName": "label_medium"
                                        }
                                      },
                                      "font_weight": {
                                        "stringVal": {
                                          "value": "bold"
                                        }
                                      },
                                      "color": {
                                        "color": {
                                          "color": "primary_text"
                                        }
                                      }
                                    },
                                    "editorId": "text54"
                                  },
                                  {
                                    "type": "text",
                                    "properties": {
                                      "content": {
                                        "stringVal": {
                                          "value": "12:45 / 18:30"
                                        }
                                      },
                                      "style": {
                                        "textStyle": {
                                          "styleName": "label_small"
                                        }
                                      },
                                      "color": {
                                        "color": {
                                          "color": "secondary_text"
                                        }
                                      }
                                    },
                                    "editorId": "text55"
                                  }
                                ],
                                "editorId": "row24"
                              },
                              {
                                "type": "container",
                                "properties": {
                                  "height": {
                                    "px": {
                                      "value": 16,
                                      "isInfinity": false
                                    }
                                  },
                                  "bg": {
                                    "color": {
                                      "color": "surface_variant"
                                    }
                                  },
                                  "border": {
                                    "border": {
                                      "width": 2,
                                      "color": "outline"
                                    }
                                  },
                                  "clip": {
                                    "boolVal": {
                                      "value": true
                                    }
                                  }
                                },
                                "children": [
                                  {
                                    "type": "container",
                                    "properties": {
                                      "width": {
                                        "px": {
                                          "value": 240,
                                          "isInfinity": false
                                        }
                                      },
                                      "bg": {
                                        "color": {
                                          "color": "success"
                                        }
                                      },
                                      "border": {
                                        "borderSided": {
                                          "side": "right",
                                          "width": 2,
                                          "color": "outline"
                                        }
                                      }
                                    },
                                    "editorId": "container37"
                                  }
                                ],
                                "editorId": "container36"
                              },
                              {
                                "type": "@std.button",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "CONTINUE"
                                    }
                                  },
                                  "icon": {
                                    "stringVal": {
                                      "value": "play_arrow_rounded"
                                    }
                                  },
                                  "full_width": {
                                    "boolVal": {
                                      "value": true
                                    }
                                  },
                                  "variant": {
                                    "stringVal": {
                                      "value": "primary"
                                    }
                                  }
                                },
                                "editorId": "stdbutton2"
                              }
                            ],
                            "editorId": "column30"
                          }
                        ],
                        "editorId": "brutalcard1"
                      }
                    ],
                    "editorId": "column29"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "stretch"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "row",
                        "properties": {
                          "align": {
                            "align": {
                              "named": "space_between"
                            }
                          },
                          "cross_align": {
                            "align": {
                              "named": "center"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "YOUR ROADMAPS"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_large"
                                }
                              },
                              "font_weight": {
                                "numberVal": {
                                  "value": 900
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "secondary_text"
                                }
                              }
                            },
                            "editorId": "text56"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "VIEW ALL"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_small"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "primary"
                                }
                              },
                              "font_weight": {
                                "stringVal": {
                                  "value": "bold"
                                }
                              },
                              "decoration": {
                                "stringVal": {
                                  "value": "underline"
                                }
                              }
                            },
                            "editorId": "text57"
                          }
                        ],
                        "editorId": "row25"
                      },
                      {
                        "type": "wrap",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          },
                          "run_spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "@roadmap_chip",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "ML FUNDAMENTALS"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "#FFFF00"
                                }
                              }
                            },
                            "editorId": "roadmapchip1"
                          },
                          {
                            "type": "@roadmap_chip",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "DEEP LEARNING"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "#00FFFF"
                                }
                              }
                            },
                            "editorId": "roadmapchip2"
                          },
                          {
                            "type": "@roadmap_chip",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "PYTHON FOR DATA"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "#FF00FF"
                                }
                              }
                            },
                            "editorId": "roadmapchip3"
                          }
                        ],
                        "editorId": "wrap1"
                      }
                    ],
                    "editorId": "column31"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "stretch"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "RECENTLY ADDED"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_large"
                            }
                          },
                          "font_weight": {
                            "numberVal": {
                              "value": 900
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text58"
                      },
                      {
                        "type": "row",
                        "properties": {
                          "scroll": {
                            "boolVal": {
                              "value": true
                            }
                          },
                          "spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "container",
                            "properties": {
                              "width": {
                                "px": {
                                  "value": 200,
                                  "isInfinity": false
                                }
                              },
                              "bg": {
                                "color": {
                                  "color": "surface"
                                }
                              },
                              "border": {
                                "border": {
                                  "width": 3,
                                  "color": "outline"
                                }
                              },
                              "shadow": {
                                "shadow": {
                                  "color": "on_accent",
                                  "dx": 4,
                                  "dy": 4,
                                  "blur": 0,
                                  "spread": 0
                                }
                              },
                              "padding": {
                                "edgeInsets": {
                                  "top": 0,
                                  "right": 0,
                                  "bottom": 0,
                                  "left": 0,
                                  "token": "md"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "column",
                                "properties": {
                                  "spacing": {
                                    "stringVal": {
                                      "value": "sm"
                                    }
                                  }
                                },
                                "children": [
                                  {
                                    "type": "container",
                                    "properties": {
                                      "height": {
                                        "px": {
                                          "value": 100,
                                          "isInfinity": false
                                        }
                                      },
                                      "bg": {
                                        "color": {
                                          "color": "surface_variant"
                                        }
                                      },
                                      "border": {
                                        "border": {
                                          "width": 2,
                                          "color": "outline"
                                        }
                                      },
                                      "align_child": {
                                        "align": {
                                          "named": "center"
                                        }
                                      }
                                    },
                                    "children": [
                                      {
                                        "type": "icon",
                                        "properties": {
                                          "name": {
                                            "icon": {
                                              "name": "video_library_rounded"
                                            }
                                          },
                                          "size": {
                                            "numberVal": {
                                              "value": 32
                                            }
                                          },
                                          "color": {
                                            "color": {
                                              "color": "secondary_text"
                                            }
                                          }
                                        },
                                        "editorId": "icon16"
                                      }
                                    ],
                                    "editorId": "container39"
                                  },
                                  {
                                    "type": "text",
                                    "properties": {
                                      "content": {
                                        "stringVal": {
                                          "value": "Transformer Models"
                                        }
                                      },
                                      "style": {
                                        "textStyle": {
                                          "styleName": "title_small"
                                        }
                                      },
                                      "font_weight": {
                                        "stringVal": {
                                          "value": "bold"
                                        }
                                      },
                                      "max_lines": {
                                        "numberVal": {
                                          "value": 1
                                        }
                                      },
                                      "overflow": {
                                        "stringVal": {
                                          "value": "ellipsis"
                                        }
                                      }
                                    },
                                    "editorId": "text59"
                                  }
                                ],
                                "editorId": "column33"
                              }
                            ],
                            "editorId": "container38"
                          },
                          {
                            "type": "container",
                            "properties": {
                              "width": {
                                "px": {
                                  "value": 200,
                                  "isInfinity": false
                                }
                              },
                              "bg": {
                                "color": {
                                  "color": "surface"
                                }
                              },
                              "border": {
                                "border": {
                                  "width": 3,
                                  "color": "outline"
                                }
                              },
                              "shadow": {
                                "shadow": {
                                  "color": "on_accent",
                                  "dx": 4,
                                  "dy": 4,
                                  "blur": 0,
                                  "spread": 0
                                }
                              },
                              "padding": {
                                "edgeInsets": {
                                  "top": 0,
                                  "right": 0,
                                  "bottom": 0,
                                  "left": 0,
                                  "token": "md"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "column",
                                "properties": {
                                  "spacing": {
                                    "stringVal": {
                                      "value": "sm"
                                    }
                                  }
                                },
                                "children": [
                                  {
                                    "type": "container",
                                    "properties": {
                                      "height": {
                                        "px": {
                                          "value": 100,
                                          "isInfinity": false
                                        }
                                      },
                                      "bg": {
                                        "color": {
                                          "color": "surface_variant"
                                        }
                                      },
                                      "border": {
                                        "border": {
                                          "width": 2,
                                          "color": "outline"
                                        }
                                      },
                                      "align_child": {
                                        "align": {
                                          "named": "center"
                                        }
                                      }
                                    },
                                    "children": [
                                      {
                                        "type": "icon",
                                        "properties": {
                                          "name": {
                                            "icon": {
                                              "name": "video_library_rounded"
                                            }
                                          },
                                          "size": {
                                            "numberVal": {
                                              "value": 32
                                            }
                                          },
                                          "color": {
                                            "color": {
                                              "color": "secondary_text"
                                            }
                                          }
                                        },
                                        "editorId": "icon17"
                                      }
                                    ],
                                    "editorId": "container41"
                                  },
                                  {
                                    "type": "text",
                                    "properties": {
                                      "content": {
                                        "stringVal": {
                                          "value": "Backpropagation 101"
                                        }
                                      },
                                      "style": {
                                        "textStyle": {
                                          "styleName": "title_small"
                                        }
                                      },
                                      "font_weight": {
                                        "stringVal": {
                                          "value": "bold"
                                        }
                                      },
                                      "max_lines": {
                                        "numberVal": {
                                          "value": 1
                                        }
                                      },
                                      "overflow": {
                                        "stringVal": {
                                          "value": "ellipsis"
                                        }
                                      }
                                    },
                                    "editorId": "text60"
                                  }
                                ],
                                "editorId": "column34"
                              }
                            ],
                            "editorId": "container40"
                          }
                        ],
                        "editorId": "row26"
                      }
                    ],
                    "editorId": "column32"
                  }
                ],
                "editorId": "column28"
              }
            ],
            "editorId": "expanded8"
          },
          {
            "type": "container",
            "properties": {
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "top",
                  "width": 3,
                  "color": "outline"
                }
              },
              "bg": {
                "color": {
                  "color": "surface"
                }
              }
            },
            "children": [
              {
                "type": "@std.button",
                "properties": {
                  "content": {
                    "stringVal": {
                      "value": "ADD CONTENT"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "add_rounded"
                    }
                  },
                  "full_width": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "size": {
                    "stringVal": {
                      "value": "large"
                    }
                  }
                },
                "editorId": "stdbutton3"
              }
            ],
            "editorId": "container42"
          },
          {
            "type": "@std.bottom_nav",
            "children": [
              {
                "type": "@std.nav_item",
                "properties": {
                  "target": {
                    "stringVal": {
                      "value": "home"
                    }
                  },
                  "label": {
                    "stringVal": {
                      "value": "Home"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "home_rounded"
                    }
                  },
                  "selected": {
                    "boolVal": {
                      "value": true
                    }
                  }
                },
                "editorId": "stdnavitem1"
              },
              {
                "type": "@std.nav_item",
                "properties": {
                  "target": {
                    "stringVal": {
                      "value": "roadmaps"
                    }
                  },
                  "label": {
                    "stringVal": {
                      "value": "Roadmaps"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "map_rounded"
                    }
                  }
                },
                "editorId": "stdnavitem2"
              },
              {
                "type": "@std.nav_item",
                "properties": {
                  "target": {
                    "stringVal": {
                      "value": "library"
                    }
                  },
                  "label": {
                    "stringVal": {
                      "value": "Library"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "local_library_rounded"
                    }
                  }
                },
                "editorId": "stdnavitem3"
              },
              {
                "type": "@std.nav_item",
                "properties": {
                  "target": {
                    "stringVal": {
                      "value": "notes"
                    }
                  },
                  "label": {
                    "stringVal": {
                      "value": "Notes"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "edit_note_rounded"
                    }
                  }
                },
                "editorId": "stdnavitem4"
              },
              {
                "type": "@std.nav_item",
                "properties": {
                  "target": {
                    "stringVal": {
                      "value": "settings"
                    }
                  },
                  "label": {
                    "stringVal": {
                      "value": "Settings"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "settings_rounded"
                    }
                  }
                },
                "editorId": "stdnavitem5"
              }
            ],
            "editorId": "stdbottomnav1"
          }
        ],
        "editorId": "column26"
      }
    ],
    "editorId": "scaffold2"
  }
}
```

### 3. Roadmap View

- Frame ID: `frame1`
- Original page prompt: "A structured study plan showing sections, video titles, and progress indicators with high-contrast borders."
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "xl",
                  "rightToken": "lg",
                  "bottomToken": "md",
                  "leftToken": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 3,
                  "color": "outline"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "align": {
                    "align": {
                      "named": "space_between"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "ROADMAP"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary"
                            }
                          }
                        },
                        "editorId": "text61"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Machine Learning"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "headline_medium"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "text62"
                      }
                    ],
                    "editorId": "column36"
                  },
                  {
                    "type": "iconbutton",
                    "properties": {
                      "name": {
                        "icon": {
                          "name": "more_vert_rounded"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary_text"
                        }
                      },
                      "bg": {
                        "color": {
                          "color": "surface"
                        }
                      },
                      "border": {
                        "border": {
                          "width": 2,
                          "color": "outline"
                        }
                      },
                      "shadow": {
                        "stringVal": {
                          "value": "xs"
                        }
                      }
                    },
                    "editorId": "iconbutton5"
                  }
                ],
                "editorId": "row27"
              }
            ],
            "editorId": "container43"
          },
          {
            "type": "expanded",
            "children": [
              {
                "type": "column",
                "properties": {
                  "scroll": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "spacing": {
                    "stringVal": {
                      "value": "lg"
                    }
                  }
                },
                "children": [
                  {
                    "type": "container",
                    "properties": {
                      "bg": {
                        "color": {
                          "color": "surface"
                        }
                      },
                      "border": {
                        "border": {
                          "width": 3,
                          "color": "outline"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "token": "lg"
                        }
                      },
                      "shadow": {
                        "stringVal": {
                          "value": "sm"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          },
                          "cross_align": {
                            "align": {
                              "named": "stretch"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "row",
                            "properties": {
                              "align": {
                                "align": {
                                  "named": "space_between"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "TOTAL PROGRESS"
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "label_medium"
                                    }
                                  },
                                  "color": {
                                    "color": {
                                      "color": "secondary_text"
                                    }
                                  }
                                },
                                "editorId": "text63"
                              },
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "68%"
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "label_medium"
                                    }
                                  },
                                  "color": {
                                    "color": {
                                      "color": "primary"
                                    }
                                  },
                                  "font_weight": {
                                    "stringVal": {
                                      "value": "bold"
                                    }
                                  }
                                },
                                "editorId": "text64"
                              }
                            ],
                            "editorId": "row28"
                          },
                          {
                            "type": "container",
                            "properties": {
                              "height": {
                                "px": {
                                  "value": 24,
                                  "isInfinity": false
                                }
                              },
                              "bg": {
                                "color": {
                                  "color": "surface_variant"
                                }
                              },
                              "border": {
                                "border": {
                                  "width": 2,
                                  "color": "outline"
                                }
                              },
                              "clip": {
                                "boolVal": {
                                  "value": true
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "container",
                                "properties": {
                                  "width": {
                                    "px": {
                                      "value": 240,
                                      "isInfinity": false
                                    }
                                  },
                                  "bg": {
                                    "color": {
                                      "color": "success"
                                    }
                                  },
                                  "align_child": {
                                    "align": {
                                      "named": "center"
                                    }
                                  }
                                },
                                "editorId": "container46"
                              }
                            ],
                            "editorId": "container45"
                          }
                        ],
                        "editorId": "column38"
                      }
                    ],
                    "editorId": "container44"
                  },
                  {
                    "type": "@section_header",
                    "properties": {
                      "title": {
                        "stringVal": {
                          "value": "01 Foundations"
                        }
                      },
                      "count": {
                        "stringVal": {
                          "value": "3 ITEMS"
                        }
                      }
                    },
                    "editorId": "sectionheader1"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "@learning_card",
                        "properties": {
                          "title": {
                            "stringVal": {
                              "value": "Linear Algebra for ML"
                            }
                          },
                          "duration": {
                            "stringVal": {
                              "value": "45:20"
                            }
                          },
                          "completed": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "editorId": "learningcard1"
                      },
                      {
                        "type": "@learning_card",
                        "properties": {
                          "title": {
                            "stringVal": {
                              "value": "Probability & Statistics"
                            }
                          },
                          "duration": {
                            "stringVal": {
                              "value": "1:12:05"
                            }
                          },
                          "completed": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "editorId": "learningcard2"
                      },
                      {
                        "type": "@learning_card",
                        "properties": {
                          "title": {
                            "stringVal": {
                              "value": "Calculus Refresher"
                            }
                          },
                          "duration": {
                            "stringVal": {
                              "value": "38:15"
                            }
                          },
                          "active": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "editorId": "learningcard3"
                      }
                    ],
                    "editorId": "column39"
                  },
                  {
                    "type": "@section_header",
                    "properties": {
                      "title": {
                        "stringVal": {
                          "value": "02 Supervised Learning"
                        }
                      },
                      "count": {
                        "stringVal": {
                          "value": "4 ITEMS"
                        }
                      }
                    },
                    "editorId": "sectionheader2"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "@learning_card",
                        "properties": {
                          "title": {
                            "stringVal": {
                              "value": "Linear Regression"
                            }
                          },
                          "duration": {
                            "stringVal": {
                              "value": "52:00"
                            }
                          }
                        },
                        "editorId": "learningcard4"
                      },
                      {
                        "type": "@learning_card",
                        "properties": {
                          "title": {
                            "stringVal": {
                              "value": "Logistic Regression"
                            }
                          },
                          "duration": {
                            "stringVal": {
                              "value": "48:10"
                            }
                          }
                        },
                        "editorId": "learningcard5"
                      },
                      {
                        "type": "@learning_card",
                        "properties": {
                          "title": {
                            "stringVal": {
                              "value": "Decision Trees"
                            }
                          },
                          "duration": {
                            "stringVal": {
                              "value": "1:05:30"
                            }
                          }
                        },
                        "editorId": "learningcard6"
                      },
                      {
                        "type": "@learning_card",
                        "properties": {
                          "title": {
                            "stringVal": {
                              "value": "Support Vector Machines"
                            }
                          },
                          "duration": {
                            "stringVal": {
                              "value": "55:00"
                            }
                          }
                        },
                        "editorId": "learningcard7"
                      }
                    ],
                    "editorId": "column40"
                  }
                ],
                "editorId": "column37"
              }
            ],
            "editorId": "expanded9"
          },
          {
            "type": "stack",
            "properties": {
              "height": {
                "px": {
                  "value": 0,
                  "isInfinity": false
                }
              }
            },
            "children": [
              {
                "type": "container",
                "properties": {
                  "align": {
                    "align": {
                      "named": "bottom_right"
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "rightToken": "lg",
                      "bottomToken": "xxl",
                      "leftToken": "lg"
                    }
                  }
                },
                "children": [
                  {
                    "type": "container",
                    "properties": {
                      "width": {
                        "px": {
                          "value": 64,
                          "isInfinity": false
                        }
                      },
                      "height": {
                        "px": {
                          "value": 64,
                          "isInfinity": false
                        }
                      },
                      "bg": {
                        "color": {
                          "color": "primary"
                        }
                      },
                      "border": {
                        "border": {
                          "width": 3,
                          "color": "outline"
                        }
                      },
                      "shadow": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "align_child": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "icon",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "add_rounded"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "surface"
                            }
                          },
                          "size": {
                            "numberVal": {
                              "value": 32
                            }
                          }
                        },
                        "editorId": "icon18"
                      }
                    ],
                    "editorId": "container48"
                  }
                ],
                "editorId": "container47"
              }
            ],
            "editorId": "stack1"
          }
        ],
        "editorId": "column35"
      }
    ],
    "editorId": "scaffold3"
  }
}
```

### 4. Roadmap Builder

- Frame ID: `frame2`
- Original page prompt: "An interface to organize videos into sections, reorder items, and name study modules."
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "xl",
                  "rightToken": "lg",
                  "bottomToken": "md",
                  "leftToken": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 3,
                  "color": "outline"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "align": {
                    "align": {
                      "named": "space_between"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "BUILDER"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary"
                            }
                          }
                        },
                        "editorId": "text65"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Machine Learning Plan"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "headline_medium"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "text66"
                      }
                    ],
                    "editorId": "column42"
                  },
                  {
                    "type": "row",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "sm"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "@std.button",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Preview"
                            }
                          },
                          "variant": {
                            "stringVal": {
                              "value": "secondary"
                            }
                          },
                          "size": {
                            "stringVal": {
                              "value": "small"
                            }
                          }
                        },
                        "editorId": "stdbutton4"
                      },
                      {
                        "type": "@std.button",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Save"
                            }
                          },
                          "variant": {
                            "stringVal": {
                              "value": "primary"
                            }
                          },
                          "size": {
                            "stringVal": {
                              "value": "small"
                            }
                          }
                        },
                        "editorId": "stdbutton5"
                      }
                    ],
                    "editorId": "row30"
                  }
                ],
                "editorId": "row29"
              }
            ],
            "editorId": "container49"
          },
          {
            "type": "expanded",
            "children": [
              {
                "type": "column",
                "properties": {
                  "scroll": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "spacing": {
                    "stringVal": {
                      "value": "xl"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "stretch"
                    }
                  }
                },
                "children": [
                  {
                    "type": "container",
                    "properties": {
                      "bg": {
                        "color": {
                          "color": "surface"
                        }
                      },
                      "border": {
                        "border": {
                          "width": 3,
                          "color": "outline"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "token": "lg"
                        }
                      },
                      "shadow": {
                        "stringVal": {
                          "value": "sm"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "@std.textfield",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "Roadmap Title"
                                }
                              },
                              "value": {
                                "stringVal": {
                                  "value": "Machine Learning Fundamentals"
                                }
                              },
                              "variant": {
                                "stringVal": {
                                  "value": "outlined"
                                }
                              }
                            },
                            "editorId": "stdtextfield3"
                          },
                          {
                            "type": "@std.textfield",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "Description"
                                }
                              },
                              "hint": {
                                "stringVal": {
                                  "value": "Step-by-step path from zero to hero"
                                }
                              },
                              "variant": {
                                "stringVal": {
                                  "value": "outlined"
                                }
                              }
                            },
                            "editorId": "stdtextfield4"
                          }
                        ],
                        "editorId": "column44"
                      }
                    ],
                    "editorId": "container50"
                  },
                  {
                    "type": "@builder_section",
                    "properties": {
                      "title": {
                        "stringVal": {
                          "value": "01 Foundations"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "sm"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "@builder_item",
                            "properties": {
                              "title": {
                                "stringVal": {
                                  "value": "Linear Algebra for ML"
                                }
                              },
                              "duration": {
                                "stringVal": {
                                  "value": "45:20"
                                }
                              }
                            },
                            "editorId": "builderitem1"
                          },
                          {
                            "type": "@builder_item",
                            "properties": {
                              "title": {
                                "stringVal": {
                                  "value": "Probability & Statistics"
                                }
                              },
                              "duration": {
                                "stringVal": {
                                  "value": "1:12:05"
                                }
                              }
                            },
                            "editorId": "builderitem2"
                          },
                          {
                            "type": "@builder_item",
                            "properties": {
                              "title": {
                                "stringVal": {
                                  "value": "Calculus Refresher"
                                }
                              },
                              "duration": {
                                "stringVal": {
                                  "value": "38:15"
                                }
                              }
                            },
                            "editorId": "builderitem3"
                          }
                        ],
                        "editorId": "column45"
                      }
                    ],
                    "editorId": "buildersection1"
                  },
                  {
                    "type": "@builder_section",
                    "properties": {
                      "title": {
                        "stringVal": {
                          "value": "02 Supervised Learning"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "sm"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "@builder_item",
                            "properties": {
                              "title": {
                                "stringVal": {
                                  "value": "Linear Regression"
                                }
                              },
                              "duration": {
                                "stringVal": {
                                  "value": "52:00"
                                }
                              }
                            },
                            "editorId": "builderitem4"
                          },
                          {
                            "type": "@builder_item",
                            "properties": {
                              "title": {
                                "stringVal": {
                                  "value": "Logistic Regression"
                                }
                              },
                              "duration": {
                                "stringVal": {
                                  "value": "48:10"
                                }
                              }
                            },
                            "editorId": "builderitem5"
                          }
                        ],
                        "editorId": "column46"
                      }
                    ],
                    "editorId": "buildersection2"
                  },
                  {
                    "type": "container",
                    "properties": {
                      "bg": {
                        "color": {
                          "color": "surface_variant"
                        }
                      },
                      "border": {
                        "border": {
                          "width": 2,
                          "color": "outline"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "token": "lg"
                        }
                      },
                      "align_child": {
                        "align": {
                          "named": "center"
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 8,
                          "topRight": 8,
                          "bottomLeft": 8,
                          "bottomRight": 8
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "sm"
                            }
                          },
                          "cross_align": {
                            "align": {
                              "named": "center"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "icon",
                            "properties": {
                              "name": {
                                "icon": {
                                  "name": "add_box_rounded"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "secondary_text"
                                }
                              },
                              "size": {
                                "numberVal": {
                                  "value": 32
                                }
                              }
                            },
                            "editorId": "icon19"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Tap to add a new study module"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "body_small"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "secondary_text"
                                }
                              }
                            },
                            "editorId": "text67"
                          },
                          {
                            "type": "@std.button",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "New Section"
                                }
                              },
                              "variant": {
                                "stringVal": {
                                  "value": "ghost"
                                }
                              },
                              "size": {
                                "stringVal": {
                                  "value": "small"
                                }
                              }
                            },
                            "editorId": "stdbutton6"
                          }
                        ],
                        "editorId": "column47"
                      }
                    ],
                    "editorId": "container51"
                  }
                ],
                "editorId": "column43"
              }
            ],
            "editorId": "expanded10"
          },
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "md",
                  "rightToken": "lg",
                  "bottomToken": "md",
                  "leftToken": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "top",
                  "width": 3,
                  "color": "outline"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  }
                },
                "children": [
                  {
                    "type": "expanded",
                    "children": [
                      {
                        "type": "@std.button",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Add Video URL"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "link_rounded"
                            }
                          },
                          "variant": {
                            "stringVal": {
                              "value": "outline"
                            }
                          },
                          "full_width": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "editorId": "stdbutton7"
                      }
                    ],
                    "editorId": "expanded11"
                  },
                  {
                    "type": "expanded",
                    "children": [
                      {
                        "type": "@std.button",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Import Playlist"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "playlist_add_rounded"
                            }
                          },
                          "variant": {
                            "stringVal": {
                              "value": "outline"
                            }
                          },
                          "full_width": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "editorId": "stdbutton8"
                      }
                    ],
                    "editorId": "expanded12"
                  }
                ],
                "editorId": "row31"
              }
            ],
            "editorId": "container52"
          }
        ],
        "editorId": "column41"
      }
    ],
    "editorId": "scaffold4"
  }
}
```

### 5. Learning Player

- Frame ID: `frame9`
- Original page prompt: "Distraction-free video player with bold playback controls, speed selector, and a quick-note entry area."
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "aspect_ratio": {
                "numberVal": {
                  "value": 1.77
                }
              },
              "bg": {
                "color": {
                  "color": "on_accent"
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 3,
                  "color": "outline"
                }
              },
              "align_child": {
                "align": {
                  "named": "center"
                }
              }
            },
            "children": [
              {
                "type": "stack",
                "children": [
                  {
                    "type": "container",
                    "properties": {
                      "bg": {
                        "color": {
                          "color": "on_primary_container"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "icon",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "play_circle_filled_rounded"
                            }
                          },
                          "size": {
                            "numberVal": {
                              "value": 64
                            }
                          },
                          "color": {
                            "color": {
                              "color": "surface",
                              "opacityPercent": 40
                            }
                          }
                        },
                        "editorId": "icon20"
                      }
                    ],
                    "editorId": "container54"
                  },
                  {
                    "type": "container",
                    "properties": {
                      "align": {
                        "align": {
                          "named": "top_center"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "token": "md"
                        }
                      },
                      "height": {
                        "px": {
                          "value": 60,
                          "isInfinity": false
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "row",
                        "properties": {
                          "align": {
                            "align": {
                              "named": "space_between"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "iconbutton",
                            "properties": {
                              "name": {
                                "icon": {
                                  "name": "arrow_back_rounded"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "surface"
                                }
                              },
                              "bg": {
                                "color": {
                                  "color": "on_accent",
                                  "opacityPercent": 50
                                }
                              },
                              "radius": {
                                "radius": {
                                  "topLeft": 0,
                                  "topRight": 0,
                                  "bottomLeft": 0,
                                  "bottomRight": 0
                                }
                              }
                            },
                            "editorId": "iconbutton6"
                          },
                          {
                            "type": "iconbutton",
                            "properties": {
                              "name": {
                                "icon": {
                                  "name": "cast_rounded"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "surface"
                                }
                              },
                              "bg": {
                                "color": {
                                  "color": "on_accent",
                                  "opacityPercent": 50
                                }
                              },
                              "radius": {
                                "radius": {
                                  "topLeft": 0,
                                  "topRight": 0,
                                  "bottomLeft": 0,
                                  "bottomRight": 0
                                }
                              }
                            },
                            "editorId": "iconbutton7"
                          }
                        ],
                        "editorId": "row32"
                      }
                    ],
                    "editorId": "container55"
                  }
                ],
                "editorId": "stack2"
              }
            ],
            "editorId": "container53"
          },
          {
            "type": "expanded",
            "children": [
              {
                "type": "column",
                "properties": {
                  "scroll": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "spacing": {
                    "stringVal": {
                      "value": "lg"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "start"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "07. Neural Networks: Backpropagation"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "headline_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text68"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Machine Learning Fundamentals · 18:42"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_medium"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text69"
                      }
                    ],
                    "editorId": "column50"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "sm"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "container",
                        "properties": {
                          "height": {
                            "px": {
                              "value": 12,
                              "isInfinity": false
                            }
                          },
                          "bg": {
                            "color": {
                              "color": "surface_variant"
                            }
                          },
                          "border": {
                            "border": {
                              "width": 3,
                              "color": "outline"
                            }
                          },
                          "clip": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "container",
                            "properties": {
                              "width": {
                                "px": {
                                  "value": 120,
                                  "isInfinity": false
                                }
                              },
                              "bg": {
                                "color": {
                                  "color": "primary"
                                }
                              }
                            },
                            "editorId": "container57"
                          }
                        ],
                        "editorId": "container56"
                      },
                      {
                        "type": "row",
                        "properties": {
                          "align": {
                            "align": {
                              "named": "space_between"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "01:32"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_small"
                                }
                              },
                              "font_weight": {
                                "stringVal": {
                                  "value": "bold"
                                }
                              }
                            },
                            "editorId": "text70"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "18:42"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_small"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "secondary_text"
                                }
                              }
                            },
                            "editorId": "text71"
                          }
                        ],
                        "editorId": "row33"
                      }
                    ],
                    "editorId": "column51"
                  },
                  {
                    "type": "row",
                    "properties": {
                      "align": {
                        "align": {
                          "named": "space_evenly"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "@brutalist_control_btn",
                        "properties": {
                          "icon": {
                            "stringVal": {
                              "value": "replay_10_rounded"
                            }
                          },
                          "small": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "editorId": "brutalistcontrolbtn1"
                      },
                      {
                        "type": "@brutalist_control_btn",
                        "properties": {
                          "icon": {
                            "stringVal": {
                              "value": "pause_rounded"
                            }
                          },
                          "bg": {
                            "stringVal": {
                              "value": "accent"
                            }
                          }
                        },
                        "editorId": "brutalistcontrolbtn2"
                      },
                      {
                        "type": "@brutalist_control_btn",
                        "properties": {
                          "icon": {
                            "stringVal": {
                              "value": "forward_10_rounded"
                            }
                          },
                          "small": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "editorId": "brutalistcontrolbtn3"
                      }
                    ],
                    "editorId": "row34"
                  },
                  {
                    "type": "row",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "expanded",
                        "children": [
                          {
                            "type": "container",
                            "properties": {
                              "bg": {
                                "color": {
                                  "color": "surface"
                                }
                              },
                              "border": {
                                "border": {
                                  "width": 3,
                                  "color": "outline"
                                }
                              },
                              "padding": {
                                "edgeInsets": {
                                  "top": 0,
                                  "right": 0,
                                  "bottom": 0,
                                  "left": 0,
                                  "token": "md"
                                }
                              },
                              "shadow": {
                                "stringVal": {
                                  "value": "sm"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "row",
                                "properties": {
                                  "align": {
                                    "align": {
                                      "named": "center"
                                    }
                                  },
                                  "spacing": {
                                    "stringVal": {
                                      "value": "xs"
                                    }
                                  }
                                },
                                "children": [
                                  {
                                    "type": "icon",
                                    "properties": {
                                      "name": {
                                        "icon": {
                                          "name": "speed_rounded"
                                        }
                                      },
                                      "size": {
                                        "numberVal": {
                                          "value": 18
                                        }
                                      }
                                    },
                                    "editorId": "icon21"
                                  },
                                  {
                                    "type": "text",
                                    "properties": {
                                      "content": {
                                        "stringVal": {
                                          "value": "1.25x"
                                        }
                                      },
                                      "style": {
                                        "textStyle": {
                                          "styleName": "label_large"
                                        }
                                      },
                                      "font_weight": {
                                        "stringVal": {
                                          "value": "bold"
                                        }
                                      }
                                    },
                                    "editorId": "text72"
                                  }
                                ],
                                "editorId": "row36"
                              }
                            ],
                            "editorId": "container58"
                          }
                        ],
                        "editorId": "expanded14"
                      },
                      {
                        "type": "expanded",
                        "children": [
                          {
                            "type": "container",
                            "properties": {
                              "bg": {
                                "color": {
                                  "color": "surface"
                                }
                              },
                              "border": {
                                "border": {
                                  "width": 3,
                                  "color": "outline"
                                }
                              },
                              "padding": {
                                "edgeInsets": {
                                  "top": 0,
                                  "right": 0,
                                  "bottom": 0,
                                  "left": 0,
                                  "token": "md"
                                }
                              },
                              "shadow": {
                                "stringVal": {
                                  "value": "sm"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "row",
                                "properties": {
                                  "align": {
                                    "align": {
                                      "named": "center"
                                    }
                                  },
                                  "spacing": {
                                    "stringVal": {
                                      "value": "xs"
                                    }
                                  }
                                },
                                "children": [
                                  {
                                    "type": "icon",
                                    "properties": {
                                      "name": {
                                        "icon": {
                                          "name": "bookmark_border_rounded"
                                        }
                                      },
                                      "size": {
                                        "numberVal": {
                                          "value": 18
                                        }
                                      }
                                    },
                                    "editorId": "icon22"
                                  },
                                  {
                                    "type": "text",
                                    "properties": {
                                      "content": {
                                        "stringVal": {
                                          "value": "SAVE"
                                        }
                                      },
                                      "style": {
                                        "textStyle": {
                                          "styleName": "label_large"
                                        }
                                      },
                                      "font_weight": {
                                        "stringVal": {
                                          "value": "bold"
                                        }
                                      }
                                    },
                                    "editorId": "text73"
                                  }
                                ],
                                "editorId": "row37"
                              }
                            ],
                            "editorId": "container59"
                          }
                        ],
                        "editorId": "expanded15"
                      }
                    ],
                    "editorId": "row35"
                  },
                  {
                    "type": "divider",
                    "properties": {
                      "thickness": {
                        "numberVal": {
                          "value": 3
                        }
                      },
                      "color": {
                        "color": {
                          "color": "outline"
                        }
                      }
                    },
                    "editorId": "divider7"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "stretch"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "row",
                        "properties": {
                          "align": {
                            "align": {
                              "named": "space_between"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "NOTES"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "title_medium"
                                }
                              },
                              "font_weight": {
                                "numberVal": {
                                  "value": 900
                                }
                              }
                            },
                            "editorId": "text74"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "4 TOTAL"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_small"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "secondary_text"
                                }
                              }
                            },
                            "editorId": "text75"
                          }
                        ],
                        "editorId": "row38"
                      },
                      {
                        "type": "@std.textfield",
                        "properties": {
                          "hint": {
                            "stringVal": {
                              "value": "Add a note at 01:32..."
                            }
                          },
                          "leading_icon": {
                            "stringVal": {
                              "value": "edit_note_rounded"
                            }
                          },
                          "variant": {
                            "stringVal": {
                              "value": "outlined"
                            }
                          }
                        },
                        "editorId": "stdtextfield5"
                      },
                      {
                        "type": "column",
                        "children": [
                          {
                            "type": "@note_card",
                            "properties": {
                              "timestamp": {
                                "stringVal": {
                                  "value": "00:45"
                                }
                              },
                              "content": {
                                "stringVal": {
                                  "value": "Gradient descent minimizes the cost function by iterating weights."
                                }
                              }
                            },
                            "editorId": "note1"
                          },
                          {
                            "type": "@note_card",
                            "properties": {
                              "timestamp": {
                                "stringVal": {
                                  "value": "01:12"
                                }
                              },
                              "content": {
                                "stringVal": {
                                  "value": "Remember to check the learning rate hyperparameter."
                                }
                              }
                            },
                            "editorId": "note2"
                          }
                        ],
                        "editorId": "column53"
                      }
                    ],
                    "editorId": "column52"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "sm"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "ATTACHMENTS"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text76"
                      },
                      {
                        "type": "row",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "sm"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "container",
                            "properties": {
                              "bg": {
                                "color": {
                                  "color": "surface"
                                }
                              },
                              "border": {
                                "border": {
                                  "width": 2,
                                  "color": "outline"
                                }
                              },
                              "padding": {
                                "edgeInsets": {
                                  "top": 0,
                                  "right": 0,
                                  "bottom": 0,
                                  "left": 0,
                                  "topToken": "sm",
                                  "rightToken": "md",
                                  "bottomToken": "sm",
                                  "leftToken": "md"
                                }
                              },
                              "shadow": {
                                "stringVal": {
                                  "value": "xs"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "row",
                                "properties": {
                                  "spacing": {
                                    "stringVal": {
                                      "value": "xs"
                                    }
                                  }
                                },
                                "children": [
                                  {
                                    "type": "icon",
                                    "properties": {
                                      "name": {
                                        "icon": {
                                          "name": "description_rounded"
                                        }
                                      },
                                      "size": {
                                        "numberVal": {
                                          "value": 16
                                        }
                                      },
                                      "color": {
                                        "color": {
                                          "color": "error"
                                        }
                                      }
                                    },
                                    "editorId": "icon23"
                                  },
                                  {
                                    "type": "text",
                                    "properties": {
                                      "content": {
                                        "stringVal": {
                                          "value": "lecture-notes.pdf"
                                        }
                                      },
                                      "style": {
                                        "textStyle": {
                                          "styleName": "label_small"
                                        }
                                      }
                                    },
                                    "editorId": "text77"
                                  }
                                ],
                                "editorId": "row40"
                              }
                            ],
                            "editorId": "container60"
                          },
                          {
                            "type": "container",
                            "properties": {
                              "bg": {
                                "color": {
                                  "color": "surface"
                                }
                              },
                              "border": {
                                "border": {
                                  "width": 2,
                                  "color": "outline"
                                }
                              },
                              "padding": {
                                "edgeInsets": {
                                  "top": 0,
                                  "right": 0,
                                  "bottom": 0,
                                  "left": 0,
                                  "topToken": "sm",
                                  "rightToken": "md",
                                  "bottomToken": "sm",
                                  "leftToken": "md"
                                }
                              },
                              "shadow": {
                                "stringVal": {
                                  "value": "xs"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "row",
                                "properties": {
                                  "spacing": {
                                    "stringVal": {
                                      "value": "xs"
                                    }
                                  }
                                },
                                "children": [
                                  {
                                    "type": "icon",
                                    "properties": {
                                      "name": {
                                        "icon": {
                                          "name": "image_rounded"
                                        }
                                      },
                                      "size": {
                                        "numberVal": {
                                          "value": 16
                                        }
                                      },
                                      "color": {
                                        "color": {
                                          "color": "on_surface"
                                        }
                                      }
                                    },
                                    "editorId": "icon24"
                                  },
                                  {
                                    "type": "text",
                                    "properties": {
                                      "content": {
                                        "stringVal": {
                                          "value": "handwritten.png"
                                        }
                                      },
                                      "style": {
                                        "textStyle": {
                                          "styleName": "label_small"
                                        }
                                      }
                                    },
                                    "editorId": "text78"
                                  }
                                ],
                                "editorId": "row41"
                              }
                            ],
                            "editorId": "container61"
                          }
                        ],
                        "editorId": "row39"
                      }
                    ],
                    "editorId": "column54"
                  }
                ],
                "editorId": "column49"
              }
            ],
            "editorId": "expanded13"
          }
        ],
        "editorId": "column48"
      }
    ],
    "editorId": "scaffold5"
  }
}
```

### 6. Library

- Frame ID: `frame4`
- Original page prompt: "A searchable collection of all saved videos, playlists, and roadmaps in a compact list layout."
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "xl",
                  "rightToken": "lg",
                  "bottomToken": "md",
                  "leftToken": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 3,
                  "color": "outline"
                }
              }
            },
            "children": [
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  }
                },
                "children": [
                  {
                    "type": "row",
                    "properties": {
                      "align": {
                        "align": {
                          "named": "space_between"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "LIBRARY"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "headline_medium"
                            }
                          },
                          "font_weight": {
                            "numberVal": {
                              "value": 900
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "text79"
                      },
                      {
                        "type": "iconbutton",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "filter_list_rounded"
                            }
                          },
                          "bg": {
                            "color": {
                              "color": "accent"
                            }
                          },
                          "border": {
                            "border": {
                              "width": 2,
                              "color": "outline"
                            }
                          },
                          "shadow": {
                            "stringVal": {
                              "value": "xs"
                            }
                          }
                        },
                        "editorId": "iconbutton8"
                      }
                    ],
                    "editorId": "row42"
                  },
                  {
                    "type": "@brutalist_search",
                    "properties": {
                      "hint": {
                        "stringVal": {
                          "value": "Search videos, notes..."
                        }
                      }
                    },
                    "editorId": "brutalistsearch1"
                  }
                ],
                "editorId": "column56"
              }
            ],
            "editorId": "container62"
          },
          {
            "type": "container",
            "properties": {
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "md",
                  "rightToken": "lg",
                  "bottomToken": "md",
                  "leftToken": "lg"
                }
              },
              "bg": {
                "color": {
                  "color": "background"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  },
                  "scroll": {
                    "boolVal": {
                      "value": true
                    }
                  }
                },
                "children": [
                  {
                    "type": "@brutalist_chip",
                    "properties": {
                      "label": {
                        "stringVal": {
                          "value": "ALL"
                        }
                      },
                      "selected": {
                        "boolVal": {
                          "value": true
                        }
                      }
                    },
                    "editorId": "brutalistchip1"
                  },
                  {
                    "type": "@brutalist_chip",
                    "properties": {
                      "label": {
                        "stringVal": {
                          "value": "VIDEOS"
                        }
                      }
                    },
                    "editorId": "brutalistchip2"
                  },
                  {
                    "type": "@brutalist_chip",
                    "properties": {
                      "label": {
                        "stringVal": {
                          "value": "PLAYLISTS"
                        }
                      }
                    },
                    "editorId": "brutalistchip3"
                  },
                  {
                    "type": "@brutalist_chip",
                    "properties": {
                      "label": {
                        "stringVal": {
                          "value": "SAVED"
                        }
                      }
                    },
                    "editorId": "brutalistchip4"
                  }
                ],
                "editorId": "row43"
              }
            ],
            "editorId": "container63"
          },
          {
            "type": "expanded",
            "children": [
              {
                "type": "column",
                "properties": {
                  "scroll": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "rightToken": "lg",
                      "bottomToken": "lg",
                      "leftToken": "lg"
                    }
                  },
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  }
                },
                "children": [
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "RECENTLY ADDED"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_small"
                        }
                      },
                      "font_weight": {
                        "stringVal": {
                          "value": "bold"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      },
                      "margin": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "bottomToken": "xs"
                        }
                      }
                    },
                    "editorId": "text80"
                  },
                  {
                    "type": "@library_item",
                    "properties": {
                      "title": {
                        "stringVal": {
                          "value": "Introduction to Transformers"
                        }
                      },
                      "creator": {
                        "stringVal": {
                          "value": "DeepLearning.AI"
                        }
                      },
                      "meta": {
                        "stringVal": {
                          "value": "18:32"
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "play_circle_filled_rounded"
                        }
                      },
                      "tone": {
                        "stringVal": {
                          "value": "accent"
                        }
                      }
                    },
                    "editorId": "libraryitem1"
                  },
                  {
                    "type": "@library_item",
                    "properties": {
                      "title": {
                        "stringVal": {
                          "value": "Linear Algebra Essentials"
                        }
                      },
                      "creator": {
                        "stringVal": {
                          "value": "3Blue1Brown"
                        }
                      },
                      "meta": {
                        "stringVal": {
                          "value": "24:15"
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "playlist_play_rounded"
                        }
                      },
                      "tone": {
                        "color": {
                          "color": "#60A5FA"
                        }
                      }
                    },
                    "editorId": "libraryitem2"
                  },
                  {
                    "type": "@library_item",
                    "properties": {
                      "title": {
                        "stringVal": {
                          "value": "Probability Theory Notes"
                        }
                      },
                      "creator": {
                        "stringVal": {
                          "value": "My Notes"
                        }
                      },
                      "meta": {
                        "stringVal": {
                          "value": "PDF • 2.4MB"
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "description_rounded"
                        }
                      },
                      "tone": {
                        "color": {
                          "color": "#F87171"
                        }
                      }
                    },
                    "editorId": "libraryitem3"
                  },
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "ALL CONTENT"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_small"
                        }
                      },
                      "font_weight": {
                        "stringVal": {
                          "value": "bold"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      },
                      "margin": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "topToken": "md",
                          "bottomToken": "xs"
                        }
                      }
                    },
                    "editorId": "text81"
                  },
                  {
                    "type": "@library_item",
                    "properties": {
                      "title": {
                        "stringVal": {
                          "value": "Backpropagation Explained"
                        }
                      },
                      "creator": {
                        "stringVal": {
                          "value": "Karpathy"
                        }
                      },
                      "meta": {
                        "stringVal": {
                          "value": "32:10"
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "play_circle_filled_rounded"
                        }
                      },
                      "tone": {
                        "stringVal": {
                          "value": "accent"
                        }
                      }
                    },
                    "editorId": "libraryitem4"
                  },
                  {
                    "type": "@library_item",
                    "properties": {
                      "title": {
                        "stringVal": {
                          "value": "Calculus for ML Roadmap"
                        }
                      },
                      "creator": {
                        "stringVal": {
                          "value": "Curated"
                        }
                      },
                      "meta": {
                        "stringVal": {
                          "value": "12 Videos"
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "map_rounded"
                        }
                      },
                      "tone": {
                        "color": {
                          "color": "#34D399"
                        }
                      }
                    },
                    "editorId": "libraryitem5"
                  },
                  {
                    "type": "@library_item",
                    "properties": {
                      "title": {
                        "stringVal": {
                          "value": "Data Preprocessing Guide"
                        }
                      },
                      "creator": {
                        "stringVal": {
                          "value": "StatQuest"
                        }
                      },
                      "meta": {
                        "stringVal": {
                          "value": "15:45"
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "play_circle_filled_rounded"
                        }
                      },
                      "tone": {
                        "stringVal": {
                          "value": "accent"
                        }
                      }
                    },
                    "editorId": "libraryitem6"
                  },
                  {
                    "type": "@library_item",
                    "properties": {
                      "title": {
                        "stringVal": {
                          "value": "Vector Calculus"
                        }
                      },
                      "creator": {
                        "stringVal": {
                          "value": "MIT OCW"
                        }
                      },
                      "meta": {
                        "stringVal": {
                          "value": "Playlist • 8 Items"
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "playlist_play_rounded"
                        }
                      },
                      "tone": {
                        "color": {
                          "color": "#60A5FA"
                        }
                      }
                    },
                    "editorId": "libraryitem7"
                  },
                  {
                    "type": "@library_item",
                    "properties": {
                      "title": {
                        "stringVal": {
                          "value": "Optimization Algorithms"
                        }
                      },
                      "creator": {
                        "stringVal": {
                          "value": "Stanford"
                        }
                      },
                      "meta": {
                        "stringVal": {
                          "value": "45:00"
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "play_circle_filled_rounded"
                        }
                      },
                      "tone": {
                        "stringVal": {
                          "value": "accent"
                        }
                      }
                    },
                    "editorId": "libraryitem8"
                  }
                ],
                "editorId": "column57"
              }
            ],
            "editorId": "expanded16"
          },
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "border": {
                "borderSided": {
                  "side": "top",
                  "width": 3,
                  "color": "outline"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "md",
                  "rightToken": "lg",
                  "bottomToken": "md",
                  "leftToken": "lg"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "align": {
                    "align": {
                      "named": "space_around"
                    }
                  }
                },
                "children": [
                  {
                    "type": "iconbutton",
                    "properties": {
                      "name": {
                        "icon": {
                          "name": "home_rounded"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      }
                    },
                    "editorId": "iconbutton9"
                  },
                  {
                    "type": "iconbutton",
                    "properties": {
                      "name": {
                        "icon": {
                          "name": "map_rounded"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      }
                    },
                    "editorId": "iconbutton10"
                  },
                  {
                    "type": "iconbutton",
                    "properties": {
                      "name": {
                        "icon": {
                          "name": "local_library_rounded"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary"
                        }
                      },
                      "bg": {
                        "color": {
                          "color": "accent"
                        }
                      },
                      "border": {
                        "border": {
                          "width": 2,
                          "color": "outline"
                        }
                      }
                    },
                    "editorId": "iconbutton11"
                  },
                  {
                    "type": "iconbutton",
                    "properties": {
                      "name": {
                        "icon": {
                          "name": "note_alt_rounded"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      }
                    },
                    "editorId": "iconbutton12"
                  },
                  {
                    "type": "iconbutton",
                    "properties": {
                      "name": {
                        "icon": {
                          "name": "settings_rounded"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      }
                    },
                    "editorId": "iconbutton13"
                  }
                ],
                "editorId": "row44"
              }
            ],
            "editorId": "container64"
          }
        ],
        "editorId": "column55"
      }
    ],
    "editorId": "scaffold6"
  }
}
```

### 7. Notes & Attachments

- Frame ID: `frame7`
- Original page prompt: "A document-style view of timestamped notes, handwritten note images, and PDF attachments."
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "xl",
                  "rightToken": "lg",
                  "bottomToken": "md",
                  "leftToken": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 3,
                  "color": "outline"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "align": {
                    "align": {
                      "named": "space_between"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "NEURAL NETWORKS"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text82"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Notes & Assets"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "headline_medium"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "text83"
                      }
                    ],
                    "editorId": "column59"
                  },
                  {
                    "type": "row",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "sm"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "iconbutton",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "search_rounded"
                            }
                          },
                          "bg": {
                            "color": {
                              "color": "surface"
                            }
                          },
                          "border": {
                            "border": {
                              "width": 2,
                              "color": "outline"
                            }
                          },
                          "shadow": {
                            "stringVal": {
                              "value": "xs"
                            }
                          }
                        },
                        "editorId": "iconbutton14"
                      },
                      {
                        "type": "iconbutton",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "tune_rounded"
                            }
                          },
                          "bg": {
                            "color": {
                              "color": "surface"
                            }
                          },
                          "border": {
                            "border": {
                              "width": 2,
                              "color": "outline"
                            }
                          },
                          "shadow": {
                            "stringVal": {
                              "value": "xs"
                            }
                          }
                        },
                        "editorId": "iconbutton15"
                      }
                    ],
                    "editorId": "row46"
                  }
                ],
                "editorId": "row45"
              }
            ],
            "editorId": "container65"
          },
          {
            "type": "expanded",
            "children": [
              {
                "type": "column",
                "properties": {
                  "scroll": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "spacing": {
                    "stringVal": {
                      "value": "lg"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "stretch"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "row",
                        "properties": {
                          "align": {
                            "align": {
                              "named": "space_between"
                            }
                          },
                          "cross_align": {
                            "align": {
                              "named": "center"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "TIMESTAMPED NOTES"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_medium"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "secondary_text"
                                }
                              },
                              "font_weight": {
                                "stringVal": {
                                  "value": "bold"
                                }
                              }
                            },
                            "editorId": "text84"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "12 NOTES"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_small"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "primary_text"
                                }
                              }
                            },
                            "editorId": "text85"
                          }
                        ],
                        "editorId": "row47"
                      },
                      {
                        "type": "@brutalist_note_card",
                        "properties": {
                          "timestamp": {
                            "stringVal": {
                              "value": "12:42"
                            }
                          },
                          "content": {
                            "stringVal": {
                              "value": "Gradient descent minimizes the cost function by taking steps proportional to the negative of the gradient."
                            }
                          },
                          "has_attachments": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "editorId": "brutalistnotecard1"
                      },
                      {
                        "type": "@brutalist_note_card",
                        "properties": {
                          "timestamp": {
                            "stringVal": {
                              "value": "18:05"
                            }
                          },
                          "content": {
                            "stringVal": {
                              "value": "Backpropagation is essentially just the chain rule from calculus applied to the network weights."
                            }
                          }
                        },
                        "editorId": "brutalistnotecard2"
                      },
                      {
                        "type": "@brutalist_note_card",
                        "properties": {
                          "timestamp": {
                            "stringVal": {
                              "value": "24:15"
                            }
                          },
                          "content": {
                            "stringVal": {
                              "value": "ReLU activation helps prevent vanishing gradient problems in deep architectures."
                            }
                          },
                          "has_attachments": {
                            "boolVal": {
                              "value": false
                            }
                          }
                        },
                        "editorId": "note3"
                      }
                    ],
                    "editorId": "column61"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "stretch"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "LEARNING ATTACHMENTS"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_medium"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text86"
                      },
                      {
                        "type": "row",
                        "properties": {
                          "scroll": {
                            "boolVal": {
                              "value": true
                            }
                          },
                          "spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "@brutalist_attachment_tile",
                            "properties": {
                              "name": {
                                "stringVal": {
                                  "value": "handwritten_math.png"
                                }
                              },
                              "type": {
                                "stringVal": {
                                  "value": "IMAGE"
                                }
                              },
                              "icon": {
                                "stringVal": {
                                  "value": "image_rounded"
                                }
                              },
                              "tone": {
                                "stringVal": {
                                  "value": "accent"
                                }
                              }
                            },
                            "editorId": "file1"
                          },
                          {
                            "type": "@brutalist_attachment_tile",
                            "properties": {
                              "name": {
                                "stringVal": {
                                  "value": "lecture_notes.pdf"
                                }
                              },
                              "type": {
                                "stringVal": {
                                  "value": "PDF"
                                }
                              },
                              "icon": {
                                "stringVal": {
                                  "value": "description_rounded"
                                }
                              },
                              "tone": {
                                "stringVal": {
                                  "value": "info"
                                }
                              }
                            },
                            "editorId": "file2"
                          },
                          {
                            "type": "@brutalist_attachment_tile",
                            "properties": {
                              "name": {
                                "stringVal": {
                                  "value": "architecture_diagram.jpg"
                                }
                              },
                              "type": {
                                "stringVal": {
                                  "value": "IMAGE"
                                }
                              },
                              "icon": {
                                "stringVal": {
                                  "value": "brush_rounded"
                                }
                              },
                              "tone": {
                                "stringVal": {
                                  "value": "success"
                                }
                              }
                            },
                            "editorId": "file3"
                          },
                          {
                            "type": "@brutalist_attachment_tile",
                            "properties": {
                              "name": {
                                "stringVal": {
                                  "value": "syllabus.pdf"
                                }
                              },
                              "type": {
                                "stringVal": {
                                  "value": "PDF"
                                }
                              },
                              "icon": {
                                "stringVal": {
                                  "value": "picture_as_pdf_rounded"
                                }
                              },
                              "tone": {
                                "stringVal": {
                                  "value": "warning"
                                }
                              }
                            },
                            "editorId": "file4"
                          }
                        ],
                        "editorId": "row48"
                      }
                    ],
                    "editorId": "column62"
                  },
                  {
                    "type": "container",
                    "properties": {
                      "bg": {
                        "color": {
                          "color": "surface_variant"
                        }
                      },
                      "border": {
                        "border": {
                          "width": 3,
                          "color": "outline"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "token": "lg"
                        }
                      },
                      "shadow": {
                        "stringVal": {
                          "value": "sm"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "row",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          },
                          "cross_align": {
                            "align": {
                              "named": "center"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "icon",
                            "properties": {
                              "name": {
                                "icon": {
                                  "name": "edit_rounded"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "secondary_text"
                                }
                              }
                            },
                            "editorId": "icon25"
                          },
                          {
                            "type": "expanded",
                            "children": [
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "Add a timestamped note..."
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "body_medium"
                                    }
                                  },
                                  "color": {
                                    "color": {
                                      "color": "on_surface_variant"
                                    }
                                  }
                                },
                                "editorId": "text87"
                              }
                            ],
                            "editorId": "expanded18"
                          },
                          {
                            "type": "container",
                            "properties": {
                              "bg": {
                                "color": {
                                  "color": "primary"
                                }
                              },
                              "border": {
                                "border": {
                                  "width": 2,
                                  "color": "outline"
                                }
                              },
                              "padding": {
                                "edgeInsets": {
                                  "top": 0,
                                  "right": 0,
                                  "bottom": 0,
                                  "left": 0,
                                  "topToken": "sm",
                                  "rightToken": "md",
                                  "bottomToken": "sm",
                                  "leftToken": "md"
                                }
                              },
                              "shadow": {
                                "stringVal": {
                                  "value": "xs"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "SAVE"
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "label_large"
                                    }
                                  },
                                  "color": {
                                    "color": {
                                      "color": "on_primary"
                                    }
                                  },
                                  "font_weight": {
                                    "stringVal": {
                                      "value": "bold"
                                    }
                                  }
                                },
                                "editorId": "text88"
                              }
                            ],
                            "editorId": "container67"
                          }
                        ],
                        "editorId": "row49"
                      }
                    ],
                    "editorId": "container66"
                  }
                ],
                "editorId": "column60"
              }
            ],
            "editorId": "expanded17"
          },
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "md",
                  "rightToken": "lg",
                  "bottomToken": "md",
                  "leftToken": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "top",
                  "width": 3,
                  "color": "outline"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "align": {
                    "align": {
                      "named": "space_around"
                    }
                  }
                },
                "children": [
                  {
                    "type": "iconbutton",
                    "properties": {
                      "name": {
                        "icon": {
                          "name": "home_rounded"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary_text"
                        }
                      }
                    },
                    "editorId": "nav1"
                  },
                  {
                    "type": "iconbutton",
                    "properties": {
                      "name": {
                        "icon": {
                          "name": "map_rounded"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary_text"
                        }
                      }
                    },
                    "editorId": "nav2"
                  },
                  {
                    "type": "iconbutton",
                    "properties": {
                      "name": {
                        "icon": {
                          "name": "library_books_rounded"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary_text"
                        }
                      }
                    },
                    "editorId": "nav3"
                  },
                  {
                    "type": "container",
                    "properties": {
                      "bg": {
                        "color": {
                          "color": "accent"
                        }
                      },
                      "border": {
                        "border": {
                          "width": 2,
                          "color": "outline"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "topToken": "xs",
                          "rightToken": "lg",
                          "bottomToken": "xs",
                          "leftToken": "lg"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "icon",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "sticky_note_2_rounded"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "icon26"
                      }
                    ],
                    "editorId": "container69"
                  }
                ],
                "editorId": "row50"
              }
            ],
            "editorId": "container68"
          }
        ],
        "editorId": "column58"
      }
    ],
    "editorId": "scaffold7"
  }
}
```

### 8. Global Search

- Frame ID: `frame6`
- Original page prompt: "A simple search interface to find content across videos, roadmaps, and personal notes."
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "xl",
                  "rightToken": "lg",
                  "bottomToken": "md",
                  "leftToken": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 3,
                  "color": "outline"
                }
              }
            },
            "children": [
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "lg"
                    }
                  }
                },
                "children": [
                  {
                    "type": "row",
                    "properties": {
                      "align": {
                        "align": {
                          "named": "space_between"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "SEARCH"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "headline_medium"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          },
                          "font_weight": {
                            "numberVal": {
                              "value": 900
                            }
                          }
                        },
                        "editorId": "text89"
                      },
                      {
                        "type": "iconbutton",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "close_rounded"
                            }
                          },
                          "bg": {
                            "color": {
                              "color": "surface"
                            }
                          },
                          "border": {
                            "border": {
                              "width": 2,
                              "color": "outline"
                            }
                          },
                          "shadow": {
                            "stringVal": {
                              "value": "xs"
                            }
                          }
                        },
                        "editorId": "iconbutton16"
                      }
                    ],
                    "editorId": "row51"
                  },
                  {
                    "type": "container",
                    "properties": {
                      "bg": {
                        "color": {
                          "color": "surface"
                        }
                      },
                      "border": {
                        "border": {
                          "width": 3,
                          "color": "outline"
                        }
                      },
                      "shadow": {
                        "stringVal": {
                          "value": "sm"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "topToken": "sm",
                          "rightToken": "md",
                          "bottomToken": "sm",
                          "leftToken": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "row",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          },
                          "cross_align": {
                            "align": {
                              "named": "center"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "icon",
                            "properties": {
                              "name": {
                                "icon": {
                                  "name": "search_rounded"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "primary_text"
                                }
                              },
                              "size": {
                                "numberVal": {
                                  "value": 28
                                }
                              }
                            },
                            "editorId": "icon27"
                          },
                          {
                            "type": "expanded",
                            "children": [
                              {
                                "type": "@std.textfield",
                                "properties": {
                                  "variant": {
                                    "stringVal": {
                                      "value": "ghost"
                                    }
                                  },
                                  "hint": {
                                    "stringVal": {
                                      "value": "Search videos, notes, roadmaps..."
                                    }
                                  },
                                  "placeholder_color": {
                                    "stringVal": {
                                      "value": "hint"
                                    }
                                  }
                                },
                                "editorId": "stdtextfield6"
                              }
                            ],
                            "editorId": "expanded19"
                          }
                        ],
                        "editorId": "row52"
                      }
                    ],
                    "editorId": "container71"
                  }
                ],
                "editorId": "column64"
              }
            ],
            "editorId": "container70"
          },
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "secondary_background"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "md",
                  "rightToken": "lg",
                  "bottomToken": "md",
                  "leftToken": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 3,
                  "color": "outline"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  },
                  "scroll": {
                    "boolVal": {
                      "value": true
                    }
                  }
                },
                "children": [
                  {
                    "type": "@filter_chip",
                    "properties": {
                      "label": {
                        "stringVal": {
                          "value": "ALL"
                        }
                      },
                      "selected": {
                        "boolVal": {
                          "value": true
                        }
                      }
                    },
                    "editorId": "filterchip1"
                  },
                  {
                    "type": "@filter_chip",
                    "properties": {
                      "label": {
                        "stringVal": {
                          "value": "VIDEOS"
                        }
                      }
                    },
                    "editorId": "filterchip2"
                  },
                  {
                    "type": "@filter_chip",
                    "properties": {
                      "label": {
                        "stringVal": {
                          "value": "ROADMAPS"
                        }
                      }
                    },
                    "editorId": "filterchip3"
                  },
                  {
                    "type": "@filter_chip",
                    "properties": {
                      "label": {
                        "stringVal": {
                          "value": "NOTES"
                        }
                      }
                    },
                    "editorId": "filterchip4"
                  }
                ],
                "editorId": "row53"
              }
            ],
            "editorId": "container72"
          },
          {
            "type": "expanded",
            "children": [
              {
                "type": "column",
                "properties": {
                  "scroll": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "spacing": {
                    "stringVal": {
                      "value": "lg"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "stretch"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "row",
                        "properties": {
                          "align": {
                            "align": {
                              "named": "space_between"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "VIDEOS"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_large"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "secondary_text"
                                }
                              },
                              "font_weight": {
                                "stringVal": {
                                  "value": "bold"
                                }
                              }
                            },
                            "editorId": "text90"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "12 FOUND"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_small"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "primary"
                                }
                              }
                            },
                            "editorId": "text91"
                          }
                        ],
                        "editorId": "row54"
                      },
                      {
                        "type": "@search_result_item",
                        "properties": {
                          "type": {
                            "stringVal": {
                              "value": "VIDEO"
                            }
                          },
                          "title": {
                            "stringVal": {
                              "value": "Backpropagation Explained"
                            }
                          },
                          "subtitle": {
                            "stringVal": {
                              "value": "Neural Networks • 18:32"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "play_circle_filled_rounded"
                            }
                          },
                          "tone": {
                            "stringVal": {
                              "value": "accent"
                            }
                          }
                        },
                        "editorId": "searchresultitem1"
                      },
                      {
                        "type": "@search_result_item",
                        "properties": {
                          "type": {
                            "stringVal": {
                              "value": "VIDEO"
                            }
                          },
                          "title": {
                            "stringVal": {
                              "value": "Gradient Descent Optimization"
                            }
                          },
                          "subtitle": {
                            "stringVal": {
                              "value": "Foundations • 12:45"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "play_circle_filled_rounded"
                            }
                          },
                          "tone": {
                            "stringVal": {
                              "value": "accent"
                            }
                          }
                        },
                        "editorId": "searchresultitem2"
                      }
                    ],
                    "editorId": "column66"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "stretch"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "row",
                        "properties": {
                          "align": {
                            "align": {
                              "named": "space_between"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "ROADMAPS"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_large"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "secondary_text"
                                }
                              },
                              "font_weight": {
                                "stringVal": {
                                  "value": "bold"
                                }
                              }
                            },
                            "editorId": "text92"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "2 FOUND"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_small"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "primary"
                                }
                              }
                            },
                            "editorId": "text93"
                          }
                        ],
                        "editorId": "row55"
                      },
                      {
                        "type": "@search_result_item",
                        "properties": {
                          "type": {
                            "stringVal": {
                              "value": "ROADMAP"
                            }
                          },
                          "title": {
                            "stringVal": {
                              "value": "Deep Learning Specialization"
                            }
                          },
                          "subtitle": {
                            "stringVal": {
                              "value": "68% Complete • 24 Videos"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "map_rounded"
                            }
                          },
                          "tone": {
                            "stringVal": {
                              "value": "success"
                            }
                          }
                        },
                        "editorId": "searchresultitem3"
                      }
                    ],
                    "editorId": "column67"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "stretch"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "row",
                        "properties": {
                          "align": {
                            "align": {
                              "named": "space_between"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "PERSONAL NOTES"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_large"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "secondary_text"
                                }
                              },
                              "font_weight": {
                                "stringVal": {
                                  "value": "bold"
                                }
                              }
                            },
                            "editorId": "text94"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "5 FOUND"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_small"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "primary"
                                }
                              }
                            },
                            "editorId": "text95"
                          }
                        ],
                        "editorId": "row56"
                      },
                      {
                        "type": "@search_result_item",
                        "properties": {
                          "type": {
                            "stringVal": {
                              "value": "NOTE"
                            }
                          },
                          "title": {
                            "stringVal": {
                              "value": "Cost Function Derivatives"
                            }
                          },
                          "subtitle": {
                            "stringVal": {
                              "value": "Last edited 2 days ago"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "description_rounded"
                            }
                          },
                          "tone": {
                            "stringVal": {
                              "value": "info"
                            }
                          }
                        },
                        "editorId": "searchresultitem4"
                      },
                      {
                        "type": "@search_result_item",
                        "properties": {
                          "type": {
                            "stringVal": {
                              "value": "ATTACHMENT"
                            }
                          },
                          "title": {
                            "stringVal": {
                              "value": "lecture-notes-v2.pdf"
                            }
                          },
                          "subtitle": {
                            "stringVal": {
                              "value": "PDF • 4.2 MB"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "attachment_rounded"
                            }
                          },
                          "tone": {
                            "color": {
                              "color": "#FF90E8"
                            }
                          }
                        },
                        "editorId": "searchresultitem5"
                      }
                    ],
                    "editorId": "column68"
                  }
                ],
                "editorId": "column65"
              }
            ],
            "editorId": "expanded20"
          },
          {
            "type": "container",
            "properties": {
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "md"
                }
              },
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "border": {
                "borderSided": {
                  "side": "top",
                  "width": 3,
                  "color": "outline"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "align": {
                    "align": {
                      "named": "center"
                    }
                  },
                  "spacing": {
                    "stringVal": {
                      "value": "sm"
                    }
                  }
                },
                "children": [
                  {
                    "type": "icon",
                    "properties": {
                      "name": {
                        "icon": {
                          "name": "info_outline_rounded"
                        }
                      },
                      "size": {
                        "numberVal": {
                          "value": 16
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      }
                    },
                    "editorId": "icon28"
                  },
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Searching across 124 learning objects"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_small"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      }
                    },
                    "editorId": "text96"
                  }
                ],
                "editorId": "row57"
              }
            ],
            "editorId": "container73"
          }
        ],
        "editorId": "column63"
      }
    ],
    "editorId": "scaffold8"
  }
}
```

### 9. Settings

- Frame ID: `frame3`
- Original page prompt: "Simple configuration for appearance, playback speed, and storage management."
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "xl",
                  "rightToken": "lg",
                  "bottomToken": "md",
                  "leftToken": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 3,
                  "color": "outline"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "align": {
                    "align": {
                      "named": "space_between"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "PREFERENCES"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary"
                            }
                          }
                        },
                        "editorId": "text97"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Settings"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "headline_medium"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "text98"
                      }
                    ],
                    "editorId": "column70"
                  },
                  {
                    "type": "iconbutton",
                    "properties": {
                      "name": {
                        "icon": {
                          "name": "close_rounded"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary_text"
                        }
                      },
                      "bg": {
                        "color": {
                          "color": "surface"
                        }
                      },
                      "border": {
                        "border": {
                          "width": 2,
                          "color": "outline"
                        }
                      },
                      "shadow": {
                        "stringVal": {
                          "value": "xs"
                        }
                      }
                    },
                    "editorId": "iconbutton17"
                  }
                ],
                "editorId": "row58"
              }
            ],
            "editorId": "container74"
          },
          {
            "type": "expanded",
            "children": [
              {
                "type": "column",
                "properties": {
                  "scroll": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  }
                },
                "children": [
                  {
                    "type": "@brutalist_section_label",
                    "properties": {
                      "label": {
                        "stringVal": {
                          "value": "APPEARANCE"
                        }
                      }
                    },
                    "editorId": "brutalistsectionlabel1"
                  },
                  {
                    "type": "@brutalist_setting_row",
                    "properties": {
                      "title": {
                        "stringVal": {
                          "value": "Dark Mode"
                        }
                      },
                      "subtitle": {
                        "stringVal": {
                          "value": "Easier on the eyes at night"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "@std.switch",
                        "properties": {
                          "variant": {
                            "stringVal": {
                              "value": "iOS 26+"
                            }
                          },
                          "active": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "editorId": "stdswitch2"
                      }
                    ],
                    "editorId": "brutalistsettingrow1"
                  },
                  {
                    "type": "@brutalist_setting_row",
                    "properties": {
                      "title": {
                        "stringVal": {
                          "value": "Text Size"
                        }
                      },
                      "subtitle": {
                        "stringVal": {
                          "value": "Adjust for reading comfort"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "container",
                        "properties": {
                          "width": {
                            "px": {
                              "value": 120,
                              "isInfinity": false
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "@std.tab_group",
                            "properties": {
                              "label_1": {
                                "stringVal": {
                                  "value": "A"
                                }
                              },
                              "label_2": {
                                "stringVal": {
                                  "value": "A"
                                }
                              },
                              "label_3": {
                                "stringVal": {
                                  "value": "A"
                                }
                              }
                            },
                            "editorId": "stdtabgroup1"
                          }
                        ],
                        "editorId": "container75"
                      }
                    ],
                    "editorId": "brutalistsettingrow2"
                  },
                  {
                    "type": "@brutalist_section_label",
                    "properties": {
                      "label": {
                        "stringVal": {
                          "value": "PLAYBACK"
                        }
                      }
                    },
                    "editorId": "brutalistsectionlabel2"
                  },
                  {
                    "type": "@brutalist_setting_row",
                    "properties": {
                      "title": {
                        "stringVal": {
                          "value": "Default Speed"
                        }
                      },
                      "subtitle": {
                        "stringVal": {
                          "value": "Set your learning pace"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "container",
                        "properties": {
                          "width": {
                            "px": {
                              "value": 100,
                              "isInfinity": false
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "dropdown",
                            "properties": {
                              "value": {
                                "stringVal": {
                                  "value": "1.25x"
                                }
                              },
                              "options": {
                                "stringVal": {
                                  "value": "1.0x,1.25x,1.5x,2.0x"
                                }
                              },
                              "bg": {
                                "color": {
                                  "color": "surface"
                                }
                              },
                              "border": {
                                "border": {
                                  "width": 2,
                                  "color": "outline"
                                }
                              },
                              "radius": {
                                "radius": {
                                  "topLeft": 0,
                                  "topRight": 0,
                                  "bottomLeft": 0,
                                  "bottomRight": 0
                                }
                              }
                            },
                            "editorId": "dropdown1"
                          }
                        ],
                        "editorId": "container76"
                      }
                    ],
                    "editorId": "brutalistsettingrow3"
                  },
                  {
                    "type": "@brutalist_setting_row",
                    "properties": {
                      "title": {
                        "stringVal": {
                          "value": "Resume Playback"
                        }
                      },
                      "subtitle": {
                        "stringVal": {
                          "value": "Start where you left off"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "@std.switch",
                        "properties": {
                          "variant": {
                            "stringVal": {
                              "value": "iOS 26+"
                            }
                          },
                          "active": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "editorId": "stdswitch3"
                      }
                    ],
                    "editorId": "brutalistsettingrow4"
                  },
                  {
                    "type": "@brutalist_section_label",
                    "properties": {
                      "label": {
                        "stringVal": {
                          "value": "STORAGE"
                        }
                      }
                    },
                    "editorId": "brutalistsectionlabel3"
                  },
                  {
                    "type": "container",
                    "properties": {
                      "bg": {
                        "color": {
                          "color": "surface"
                        }
                      },
                      "border": {
                        "border": {
                          "width": 2,
                          "color": "outline"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "token": "md"
                        }
                      },
                      "shadow": {
                        "stringVal": {
                          "value": "sm"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          },
                          "cross_align": {
                            "align": {
                              "named": "stretch"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "row",
                            "properties": {
                              "align": {
                                "align": {
                                  "named": "space_between"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "Storage Usage"
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "title_medium"
                                    }
                                  },
                                  "font_weight": {
                                    "stringVal": {
                                      "value": "bold"
                                    }
                                  }
                                },
                                "editorId": "text99"
                              },
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "1.2 GB / 5 GB"
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "label_medium"
                                    }
                                  },
                                  "color": {
                                    "color": {
                                      "color": "secondary_text"
                                    }
                                  }
                                },
                                "editorId": "text100"
                              }
                            ],
                            "editorId": "row59"
                          },
                          {
                            "type": "container",
                            "properties": {
                              "height": {
                                "px": {
                                  "value": 12,
                                  "isInfinity": false
                                }
                              },
                              "bg": {
                                "color": {
                                  "color": "surface_variant"
                                }
                              },
                              "border": {
                                "border": {
                                  "width": 2,
                                  "color": "outline"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "container",
                                "properties": {
                                  "width": {
                                    "px": {
                                      "value": 80,
                                      "isInfinity": false
                                    }
                                  },
                                  "bg": {
                                    "color": {
                                      "color": "accent"
                                    }
                                  }
                                },
                                "editorId": "container79"
                              }
                            ],
                            "editorId": "container78"
                          },
                          {
                            "type": "@std.button",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Clear Cached Files"
                                }
                              },
                              "variant": {
                                "stringVal": {
                                  "value": "outline"
                                }
                              },
                              "size": {
                                "stringVal": {
                                  "value": "small"
                                }
                              },
                              "full_width": {
                                "boolVal": {
                                  "value": true
                                }
                              }
                            },
                            "editorId": "stdbutton9"
                          }
                        ],
                        "editorId": "column72"
                      }
                    ],
                    "editorId": "container77"
                  },
                  {
                    "type": "@brutalist_section_label",
                    "properties": {
                      "label": {
                        "stringVal": {
                          "value": "LEARNING"
                        }
                      }
                    },
                    "editorId": "brutalistsectionlabel4"
                  },
                  {
                    "type": "@brutalist_setting_row",
                    "properties": {
                      "title": {
                        "stringVal": {
                          "value": "Completion Behavior"
                        }
                      },
                      "subtitle": {
                        "stringVal": {
                          "value": "Auto-mark roadmap items"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "@std.checkbox",
                        "properties": {
                          "is_checked": {
                            "boolVal": {
                              "value": true
                            }
                          },
                          "has_subtitle": {
                            "boolVal": {
                              "value": false
                            }
                          }
                        },
                        "editorId": "stdcheckbox1"
                      }
                    ],
                    "editorId": "brutalistsettingrow5"
                  },
                  {
                    "type": "container",
                    "properties": {
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "topToken": "top",
                          "rightToken": "xl",
                          "bottomToken": "bottom",
                          "leftToken": "xl"
                        }
                      },
                      "align_child": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "xs"
                            }
                          },
                          "cross_align": {
                            "align": {
                              "named": "center"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "FocusLearn v1.0.4"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_small"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "secondary_text"
                                }
                              }
                            },
                            "editorId": "text101"
                          },
                          {
                            "type": "@std.button",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "View Open-source Licenses"
                                }
                              },
                              "variant": {
                                "stringVal": {
                                  "value": "ghost"
                                }
                              },
                              "size": {
                                "stringVal": {
                                  "value": "small"
                                }
                              }
                            },
                            "editorId": "stdbutton10"
                          }
                        ],
                        "editorId": "column73"
                      }
                    ],
                    "editorId": "container80"
                  }
                ],
                "editorId": "column71"
              }
            ],
            "editorId": "expanded21"
          }
        ],
        "editorId": "column69"
      }
    ],
    "editorId": "scaffold9"
  }
}
```