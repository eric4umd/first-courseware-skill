/* Eric Teaching Stage — sound effects + listening player.
   Self-contained, offline, no files: every cue is synthesized with the Web Audio API.
   Load AFTER deck.js is not required; deck.js calls window.StageAudio.cue(...) when present.

   Public API (window.StageAudio)
     cue(name)                 play a sound effect (no-op when muted / locked / listening audio is playing)
     enabled / setEnabled(b)   sound effects on/off (M key, #snd button). Listening audio is never muted by this.
     toggle()
     volume / setVolume(0..1)
     renderCue(name, sec)      -> Promise<Float32Array>  (offline render, used by QA and the sfx lab)
     names                     list of cue names
     cueLog                    the last 40 cue names requested (QA)
     sceneLeft(sceneEl)        reset any .listen player inside the scene
     listen(el)                the player instance for a .listen element (state(), play(), reset())
   Cues are deliberately quiet (peaks around -18 dBFS) so they sit under a voice on a video call.
   Tencent Meeting / Zoom only carry them if "share computer sound" is on. */
(function () {
  "use strict";

  var KEY = "stage-sfx-v1";
  var AC = window.AudioContext || window.webkitAudioContext;
  var ctx = null, master = null, comp = null, noiseBuf = null;
  var enabled = true, volume = 0.8, unlocked = false;
  var listeningNow = 0;                       // number of listening players currently playing audio

  try {
    var saved = JSON.parse(localStorage.getItem(KEY) || "null");
    if (saved) { enabled = saved.on !== false; if (typeof saved.vol === "number") volume = saved.vol; }
  } catch (e) { /* private mode / file:// quirks — fine */ }

  function persist() {
    try { localStorage.setItem(KEY, JSON.stringify({ on: enabled, vol: volume })); } catch (e) {}
  }

  /* ---------------------------------------------------------------- engine */
  function ensure() {
    if (ctx || !AC) return ctx;
    ctx = new AC();
    master = ctx.createGain();
    master.gain.value = volume;
    comp = ctx.createDynamicsCompressor();     // gentle safety net, not an effect
    comp.threshold.value = -20; comp.knee.value = 18; comp.ratio.value = 3; comp.attack.value = 0.004; comp.release.value = 0.15;
    master.connect(comp); comp.connect(ctx.destination);
    noiseBuf = makeNoise(ctx, 1.2);
    return ctx;
  }

  function makeNoise(c, sec) {
    var n = Math.floor(c.sampleRate * sec), b = c.createBuffer(1, n, c.sampleRate), d = b.getChannelData(0);
    var seed = 22222;                           // deterministic: same noise every time
    for (var i = 0; i < n; i++) { seed = (seed * 1664525 + 1013904223) >>> 0; d[i] = (seed / 4294967296) * 2 - 1; }
    return b;
  }

  function unlock() {
    if (unlocked) return;
    ensure();
    if (ctx && ctx.state === "suspended") ctx.resume();
    unlocked = true;
  }
  ["pointerdown", "keydown", "touchstart"].forEach(function (ev) {
    window.addEventListener(ev, unlock, { capture: true, passive: true });
  });

  /* ---------------------------------------------------------------- synth blocks (take c = context, out = node) */
  function env(c, out, t, a, d, peak) {         // attack/decay gain node → out
    var g = c.createGain();
    g.gain.setValueAtTime(0.0001, t);
    g.gain.linearRampToValueAtTime(peak, t + a);
    g.gain.exponentialRampToValueAtTime(0.0001, t + a + d);
    g.connect(out);
    return g;
  }

  function tone(c, out, t, o) {                 // o: f, to, dur, gain, type, a
    var osc = c.createOscillator();
    osc.type = o.type || "sine";
    osc.frequency.setValueAtTime(o.f, t);
    if (o.to) osc.frequency.exponentialRampToValueAtTime(o.to, t + o.dur);
    var g = env(c, out, t, o.a || 0.004, o.dur, o.gain);
    osc.connect(g);
    osc.start(t); osc.stop(t + (o.a || 0.004) + o.dur + 0.05);
  }

  function noise(c, buf, out, t, o) {           // o: f, to, q, dur, gain, type, a
    var src = c.createBufferSource();
    src.buffer = buf;
    var f = c.createBiquadFilter();
    f.type = o.type || "bandpass";
    f.Q.value = o.q || 1;
    f.frequency.setValueAtTime(o.f, t);
    if (o.to) f.frequency.exponentialRampToValueAtTime(o.to, t + o.dur);
    var g = env(c, out, t, o.a || 0.002, o.dur, o.gain);
    src.connect(f); f.connect(g);
    src.start(t, 0.05); src.stop(t + (o.a || 0.002) + o.dur + 0.05);
  }

  // soft mallet / marimba-ish note: fundamental + a quick 4x partial
  function mallet(c, out, t, f, gain, dur) {
    dur = dur || 0.38;
    tone(c, out, t, { f: f, dur: dur, gain: gain, type: "sine", a: 0.003 });
    tone(c, out, t, { f: f * 4, dur: dur * 0.18, gain: gain * 0.28, type: "sine", a: 0.002 });
    tone(c, out, t, { f: f * 2, dur: dur * 0.5, gain: gain * 0.22, type: "triangle", a: 0.003 });
  }

  // small hand-bell: inharmonic partials, long tail
  function bell(c, out, t, f, gain, dur) {
    dur = dur || 1.1;
    [[1, 1, 1], [2.01, 0.42, 0.62], [2.76, 0.30, 0.42], [4.07, 0.14, 0.26], [5.4, 0.08, 0.18]].forEach(function (p) {
      tone(c, out, t, { f: f * p[0], dur: dur * p[2], gain: gain * p[1], type: "sine", a: 0.002 });
    });
  }

  /* ---------------------------------------------------------------- the cues
     Each cue(c, out, buf, t) schedules sound at time t. Keep every cue < ~1.8 s. */
  var CUES = {
    // forward one beat: paper-card tap, barely there
    beat: function (c, out, b, t) {
      noise(c, b, out, t, { f: 2600, q: 1.1, dur: 0.035, gain: 0.20 });
      tone(c, out, t, { f: 410, to: 300, dur: 0.07, gain: 0.07 });
    },
    // next scene: card slid across the table, then set down
    scene: function (c, out, b, t) {
      noise(c, b, out, t, { f: 520, to: 3000, q: 0.8, dur: 0.20, gain: 0.13, a: 0.03 });
      noise(c, b, out, t + 0.19, { f: 1900, q: 1.2, dur: 0.04, gain: 0.18 });
      tone(c, out, t + 0.19, { f: 190, to: 130, dur: 0.09, gain: 0.10 });
    },
    back: function (c, out, b, t) {
      noise(c, b, out, t, { f: 2600, to: 650, q: 0.8, dur: 0.13, gain: 0.08, a: 0.01 });
    },
    // 看对照 / Stuck? opens
    reveal: function (c, out, b, t) {
      mallet(c, out, t, 659.3, 0.10, 0.30);
      mallet(c, out, t + 0.085, 987.8, 0.09, 0.40);
    },
    pick: function (c, out, b, t) {
      noise(c, b, out, t, { f: 1500, q: 1.4, dur: 0.03, gain: 0.16 });
      tone(c, out, t, { f: 620, dur: 0.05, gain: 0.05 });
    },
    pickOk: function (c, out, b, t) {
      mallet(c, out, t, 784, 0.10, 0.28);
      mallet(c, out, t + 0.07, 1174.7, 0.09, 0.40);
    },
    // not punishing: a soft wooden knock, lower pitch
    pickNo: function (c, out, b, t) {
      tone(c, out, t, { f: 215, to: 150, dur: 0.16, gain: 0.14, type: "triangle", a: 0.003 });
      noise(c, b, out, t, { f: 700, q: 1.5, dur: 0.03, gain: 0.10 });
    },
    tallyUp: function (c, out, b, t) { tone(c, out, t, { f: 520, to: 780, dur: 0.09, gain: 0.10 }); },
    tallyDown: function (c, out, b, t) { tone(c, out, t, { f: 520, to: 350, dur: 0.09, gain: 0.09 }); },
    // cassette PLAY key: click, thunk, second lighter click
    timerStart: function (c, out, b, t) {
      noise(c, b, out, t, { f: 1100, q: 2.2, dur: 0.022, gain: 0.30 });
      tone(c, out, t + 0.012, { f: 120, to: 78, dur: 0.11, gain: 0.20 });
      noise(c, b, out, t + 0.075, { f: 2300, q: 1.6, dur: 0.018, gain: 0.14 });
    },
    timerPause: function (c, out, b, t) {
      noise(c, b, out, t, { f: 900, q: 2.2, dur: 0.022, gain: 0.26 });
      tone(c, out, t + 0.01, { f: 105, to: 80, dur: 0.08, gain: 0.14 });
    },
    timerReset: function (c, out, b, t) {
      noise(c, b, out, t, { f: 1800, to: 500, q: 1.0, dur: 0.09, gain: 0.09, a: 0.01 });
    },
    // time's up: friendly two-note bell, twice — noticeable on a call but not alarming
    timerDone: function (c, out, b, t) {
      bell(c, out, t, 784, 0.15, 1.0);
      bell(c, out, t + 0.20, 1046.5, 0.14, 1.1);
      bell(c, out, t + 1.05, 784, 0.11, 0.9);
      bell(c, out, t + 1.25, 1046.5, 0.10, 1.0);
    },
    // before a recording starts (like the exam "ding")
    listenStart: function (c, out, b, t) {
      bell(c, out, t, 659.3, 0.14, 0.9);
      bell(c, out, t + 0.22, 880, 0.13, 1.0);
    },
    // the gap between plays is over
    gapDone: function (c, out, b, t) {
      mallet(c, out, t, 880, 0.10, 0.30);
      mallet(c, out, t + 0.12, 1108.7, 0.10, 0.30);
      mallet(c, out, t + 0.24, 1318.5, 0.11, 0.55);
    },
    // small positive: both plays done, deck finished, etc.
    done: function (c, out, b, t) {
      mallet(c, out, t, 523.3, 0.10, 0.4);
      mallet(c, out, t + 0.10, 659.3, 0.10, 0.4);
      mallet(c, out, t + 0.20, 784, 0.10, 0.4);
      mallet(c, out, t + 0.30, 1046.5, 0.11, 0.9);
    },
    // sound on/off confirmation
    on: function (c, out, b, t) { mallet(c, out, t, 880, 0.09, 0.25); },
    off: function (c, out, b, t) { tone(c, out, t, { f: 440, to: 330, dur: 0.12, gain: 0.08 }); }
  };
  CUES.jump = CUES.scene;
  var NAMES = Object.keys(CUES);

  /* ---------------------------------------------------------------- sound palettes (one per theme)
     A palette replaces only the ambient cues (beat, scene, back, reveal, timerDone). The functional ones
     (listenStart, gapDone, done, pick*, tally*, timer start/pause) stay shared so a student always recognises them.
     data-theme on <html> selects the palette; StageAudio.usePalette(name) switches it (Sound Lab). Keep gains low. */
  var PALETTES = {
    // paper and pencil
    marginalia: {
      beat: function (c, out, b, t) {
        noise(c, b, out, t, { f: 4200, q: 2.5, dur: 0.018, gain: 0.12 });
        noise(c, b, out, t, { f: 900, q: 1, dur: 0.03, gain: 0.05 });
      },
      scene: function (c, out, b, t) {
        noise(c, b, out, t, { f: 700, to: 2800, q: 0.7, dur: 0.30, gain: 0.12, a: 0.06 });
        noise(c, b, out, t + 0.29, { f: 1800, q: 1.4, dur: 0.03, gain: 0.08 });
      },
      back: function (c, out, b, t) { noise(c, b, out, t, { f: 2800, to: 800, q: 0.8, dur: 0.16, gain: 0.07, a: 0.01 }); },
      reveal: function (c, out, b, t) {
        noise(c, b, out, t, { f: 3800, q: 3, dur: 0.03, gain: 0.12 });
        noise(c, b, out, t + 0.05, { f: 3000, q: 3, dur: 0.03, gain: 0.11 });
        noise(c, b, out, t + 0.10, { f: 4200, q: 3, dur: 0.035, gain: 0.12 });
        mallet(c, out, t + 0.12, 587.3, 0.06, 0.30);
      },
      timerDone: function (c, out, b, t) {
        bell(c, out, t, 880, 0.12, 1.0);
        bell(c, out, t + 0.20, 1174.7, 0.10, 1.0);
      }
    },
    // mechanical: clicks, ratchets, square beeps
    grid: {
      beat: function (c, out, b, t) {
        noise(c, b, out, t, { f: 5200, q: 4, dur: 0.012, gain: 0.20 });
        tone(c, out, t, { f: 1800, dur: 0.02, gain: 0.04, type: "square", a: 0.001 });
      },
      scene: function (c, out, b, t) {
        for (var i = 0; i < 3; i++) noise(c, b, out, t + i * 0.04, { f: 4200, q: 3, dur: 0.012, gain: 0.18 });
        tone(c, out, t + 0.1, { f: 220, to: 110, dur: 0.1, gain: 0.08 });
      },
      back: function (c, out, b, t) { noise(c, b, out, t, { f: 2600, q: 3, dur: 0.014, gain: 0.16 }); },
      reveal: function (c, out, b, t) {
        noise(c, b, out, t, { f: 4800, q: 4, dur: 0.012, gain: 0.18 });
        bell(c, out, t + 0.03, 1318.5, 0.09, 0.4);
      },
      timerDone: function (c, out, b, t) {
        [0, 0.2, 1.0, 1.2].forEach(function (d) { tone(c, out, t + d, { f: 880, dur: 0.12, gain: 0.15, type: "square", a: 0.002 }); });
      }
    },
    // warm stage: low thumps, swells, slow pads
    studio: {
      beat: function (c, out, b, t) {
        tone(c, out, t, { f: 150, to: 95, dur: 0.12, gain: 0.12, a: 0.006 });
        noise(c, b, out, t, { f: 400, q: 0.6, dur: 0.08, gain: 0.04 });
      },
      scene: function (c, out, b, t) {
        noise(c, b, out, t, { f: 300, to: 1800, q: 0.6, dur: 0.5, gain: 0.10, a: 0.18 });
        tone(c, out, t, { f: 98, to: 196, dur: 0.5, gain: 0.09, type: "triangle", a: 0.12 });
      },
      back: function (c, out, b, t) { tone(c, out, t, { f: 196, to: 110, dur: 0.2, gain: 0.08, a: 0.01 }); },
      reveal: function (c, out, b, t) {
        tone(c, out, t, { f: 440, dur: 0.5, gain: 0.08, type: "triangle", a: 0.05 });
        tone(c, out, t + 0.06, { f: 659.3, dur: 0.6, gain: 0.07, type: "triangle", a: 0.05 });
        tone(c, out, t + 0.06, { f: 880, dur: 0.4, gain: 0.03, a: 0.05 });
      },
      timerDone: function (c, out, b, t) {
        tone(c, out, t, { f: 523.3, dur: 1.1, gain: 0.10, type: "triangle", a: 0.03 });
        tone(c, out, t + 0.15, { f: 659.3, dur: 1.0, gain: 0.09, type: "triangle", a: 0.03 });
        tone(c, out, t + 0.30, { f: 784, dur: 0.9, gain: 0.09, type: "triangle", a: 0.03 });
        bell(c, out, t + 0.30, 1046.5, 0.06, 1.0);
      }
    },
    // exam hall: almost silent
    exam: {
      beat: function (c, out, b, t) { noise(c, b, out, t, { f: 3000, q: 2, dur: 0.008, gain: 0.07 }); },
      scene: function (c, out, b, t) { noise(c, b, out, t, { f: 3000, q: 2, dur: 0.01, gain: 0.08 }); },
      back: function (c, out, b, t) { noise(c, b, out, t, { f: 2400, q: 2, dur: 0.008, gain: 0.06 }); },
      reveal: function (c, out, b, t) { tone(c, out, t, { f: 700, dur: 0.08, gain: 0.06 }); },
      timerDone: function (c, out, b, t) {
        [0, 0.4, 1.2, 1.6].forEach(function (d) { tone(c, out, t + d, { f: 880, dur: 0.25, gain: 0.16 }); });
      }
    }
  };
  var BASE = {};
  Object.keys(CUES).forEach(function (k) { BASE[k] = CUES[k]; });
  var paletteName = "";
  function usePalette(name) {
    Object.keys(BASE).forEach(function (k) { CUES[k] = BASE[k]; });
    if (PALETTES[name]) Object.keys(PALETTES[name]).forEach(function (k) { CUES[k] = PALETTES[name][k]; });
    CUES.jump = CUES.scene;
    paletteName = PALETTES[name] ? name : "";
  }
  usePalette(document.documentElement.getAttribute("data-theme") || "");

  /* ---------------------------------------------------------------- playing / rendering */
  var lastAt = {};
  var cueLog = [];                            // last 40 requested cue names (QA reads this; no effect on sound)
  function cue(name, force) {
    if (!CUES[name]) return;
    cueLog.push(name); if (cueLog.length > 40) cueLog.shift();
    if (!force && (!enabled || listeningNow > 0)) return;
    if (!ensure()) return;
    if (ctx.state === "suspended") { ctx.resume(); if (!unlocked) return; }
    var now = ctx.currentTime;
    if (lastAt[name] && now - lastAt[name] < 0.03) return;   // key-repeat guard
    lastAt[name] = now;
    CUES[name](ctx, master, noiseBuf, now + 0.005);
  }

  function renderCue(name, sec) {
    var OAC = window.OfflineAudioContext || window.webkitOfflineAudioContext;
    var rate = 44100, off = new OAC(1, Math.ceil(rate * (sec || 2)), rate);
    var out = off.createGain(); out.gain.value = 0.8; out.connect(off.destination);
    CUES[name](off, out, makeNoise(off, 1.2), 0.01);
    return off.startRendering().then(function (buf) { return buf.getChannelData(0); });
  }

  /* ---------------------------------------------------------------- sound toggle (button #snd, key M) */
  function paintToggle() {
    var btn = document.getElementById("snd");
    if (!btn) return;
    btn.classList.toggle("is-muted", !enabled);
    btn.setAttribute("aria-pressed", String(enabled));
    btn.setAttribute("aria-label", enabled ? "音效：开（M 键关闭）" : "音效：关（M 键打开）");
    btn.title = enabled ? "音效：开 · 按 M 关闭" : "音效：关 · 按 M 打开";
  }
  function setEnabled(on) {
    var was = enabled;
    enabled = !!on; persist(); paintToggle();
    if (enabled && !was) { unlock(); cue("on", true); }
  }
  function toggle() { if (enabled) { cue("off", true); } setEnabled(!enabled); }
  function setVolume(v) {
    volume = Math.min(1, Math.max(0, v)); persist();
    if (master) master.gain.value = volume;
  }

  document.addEventListener("keydown", function (e) {
    if (e.code === "KeyM" && !e.metaKey && !e.ctrlKey && !e.altKey) { e.preventDefault(); toggle(); }
  });
  document.addEventListener("click", function (e) {
    if (e.target.closest("#snd")) { e.preventDefault(); e.stopPropagation(); toggle(); }
  }, true);
  document.addEventListener("DOMContentLoaded", paintToggle);
  paintToggle();

  /* ---------------------------------------------------------------- listening player
     Markup contract (author writes only this):
       <div class="listen" data-src="audio/listening.mp3" data-plays="2" data-gap="45"
            data-label="Listening" data-auto2="0" data-chime="0"></div>
     JS builds: big play button, cassette reels, level bars, play counter, gap ring, status line.
     Flow: Play 1 → audio → gap countdown → "Play 2" ready (or auto) → audio → done → optional check replay.
     The player is silent apart from the recording itself. data-chime="1" brings back the exam-style bell before each
     play, the rising notes when the gap ends and the small fanfare when both plays are done (off by default, the teacher's call).
     Teacher keys while a player is on screen:  P = play / pause.   No transcript, no scrubbing. */
  var players = [];

  function ListenPlayer(el) {
    var self = this;
    this.el = el;
    this.src = el.getAttribute("data-src");
    this.max = parseInt(el.getAttribute("data-plays"), 10) || 2;
    this.gap = parseInt(el.getAttribute("data-gap"), 10);
    if (isNaN(this.gap)) this.gap = 45;
    this.auto2 = el.getAttribute("data-auto2") === "1";
    this.chime = el.getAttribute("data-chime") === "1";   // listenStart / gapDone / done bells: opt-in
    this.doneMsg = el.getAttribute("data-msg-done") || "两遍听完。开始回答问题。";
    this.nudgedAt = 0;
    if (el.getAttribute("data-layout") === "bar") el.classList.add("ls-row");
    this.n = 0;                                  // plays completed
    this.mode = "idle";                          // idle | lead | playing | paused | gap | ready | done | error
    this.gapLeft = this.gap;
    this.gapEnd = 0;
    this.leadTimer = 0;
    this.tick = 0;
    this.audio = new Audio();
    this.audio.preload = "auto";
    this.audio.src = this.src;
    this.build();
    this.audio.addEventListener("ended", function () { self.ended(); });
    this.audio.addEventListener("error", function () { self.fail(); });
    this.audio.addEventListener("loadedmetadata", function () { self.dur = self.audio.duration; self.paint(); });
    this.audio.addEventListener("timeupdate", function () { self.progress(); });
    this.paint();
  }

  ListenPlayer.prototype.build = function () {
    var el = this.el;
    el.classList.add("ls");
    el.innerHTML =
      '<div class="ls-top"><span class="ls-count"></span><span class="ls-label"></span></div>' +
      '<button type="button" class="ls-btn" aria-live="polite"><span class="ls-ico"></span><span class="ls-btn-t"></span></button>' +
      '<div class="ls-bars" aria-hidden="true">' + new Array(29).join("<i></i>") + "</div>" +
      '<div class="ls-bar"><div class="ls-bar-fill"></div></div>' +
      '<div class="ls-gap"><svg viewBox="0 0 44 44" aria-hidden="true"><circle class="g-bg" cx="22" cy="22" r="18"/><circle class="g-fg" cx="22" cy="22" r="18" pathLength="1"/></svg><span class="ls-gap-n"></span></div>' +
      '<p class="ls-status"></p>' +
      '<button type="button" class="ls-again" hidden>再听一次（核对用）</button>';
    el.querySelector(".ls-label").textContent = el.getAttribute("data-label") || "Listening";
    this.q = function (s) { return el.querySelector(s); };
    var self = this;
    this.q(".ls-btn").addEventListener("click", function () { self.press(); });
    this.q(".ls-again").addEventListener("click", function () { self.replayCheck(); });
    var bars = el.querySelectorAll(".ls-bars i");
    for (var i = 0; i < bars.length; i++) {      // fixed pseudo-random delays → lively but identical each time
      bars[i].style.animationDelay = (-((i * 37) % 11) * 0.09).toFixed(2) + "s";
      bars[i].style.animationDuration = (0.55 + ((i * 53) % 7) * 0.07).toFixed(2) + "s";
    }
  };

  ListenPlayer.prototype.press = function () {
    unlock();
    var m = this.mode;
    if (m === "idle" || m === "ready") this.start();
    else if (m === "playing") { this.audio.pause(); this.mode = "paused"; listeningNow = Math.max(0, listeningNow - 1); }
    else if (m === "paused") { this.resume(); }
    else if (m === "lead") { /* chime still ringing */ }
    else if (m === "gap") { this.skipGap(); }
    this.paint();
  };

  ListenPlayer.prototype.start = function () {
    var self = this;
    this.mode = "lead";
    this.audio.currentTime = 0;
    if (this.chime) cue("listenStart", true);
    this.paint();
    clearTimeout(this.leadTimer);
    this.leadTimer = setTimeout(function () { self.begin(); }, this.chime ? 1250 : 300);   // chime: let it finish; none: a short beat so the click registers
  };

  ListenPlayer.prototype.begin = function () {
    var self = this;
    this.mode = "playing";
    listeningNow += 1;
    var p = this.audio.play();
    if (p && p.catch) p.catch(function () { listeningNow = Math.max(0, listeningNow - 1); self.fail(); });
    this.paint();
  };

  ListenPlayer.prototype.resume = function () {
    var self = this;
    this.mode = "playing";
    listeningNow += 1;
    var p = this.audio.play();
    if (p && p.catch) p.catch(function () { listeningNow = Math.max(0, listeningNow - 1); self.fail(); });
  };

  ListenPlayer.prototype.ended = function () {
    listeningNow = Math.max(0, listeningNow - 1);
    this.n += 1;
    if (this.n < this.max) {
      this.mode = "gap";
      this.gapLeft = this.gap;
      this.gapEnd = Date.now() + this.gap * 1000;
      var self = this;
      clearInterval(this.tick);
      this.tick = setInterval(function () { self.gapTick(); }, 200);
      if (this.gap === 0) this.gapTick();
    } else {
      this.mode = "done";
      if (this.chime) cue("done", true);
    }
    this.paint();
  };

  ListenPlayer.prototype.gapTick = function () {
    this.gapLeft = Math.max(0, (this.gapEnd - Date.now()) / 1000);
    if (this.gapLeft <= 0) {
      clearInterval(this.tick);
      if (this.chime) cue("gapDone", true);
      this.mode = "ready";
      if (this.auto2) { this.start(); }
    }
    this.paint();
  };

  ListenPlayer.prototype.skipGap = function () {
    clearInterval(this.tick);
    this.gapLeft = 0;
    this.mode = "ready";
    this.start();
  };

  ListenPlayer.prototype.replayCheck = function () {   // after the official plays: teacher re-plays to check answers
    this.n = this.max - 1;                              // does not re-open the counter
    this.mode = "idle";
    this.start();
  };

  ListenPlayer.prototype.fail = function () {
    this.mode = "error";
    this.paint();
  };

  ListenPlayer.prototype.progress = function () {
    var d = this.audio.duration || this.dur || 0;
    var f = this.q(".ls-bar-fill");
    if (f && d) f.style.width = (100 * this.audio.currentTime / d) + "%";
  };

  ListenPlayer.prototype.reset = function () {
    clearTimeout(this.leadTimer);
    clearInterval(this.tick);
    if (this.mode === "playing") listeningNow = Math.max(0, listeningNow - 1);
    this.audio.pause();
    try { this.audio.currentTime = 0; } catch (e) {}
    this.n = 0; this.mode = "idle"; this.gapLeft = this.gap;
    this.paint();
  };

  // Called by deck.js before the deck leaves a scene. If the listening task has not been finished,
  // the first press only flashes the player; a second press within 5 s really leaves.
  ListenPlayer.prototype.hold = function () {
    if (this.n >= this.max) return false;
    var now = Date.now();
    if (now - this.nudgedAt < 5000) return false;
    this.nudgedAt = now;
    var self = this, el = this.el, st = this.q(".ls-status");
    el.classList.remove("nudge"); void el.offsetWidth; el.classList.add("nudge");
    st.textContent = this.n === 0 && this.mode === "idle"
      ? "还没开始听。点 Play 1；真要跳过，再按一次下一拍。"
      : "还没听完两遍。真要跳过，再按一次下一拍。";
    setTimeout(function () { el.classList.remove("nudge"); self.paint(); }, 4800);
    return true;
  };

  ListenPlayer.prototype.state = function () {
    return { mode: this.mode, plays: this.n, max: this.max, gapLeft: Math.round(this.gapLeft), duration: this.audio.duration || 0 };
  };

  ListenPlayer.prototype.paint = function () {
    var el = this.el, m = this.mode, n = this.n, max = this.max;
    el.setAttribute("data-mode", m);
    var count = max > 1 ? "Play " + Math.min(n + (m === "done" ? 0 : 1), max) + " of " + max : "Listen";
    if (m === "done") count = "Done · " + max + " of " + max;
    this.q(".ls-count").textContent = count;
    var t = this.q(".ls-btn-t"), s = this.q(".ls-status"), ico = this.q(".ls-ico");
    var label = {
      idle: "Play " + (n + 1), lead: "…", playing: "Pause", paused: "Resume",
      gap: "Skip wait", ready: "Play " + (n + 1), done: "Done", error: "No audio"
    }[m];
    t.textContent = label;
    ico.className = "ls-ico i-" + (m === "playing" ? "pause" : m === "gap" ? "wait" : m === "done" ? "check" : "play");
    var msg = {
      idle: "只听，不看稿。第一遍只记笔记。",
      lead: "准备…",
      playing: n === 0 ? "第一遍：只记，不回答。" : "第二遍：补全、核对。",
      paused: "已暂停。",
      gap: "整理笔记 · " + Math.ceil(this.gapLeft) + " 秒后可以听第二遍",
      ready: "时间到。点 Play " + (n + 1) + "（或按 P）。",
      done: this.doneMsg,
      error: "这段音频没加载出来。请老师直接朗读，或检查 audio 文件。"
    }[m];
    s.textContent = msg;
    var ring = this.q(".g-fg");
    if (ring) ring.style.strokeDashoffset = String(this.gap ? 1 - this.gapLeft / this.gap : 1);
    this.q(".ls-gap-n").textContent = m === "gap" ? String(Math.ceil(this.gapLeft)) : "";
    this.q(".ls-again").hidden = m !== "done";
    el.classList.toggle("is-playing", m === "playing");
    if (m !== "playing" && m !== "paused") this.q(".ls-bar-fill").style.width = m === "done" ? "100%" : "0%";
  };

  function initPlayers() {
    document.querySelectorAll(".listen").forEach(function (el) {
      if (!el._ls) { el._ls = new ListenPlayer(el); players.push(el._ls); }
    });
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", initPlayers);
  else initPlayers();

  document.addEventListener("keydown", function (e) {
    if (e.code !== "KeyP" || e.metaKey || e.ctrlKey || e.altKey) return;
    var on = document.querySelector(".scene.is-on .listen");
    if (on && on._ls) { e.preventDefault(); on._ls.press(); }
  });

  window.StageAudio = {
    cue: cue,
    names: NAMES,
    get enabled() { return enabled; },
    get volume() { return volume; },
    setEnabled: setEnabled,
    toggle: toggle,
    setVolume: setVolume,
    renderCue: renderCue,
    cueLog: cueLog,
    usePalette: usePalette,
    get palette() { return paletteName; },
    palettes: Object.keys(PALETTES),
    unlock: unlock,
    listen: function (el) { return el && el._ls; },
    holdAdvance: function (scene) {
      if (!scene) return false;
      var held = false;
      scene.querySelectorAll(".listen").forEach(function (el) { if (el._ls && el._ls.hold()) held = true; });
      return held;
    },
    sceneLeft: function (scene) {
      if (!scene) return;
      scene.querySelectorAll(".listen").forEach(function (el) { if (el._ls) el._ls.reset(); });
    },
    get listeningNow() { return listeningNow; }
  };
})();
