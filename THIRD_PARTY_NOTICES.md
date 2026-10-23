# Third-party resources

The repository accompanies the 「Eric带你学AI」 teaching tutorials. Original project material has no repository-wide license selected. The resources below retain their own licenses.

## Fonts

Teaching Press Sans is a renamed static derivative of Inter. Noto Serif SC, Noto Sans SC and the theme font families are distributed with SIL Open Font License files in the corresponding `fonts/` or `fonts-<theme>/` directories. Keep these notices with copies of the font files. See the detailed [Press font notes](eric-teaching-press/references/fonts.md), [Stage runtime sources](eric-teaching-stage/assets/runtime/SOURCES.md) and [theme sources](eric-teaching-stage/assets/themes/SOURCES.md).

Instrument Serif's license is from the [Google Fonts source](https://github.com/google/fonts/blob/main/ofl/instrumentserif/OFL.txt), with copyright belonging to the Instrument Serif Project Authors.

macOS system fonts are referenced by some templates and are not distributed here. Check the applicable font rights before distributing PDFs made with them. The optional Marginalia Stage theme includes CJK font sources and subsets them per deck with fontTools and brotli.

## GSAP 3.12.7

`eric-teaching-stage/assets/runtime/vendor/gsap.min.js` retains the original GreenSock copyright header and its [license link](https://gsap.com/standard-license). Review those terms for the intended use; GSAP is not covered by the font licenses or any future license chosen for this project's original files.

## Audio engines and other tools

No API credentials are included. `stage_setup.sh` can install Python dependencies and download Kokoro model files from upstream. These are separate downloads with their own terms. Read the script and obtain approval before installing. edge-tts uses an online, unofficial service endpoint; ElevenLabs is optional and paid. Generated audio is not bundled with the sample lesson.
