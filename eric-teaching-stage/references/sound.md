# Sound design

All cues are generated live by `stage-audio.js` (Web Audio) so they work offline with no licences. Theme: paper index cards + a cassette recorder.

| Cue | When | Sound | Peak (dBFS, measured offline) |
|---|---|---|---|
| beat | next beat | soft paper tap | −20 |
| scene | next scene / jump | card slides, lands | −19.5 |
| back | previous | reverse brush | −28 |
| reveal | 看对照 / Stuck? | two mallet notes | −19 |
| pick / pickOk / pickNo | choice chips | tick / bright pair / soft wooden knock (never harsh) | −25 / −20 / −20 |
| tallyUp / tallyDown | counters | rising / falling pop | −22 / −23 |
| timerStart / Pause / Reset | timer | cassette PLAY key click-thunk / single click / short rewind | −17.5 / −21 / −29 |
| timerDone | zero | two-note bell, twice, ~1.8 s | −13 |
| listenStart | before clip (only with `data-chime="1"`) | exam-style two-tone chime | −14 |
| gapDone | gap over (only with `data-chime="1"`) | rising three notes | −18 |
| done | both plays done (only with `data-chime="1"`) | small fanfare | −17 |
| on / off | M key | confirmation | −21 / −24 |

Rules: the three listening cues above belong to the player and are **off by default** (`stage_kit.listening(chime=True)` turns them on for a deck); effects are suppressed while listening audio plays; `M` toggles and persists in `localStorage` (wrapped in try/catch); the AudioContext starts only after a user gesture; default master volume 0.8, adjustable in the Sound Lab. Key-repeat guard 30 ms.

Adding a cue: add a function to `CUES` in `stage-audio.js` (schedule with `tone`, `noise`, `mallet`, `bell`), keep it under ~1.8 s, check its peak in the Sound Lab (`renderCue` measures offline), then call `StageAudio.cue("name")` from the runtime. Do not use sound to signal wrong answers harshly; do not add music beds (they fight the listening clip and the call codec).

Sound Lab: copy `assets/templates/sfx-lab.html` next to the runtime, replace `__LISTEN_SRC__` and `__GAP__`, open in Safari. Nothing plays by itself.
