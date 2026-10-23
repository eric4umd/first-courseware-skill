# Theme layers

A style is **one CSS file** (`css/theme-<name>.css`) loaded after the runtime, selected with `K.page(..., theme="<name>")` (which sets `<html data-theme="<name>">`). The DOM, behaviour, listening player, components and both QA scripts are shared, so every pitfall already fixed in the engine carries into every style. Never fork a deck into a new style; add a theme file.

**Compose every scene for its theme.** Each theme must give *every* scene the skill can produce its own composition, type, motion (`--mo-style`) and sound palette (`PALETTES` in `stage-audio.js`, keyed by `data-theme`). Five hand-picked pages are not enough; the fixture below covers all of them.

**Included themes.** The built files live in `assets/themes/` (`theme-<name>.css`, `fonts-<name>/`, `SOURCES.md`); this is the only built copy. They are kept out of `assets/runtime/` on purpose: the runtime is copied into every deck and into every runtime update, and a deck needs only the look it uses.

```
python3 scripts/stage_scaffold.py <folder> --theme grid   # new deck: runtime + theme css + fonts + build.py already themed
python3 scripts/stage_theme.py install <deck> <name>      # add a look to an existing deck (then K.page(..., theme="<name>"))
python3 scripts/stage_theme.py fonts   <deck> <name>      # Chinese subset (Marginalia): re-run after every text change; build.py does it
python3 scripts/stage_theme.py check   <deck> <name>      # css linked, every font file exists, subset resolved
```
Run these commands from this Skill's directory. The default D3 look and Grid, Studio and Exam have bundled runtime resources. Marginalia includes Noto Serif SC Regular/SemiBold and Zhuque Fangsong sources in `assets/themes/cjk-sources/`. It needs fontTools and brotli to subset them per deck. The scaffolder copies these sources to `font-sources/` in the new deck so later rebuilds remain independent of the Skill installation.

## The four works (+ the D3 baseline)

| Theme | One line | Latin / CJK type | Motion · sound |
|---|---|---|---|
| *(none)* D3 Index Cards | Approved baseline: paper, navy, tomato/mustard, offset shadows, cassette cover | Teaching Press Sans + Noto Sans SC | `rise` · shared set |
| `marginalia` | An annotated reader: bound book, folio, running heads, marginal notes in a pen hand | Lora, Instrument Serif, Nothing You Could Do · Noto Serif SC + Zhuque Fangsong (deck subset) | `ink` · paper and pencil |
| `grid` | Swiss poster: a numeral spine, heavy rules, flat colour blocks, no boxes | Instrument Sans, DM Mono · Noto Sans SC | `snap` · clicks and ratchets |
| `studio` | A broadcast control room: ON AIR, cue list, clapperboard, VU meter | Big Shoulders, Outfit, Geist Mono · Noto Sans SC | `light` · warm thumps, swells, pads |
| `exam` | A generic computer-based test centre (not any exam board's UI) | Work Sans, IBM Plex Serif, IBM Plex Mono · Noto Sans SC | `cut` · almost silent ticks |

All fonts are OFL; each theme's Latin fonts are pre-subset woff2 in `assets/themes/fonts-<theme>/` with the licence texts (and a section per theme in `assets/themes/SOURCES.md`, copied into a deck's `SOURCES.md` on install). Functional cues (pick/tally, timer start/pause, and, when a deck opts in with `chime=True`, `listenStart` / `gapDone` / `done`) are shared by every palette so a student always recognises them; the listening player itself is silent by default. Never animate `filter: blur` on large beats (stutters in Safari under screen share).

### Marginalia — annotated reader
- **Palette**: paper `#f2e9d3`, ink `#2a211c`, oxblood `#8c2f39`, highlighter `#f3da6a`, bottle green `#3f6b57`, pen blue `#2d4a7a`, page `#fffbf0`.
- **Composition**: gutter and stitches down the left; folio "— nn —" in the footer; part tabs are small-caps running-head pills with a section sign; cover is a double-framed title page with a chapter numeral, the closing is "Finis"; route is a table of contents (dotted leaders, italic numerals, durations); rules are numbered paragraphs without boxes; questions are a printed page with a **margin column** (steps note and hints in the hand font); fixes are marked in red ink with a wavy underline; the divider is a chapter head; listening art is a vinyl record that spins while playing; notes are writing pads with red-pen answers; tables are double-ruled ledgers.
- **Watch**: Zhuque Fangsong is only used for short CJK flourishes; never exceed the deck subset (rerun `stage_fonts.py` after content changes).

### Grid — Swiss poster
- **Palette**: paper `#f3f2ee`, black, cobalt `#2442ff`, signal yellow `#ffd60a`, red `#ff3d1f`, green `#00875a`; colour is information (part / code), never decoration.
- **Composition**: every page with a header hangs on a **spine** — big page numeral and part name (`attr(data-no)`, `attr(data-part-label)`) beside a vertical rule; header band at the top with the position label and a numbered text index instead of side tabs; prompts have no box, only a heavy top rule over very large type with the tool column ruled off on the right; route is a timetable with colour squares; rules are four columns of numerals; dividers are a colour block with a giant letter (`data-side`); cover is a poster with a cobalt art block; notes use writing lines, tables are ruled with no frame.
- **Watch**: very large type needs `text-wrap: balance`; questions are sized for ~170 characters (4.2u) — re-check long prompts.

### Studio — broadcast control room
- **Palette**: paper `#080a11`, ink `#f2ede3`, tomato `#ff5a4a`, amber `#ffb43a`, teal `#35d6a0`, sky `#4fb7ff`, lilac `#a48bff`, surface `#141929`.
- **Composition**: the stage light follows the current part (`:has()` on the rail tab); cover is an ON AIR neon sign, closing is OFF AIR; route is a run-of-show with duration boxes; rules are a pre-flight 2×2; divider is a clapperboard slate (`data-top`/`data-main`); `again` is a TAKE-2 clapper bar; prompt cards carry viewfinder brackets and teleprompter marks; the rail is a cue list and the footer prints `CUE nn / total`; listening art is a VU meter whose needle swings while playing; timers are LEDs (green running, red done).
- **Watch**: the VU art depends on `:has(.ls.is-playing)`; dark theme — `.c-*` coloured blocks need an explicit dark ink.

### Exam — test centre
- **Palette**: canvas `#e3e8ef`, white panels, ink `#1b2430`, toolbar `#1f2a37`, accent blue `#1f5fbf`, green `#1d7a5f`, red `#c0392b`.
- **Composition**: toolbar with a "Page nn of N" counter on the left and part tabs on the right (no side rail), instruction strip under it, grey bottom bar with flat white buttons and a blue Next; cover and break/again/closing are **dialogs** with a title bar; route is a test-overview table; rules are panels with header strips ("Rule n"); questions are a **split pane** (Instructions panel left, question panel right with a dashed "answer" area); fix/make/ba are stacked panels; answers open as a green "key" panel; listening is a headset panel plus a media-player bar; notes are form fields; the big timer is a "Time remaining" clock.
- **Watch**: the counter says "Page", not "Question", because the panels already number questions within a round; the interface copy ("Instructions", "Select ▸") is invented, not any real exam's.

## Preview and check a theme

The original `styles-preview/` gallery and theme-development scripts are outside this repository. Use the bundled fictional sample to preview a theme:

```bash
python3 scripts/stage_scaffold.py /path/to/new-preview --theme grid
python3 /path/to/new-preview/build.py
python3 scripts/stage_theme.py check /path/to/new-preview grid
```

Open the resulting `lesson.html` in your intended browser. With an existing Playwright installation, run `qa_deck.js` and `qa_flow.js` from `scripts/`. Check the real lesson too: long text and larger menus can expose problems absent from the sample. Inspect every scene and its opened answer states at 1920×1080 and 1280×720.

Theme CSS and bundled Latin fonts are in `assets/themes/`. Edit copies in a new preview folder. The `/*@FONTS*/` marker is filled by `stage_theme.py fonts` for Marginalia after each content change.

## Additive hooks (only when `theme` is set; D3 ignores them)

`K.page(..., theme=…)` stamps the scenes so CSS can print structure without new markup:
- every `<section class="scene…">`: `data-no` (main-path number; branch scenes carry their anchor's number), `data-total`, `data-part-label`;
- `deck.js` copies those three onto `#pos` (`.nav .mid`) so CSS can print `content: attr(data-no)`;
- `route()` stations: `data-mins`; `divider()` `.div-art`: `data-top/main/side`; `listening()` `.listen-art`: `data-top/main`; `cover()` / `closing()` `.art-card`: `data-label`.

Motion personality is the CSS variable `--mo-style` (`rise | ink | snap | light | cut`, read once by `deck.js`); sound palette is chosen from `data-theme` by `stage-audio.js` (`StageAudio.usePalette(name)` in the Sound Lab).

## Density tiers (how many stops / cards a scene can hold)

Recheck the actual route, menu and check-card counts in your deck at 1280×720 and 1920×1080. Split routes beyond 8 stops and menus beyond 6 cards. The CSS uses item-count tiers; the original development stress scripts are outside this package.

| Theme | Route (stops) | Menu (cards) | Check card |
|---|---|---|---|
| `marginalia` | 5: compact two-line rows · 6–7: airy one-line contents with dotted leaders · 8+: tight | fits 1–6 as is | fits as is |
| `studio` | 5–6: dot 4.4u · 7+: dot 3.4u; no empty minutes pill | fits 1–6 as is | fits as is |
| `exam` | 5–6 and 7+ tighter table rows; no "Time" header without `data-mins` | rows `minmax(0, 9.4u)`; 4+ cards shrink the letter block | fits as is |
| `grid` | 7+: smaller numeral block | 5–6 cards: three columns · 7+: four | a 3-pass card: title 3.2u (one line) and tighter card chrome; `.cc-rule` stays ≥ 14 px |

The long-rule check card (N and J cards with 100+ characters in a column one fifth wide) is the worst case; keep it in any real-deck test.

## What a theme overrides

1. **Tokens** on `:root[data-theme="x"]`: `--paper --navy(ink) --navy-2 --muted --tomato --mustard --teal --sky --lilac --white(card surface) --*-t(tints) --bw --off --r --r-sm --font --rail --mo-style`. `--off: 0px` removes every offset shadow; `--r: 0` squares everything; `--rail: 0px` frees the side rail for a top bar.
2. **Every scene type** — cover, route, rules4, rewrite, divider, question (+ hints, stretch), steps3, why-passes, check card, menu, S/J blocks, again, before/after, break, listening divider and player, note grid, note+player, listen question, note check, compare table, task card, ladder, timed task, model text, homework, send-two, closing — plus the opened states (reveal panels, Stuck? hints, player modes, timer running/done).
3. **Cover art**: hide `.art-card .recorder, .waves` or recolour `.art-card`; paint new art as an inline SVG data URI in the copied CSS (no external fonts inside it). The original `theme_art.py` development helper is outside this package.
4. **Fonts**: `@font-face` at the top; CJK serif/other big fonts must be subset to the deck (`scripts/stage_fonts.py`), re-run after every content change.

## Rules that keep a theme honest

- Keep the readability floors (labels ≥ 13 px, hints ≥ 14 px at 720p); `qa_deck.js` fails below 12.5 px.
- `--navy` is the *ink* token, `--white` the *surface* token. In a dark theme both flip, so `.c-* / .p-*` coloured blocks (they use `color: var(--white)`) need an explicit dark ink; and `--navy-2` is used both as a fill and as a text colour — pick a mid value that works for both.
- `.badge` appears as a circle number (`.badge`) **and** as a coloured label (`.badge.big.c-*`) **and** as `.badge.q-badge`. Override the circle with `.badge:not(.big):not(.q-badge)` only, and give `.badge.q-badge` its own `width/height: auto`.
- `.c-*` colour classes are more specific than most rail/head rules; override with `§ .rail .rail-tab` rather than `§ .rail-tab`.
- Base grids inherit `align-items`; if rows misalign in a re-composed layout, set `align-items: stretch` explicitly.
- `.passes` (check card) is `3fr 1fr 1fr` in the base; themes use `display:flex` with `:has(.code-card:nth-child(n))` so column width follows card count.
- Gradients on `.index-card` need `background-repeat: no-repeat` and explicit positions, or a 1 px rule tiles into a solid fill.
- To paint a bar past the deck box use `box-shadow`, not negative margins; `qa_deck.js` flags anything that leaves the deck box.
- A theme changes look, never meaning: no colour-only meaning, same text, same controls, same keys.
- Long prompts (≈170 characters) must still fit; check the long-question scene at 720p before accepting a type size.
- Never size a list scene for the fixture's count. Add count tiers for routes and menus, and don't rely on `justify-content: center` for a column that can overflow (it grows upward over the title). Guard hooks a deck may not set: `.station:not([data-mins])::after { display: none }`.
- `.route-break` (the Break pill) is absent from the gallery; place it on the row rule inside each theme's route and check it with a real deck.

## Choosing a theme

Build a preview from the bundled sample, then preview representative pages from the actual lesson. Ask the teacher to choose or refine a look when that choice matters. Keep the accepted deck in its own version.
