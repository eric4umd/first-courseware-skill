---
name: eric-teaching-stage
description: '【教学网页·有声】Build teacher-controlled HTML classroom decks (D3 Index Cards look) with synthesized sound effects and natural-voice listening audio, offline, one teaching move per beat. Use for any new Stage / 讲解 HTML, and for any lesson whose listening task needs a real-sounding American-English voice.'
---

# Eric Teaching Stage

Companion Skill for the 「Eric带你学AI」 teaching tutorials. Read [the repository guide](https://github.com/eric4umd/first-courseware-skill#readme) for installation and dependencies. Use the directory containing this file as `SKILL_ROOT`; commands below run from that directory.

Build a classroom deck that looks and feels like a finished product: D3 Index Cards visuals, soft sound design, and a listening player that speaks like a person. Everything runs from a double-clicked `lesson.html`, offline, in Safari, Chrome and screen share.

Scope: a deck for one lesson (or one part of it). Lesson content, answers and teacher guidance stay in the lesson package (教案 / PDF); the deck only shows what the student may see. Student names, EC numbers and personality labels never appear on screen.

**Use.** Build new classroom HTML from an agreed lesson or handout. Preserve any accepted deck in a separate version when adding audio or changing its design. This public package does not require Eric's private teaching workspace.

## What you get

| Piece | Where | Notes |
|---|---|---|
| Runtime (CSS, JS, GSAP, fonts) | `assets/runtime/` | self-contained, no CDN; Teaching Press Sans (OFL) + Noto Sans SC |
| Sound effects | `js/stage-audio.js` | 18 cues synthesized with Web Audio (no files, no licences); M mutes; quiet by design |
| Listening player | `.listen` component | Play 1 → audio → 45 s gap ring → Play 2 → done; P key; never autoplays; no transcript; silent apart from the recording (bells are opt-in: `listening(..., chime=True)`) |
| Scene components | `scripts/stage_kit.py` | cover, route, rules, rewrite + 看对照, divider, question + Stuck?, steps, check-card family, ladder, note grid, listening, compare table, homework, send, closing |
| Audio tool | `scripts/stage_tts.py` | script → natural-voice mp3 (multi-speaker), Whisper round-trip check, voice audition sheet |
| Acceptance run | `scripts/qa_deck.js` + `scripts/qa_flow.js` | Chromium **and WebKit**: layout, cues, mute, offline, transcript-leak (qa_deck) · whole-lesson teacher run-through, every reveal and branch, listening hold and player flow (qa_flow) |
| Sound Lab | `assets/templates/sfx-lab.html` | every cue on a button with its measured peak level — for the teacher to audition |
| Worked example | `examples/sample-deck/` | fictional lesson using every component |
| Style layers | `references/themes.md`, `assets/themes/` | Four optional looks: `marginalia`, `grid`, `studio`, `exam`. All themes include their font resources. Marginalia subsets its bundled CJK sources per deck and requires fontTools and brotli. Local theme-development previews are outside this package. |

## Workflow

1. **Content first, then a scene ledger.** Have the lesson's content spec (Markdown) and the exact listening script. The deck follows the spec; it does not invent tasks. Before building, write one line per scene: *what the teacher does here · what the student does or learns here · where the answer is shown*. A scene that cannot fill all three is not a page — merge it, cut it, or fix it. Any jargon the lesson introduces (a "Check Card", "three passes", an ABC ladder) needs a page that shows **why** with one worked example, not just a label (`why_passes`); if the teacher would have to explain a page out loud, the page is unfinished.
2. **Scaffold.** `python3 scripts/stage_scaffold.py <lesson>/06_讲解网页-有声版 [--theme marginalia|grid|studio|exam]` copies the runtime, `stage_kit.py` and the sample `build.py` (no `--theme` = the D3 look). Replace the CONTENT block; keep the component calls. Read [scenes](references/scenes.md) to pick components, [design](references/design.md) before departing from them.
3. **Listening audio** (only if the lesson listens). Read [listening-audio](references/listening-audio.md): write for the ear, tag speakers, mark numbers `204{two oh four}`, then
   `~/.local/share/eric-stage-tts/venv/bin/python scripts/stage_tts.py render listening.txt audio/listening.mp3 --voice dana=@female`
   and **always** run `check` (Whisper round trip) — numbers, prices, times and spellings are what the task tests. First read `scripts/stage_setup.sh`: it installs dependencies and downloads models. Run it only with the user's approval.
4. **Voice audition.** If the voice is not already chosen, run `stage_tts.py audition` on the real script and open the sheet for the teacher. Do not autoplay. You cannot hear audio; "sounds human" is the teacher's call, never yours. Save his pick in `~/.local/share/eric-stage-tts/voices.json`.
5. **Build** `python3 build.py`, then open it in the teacher's intended browser. Safari is the reference browser used in the tutorials.
6. **QA — both scripts, both browsers.**
   `node scripts/qa_flow.js lesson.html` teaches the whole lesson with real key presses and clicks: every scene is reached in order, every 看对照 shows a non-empty answer, timers/tallies/choices respond, every menu card walks its branch and returns, rail and footer jumps land, the listening page holds an early Space, and the player runs Play 1 → gap → Play 2 → done.
   `node scripts/qa_deck.js lesson.html --script listening.txt` checks layout at 1920×1080 and 1280×720, sound cues, mute, offline, and that no transcript is on screen.
   Both need Playwright on Node's module search path. For a global installation, use `NODE_PATH="$(npm root -g)"`; use an existing local installation when available. On macOS, Chromium QA must use the installed headless shell via the default `chromium.launch({ headless: true })`; do not set a Chrome app executable or browser channel. Fix every FAIL, then look at the screenshots at full size — a pass is not a design review. A mutation check (break an answer or remove the hold, expect FAIL) shows the tests still bite.
7. **Report honestly**: what ran (which browsers, sizes, checks), what was not heard or not tried (audio quality, real screen share, a real student), what is provisional (voice, timings).

## Before you build

Read [pitfalls](references/pitfalls.md) for implementation and testing notes. The three that matter most for a new lesson: a page that needs a spoken explanation is unfinished; every task with a key must be checkable on screen; **timers are opt-in** (only silent, time-boxed student work of a few minutes — never a spoken answer, a warm-up line or a log).

## Hard rules

- **One teaching move per beat.** Space / → / click on empty paper = next beat; ← = back; a press during a tween only completes it. Controls (timers, 看对照, player, sound button) never advance.
- **Every task with a key can be checked on screen.** Answers appear only behind 看对照, one item at a time — including listening questions (`listen_question(answer=…)`), each cell of the note grid (`note_check`) and reference writing (`model_text`). A task page without a way to show its answer is a defect. The listening *transcript* is never visible until a deliberate 看原文 after the check; QA's `--script` test enforces that.
- **Listening is one page: note grid + player.** The student sees what to catch while the teacher plays (`note_listen`). Never put the player on a page the teacher can click past by accident: the runtime holds the first Space/→ on an unfinished listening task, flashes the player and says why; a second press within 5 s really leaves.
- **Offline `file://`**: inline-able local assets only; no CDN, no network at class time. Audio is a local mp3 loaded by an `<audio>` element (not `fetch`/`decodeAudioData`, which fail on `file://`).
- **Sound is quiet and optional.** Effects peak about −14 to −28 dBFS, are skipped while listening audio plays, and M toggles them; the listening audio is separate and never muted by M. Nothing autoplays; audio starts only from a click or P. Never play audio on the user's machine without permission.
- **Online class:** Tencent Meeting (and Zoom) carry computer sound only if 共享电脑声音 is ticked when sharing the screen. Put this in the teacher notes for any lesson with audio. Effects are tiny and may be squeezed by call compression; the listening clip is the thing that must be heard clearly — say so and have a fallback (teacher reads the script aloud; the deck's status line says so if the file fails to load).
- **Timers are rare and never auto-advance.** Use one only for silent, time-boxed student work (writing, self-check, break, a silent write-down). Components default to no timer (`secs=None`); a timer on every page is clutter. They ring at zero; the teacher moves on.
- **Reduced motion** shows the beat without a tween; sound is unaffected.
- **Readable on a shared screen:** English examples sans-serif, meaning never by colour alone, and look at 1280×720. Floors in the runtime: labels ≥ 13 px, hint / Chinese gloss ≥ 14 px (side rail 12 px); `qa_deck.js` fails in-scene text under 12.5 px. New components must keep the `max(13px, …)` pattern.
- Student-facing English uses US spelling and words (football stays football).

## Voice policy

Default engine: **edge**, using Microsoft neural voices through `edge-tts`. Rendering requires internet and uses an unofficial service endpoint whose availability and permitted uses must be checked by the user. **kokoro** is an optional local engine; setup downloads its model and voice files before offline use. **eleven** uses ElevenLabs and is optional and paid: it requires `ELEVENLABS_API_KEY` in the process environment and explicit approval for the cost. No API key is bundled. The default accent is en-US; choose a different accent when the lesson requires it. Let the teacher audition the output before classroom use.

## Files not to forget

`SOURCES.md` (font and library licences) ships inside every deck folder. Generated audio is AI-synthesized: say so in the lesson's teacher notes. Keep `listening.txt` (the script with `{spoken}` markup) next to the audio so the clip can be re-rendered.
