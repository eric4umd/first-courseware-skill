#!/usr/bin/env python3
"""stage_scaffold.py — start a new classroom deck project from the sample.

    python3 stage_scaffold.py <new-folder> [--title "Lesson title"] [--theme marginalia|grid|studio|exam]

Creates <new-folder>/ with: css/ js/ vendor/ fonts/ (runtime, self-contained, offline),
stage_kit.py, build.py (the sample deck — replace its CONTENT), listening.txt, audio/.
No --theme = the D3 Index Cards look (the default). --theme also copies that theme's css + fonts, sets theme= in build.py
and adds stage_theme.py / stage_fonts.py so build.py rebuilds the Chinese font subset (Marginalia) after every run.
Refuses to overwrite a non-empty folder. Then:  cd <new-folder> && python3 build.py
"""
import argparse
import pathlib
import shutil
import sys

SKILL = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import stage_theme  # noqa: E402


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("dest")
    ap.add_argument("--title", default="")
    ap.add_argument("--theme", default="", choices=[""] + stage_theme.available(), help="optional look; default is D3 Index Cards")
    a = ap.parse_args()
    dest = pathlib.Path(a.dest).expanduser().resolve()
    if dest.exists() and any(dest.iterdir()):
        sys.exit(f"{dest} exists and is not empty — pick a new folder.")
    dest.mkdir(parents=True, exist_ok=True)
    rt = SKILL / "assets" / "runtime"
    for sub in ("css", "js", "vendor", "fonts"):
        shutil.copytree(rt / sub, dest / sub)
    shutil.copy(rt / "SOURCES.md", dest / "SOURCES.md")
    shutil.copy(SKILL / "scripts" / "stage_kit.py", dest / "stage_kit.py")
    shutil.copy(SKILL / "examples" / "sample-deck" / "build.py", dest / "build.py")
    shutil.copy(SKILL / "examples" / "sample-deck" / "listening.txt", dest / "listening.txt")
    (dest / "audio").mkdir()
    if a.title:
        b = (dest / "build.py").read_text(encoding="utf-8")
        (dest / "build.py").write_text(b.replace("Study Room, Please · sample", a.title), encoding="utf-8")
    if a.theme:
        stage_theme.install(dest, a.theme)
        if a.theme == "marginalia":
            shutil.copytree(SKILL / "assets" / "themes" / "cjk-sources", dest / "font-sources")
        for f in ("stage_theme.py", "stage_fonts.py"):
            shutil.copy(SKILL / "scripts" / f, dest / f)
        b = (dest / "build.py").read_text(encoding="utf-8")
        old = 'nav_jumps=(("路线", "route"), ("小卡", "menu"))), encoding="utf-8")'
        if b.count(old) != 1:
            sys.exit("stage_scaffold: the sample build.py changed; cannot insert theme= (update this script)")
        b = b.replace(old, f'nav_jumps=(("路线", "route"), ("小卡", "menu")), theme="{a.theme}"), encoding="utf-8")\n'
                           f'import stage_theme  # noqa: E402\nstage_theme.fonts(HERE, "{a.theme}")   # Chinese font subset (Marginalia only); keeps it in step with the text')
        if f'theme="{a.theme}"' not in b:
            sys.exit("stage_scaffold: theme= was not inserted")
        (dest / "build.py").write_text(b, encoding="utf-8")
    print(f"scaffolded {dest}{' (theme: ' + a.theme + ')' if a.theme else ''}\nnext: edit build.py CONTENT, render audio (see SKILL.md), python3 build.py")


if __name__ == "__main__":
    main()
