# Design QA — 2026-09-08

## Scope and evidence

This report supersedes the earlier QA claims. Acceptance is for this native UI
redesign, not a completed production weather service or a pixel-identical clone.

- Source direction: `design/originos-weather-target.png` (853 × 1844).
- Current native home: `design/redesign-home-final.jpeg` (1320 × 2856).
- Full comparison: `design/redesign-reference-comparison.jpg`. Both images are
  scaled proportionally to 440px wide; no UI content is retouched.
- Focused forecast comparison: `design/redesign-forecast-comparison.jpg`.
- Actual four-screen overview: `design/redesign-overview.jpg`.
- Emulator: Pura 90, viewport about 377.14 × 816vp, density 3.5px/vp.
  There is no CSS/browser viewport in this ArkTS application.
- State: Shenzhen, daytime, 26°C, explicitly **demo** weather. Dates, hourly
  times, city photography and native status bars differ from the June reference.
  No exact-pixel claim is made across those intentional differences.

## Findings and iteration

The final reviewed screens have no remaining actionable P0/P1/P2 **visual**
findings within the tested phone UI scope. The following findings were fixed
and recaptured during this pass:

| Finding | Fix | Post-fix evidence |
| --- | --- | --- |
| P2: Canvas labels rendered black against the dark forecast surface | Explicit fill color and measured responsive chart width | `redesign-forecast-final.jpeg` |
| P2: City thumbnails showed sky/building fragments instead of recognizable streetscapes | Crop the sharp lower region using measured card width | `redesign-cities-final.jpeg` |
| P2: Empty search guidance was hidden behind the keyboard | Anchor feedback beneath the result count | `qa-city-empty.jpeg` |
| P2: Full-width warning panel overpowered the scenery | Compact visual capsule inside a 44vp-high touch row | `redesign-home-final.jpeg` |
| P2: Scrolled content overlapped status icons | Top safe-area scrim while scrolling | `redesign-life-final.jpeg` |

An earlier screenshot was reviewed, patched, rebuilt and captured again after
each finding. Draft screenshots with transition artifacts are not deliverables.

## Five fidelity surfaces

- **Typography:** native HarmonyOS font; thin 112sp temperature, 22sp weather
  description and restrained secondary text. Larger readable type is an
  intentional redesign, rather than matching the dense mock at every pixel.
- **Spacing/layout:** 24vp body gutters; continuous scroll; hourly selected state;
  shared-scale daily curves. Life illustrations and detailed metrics are below
  the fold, not squeezed into the first screen. Compact warning now preserves
  the skyline. City, settings and detail pages use the same dark surface system.
- **Colors/tokens:** cool blue atmosphere, dark blue reading surfaces, warm highs
  and cyan lows. Foreground text remains light for fog/rain as well as clear sky.
  Selected settings controls and city borders have explicit contrasting states.
- **Image quality:** bundled city photographs stay recognizable; moving cloud,
  rain and wet-glass textures are separate from the photo. Three original life
  illustrations have consistent lighting and material detail. Weather symbols
  are unmodified MIT Meteocons SVG resources, with proper night variants.
- **Copy/content:** Chinese renders correctly. Demo weather and background
  preview are labeled separately. Preview changes only the background; it never
  relabels fabricated weather as current observations. Other city cards show no
  invented temperature. Detailed advice is available in dialogs.

## Verified

- Full Hvigor `assembleHap`: **passed**. Only expected unsigned-HAP warning.
  The unsigned HAP installs and launches in the local HarmonyOS emulator.
- `scripts/test-weather-state.cjs`: **7/7 passed**, testing the real transpiled
  model/service code with platform storage/network mocked at the boundary.
  Covers UTF-8, placeholder keys, no demo fallback for live failures, real-cache
  identity/timestamps, stable-ID city persistence, storage failure and minute
  precision at sunrise/sunset. This is not a real API integration test.
- Native flows: city search for Beijing, switch Beijing/Shenzhen, empty search
  with keyboard, settings navigation, Fahrenheit conversion and retention after
  force-stop/relaunch, city retention, forecast details and expanded daily row.
- Motion: app toggle off persists after restart; two rain-preview captures
  about 2.4 seconds apart have identical SHA256 hashes. Toggle on resumes motion.
  `redesign-rain-motion.gif` contains 18 actual native captures over ~14.5 seconds,
  using measured capture intervals (see `motion-capture.json`). It is a low-frame-
  rate evidence capture, not an app-frame-rate benchmark or seamless video.
- Day, night and rainy background previews were rendered. Preview mode is
  visibly labeled and exited through its control/back navigation.
- Responsive smoke tests: 320vp parent width with 1.3× font, 360vp parent width
  with normal font, plus the actual ~377vp device viewport. Parent-width QA
  captures intentionally have unused space at the right; they are not device
  screenshots of a 320px display. Daily/hourly strips scroll horizontally where
  needed. The final compact-alert change was reviewed at the normal viewport.
- Temporary font/width QA hooks were removed before the final build.

## Remaining validation / product work

- 390/480vp, landscape, tablet, system screen reader, system-level reduced-motion
  and prolonged on-device performance are **not verified**. Current motion toggle
  is app-specific; it does not claim to follow the OS reduce-motion preference.
- Live weather integration is **not verified**: no local key file is present and
  the checked-in config contains a placeholder. Existing API plumbing is kept;
  no credential was recovered, changed or committed during this redesign.
- Location refusal UI, device-level offline recovery and automatic-refresh timing
  still need end-to-end tests with real permissions/network/configuration. The
  cache tests above cover service logic, not those device scenarios.
- City management currently covers the existing 15-city catalog; worldwide search,
  drag ordering, additional timezone handling and production signing remain out
  of this UI pass. See `docs/ui-redesign-2026-09.md` for prioritized follow-up.

final result: passed

Result applies only to the bounded native UI redesign and tested states above.
