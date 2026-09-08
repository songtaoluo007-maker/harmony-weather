// Run with DevEco's Node; transpile the real ArkTS classes and stub platform I/O only.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const { test } = require('node:test');
const studio = process.env.DEVECO_STUDIO_HOME || path.resolve(path.dirname(process.execPath), '../..');
const ts = require(path.join(studio, 'tools/hvigor/hvigor/node_modules/typescript'));
const root = path.resolve(__dirname, '..');
const sourceRoot = path.join(root, 'entry/src/main/ets');

function fixture(provider = 'qweather') {
  const stores = new Map();
  let failing = false;
  const prefs = {
    getPreferences: async (_context, { name }) => {
      if (failing) throw new Error('disk unavailable');
      if (!stores.has(name)) stores.set(name, new Map());
      const data = stores.get(name);
      return {
        get: async (key, fallback) => data.has(key) ? data.get(key) : fallback,
        put: async (key, value) => data.set(key, value),
        flush: async () => {}
      };
    }
  };
  const quietConsole = { log() {}, warn() {}, error() {} };
  const modules = {};
  function load(relative) {
    const filename = path.join(sourceRoot, relative + '.ets');
    const code = ts.transpileModule(fs.readFileSync(filename, 'utf8'), {
      compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 }
    }).outputText;
    const module = { exports: {} };
    const platformRequire = (name) => {
      if (name === '../models/WeatherModels') return modules.models;
      if (name === './OpenMeteoService') return modules.openMeteo;
      if (name === '@kit.ArkData') return { preferences: prefs };
      if (name === '@kit.ArkTS') return { util: { TextDecoder: {
        create: () => ({ decodeToString: value => new TextDecoder('utf-8').decode(value) })
      } } };
      if (name === '@kit.NetworkKit') return { http: {} };
      if (name === '@kit.AbilityKit') return {};
      throw new Error('Unexpected import: ' + name);
    };
    vm.runInNewContext(code, { module, exports: module.exports, require: platformRequire,
      console: quietConsole, TextDecoder, Date, Map, setTimeout, clearTimeout, $r: name => name }, { filename });
    return module.exports;
  }
  modules.models = load('models/WeatherModels');
  modules.openMeteo = fs.existsSync(path.join(sourceRoot, 'services/OpenMeteoService.ets')) ? load('services/OpenMeteoService') : {};
  const { WeatherService, AppSettings } = load('services/WeatherService');
  const service = new WeatherService();
  const context = { resourceManager: { getRawFileContent: async (name) => {
    if (name === 'weather_config.local.json') throw new Error('not configured');
    const content = fs.readFileSync(path.join(root, 'entry/src/main/resources/rawfile', name));
    if (name === 'weather_config.json') {
      const config = JSON.parse(content); config.provider = provider;
      return new TextEncoder().encode(JSON.stringify(config));
    }
    return new Uint8Array(content);
  } } };
  return { service, AppSettings, context, models: modules.models, stores,
    OpenMeteoService: modules.openMeteo.OpenMeteoService, theme: load('theme/WeatherTheme').WeatherTheme,
    failStorage: () => { failing = true; } };
}

test('UTF-8 demo data is explicitly marked and preserves Chinese city names', async () => {
  const f = fixture('mock');
  const data = await f.service.loadWeather(f.context);
  assert.equal(data.city, '深圳');
  assert.equal(data.source, 'mock');
  assert.equal(data.current.text, '晴');
  assert.equal(data.daily.length, 15);
  assert.equal(data.hourly[0].time, '现在');
  assert.ok(data.daily[0].date.startsWith(String(new Date().getFullYear())));
});

test('both template key formats are rejected before network use', async () => {
  const f = fixture();
  await f.service.initialize(f.context);
  for (const apiKey of ['YOUR_API_KEY_HERE', 'YOUR_QWEATHER_API_KEY', '', ' ']) {
    f.service.config.apiKey = apiKey;
    assert.equal(f.service.hasLiveConfiguration(), false);
  }
});

test('live failure never substitutes cached demo data', async () => {
  const f = fixture('mock');
  await f.service.loadWeather(f.context); // populate a real demo cache
  f.service.config.provider = 'qweather';
  f.service.config.apiKey = 'test-only-configured-key';
  f.service.fetchFromAPI = async () => { throw new Error('API unavailable'); };
  await assert.rejects(f.service.loadWeather(f.context, undefined, true), /暂无可用的真实天气缓存/);
});

test('live cache survives network failure with source and stale flag intact', async () => {
  const f = fixture();
  await f.service.initialize(f.context);
  f.service.config.apiKey = 'test-only-configured-key';
  const live = new f.models.WeatherData();
  live.source = 'qweather';
  live.lastUpdate = Date.now() - 3_600_000;
  live.current.temp = 19;
  f.service.fetchFromAPI = async () => live;
  await f.service.loadWeather(f.context, undefined, true);
  f.service.fetchFromAPI = async () => { throw new Error('network unavailable'); };
  const cached = await f.service.loadWeather(f.context, undefined, true);
  assert.equal(cached.source, 'qweather');
  assert.equal(cached.isOffline, true);
  assert.equal(cached.current.temp, 19);
  assert.equal(cached.lastUpdate, live.lastUpdate);
});

test('city deletion is persisted by ID and selecting it adds it back', async () => {
  const f = fixture();
  await f.service.initialize(f.context);
  const id = '101010100';
  assert.equal(await f.service.removeSavedCity(f.context, id), true);
  assert.equal(f.service.getSavedCities().some(city => city.id === id), false);
  assert.ok(f.stores.get('weather_preferences').get('hidden_city_ids').includes(id));
  assert.equal(await f.service.selectCity(f.context, id), true);
  assert.equal(f.service.getCurrentCity().name, '北京');
  assert.equal(f.service.getSavedCities().some(city => city.id === id), true);
  assert.equal(await f.service.removeSavedCity(f.context, id), false);
});

test('failed storage leaves the previous settings and selected city intact', async () => {
  const f = fixture();
  await f.service.initialize(f.context);
  const settings = new f.AppSettings();
  settings.unit = 'f';
  f.failStorage();
  assert.equal(await f.service.saveSettings(f.context, settings), false);
  assert.equal(f.service.getSettings().unit, 'c');
  assert.equal(await f.service.selectCity(f.context, '101010100'), false);
  assert.equal(f.service.getCurrentCity().name, '深圳');
  assert.equal(await f.service.removeSavedCity(f.context, '101010100'), false);
});

test('sunrise and sunset use their minute boundaries', () => {
  const f = fixture();
  const resolve = hour => f.models.WeatherData.resolveVisualState('晴', hour, '05:46', '19:13');
  assert.equal(resolve(5.5), 'clear_night');
  assert.equal(resolve(5 + 46 / 60), 'clear_day');
  assert.equal(resolve(19.1), 'clear_day');
  assert.equal(resolve(19 + 13 / 60), 'clear_night');
});

test('city clock chooses a lit night scene independently of device timezone', () => {
  const f = fixture();
  assert.equal(typeof f.models.WeatherData.sceneAt, 'function', 'city-clock scene resolver is required');
  const data = new f.models.WeatherData();
  data.utcOffsetSeconds = 28800;
  data.current.sunrise = '06:08'; data.current.sunset = '18:34';
  const scene = f.models.WeatherData.sceneAt(data, Date.parse('2026-09-08T11:00:00Z'));
  assert.equal(scene.hour, 19);
  assert.equal(scene.isNight, true);
  assert.equal(scene.visualState, 'clear_night');
  data.current.text = '小雨';
  assert.equal(f.models.WeatherData.sceneAt(data, Date.parse('2026-09-08T04:00:00Z')).isNight, false);
  assert.equal(f.models.WeatherData.sceneAt(data, Date.parse('2026-09-08T11:00:00Z')).isNight, true);
});

test('rain palettes distinguish daylight from night rather than always darkening', () => {
  const f = fixture();
  assert.notEqual(f.theme.getColors('rain', false).skyTop, f.theme.getColors('rain', true).skyTop);
});

function meteoPayload() {
  const seconds = iso => Date.parse(iso) / 1000;
  const at = seconds('2026-09-08T11:00:00Z');
  return { timezone: 'Asia/Shanghai', utc_offset_seconds: 28800,
    current: { time: at, temperature_2m: 28, apparent_temperature: 34, relative_humidity_2m: 87,
      weather_code: 0, is_day: 0, precipitation: 0, cloud_cover: 14, pressure_msl: 1006.7,
      wind_speed_10m: 6.9, wind_direction_10m: 225 },
    hourly: { time: [at - 3600, at, at + 3600], temperature_2m: [29, 28, 27],
      weather_code: [0, 0, 61], is_day: [1, 0, 0], precipitation_probability: [0, 0, 75],
      visibility: [12000, 10000, 8000], relative_humidity_2m: [80, 87, 90],
      wind_speed_10m: [6, 7, 8], wind_direction_10m: [225, 225, 225] },
    daily: { time: [seconds('2026-09-07T16:00:00Z')], weather_code: [61],
      temperature_2m_max: [31], temperature_2m_min: [25],
      sunrise: [seconds('2026-09-07T22:08:00Z')], sunset: [seconds('2026-09-08T10:34:00Z')],
      uv_index_max: [8], precipitation_probability_max: [75], wind_speed_10m_max: [12],
      wind_direction_10m_dominant: [225] } };
}

test('free provider maps online data, city time, units and forecast without a key', async () => {
  const f = fixture();
  assert.equal(typeof f.OpenMeteoService, 'function', 'free weather adapter is required');
  const client = new f.OpenMeteoService();
  const requests = [];
  client.httpGet = async url => {
    requests.push(url);
    return url.includes('air-quality') ? { current: { us_aqi: 52, pm2_5: 10, pm10: 18, carbon_monoxide: 200,
      nitrogen_dioxide: 12, sulphur_dioxide: 3, ozone: 40 } } : meteoPayload();
  };
  const data = await client.fetch(new f.models.CityInfo('101280601', '深圳', '广东', 22.5431, 114.0579));
  assert.equal(data.source, 'openmeteo');
  assert.equal(data.current.temp, 28);
  assert.equal(data.current.sunset, '18:34');
  assert.equal(data.current.visibility, 10);
  assert.equal(data.utcOffsetSeconds, 28800);
  assert.equal(data.hourly[0].time, '19:00');
  assert.equal(data.hourly[0].isDay, false);
  assert.equal(data.daily[0].pop, 75);
  assert.equal(data.air.standard, 'US AQI');
  assert.equal(data.air.co, .2);
  assert.equal(data.alerts.length, 0);
  assert.ok(requests.every(url => !/[?&](key|apikey)=/.test(url)));
  const cached = f.models.WeatherData.fromMock(JSON.parse(JSON.stringify(data)));
  assert.equal(cached.observedAt, data.observedAt);
  assert.equal(cached.daily[0].sunsetAt, data.daily[0].sunsetAt);
  assert.equal(cached.air.standard, 'US AQI');
});

test('optional air failure cannot invent clean air or discard valid weather', async () => {
  const f = fixture();
  assert.equal(typeof f.OpenMeteoService, 'function', 'free weather adapter is required');
  const client = new f.OpenMeteoService();
  client.httpGet = async url => {
    if (url.includes('air-quality')) throw new Error('air unavailable');
    return meteoPayload();
  };
  const data = await client.fetch(new f.models.CityInfo('101280601', '深圳', '广东', 22.5431, 114.0579));
  assert.equal(data.current.temp, 28);
  assert.equal(data.air.available, false);
  client.httpGet = async () => { const response = meteoPayload(); response.current.temperature_2m = null; return response; };
  await assert.rejects(client.fetch(new f.models.CityInfo()), /天气/);
});

test('partial air data is unavailable rather than invented zero pollution', async () => {
  const f = fixture();
  const client = new f.OpenMeteoService();
  client.httpGet = async url => url.includes('air-quality') ? { current: {
    us_aqi: 52, pm2_5: null, pm10: 18, carbon_monoxide: 200,
    nitrogen_dioxide: 12, sulphur_dioxide: 3, ozone: 40
  } } : meteoPayload();
  const data = await client.fetch(new f.models.CityInfo());
  assert.equal(data.air.available, false);
});

test('provider-separated persisted caches restore only the selected live source', async () => {
  const f = fixture();
  await f.service.initialize(f.context);
  for (const source of ['mock', 'qweather', 'openmeteo']) {
    const data = new f.models.WeatherData();
    data.cityId = '101280601'; data.source = source;
    await f.service.savePersistentCache(f.context, data);
  }
  f.service.config.provider = 'openmeteo';
  assert.equal(f.service.hasLiveConfiguration(), true);
  const cache = f.stores.get('weather_cache');
  assert.ok(cache.has('openmeteo_city_101280601'));
  assert.ok(cache.has('qweather_city_101280601'));
  assert.ok(cache.has('mock_city_101280601'));
  assert.equal((await f.service.readPersistentCache(f.context, '101280601')).source, 'openmeteo');
  cache.delete('openmeteo_city_101280601');
  assert.equal(await f.service.readPersistentCache(f.context, '101280601'), null);
});

test('the city clock rolls over to the next forecast day and survives cache restoration', () => {
  const f = fixture();
  const data = new f.models.WeatherData();
  data.current.sunrise = '05:00'; data.current.sunset = '20:00';
  const next = new f.models.DailyWeather();
  next.date = '2026-09-09';
  next.sunriseAt = Date.parse('2026-09-08T22:12:00Z');
  next.sunsetAt = Date.parse('2026-09-09T10:32:00Z');
  data.daily = [next];
  const restored = f.models.WeatherData.fromMock(JSON.parse(JSON.stringify(data)));
  assert.equal(f.models.WeatherData.sceneAt(restored, next.sunriseAt - 60_000).isNight, true);
  assert.equal(f.models.WeatherData.sceneAt(restored, next.sunriseAt).isNight, false);
  assert.equal(f.models.WeatherData.sceneAt(restored, next.sunsetAt).isNight, true);
});

test('missing live credentials do not silently switch the selected provider to demo', async () => {
  const f = fixture('qweather');
  await f.service.initialize(f.context);
  assert.equal(f.service.getProvider(), 'qweather');
  await assert.rejects(f.service.loadWeather(f.context), /配置/);
});

test('Open-Meteo network failure restores persistent real data after clearing memory', async () => {
  const f = fixture('openmeteo');
  const client = new f.OpenMeteoService();
  client.httpGet = async url => {
    if (url.includes('air-quality')) throw new Error('air unavailable');
    return meteoPayload();
  };
  const real = await client.fetch(new f.models.CityInfo('101280601', '深圳', '广东', 22.5431, 114.0579));
  f.OpenMeteoService.prototype.fetch = async () => real;
  await f.service.loadWeather(f.context, undefined, true);
  f.service.cache.clear();
  f.OpenMeteoService.prototype.fetch = async () => { throw new Error('network unavailable'); };
  const cached = await f.service.loadWeather(f.context, undefined, true);
  assert.equal(cached.source, 'openmeteo');
  assert.equal(cached.isOffline, true);
  assert.equal(cached.observedAt, real.observedAt);
  assert.equal(cached.air.available, false);
  assert.equal(cached.hourly[0].temp, 28);
  assert.equal(cached.daily[0].sunsetAt, real.daily[0].sunsetAt);
});
