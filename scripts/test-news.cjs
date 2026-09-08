// Run with DevEco's Node; execute the real ArkTS catalog, not a JS copy of its policy.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const { test } = require('node:test');
const studio = process.env.DEVECO_STUDIO_HOME || path.resolve(path.dirname(process.execPath), '../..');
const ts = require(path.join(studio, 'tools/hvigor/hvigor/node_modules/typescript'));
const filename = path.resolve(__dirname, '../entry/src/main/ets/models/NewsCatalog.ets');

function catalog() {
  assert.ok(fs.existsSync(filename), 'NewsCatalog must provide the real official-channel safety policy');
  const result = ts.transpileModule(fs.readFileSync(filename, 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 },
    reportDiagnostics: true
  });
  assert.equal((result.diagnostics || []).length, 0, 'catalog must transpile without diagnostics');
  const module = { exports: {} };
  vm.runInNewContext(result.outputText, { module, exports: module.exports }, { filename });
  return module.exports;
}

test('channel IDs resolve to official entry pages, never arbitrary route URLs', () => {
  const { NewsCatalog: c } = catalog();
  assert.equal(c.channel('news').url, 'https://m.weather.com.cn/news/index.shtml');
  assert.equal(c.channel('science').url, 'https://m.weather.com.cn/news/kp.shtml');
  assert.equal(c.channel('science').title, '气象科普');
  for (const channel of c.channels()) {
    assert.equal(c.httpsUrl(channel.url), channel.url);
    assert.ok(channel.source && channel.title && channel.description);
    assert.ok(!('articles' in channel) && !('publishedAt' in channel));
  }
});

test('missing, malformed and prototype-like channel IDs fail closed without coercion', () => {
  const { NewsCatalog: c } = catalog();
  for (const id of [undefined, null, '', ' news', 'NEWS', 'science/', 'toString', '__proto__',
    'https://news.weather.com.cn/', 'https://m.weather.com.cn/news/index.shtml',
    1, {}, ['news'], { toString: () => 'news' }]) {
    assert.equal(c.channel(id), null, String(id));
    assert.equal(c.externalUrl(id, 'https://news.weather.com.cn/'), '');
  }
});

test('official HTTPS paths, query and fragment survive safe normalization', () => {
  const { NewsCatalog: c } = catalog();
  for (const [input, expected] of [
    ['https://m.weather.com.cn/news/index.shtml', 'https://m.weather.com.cn/news/index.shtml'],
    ['HTTPS://M.WEATHER.COM.CN:443/news/index.shtml?type=news#read', 'https://m.weather.com.cn/news/index.shtml?type=news#read'],
    ['https://news.weather.com.cn', 'https://news.weather.com.cn/'],
    ['HTTPS://WWW.WEATHER.COM.CN:443/science/?q=%E9%9B%A8#read', 'https://www.weather.com.cn/science/?q=%E9%9B%A8#read'],
    ['https://news.weather.com.cn/2026/09/4785333.shtml', 'https://news.weather.com.cn/2026/09/4785333.shtml'],
    ['https://news.weather.com.cn?type=news', 'https://news.weather.com.cn/?type=news']
  ]) assert.equal(c.httpsUrl(input), expected);
});

test('legacy HTTP is upgraded only for exact trusted hosts on the default port', () => {
  const { NewsCatalog: c } = catalog();
  assert.equal(c.httpsUrl('http://news.weather.com.cn:80/2026/09/4785333.shtml'),
    'https://news.weather.com.cn/2026/09/4785333.shtml');
  assert.equal(c.httpsUrl('http://www.weather.com.cn/science/'), 'https://www.weather.com.cn/science/');
  assert.equal(c.httpsUrl('http://m.weather.com.cn:80/news/index.shtml'), 'https://m.weather.com.cn/news/index.shtml');
  for (const input of ['http://evil.test/', 'http://news.weather.com.cn:443/',
    'http://news.weather.com.cn.evil.test/', 'http://news.weather.com.cn@evil.test/']) {
    assert.equal(c.httpsUrl(input), '');
  }
});

test('host suffix, userinfo, encoding, port and URL-parser ambiguity attacks are rejected', () => {
  const { NewsCatalog: c } = catalog();
  for (const input of [
    'https://news.weather.com.cn.evil.test/', 'https://evilnews.weather.com.cn/',
    'https://weather.com.cn/', 'https://unverified.weather.com.cn/',
    'https://news.weather.com.cn@evil.test/', 'https://user:pass@news.weather.com.cn/',
    'https://@news.weather.com.cn/', 'https://news.weather.com.cn:444/',
    'https://news.weather.com.cn:80/', 'https://news.weather.com.cn:/',
    'https://news.weather.com.cn./', 'https://news.weather.com.cn%2eevil.test/',
    'https://%6eews.weather.com.cn/', 'https://news.weather.com.cn%40evil.test/',
    'https://news.weather.com.cn\\@evil.test/', 'https://news.weather.com.cn/%5c../',
    'https://news.weather.com.cn\n.evil.test/', ' https://news.weather.com.cn/',
    'https://news.weather.com.cn/\t', 'https://news.weather.com.cn/%0d%0aHost:evil.test',
    'https:////news.weather.com.cn/', 'https://news.weather.com.cn\u3002evil.test/',
    '//news.weather.com.cn/', '/science/', 'https://127.0.0.1/',
    'https://[::1]/', 'https://news.weather.com.cn/%zz',
    null, undefined, 9, {}, ['https://news.weather.com.cn/']
  ]) assert.equal(c.httpsUrl(input), '', String(input));
});

test('mobile official host rejects adversarial suffixes, userinfo and encoded authorities', () => {
  const { NewsCatalog: c } = catalog();
  for (const input of [
    'https://m.weather.com.cn.evil.test/news/index.shtml', 'http://m.weather.com.cn.evil.test/',
    'https://evilm.weather.com.cn/', 'https://sub.m.weather.com.cn/',
    'https://m.weather.com.cn@evil.test/', 'http://m.weather.com.cn@evil.test/',
    'https://user:pass@m.weather.com.cn/', 'https://@m.weather.com.cn/',
    'https://%6d.weather.com.cn/', 'https://m.weather.com.cn%40evil.test/',
    'https://m.weather.com.cn%2eevil.test/', 'https://m.weather.com.cn\\@evil.test/',
    'https://m.weather.com.cn./', 'https://m.weather.com.cn:444/', 'http://m.weather.com.cn:443/'
  ]) {
    assert.equal(c.httpsUrl(input), '', input);
    assert.equal(c.origin(input), '', input);
  }
});

test('custom schemes and local/script/blob content cannot enter Web or browser fallback', () => {
  const { NewsCatalog: c } = catalog();
  for (const input of ['javascript:alert(1)', 'file:///data/storage/el1/bundle/a', 'data:text/html,hi',
    'about:blank', 'blob:https://news.weather.com.cn/id', 'intent://news.weather.com.cn/',
    'mailto:news@weather.com.cn', 'tel:123', 'ftp://news.weather.com.cn/', 'huawei://weather']) {
    assert.equal(c.httpsUrl(input), '');
    assert.equal(c.externalUrl('news', input), 'https://m.weather.com.cn/news/index.shtml');
    assert.equal(c.externalUrl('science', input), 'https://m.weather.com.cn/news/kp.shtml');
  }
});

test('external browser fallback uses a validated current page or fixed channel home', () => {
  const { NewsCatalog: c } = catalog();
  assert.equal(c.externalUrl('science', 'http://news.weather.com.cn/2021/05/3464628.shtml'),
    'https://news.weather.com.cn/2021/05/3464628.shtml');
  assert.equal(c.externalUrl('science', 'https://evil.test/'), 'https://m.weather.com.cn/news/kp.shtml');
  assert.equal(c.externalUrl('science', ''), 'https://m.weather.com.cn/news/kp.shtml');
  assert.equal(c.externalUrl('science', 'http://m.weather.com.cn/news/kp.shtml'), 'https://m.weather.com.cn/news/kp.shtml');
  assert.equal(c.externalUrl('science', 'http://www.weather.com.cn/science/'), 'https://www.weather.com.cn/science/');
  assert.equal(c.externalUrl('news', ''), 'https://m.weather.com.cn/news/index.shtml');
  assert.equal(c.externalUrl('news', 'https://m.weather.com.cn.evil.test/'), 'https://m.weather.com.cn/news/index.shtml');
  assert.equal(c.externalUrl('news', 'http://m.weather.com.cn/news/index.shtml'), 'https://m.weather.com.cn/news/index.shtml');
  assert.equal(c.externalUrl('news', 'https://news.weather.com.cn/2026/09/4785333.shtml'),
    'https://news.weather.com.cn/2026/09/4785333.shtml');
  assert.equal(c.origin('https://m.weather.com.cn/news/index.shtml'), 'https://m.weather.com.cn');
  assert.equal(c.origin('http://news.weather.com.cn/a?b=c#d'), 'https://news.weather.com.cn');
  assert.equal(c.origin('https://news.weather.com.cn@evil.test/'), '');
});

test('mutating a returned channel cannot poison later route resolution', () => {
  const { NewsCatalog: c } = catalog();
  const first = c.channels();
  first[0].url = 'https://evil.test/'; first.splice(1);
  assert.equal(c.channel('news').url, 'https://m.weather.com.cn/news/index.shtml');
  assert.equal(c.channel('science').url, 'https://m.weather.com.cn/news/kp.shtml');
});

test('reader times out at 20 seconds, and late completion cannot clear a failure', () => {
  const { NewsLoadState } = catalog();
  const state = new NewsLoadState();
  assert.equal(state.begin('https://news.weather.com.cn/', 1000), true);
  assert.equal(state.expire(20999), false);
  assert.equal(state.loading, true);
  assert.equal(state.expire(21000), true);
  assert.equal(state.loading, false);
  assert.ok(state.error);
  assert.equal(state.finish('https://news.weather.com.cn/'), false);
  assert.ok(state.error);
});

test('reader ignores stale completion after a new navigation and permits explicit retry', () => {
  const { NewsLoadState } = catalog();
  const state = new NewsLoadState();
  state.begin('https://news.weather.com.cn/', 0);
  state.begin('https://www.weather.com.cn/science/', 50);
  assert.equal(state.finish('https://news.weather.com.cn/'), false);
  state.fail('SSL validation failed');
  assert.equal(state.finish('https://www.weather.com.cn/science/'), false);
  assert.equal(state.begin('https://www.weather.com.cn/science/', 100), true);
  assert.equal(state.error, '');
  assert.equal(state.finish('https://www.weather.com.cn/science/#read'), true);
  assert.equal(state.expire(99999), false);
  assert.equal(state.loading, false);
});

test('an invalid reader destination never starts loading', () => {
  const { NewsLoadState } = catalog();
  const state = new NewsLoadState();
  assert.equal(state.begin('javascript:alert(1)', 0), false);
  assert.equal(state.loading, false);
  assert.equal(state.url, '');
  assert.ok(state.error);
});

test('redirects share the original deadline and cannot keep the reader loading forever', () => {
  const { NewsLoadState } = catalog();
  const state = new NewsLoadState();
  state.begin('https://news.weather.com.cn/', 1000);
  state.begin('https://www.weather.com.cn/science/', 19000);
  assert.equal(state.expire(21000), true);
  assert.ok(state.error);
  assert.equal(state.isCurrent('https://www.weather.com.cn.evil.test/science/'), false);
});

test('new ArkUI sources parse with the installed SDK component grammar', () => {
  const sdk = path.join(studio, 'sdk/default/openharmony/ets');
  const arkts = require(path.join(sdk, 'build-tools/ets-loader/node_modules/typescript'));
  const components = Object.keys(JSON.parse(fs.readFileSync(path.join(sdk, 'component/component_config.json'), 'utf8')));
  const options = { ets: { render: { method: ['build'], decorator: ['Builder'] }, components } };
  for (const relative of ['models/NewsCatalog.ets', 'pages/News.ets', 'pages/NewsReader.ets']) {
    const file = path.resolve(__dirname, '../entry/src/main/ets', relative);
    const ast = arkts.createSourceFile(file, fs.readFileSync(file, 'utf8'),
      arkts.ScriptTarget.Latest, true, arkts.ScriptKind.ETS, options);
    const diagnostics = ast.parseDiagnostics.map(d =>
      `${relative}:${ast.getLineAndCharacterOfPosition(d.start).line + 1} ${arkts.flattenDiagnosticMessageText(d.messageText, ' ')}`);
    assert.deepEqual(diagnostics, []);
  }
});
