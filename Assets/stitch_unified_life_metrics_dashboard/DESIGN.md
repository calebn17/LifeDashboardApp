---
name: Life Intelligence System
colors:
  surface: '#131317'
  surface-dim: '#131317'
  surface-bright: '#39393d'
  surface-container-lowest: '#0e0e12'
  surface-container-low: '#1b1b1f'
  surface-container: '#1f1f23'
  surface-container-high: '#2a2a2e'
  surface-container-highest: '#353439'
  on-surface: '#e4e1e7'
  on-surface-variant: '#c7c6ca'
  inverse-surface: '#e4e1e7'
  inverse-on-surface: '#303034'
  outline: '#919094'
  outline-variant: '#46464a'
  surface-tint: '#c8c6c7'
  primary: '#c8c6c7'
  on-primary: '#313031'
  primary-container: '#0a0a0b'
  on-primary-container: '#7a797a'
  inverse-primary: '#5f5e5f'
  secondary: '#4edea3'
  on-secondary: '#003824'
  secondary-container: '#00a572'
  on-secondary-container: '#00311f'
  tertiary: '#adc6ff'
  on-tertiary: '#002e6a'
  tertiary-container: '#000920'
  on-tertiary-container: '#2976e9'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e5e2e3'
  primary-fixed-dim: '#c8c6c7'
  on-primary-fixed: '#1c1b1c'
  on-primary-fixed-variant: '#474647'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#d8e2ff'
  tertiary-fixed-dim: '#adc6ff'
  on-tertiary-fixed: '#001a42'
  on-tertiary-fixed-variant: '#004395'
  background: '#131317'
  on-background: '#e4e1e7'
  surface-variant: '#353439'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  data-mono:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 24px
    letterSpacing: -0.01em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  container-margin: 1.25rem
  stack-gap: 1rem
  element-gap: 0.5rem
  grid-gutter: 1rem
---

## Brand & Style

The design system is anchored in the concept of "The Quantified Self." It transforms complex personal data into a high-performance dashboard that feels like a premium cockpit for one’s life. The aesthetic follows a **High-End Glassmorphism** style—utilizing deep, layered blacks and charcoals to provide a sense of infinite depth, while vibrant accents highlight critical performance metrics.

The emotional response should be one of **calm mastery**. By using a "Dark Mode Premium" approach, we reduce visual noise and eye strain, allowing the user to focus entirely on their data. The interface must feel precise, expensive, and empowering, bridging the gap between a high-frequency trading platform and a luxury wellness retreat.

## Colors

The palette is built on a foundation of absolute blacks and "Obsidian" charcoals to create a sophisticated canvas. Color is used functionally, not just decoratively:

*   **Base Background:** `#0A0A0B` (Pure Dark)
*   **Surface/Card:** `#16161A` with varying opacities for glass effects.
*   **Investments & Growth:** `Emerald Green (#10B981)` — symbolizes prosperity and positive momentum.
*   **Fitness & Activity:** `Electric Blue (#3B82F6)` — evokes energy, hydration, and movement.
*   **Sleep & Recovery:** `Soft Violet (#A78BFA)` — represents circadian rhythm and mental clarity.
*   **Urgency/Alerts:** `Amber (#F59E0B)` — used sparingly for recovery needs or budget warnings.

All vibrant colors must maintain a high luminosity to "glow" against the dark background, simulating a self-lit display.

## Typography

This design system utilizes **Inter** exclusively to achieve a technical, clean, and highly legible look. The typeface’s tall x-height and excellent kerning make it ideal for data-heavy dashboards on mobile screens.

We utilize a "Data-Mono" style for numerical figures to ensure vertical alignment when tracking fluctuating values like stock prices or heart rates. Headlines use tighter letter spacing for a "locked-in" editorial feel, while labels use slightly wider spacing and uppercase transformations to provide clear hierarchy in dense information environments.

## Layout & Spacing

The layout is a **fluid-to-grid mobile system** based on an 8px base unit. 

*   **Safe Zones:** A standard 20px (1.25rem) margin is maintained on the left and right edges to ensure content is not obscured by physical device bezels.
*   **Verticality:** Content is organized in a vertical stack of "Lego-style" modules.
*   **Modular Units:** Each dashboard card should either span the full width (1 column) or sit as a pair in a 2-column grid.
*   **Density:** We favor higher information density, using tight 8px gaps between related elements and 16px gaps between distinct functional sections.

## Elevation & Depth

Hierarchy is established through **translucent layering** rather than traditional drop shadows.

1.  **Level 0 (Floor):** Pure black `#000000` for the deepest background.
2.  **Level 1 (Base Layer):** Obsidian `#0A0A0B` for the main app canvas.
3.  **Level 2 (Glass Cards):** Surfaces use a semi-transparent fill (`rgba(255, 255, 255, 0.05)`) with a `backdrop-filter: blur(20px)`. 
4.  **Accents (Stroke):** Every card features a subtle, 1px inner border (`rgba(255, 255, 255, 0.1)`) on the top and left sides to simulate a light source catching the edge of the glass.
5.  **Glows:** High-priority data points use a soft outer "bloom" effect using the category's accent color (e.g., a 15px emerald blur behind a growth metric) to create a sense of vibrancy.

## Shapes

The design system uses a **Rounded** (Level 2) logic. 

*   **Primary Cards:** 1rem (16px) corner radius to feel modern and accessible without becoming overly "bubbly."
*   **Inner Elements (Buttons/Inputs):** 0.5rem (8px) radius to maintain a structural relationship with the parent container.
*   **Progress Indicators:** Circular forms are used for health and completion metrics to provide a visual break from the rectangular grid.

## Components

### Glass Cards
The core container of the system. They must feature the 20px backdrop blur and the 1px subtle highlight stroke. Content inside should have 16px of internal padding.

### Action Buttons
Primary buttons use a solid white or vibrant accent background with black text for maximum contrast. Secondary buttons use a ghost style (1px stroke) with white text.

### Performance Rings
Used for fitness and sleep tracking. These are high-stroke circular progress bars using the Electric Blue and Soft Violet accents. The "unfilled" portion of the ring should be a dark `#1F1F23`.

### Data Sparklines
Minimalist line charts without axes, embedded directly within cards. They use a 2px stroke width in the category's accent color to show 24-hour trends at a glance.

### Segmented Controls
Used for toggling timeframes (D, W, M, Y). These should be styled as a single dark container with a "sliding" glass pill that highlights the active selection.

### Micro-Inputs
Form fields for logging data (e.g., calories or expenses) should be ultra-minimal, using only a bottom border that glows in the primary accent color when focused.