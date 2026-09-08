## Summary

Native ArkTS redesign of the existing weather app, continuing the approved
OriginOS-inspired direction without copying vivo branding or replacing the app
with a webpage.

- Lighter home hierarchy, compact alert, interactive hourly selection and a
  responsive high/low forecast chart. No fixed-size scene Canvas or Emoji icons.
- Three original material-style life illustrations and MIT Meteocons weather
  resources; consistent city, settings and daily-detail screens.
- Recognizable city-photo crops; independently animated clouds, distant rain and
  foreground wet-glass textures. App toggle and off-screen lifecycle stop motion.
- Stable-ID city persistence/removal, settings failure handling, precise sunrise
  boundaries and explicit weather-source labels. Failed live requests cannot
  substitute demo caches as real observations.
- Earlier environment/UTF-8/local-configuration fixes remain in this branch.

## Preview and evidence

- [Four native screens](https://github.com/songtaoluo007-maker/harmony-weather/blob/codex/originos-weather-redesign/design/redesign-overview.jpg)
- [Native rain motion capture](https://github.com/songtaoluo007-maker/harmony-weather/blob/codex/originos-weather-redesign/design/redesign-rain-motion.gif)
- [Bounded design QA and test gaps](https://github.com/songtaoluo007-maker/harmony-weather/blob/codex/originos-weather-redesign/design-qa.md)
- [Design decisions and prioritized follow-up](https://github.com/songtaoluo007-maker/harmony-weather/blob/codex/originos-weather-redesign/docs/ui-redesign-2026-09.md)

## Verified in this iteration

- Hvigor `assembleHap` with SDK `6.1.1(24)` succeeds; unsigned HAP installs and
  launches on the Pura 90 emulator.
- Seven real-service/model tests pass with platform I/O mocked.
- Native city search/switch, empty result with keyboard, settings and daily-detail
  navigation, Fahrenheit and selected-city persistence across restart.
- Day/night/rain previews; disabled-motion screenshots are identical. Enabled
  motion evidence contains 18 real captures over ~14.5 seconds at their original
  sampling cadence, not a frame-rate benchmark.
- 320vp parent-width/1.3× font and 360vp parent-width smoke tests, plus the actual
  ~377vp device. All temporary QA hooks are removed.

## Limitations / review notes

- Current checked-in config is a placeholder and no local key file was available:
  screenshots are explicitly **demo weather**, not real current observations.
  The QWeather client is retained; live integration has not been verified here.
- App-specific motion toggle is implemented, **not** system reduced-motion sync.
- Existing city catalog contains 15 cities; global search and drag sorting are
  future work. 390/480vp, tablet, landscape, screen reader, real location denial,
  device-offline recovery and long-duration performance remain unverified.
- Keep draft for review. No production certificate, key, signed artifact, merge
  or deployment is included. Unsigned HAP is the local build baseline.
