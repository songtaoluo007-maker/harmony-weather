// Exercise the actual non-rendering ArkTS page methods; platform services/controllers are doubles.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const { test } = require('node:test');
const studio = process.env.DEVECO_STUDIO_HOME || path.resolve(path.dirname(process.execPath), '../..');
const ts = require(path.join(studio, 'tools/hvigor/hvigor/node_modules/typescript'));
const root = path.resolve(__dirname, '../entry/src/main/ets');
const deferred = () => { let resolve; const promise = new Promise(r => { resolve = r; }); return { promise, resolve }; };

function execute(source, globals = {}) {
  const module = { exports: {} };
  const result = ts.transpileModule(source, { compilerOptions: { module: ts.ModuleKind.CommonJS,
    target: ts.ScriptTarget.ES2020 }, reportDiagnostics: true });
  assert.deepEqual(result.diagnostics, []);
  vm.runInNewContext(result.outputText, { module, exports: module.exports, Date, ...globals });
  return module.exports;
}

function page(name, globals) {
  let source = fs.readFileSync(path.join(root, 'pages', name + '.ets'), 'utf8');
  const end = source.indexOf(name === 'Index' ? '\n  build()' : '\n  @Builder');
  source = source.slice(source.indexOf('struct '), end).replace(/^struct /, 'export class ')
    .replace(/@State\s+/g, '') + '\n}';
  return Object.values(execute(source, globals))[0];
}

function home() {
  const timers = new Map();
  const settings = { unit: 'c', motionEnabled: true, refreshMinutes: 30 };
  const service = { initialize: async () => {}, getSettings: () => settings,
    getCurrentCity: () => ({ id: 'test-city' }), getCityList: () => [{ id: 'test-city' }],
    loadWeather: async () => ({ lastUpdate: 100, cityId: 'test-city' }) };
  const background = { resolve: async () => ({ imageUrl: 'test' }) };
  class Data { lastUpdate = 0; cityId = 'test-city'; }
  class Ui { static loading() { return 'loading'; } static ready() { return 'ready'; } static error() { return 'error'; } }
  const Home = page('Index', { WeatherData: Data, WeatherUiState: Ui, ThemeColors: class {},
    AtmospherePalette: class {}, WeatherDetailContent: class {},
    WeatherVisualState: { CLEAR_DAY: 'day' }, Scroller: class {}, $r: v => v,
    WeatherService: { getInstance: () => service }, CityBackgroundService: { getInstance: () => background },
    BundledCityBackgrounds: { resolve: () => null }, NightCityBackgrounds: { resolve: () => null },
    setInterval: fn => { const id = timers.size + 1; timers.set(id, fn); return id; },
    clearInterval: id => timers.delete(id) });
  const instance = new Home();
  instance.getUIContext = () => ({ getHostContext: () => ({}) });
  instance.updateScene = () => {};
  return { instance, service, background, timers };
}

test('replaced home ignores a late weather response and does not resurrect its interval', async () => {
  const f = home(), pending = deferred(), started = deferred();
  f.service.loadWeather = () => { started.resolve(); return pending.promise; };
  const appear = f.instance.aboutToAppear();
  await started.promise;
  f.instance.aboutToDisappear();
  pending.resolve({ lastUpdate: 100, cityId: 'test-city' });
  await appear;
  assert.equal(f.timers.size, 0);
  assert.equal(f.instance.weatherData.lastUpdate, 0);
  assert.equal(f.instance.pageActive, false);
});

test('destroyed home ignores late page-show initialization', async () => {
  const f = home(), pending = deferred();
  f.instance.unit = 'f';
  f.service.initialize = () => pending.promise;
  const show = f.instance.onPageShow();
  f.instance.aboutToDisappear();
  pending.resolve();
  await show;
  assert.equal(f.instance.unit, 'f');
  assert.equal(f.instance.pageActive, false);
});

test('leaving or destroying home closes its weather sheet so it cannot cover the next page', () => {
  const f = home(); f.instance.detailOpen = true;
  f.instance.onPageHide();
  assert.equal(f.instance.detailOpen, false);
  f.instance.detailOpen = true;
  f.instance.aboutToDisappear();
  assert.equal(f.instance.detailOpen, false);
});

test('refresh closes the old detail sheet before replacing its underlying weather data', async () => {
  const f = home(), pending = deferred(), started = deferred();
  f.instance.detailOpen = true;
  f.service.loadWeather = () => { started.resolve(); return pending.promise; };
  const loading = f.instance.loadData(true);
  await started.promise;
  assert.equal(f.instance.detailOpen, false);
  pending.resolve({ lastUpdate: 100, cityId: 'test-city' });
  await loading;
});

test('destroyed home ignores late city image resolution', async () => {
  const f = home(), pending = deferred();
  f.background.resolve = () => pending.promise;
  const request = f.instance.updateCityBackground({}, 'test-city');
  f.instance.aboutToDisappear();
  pending.resolve({ imageUrl: 'must-not-attach' });
  await request;
  assert.equal(f.instance.cityBackgroundUrl, '');
});

test('blocked outbound navigation preserves the readable official page and back history', () => {
  const models = execute(fs.readFileSync(path.join(root, 'models/NewsCatalog.ets'), 'utf8'));
  const Reader = page('NewsReader', { ...models, clearTimeout() {} });
  const reader = new Reader();
  const notices = [];
  reader.getUIContext = () => ({ getPromptAction: () => ({ showToast: value => notices.push(value.message) }) });
  let stopped = 0, backwards = 0;
  const view = { id: 1, attached: true, controller: { stop: () => stopped++, accessBackward: () => true,
    backward: () => backwards++ } };
  reader.generation = 1;
  reader.views = [view];
  reader.currentUrl = 'https://m.weather.com.cn/news/index.shtml';
  reader.load.begin(reader.currentUrl, Date.now());
  reader.load.finish(reader.currentUrl);
  const blocked = reader.intercept(view, { getRequestUrl: () => 'https://evil.test/', isMainFrame: () => true });
  assert.equal(blocked, true);
  assert.equal(reader.views[0], view);
  assert.equal(stopped, 0);
  assert.equal(reader.error, '');
  assert.equal(reader.currentUrl, 'https://m.weather.com.cn/news/index.shtml');
  assert.ok(notices.length);
  assert.equal(reader.goBackInWeb(), true);
  assert.equal(backwards, 1);
});
