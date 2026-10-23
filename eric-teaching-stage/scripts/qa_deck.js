#!/usr/bin/env node
/* qa_deck.js — acceptance run for a classroom deck, in Chromium AND WebKit (Safari's engine).

   NODE_PATH=/opt/homebrew/lib/node_modules node qa_deck.js <lesson.html> [--out dir] [--script listening.txt]
                                                                      [--sizes 1920x1080,1280x720] [--engines chromium,webkit]
   WebKit is installed once with:  node /opt/homebrew/lib/node_modules/playwright/cli.js install webkit

   Checks (each prints PASS / FAIL with detail; nothing here can judge taste or hear audio):
     • loads over file:// with the network off, no console / page errors, no non-file requests
     • every scene at its last beat: nothing scrolls, nothing sits outside the deck, no clipped boxes (> 6 px)
     • Space / → / empty click advance one beat; ← goes back; repeated Space during a tween never skips a scene
     • sound: M toggles StageAudio.enabled; beat / scene / reveal / timer cues fire on the right actions
     • listening player: Play 1 → gap → Play 2 → done (gap shortened for the test only); leaving the scene resets it;
       silent by default (no listenStart / gapDone / done cue), and data-chime="1" brings listenStart back
     • no transcript leak: with --script, no run of 6 consecutive script words appears in any scene's visible text
   The run is silent by construction (qa_silence.js): media forced muted, WebAudio output dropped; sound checks read the cue log.
   Screenshots (all scenes, last beat) go to --out. Look at them: a pass here is not a design review. */
const { chromium, webkit } = require("playwright");
const fs = require("fs");
const path = require("path");
const { pathToFileURL } = require("url");

const argv = process.argv.slice(2);
const file = argv.find((a) => !a.startsWith("--") && a.endsWith(".html"));
const opt = (k, d) => { const i = argv.indexOf("--" + k); return i >= 0 ? argv[i + 1] : d; };
if (!file) { console.error("usage: qa_deck.js <lesson.html> [--out dir] [--script listening.txt] [--sizes WxH,..] [--engines chromium,webkit]"); process.exit(2); }
const OUT = opt("out", path.join(path.dirname(file), "qa"));
const SIZES = opt("sizes", "1920x1080,1280x720").split(",").map((s) => s.split("x").map(Number));
const ENGINES = opt("engines", "chromium,webkit").split(",");
const SCRIPT = opt("script", null);
const URL = pathToFileURL(path.resolve(file)).href;
fs.mkdirSync(OUT, { recursive: true });

let fails = 0;
const say = (ok, name, detail) => { if (!ok) fails++; console.log(`  ${ok ? "PASS" : "FAIL"}  ${name}${detail ? " — " + detail : ""}`); };

function scriptRuns() {
  if (!SCRIPT) return [];
  const words = fs.readFileSync(SCRIPT, "utf8").split("\n").filter((l) => l.trim() && !l.startsWith("#") && !/^\(pause/i.test(l.trim()))
    .map((l) => l.replace(/^\[[^\]]+\]\s*/, "").replace(/\{[^}]*\}/g, "")).join(" ")
    .toLowerCase().replace(/[^a-z0-9' ]+/g, " ").split(/\s+/).filter(Boolean);
  const runs = [];
  for (let i = 0; i + 6 <= words.length; i++) runs.push(words.slice(i, i + 6).join(" "));
  return runs;
}

async function layoutIssues(page) {
  return page.evaluate(() => {
    const scene = document.querySelector(".scene.is-on");
    const deck = document.querySelector(".deck").getBoundingClientRect();
    const out = [];
    if (scene.scrollHeight > scene.clientHeight + 1) out.push("scene scrolls");
    if (document.documentElement.scrollHeight > window.innerHeight + 1) out.push("page scrolls");
    scene.querySelectorAll("*").forEach((el) => {
      if (el.closest("svg") || el.closest("[hidden]")) return;
      const cs = getComputedStyle(el);
      if (cs.visibility === "hidden" || cs.display === "none" || cs.display === "inline") return;
      const r = el.getBoundingClientRect();
      if (!r.width && !r.height) return;
      const name = el.tagName.toLowerCase() + "." + String(el.className && el.className.baseVal === undefined ? el.className : "").trim().split(/\s+/).join(".");
      if (r.bottom > deck.bottom + 2 || r.right > deck.right + 2 || r.left < deck.left - 2 || r.top < deck.top - 2) out.push("outside " + name);
      if (el.clientHeight > 0 && cs.overflow !== "visible" && (el.scrollHeight > el.clientHeight + 6 || el.scrollWidth > el.clientWidth + 6)) out.push("clipped " + name);  // overflow:visible spill is caught by the "outside" test
      // text floor: shared-screen readability. Side rail and footer sit outside .scene and are exempt.
      const own = [...el.childNodes].some((c) => c.nodeType === 3 && c.textContent.trim());
      if (own && parseFloat(cs.fontSize) < 12.5 && window.innerWidth <= 1400) out.push("small-text " + parseFloat(cs.fontSize).toFixed(1) + "px " + name);
    });
    return out;
  });
}

async function run(engineName, [w, h]) {
  const engine = engineName === "webkit" ? webkit : chromium;
  let browser;
  try { browser = await engine.launch(); } catch (e) { console.log(`\n[${engineName}] cannot launch: ${String(e).split("\n")[0]}`); fails++; return; }
  console.log(`\n[${engineName} ${w}x${h}]`);
  const ctx = await browser.newContext({ viewport: { width: w, height: h } });
  await ctx.addInitScript(require("./qa_silence"));   // QA never makes sound: media muted, WebAudio detached from the speakers
  await ctx.route((u) => !/^(file|data|blob):/.test(u.toString()), (r) => r.abort());  // network off (WebKit rejects offline:true on file://)
  const page = await ctx.newPage();
  const errs = [], reqs = [];
  page.on("pageerror", (e) => errs.push(String(e)));
  page.on("console", (m) => { if (m.type() === "error") errs.push(m.text()); });
  page.on("request", (r) => reqs.push(r.url()));
  await page.goto(URL);
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(300);

  const n = await page.evaluate(() => document.querySelectorAll(".scene").length);
  say(n > 0, "scenes found", String(n));
  say(errs.length === 0, "no console/page errors", errs.slice(0, 3).join(" | "));
  say(reqs.every((u) => u.startsWith("file://") || u.startsWith("data:")), "offline: only file:// requests", reqs.filter((u) => !u.startsWith("file://") && !u.startsWith("data:")).slice(0, 3).join(" "));

  // ---- layout + screenshots, every scene at its last beat
  const bad = [];
  const runs = scriptRuns();
  let leaked = [];
  const tag = `${engineName}-${w}x${h}`;
  fs.mkdirSync(path.join(OUT, tag), { recursive: true });
  for (let i = 0; i < n; i++) {
    const info = await page.evaluate((i) => { const s = document.querySelectorAll(".scene")[i]; return { id: s.id || String(i), last: Math.max(s.querySelectorAll("[data-beat]").length - 1, 0) }; }, i);
    await page.evaluate(([i, b]) => window.__deck.go(i, b), [i, info.last]);
    await page.waitForTimeout(50);
    const iss = await layoutIssues(page);
    if (iss.length) bad.push(`#${i} ${info.id}: ${iss.slice(0, 3).join(", ")}`);
    if (runs.length) {
      const txt = (await page.evaluate(() => document.querySelector(".scene.is-on").innerText)).toLowerCase().replace(/[^a-z0-9' ]+/g, " ").replace(/\s+/g, " ");
      const hit = runs.find((r) => txt.includes(r));
      if (hit) leaked.push(`#${i} ${info.id}: "${hit}"`);
    }
    await page.screenshot({ path: path.join(OUT, tag, String(i).padStart(2, "0") + "-" + info.id + ".png") });
  }
  say(bad.length === 0, "layout: no scroll / overflow / clipping", bad.slice(0, 4).join(" ; "));
  if (SCRIPT) say(leaked.length === 0, "no transcript on screen", leaked.slice(0, 3).join(" ; "));

  // ---- navigation
  await page.evaluate(() => window.__deck.go(0, 0));
  const st0 = await page.evaluate(() => window.__deck.state());
  await page.keyboard.press("Space"); await page.waitForTimeout(700);
  const st1 = await page.evaluate(() => window.__deck.state());
  say(st1.si === st0.si ? st1.bi === st0.bi + 1 : st1.si === st0.si + 1, "Space advances one beat", `${st0.si}.${st0.bi} → ${st1.si}.${st1.bi}`);
  await page.keyboard.press("ArrowLeft"); await page.waitForTimeout(150);
  const st2 = await page.evaluate(() => window.__deck.state());
  say(st2.si === st0.si && st2.bi === st0.bi, "← goes back one beat");
  await page.evaluate(() => window.__deck.go(1, 0));
  for (let k = 0; k < 3; k++) await page.keyboard.press("Space"); // rapid presses
  await page.waitForTimeout(900);
  const st3 = await page.evaluate(() => window.__deck.state());
  // a press mid-tween only completes the tween, so 3 rapid presses may never go further than 3 real beats from (1,0)
  const reach = await page.evaluate(() => {
    const sc = [...document.querySelectorAll(".scene")]; let si = 1, bi = 0;
    for (let k = 0; k < 3 && si < sc.length; k++) { const last = Math.max(sc[si].querySelectorAll("[data-beat]").length - 1, 0); if (bi < last) bi++; else { si++; bi = 0; } }
    return si;
  });
  say(st3.si <= reach, "rapid Space does not skip scenes", `now scene ${st3.si}, at most ${reach}`);

  // ---- sound
  const hasAudio = await page.evaluate(() => !!window.StageAudio);
  if (hasAudio) {
    await page.evaluate(() => { window.__cues = []; const o = StageAudio.cue; StageAudio.cue = (n, f) => { window.__cues.push(n); }; window.__origCue = o; });
    await page.evaluate(() => window.__deck.go(0, 0));
    await page.keyboard.press("Space"); await page.waitForTimeout(700);
    await page.keyboard.press("Space"); await page.waitForTimeout(700);
    const cues = await page.evaluate(() => window.__cues.slice());
    say(cues.includes("beat") || cues.includes("scene"), "advance fires a beat/scene cue", cues.join(","));
    await page.evaluate(() => { window.__cues = []; });
    const look = await page.evaluate(() => { const s = [...document.querySelectorAll(".scene")].findIndex((x) => x.querySelector(".look")); return s; });
    if (look >= 0) {
      await page.evaluate((i) => window.__deck.go(i, Math.max(document.querySelectorAll(".scene")[i].querySelectorAll("[data-beat]").length - 1, 0)), look);
      await page.click(".scene.is-on .look:not([hidden])");
      say((await page.evaluate(() => window.__cues)).includes("reveal"), "看对照 fires reveal cue");
    }
    const tm = await page.evaluate(() => [...document.querySelectorAll(".scene")].findIndex((x) => x.querySelector(".timer")));
    if (tm >= 0) {
      await page.evaluate((i) => window.__deck.go(i, Math.max(document.querySelectorAll(".scene")[i].querySelectorAll("[data-beat]").length - 1, 0)), tm);
      await page.evaluate(() => { window.__cues = []; });
      await page.click(".scene.is-on .timer");
      await page.click(".scene.is-on .timer");
      const c = await page.evaluate(() => window.__cues);
      say(c[0] === "timerStart" && c[1] === "timerPause", "timer start/pause cues", c.join(","));
    }
    await page.evaluate(() => { StageAudio.cue = window.__origCue; });
    const e0 = await page.evaluate(() => StageAudio.enabled);
    await page.keyboard.press("m");
    const e1 = await page.evaluate(() => StageAudio.enabled);
    await page.keyboard.press("m");
    say(e0 && !e1 && (await page.evaluate(() => StageAudio.enabled)), "M mutes and unmutes sound effects");
    const cue = await page.evaluate(async () => { StageAudio.unlock(); const d = await StageAudio.renderCue("timerDone", 2.2); let pk = 0; for (const x of d) pk = Math.max(pk, Math.abs(x)); return pk; });
    say(cue > 0.01 && cue < 0.95, "rendered cue is audible and not clipping", "peak " + cue.toFixed(3));
  } else {
    console.log("  (no StageAudio on this page — sound checks skipped)");
  }

  // ---- listening player
  const lp = await page.evaluate(() => [...document.querySelectorAll(".scene")].findIndex((x) => x.querySelector(".listen")));
  if (lp >= 0) {
    await page.evaluate((i) => window.__deck.go(i, 0), lp);
    await page.evaluate(() => { const l = document.querySelector(".scene.is-on .listen")._ls; l.gap = 2; l.gapLeft = 2; });
    const dur = await page.evaluate(() => new Promise((res) => { const a = document.querySelector(".scene.is-on .listen")._ls.audio; if (a.duration) return res(a.duration); a.addEventListener("loadedmetadata", () => res(a.duration)); setTimeout(() => res(0), 4000); }));
    say(dur > 5, "listening audio loads", dur.toFixed(1) + " s");
    // fast-forward the clip to its end so the test does not wait for real time
    await page.evaluate(() => { StageAudio.cueLog.length = 0; });
    await page.click(".scene.is-on .ls-btn");
    await page.waitForFunction(() => document.querySelector(".scene.is-on .listen")._ls.mode === "playing", null, { timeout: 5000 }).catch(() => {});
    const m1 = await page.evaluate(() => document.querySelector(".scene.is-on .listen")._ls.mode);
    say(m1 === "playing", "Play 1 starts after a short beat", m1);
    await page.evaluate(() => { const a = document.querySelector(".scene.is-on .listen")._ls.audio; a.muted = true; a.currentTime = Math.max(a.duration - 0.4, 0); });
    await page.waitForFunction(() => ["gap", "ready"].includes(document.querySelector(".scene.is-on .listen")._ls.mode), null, { timeout: 5000 }).catch(() => {});
    say(["gap", "ready"].includes(await page.evaluate(() => document.querySelector(".scene.is-on .listen")._ls.mode)), "gap countdown follows Play 1");
    await page.waitForFunction(() => document.querySelector(".scene.is-on .listen")._ls.mode === "ready", null, { timeout: 6000 }).catch(() => {});
    say((await page.evaluate(() => document.querySelector(".scene.is-on .listen")._ls.mode)) === "ready", "Play 2 becomes ready after the gap");
    await page.click(".scene.is-on .ls-btn", { force: true });  // the ready state pulses, so skip the stability wait
    await page.waitForFunction(() => document.querySelector(".scene.is-on .listen")._ls.mode === "playing", null, { timeout: 5000 }).catch(() => {});
    await page.evaluate(() => { const a = document.querySelector(".scene.is-on .listen")._ls.audio; a.muted = true; a.currentTime = Math.max(a.duration - 0.4, 0); });
    await page.waitForFunction(() => document.querySelector(".scene.is-on .listen")._ls.mode === "done", null, { timeout: 5000 }).catch(() => {});
    say((await page.evaluate(() => document.querySelector(".scene.is-on .listen")._ls.mode)) === "done", "player finishes after exactly two plays");
    const pcues = await page.evaluate(() => StageAudio.cueLog.filter((n) => ["listenStart", "gapDone", "done"].includes(n)));
    const wantChime = await page.evaluate(() => document.querySelector(".scene.is-on .listen")._ls.chime);
    say(wantChime ? pcues.length >= 3 : pcues.length === 0, wantChime ? "chime opted in: bell before each play, gap-end notes, done" : "player is silent by default (no listenStart / gapDone / done)", pcues.join(",") || "none");
    await page.evaluate((i) => window.__deck.go(i + 1, 0), lp);
    await page.waitForTimeout(150);
    const reset = await page.evaluate((i) => document.querySelectorAll(".scene")[i].querySelector(".listen")._ls.state(), lp);
    say(reset.mode === "idle" && reset.plays === 0, "leaving the scene resets the player", JSON.stringify(reset));
    // Space must never press the player
    await page.evaluate((i) => window.__deck.go(i, 0), lp);
    await page.keyboard.press("Space"); await page.waitForTimeout(600);
    say((await page.evaluate((i) => document.querySelectorAll(".scene")[i].querySelector(".listen")._ls.mode, lp)) === "idle", "Space never starts the audio");
    // data-chime="1" must bring the bell back (flip the flag on the live player, press Play, look at the cue log)
    if (!wantChime) {
      await page.evaluate(() => { const l = document.querySelector(".scene.is-on .listen")._ls; l.chime = true; StageAudio.cueLog.length = 0; });
      await page.click(".scene.is-on .ls-btn");
      await page.waitForTimeout(150);
      say(await page.evaluate(() => StageAudio.cueLog.includes("listenStart")), "opt-in chime: listenStart fires on Play");
      await page.evaluate((i) => window.__deck.go(i + 1, 0), lp);   // leave the scene: resets the player
      await page.waitForTimeout(150);
    }
  } else {
    console.log("  (no listening player in this deck)");
  }
  await browser.close();
}

(async () => {
  for (const e of ENGINES) for (const s of SIZES) await run(e, s);
  console.log(fails ? `\n${fails} FAIL` : "\nall checks passed");
  console.log("screenshots:", OUT, "— open and look at them; this run cannot hear audio or judge design.");
  process.exit(fails ? 1 : 0);
})();
