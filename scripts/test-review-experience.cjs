// Test actual presentation decisions; no ArkUI renderer or network is simulated here.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const { test } = require('node:test');
const studio = process.env.DEVECO_STUDIO_HOME || path.resolve(path.dirname(process.execPath), '../..');
const ts = require(path.join(studio, 'tools/hvigor/hvigor/node_modules/typescript'));
const root = path.resolve(__dirname, '../entry/src/main/ets');
function fixture() {
  const cache = new Map();
  function load(relative) {
    const file = path.resolve(root, relative + '.ets');
    if (cache.has(file)) return cache.get(file);
    assert.ok(fs.existsSync(file), `${relative} must provide the production presentation model`);
    const module = { exports: {} };
    const result = ts.transpileModule(fs.readFileSync(file, 'utf8'), {
      compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 }, reportDiagnostics: true });
    assert.deepEqual(result.diagnostics, []);
    vm.runInNewContext(result.outputText, { module, exports: module.exports, Date,
      require: name => load(path.relative(root, path.resolve(path.dirname(file), name))), $r: name => name });
    cache.set(file, module.exports); return module.exports;
  }
  return { load, ...load('models/WeatherModels'), ...load('theme/AtmosphereTokens') };
}
function city(f) {
  const data = new f.WeatherData(); data.source = 'openmeteo'; data.city = '深圳';
  data.current.text = '晴'; data.current.sunrise = '06:00'; data.current.sunset = '18:30';
  data.utcOffsetSeconds = 28800; return data;
}

test('local-time materials change between day, horizon and night without allocating per redraw', () => {
  const f = fixture(), data = city(f), A = f.AtmosphereTokens;
  assert.equal(typeof A.forWeather, 'function', 'materials must derive from the real city scene');
  const day = A.forWeather(data, Date.parse('2026-09-08T12:00:00+08:00'));
  const dusk = A.forWeather(data, Date.parse('2026-09-08T18:00:00+08:00'));
  const night = A.forWeather(data, Date.parse('2026-09-08T22:00:00+08:00'));
  assert.notEqual(day.illustrationBase, night.illustrationBase);
  assert.notEqual(day.panelTop, dusk.panelTop);
  assert.notEqual(dusk.sheetBackground, night.sheetBackground);
  assert.equal(A.forWeather(data, Date.parse('2026-09-08T22:01:00+08:00')), night);
});

test('rain/haze materials preserve weather character at night instead of always using clear-night light', () => {
  const f = fixture(), d = city(f), A = f.AtmosphereTokens;
  assert.equal(typeof A.forWeather, 'function');
  const now = Date.parse('2026-09-08T22:00:00+08:00');
  const clear = A.forWeather(d, now); d.current.text = '小雨'; const rain = A.forWeather(d, now);
  d.current.text = '雾'; const haze = A.forWeather(d, now);
  assert.notEqual(clear.panelTop, rain.panelTop);
  assert.notEqual(rain.panelTop, haze.panelTop);
  assert.notEqual(rain.sheetBackground, A.forWeather(d, now - 12 * 3600000).sheetBackground);
});

test('horizon tint follows the selected city solar endpoints rather than the computer clock', () => {
  const f = fixture(), d = city(f), A = f.AtmosphereTokens;
  assert.equal(typeof A.forWeather, 'function');
  d.utcOffsetSeconds = -14400; d.current.sunset = '20:00';
  const localNoon = A.forWeather(d, Date.parse('2026-09-08T12:00:00-04:00'));
  const localDusk = A.forWeather(d, Date.parse('2026-09-08T19:45:00-04:00'));
  assert.notEqual(localNoon.panelTop, localDusk.panelTop);
  d.current.sunset = 'bad'; d.current.sunrise = 'bad';
  assert.equal(A.forWeather(d, NaN).key, 'night');
});

test('air detail keeps real pollutant units and adds source context without inventing observation time', () => {
  const f = fixture(), d = city(f); d.air.available = true; d.air.standard = 'US AQI'; d.air.aqi = 160;
  d.air.level = '不健康'; d.air.co = .788; d.air.pm25 = 77.3;
  d.observedAt = Date.parse('2026-09-08T22:00:00+08:00'); d.lastUpdate = d.observedAt + 60000;
  const D = f.load('models/WeatherDetailPresentation').WeatherDetailPresentation;
  const detail = D.air(d);
  assert.equal(detail.layout, 'metrics');
  assert.equal(detail.rows.length, 6);
  assert.equal(detail.rows.find(r => r.label === 'CO').value, '0.788');
  assert.equal(detail.rows.find(r => r.label === 'CO').unit, 'mg/m³');
  assert.equal(detail.rows.find(r => r.label === 'PM2.5').unit, 'μg/m³');
  assert.match(detail.subtitle, /US AQI/);
  assert.match(detail.context, /CAMS/);
  assert.match(detail.metadata, /09-08 22:01/);
  assert.doesNotMatch(detail.metadata, /观测.*22:00/);
});

test('unavailable air hides plausible defaults instead of displaying fabricated pollutant readings', () => {
  const f = fixture(), d = city(f); d.air.available = false;
  const detail = f.load('models/WeatherDetailPresentation').WeatherDetailPresentation.air(d);
  assert.equal(detail.rows.length, 0);
  assert.match(detail.headline, /不可用/);
  assert.doesNotMatch(detail.context, /空气清新/);
});

test('life detail preserves scope and signals offline data instead of implying a current recommendation', () => {
  const f = fixture(), d = city(f); d.isOffline = true;
  const item = new f.LifeIndex(); item.name = '紫外线'; item.caption = '今日峰值';
  item.brief = '很强'; item.detail = '今日最大紫外线指数，不代表此刻。';
  const detail = f.load('models/WeatherDetailPresentation').WeatherDetailPresentation.life(d, item);
  assert.match(detail.subtitle, /今日峰值/);
  assert.match(detail.metadata, /离线/);
  assert.equal(detail.context, item.detail);
});

test('visible local UV scope changes at city midnight even without a network refresh', () => {
  const f = fixture(), d = city(f), item = new f.LifeIndex();
  const D = f.load('models/WeatherDetailPresentation').WeatherDetailPresentation;
  assert.equal(typeof D.lifeCaption, 'function');
  item.name = '紫外线'; item.iconKey = 'uv'; item.source = 'local'; item.caption = '今日峰值';
  d.current.uvScope = 'daily_max'; d.observedAt = Date.parse('2026-09-08T23:45:00+08:00');
  assert.equal(D.lifeCaption(d, item, Date.parse('2026-09-08T23:59:00+08:00')), '今日峰值');
  assert.equal(D.lifeCaption(d, item, Date.parse('2026-09-09T00:00:00+08:00')), '预报峰值');
  d.current.uvScope = 'daily'; item.caption = '今日预报';
  assert.equal(D.lifeCaption(d, item, Date.parse('2026-09-09T00:00:00+08:00')), '逐日预报');
  item.source = 'qweather'; item.caption = '供应商时段';
  assert.equal(D.lifeCaption(d, item, Date.parse('2026-09-09T00:00:00+08:00')), '供应商时段');
});

test('detail metadata never attributes unknown providers to Qweather or synthesizes missing time', () => {
  const f = fixture(), d = city(f); d.source = 'unknown'; d.lastUpdate = 0;
  const detail = f.load('models/WeatherDetailPresentation').WeatherDetailPresentation.air(d);
  assert.doesNotMatch(detail.metadata, /和风|1970|NaN/);
  assert.match(detail.metadata, /未提供/);
});

test('alert sheet keeps every real warning instead of silently dropping additional alerts', () => {
  const f = fixture(), d = city(f);
  d.alerts = [Object.assign(new f.WeatherAlert(), {title:'暴雨提醒', detail:'真实预警甲'}),
    Object.assign(new f.WeatherAlert(), {title:'雷电提醒', detail:'真实预警乙'})];
  const detail = f.load('models/WeatherDetailPresentation').WeatherDetailPresentation.alerts(d);
  assert.equal(detail.rows.length, 2);
  assert.equal(detail.rows[1].value, '真实预警乙');
  assert.equal(detail.layout, 'list');
});

function luminance(hex) {
  assert.match(hex, /^#[0-9a-f]{6}$/i);
  const values = hex.slice(1).match(/../g).map(v => parseInt(v, 16) / 255)
    .map(v => v <= .04045 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4);
  return values[0] * .2126 + values[1] * .7152 + values[2] * .0722;
}
function contrast(a, b) {
  const x = luminance(a), y = luminance(b);
  return (Math.max(x, y) + .05) / (Math.min(x, y) + .05);
}

test('blue-white surfaces keep day readable and night dim across weather palettes', () => {
  const f = fixture(), d = city(f);
  for (const weather of ['晴', '小雨', '雾', '雪']) {
    d.current.text = weather;
    for (const hour of [12, 18, 22]) {
      const p = f.AtmosphereTokens.forWeather(d, Date.parse(`2026-09-08T${hour}:00:00+08:00`));
      assert.equal(typeof p.page, 'string');
      assert.equal(p.isLight, hour !== 22);
      assert.ok(hour === 22 ? luminance(p.page) < .09 : luminance(p.page) > .8);
      for (const bg of [p.page, p.panelTop, p.panelBottom, p.illustrationBase, p.sheetBackground]) {
        for (const ink of [p.text, p.secondary, p.muted, p.accent]) {
          assert.ok(contrast(ink, bg) >= 4.5, `${weather}/${hour}: ${ink} on ${bg}`);
        }
      }
    }
  }
});

test('surface theme mapping cannot recolor or mutate the city scene theme', () => {
  const f = fixture(), d = city(f), W = f.load('theme/WeatherTheme').WeatherTheme;
  const scene = W.getColors(f.WeatherVisualState.CLEAR_NIGHT, true);
  const original = JSON.stringify(scene);
  const p = f.AtmosphereTokens.forWeather(d, Date.parse('2026-09-08T12:00:00+08:00'));
  assert.equal(typeof p.toTheme, 'function');
  const surface = p.toTheme();
  assert.notEqual(surface.pageBackground, scene.pageBackground);
  assert.equal(surface.textColor, p.text);
  assert.equal(surface.isLight, true);
  assert.equal(JSON.stringify(scene), original);
});

test('secondary native pages inherit the last selected city surface palette', () => {
  const f = fixture(), d = city(f), T = f.load('theme/DesignTokens').DesignTokens;
  assert.equal(typeof T.usePalette, 'function');
  for (const hour of [12, 22]) {
    const p = f.AtmosphereTokens.forWeather(d, Date.parse(`2026-09-08T${hour}:00:00+08:00`));
    T.usePalette(p);
    assert.equal(T.page, p.page);
    assert.equal(T.surface, p.panelTop);
    assert.equal(T.text, p.text);
    assert.equal(T.accent, p.accent);
    assert.ok(contrast(T.muted, T.surface) >= 4.5);
  }
});

test('system bars use dark ink on blue-white surfaces but retain white ink above city photography', () => {
  const f = fixture(), T = f.load('theme/DesignTokens').DesignTokens;
  assert.equal(typeof T.barInk, 'function');
  assert.equal(T.barInk(true, false), '#172F50');
  assert.equal(T.barInk(true, true), '#FFFFFF');
  assert.equal(T.barInk(false, false), '#FFFFFF');
});
