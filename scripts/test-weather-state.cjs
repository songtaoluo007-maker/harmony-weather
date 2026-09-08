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

function deferred() {
  let resolve, reject;
  const promise = new Promise((yes, no) => { resolve = yes; reject = no; });
  return { promise, resolve, reject };
}

function fixture(provider = 'qweather') {
  const stores = new Map();
  let failing = false;
  let nextCacheFlush = null;
  const prefs = {
    getPreferences: async (_context, { name }) => {
      if (failing) throw new Error('disk unavailable');
      if (!stores.has(name)) stores.set(name, new Map());
      const data = stores.get(name);
      return {
        get: async (key, fallback) => data.has(key) ? data.get(key) : fallback,
        put: async (key, value) => data.set(key, value),
        clear: async () => data.clear(),
        flush: async () => {
          if (name !== 'weather_cache' || !nextCacheFlush) return;
          const gate = nextCacheFlush;
          nextCacheFlush = null;
          gate.entered.resolve();
          await gate.completion.promise;
        }
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
      if (name === '../models/WeatherModels' || name === './WeatherModels') return modules.models;
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
  const presentation = fs.existsSync(path.join(sourceRoot, 'models/WeatherPresentation.ets')) ? load('models/WeatherPresentation') : {};
  const snow = fs.existsSync(path.join(sourceRoot, 'models/SnowField.ets')) ? load('models/SnowField') : {};
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
    presentation: presentation.WeatherPresentation, snow: snow.SnowField,
    failStorage: () => { failing = true; },
    delayNextCacheFlush: () => {
      assert.equal(nextCacheFlush, null, 'the previous flush gate must be consumed first');
      const gate = { entered: deferred(), completion: deferred() };
      nextCacheFlush = gate;
      return { entered: gate.entered.promise,
        finish: () => gate.completion.resolve(),
        fail: () => gate.completion.reject(new Error('flush failed')) };
    } };
}

// Execute the real details fields/lifecycle method, excluding only ArkUI rendering syntax.
function weatherDetails(f) {
  const filename = path.join(sourceRoot, 'pages/WeatherDetails.ets');
  const source = fs.readFileSync(filename, 'utf8');
  const start = source.indexOf('struct WeatherDetails');
  const end = source.indexOf('  private temperature(');
  assert.ok(start >= 0 && end > start, 'details lifecycle extraction boundaries must exist');
  const code = source.slice(start, end).replace('struct WeatherDetails', 'class WeatherDetails')
    .replace(/@State\s+/g, '') + '}\nmodule.exports = WeatherDetails;';
  const result = ts.transpileModule(code, {
    compilerOptions: { target: ts.ScriptTarget.ES2020 }, reportDiagnostics: true
  });
  assert.equal((result.diagnostics || []).length, 0);
  const module = { exports: {} };
  vm.runInNewContext(result.outputText, { module, WeatherData: f.models.WeatherData,
    WeatherService: { getInstance: () => f.service } }, { filename });
  const page = new module.exports();
  page.aboutToAppear();
  return page;
}

function liveWeather(f, temp) {
  const data = new f.models.WeatherData();
  data.source = 'openmeteo'; data.lastUpdate = Date.now(); data.current.temp = temp;
  return data;
}

// Yield one event-loop turn, not a wall-clock delay, to detect reads escaping a held flush.
const nextTurn = () => new Promise(resolve => setImmediate(resolve));

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

test('wind presentation retains speed with units as well as direction and force', () => {
  const f = fixture();
  assert.equal(typeof f.presentation?.windSpeed, 'function', 'wind speed must be a displayed metric');
  assert.equal(f.presentation.windSpeed(6.9), '6.9 km/h');
  assert.equal(f.presentation.windSpeed(0), '0 km/h');
  assert.equal(f.presentation.windSpeed(-1), '暂无');
});

test('air presentation exposes all six pollutants with the correct CO unit', () => {
  const f = fixture();
  assert.equal(typeof f.presentation?.pollutants, 'function', 'all pollutant rows are required');
  const air = new f.models.AirQuality();
  const rows = f.presentation.pollutants(air);
  assert.equal(rows.length, 6);
  assert.equal(rows.map(r => r.key).join(','), 'pm25,pm10,no2,so2,co,o3');
  assert.equal(rows.find(r => r.key === 'co').unit, 'mg/m³');
  assert.equal(rows.find(r => r.key === 'so2').unit, 'μg/m³');
  air.available = false;
  assert.ok(f.presentation.pollutants(air).every(r => r.value === '暂无'));
});

test('life modules retain all six original entries without invented travel or health ratings', () => {
  const f = fixture();
  const rows = f.service.getDefaultLifeIndex(new f.models.CurrentWeather());
  for (const name of ['穿衣', '运动', '紫外线', '洗车', '旅游', '感冒']) {
    assert.ok(rows.some(r => r.name === name), `missing original life module: ${name}`);
  }
  for (const name of ['旅游', '感冒']) {
    assert.equal(rows.find(r => r.name === name).brief, '暂无数据');
  }
  assert.ok(rows.some(r => r.name === '温差'));
});

function nightPayload() {
  const data = meteoPayload();
  const start = Date.parse('2026-09-07T16:00:00Z') / 1000;
  for (const key of Object.keys(data.hourly)) data.hourly[key] = [];
  for (let i = 0; i < 48; i++) {
    data.hourly.time.push(start + i * 3600);
    data.hourly.temperature_2m.push(20);
    data.hourly.weather_code.push(i < 6 ? 95 : i >= 19 && i < 30 ? (i < 24 ? 3 : 61) : 0);
    data.hourly.is_day.push(i % 24 >= 6 && i % 24 < 19 ? 1 : 0);
    data.hourly.relative_humidity_2m.push(70);
    data.hourly.precipitation_probability.push(20);
    data.hourly.visibility.push(10000);
    data.hourly.wind_speed_10m.push(7);
    data.hourly.wind_direction_10m.push(180);
  }
  for (const key of Object.keys(data.daily)) data.daily[key].push(data.daily[key][0]);
  data.daily.time[1] += 86400;
  data.daily.sunrise[0] = start + 6 * 3600;
  data.daily.sunset[0] = start + 18.5 * 3600;
  data.daily.sunrise[1] = start + 30 * 3600;
  data.daily.sunset[1] = start + 42.5 * 3600;
  return data;
}

test('night summary uses sunset to next sunrise, not previous dawn or daily daytime code', async () => {
  const f = fixture(); const client = new f.OpenMeteoService(); const urls = [];
  client.httpGet = async url => { urls.push(url); if (url.includes('air-quality')) throw new Error('offline'); return nightPayload(); };
  const data = await client.fetch(new f.models.CityInfo());
  const first = data.daily[0];
  assert.equal(first.textNight, '阴 / 小雨');
  assert.equal(first.nightHours, 11);
  assert.equal(first.nightExpectedHours, 11);
  assert.equal(first.nightSummarySource, 'hourly');
  assert.equal(first.nightRange, '18:30–次日06:00');
  assert.ok(urls[0].includes('forecast_days=16'), 'one extra day is needed for the fifteenth night');
  const restored = f.models.WeatherData.fromMock(JSON.parse(JSON.stringify(data)));
  assert.equal(restored.daily[0].nightHours, 11);
  assert.equal(restored.daily[0].nightRange, first.nightRange);
});

test('incomplete or missing night hours are labeled instead of copied from daytime', async () => {
  const f = fixture(); const client = new f.OpenMeteoService(); const payload = nightPayload();
  payload.hourly.weather_code[20] = null;
  client.httpGet = async url => { if (url.includes('air-quality')) throw new Error('offline'); return payload; };
  const data = await client.fetch(new f.models.CityInfo());
  assert.equal(data.daily[0].nightHours, 10);
  assert.equal(data.daily[0].nightExpectedHours, 11);
  assert.equal(data.daily[1].textNight, '暂无夜间数据');
});

test('night coverage excludes malformed timestamps instead of counting them as nighttime', async () => {
  const f = fixture(); const client = new f.OpenMeteoService(); const payload = nightPayload();
  payload.hourly.time[20] = undefined;
  client.httpGet = async url => { if (url.includes('air-quality')) throw new Error('offline'); return payload; };
  const data = await client.fetch(new f.models.CityInfo());
  assert.equal(data.daily[0].nightHours, 10);
  assert.equal(data.daily[0].nightExpectedHours, 11);
});

test('snow particles fall, drift and wrap within measured containers', () => {
  const f = fixture();
  assert.equal(typeof f.snow?.frame, 'function', 'a moving snow field is required');
  for (const width of [320, 360, 390, 480]) {
    const a = f.snow.frame(width, 600, 0), b = f.snow.frame(width, 600, .02);
    assert.ok(a.length >= 30 && a.length <= 60);
    assert.ok(a.some((p, i) => p.y !== b[i].y && p.x !== b[i].x));
    assert.ok(b.every(p => p.x >= -10 && p.x <= width + 10 && p.y >= -10 && p.y <= 610));
    assert.deepEqual(f.snow.frame(width, 600, 0), f.snow.frame(width, 600, 1));
  }
});

test('upgrading an old offline cache restores life entries without changing its weather or age', async () => {
  const f = fixture('openmeteo');
  await f.service.initialize(f.context);
  const old = new f.models.WeatherData();
  old.source = 'openmeteo'; old.lastUpdate = 123456; old.current.temp = 21;
  old.lifeIndex = [{ name: '温差', iconKey: 'cold', brief: '4°', detail: 'old local advice' }];
  await f.service.savePersistentCache(f.context, old);
  f.OpenMeteoService.prototype.fetch = async () => { throw new Error('offline'); };
  const data = await f.service.loadWeather(f.context, undefined, true);
  assert.equal(data.isOffline, true);
  assert.equal(data.lastUpdate, 123456);
  assert.equal(data.current.temp, 21);
  for (const name of ['穿衣', '运动', '紫外线', '洗车', '旅游', '感冒']) {
    assert.ok(data.lifeIndex.some(item => item.name === name), name);
  }
  for (const name of ['旅游', '感冒']) assert.equal(data.lifeIndex.find(item => item.name === name).brief, '暂无数据');
  const demo = fixture('mock');
  const demoData = await demo.service.loadWeather(demo.context);
  assert.ok(demoData.lifeIndex.some(item => item.name === '旅游'));
});

test('old cached night placeholders never become a fabricated daytime copy', () => {
  const f = fixture();
  for (const textNight of [undefined, '', '见逐小时预报']) {
    const data = f.models.WeatherData.fromMock({ daily: [{ textDay: '晴', textNight }] });
    assert.equal(data.daily[0].textNight, '暂无夜间数据');
  }
  const real = f.models.WeatherData.fromMock({ daily: [{ textDay: '晴', textNight: '小雨' }] });
  assert.equal(real.daily[0].textNight, '小雨');
});

test('product status keeps offline and sample identity without a developer badge for live weather', () => {
  const f = fixture(); const data = new f.models.WeatherData();
  assert.equal(typeof f.presentation.status, 'function');
  data.source = 'openmeteo'; assert.equal(f.presentation.status(data), '');
  data.isOffline = true; assert.equal(f.presentation.status(data), '离线数据');
  data.source = 'mock'; assert.equal(f.presentation.status(data), '示例数据');
});

test('clearing weather cache removes all weather data but preserves cities and settings', async () => {
  const f = fixture('mock'); const data = await f.service.loadWeather(f.context);
  await f.service.selectCity(f.context, '101010100');
  const settings = new f.AppSettings(); settings.unit = 'f';
  await f.service.saveSettings(f.context, settings);
  assert.equal(typeof f.service.clearWeatherCache, 'function');
  assert.equal(await f.service.clearWeatherCache(f.context), true);
  assert.equal(f.stores.get('weather_cache').size, 0);
  assert.equal(f.service.peekLatestData(), null);
  assert.equal(f.service.cache.size, 0);
  assert.equal(f.service.getCurrentCity().id, '101010100');
  assert.equal(f.stores.get('weather_preferences').get('temperature_unit'), 'f');
});

test('failed cache clearing reports failure and retains the active weather', async () => {
  const f = fixture('mock'); const data = await f.service.loadWeather(f.context);
  f.failStorage();
  assert.equal(typeof f.service.clearWeatherCache, 'function');
  assert.equal(await f.service.clearWeatherCache(f.context), false);
  assert.equal(f.service.peekLatestData(), data);
});

test('a request begun before cache clearing cannot restore the cleared persistent cache', async () => {
  const f = fixture('openmeteo'); await f.service.initialize(f.context);
  let finish; let started;
  const entered = new Promise(resolve => { started = resolve; });
  const data = new f.models.WeatherData(); data.source = 'openmeteo';
  f.OpenMeteoService.prototype.fetch = () => { started(); return new Promise(resolve => { finish = resolve; }); };
  const loading = f.service.loadWeather(f.context, undefined, true);
  await entered;
  assert.equal(typeof f.service.clearWeatherCache, 'function');
  assert.equal(await f.service.clearWeatherCache(f.context), true);
  finish(data); await loading;
  assert.equal(f.stores.get('weather_cache').size, 0);
  assert.equal(f.service.cache.size, 0);
  assert.equal(f.service.peekLatestData(), null);
});

test('a fresh-cache read waits for clear flush instead of returning pre-clear memory', async () => {
  const f = fixture('openmeteo');
  f.OpenMeteoService.prototype.fetch = async () => liveWeather(f, 19);
  await f.service.loadWeather(f.context);
  const gate = f.delayNextCacheFlush();
  const clearing = f.service.clearWeatherCache(f.context);
  await gate.entered;
  f.OpenMeteoService.prototype.fetch = async () => liveWeather(f, 27);
  let settled = false;
  const loading = f.service.loadWeather(f.context).finally(() => { settled = true; });
  try {
    await nextTurn();
    assert.equal(settled, false, 'a weather read must not escape a pending clear');
  } finally { gate.finish(); await clearing; await loading; }
  const data = await loading;
  assert.equal(data.current.temp, 27);
  assert.equal(f.service.peekLatestData(), data);
  assert.equal(weatherDetails(f).data.current.temp, 27);
});

test('an empty-cache load during clear retains a live source for the actual details page', async () => {
  const f = fixture('openmeteo'); await f.service.initialize(f.context);
  const gate = f.delayNextCacheFlush();
  const clearing = f.service.clearWeatherCache(f.context);
  await gate.entered;
  f.OpenMeteoService.prototype.fetch = async () => liveWeather(f, 27);
  const loading = f.service.loadWeather(f.context);
  // Let the broken implementation capture the old revision before releasing the flush.
  await nextTurn();
  gate.finish();
  assert.equal(await clearing, true);
  const data = await loading;
  assert.equal(data.source, 'openmeteo');
  const details = weatherDetails(f);
  assert.equal(details.data.source, 'openmeteo', 'details must not fall back to an empty-source WeatherData');
  assert.equal(details.data.current.temp, 27);
  assert.equal(f.service.peekLatestData(), data);
  assert.equal(f.service.cache.get(data.cityId), data);
  assert.equal(JSON.parse(f.stores.get('weather_cache').get(`openmeteo_city_${data.cityId}`)).current.temp, 27);
});

test('a failed clear flush returns false, preserves memory and releases waiting weather reads', async () => {
  const f = fixture('openmeteo');
  f.OpenMeteoService.prototype.fetch = async () => liveWeather(f, 19);
  const previous = await f.service.loadWeather(f.context);
  const revision = f.service.cacheRevision;
  const gate = f.delayNextCacheFlush();
  const clearing = f.service.clearWeatherCache(f.context);
  await gate.entered;
  let settled = false;
  const loading = f.service.loadWeather(f.context).finally(() => { settled = true; });
  try {
    await nextTurn();
    assert.equal(settled, false, 'read must wait for the clear outcome, including failure');
  } finally { gate.fail(); await clearing; await loading; }
  assert.equal(await clearing, false);
  assert.equal(await loading, previous);
  assert.equal(f.service.peekLatestData(), previous);
  assert.equal(f.service.cache.get(previous.cityId), previous);
  assert.equal(f.service.cacheRevision, revision);
  assert.equal(await f.service.clearWeatherCache(f.context), true, 'failed flush must not poison the queue');
  f.OpenMeteoService.prototype.fetch = async () => liveWeather(f, 27);
  assert.equal((await f.service.loadWeather(f.context)).current.temp, 27);
});

test('persistent cache reads wait for a queued clear flush before resolving', async () => {
  const f = fixture('openmeteo'); await f.service.initialize(f.context);
  const gate = f.delayNextCacheFlush();
  const clearing = f.service.clearWeatherCache(f.context);
  await gate.entered;
  let settled = false;
  const reading = f.service.readPersistentCache(f.context, '101280601').finally(() => { settled = true; });
  try {
    await nextTurn();
    assert.equal(settled, false, 'persistent fallback must not observe a partial clear');
  } finally { gate.finish(); await clearing; await reading; }
  assert.equal(await reading, null);
});

test('a waiting load also waits for a second clear appended to the cache queue', async () => {
  const f = fixture('openmeteo'); await f.service.initialize(f.context);
  const first = f.delayNextCacheFlush();
  const clearFirst = f.service.clearWeatherCache(f.context);
  await first.entered;
  let fetched = false;
  f.OpenMeteoService.prototype.fetch = async () => { fetched = true; return liveWeather(f, 27); };
  const loading = f.service.loadWeather(f.context);
  await nextTurn();
  const second = f.delayNextCacheFlush();
  const clearSecond = f.service.clearWeatherCache(f.context);
  first.finish();
  await second.entered;
  try {
    await nextTurn();
    assert.equal(fetched, false, 'revision must be captured after all queued clears');
  } finally { second.finish(); await clearFirst; await clearSecond; await loading; }
  const data = await loading;
  assert.equal(f.service.peekLatestData(), data);
  assert.equal(weatherDetails(f).data.source, 'openmeteo');
});
