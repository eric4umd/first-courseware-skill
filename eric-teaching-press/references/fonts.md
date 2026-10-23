# Font provenance and fidelity

Only existing local font assets are reused; no font/software dependencies were installed. OFL-candidate compilation disables system font search to prevent an unnoticed macOS fallback. D2/D3 require an explicit font-mode choice. original-system mode instead preserves the original local appearance with an unverified-rights warning; it carries no system font binaries.

| Face | Local asset / runtime | License evidence | Use |
|---|---|---|---|
| Noto Serif SC | bundled Regular and SemiBold OTF, version 2.003 | font name-table license record: SIL OFL 1.1; `assets/fonts/NotoSerifSC-OFL.txt`; [official Noto CJK Serif license](https://raw.githubusercontent.com/notofonts/noto-cjk/main/Serif/LICENSE) | D1 Chinese; D2/D3 candidate Chinese |
| Inter | local static instances named Teaching Press Sans, from existing Inter 4.001 git-66647c0bb | font name-table license record: SIL OFL 1.1; `assets/fonts/Inter-OFL.txt`; [official project license](https://github.com/rsms/inter/blob/master/LICENSE.txt) | D2/D3 candidate Latin |
| Libertinus Serif | embedded in existing Typst 0.14.2; not separately redistributed | [official OFL](https://raw.githubusercontent.com/alerque/libertinus/master/OFL.txt) | D1 Latin and all IPA |

Both bundled families have OS/2 fsType=0. Keep the bundled font files and copyright/license notices together. Inter static instances were produced with the existing fontTools library at opsz=14 and weights 300/400/500/600/700/900, then renamed Teaching Press Sans. This avoids Typst 0.14.2 variable-font warnings and distinguishes the local derivative from upstream Inter. No new font was downloaded or installed. Do not change these files casually. File hashes are recorded in `assets/fonts/manifest.json`.

D1 preserves the exploration's font choices. D2 originally used Helvetica Neue / PingFang; D3 used Avenir Next / Arial Rounded / Yuanti / PingFang. Those original PDFs are unmodified and their system-font embedding permissions remain unconfirmed. The new candidate keeps geometry, palette, illustrations and card mechanics, but Inter has different widths and Noto Serif SC has serifs. D3's typography is less rounded. This is an explicit portable candidate, not a pixel-identical replacement or a silently chosen house style.

Audit every output's embedded font list and inspect pixels. The verified candidate may have its font licensing documented, but this does not establish print production readiness, classroom usability, duplex proofing or tagged-PDF accessibility. No physical proof was made.
