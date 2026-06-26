// Slack Digest local refresh server.
// Runs claude -p via regenerate.sh when the refresh button is clicked.
// Start manually: node server.mjs
// Or install the LaunchAgent: com.rutaroberts.slack-digest-server.plist

import { createServer } from 'http'
import { spawn }        from 'child_process'
import { join, dirname } from 'path'
import { fileURLToPath } from 'url'
import { readFileSync, writeFileSync } from 'fs'

const PORT   = 3141
const DIR    = dirname(fileURLToPath(import.meta.url))
const SCRIPT = join(DIR, 'regenerate.sh')

const server = createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*')
  res.setHeader('Content-Type', 'application/json')

  if (req.url === '/ping') {
    return res.end(JSON.stringify({ ok: true }))
  }

  if (req.method === 'POST' && req.url === '/dismiss') {
    let body = '';
    req.on('data', chunk => { body += chunk });
    req.on('end', () => {
      try {
        const { id } = JSON.parse(body || '{}');
        const file = join(DIR, 'dismissed.json');
        let list = [];
        try { list = JSON.parse(readFileSync(file, 'utf8')); } catch (_) {}
        if (id && !list.includes(id)) { list.push(id); writeFileSync(file, JSON.stringify(list, null, 2)); }
        console.log(`[digest] Dismissed: ${id}`);
      } catch (err) { console.error('[digest] dismiss error:', err.message); }
      res.end(JSON.stringify({ ok: true }));
    });
    return;
  }

  if (req.url === '/settings') {
    if (req.method === 'GET') {
      try {
        const data = JSON.parse(readFileSync(join(DIR, 'settings.json'), 'utf8'));
        return res.end(JSON.stringify(data));
      } catch {
        return res.end(JSON.stringify({}));
      }
    }
    if (req.method === 'POST') {
      let body = '';
      req.on('data', chunk => { body += chunk });
      req.on('end', () => {
        try {
          const settings = JSON.parse(body || '{}');
          writeFileSync(join(DIR, 'settings.json'), JSON.stringify(settings, null, 2));
          console.log('[digest] Settings saved to settings.json');
        } catch (err) { console.error('[digest] settings error:', err.message); }
        res.end(JSON.stringify({ ok: true }));
      });
      return;
    }
  }

  if (req.method === 'GET' && req.url === '/refresh') {
    console.log('[digest] Refresh requested — running regenerate.sh')
    const proc = spawn('/bin/bash', [SCRIPT], { timeout: 300_000 })
    let log = ''
    proc.stdout.on('data', d => { process.stdout.write(d); log += d })
    proc.stderr.on('data', d => { process.stderr.write(d); log += d })
    proc.on('close', code => {
      res.end(JSON.stringify({ ok: code === 0, log: log.slice(-400) }))
    })
    proc.on('error', err => {
      res.end(JSON.stringify({ ok: false, error: err.message }))
    })
    return
  }

  res.writeHead(404)
  res.end(JSON.stringify({ error: 'not found' }))
})

server.on('error', err => {
  if (err.code === 'EADDRINUSE') {
    console.error(`[digest] Port ${PORT} already in use — another instance is running.`)
    process.exit(0)
  }
  throw err
})

server.listen(PORT, '127.0.0.1', () => {
  console.log(`[digest] Refresh server ready at http://127.0.0.1:${PORT}`)

  // Also run a fresh generation on startup
  console.log('[digest] Running initial regeneration on startup…')
  spawn('/bin/bash', [SCRIPT], { stdio: 'inherit' })
})
