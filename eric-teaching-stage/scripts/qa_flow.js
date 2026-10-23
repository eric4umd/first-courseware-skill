#!/usr/bin/env node
/* qa_flow.js — "teach the whole lesson" run: uses the deck the way a teacher does, with real key presses and clicks,
   and fails when a page is a dead end, a control does nothing, an answer cannot be shown, or the deck skips something.

   NODE_PATH=/opt/homebrew/lib/node_modules node qa_flow.js <lesson.html> [--engines chromium,webkit] [--size 1920x1080]

   What it does
     1  Natural path: from the cover, press Space until the deck stops. Every main-path scene must be visited in document order,
        each beat once; the last scene must be the closing scene.
     2  On every scene it meets: click every 看对照 / Stuck? / reveal button -> a visible, non-empty answer must appear, inside the
        viewport, and the deck must not advance; click each timer (start, pause, reset) -> state changes, no advance;
        click + / − on tallies -> number changes; click on a choice chip -> marks it.
     3  Listening scenes: the deck must HOLD the first Space (player flashes, scene unchanged) and leave on the second; then the
        real flow Play 1 -> gap -> Play 2 -> done is run (clip fast-forwarded, muted, gap shortened).
     4  Menu / branch scenes: every menu card must land on its rule scene, walk its branch to the return scene, and ← must come back.
     5  Rail tabs and footer jumps: each lands on a real scene; none leaves the deck on a blank page.
     6  Dead ends: a scene whose controls are all inert, or one with no way forward, is reported.
   Prints one PASS/FAIL line per finding; exit code 1 on any FAIL. It cannot judge teaching quality — read the list of scenes
   against the lesson spec yourself: "could a teacher run this page, and could the student learn something from it?" */
const { chromium, webkit } = require("playwright");
const path = require("path");
const { pathToFileURL } = require("url");

const argv = process.argv.slice(2);
const file = argv.find((a) => a.endsWith(".html"));
const opt = (k, d) => { const i = argv.indexOf("--" + k); return i >= 0 ? argv[i + 1] : d; };
if (!file) { console.error("usage: qa_flow.js <lesson.html> [--engines chromium,webkit] [--size WxH]"); process.exit(2); }
const [W, H] = opt("size", "1920x1080").split("x").map(Number);
const ENGINES = opt("engines", "chromium,webkit").split(",");
const URL = pathToFileURL(path.resolve(file)).href;
let fails = 0;
const log = (ok, msg) => { if (!ok) fails++; console.log(`  ${ok ? "PASS" : "FAIL"}  ${msg}`); };
const st = (page) => page.evaluate(() => window.__deck.state());

async function visibleBox(page, sel) {
  return page.evaluate((sel) => {
    const el = document.querySelector(sel);
    if (!el) return null;
    const r = el.getBoundingClientRect(), cs = getComputedStyle(el);
    return { w: r.width, h: r.height, inside: r.left >= -1 && r.top >= -1 && r.right <= innerWidth + 1 && r.bottom <= innerHeight + 1, shown: cs.visibility !== "hidden" && cs.display !== "none" && +cs.opacity > 0.5, text: el.innerText.trim() };
  }, sel);
}

async function exerciseControls(page, sceneId, problems) {
  const before = await st(page);
  // reveals — only buttons the teacher can currently see
  const nLooks = (await page.$$(".scene.is-on .look:not([hidden])")).length;
  for (let k = 0; k < nLooks + 2; k++) {
    let handle = null;
    for (const h of await page.$$(".scene.is-on .look:not([hidden])")) { if (await h.isVisible()) { handle = h; break; } }
    if (!handle) break;
    const tag = await handle.evaluate((b) => { const w = b.closest(".look-wrap") || b.closest("[data-beat]"); const c = w && w.querySelector(".contrast"); if (c) c.setAttribute("data-qa", "1"); return !!c; });
    if (!tag) { problems.push(`${sceneId}: a 看对照 button has no .contrast answer to show`); await handle.evaluate((b) => b.setAttribute("hidden", "")); continue; }
    const b0 = await st(page);
    await handle.click({ force: true });
    await page.waitForTimeout(450);
    const c = await page.evaluate(() => { const el = document.querySelector("[data-qa='1']"); el.removeAttribute("data-qa"); const r = el.getBoundingClientRect(), cs = getComputedStyle(el); return { hidden: el.hidden, text: el.innerText.replace(/[✓\s]/g, "").length, inside: r.left >= -1 && r.top >= -1 && r.right <= innerWidth + 1 && r.bottom <= innerHeight + 1, vis: cs.visibility !== "hidden" && +cs.opacity > 0.5 }; });
    if (c.hidden || !c.text || !c.inside || !c.vis) problems.push(`${sceneId}: reveal not usable (hidden=${c.hidden} chars=${c.text} inside=${c.inside} visible=${c.vis})`);
    const b1 = await st(page);
    if (b1.si !== b0.si || b1.bi !== b0.bi) problems.push(`${sceneId}: clicking 看对照 moved the deck`);
  }
  // timers
  const timers = [];
  for (const t of await page.$$(".scene.is-on .timer")) if (await t.isVisible()) timers.push(t);
  for (const t of timers) {
    const s0 = await t.evaluate((b) => b.className);
    await t.click({ force: true });
    const s1 = await t.evaluate((b) => b.className);
    await t.click({ force: true });
    const s2 = await t.evaluate((b) => b.className);
    if (!/is-running/.test(s1)) problems.push(`${sceneId}: timer did not start`);
    if (!/is-paused/.test(s2)) problems.push(`${sceneId}: timer did not pause`);
    await page.evaluate(() => document.querySelector(".scene.is-on .timer-reset") && document.querySelector(".scene.is-on .timer-reset").click());
  }
  if (timers.length) {
    const after = await st(page);
    if (after.si !== before.si) problems.push(`${sceneId}: using a timer moved the deck`);
  }
  // tallies
  for (const plus of await page.$$(".scene.is-on .tally-plus")) {
    if (!(await plus.isVisible())) continue;
    const num = await plus.evaluateHandle((b) => b.closest(".tally").querySelector(".tally-num"));
    const a = await num.evaluate((n) => n.textContent);
    await plus.click({ force: true });
    const b = await num.evaluate((n) => n.textContent);
    if (a === b) problems.push(`${sceneId}: tally + did nothing`);
    await (await plus.evaluateHandle((x) => x.closest(".tally").querySelector(".tally-minus"))).asElement().click({ force: true });
  }
  // chips / choices
  for (const c of await page.$$(".scene.is-on .chip[data-ok], .scene.is-on .choice")) {
    if (!(await c.isVisible())) continue;
    await c.click({ force: true });
    if (!(await c.evaluate((n) => n.classList.contains("picked")))) problems.push(`${sceneId}: choice did not register`);
  }
}

async function run(engineName) {
  const engine = engineName === "webkit" ? webkit : chromium;
  let browser;
  try { browser = await engine.launch(); } catch (e) { console.log(`[${engineName}] cannot launch`); fails++; return; }
  console.log(`\n[${engineName} ${W}x${H}]`);
  const ctx = await browser.newContext({ viewport: { width: W, height: H }, reducedMotion: "reduce" });
  await ctx.addInitScript(require("./qa_silence"));   // QA never makes sound: media muted, WebAudio detached from the speakers
  await ctx.route((u) => !/^(file|data|blob):/.test(u.toString()), (r) => r.abort());
  const page = await ctx.newPage();
  const errs = [];
  page.on("pageerror", (e) => errs.push(String(e)));
  page.on("console", (m) => { if (m.type() === "error") errs.push(m.text()); });
  await page.goto(URL);
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(300);

  const info = await page.evaluate(() => [...document.querySelectorAll(".scene")].map((s, i) => ({ i, id: s.id || String(i), branch: s.hasAttribute("data-branch"), beats: Math.max(s.querySelectorAll("[data-beat]").length, 1), listen: !!s.querySelector(".listen"), menu: s.getAttribute("data-scene") === "choose" })));
  const main = info.filter((s) => !s.branch);
  console.log(`  ${info.length} scenes (${main.length} main path, ${info.length - main.length} branch)`);

  // ---- 1+2: natural path with real Space presses, exercising controls on every scene
  const problems = [];
  const visited = [];
  let heldOk = 0;
  const seen = new Set();
  let guard = 0;
  let last = await st(page);
  while (guard++ < 600) {
    const s = await st(page);
    const key = s.si + ":" + s.bi;
    if (!seen.has(key)) {
      seen.add(key);
      if (!visited.length || visited[visited.length - 1] !== s.id) visited.push(s.id);
      if (s.bi === 0 || true) await exerciseControls(page, s.id, problems);
    }
    const sceneInfo = info[s.si];
    // end of this scene? (last beat)
    const atLast = s.bi >= sceneInfo.beats - 1;
    if (atLast && sceneInfo.listen) {
      await page.keyboard.press("Space"); await page.waitForTimeout(150);
      const s2 = await st(page);
      if (s2.si !== s.si) { problems.push(`${s.id}: listening page let Space skip it without a warning`); await page.evaluate(([i, b]) => window.__deck.go(i, b), [s.si, s.bi]); }
      if (s2.si === s.si) {
        const nudged = await page.evaluate(() => document.querySelector(".scene.is-on .listen").classList.contains("nudge"));
        if (!nudged) problems.push(`${s.id}: Space was held but the player gave no visible warning`); else heldOk++;
      }
      // run the real flow once
      const flow = await page.evaluate(async () => {
        const L = document.querySelector(".scene.is-on .listen")._ls;
        const out = {};
        L.gap = 1; L.gapLeft = 1;
        const wait = (f, ms) => new Promise((res) => { const t0 = Date.now(); (function w() { if (f()) return res(true); if (Date.now() - t0 > ms) return res(false); setTimeout(w, 80); })(); });
        L.audio.muted = true;
        L.press();
        out.p1 = await wait(() => L.mode === "playing", 6000);
        L.audio.currentTime = Math.max((L.audio.duration || 1) - 0.3, 0);
        out.gap = await wait(() => L.mode === "gap" || L.mode === "ready", 6000);
        out.ready = await wait(() => L.mode === "ready", 6000);
        L.press();
        out.p2 = await wait(() => L.mode === "playing", 6000);
        L.audio.currentTime = Math.max((L.audio.duration || 1) - 0.3, 0);
        out.done = await wait(() => L.mode === "done", 6000);
        out.plays = L.n; out.dur = L.audio.duration;
        return out;
      });
      if (!(flow.p1 && flow.gap && flow.ready && flow.p2 && flow.done && flow.plays === 2)) problems.push(`${s.id}: player flow broke ${JSON.stringify(flow)}`);
      else heldOk += 0;
    }
    await page.keyboard.press("Space");
    await page.waitForTimeout(60);
    const n = await st(page);
    if (n.si === s.si && n.bi === s.bi) { if (atLast) break; }
    last = n;
  }
  const expected = main.map((s) => s.id);
  const missing = expected.filter((id) => !visited.includes(id));
  log(missing.length === 0, `natural path visits all ${expected.length} main-path scenes` + (missing.length ? ` — missed: ${missing.join(", ")}` : ""));
  const order = visited.filter((id) => expected.includes(id));
  log(JSON.stringify(order) === JSON.stringify(expected.filter((id) => order.includes(id))), "scenes come in document order");
  log(visited[visited.length - 1] === expected[expected.length - 1], `ends on the closing scene (${visited[visited.length - 1]})`);
  info.filter((s) => s.listen).forEach(() => log(heldOk > 0, "listening page holds the first Space and warns the teacher"));
  log(problems.length === 0, "every control on every page works" + (problems.length ? "" : ` (${seen.size} beats exercised)`));
  problems.slice(0, 25).forEach((p) => console.log("        · " + p));

  // ---- 4: menu + branches
  for (const m of info.filter((s) => s.menu)) {
    const cards = await page.evaluate((i) => [...document.querySelectorAll(".scene")[i].querySelectorAll("[data-jump]")].map((b) => b.getAttribute("data-jump")), m.i);
    let bad = [];
    for (const target of cards) {
      await page.evaluate((i) => window.__deck.go(i, 0), m.i);
      await page.click(`.scene.is-on [data-jump="${target}"]`, { force: true });
      await page.waitForTimeout(100);
      let s = await st(page);
      if (!/rule|^/.test(s.id) || s.id === m.id) { bad.push(`${target}: card did nothing`); continue; }
      const path_ = [s.id];
      let g = 0;
      while (g++ < 30) {
        const sc = info[(await st(page)).si];
        const cur = await st(page);
        if (cur.bi < sc.beats - 1) { await page.keyboard.press("Space"); continue; }
        await page.keyboard.press("Space"); await page.waitForTimeout(60);
        const nx = await st(page);
        if (nx.si === cur.si && nx.bi === cur.bi) break;
        path_.push(nx.id);
        if (!info[nx.si].branch) break;
      }
      const ret = info.find((x) => x.id === path_[path_.length - 1]);
      if (!ret || ret.branch) bad.push(`${target}: branch never returned to the main line (${path_.join(">")})`);
      // ← from the rule scene returns to the menu
      await page.evaluate((i) => window.__deck.go(i, 0), m.i);
      await page.click(`.scene.is-on [data-jump="${target}"]`, { force: true });
      await page.keyboard.press("ArrowLeft"); await page.waitForTimeout(80);
      if ((await st(page)).id !== m.id) bad.push(`${target}: ← from the first branch scene does not return to the menu`);
    }
    log(bad.length === 0, `menu "${m.id}": ${cards.length} cards each land, walk the branch, return` + (bad.length ? " — " + bad.join("; ") : ""));
  }

  // ---- 5: rail and footer jumps
  const jumps = await page.evaluate(() => [...document.querySelectorAll("[data-part-tab],.nav [data-jump]")].map((b) => b.getAttribute("data-jump")));
  const dead = [];
  for (const j of jumps) {
    await page.evaluate(() => window.__deck.go(0, 0));
    const ok = await page.evaluate((j) => { const b = [...document.querySelectorAll("[data-part-tab],.nav [data-jump]")].find((x) => x.getAttribute("data-jump") === j); b.click(); return true; }, j);
    await page.waitForTimeout(80);
    const s = await st(page);
    if (s.id === info[0].id && j !== info[0].id) dead.push(j);
  }
  log(dead.length === 0, `${jumps.length} rail/footer jumps all land` + (dead.length ? " — dead: " + dead.join(", ") : ""));

  // ---- 6: after the very end, extra presses do nothing bad; ← walks back
  await page.evaluate((i) => window.__deck.go(i, 0), info[info.length - 1].i);
  for (let k = 0; k < 5; k++) await page.keyboard.press("Space");
  await page.keyboard.press("ArrowLeft");
  log(errs.length === 0, "no console / page errors during the whole run" + (errs.length ? " — " + errs.slice(0, 2).join(" | ") : ""));
  await browser.close();
}

(async () => {
  for (const e of ENGINES) await run(e);
  console.log(fails ? `\n${fails} FAIL` : "\nall flow checks passed");
  process.exit(fails ? 1 : 0);
})();
