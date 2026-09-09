# Third-party notices

The interface icons under `entry/src/main/resources/base/media/*.svg` are sourced from
[Material Design Icons](https://github.com/Templarian/MaterialDesign), licensed under the
Apache License 2.0.

Generic weather textures/backgrounds are original AI-generated project assets.
Bundled city photographs are NOT AI-generated: daytime sources are credited in
[CITY_BACKGROUND_SOURCES.md](CITY_BACKGROUND_SOURCES.md), and night/dusk sources in
[CITY_NIGHT_SOURCES.md](CITY_NIGHT_SOURCES.md). Each photograph retains its own
license; display cropping, brightness and atmospheric compositing are indicated
there. This does not relicense the photographs as application code.

Online weather is supplied by [Open-Meteo](https://open-meteo.com/), with air-quality
model data from [CAMS](https://atmosphere.copernicus.eu/) via Open-Meteo. Data credit:
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/); see the
[Open-Meteo air-quality documentation](https://open-meteo.com/en/docs/air-quality-api)
for underlying data attribution. The app rounds temperatures, converts time to the
city offset, converts visibility to km and CO to mg/m³, maps WMO codes to Chinese,
and derives local lifestyle tips. These are project transformations, not official
life indices. The free hosted API is non-commercial and rate-limited, independently
of the open-data license: [terms](https://open-meteo.com/en/terms),
[pricing](https://open-meteo.com/en/pricing).

The `meteo_*.svg` weather icons are unmodified static Fill assets from
[@meteocons/svg-static 0.1.0](https://www.npmjs.com/package/@meteocons/svg-static/v/0.1.0)
by Bas Milius. The full MIT license is in `licenses/Meteocons-MIT.txt`.
Source: https://github.com/basmilius/meteocons

`life_clothing.png`, `life_uv.png`, and `life_sport.png` are original AI-generated
illustrations created for the September 2026 redesign. Their prompts are recorded in
`design/life-assets-prompts.md`.

The corresponding `life_*_cutout.png` illustrations are AI-edited transparent
variants for the blue-white theme. Sources, output paths and full edit prompts
are recorded in `design/bluewhite-assets-prompts.md`. City photography and
weather-motion resources were not altered by this edit.
