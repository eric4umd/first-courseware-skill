#!/usr/bin/env python3
"""stage_theme.py — use one of the installed looks (themes) in a deck folder.

    python3 stage_theme.py list
    python3 stage_theme.py install <deck-folder> <theme>   # css/theme-<theme>.css + its fonts + a SOURCES.md section
    python3 stage_theme.py fonts   <deck-folder> <theme>   # (re)build the Chinese font subset, for themes that need one
    python3 stage_theme.py check   <deck-folder> <theme>   # css linked, every font file it names exists, subset resolved

A theme is one CSS file loaded after the runtime plus its Latin fonts (skill assets/themes/). Select it in the
deck's build with K.page(..., theme="<name>"). The default look (no theme) is D3 Index Cards.
`stage_scaffold.py --theme <name>` does install + wires `fonts` into build.py; for an existing deck run
`install`, add theme="<name>" to K.page, and call stage_theme.fonts(HERE, "<name>") after each build.

`fonts` reads <deck>/lesson.html and the deck's js/ (so it keeps every character the deck can show), subsets the
theme's Chinese faces (today: Marginalia) into <deck>/fonts/ and writes the @font-face rules between
/*@FONTS:begin*/ and /*@FONTS:end*/ in the deck's theme CSS, so it can be re-run after every text change.
It needs fontTools (the TTS venv from stage_setup.sh has it) and the bundled CJK font sources; it stops with a clear
message when either is missing. Without the subset the deck still renders (system Chinese serif), only the look differs.
`install` overwrites the deck's theme CSS with the pristine copy; run `fonts` again afterwards."""
import pathlib
import re
import shutil
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
THEMES = HERE.parent / "assets" / "themes"          # absent inside a scaffolded deck (only `fonts` / `check` run there)
VENV_PY = pathlib.Path.home() / ".local/share/eric-stage-tts/venv/bin/python"
CJK_FONTS = HERE / "font-sources" if (HERE / "font-sources").is_dir() else HERE.parent / "assets/themes/cjk-sources"
SUBSET = {  # theme -> Chinese faces to subset to the deck's text (file : weight : family)
    "marginalia": [("NotoSerifSC-Regular.otf", "400", "Noto Serif SC"), ("NotoSerifSC-SemiBold.otf", "600", "Noto Serif SC"),
                   ("ZhuqueFangsong-Regular.ttf", "400", "Zhuque Fangsong")],
}
BEGIN, END, HOLE = "/*@FONTS:begin*/", "/*@FONTS:end*/", "/*@FONTS*/"


def available():
    return sorted(p.stem[len("theme-"):] for p in THEMES.glob("theme-*.css")) if THEMES.is_dir() else []


def _fail(msg):
    sys.exit(f"stage_theme: {msg}")


def install(deck, theme):
    deck = pathlib.Path(deck)
    if theme not in available():
        _fail(f"unknown theme {theme!r}; installed: {', '.join(available()) or '(none: run from the skill, not a deck copy)'}")
    (deck / "css").mkdir(parents=True, exist_ok=True)
    (deck / "fonts").mkdir(parents=True, exist_ok=True)
    shutil.copy(THEMES / f"theme-{theme}.css", deck / "css" / f"theme-{theme}.css")
    for f in sorted((THEMES / f"fonts-{theme}").iterdir()):
        shutil.copy(f, deck / "fonts" / f.name)
    # SOURCES.md: add this theme's section once
    src = (THEMES / "SOURCES.md").read_text(encoding="utf-8")
    m = re.search(rf"^## Theme: {re.escape(theme)}\n.*?(?=^## Theme: |\Z)", src, flags=re.S | re.M)
    out = deck / "SOURCES.md"
    if m and out.exists() and f"## Theme: {theme}\n" not in out.read_text(encoding="utf-8"):
        out.write_text(out.read_text(encoding="utf-8").rstrip() + "\n\n" + m.group(0).rstrip() + "\n", encoding="utf-8")
    return deck / "css" / f"theme-{theme}.css"


def _python_with_fonttools():
    for py in (sys.executable, str(VENV_PY)):
        if py and pathlib.Path(py).exists() and subprocess.run([py, "-c", "import fontTools, brotli"], capture_output=True).returncode == 0:
            return py
    _fail("fontTools + brotli not found. Run stage_setup.sh once (it builds the TTS venv with both), then re-run.")


def fonts(deck, theme):
    """Chinese subset for themes that have one; returns True when the CSS holds a resolved font block (or none is needed)."""
    deck = pathlib.Path(deck)
    css = deck / "css" / f"theme-{theme}.css"
    if not css.exists():
        _fail(f"{css} is missing; run: stage_theme.py install {deck} {theme}")
    if theme not in SUBSET:
        return True
    html = deck / "lesson.html"
    if not html.exists():
        _fail(f"{html} not built yet; build the deck first, then run fonts")
    specs = []
    for name, weight, family in SUBSET[theme]:
        path = CJK_FONTS / name
        if not path.exists():
            _fail(f"Chinese font {path} not found (re-copy the bundled cjk-sources or scaffold the theme again)")
        specs.append(f"{path}:{weight}:{family}")
    r = subprocess.run([_python_with_fonttools(), str(HERE / "stage_fonts.py"), str(html), str(deck / "fonts")] + specs,
                       capture_output=True, text=True)
    if r.returncode != 0:
        _fail("stage_fonts.py failed:\n" + r.stderr.strip()[-600:])
    block = f"{BEGIN}\n{r.stdout.strip()}\n{END}"
    text = css.read_text(encoding="utf-8")
    if HOLE in text:
        text = text.replace(HOLE, block)
    elif BEGIN in text and END in text:
        text = re.sub(re.escape(BEGIN) + r".*?" + re.escape(END), lambda _: block, text, flags=re.S)
    else:
        _fail(f"{css} has neither {HOLE} nor {BEGIN}…{END}; nothing to fill")
    css.write_text(text, encoding="utf-8")
    print(f"{theme}: Chinese subset {r.stdout.count('@font-face')} faces")
    return True


def check(deck, theme):
    """Problems as a list of strings (empty = fine)."""
    deck = pathlib.Path(deck)
    bad = []
    css = deck / "css" / f"theme-{theme}.css"
    html = deck / "lesson.html"
    if not css.exists():
        return [f"{css.name} missing"]
    text = css.read_text(encoding="utf-8")
    if html.exists():
        h = html.read_text(encoding="utf-8")
        if f'href="css/theme-{theme}.css"' not in h:
            bad.append("lesson.html does not link the theme css (K.page(..., theme=...) missing?)")
        if f'data-theme="{theme}"' not in h:
            bad.append('lesson.html has no data-theme on <html>')
    if theme in SUBSET and HOLE in text:
        bad.append("Chinese subset not built (run stage_theme.py fonts)")
    for u in re.findall(r"url\(\s*['\"]?(\.\./fonts/[^'\")]+)", text):
        if not (deck / "css" / u).resolve().exists():
            bad.append(f"css names {u} but the file is missing")
    return bad


def main(argv):
    if len(argv) >= 2 and argv[1] == "list":
        print("\n".join(available()))
        return 0
    if len(argv) != 4 or argv[1] not in ("install", "fonts", "check"):
        print(__doc__)
        return 2
    _, cmd, deck, theme = argv
    if cmd == "install":
        print("installed", install(deck, theme))
    elif cmd == "fonts":
        fonts(deck, theme)
    else:
        bad = check(deck, theme)
        print("\n".join(bad) if bad else f"{theme}: ok")
        return 1 if bad else 0
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
