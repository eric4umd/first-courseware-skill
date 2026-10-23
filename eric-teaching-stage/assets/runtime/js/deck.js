/* Eric Teaching Deck runtime.
   Based on the accepted lesson-2 runtime; same beat contract:
   Space / ArrowRight / empty-paper click = next beat; a press during a tween finishes that tween;
   ArrowLeft = previous beat (instant); local controls never advance.
   Additions: data-next / data-prev scene routing, branch scenes (excluded from progress),
   jump trail for back navigation, timers, local reveals, tallies, section rail. */
(function () {
  const reducedPref = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  /* Motion personality: a theme sets --mo-style on :root (rise | ink | snap | light | cut). Read once.
     No theme = "rise" = the original behaviour, unchanged. "cut" = no tweens at all (same path as reduced motion). */
  const MO = (function () {
    const raw = getComputedStyle(document.documentElement).getPropertyValue("--mo-style").trim();
    const style = /^(rise|ink|snap|light|cut)$/.test(raw) ? raw : "rise";
    const T = {
      rise:  { from: { autoAlpha: 0, y: 12 }, to: { autoAlpha: 1, y: 0, duration: 0.55 }, scene: 0.24 },
      ink:   { from: { autoAlpha: 1, y: 0, clipPath: "inset(-30px 100% -30px -30px)" }, to: { clipPath: "inset(-30px -30px -30px -30px)", duration: 0.85, ease: "power1.inOut" }, scene: 0.30 },
      snap:  { from: { autoAlpha: 0, x: -28 }, to: { autoAlpha: 1, x: 0, duration: 0.22, ease: "power4.out" }, scene: 0.10 },
      light: { from: { autoAlpha: 0, scale: 0.985, y: 6 }, to: { autoAlpha: 1, scale: 1, y: 0, duration: 0.7, ease: "sine.out" }, scene: 0.40 },
      cut:   { from: {}, to: {}, scene: 0 }
    };
    return Object.assign({ style: style, still: style === "cut" }, T[style]);
  })();
  const reduced = reducedPref || MO.still;
  // everything a beat can have been animated with, cleared when it settles (default theme: exactly y/alpha as before)
  const SETTLED = MO.style === "rise" ? { autoAlpha: 1, y: 0 } : { autoAlpha: 1, y: 0, x: 0, scale: 1, clearProps: "clipPath" };
  const HIDDEN = MO.style === "rise" ? { autoAlpha: 0, y: 12 } : { autoAlpha: 0, y: 12, x: 0, scale: 1, clearProps: "clipPath" };
  const scenes = Array.from(document.querySelectorAll(".scene"));
  const bar = document.getElementById("bar");
  const label = document.getElementById("pos");
  const prevBtn = document.getElementById("prev");
  const nextBtn = document.getElementById("next");
  const railTabs = Array.from(document.querySelectorAll("[data-part-tab]"));

  // Sound effects (js/stage-audio.js). Optional: the deck works the same without it.
  function cue(name) { if (window.StageAudio) window.StageAudio.cue(name); }

  let si = 0;
  let bi = 0;
  let tl = null;
  let busy = false;
  let current = null;
  let started = false;
  const trail = [];

  /* ---------- scene helpers ---------- */

  function beats(scene) {
    return Array.from(scene.querySelectorAll("[data-beat]"));
  }

  function isBranch(scene) {
    return scene.hasAttribute("data-branch");
  }

  function findScene(key) {
    if (!key) return -1;
    return scenes.findIndex(function (scene) {
      return scene.id === key || scene.getAttribute("data-block") === key;
    });
  }

  function totalBeats() {
    return scenes.reduce(function (n, scene) {
      return isBranch(scene) ? n : n + beats(scene).length;
    }, 0);
  }

  function doneBeats() {
    let anchor = si;
    let extra = bi + 1;
    if (isBranch(scenes[si])) {
      while (anchor > 0 && isBranch(scenes[anchor])) anchor -= 1;
      extra = beats(scenes[anchor]).length;
    }
    let n = 0;
    for (let i = 0; i < anchor; i += 1) {
      if (!isBranch(scenes[i])) n += beats(scenes[i]).length;
    }
    return n + extra;
  }

  /* ---------- beat motion ---------- */

  function settle(el) {
    if (!el) return;
    gsap.set(el, SETTLED);
    el.classList.add("is-in");
  }

  function kill() {
    if (tl) {
      const t = tl;        // progress(1) fires onComplete, which nulls `tl`; keep our own handle
      tl = null;
      t.progress(1);
      t.kill();
    }
    settle(current);
    busy = false;
  }

  function paintChrome() {
    const scene = scenes[si];
    if (bar) bar.style.width = (100 * doneBeats() / Math.max(totalBeats(), 1)) + "%";
    if (label) {
      label.textContent = scene.getAttribute("data-title") || "";
      // themes may print the folio / cue number from CSS (content: attr(data-no)); D3 ignores these
      ["data-no", "data-total", "data-part-label"].forEach(function (k) {
        const v = scene.getAttribute(k);
        if (v === null) label.removeAttribute(k); else label.setAttribute(k, v);
      });
    }
    const part = scene.getAttribute("data-part");
    railTabs.forEach(function (tab) {
      tab.classList.toggle("is-current", tab.getAttribute("data-part-tab") === part);
    });
    document.body.setAttribute("data-current-part", part || "");
  }

  function rest(el, on) {
    if (on) {
      gsap.set(el, SETTLED);
      el.classList.add("is-in");
    } else {
      gsap.set(el, HIDDEN);
      el.classList.remove("is-in");
    }
  }

  function play(el, sceneChanged) {
    current = el;
    el.classList.add("is-in");
    if (reduced || document.hidden) {
      rest(el, true);
      busy = false;
      return;
    }
    busy = true;
    tl = gsap.timeline({
      defaults: { ease: "power2.out" },
      onComplete: function () {
        settle(el);
        busy = false;
        tl = null;
      }
    });
    if (sceneChanged) {
      tl.fromTo(
        scenes[si],
        { autoAlpha: 0, scale: 0.996 },
        { autoAlpha: 1, scale: 1, duration: MO.scene, ease: "power2.out" },
        0
      );
    }
    tl.fromTo(el, MO.from, MO.to, sceneChanged ? 0.02 : 0);
  }

  /* ---------- per-scene local state ---------- */

  function resetScene(scene) {
    scene.querySelectorAll(".contrast").forEach(function (box) {
      box.hidden = true;
      gsap.set(box, { clearProps: "opacity,visibility,transform,clipPath" });
    });
    scene.querySelectorAll(".look").forEach(function (btn) {
      btn.hidden = false;
    });
    scene.querySelectorAll(".timer").forEach(resetTimer);
    if (window.StageAudio) window.StageAudio.sceneLeft(scene);
  }

  function showScene(nextSi, nextBi, animate) {
    const sceneChanged = !started || nextSi !== si;
    const first = !started;
    started = true;
    kill();
    if (sceneChanged) {
      resetScene(scenes[si]);
      resetScene(scenes[nextSi]);
      gsap.set(scenes[nextSi], { autoAlpha: 1, scale: 1 });
    }
    si = nextSi;
    bi = nextBi;
    scenes.forEach(function (scene, i) {
      scene.classList.toggle("is-on", i === si);
    });
    const items = beats(scenes[si]);
    items.forEach(function (el, i) {
      if (i < bi) rest(el, true);
      else if (i > bi) rest(el, false);
    });
    if (items[bi]) {
      if (animate) play(items[bi], sceneChanged);
      else rest(items[bi], true);
    }
    paintChrome();
    if (!first) cue(animate ? (sceneChanged ? "scene" : "beat") : "back");
  }

  function skip() {
    if (tl) tl.progress(1);
    settle(current);
    busy = false;
  }

  /* ---------- navigation ---------- */

  function goJump(index, remember) {
    if (index < 0) return;
    if (remember) trail.push({ si: si, bi: bi, to: index });
    showScene(index, 0, true);
  }

  function next() {
    if (busy) {
      skip();
      return;
    }
    const scene = scenes[si];
    const items = beats(scene);
    if (bi < items.length - 1) {
      showScene(si, bi + 1, true);
      return;
    }
    // A listening task that is not finished holds the first press (see stage-audio.js).
    if (window.StageAudio && window.StageAudio.holdAdvance(scene)) return;
    const route = scene.getAttribute("data-next");
    if (route) {
      goJump(findScene(route), true);
      return;
    }
    let n = si + 1;
    if (!isBranch(scene)) {
      while (n < scenes.length && isBranch(scenes[n])) n += 1;
    }
    if (n < scenes.length) showScene(n, 0, true);
  }

  function lastBeat(index) {
    return Math.max(beats(scenes[index]).length - 1, 0);
  }

  function prev() {
    skip();
    if (bi > 0) {
      showScene(si, bi - 1, false);
      return;
    }
    const top = trail[trail.length - 1];
    if (top && top.to === si) {
      trail.pop();
      showScene(top.si, top.bi, false);
      return;
    }
    const fallback = findScene(scenes[si].getAttribute("data-prev"));
    if (fallback >= 0) {
      showScene(fallback, lastBeat(fallback), false);
      return;
    }
    let p = si - 1;
    if (!isBranch(scenes[si])) {
      while (p >= 0 && isBranch(scenes[p])) p -= 1;
    }
    if (p >= 0) showScene(p, lastBeat(p), false);
  }

  /* ---------- timers (soft cassette clicks + a bell at zero; never auto-advance) ---------- */

  const timers = new Map();

  function fmt(sec) {
    const s = Math.max(0, Math.ceil(sec));
    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
  }

  function timerState(btn) {
    let st = timers.get(btn);
    if (!st) {
      const total = parseInt(btn.getAttribute("data-timer"), 10) || 60;
      st = { total: total, left: total, endAt: 0, mode: "idle" };
      timers.set(btn, st);
    }
    return st;
  }

  const stateWords = { idle: "点一下开始", running: "计时中 · 点一下暂停", paused: "已暂停 · 点一下继续", done: "时间到" };

  function paintTimer(btn) {
    const st = timerState(btn);
    const t = btn.querySelector(".t-time");
    const s = btn.querySelector(".t-state");
    const ring = btn.querySelector(".t-ring-fg");
    if (t) t.textContent = fmt(st.left);
    if (s) s.textContent = stateWords[st.mode];
    if (ring) ring.style.strokeDashoffset = String(1 - st.left / st.total);
    btn.classList.toggle("is-running", st.mode === "running");
    btn.classList.toggle("is-paused", st.mode === "paused");
    btn.classList.toggle("is-done", st.mode === "done");
    btn.setAttribute("aria-label", "计时器 " + fmt(st.left) + " " + stateWords[st.mode]);
  }

  function resetTimer(btn) {
    const st = timerState(btn);
    st.left = st.total;
    st.mode = "idle";
    paintTimer(btn);
  }

  function toggleTimer(btn) {
    const st = timerState(btn);
    if (st.mode === "idle" || st.mode === "paused") {
      st.endAt = Date.now() + st.left * 1000;
      st.mode = "running";
      cue("timerStart");
    } else if (st.mode === "running") {
      st.left = Math.max(0, (st.endAt - Date.now()) / 1000);
      st.mode = "paused";
      cue("timerPause");
    } else {
      st.left = st.total;
      st.mode = "idle";
      cue("timerReset");
    }
    paintTimer(btn);
  }

  function finishTimer(btn) {
    const st = timerState(btn);
    st.left = 0;
    st.mode = "done";
    paintTimer(btn);
    cue("timerDone");
    if (!reduced) {
      const box = btn.closest(".timer-wrap") || btn;
      gsap.fromTo(box, { x: 0 }, { keyframes: { x: [0, -9, 9, -6, 6, -3, 0] }, duration: 0.5, ease: "none", clearProps: "x" });
    }
  }

  setInterval(function () {
    timers.forEach(function (st, btn) {
      if (st.mode !== "running") return;
      st.left = Math.max(0, (st.endAt - Date.now()) / 1000);
      if (st.left <= 0) finishTimer(btn);
      else paintTimer(btn);
    });
  }, 200);

  document.querySelectorAll(".timer").forEach(function (btn) {
    paintTimer(btn);
  });

  /* ---------- local reveals (看对照 / Stuck?) ---------- */

  function reveal(look) {
    const scope = look.closest(".look-wrap") || look.closest("[data-beat]");
    const box = scope ? scope.querySelector(".contrast") : null;
    if (!box) return;
    box.hidden = false;
    look.hidden = true;
    cue("reveal");
    if (reduced) {
      gsap.set(box, { autoAlpha: 1, y: 0 });
    } else if (MO.style === "rise") {
      gsap.fromTo(
        box,
        { autoAlpha: 0, y: 10 },
        { autoAlpha: 1, y: 0, duration: 0.32, ease: "power2.out" }
      );
    } else {
      // same personality as the beats, a little quicker
      gsap.fromTo(box, MO.from, Object.assign({}, MO.to, { duration: Math.min(MO.to.duration, 0.55), ease: MO.to.ease || "power2.out", clearProps: "clipPath,x,scale" }));
    }
  }

  /* ---------- input ---------- */

  function localTarget(node) {
    return node.closest("a, button, .chip, .choice, .look, .timer, .tally, [data-jump], .listen, .snd-btn, input, textarea, label");
  }

  // Keep buttons from taking focus, so Space never "clicks" a control and advances at once.
  document.addEventListener("mousedown", function (event) {
    if (event.target.closest("button")) event.preventDefault();
  });

  document.addEventListener("keydown", function (event) {
    const active = document.activeElement;
    if (active && active.tagName === "BUTTON") active.blur();
    if (event.code === "Space" || event.code === "ArrowRight" || event.code === "PageDown") {
      event.preventDefault();
      if (!event.repeat || busy) next();
    } else if (event.code === "ArrowLeft" || event.code === "PageUp") {
      event.preventDefault();
      prev();
    }
  });

  document.addEventListener("keyup", function (event) {
    if (event.code === "Space") event.preventDefault();
  });

  document.addEventListener("click", function (event) {
    const btnClicked = event.target.closest("button");
    if (btnClicked) btnClicked.blur();

    const look = event.target.closest(".look");
    if (look) {
      event.preventDefault();
      reveal(look);
      return;
    }

    const reset = event.target.closest(".timer-reset");
    if (reset) {
      const wrap = reset.closest(".timer-wrap");
      const t = wrap ? wrap.querySelector(".timer") : null;
      if (t) { resetTimer(t); cue("timerReset"); }
      return;
    }

    const timer = event.target.closest(".timer");
    if (timer) {
      toggleTimer(timer);
      return;
    }

    const tallyBtn = event.target.closest(".tally button");
    if (tallyBtn) {
      const num = tallyBtn.closest(".tally").querySelector(".tally-num");
      const v = parseInt(num.textContent, 10) || 0;
      const down = tallyBtn.classList.contains("tally-minus");
      num.textContent = String(Math.max(0, v + (down ? -1 : 1)));
      cue(down ? "tallyDown" : "tallyUp");
      return;
    }

    const jump = event.target.closest("[data-jump]");
    if (jump) {
      const index = findScene(jump.getAttribute("data-jump"));
      goJump(index, jump.hasAttribute("data-remember"));
      return;
    }

    const pick = event.target.closest(".chip, .choice");
    if (pick) {
      const group = pick.parentElement;
      Array.from(group.children).forEach(function (node) {
        node.classList.remove("picked", "ok", "no");
      });
      pick.classList.add("picked");
      if (pick.getAttribute("data-ok") === "1") { pick.classList.add("ok"); cue("pickOk"); }
      else if (pick.getAttribute("data-ok") === "0") { pick.classList.add("no"); cue("pickNo"); }
      else cue("pick");
      return;
    }

    if (localTarget(event.target)) return;
    next();
  });

  if (prevBtn) {
    prevBtn.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      prev();
    });
  }
  if (nextBtn) {
    nextBtn.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      next();
    });
  }

  if (!scenes.length) return;
  showScene(0, 0, true);

  // Test hook (read-only state) for local QA scripts.
  window.__deck = {
    state: function () {
      return { si: si, bi: bi, id: scenes[si].id, title: scenes[si].getAttribute("data-title"), busy: busy, beats: beats(scenes[si]).length, scenes: scenes.length, trail: trail.length };
    },
    go: function (i, b) { showScene(i, b || 0, false); }
  };
})();
