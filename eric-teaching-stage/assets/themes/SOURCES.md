# Theme fonts: sources and licences

Each theme ships `theme-<name>.css` plus `fonts-<name>/`. `stage_theme.py install` copies both into a deck and adds the matching
section below to that deck's `SOURCES.md`. Everything is bundled for offline use from `file://`; nothing loads from a network.
All fonts are SIL OFL 1.1 (the licence text sits beside the font files in `fonts-<name>/`). Latin faces are static instances
subset to Latin and Latin punctuation (about 10–30 KB per face, woff2) prepared from OFL font families. The original font-subsetting development scripts are outside this repository. Chinese text uses `Noto Sans SC` from the runtime unless noted.

## Theme: marginalia

| Asset | Files | Role | Licence |
|---|---|---|---|
| Lora 400 / 400 italic / 700 | `fonts/lora-*.woff2` | running text, answers | OFL 1.1, `fonts/OFL-Lora.txt` |
| Instrument Serif 400 / italic | `fonts/instrument-serif-*.woff2` | titles | OFL 1.1, `fonts/OFL-InstrumentSerif.txt` |
| Nothing You Could Do 400 | `fonts/nothing-you-could-do-400.woff2` | margin notes in a pen hand | OFL 1.1, `fonts/OFL-NothingYouCouldDo.txt` |
| Noto Serif SC 400 / 600, Zhuque Fangsong 400 | `fonts/NotoSerifSC-*-sub.woff2`, `fonts/ZhuqueFangsong-*-sub.woff2` | Chinese text, short Chinese flourishes | OFL 1.1, `fonts/OFL-NotoSerifSC-ZhuqueFangsong.txt`; subset **per deck** by `stage_theme.py fonts` from bundled `assets/themes/cjk-sources/` files (the deck's own characters plus about 200 safe ones, so a late text edit does not show tofu; re-run after content changes) |

## Theme: grid

| Asset | Files | Role | Licence |
|---|---|---|---|
| Instrument Sans 400 / 400i / 700 / 700i | `fonts/instrument-sans-*.woff2` | all Latin type | OFL 1.1, `fonts/OFL-InstrumentSans.txt` |
| DM Mono 400 | `fonts/dm-mono-400.woff2` | labels, numerals, times | OFL 1.1, `fonts/OFL-DMMono.txt` |

## Theme: studio

| Asset | Files | Role | Licence |
|---|---|---|---|
| Big Shoulders 400 / 700 | `fonts/big-shoulders-*.woff2` | display titles | OFL 1.1, `fonts/OFL-BigShoulders.txt` |
| Outfit 400 / 700 | `fonts/outfit-*.woff2` | text | OFL 1.1, `fonts/OFL-Outfit.txt` |
| Geist Mono 400 / 700 | `fonts/geist-mono-*.woff2` | cue labels, LED timers | OFL 1.1, `fonts/OFL-GeistMono.txt` |

## Theme: exam

| Asset | Files | Role | Licence |
|---|---|---|---|
| Work Sans 400 / 400i / 700 | `fonts/work-sans-*.woff2` | interface and headings | OFL 1.1, `fonts/OFL-WorkSans.txt` |
| IBM Plex Serif 400 / 400i / 700 | `fonts/plex-serif-*.woff2` | question text | OFL 1.1 (the Plex family text is `fonts/OFL-IBMPlexMono.txt`) |
| IBM Plex Mono 400 / 700 | `fonts/plex-mono-*.woff2` | numerals, timers | OFL 1.1, `fonts/OFL-IBMPlexMono.txt` |

## CJK font sources

`cjk-sources/` contains Noto Serif SC Regular/SemiBold and Zhuque Fangsong Regular for per-deck subsetting. Copyright and license notices are in that directory and in the source font metadata. `stage_scaffold.py --theme marginalia` copies this directory into the generated deck as `font-sources/`; retain it when rebuilding the deck.
