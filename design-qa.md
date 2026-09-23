# Locus design QA

## Comparison target

- Source visual truth: `/Users/wangwenqing/Downloads/ChatGPT Image 2026年9月22日 23_30_30 (1).png` through `(7).png`
- Implementation screenshots: `/tmp/locus-design-qa/*.png` and `/tmp/locus-design-qa-dark/*.png`
- Comparison boards: `/tmp/locus-design-qa/compare-home.jpg`, `compare-rule.jpg`, and `compare-permission.jpg`
- App viewport: 368 x 580 pt, rendered at 2x as 736 x 1160 pixels
- Source images: approximately 941 x 1672 pixels; normalized to the implementation width for comparison
- States: home, add rule, rule detail, settings, activity, permission overlay, delete confirmation; light and dark appearance

## Full-view evidence

The implementation now uses the same visual system as the references: pale blue gray canvas, white grouped cards, rounded icon tiles, compact SF Pro hierarchy, blue active controls, orange permission treatment, red destructive treatment, and a dimmed home screen behind the permission dialog. The 368 x 580 pt product viewport is shorter than the tall reference boards, so long pages scroll while their headers and persistent actions remain available.

## Focused evidence

- Home comparison verifies the status notice, permission card, environment/audio/rule cards, chevrons, and persistent automation card.
- Rule comparison verifies the grouped sound controls, icon tiles, picker alignment, slider, notification toggle, and paired destructive/primary actions.
- Permission comparison verifies the dimmed home context, centered white dialog, orange location mark, explanatory copy, and two-button action row.
- No raster assets were substituted: all visible UI symbols are native SF Symbols, consistent with the macOS product design.

## Required fidelity surfaces

- Fonts and typography: system SF Pro styles, stronger headers, semibold row titles, secondary descriptions, and matching truncation behavior.
- Spacing and layout rhythm: 18 pt page margins, grouped cards, 13 pt radii, consistent row heights, and scrollable content within the fixed popover.
- Colors and tokens: semantic macOS colors plus the reference's pale blue gray light canvas; dark mode uses semantic system surfaces.
- Image and asset quality: native vector SF Symbols remain sharp at Retina density; no generated or placeholder imagery is present.
- Copy and content: titles, status descriptions, permission copy, action labels, and rule summaries match the supplied designs and current product behavior.

## Comparison history

1. Initial implementation used flat sections and separators, with no card grouping or icon tiles. It also showed permission as a separate page.
2. Fixed by introducing shared card, icon tile, panel background, row, and button components; applying them across all screens; grouping activities by date; and rendering permission as an overlay over the home screen.
3. Post-fix evidence is recorded in the comparison boards above. No actionable P0, P1, or P2 visual mismatch remains. The taller reference boards show more scroll content simultaneously; the implementation intentionally preserves the required 368 x 580 pt macOS popover.

## Follow-up polish

- P3: validate exact perceived type weight on additional non-Retina displays.
- P3: tune card shadow opacity after testing against different macOS wallpaper contrast levels.

final result: passed
