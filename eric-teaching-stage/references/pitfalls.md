# Building and checking a classroom deck

These notes describe failure cases addressed by the bundled runtime. Use `scripts/qa_flow.js` and `scripts/qa_deck.js` for the automated checks; inspect the rendered lesson as well.

## Lesson design

- Explain an unfamiliar routine with a worked example. `why_passes` can show how checking one error type at a time changes a sentence. State when an order is a teaching choice.
- Give every question a usable answer reveal: `listen_question(answer=...)`, `note_check` for note cells, and `model_text` for reference writing. Each reveal should show enough text to check the answer.
- Keep the listening grid and its player on one page with `note_listen`. The first Space or arrow press on an unfinished listening task should hold that page; a second deliberate press may leave.
- Use timers only for time-limited student work. Components default to `secs=None`. A spoken answer, single example or log usually needs no timer.
- Before building, record what the teacher does, what the student does and where each answer appears. Walk through the result in the browser used for class.
- Use question numbers in student text. Keep private learner analysis and internal task codes out of the deck. A lesson plan does not establish attendance or mastery.

## Runtime and browser checks

- Load local audio through an `<audio>` element. `fetch` and `decodeAudioData` can fail on `file://`. Playback must start from a deliberate click or P key.
- Put the player in the first visible beat. A control hidden in an unrevealed beat cannot be used.
- Keep the timeline cleanup safe when completing a tween fires `onComplete`; that callback may clear the timeline reference. Test jumps during transitions after modifying animation code.
- CSS `:has()` needs a modern browser; Safari added it in 15.4. Check the actual classroom browser.
- The runtime suppresses sound effects while listening audio plays. The AudioContext starts after a user gesture, and local mute storage is guarded with try/catch. Do not add background music without a specific request.
- For online teaching, mention the meeting app's computer-sound sharing option and keep a teacher-read-aloud fallback in the teacher notes.
- Use Playwright's installed headless shell for automated Chromium checks on macOS. Do not launch a Chrome app bundle or set a Chrome browser channel. Also use WebKit when available; it shares Safari's browser engine. Obtain approval before installing missing browser runtimes.
- WebKit may reject `offline: true` with `file://`. Block external requests with `context.route` for offline tests.
- A pulsing Play 2 button may need `{ force: true }` in a test. Normal classroom clicks must work without special handling.
- Wait for transitions before inspecting screenshots. Use reduced motion for deterministic navigation checks and a separate check for rapid presses during animation.
- Distinguish visible overflow from intentional display typography. Check elements outside the deck separately from internally clipped boxes.
- Test an answer panel's actual text. A tick alone cannot explain a key. When changing a test, confirm that deleting an answer or removing the listening hold causes a failure.

## Audio

- A fresh scaffold includes `listening.txt` and an empty `audio/` folder. Its player needs `audio/listening.mp3`; full listening and console checks will fail until that file is rendered. A mechanics-only fixture may use a local test tone, clearly separated from classroom output.
- edge-tts rendering requires network access. The tool reads `HTTPS_PROXY`; an outdated package or service outage can also cause a failure. Check the reported error before changing dependencies.
- The Whisper checker decodes through FFmpeg. It canonicalizes number formats such as `6:30`, `6 30` and `3rd`. Read failures in context: an interjection such as “Oh, and…” is not a dictated zero.
- Mark intended spoken numbers with braces, such as `204{two oh four}`. Check names, numbers and spellings against the script after rendering.
- Let the teacher audition the voices and turn gaps. Automated transcription cannot judge whether delivery suits the class. Never autoplay on the user's machine.
- The setup script uses Python 3.12 for its audio environment. Inspect its dependency and model downloads before running it.
- Keep the listening script, generated audio and teacher notes together. The notes should identify synthesized audio and explain the playback fallback.

## Files and theme layouts

- Keep `build.py` beside the generated deck, and preserve an accepted version when trying a different look. Save later classroom observations only when the teacher supplies them.
- Small text can pass clipping tests and remain unreadable. At 1280×720, aim for labels at least 13 px and hints or Chinese glosses at least 14 px. Recheck real screen sharing separately.
- Theme CSS layers share the runtime and component markup. Check every scene type and opened answer state when changing a theme.
- Rebuild CJK font subsets after changing text. The Marginalia scaffolder preserves source fonts in `font-sources/` for subsequent rebuilds.
- In dark themes, inspect timer-done text, answer panels and player states. Ink and surface tokens change roles, and `.c-*` classes can override less specific rules.
- Preserve default motion and sound when adding theme hooks. Clean up every changed property (`clipPath`, `x`, `scale`) and verify reduced-motion behavior.
- The theme CSS in this repository is already built. Original theme preprocessors and development galleries are outside this package; edit a copy of the bundled CSS and preview it with the sample or actual lesson.
- Use selectors that distinguish `.badge`, `.badge.big` and `.badge.q-badge`. Set grid alignment explicitly where a theme recomposes rows or columns.
- Check long prompts around 170 characters at 1280×720 before increasing type size. Wait for an ink wipe to finish before judging a reveal.
- Check the real route and menu sizes. The CSS has count-based tiers for routes up to eight stops and menus up to six cards. Use `minmax(0, ...)` for shrinking rows and split larger lists into another scene.
- Centered columns can overflow upward. Guard empty `data-mins` hooks so they do not paint blank duration pills. Test a real break marker as well as ordinary route rows.
- Strip `{spoken form}` markers when deriving a visible transcript from `listening.txt`, as the sample builder does. Reveal the transcript only after the listening task is checked.
- Finish rebuilding before running QA so screenshots and checks all read the same files.
