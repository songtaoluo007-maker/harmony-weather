# Design QA

- Source visual truth: `D:/Dev/Project/harmony_weather/design/originos-weather-target.png`
- Implementation screenshot: `D:/Dev/Project/harmony_weather/design/implementation-shenzhen-day-v2.jpeg`
- Viewport: 390 × 844 logical comparison; emulator capture 1320 × 2856
- State: 深圳、晴天、日间、26°C；首页首屏
- Full-view comparison: `D:/Dev/Project/harmony_weather/design/qa-full-comparison-v3.jpg`
- Focused comparison: `D:/Dev/Project/harmony_weather/design/qa-hero-comparison-v3.jpg`
- Additional state evidence: `implementation-beijing-dynamic.jpeg` verifies city switching; `rain-dynamic-preview.gif` verifies rain and wet-glass motion.

**Findings**

- No actionable P0, P1, or P2 differences remain.
- Typography: HarmonyOS Sans hierarchy, optical weights, temperature scale, forecast labels, and compact metadata match the selected OriginOS direction. Native status-bar text is intentionally present in the emulator capture.
- Spacing and layout: hero, alert chip, hourly forecast, 15-day forecast, metrics, and life-index sequence preserve the source hierarchy. Native safe-area handling adds a small top offset without clipping or overlap.
- Colors and tokens: the implementation keeps the source's blue atmospheric palette while using slightly stronger lower-page scrims so white text remains readable over automatically sourced city photography.
- Image quality: all visible weather and action icons are real vector assets. The source's fixed Shenzhen illustration is intentionally replaced by a real per-city image layer; city assets are sharp, correctly cropped, and automatically mapped by stable city ID.
- Copy and content: Chinese labels are coherent and UTF-8 rendering is correct. Dynamic timestamps, city names, weather data, and source attribution are intentionally data-driven.
- Accessibility and behavior: 44 vp controls, accessibility labels, reduced-motion setting, scroll behavior, loading/error/offline states, and city switching are implemented. No visible clipping occurs at the tested 390-wide viewport.

**Patches made since the previous QA pass**

- Replaced the oversized full-width warning bar with a compact source-aligned alert chip.
- Lightened daytime imagery and reduced default scrim/card opacity.
- Added automatic city-ID background switching with bundled offline assets for all configured cities.
- Added slow cloud drift, animated distant rain, and a foreground wet-glass layer; all stop when dynamic effects are disabled.

**Follow-up Polish**

- [P3] Add a subtle reusable sunlight/glare layer for clear daytime scenes to echo the reference's brighter upper-right sun without tying it to one city.

final result: passed
