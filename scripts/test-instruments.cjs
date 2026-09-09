const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const { test } = require('node:test');
const studio = process.env.DEVECO_STUDIO_HOME || path.resolve(path.dirname(process.execPath), '../..');
const ts = require(path.join(studio, 'tools/hvigor/hvigor/node_modules/typescript'));
const root = path.resolve(__dirname, '../entry/src/main/ets/models');
function load(name, globals = {}) {
  const filename = path.join(root, name + '.ets');
  assert.ok(fs.existsSync(filename), 'instrument model must exist to drive the actual native drawings');
  const result = ts.transpileModule(fs.readFileSync(filename, 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 }, reportDiagnostics: true });
  assert.deepEqual(result.diagnostics, []);
  const module = { exports: {} };
  vm.runInNewContext(result.outputText, { module, exports: module.exports, Date, ...globals });
  return module.exports;
}
function fixture() {
  const models = load('WeatherModels');
  const instruments = load('WeatherInstruments', { require: name => {
    assert.equal(name, './WeatherModels'); return models;
  } });
  return { ...models, ...instruments };
}

test('compass uses the reported wind origin and does not invent a north bearing for unknown wind', () => {
  const { WeatherInstruments: I } = fixture();
  for (const [direction, bearing] of [['北风', 0], ['东北风', 45], ['东风', 90], ['东南风', 135],
    ['南风', 180], ['西南风', 225], ['西风', 270], ['西北风', 315]]) assert.equal(I.bearing(direction), bearing);
  for (const unknown of ['', '无持续风向', '静风', '变化']) assert.equal(I.bearing(unknown), -1);
});

test('percentage instruments clamp geometry but keep invalid input unavailable', () => {
  const { WeatherInstruments: I } = fixture();
  assert.equal(I.fraction(41), .41);
  assert.equal(I.fraction(-10), 0);
  assert.equal(I.fraction(130), 1);
  assert.equal(I.fraction(NaN), -1);
});

test('AQI marker follows unequal category thresholds without changing the supplied index', () => {
  const { WeatherInstruments: I } = fixture();
  assert.equal(I.aqiPosition(0), 0);
  assert.equal(I.aqiPosition(50), 1 / 6);
  assert.equal(I.aqiPosition(100), 2 / 6);
  assert.equal(I.aqiPosition(250), .75);
  assert.equal(I.aqiPosition(500), 1);
  assert.equal(I.aqiPosition(800), 1);
  assert.equal(I.aqiPosition(-1), -1);
  assert.equal(I.aqiPosition(NaN), -1);
});

test('AQI tint uses all six severity bands, including the correct boundary values', () => {
  const { WeatherInstruments: I } = fixture();
  for (const [value, band] of [[0, 0], [50, 0], [51, 1], [100, 1], [101, 2], [150, 2],
    [151, 3], [200, 3], [201, 4], [300, 4], [301, 5], [800, 5], [-1, -1], [NaN, -1]]) {
    assert.equal(I.aqiBand(value), band);
  }
});

function weather(f) {
  const data = new f.WeatherData();
  data.utcOffsetSeconds = 28800;
  const day = new f.DailyWeather(); day.date = '2026-09-08';
  day.sunriseAt = Date.parse('2026-09-08T06:00:00+08:00');
  day.sunsetAt = Date.parse('2026-09-08T18:00:00+08:00');
  data.daily = [day]; return data;
}

test('solar card uses the city date and real daily endpoints at sunrise noon sunset and night', () => {
  const f = fixture(), data = weather(f);
  for (const [time, position, visible] of [['05:59:00', 0, false], ['06:00:00', 0, true],
    ['12:00:00', .5, true], ['18:00:00', 1, false], ['23:00:00', 1, false]]) {
    const reading = f.WeatherInstruments.solar(data, Date.parse('2026-09-08T' + time + '+08:00'));
    assert.equal(reading.valid, true);
    assert.equal(reading.progress, position);
    assert.equal(reading.sunVisible, visible);
    assert.equal(reading.rise, '06:00'); assert.equal(reading.set, '18:00');
    assert.equal(reading.duration, '12小时');
  }
});

test('solar card does not put a fake sun onto an old or invalid forecast', () => {
  const f = fixture(), data = weather(f);
  const stale = f.WeatherInstruments.solar(data, Date.parse('2026-09-09T12:00:00+08:00'));
  assert.equal(stale.valid, false); assert.equal(stale.sunVisible, false);
  data.daily[0].sunsetAt = data.daily[0].sunriseAt;
  assert.equal(f.WeatherInstruments.solar(data, Date.parse('2026-09-08T12:00:00+08:00')).valid, false);
});

test('solar local labels handle a negative UTC offset independently of the device timezone', () => {
  const f = fixture(), data = weather(f);
  data.utcOffsetSeconds = -14400;
  data.daily[0].sunriseAt = Date.parse('2026-09-08T06:10:00-04:00');
  data.daily[0].sunsetAt = Date.parse('2026-09-08T18:42:00-04:00');
  const reading = f.WeatherInstruments.solar(data, Date.parse('2026-09-08T12:26:00-04:00'));
  assert.equal(reading.rise, '06:10'); assert.equal(reading.set, '18:42');
  assert.equal(reading.duration, '12小时32分'); assert.equal(reading.progress, .5);
});
