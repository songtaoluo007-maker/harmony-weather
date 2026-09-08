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

function fixture() {
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
      if (name === '@kit.ArkData') return { preferences: prefs };
      if (name === '@kit.ArkTS') return { util: { TextDecoder: {
        create: () => ({ decodeToString: value => new TextDecoder('utf-8').decode(value) })
      } } };
      if (name === '@kit.NetworkKit') return { http: {} };
      if (name === '@kit.AbilityKit') return {};
      throw new Error('Unexpected import: ' + name);
    };
    vm.runInNewContext(code, { module, exports: module.exports, require: platformRequire,
      console: quietConsole, TextDecoder, Date, Map, setTimeout, clearTimeout }, { filename });
    return module.exports;
  }
  modules.models = load('models/WeatherModels');
  const { WeatherService, AppSettings } = load('services/WeatherService');
  const service = new WeatherService();
  const context = { resourceManager: { getRawFileContent: async (name) => {
    if (name === 'weather_config.local.json') throw new Error('not configured');
    return new Uint8Array(fs.readFileSync(path.join(root, 'entry/src/main/resources/rawfile', name)));
  } } };
  return { service, AppSettings, context, models: modules.models, stores,
    failStorage: () => { failing = true; } };
}

test('UTF-8 demo data is explicitly marked and preserves Chinese city names', async () => {
  const f = fixture();
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
  const f = fixture();
  await f.service.loadWeather(f.context); // populate a real demo cache
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

