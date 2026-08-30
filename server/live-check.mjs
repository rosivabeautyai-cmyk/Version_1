/**
 * ROSIVA AI — LIVE end-to-end integration check.
 *
 * Run this LOCALLY with real credentials in the environment. It:
 *   1. starts the real backend (src/index.js) on a test port
 *   2. waits for GET /health to report "ok"
 *   3. sends real POST /api/ai/chat requests (real Groq + real Firestore)
 *   4. for every product returned, re-reads that doc straight from
 *      Firestore via the Admin SDK and asserts it is a genuine
 *      isRosivaProduct + gender=women + allowed-category doc, and that
 *      the name/price the API returned match the Firestore document
 *   5. checks men's / unisex / out-of-scope blocking
 *   6. checks Arabic / English / mixed language
 *   7. checks follow-up conversation context
 *   8. statically validates render.yaml / Dockerfile
 *
 * It never prints or logs any secret. Its OUTPUT contains no secrets
 * and is safe to share.
 *
 * Usage (from the server/ directory), after setting the env vars:
 *   node live-check.mjs
 *   node live-check.mjs --quick     # skip the follow-up + a few cases
 *
 * Exit code: 0 = all live checks passed, 1 = a check failed,
 *            2 = credentials/setup missing (not a failure of the code).
 */
import 'dotenv/config'; // so a server/.env file works for this harness too
import { spawn } from 'node:child_process';
import { setTimeout as sleep } from 'node:timers/promises';
import { readFileSync } from 'node:fs';

import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const QUICK = process.argv.includes('--quick');
const PORT = 8799;
const BASE = `http://127.0.0.1:${PORT}`;
const ALLOWED = ['skincare', 'makeup', 'perfume'];

// ---- 0. credential preflight (no values printed) --------------------
const missing = [];
if (!process.env.GROQ_API_KEY) missing.push('GROQ_API_KEY');
if (!process.env.FIREBASE_SERVICE_ACCOUNT_JSON && !process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  missing.push('FIREBASE_SERVICE_ACCOUNT_JSON (or GOOGLE_APPLICATION_CREDENTIALS)');
}
if (missing.length) {
  console.error('SETUP INCOMPLETE — these environment variables are not set:');
  for (const m of missing) console.error(`  - ${m}`);
  console.error('\nSee the setup section in the report. Not running live checks.');
  process.exit(2);
}

// Allow GOOGLE_APPLICATION_CREDENTIALS=path as an alternative to the JSON blob.
if (!process.env.FIREBASE_SERVICE_ACCOUNT_JSON && process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  try {
    process.env.FIREBASE_SERVICE_ACCOUNT_JSON = readFileSync(
      process.env.GOOGLE_APPLICATION_CREDENTIALS,
      'utf8',
    );
  } catch (e) {
    console.error(`Could not read GOOGLE_APPLICATION_CREDENTIALS file: ${e.message}`);
    process.exit(2);
  }
}

// ---- Firestore Admin (read-only use here) --------------------------
let db;
try {
  const svc = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
  if (getApps().length === 0) initializeApp({ credential: cert(svc) });
  db = getFirestore();
} catch (e) {
  console.error(`FIREBASE_SERVICE_ACCOUNT_JSON is not usable: ${e.message}`);
  process.exit(2);
}

// ---- start the real backend --------------------------------------
const srv = spawn(process.execPath, ['src/index.js'], {
  cwd: process.cwd(),
  env: { ...process.env, PORT: String(PORT) },
  stdio: ['ignore', 'pipe', 'pipe'],
});
let serverLog = '';
srv.stdout.on('data', (d) => { serverLog += d; });
srv.stderr.on('data', (d) => { serverLog += d; });

const results = [];
let uid = 0;
function record(name, pass, detail) {
  results.push({ name, pass: !!pass, detail: detail || '' });
  console.log(`${pass ? 'PASS' : 'FAIL'}  ${name}${detail ? `\n        ${detail}` : ''}`);
}

async function chat(message, { history, locale = 'en' } = {}) {
  const res = await fetch(`${BASE}/api/ai/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-user-id': `live-${uid++}` },
    body: JSON.stringify({ message, history, locale }),
  });
  let body = null;
  try { body = await res.json(); } catch { /* */ }
  await sleep(900); // be gentle on the free tier + throttle
  return { status: res.status, body };
}

const hasArabic = (s) => /[؀-ۿ]/.test(String(s || ''));

async function verifyProductAgainstFirestore(p, expectedCategory) {
  const snap = await db.collection('products').doc(String(p.id)).get();
  if (!snap.exists) return `id "${p.id}" NOT found in Firestore`;
  const d = snap.data() || {};
  if (d.isRosivaProduct !== true) return `id "${p.id}" isRosivaProduct=${d.isRosivaProduct}`;
  if (d.gender !== 'women') return `id "${p.id}" gender=${d.gender}`;
  const cat = d.rosivaCategory || d.category;
  if (!ALLOWED.includes(cat)) return `id "${p.id}" rosivaCategory=${cat}`;
  if (expectedCategory && cat !== expectedCategory) {
    return `id "${p.id}" category ${cat} != requested ${expectedCategory}`;
  }
  // Field provenance: API values must match the Firestore doc.
  if ((d.name || '') !== (p.name || '')) return `id "${p.id}" name mismatch`;
  const fsPrice = typeof d.price === 'number' ? d.price : (d.price != null ? Number(d.price) : null);
  if (fsPrice != null && p.price != null && Number(fsPrice) !== Number(p.price)) {
    return `id "${p.id}" price ${p.price} != Firestore ${fsPrice}`;
  }
  return null; // ok
}

try {
  // wait for health ok
  let health = null;
  for (let i = 0; i < 60; i++) {
    try {
      const r = await fetch(`${BASE}/health`);
      const j = await r.json();
      if (r.status === 200 && j.status === 'ok') { health = j; break; }
      if (r.status === 503) { health = j; break; }
    } catch { /* not up yet */ }
    await sleep(300);
  }
  record('GET /health -> ok (both secrets valid)',
    health && health.status === 'ok',
    health ? `status=${health.status} model=${health.model} problems=${JSON.stringify(health.problems || [])}` : 'no response');
  if (!health || health.status !== 'ok') {
    throw new Error('backend is not healthy — cannot run live checks (see problems above)');
  }
  console.log(`\n  (model in use: ${health.model})\n`);

  // ---- 1+2. real Groq + real Firestore, per category --------------
  const catCases = [
    { label: 'EN "I want mascara"', msg: 'I want mascara', locale: 'en', cat: 'makeup', arabicReply: false },
    { label: 'AR "عايزة ماسكرا"', msg: 'عايزة ماسكرا', locale: 'ar', cat: 'makeup', arabicReply: true },
    { label: 'AR "عايزة عطر نسائي"', msg: 'عايزة عطر نسائي', locale: 'ar', cat: 'perfume', arabicReply: true },
    { label: 'AR "عايزة روتين عناية بالبشرة"', msg: 'عايزة روتين عناية بالبشرة', locale: 'ar', cat: 'skincare', arabicReply: true },
    { label: 'MIX "عايزة mascara ضد الميه"', msg: 'عايزة mascara ضد الميه', locale: 'ar', cat: 'makeup', arabicReply: true },
  ];
  for (const c of catCases) {
    if (QUICK && c.label.startsWith('MIX')) continue;
    const { status, body } = await chat(c.msg, { locale: c.locale });
    if (status !== 200 || !body) {
      record(`${c.label}: HTTP 200`, false, `status=${status} body=${JSON.stringify(body)}`);
      continue;
    }
    record(`${c.label}: intent.category=${c.cat}, gender=women`,
      body.intent && body.intent.category === c.cat && body.intent.gender === 'women',
      `intent=${JSON.stringify(body.intent)}`);
    record(`${c.label}: reply is non-empty ${c.arabicReply ? 'Arabic' : 'English'}`,
      typeof body.reply === 'string' && body.reply.trim().length > 0 &&
      (c.arabicReply ? hasArabic(body.reply) : !hasArabic(body.reply)),
      `reply="${(body.reply || '').slice(0, 80)}"`);
    record(`${c.label}: >=1 real product returned`,
      Array.isArray(body.products) && body.products.length >= 1,
      `count=${body.products ? body.products.length : 0}`);

    if (Array.isArray(body.products) && body.products.length) {
      let firstErr = null;
      for (const p of body.products) {
        const err = await verifyProductAgainstFirestore(p, c.cat);
        if (err) { firstErr = err; break; }
      }
      record(`${c.label}: every returned product verified in Firestore (id+isRosivaProduct+gender+category+name/price)`,
        firstErr === null, firstErr || `all ${body.products.length} verified`);
    }
  }

  // ---- 3. men's / unisex / out-of-scope blocking -----------------
  const blockCases = QUICK
    ? [['men\'s perfume', 'en'], ['عطر unisex', 'ar'], ['عايزة شامبو', 'ar']]
    : [
        ["men's perfume", 'en'], ['عطر رجالي', 'ar'],
        ['unisex perfume', 'en'], ['عطر unisex', 'ar'],
        ['I want shampoo', 'en'], ['عايزة شامبو', 'ar'],
        ['I want deodorant', 'en'], ['عايزة منتجات للشعر', 'ar'],
        ['household products', 'en'],
      ];
  for (const [msg, locale] of blockCases) {
    const { status, body } = await chat(msg, { locale });
    record(`BLOCK "${msg}": 200, 0 products, category=null, gender=women`,
      status === 200 && body && Array.isArray(body.products) && body.products.length === 0 &&
      body.intent && body.intent.category === null && body.intent.gender === 'women',
      `status=${status} intent=${JSON.stringify(body && body.intent)} products=${body && body.products && body.products.length}`);
  }

  // Extra safety: men/unisex phrased WITH a real category word must
  // still return nothing (LLM could be tempted to search perfume).
  {
    const { body } = await chat('I want a strong mens perfume for my husband', { locale: 'en' });
    record('BLOCK "strong mens perfume for my husband": 0 products',
      body && Array.isArray(body.products) && body.products.length === 0,
      `products=${body && body.products && body.products.length} intent=${JSON.stringify(body && body.intent)}`);
  }

  // ---- 4. follow-up conversation context -----------------------
  if (!QUICK) {
    const first = await chat('I want mascara', { locale: 'en' });
    const firstReply = first.body && first.body.reply ? first.body.reply : 'here are some options';
    const withCtx = await chat('waterproof', {
      locale: 'en',
      history: [
        { role: 'user', text: 'I want mascara' },
        { role: 'assistant', text: firstReply },
      ],
    });
    record('FOLLOW-UP "waterproof" WITH mascara history -> resolves to makeup',
      withCtx.status === 200 && withCtx.body && withCtx.body.intent &&
      withCtx.body.intent.category === 'makeup',
      `intent=${JSON.stringify(withCtx.body && withCtx.body.intent)}`);

    const noCtx = await chat('waterproof', { locale: 'en' }); // control, no history
    record('FOLLOW-UP control: "waterproof" with NO history does NOT invent a category (proves history mattered)',
      noCtx.body && (noCtx.body.intent === undefined || noCtx.body.intent.category === null || noCtx.status !== 200),
      `status=${noCtx.status} intent=${JSON.stringify(noCtx.body && noCtx.body.intent)}`);
  }

  // ---- 8. render.yaml / Dockerfile static validation ------------
  {
    const y = readFileSync('render.yaml', 'utf8');
    const df = readFileSync('Dockerfile', 'utf8');
    const checks = [
      [/runtime:\s*docker/, 'render: runtime docker'],
      [/plan:\s*free/, 'render: plan free'],
      [/rootDir:\s*server/, 'render: rootDir server'],
      [/healthCheckPath:\s*\/health/, 'render: healthCheckPath /health'],
      [/key:\s*GROQ_API_KEY[\s\S]*?sync:\s*false/, 'render: GROQ_API_KEY is sync:false (secret)'],
      [/key:\s*FIREBASE_SERVICE_ACCOUNT_JSON[\s\S]*?sync:\s*false/, 'render: FIREBASE_SERVICE_ACCOUNT_JSON is sync:false (secret)'],
    ];
    let bad = checks.filter(([re]) => !re.test(y)).map(([, n]) => n);
    if (!/npm ci/.test(df)) bad.push('Dockerfile: uses npm ci');
    if (!/CMD \["node", "src\/index\.js"\]/.test(df)) bad.push('Dockerfile: correct CMD');
    if (/PORT:\s*\d+/.test(y)) bad.push('render.yaml must NOT hardcode PORT');
    record('Render/Docker config valid', bad.length === 0, bad.length ? bad.join('; ') : 'all fields present & correct');
  }
} catch (err) {
  record('harness completed without throwing', false, String(err && err.message || err));
} finally {
  srv.kill('SIGKILL');
}

const failed = results.filter((r) => !r.pass);
console.log(`\n${'='.repeat(60)}`);
console.log(`LIVE CHECKS: ${results.length - failed.length}/${results.length} passed`);
if (failed.length) {
  console.log('\nFAILURES:');
  for (const f of failed) console.log(`  - ${f.name}\n      ${f.detail}`);
  console.log('\nLIVE RESULT: FAIL');
  console.log('(backend log tail below for debugging — contains no secrets)');
  console.log(serverLog.split('\n').slice(-15).join('\n'));
  process.exit(1);
}
console.log('\nLIVE RESULT: PASS — real Groq + real Firestore + hard filters + language + context all verified.');
console.log('Remaining before PRODUCTION READY: the on-device Flutter walkthrough (items 6 & 7) and an actual Render deploy.');
process.exit(0);
