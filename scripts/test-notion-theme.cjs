'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = fs.readFileSync(path.join(__dirname, '../home/.local/share/sensei-notion/main.cjs'), 'utf8');
async function probe(url) {
  const events = {}, calls = [];
  const app = {setName() {}, setPath() {}, setAppPath() {}, getPath: () => '/home/test/.config', on: (n, fn) => events[n] = fn};
  const installed = '/usr/lib/notion-app/app.asar';
  const fakeRequire = name => name === 'electron' ? {app} : name === 'node:fs' ? {existsSync: () => true, readFileSync: () => '/* local theme */'} : name === 'node:path' ? path : name === installed + '/package.json' ? {version: '7.40.0'} : name === installed ? {} : assert.fail(name);
  vm.runInNewContext(source, {require: fakeRequire, __dirname: '/theme', console, URL});
  assert.equal(app.getVersion(), '7.40.0');
  const listeners = {};
  const contents = {on: (n, fn) => listeners[n] = fn, getURL: () => url, insertCSS: async (css, options) => {calls.push({css, options}); return 'style-1';}, removeInsertedCSS: async () => {}, isDestroyed: () => false};
  events['web-contents-created']({}, contents);
  await listeners['did-finish-load']();
  return calls;
}
(async () => {
  assert.equal((await probe('https://app.notion.com/private')).length, 1);
  assert.equal((await probe('https://www.notion.so/page')).length, 1);
  assert.equal((await probe('https://notion.com.evil.example/')).length, 0);
  assert.equal((await probe('https://accounts.google.com/')).length, 0);
  assert.equal((await probe('file:///placeholder.html')).length, 0);
  assert.equal((await probe('file:///usr/lib/notion-app/app.asar/.webpack/renderer/index.html')).length, 1);
  assert.equal((await probe('http://app.notion.com/')).length, 0);
  assert.equal((await probe('notion://www.notion.so/page')).length, 1);
  assert.equal((await probe('notion://evil.example/page')).length, 0);
  console.log('Notion theme: version preserved; only Notion origins styled; auth pages untouched.');
})();
