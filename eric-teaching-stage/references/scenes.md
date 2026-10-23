# Scene catalog (`stage_kit.py`)

Each function returns one `<section class="scene …">`. `scene` type drives layout: `cover` (hero), `teach`, `judge` (a question card), `rewrite` (prompt + reveal), `choose` (card menu). A scene's `part` ties it to a rail tab; exactly one scene per part needs `data-block=<part>` (dividers, `rules4`, `homework` set it) so the rail can jump there.

| Teaching move | Component | Notes |
|---|---|---|
| Opening / closing | `cover`, `closing` | recorder art; closing is the last scene |
| Where we are going | `route` | ≤ 6 stations; `break_after=` floats a Break chip |
| Ground rules for a task | `rules4` | four icon cards, one beat each |
| Translate / reformulate with reveal | `rewrite` | timer + `.look` (看对照) reference box |
| Section opener | `divider` | cassette + big title; sets the rail block |
| Spoken question | `question` | timer, REC chip, optional `stuck_hints` scaffold (A/B/C) — hints never contain the answer |
| Process in 3 steps | `steps3` | icon cards with arrows |
| Why a routine works (worked example) | `why_passes` | one sentence with N mistakes; each pass highlights the one it finds; use before a check card or any multi-step routine |
| Self-check order | `Codes.check_card_scene` | colour-coded error codes in passes (verbs → nouns → joins) |
| Choose the mini-lesson | `Codes.menu_scene` + `Codes.block` | menu → rule → three cold fixes → make your own → back to the main line (branch scenes are excluded from progress) |
| Writing task | `task_card`, `timed_task`, `ladder` | big timer; a 3–4 rung ladder for paragraph structure |
| Revision evidence | `before_after` | "改前 → 改后" with reveal |
| Break | `break_scene` | five-minute timer |
| Listening (the task page) | `note_listen` | note-grid headings + compact player on ONE page; the student writes on paper |
| Listening (player only, e.g. a prop clip) | `listening` | cassette + large player; see listening-audio.md |
| Answer in full sentences | `listen_question(answer=…)` | question card with 看对照 model answer; optional focus pill ("Careful") |
| Check the notes | `note_check` | each note cell has its own 看对照; last, 看原文 reveals the transcript |
| Reference writing | `model_text` | colour-tagged segments (Side / A / B / C) behind one button |
| Compare two attempts | `compare_table` | blanks for the student's paper; note says not to grade across topics |
| Homework | `homework`, `send_two` | Daily Menu cards; what to send back |

Beat design: put everything the teacher reveals separately inside its own `data-beat`. A scene with no `data-beat` shows at once. Reveal controls (`.look`, `.stuck-btn`) belong inside a beat's container; the `.contrast` box is `hidden` until pressed and resets when the scene is left.

Interactive extras the runtime already handles: timers (`.timer`), tallies (`.tally` with +/−), choice chips (`.chip`/`.choice` with `data-ok="1|0"`), jumps (`data-jump="sceneId"`, `data-remember` to come back with ←), `data-next` / `data-prev` routing for branches.

Writing the content: the on-screen prompt is Chinese for instructions and English for the task language; keep one idea per card, ≤ 12 words in a heading, 1 line of Chinese hint. A reference answer is "参考（不是唯一答案）". Avoid raw question codes (B1, A2) on student-facing text — the teaching-polish validator flags them; number questions 1–3 instead.

Timers: `timer(sec)` exists as a component, but `rewrite`, `question`, `before_after` and `check_card_scene` take `secs=None` by default. Add a timer only for silent, time-boxed work (see pitfalls.md #4).
