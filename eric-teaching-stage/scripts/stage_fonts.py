#!/usr/bin/env python3
"""Subset a big CJK font to exactly the characters a deck uses (plus ASCII and common punctuation).
Usage: stage_fonts.py <lesson.html> <out_dir> <font.otf>[:weight:family] ...
Example: stage_fonts.py lesson.html fonts NotoSerifSC-Regular.otf:400:"Noto Serif SC"
Writes <out_dir>/<stem>-sub.woff2 and prints @font-face rules to paste into the theme CSS.
Run with the TTS venv python (it has fontTools + brotli):  ~/.local/share/eric-stage-tts/venv/bin/python
Always add ~200 safe characters so a late text edit does not tofu; re-run after content changes."""
import pathlib, re, sys
from fontTools import subset

SAFE = "".join(chr(c) for c in range(0x20, 0x7F)) + "，。、；：？！“”‘’（）《》—…·→←↑↓×÷％＋＝～「」『』【】 　✓✗"

def deck_text(html_path):
    s = pathlib.Path(html_path).read_text(encoding="utf-8")
    s = re.sub(r"<(script|style)\b.*?</\1>", "", s, flags=re.S)
    chars = set(re.sub(r"<[^>]+>", "", s)) | set(SAFE)
    # text that scripts inject at run time (player status, timer labels, nudges): keep every CJK / full-width char found in js/*.js
    for js in (pathlib.Path(html_path).parent / "js").glob("*.js"):
        chars |= set(re.findall(r"[\u3000-\u9fff\uff00-\uffef\u2190-\u21ff\u2022-\u2026]", js.read_text(encoding="utf-8")))
    return chars

def main():
    html, out, *fonts = sys.argv[1:]
    chars = deck_text(html)
    outd = pathlib.Path(out); outd.mkdir(parents=True, exist_ok=True)
    for spec in fonts:
        path, weight, family = (spec.split(":") + ["400", ""])[:3]
        opts = subset.Options(); opts.flavor = "woff2"; opts.layout_features = ["*"]; opts.notdef_outline = True
        f = subset.load_font(path, opts)
        sub = subset.Subsetter(opts); sub.populate(text="".join(sorted(chars))); sub.subset(f)
        stem = pathlib.Path(path).stem.replace("-Regular", "-400").replace("-SemiBold", "-600")
        dest = outd / f"{stem}-sub.woff2"
        subset.save_font(f, str(dest), opts)
        print(f'@font-face {{ font-family: "{family}"; src: url("../fonts/{dest.name}") format("woff2"); font-weight: {weight}; font-display: block; }}  /* {dest.stat().st_size//1024} KB, {len(chars)} chars */')

if __name__ == "__main__":
    main()
