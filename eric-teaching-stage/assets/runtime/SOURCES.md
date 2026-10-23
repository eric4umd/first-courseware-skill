# Sources and licenses

Everything here is bundled for offline use from `file://`. There is no CDN, no web font service and no build step.

| Asset | Files | Role | Source | License |
|---|---|---|---|---|
| Teaching Press Sans | `fonts/TeachingPressSans-{Regular,Medium,SemiBold,Bold,Black}.ttf` | English and UI type, 400–900 | Copied from the eric-teaching-press skill `assets/fonts/`. These are static instances generated locally from Inter 4.001 (optical size 14) and renamed Teaching Press Sans. | SIL OFL 1.1, `fonts/OFL-teaching-press-sans.txt` (Copyright 2020 The Inter Project Authors) |
| Noto Sans SC | `fonts/noto-sans-sc-400.woff2`, `fonts/noto-sans-sc-600.woff2` | Chinese fallback when PingFang SC isn't installed | Copied from the accepted Lesson 2 deck (fontsource `noto-sans-sc@5.2.8`) | SIL OFL 1.1, `fonts/OFL-noto-sans-sc.txt` (generic OFL text) |
| GSAP | `vendor/gsap.min.js` | Beat entrance tweens | GSAP 3.12.7, copied from the accepted Lesson 2 deck | GreenSock Standard "no charge" license, https://gsap.com/standard-license |

The font stack is `"Teaching Press Sans", "PingFang SC", "Noto Sans SC", sans-serif`. On a Mac, Chinese text uses PingFang SC; the bundled Noto Sans SC is only a fallback.

The icons, cassette, and tape recorder art are inline SVG drawn for this deck. No third-party images are used.
