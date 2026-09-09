# Weather Product Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver the approved weather/news/settings product interface while preserving live weather and removing development presentation.

**Architecture:** Keep existing ArkTS routes and shared WeatherService. Shared bottom navigation replaces root routes so repeated tab switches cannot accumulate a stack; detail routes push/back normally. Independent news reader enforces HTTPS navigation policy; attribution moves to About.

**Tech Stack:** ArkTS Stage, ArkUI, ArkWeb, NetworkKit, ArkData preferences, SDK 6.1.1(24), existing Node model test harness.

**Spec:** `docs/superpowers/specs/2026-09-08-product-shell-design.md` (approved in conversation).

## Global Constraints

- Preserve existing weather modules, source-separated caches and dynamic city scenes.
- No new third-party dependencies, credentials, fake news or copied publisher content.
- Keep mandatory attribution and offline/mock data identity; remove development entry points.
- Commit on `codex/originos-weather-redesign`; update existing draft PR without merging.

### Task 1: Root navigation and weather presentation

Files: create `components/BottomNavigation.ets`; modify `pages/Index.ets`, `pages/WeatherDetails.ets`, `components/AirQualityCard.ets`, `models/WeatherPresentation.ets`, `scripts/test-weather-state.cjs`.

Interface: `BottomNavigation({ selected: 'weather' | 'news' | 'settings' })`; roots are `pages/Index`, `pages/News`, `pages/Settings`.

- [x] Add failing display-state tests: `assert.equal(presentation.status(offline), '离线数据')`; live returns empty, mock returns `示例数据`.
- [x] Run Node test harness, confirm new failures before implementation.
- [x] Implement status helper; use `router.replaceUrl({url})` for tabs, remove preview params/overrides/cards, replace source footer with concise observation/update time and About entry.
- [x] Implement semantic 44vp minimum tab buttons, preserve explicit mock/unknown identities and stale timestamp; build and inspect native home.

### Task 2: Settings, cache and About

Files: modify `services/WeatherService.ets`, `pages/Settings.ets`, `scripts/test-weather-state.cjs`; create `pages/About.ets`, `pages/Privacy.ets`, `components/PageHeader.ets`; reuse existing static city/credit models instead of duplicating attribution JSON.

Interface: `WeatherService.clearWeatherCache(context): Promise<boolean>` clears `weather_cache` plus memory/latest only after persistent clear+flush succeeds. Never clear `weather_preferences`.

- [x] Write tests asserting cleared weather memory/store, preserved selected city/unit, and failure retaining previous memory.
- [x] Observe failures; implement preferences clear/flush with false on error; clear only named app weather cache. Serialize cache reads as well as writes and protect against stale request completion.
- [x] Rewrite settings as grouped native rows/controls; confirmation before clearing and real error result; open system permission controls using SDK API.
- [x] About reuses existing packaged city and night photo credit models/source links. Privacy describes actual network/location/local persistence; official web reading is opt-in by tap.
- [x] Verify each route, settings persistence, cache confirmation and successful clear on emulator.

### Task 3: Official news reader (parallel write scope)

Files: create `models/NewsCatalog.ets`, `pages/News.ets`, `pages/NewsReader.ets`, `scripts/test-news.cjs` only.

Interfaces: catalog has fixed official channel IDs/titles/HTTPS URLs, never article snapshots; reader receives channel ID via route params, not arbitrary URL. News imports shared BottomNavigation.

- [x] Write failing tests for official URL allowlist, malicious suffix/userinfo/custom schemes/invalid channel IDs, and trusted HTTP-to-HTTPS upgrade if needed.
- [x] Implement native channel UI plus ArkWeb reader with loading/timeout/error/retry/back/refresh and user-triggered external browser fallback.
- [x] Disable file access, mixed content, native JS bridging, geolocation, media permission and window creation; fail closed on SSL errors and invalid routes. Do not change publisher DOM.
- [x] Run tests; parent integrates route registration and compiles. Native verify official article loading and browser-back behavior. Use verified official mobile entry pages after PC layout failed visual QA.

### Task 4: Integration, QA and sync

Files: modify `resources/base/profile/main_pages.json`, README/QA/PR docs; add actual emulator evidence.

- [x] Register routes; run all three Node suites (52 tests) and complete unsigned Hvigor build.
- [x] Test home→news→article→news→settings→about/privacy→home, repeated switching, city change, clear/cache recovery, live scene motion, and readable native layouts (actual ~377vp and 320vp parent for new roots).
- [x] Inspect staged diff for credentials/accidental removals; record actual test gaps (commercial authorization, full device matrix, publisher availability).
- [x] Commit/push scoped changes and update PR #1; verify remote OID and clean working tree. Implementation commit `3ed4c54bcf563e000d601777e97745b09d8c4c57` was confirmed on the open draft PR; this record follows in a documentation-only commit.
