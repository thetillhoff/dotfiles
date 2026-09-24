#!/usr/bin/env node
// Measured accessibility + responsive gate. Every page x colour scheme x width.
// Deps: npm i -D playwright axe-core && npx playwright install chromium
//
// node verify.mjs --urls http://localhost:8080/,http://localhost:8080/pricing/
// node verify.mjs --urls 'dist/**/*.html' --widths 375,1280 --schemes light,dark

import { createRequire } from 'node:module';
import { writeFileSync, globSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { pathToFileURL } from 'node:url';

// This script lives outside the repo it checks, so bare specifiers must be
// resolved against the caller's node_modules first - otherwise a repo that
// already has playwright installed is invisible to it.
const fromCwd = createRequire(join(process.cwd(), 'noop.js'));
const fromHere = createRequire(import.meta.url);
const find = (spec) => {
  for (const r of [fromCwd, fromHere]) {
    try { return r.resolve(spec); } catch { /* try the next root */ }
  }
  console.error(`Cannot find ${spec}. Run: npm i -D playwright axe-core && npx playwright install chromium`);
  process.exit(2);
};
const pw = await import(pathToFileURL(find('playwright')).href);
const chromium = pw.chromium ?? pw.default?.chromium; // CJS entry lands under .default
const AXE_PATH = find('axe-core/axe.min.js');

const DEFAULT_WIDTHS = [320, 360, 375, 414, 600, 768, 834, 1024, 1280, 1440, 1920, 2560];
const AXE_TAGS = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa', 'best-practice'];

const arg = (name, fallback) => {
  const i = process.argv.indexOf(`--${name}`);
  return i === -1 ? fallback : process.argv[i + 1];
};
const list = (v) => String(v).split(',').map((s) => s.trim()).filter(Boolean);

const rawUrls = list(arg('urls', ''));
if (!rawUrls.length) {
  console.error('--urls is required (comma-separated URLs, file paths, or globs)');
  process.exit(2);
}
const urls = rawUrls.flatMap((u) => {
  if (/^https?:|^file:/.test(u)) return [u];
  const matches = u.includes('*') ? globSync(u) : [u];
  return matches.map((p) => 'file://' + resolve(p));
});

const widths = arg('widths') ? list(arg('widths')).map(Number) : DEFAULT_WIDTHS;
const schemes = list(arg('schemes', 'light,dark'));
const themeAttr = arg('theme-attr'); // e.g. data-theme, set to the scheme name on <html>
const maxCh = Number(arg('max-ch', 78));
const outPath = arg('out', 'frontend-verify.json');

// Runs in the page. Everything a static read of the CSS cannot tell you:
// what the browser actually laid out at this width.
function probe(maxCh) {
  const vw = window.innerWidth;
  const sel = (el) => {
    const id = el.id ? `#${el.id}` : '';
    const cls = typeof el.className === 'string' && el.className.trim()
      ? '.' + el.className.trim().split(/\s+/).slice(0, 2).join('.')
      : '';
    return `${el.tagName.toLowerCase()}${id}${cls}`;
  };
  const visible = (el) => {
    const s = getComputedStyle(el);
    return s.visibility !== 'hidden' && s.display !== 'none' && el.getClientRects().length > 0;
  };

  const overflowing = [];
  for (const el of document.body.querySelectorAll('*')) {
    if (!visible(el)) continue;
    const r = el.getBoundingClientRect();
    if (r.width === 0 || r.height === 0) continue;
    if (r.right > vw + 1 || r.left < -1) {
      overflowing.push({ el: sel(el), left: Math.round(r.left), right: Math.round(r.right) });
    }
    if (overflowing.length >= 10) break;
  }

  // A clickable label that wraps reads as two separate links. Inline links in
  // running prose are the legitimate exception, so only chrome is checked.
  const wrapped = [];
  for (const el of document.querySelectorAll('header a, nav a, footer a, [role="navigation"] a, button, .btn, [role="button"]')) {
    if (!visible(el)) continue;
    const range = document.createRange();
    range.selectNodeContents(el);
    const tops = new Set([...range.getClientRects()].map((r) => Math.round(r.top)));
    if (tops.size > 1) wrapped.push({ el: sel(el), text: el.textContent.trim().slice(0, 40), lines: tops.size });
  }

  // Measure of the actual font, not an assumed 8px-per-char.
  const canvas = document.createElement('canvas');
  const ctx = canvas.getContext('2d');
  const longLines = [];
  for (const el of document.querySelectorAll('main p, article p, main li, article li')) {
    if (!visible(el)) continue;
    const s = getComputedStyle(el);
    // A grid/flex item is a layout box, not a line of text - it can span a
    // whole multi-column row (a number column beside a prose column) with no
    // reading-measure problem at all. Only flow-layout boxes are actual text
    // lines worth measuring in characters.
    if (s.display === 'grid' || s.display === 'flex') continue;
    ctx.font = `${s.fontStyle} ${s.fontWeight} ${s.fontSize} ${s.fontFamily}`;
    const zero = ctx.measureText('0').width || 8;
    const inner = el.getBoundingClientRect().width
      - parseFloat(s.paddingLeft) - parseFloat(s.paddingRight);
    const ch = Math.round(inner / zero);
    if (ch > maxCh && el.textContent.trim().length > 120) {
      longLines.push({ el: sel(el), ch });
    }
  }

  return {
    horizontalScroll: document.documentElement.scrollWidth > vw + 1,
    scrollWidth: document.documentElement.scrollWidth,
    overflowing,
    wrapped,
    longLines: longLines.slice(0, 10),
  };
}

// Tab order is a sequence, so it is recorded rather than asserted - a human
// reads it. The one hard check: a skip link that does not move focus is worse
// than no skip link, because it silently swallows the keystroke.
async function keyboardPath(page) {
  const stops = [];
  for (let i = 0; i < 15; i++) {
    await page.keyboard.press('Tab');
    const stop = await page.evaluate(() => {
      const el = document.activeElement;
      if (!el || el === document.body) return null;
      const s = getComputedStyle(el);
      return {
        tag: el.tagName.toLowerCase(),
        text: (el.textContent || el.value || '').trim().slice(0, 30),
        outline: s.outlineStyle === 'none' ? s.boxShadow : `${s.outlineWidth} ${s.outlineColor}`,
        inViewport: el.getBoundingClientRect().top >= 0,
      };
    });
    if (!stop) break;
    stops.push(stop);
  }
  const skip = await page.$('a[href^="#"]:has-text("Skip"), a.skip-link');
  let skipLandsFocus = null;
  if (skip) {
    // A page with more than 15 focusable elements never hits the `!stop`
    // break above, so the tab cursor is left mid-page; `body.focus()` is a
    // no-op on a plain <body> with no tabindex, so the follow-up Tab+Enter
    // used to fire on whatever real link was last focused, navigating away
    // and destroying the execution context. Reload for a guaranteed-clean
    // first-Tab state instead of trying to rewind focus by hand.
    await page.reload({ waitUntil: 'load' });
    await page.keyboard.press('Tab');
    await page.keyboard.press('Enter');
    skipLandsFocus = await page.evaluate(() => {
      const el = document.activeElement;
      return el ? `${el.tagName.toLowerCase()}#${el.id}` : 'BODY';
    });
  }
  return { stops, skipLandsFocus, noFocusRing: stops.filter((s) => !s.outline || s.outline === 'none').length };
}

const browser = await chromium.launch();
const report = { widths, schemes, urls, pages: [], failures: [] };
const fail = (msg) => report.failures.push(msg);

for (const scheme of schemes) {
  const context = await browser.newContext({ colorScheme: scheme, reducedMotion: 'reduce' });
  for (const url of urls) {
    const page = await context.newPage();
    const consoleErrors = [];
    page.on('pageerror', (e) => consoleErrors.push(String(e)));
    await page.goto(url, { waitUntil: 'load' });
    if (themeAttr) await page.evaluate(([a, v]) => document.documentElement.setAttribute(a, v), [themeAttr, scheme]);
    await page.addScriptTag({ path: AXE_PATH });

    for (const width of widths) {
      await page.setViewportSize({ width, height: 900 });
      await page.waitForTimeout(120); // let media queries and any resize handler settle

      const axeRes = await page.evaluate(
        (tags) => axe.run(document, { runOnly: { type: 'tag', values: tags }, resultTypes: ['violations'] }),
        AXE_TAGS,
      );
      const violations = axeRes.violations.map((v) => ({
        id: v.id, impact: v.impact, help: v.help,
        nodes: v.nodes.slice(0, 3).map((n) => ({ target: n.target.join(' '), summary: n.failureSummary })),
      }));
      const layout = await page.evaluate(probe, maxCh);

      report.pages.push({ url, scheme, width, violations, ...layout });
      const where = `${url} [${scheme}, ${width}px]`;
      for (const v of violations) fail(`a11y ${v.id} (${v.impact}) - ${where}`);
      if (layout.horizontalScroll) fail(`horizontal scroll (${layout.scrollWidth}px) - ${where}`);
      for (const o of layout.overflowing) fail(`${o.el} past viewport (right ${o.right}) - ${where}`);
      for (const w of layout.wrapped) fail(`"${w.text}" wraps to ${w.lines} lines - ${where}`);
      for (const l of layout.longLines) fail(`${l.el} is ${l.ch}ch (max ${maxCh}) - ${where}`);
    }

    if (scheme === schemes[0]) {
      await page.setViewportSize({ width: 1280, height: 900 });
      report.pages.at(-1).keyboard = await keyboardPath(page);
    }
    for (const e of consoleErrors) fail(`page error - ${url}: ${e}`);
    await page.close();
  }
  await context.close();
}
await browser.close();

writeFileSync(outPath, JSON.stringify(report, null, 2));
const combos = urls.length * schemes.length * widths.length;
console.log(`${combos} page/scheme/width combinations checked, ${report.failures.length} failures`);
for (const f of report.failures.slice(0, 60)) console.log('  ' + f);
if (report.failures.length > 60) console.log(`  ... ${report.failures.length - 60} more, see ${outPath}`);
process.exit(report.failures.length ? 1 : 0);
