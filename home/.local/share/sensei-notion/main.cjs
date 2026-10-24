'use strict';
// Apply a local stylesheet to the installed Notion application. Keep its own
// preload, sandbox, credentials, user-data directory, updater and window model.
const {app} = require('electron');
const fs = require('node:fs');
const path = require('node:path');
const installed = '/usr/lib/notion-app/app.asar';
if (!fs.existsSync(installed)) {
  console.error('Install notion-app-electron before starting the themed client.');
  app.exit(1);
} else {
  app.setName('Notion');
  app.setPath('userData', path.join(app.getPath('appData'), 'Notion'));
  app.setAppPath(installed);
  // Electron caches a script launcher's version as 0.0. Use the installed
  // application's actual package version for its updater and compatibility checks.
  const metadata = require(installed + '/package.json');
  app.getVersion = () => metadata.version;
  const css = fs.readFileSync(path.join(__dirname, 'theme.css'), 'utf8');
  app.on('web-contents-created', (_event, contents) => {
    let key;
    const apply = async () => {
      try {
        const location = new URL(contents.getURL());
        // The packaged client serves its web UI through a secure notion:
        // protocol unless its HTTPS flag is enabled.
        const remote = ['https:', 'notion:'].includes(location.protocol) && /(^|\.)notion\.(so|com)$/.test(location.hostname);
        const bundled = location.protocol === 'file:' && decodeURIComponent(location.pathname).startsWith(installed + '/');
        if (!remote && !bundled) return;
        if (key) await contents.removeInsertedCSS(key).catch(() => {});
        key = await contents.insertCSS(css, {cssOrigin: 'user'});
        console.info('Noesis local typography loaded for a Notion window.');
      } catch (error) {
        if (!contents.isDestroyed()) console.warn('Noesis styling:', error.message);
      }
    };
    contents.on('did-finish-load', apply);
  });
  require(installed);
}
