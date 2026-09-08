## Why

The user needs city scenes to follow actual local time and online weather, with
visible night lighting and moving rain/clouds. The previous fallback to demo data,
dimmed daytime photos and stale forecast rows after city switches broke that
experience. This PR also retains the earlier native UI and environment redesign.

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
- Default native provider is now keyless Open-Meteo, with current/hourly/15-day
  forecasts and optional CAMS air quality (explicit US AQI). Live model data and
  local lifestyle heuristics are labeled honestly; missing air is not invented.
- City-local UTC offset and daily sunrise/sunset drive the scene every minute.
  Fifteen licensed night/dusk city photos replace dimmed daylight images, and
  rain now distinguishes daylight/night. Curated download/mapping script included.
- Fixed stale hourly/daily/lifestyle ForEach rows after city switches. Weather
  caches are separated by provider; missing QWeather credentials report an error
  instead of silently selecting demo mode. QWeather configuration remains local.

## Preview and evidence

- [Four native screens](https://github.com/songtaoluo007-maker/harmony-weather/blob/codex/originos-weather-redesign/design/redesign-overview.jpg)
- [Current live Shenzhen/Beijing and day-rain preview](https://github.com/songtaoluo007-maker/harmony-weather/blob/codex/originos-weather-redesign/design/live-weather-scenes.jpg)
- [Native daytime rain motion capture](https://github.com/songtaoluo007-maker/harmony-weather/blob/codex/originos-weather-redesign/design/live-day-rain-motion.gif)
- [Earlier demo-era native rain evidence](https://github.com/songtaoluo007-maker/harmony-weather/blob/codex/originos-weather-redesign/design/redesign-rain-motion.gif)
- [Bounded design QA and test gaps](https://github.com/songtaoluo007-maker/harmony-weather/blob/codex/originos-weather-redesign/design-qa.md)
- [Design decisions and prioritized follow-up](https://github.com/songtaoluo007-maker/harmony-weather/blob/codex/originos-weather-redesign/docs/ui-redesign-2026-09.md)

## Verified in this iteration

- Hvigor `assembleHap` with SDK `6.1.1(24)` succeeds; unsigned HAP installs and
  launches on the Pura 90 emulator.
- Sixteen real-service/model tests pass with platform I/O mocked, including
  provider-separated offline restoration and city-local solar boundaries.
- Actual native HTTPS integration: Shenzhen 19:46 clear 28°C and Beijing 19:46
  cloudy 19°C, automatically lit night scenes. City switches refresh hourly
  temperatures and daily icons, not merely the current temperature/heading.
- Native city search/switch, empty result with keyboard, settings and daily-detail
  navigation, Fahrenheit and selected-city persistence across restart.
- Day/night/rain previews; disabled-motion screenshots are identical. Enabled
  motion evidence contains 18 real captures over ~14.5 seconds at their original
  sampling cadence, not a frame-rate benchmark.
- 320vp parent-width/1.3× font and 360vp parent-width smoke tests, plus the actual
  ~377vp device. All temporary QA hooks are removed.

## Limitations / review notes

- Current default is online Open-Meteo; older redesign-overview images remain
  explicitly demo-era design history. No QWeather key was available, so that
  account/API integration is reserved but unverified. Free Open-Meteo is
  non-commercial and rate-limited; model values are not station observations.
- City photos are historical scenes, not live cameras. Motion is separately
  composited clouds, rain and glass droplets. No official alerts feed is included.
- App-specific motion toggle is implemented, **not** system reduced-motion sync.
- Existing city catalog contains 15 cities; global search and drag sorting are
  future work. 390/480vp, tablet, landscape, screen reader, real location denial,
  device-offline recovery and long-duration performance remain unverified.
- Keep draft for review. No production certificate, key, signed artifact, merge
  or deployment is included. Unsigned HAP is the local build baseline.
