#!/usr/bin/env python3
"""Create an editable Teaching Press project and compile with existing Typst."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
STYLES = {'d1': 'd1-marginalia', 'd2': 'd2-grid', 'd3': 'd3-index'}
ROLES = {'cover': '#page-cover()', 'words': '#page-words()',
         'grammar': '#page-grammar()', 'reading': '#page-reading()',
         'cloze': '#page-cloze()', 'writing': '#page-writing()',
         'teacher-reading': '#page-reading(teacher: true)'}

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    sub = ap.add_subparsers(dest='command', required=True)
    init = sub.add_parser('init')
    init.add_argument('directory', type=Path)
    init.add_argument('--style', choices=STYLES, required=True)
    init.add_argument('--font-mode', choices=['ofl-candidate', 'original-system'])
    init.add_argument('--roles', default=','.join(ROLES))
    build = sub.add_parser('build')
    build.add_argument('directory', type=Path)
    args = ap.parse_args()
    directory = args.directory.resolve()
    if args.command == 'init':
        roles = args.roles.split(',')
        if len(set(roles)) != len(roles) or any(r not in ROLES for r in roles):
            ap.error('roles must be distinct names from ' + ','.join(ROLES))
        if directory.exists():
            ap.error('refusing to overwrite an existing directory')
        if args.style in ['d2', 'd3'] and args.font_mode is None:
            ap.error('D2/D3 require an explicit --font-mode: original-system preserves the selected look for local review (rights unverified); ofl-candidate changes Chinese to serif and loses D3 rounded type')
        mode = args.font_mode or 'ofl-candidate'
        directory.mkdir(parents=True)
        template = ROOT / 'assets/template'
        for name in ['content.typ', 'shared-flat.typ']:
            shutil.copy2(template / name, directory / name)
        style = (template / STYLES[args.style] / 'style.typ').read_text()
        style = style.replace('"../content.typ"', '"content.typ"').replace('"../shared-flat.typ"', '"shared-flat.typ"')
        if mode == 'original-system' and args.style == 'd2':
            style = style.replace('"Teaching Press Sans"', '"Helvetica Neue"').replace('"Noto Serif SC"', '"PingFang SC"')
        elif mode == 'original-system' and args.style == 'd3':
            style = style.replace('#let en-font = ("Teaching Press Sans", "Noto Serif SC")', '#let en-font = ("Avenir Next", "PingFang SC")')
            style = style.replace('#let head-font = ("Teaching Press Sans", "Noto Serif SC")', '#let head-font = ("Arial Rounded MT", "Yuanti SC")')
            style = style.replace('#let zh-font = ((name: "Teaching Press Sans", covers: "latin-in-cjk"), "Noto Serif SC")', '#let zh-font = ((name: "Avenir Next", covers: "latin-in-cjk"), "PingFang SC")')
            style = style.replace('#let zh-head = ((name: "Teaching Press Sans", covers: "latin-in-cjk"), "Noto Serif SC")', '#let zh-head = ((name: "Arial Rounded MT", covers: "latin-in-cjk"), "Yuanti SC")')
        (directory / 'style.typ').write_text(style)
        (directory / 'main.typ').write_text('#import "style.typ": *\n#show: setup\n\n' + '\n'.join(ROLES[r] for r in roles) + '\n')
        shutil.copytree(ROOT / 'assets/fonts', directory / 'fonts')
        (directory / 'press-project.json').write_text(json.dumps({'style': args.style, 'roles': roles, 'font_mode': mode, 'version': '0.1.1'}, indent=2) + '\n')
        print(json.dumps({'created': str(directory), 'style': args.style, 'roles': roles, 'font_mode': mode}))
    else:
        if not (directory / 'press-project.json').is_file():
            ap.error('expected a project created by press.py init')
        typst = shutil.which('typst')
        if not typst:
            ap.error('Typst is unavailable; use an existing permitted runtime, do not install implicitly')
        metadata = json.loads((directory / 'press-project.json').read_text())
        mode = metadata.get('font_mode', 'ofl-candidate')  # v0.1.0 projects were all OFL candidates.
        if mode not in ['ofl-candidate', 'original-system']:
            ap.error('unrecognized project font_mode')
        font_flags = ['--ignore-system-fonts'] if mode == 'ofl-candidate' else []
        if mode == 'original-system':
            sys.stderr.write('Local original-look review only: system font embedding rights are unverified; do not call this publisher-ready.\n')
        result = subprocess.run([typst, 'compile', *font_flags, '--font-path', str(directory / 'fonts'),
                                 '--root', str(directory), str(directory / 'main.typ'), str(directory / 'lesson.pdf')],
                                capture_output=True, text=True)
        sys.stderr.write(result.stderr)
        if result.returncode:
            return result.returncode
        print(json.dumps({'pdf': str(directory / 'lesson.pdf'), 'compiled': True, 'layout_validated': False, 'font_mode': mode}))
    return 0

if __name__ == '__main__':
    sys.exit(main())
