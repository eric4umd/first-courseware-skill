# Design rules — D3 Index Cards on screen

Direction: warm paper, navy ink, six accent colours, offset "card" shadows, rail tabs on the right edge, cassette/recorder illustration. D3 is the default look in the 「Eric带你学AI」 classroom-deck tutorials.

## Tokens (in `css/deck.css :root`)
paper `#fff8ec` · navy `#1d2a4d` · navy-2 `#2d3d6b` · muted `#6a7390` · tomato `#ee5b3e` · mustard `#f3b23b` · teal `#169c86` · sky `#4a98e6` · lilac `#8574d4`; tints `*-t`. Unit `--u` = 1/100 of the 16:9 box that fits the window, so 1920×1080 and 1280×720 are the same layout. Border `0.15u`, offset shadow `0.42u`.

## Type
Teaching Press Sans (Inter derivative, OFL) for Latin, PingFang SC → Noto Sans SC for Chinese; weights 400–900. Titles 700–900 with tight tracking; English examples are sans-serif; the question card text is the largest thing on a question scene. Font files and licences ship in `fonts/` and `SOURCES.md`.

## Rhythm
Header strip (pill + Chinese kicker + right slot) → one hero card or a row of cards → tool row (timer / reveal / hints). Colour = the lesson's part (warm-up mustard, round 1 tomato, writing teal, listening sky, round 3 lilac, home navy); use the same colour for the pill, badge and rail tab. Icons are drawn as inline SVG (no emoji, no icon fonts). Never let a scene scroll; if text will not fit, split the beat.

## Motion
Beat entrance 0.55 s `power2.out`, scene fade 0.24 s; reel rotation and level bars are decorative and stop under reduced motion. Do not add parallax or scroll effects: the room is a projector or a screen share, motion costs bitrate.

## When to depart
New visual territory (a different book skin, a different palette) is a separate design decision for the teacher: make an alternative scene or sample, keep the accepted deck as the baseline, and say what changed. The `eric-teaching-press` D1/D2 skins exist for paper; the deck also includes optional themes described in [themes.md](themes.md).

## Review
Open the real deck at 1080p and 720p; look at the cover, the busiest scene, a timer scene, the listening scene and the closing. Check that body Chinese is readable at 1280×720 (the usual weak spot is small hint text); say which scenes you inspected. Say which scenes you inspected and which you did not.
