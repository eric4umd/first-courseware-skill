"""stage_kit.py — scene components for Eric Teaching Stage decks (D3 Index Cards look).

Every function returns an HTML string that the shipped runtime (css/deck.css, js/deck.js,
js/stage-audio.js) already knows how to style and drive. A lesson's build.py imports this
module, calls the components with its own content, and hands the list to `page()`.

Rules baked in (see SKILL.md):
  * one teaching move per beat: every element the teacher reveals separately carries `data-beat`
  * the deck never shows answers or a listening transcript; answers sit behind `.look` (看对照)
  * all text is escaped here — pass plain strings; pass `raw=` HTML only where a param says so
"""
from __future__ import annotations

import html
import re

E = html.escape

PALETTE = dict(navy="#1d2a4d", tomato="#ee5b3e", mustard="#f3b23b", teal="#169c86", sky="#4a98e6", lilac="#8574d4")

# ───────────────────────── icons (48×48, stroke icons) ─────────────────────────
ICON = {
    "play": '<path d="M16 11l22 13-22 13z" fill="#fff"/>',
    "pencil": '<path d="M10 38l3-10 20-20 7 7-20 20z" fill="#fff"/><path d="M28 13l7 7M10 38l10-3"/>',
    "marker": '<path d="M14 30l14-18 9 7-14 18z" fill="#fff"/><path d="M14 30l-4 8 10-1M8 42h30"/>',
    "notes": '<rect x="11" y="8" width="24" height="32" rx="3" fill="#fff"/><path d="M16 17h14M16 24h14M16 31h8"/><path d="M6 42L42 6" stroke="#ee5b3e"/>',
    "think": '<circle cx="24" cy="26" r="14" fill="#fff"/><path d="M24 26V18"/><path d="M19 6h10M24 6v6"/><path d="M36 14l3-3"/>',
    "speak": '<rect x="18" y="6" width="12" height="22" rx="6" fill="#fff"/><path d="M11 22a13 13 0 0 0 26 0M24 35v7M17 42h14"/>',
    "phone": '<rect x="13" y="5" width="22" height="38" rx="4" fill="#fff"/><path d="M21 37h6"/><circle cx="24" cy="20" r="5" fill="#ee5b3e" stroke="none"/>',
    "ear": '<path d="M16 20a9 9 0 0 1 18 0c0 6-6 8-6 14a5 5 0 0 1-9 2" fill="#fff"/><path d="M21 20a4 4 0 0 1 8 0c0 3-3 4-4 6"/><path d="M39 12a14 14 0 0 1 2 14" stroke="#ee5b3e"/>',
    "camera": '<rect x="6" y="14" width="36" height="24" rx="4" fill="#fff"/><path d="M17 14l3-5h8l3 5"/><circle cx="24" cy="26" r="7"/>',
    "mic": '<rect x="18" y="6" width="12" height="22" rx="6" fill="#fff"/><path d="M11 22a13 13 0 0 0 26 0M24 35v7M17 42h14"/>',
    "cup": '<path d="M9 16h22v13a8 8 0 0 1-8 8h-6a8 8 0 0 1-8-8z" fill="#fff"/><path d="M31 19h3a5 5 0 0 1 0 10h-3M15 6c-2 3 2 4 0 7M22 6c-2 3 2 4 0 7"/>',
    "book": '<path d="M8 10h14a4 4 0 0 1 4 4v26a3 3 0 0 0-3-3H8z" fill="#fff"/><path d="M40 10H26v30a3 3 0 0 1 3-3h11z" fill="#fff"/>',
    "star": '<path d="M24 6l5.5 11.5L42 19l-9 8.8 2.2 12.4L24 34.2 12.8 40.2 15 27.8 6 19l12.5-1.5z" fill="#fff"/>',
    "clock": '<circle cx="24" cy="25" r="15" fill="#fff"/><path d="M24 25V15M24 25l7 5"/>',
}


def icon(name: str, cls: str = "ic") -> str:
    return (f'<svg class="{cls}" viewBox="0 0 48 48" aria-hidden="true" fill="none" stroke="#1d2a4d" '
            f'stroke-width="3" stroke-linecap="round" stroke-linejoin="round">{ICON[name]}</svg>')


# icons for the T/S/P/N/J check codes (Time, Single/plural, Passive, Nouns, Join)
STD_CODE_ICONS = {
    'T': '<circle cx="24" cy="25" r="15" fill="#fff"/><path d="M24 25V15M24 25l7 5"/><circle cx="24" cy="25" r="2" fill="#1d2a4d" stroke="none"/><path d="M20 6h8M24 6v4"/>',
    'S': '<circle cx="11" cy="24" r="5.5" fill="#1d2a4d" stroke="none"/><path d="M21 12v24" stroke-dasharray="3 4"/><circle cx="31" cy="17" r="4.6" fill="#fff"/><circle cx="41" cy="20" r="4.6" fill="#fff"/><circle cx="33" cy="31" r="4.6" fill="#fff"/>',
    'P': '<path d="M12 21a12 12 0 0 1 22-5"/><path d="M35 9v8h-8"/><path d="M36 27a12 12 0 0 1-22 5"/><path d="M13 39v-8h8"/>',
    'N': '<path d="M6 17h19v11a7 7 0 0 1-7 7h-5a7 7 0 0 1-7-7z" fill="#fff"/><path d="M25 20h3a4 4 0 0 1 0 8h-3"/><rect x="33" y="29" width="7" height="7" fill="#fff"/><rect x="40" y="22" width="0" height="0"/><rect x="34" y="20" width="7" height="7" fill="#fff"/><rect x="40.5" y="29" width="0" height="0"/>',
    'J': '<rect x="5" y="18" width="23" height="13" rx="6.5" transform="rotate(-18 16 24)"/><rect x="20" y="17" width="23" height="13" rx="6.5" transform="rotate(-18 32 24)"/>',
}


# ───────────────────────── small parts ─────────────────────────
REC = '<span class="rec"><i></i>REC</span>'


def timer(sec: int, big: bool = False, label: str = "") -> str:
    """Click-to-start countdown. Never auto-advances; rings a bell at zero (stage-audio.js).
    USE SPARINGLY: only for silent, time-boxed student work of a few minutes (writing, self-check, break). Never on a
    single spoken answer, a warm-up sentence, a log line or a reveal — those components take `secs=None` by default."""
    m, s = divmod(sec, 60)
    lab = f'<span class="t-label">{E(label)}</span>' if label else ""
    return (f'<div class="timer-wrap{" big" if big else ""}">{lab}'
            f'<button type="button" class="timer{" big" if big else ""}" data-timer="{sec}">'
            f'<span class="t-dial"><svg class="t-ring" viewBox="0 0 44 44" aria-hidden="true">'
            f'<circle class="t-ring-bg" cx="22" cy="22" r="18"/>'
            f'<circle class="t-ring-fg" cx="22" cy="22" r="18" pathLength="1"/></svg><span class="t-icon"></span></span>'
            f'<span class="t-text"><span class="t-time">{m}:{s:02d}</span><span class="t-state">点一下开始</span></span>'
            f'</button><button type="button" class="timer-reset" aria-label="重置计时">↺ 重置</button></div>')


def section(sid: str, scene: str, title: str, part: str, body: str, cls: str = "", extra: str = "") -> str:
    """scene ∈ cover | teach | judge | rewrite | choose. `part` ties the scene to a rail tab."""
    idattr = f' id="{sid}"' if sid else ""
    p = f' data-part="{part}"' if part else ""
    return (f'<section class="scene s-{scene} {cls}"{idattr} data-scene="{scene}" '
            f'data-title="{E(title)}"{p}{extra}>\n{body}\n</section>\n')


def head(pill: str, color: str = "navy", zh: str = "", right: str = "") -> str:
    """Top strip: coloured pill + Chinese kicker + optional right slot (raw HTML: REC, timer, count)."""
    z = f'<span class="head-zh">{E(zh)}</span>' if zh else ""
    r = f'<span class="head-right">{right}</span>' if right else ""
    return f'<header class="head"><span class="pill p-{color}">{E(pill)}</span>{z}{r}</header>'


def count(i: int, n: int) -> str:
    return f'<span class="count">{i} / {n}</span>'


# ───────────────────────── art: cassette / recorder ─────────────────────────
def reel(cx, cy, r, spin=True):
    teeth = "".join(
        f'<rect x="{cx-2.2:.1f}" y="{cy-r*0.52:.1f}" width="4.4" height="{r*0.22:.1f}" rx="1" fill="#1d2a4d" transform="rotate({a} {cx} {cy})"/>'
        for a in range(0, 360, 60))
    return (f'<g class="{"reel" if spin else "reel still"}">'
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#fff" stroke="#1d2a4d" stroke-width="3"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r*0.62:.1f}" fill="#fff8ec" stroke="#1d2a4d" stroke-width="2.5"/>'
            f'{teeth}<circle cx="{cx}" cy="{cy}" r="{r*0.2:.1f}" fill="#1d2a4d"/></g>')


def cassette(label_top: str, label_main: str, color: str = "#ee5b3e", spin: bool = True, side: str = "A") -> str:
    return f'''<svg class="cassette" viewBox="0 0 400 260" aria-hidden="true">
  <rect x="10" y="10" width="380" height="240" rx="18" fill="#2d3d6b" stroke="#1d2a4d" stroke-width="4"/>
  <rect x="34" y="30" width="332" height="138" rx="10" fill="#fff8ec" stroke="#1d2a4d" stroke-width="3"/>
  <rect x="34" y="30" width="332" height="40" rx="10" fill="{color}" stroke="#1d2a4d" stroke-width="3"/>
  <text x="54" y="57" class="cs-top">{E(label_top)}</text>
  <text x="346" y="57" class="cs-side" text-anchor="end">SIDE {E(side)}</text>
  <text x="200" y="100" class="cs-main" text-anchor="middle">{E(label_main)}</text>
  <rect x="104" y="112" width="192" height="46" rx="23" fill="#1d2a4d"/>
  {reel(132, 135, 19, spin)}{reel(268, 135, 19, spin)}
  <path d="M90 250l22-56h176l22 56" fill="#1d2a4d"/>
  <circle cx="150" cy="226" r="7" fill="#fff8ec"/><circle cx="250" cy="226" r="7" fill="#fff8ec"/>
  <circle cx="30" cy="230" r="5" fill="#fff8ec"/><circle cx="370" cy="230" r="5" fill="#fff8ec"/>
</svg>'''


def recorder(label: str = "SAY IT AGAIN", side: str = "A") -> str:
    """The orange cassette-recorder cover art."""
    dots = "".join(f'<circle cx="{150+dx}" cy="{282+dy}" r="6" fill="#f3b23b"/>'
                   for dx in range(-60, 61, 20) for dy in range(-60, 61, 20) if dx * dx + dy * dy <= 3700)
    return f'''<svg class="recorder" viewBox="0 0 640 470" aria-hidden="true">
  <path d="M200 92V58a20 20 0 0 1 20-20h200a20 20 0 0 1 20 20v34" fill="none" stroke="#1d2a4d" stroke-width="14" stroke-linecap="round"/>
  <path d="M200 92V58a20 20 0 0 1 20-20h200a20 20 0 0 1 20 20v34" fill="none" stroke="#f3b23b" stroke-width="6" stroke-linecap="round"/>
  <rect x="30" y="88" width="580" height="340" rx="28" fill="#ee5b3e" stroke="#1d2a4d" stroke-width="5"/>
  <rect x="30" y="88" width="580" height="54" rx="28" fill="#1d2a4d"/>
  <rect x="30" y="117" width="580" height="25" fill="#1d2a4d"/>
  <g class="keys">
    <rect x="70" y="70" width="70" height="40" rx="8" fill="#fff" stroke="#1d2a4d" stroke-width="4"/>
    <circle cx="105" cy="90" r="9" fill="#ee5b3e"/>
    <rect x="152" y="70" width="70" height="40" rx="8" fill="#f3b23b" stroke="#1d2a4d" stroke-width="4"/>
    <path d="M178 80l18 10-18 10z" fill="#1d2a4d"/>
    <rect x="234" y="70" width="70" height="40" rx="8" fill="#fff" stroke="#1d2a4d" stroke-width="4"/>
    <path d="M255 80v20M265 80l-10 10 10 10M283 80l-10 10 10 10" fill="none" stroke="#1d2a4d" stroke-width="4" stroke-linejoin="round"/>
    <rect x="316" y="70" width="70" height="40" rx="8" fill="#fff" stroke="#1d2a4d" stroke-width="4"/>
    <rect x="341" y="80" width="20" height="20" rx="2" fill="#1d2a4d"/>
  </g>
  <rect x="440" y="102" width="130" height="30" rx="6" fill="#2d3d6b"/>
  <text x="505" y="124" text-anchor="middle" class="rc-counter">012</text>
  <g class="grille"><circle cx="150" cy="282" r="104" fill="#1d2a4d"/><circle cx="150" cy="282" r="86" fill="#2d3d6b"/>{dots}</g>
  <rect x="282" y="176" width="300" height="196" rx="16" fill="#1d2a4d"/>
  <rect x="298" y="192" width="268" height="164" rx="10" fill="#fff8ec" stroke="#1d2a4d" stroke-width="3"/>
  <rect x="298" y="192" width="268" height="38" rx="10" fill="#f3b23b" stroke="#1d2a4d" stroke-width="3"/>
  <text x="314" y="218" class="rc-label">{E(label.upper())}</text>
  <text x="552" y="218" class="rc-label" text-anchor="end">{E(side)}</text>
  <rect x="340" y="262" width="184" height="56" rx="28" fill="#1d2a4d"/>
  {reel(372, 290, 23)}{reel(492, 290, 23)}
  <rect x="398" y="330" width="68" height="14" rx="4" fill="#2d3d6b"/>
  <circle cx="64" cy="400" r="8" fill="#fff8ec" class="rec-led"/>
  <text x="80" y="406" class="rc-rec">REC</text>
  <rect x="80" y="428" width="70" height="22" rx="6" fill="#1d2a4d"/>
  <rect x="490" y="428" width="70" height="22" rx="6" fill="#1d2a4d"/>
</svg>'''


WAVES = ('<svg class="waves" viewBox="0 0 120 200" aria-hidden="true"><path d="M20 70a40 40 0 0 1 0 60" />'
         '<path d="M45 45a75 75 0 0 1 0 110"/><path d="M70 20a110 110 0 0 1 0 160"/></svg>')


# ───────────────────────── scenes ─────────────────────────
def cover(title_lines, zh, tagline_en, tagline_zh, series, series_zh, number, art_label="SAY IT AGAIN", brand="Eric Teaching Studio", foot_right="Online class"):
    lines = "<br>".join(E(x) for x in title_lines)
    return section("cover", "cover", "封面", "", f'''
<div class="cover-grid">
  <div class="cover-text">
    <div data-beat>
      <div class="cover-pills"><span class="pill p-navy">{E(series)}</span><span class="pill p-outline">{E(series_zh)}</span></div>
      <h1 class="cover-title">{lines}</h1>
      <p class="cover-zh">{E(zh)}</p>
    </div>
    <div data-beat>
      <div class="cover-tag"><p class="en">{E(tagline_en)}</p><p class="zh">{E(tagline_zh)}</p></div>
    </div>
  </div>
  <div class="cover-art" data-beat-static>
    <div class="art-card" data-label="{E(art_label)}">{recorder(art_label)}{WAVES}</div>
    <div class="lesson-badge"><span>Lesson</span><b>{E(str(number))}</b></div>
  </div>
</div>
<footer class="cover-foot"><span>{E(brand)}</span><span>{E(foot_right)}</span></footer>''')


def route(stations, title="Today's route", zh="今天的路线", headline="", break_after=None):
    """stations: [(color, en, zh, minutes_text)]; break_after: index (1-based) after which a Break chip floats."""
    st = ""
    for i, (c, en, z, mins) in enumerate(stations, 1):
        brk = '<span class="route-break">Break</span>' if break_after == i - 1 and i > 1 else ""
        st += (f'<div class="station" data-beat data-mins="{E(mins)}">{brk}<span class="station-dot c-{c}">{i}</span>'
               f'<div class="card station-card"><p class="station-en">{E(en)}</p><p class="station-zh">{E(z)}</p></div></div>')
    return section("route", "teach", zh, "", f'''
{head("Today", "navy", zh)}
<h2 class="title">{E(headline or title)}</h2>
<div class="route">{st}</div>''')


def rules4(sid, pill, color, zh_kicker, headline, rules, part=""):
    """Four rule cards. rules: [(icon_name, en, zh)]."""
    rl = "".join(f'<div class="rule-card card" data-beat><span class="num">{i}</span>{icon(ic, "rule-ic")}'
                 f'<p class="rc-en">{E(en)}</p><p class="rc-zh">{E(z)}</p></div>' for i, (ic, en, z) in enumerate(rules, 1))
    return section(sid, "teach", zh_kicker, part, f'''
{head(pill, color, zh_kicker, REC)}
<h2 class="title">{E(headline)}</h2>
<div class="rules4">{rl}</div>''', extra=f' data-block="{part}"' if part else "")


def rewrite(sid, k, n, part, pill, color, source_zh, reference_en, note="", secs=None, tool_zh="先说英语，再把自己说的写下来。先不标，学完自查卡再回头标。", title_prefix="热身"):
    """Prompt card with a 看对照 reveal (`reference_en` hidden until pressed)."""
    nt = f'<p class="ref-note">{E(note)}</p>' if note else ""
    return section(sid, "rewrite", f"{title_prefix} {k}", part, f'''
{head(pill, color, "中文 → English", count(k, n))}
<div class="warm-body" data-beat>
  <div class="card index-card warm-card"><span class="badge big c-{color}">Sentence {k}</span><p class="warm-zh">{E(source_zh)}</p>
    <div class="contrast ref-box" hidden><span class="ref-tag">参考（不是唯一答案）</span><p class="ref-en">{E(reference_en)}</p>{nt}</div></div>
  <div class="tool-row">
    {timer(secs) if secs else ""}
    <p class="tool-say">{REC}<span>{E(tool_zh)}</span></p>
    <button type="button" class="look ref-look">看对照</button>
  </div>
</div>''')


def divider(sid, title, part, color, pill, big, en, zh, top, main, side="A", block=None):
    """Full-bleed section opener with a cassette. big may contain &amp; (raw)."""
    block = block or part
    return section(sid, "cover", title, part, f'''
<div class="divider">
  <div class="div-art" data-top="{E(top)}" data-main="{E(main)}" data-side="{E(side)}">{cassette(top, main, PALETTE[color], True, side)}</div>
  <div class="div-text" data-beat>
    <span class="pill p-{color}">{E(pill)}</span>
    <h1 class="div-title">{big}</h1>
    <p class="div-en">{E(en)}</p>
    <p class="div-zh">{E(zh)}</p>
  </div>
</div>''', cls=f"div-{color}", extra=f' data-block="{block}"')


def stuck_hints(hints):
    """hints: [(letter, en, zh)] — scaffolds revealed on demand, never an answer."""
    hs = "".join(f'<div class="hint"><span class="hint-k">{k}</span><p><span class="en">{E(en)}</span><span class="zh">{E(zh)}</span></p></div>'
                 for k, en, zh in hints)
    return (f'<div class="look-wrap stuck"><button type="button" class="look stuck-btn">Stuck? <span>卡住了</span></button>'
            f'<div class="contrast hints" hidden>{hs}</div></div>')


def question(sid, title, part, color, pill, qno, q, stretch=False, sec=None, hints=None, kicker_zh="冷答", steps=True, again=False):
    """A spoken question card with timer; `hints` adds the Stuck? scaffold."""
    st = '<span class="stretch">Stretch · 说不出可以跳过</span>' if stretch else ""
    stp = ('<p class="steps"><span>Think <b>10 s</b></span><span class="arr">→</span><span>Speak <b>30–45 s</b></span></p>' if steps else
           '<p class="steps"><span>No notes</span><span class="arr">·</span><span>Say it better</span></p>')
    return section(sid, "judge", title, part, f'''
{head(pill, color, kicker_zh, REC)}
<div class="q-body" data-beat>
  <div class="card index-card q-card"><span class="badge q-badge c-{color}">Question {qno}</span>{st}<p class="q-text">{E(q)}</p></div>
  <div class="tool-row">{timer(sec) if sec else ""}{stp}{stuck_hints(hints) if hints else ""}</div>
</div>''', cls="q-scene" + (" again" if again else ""))


def steps3(sid, title, part, pill, color, zh, headline, steps, footnote="", right=""):
    """Three step cards with arrows. steps: [(icon, en, zh, sub)]."""
    hy = ""
    for i, (ic, en, z, sub) in enumerate(steps, 1):
        arrow = '<span class="hy-arrow" aria-hidden="true">→</span>' if i < len(steps) else ""
        hy += (f'<div class="hy-step" data-beat><div class="card hy-card"><span class="num">{i}</span>{icon(ic, "hy-ic")}'
               f'<p class="hy-en">{E(en)}</p><p class="hy-zh">{E(z)}</p><p class="hy-sub">{E(sub)}</p></div>{arrow}</div>')
    fn = f'<p class="foot-note">{E(footnote)}</p>' if footnote else ""
    return section(sid, "teach", title, part, f'''
{head(pill, color, zh, right)}
<h2 class="title">{E(headline)}</h2>
<div class="hy-row">{hy}</div>{fn}''')


def task_card(sid, title, part, color, pill, zh, text_en, tag):
    return section(sid, "teach", title, part, f'''
{head(pill, color, zh)}
<div class="task-body" data-beat>
  <div class="card index-card task-card"><p class="task-en">{E(text_en)}</p>
  <p class="task-do">Write one paragraph <span class="tag">{E(tag)}</span></p></div>
</div>''')


def ladder(sid, title, part, color, pill, zh, rungs, sample_tag=""):
    """Step ladder. rungs: [(label, name, zh, example_en)] — up to 4; label is the short chip text."""
    cols = ["navy", "mustard", "teal", "sky"]
    ld = ""
    for i, (lab, name, z, ex) in enumerate(rungs):
        ld += (f'<div class="step st{i}" data-beat><div class="card step-card"><p class="step-lab">'
               f'<span class="step-k c-{cols[i]}">{E(lab)}</span><span class="step-name">{E(name)}</span>'
               f'<span class="step-zh">{E(z)}</span></p><p class="step-ex">{E(ex)}</p></div></div>')
    tag = f'<span class="sample-tag">{E(sample_tag)}</span>' if sample_tag else ""
    return section(sid, "teach", title, part, f'''
{head(pill, color, zh, tag)}
<div class="ladder">{ld}</div>''')


def before_after(sid, part, color, bad, good_html, why_html, secs=None, prompt_zh="写成“改前 → 改后”，再写一句：我为什么改。", note_en="This one is a sample, not from your paragraph."):
    """good_html / why_html are raw (may contain <b>…</b>)."""
    return section(sid, "rewrite", "Before / After", part, f'''
{head("Before → After", color, "选两句改得最多的", timer(secs) if secs else "")}
<div class="ba-body">
  <div class="card index-card ba-card" data-beat><span class="ba-tag">Before · 改前</span><p class="ba-bad">{E(bad)}</p></div>
  <div class="ba-tools" data-beat>
    <p class="fix-prompt">{E(prompt_zh)}<span>{E(note_en)}</span></p>
    <div class="look-wrap"><button type="button" class="look">看对照</button>
      <div class="contrast fix-good card" hidden><span class="ok-dot" aria-hidden="true">✓</span>
        <p class="fix-good-en">{good_html}</p><p class="fix-note">{why_html}</p></div></div>
  </div>
</div>''')


def timed_task(sid, title, part, color, pill, zh, secs, rules, ladder_chips=(), chip_note=""):
    """Big timer + three rule cards. rules: [(en, zh)]."""
    rl = "".join(f'<div class="card wr"><span class="num">{i}</span><p>{E(en)}<span>{E(z)}</span></p></div>' for i, (en, z) in enumerate(rules, 1))
    lad = ""
    if ladder_chips:
        lad = '<p class="wr-ladder">' + "→".join(f"<span>{E(c)}</span>" for c in ladder_chips) + (f"<em>{E(chip_note)}</em>" if chip_note else "") + "</p>"
    return section(sid, "teach", title, part, f'''
{head(pill, color, zh)}
<div class="write-body" data-beat>
  {timer(secs, big=True)}
  <div class="write-rules">{rl}{lad}</div>
</div>''')


def break_scene(minutes=5, part="", sid="break", zh="站起来，喝口水。"):
    word = {5: "Five", 3: "Three", 10: "Ten", 2: "Two", 4: "Four"}.get(minutes, str(minutes))
    return section(sid, "cover", "休息", part, f'''
<div class="brk" data-beat>
  <div class="brk-art">{icon("cup", "brk-ic")}</div>
  <div><span class="pill p-navy">Break</span><h1 class="brk-title">{word} minutes.</h1><p class="brk-zh">{E(zh)}</p>{timer(minutes * 60)}</div>
</div>''')


def note_grid(sid, title, part, color, pill, zh, cells, rules):
    """Listening note grid (what students fill on paper; the screen shows only the headings).
    cells: [(heading, sub, kind)] with kind '' | 'arrow' (old → new) | 'three' ($ / included / extra, or 3 labels in sub split by '·').
    rules: [(en, zh)] chips above the grid."""
    cg = ""
    for i, (h, sub, kind) in enumerate(cells, 1):
        if kind == "arrow":
            inner = '<div class="nc-split"><span class="blank"></span><span class="nc-arr">→</span><span class="blank"></span></div>'
        elif kind == "three":
            labs = [s.strip() for s in sub.split("·")]
            inner = '<div class="nc-three">' + "".join(f'<span><i>{E(l)}</i><span class="blank"></span></span>' for l in labs) + "</div>"
        else:
            inner = '<span class="blank wide"></span>'
        s2 = f'<span class="nc-sub">{E(sub)}</span>' if sub and kind != "three" else ""
        if kind == "arrow" and sub:
            s2 = f'<span class="nc-sub">{E(sub)}</span>'
        cg += (f'<div class="card ncell{" wide" if kind == "three" else ""}"><p class="nc-h"><span class="badge">{i}</span>{E(h)}{s2}</p>{inner}</div>')
    ch = "".join(f'<span class="chip-s">{E(en)} <em>{E(z)}</em></span>' for en, z in rules)
    return section(sid, "teach", title, part, f'''
{head(pill, color, zh)}
<div class="lrules" data-beat>{ch}</div>
<div class="ngrid" data-beat>{cg}</div>''')


def listening(sid, title, part, src, plays=2, gap=45, pill="Listening", color="sky", zh="听", art_top="LISTENING", art_main="1 / 2", label="Listening", chime=False):
    """THE listening scene: real-voice audio, play counter, auto gap countdown. No transcript on screen.
    src is relative to lesson.html, e.g. audio/listening.mp3 (see scripts/stage_tts.py).
    The player is silent apart from the recording; chime=True adds the exam-style bell before each play, the gap-end
    notes and the done fanfare (emits data-chime="1"; the default markup is unchanged)."""
    return section(sid, "cover", title, part, f'''
{head(pill, color, zh)}
<div class="listen-stage" data-beat>
  <div class="listen-art" data-top="{E(art_top)}" data-main="{E(art_main)}">{cassette(art_top, art_main, PALETTE[color], True, "B")}</div>
  <div class="listen" data-src="{E(src)}" data-plays="{plays}" data-gap="{gap}" data-label="{E(label)}"{' data-chime="1"' if chime else ''}></div>
</div>''')


def listen_question(sid, i, n, q, answer, part="listen", color="sky", focus_zh=""):
    """Question card + 看对照 with the model full-sentence answer (required: a task with a key must be checkable on screen)."""
    focus = f'<p class="focus" data-beat><span class="pill p-{color}">Careful</span>{E(focus_zh)}</p>' if focus_zh else ""
    return section(sid, "judge", f"听后回答 {i}", part, f'''
{head("Listen · Answer", color, "用完整句回答", count(i, n))}
<div class="q-body" data-beat>
  <div class="card index-card q-card"><span class="badge q-badge c-{color}">Question {i}</span><p class="q-text">{E(q)}</p></div>
  <div class="tool-row"><p class="full-s">Answer in a full sentence.</p>
    <div class="look-wrap"><button type="button" class="look">看对照</button>
      <div class="contrast fix-good card" hidden><span class="ok-dot" aria-hidden="true">✓</span><p class="fix-good-en">{E(answer)}</p></div></div></div>
</div>{focus}''', cls="q-scene lq")


def _grid_cells(cells):
    cg = ""
    for i, (h, sub, kind) in enumerate(cells, 1):
        if kind == "arrow":
            inner = '<div class="nc-split"><span class="blank"></span><span class="nc-arr">→</span><span class="blank"></span></div>'
        elif kind == "three":
            labs = [s.strip() for s in sub.split("·")]
            inner = '<div class="nc-three">' + "".join(f'<span><i>{E(l)}</i><span class="blank"></span></span>' for l in labs) + "</div>"
        else:
            inner = '<span class="blank wide"></span>'
        s2 = f'<span class="nc-sub">{E(sub)}</span>' if sub and kind != "three" else ""
        cg += f'<div class="card ncell{" wide" if kind == "three" else ""}"><p class="nc-h"><span class="badge">{i}</span>{E(h)}{s2}</p>{inner}</div>'
    return cg


def note_listen(sid, title, part, src, cells, rules, plays=2, gap=45, color="sky", pill="Listen for numbers", zh="听数字 · 边听边记",
                done_msg="两遍听完。数一数：第一遍记到几格？两遍后几格？"):
    """THE listening page: the note grid AND the player on one screen (the student sees what to catch while the teacher plays).
    One beat, so nothing is hidden; leaving it early is held by the runtime (first Space flashes the player)."""
    ch = "".join(f'<span class="chip-s">{E(en)} <em>{E(z)}</em></span>' for en, z in rules)
    return section(sid, "teach", title, part, f'''
{head(pill, color, zh)}
<div class="lt" data-beat>
  <div class="lrules">{ch}</div>
  <div class="ngrid">{_grid_cells(cells)}</div>
  <div class="listen" data-layout="bar" data-src="{E(src)}" data-plays="{plays}" data-gap="{gap}" data-label="Listening" data-msg-done="{E(done_msg)}"></div>
</div>''', cls="lt-scene")


def note_check(sid, title, part, items, transcript=None, color="sky", pill="Check your notes", zh="核对笔记 · 一格一格看"):
    """After the questions: each note cell has its own 看对照; an optional 看原文 reveals the transcript last.
    items: [(heading, answer_text)]"""
    nk = "".join(f'<div class="card ncell nk"><p class="nc-h"><span class="badge">{i}</span>{E(h)}</p>'
                 f'<div class="look-wrap"><button type="button" class="look">看对照</button><div class="contrast nk-ans" hidden><p>{E(a)}</p></div></div></div>'
                 for i, (h, a) in enumerate(items, 1))
    tr = (f'<div class="look-wrap nk-script" data-beat><button type="button" class="look">看原文（核对完再看）</button>'
          f'<div class="contrast card nk-text" hidden><p>{E(transcript)}</p></div></div>') if transcript else ""
    return section(sid, "teach", title, part, f'''
{head(pill, color, zh, '<span class="count">数一数：记对了几格</span>')}
<div class="ngrid nkgrid" data-beat>{nk}</div>
{tr}''')


def why_passes(sid, part, pill, color, zh, headline, question_zh, sentence_html, passes, note_html):
    """Explain a multi-pass routine with ONE worked sentence: it has N mistakes; each pass highlights the one it finds.
    sentence_html: raw, wrap each error as <span class="e e1">…</span> (e1…e3).
    passes: [(label_en, label_zh, code_tiles_html, fix_html, why_zh)]  (fix_html raw: <s>old</s> → <b>new</b>)"""
    ps = ""
    for i, (en, z, tiles, fix, why) in enumerate(passes, 1):
        ps += (f'<div class="card why-pass wp{i}" data-beat><p class="wp-h"><span class="badge">{i}</span>{E(en)} <span class="zh">{E(z)}</span>'
               f'<span class="wp-codes">{tiles}</span></p><p class="wp-fix">{fix}</p><p class="wp-why">{E(why)}</p></div>')
    return section(sid, "teach", zh, part, f'''
{head(pill, color, zh)}
<h2 class="title">{E(headline)}</h2>
<div class="why">
  <div class="card index-card why-sent" data-beat><p class="why-q">{question_zh}</p><p class="why-s">{sentence_html}</p></div>
  <div class="why-passes" style="--n:{len(passes)}">{ps}</div>
  <p class="why-note" data-beat>{note_html}</p>
</div>''')


def model_text(sid, part, segs, prompt_zh="先看自己的段落，再对照。", prompt_en="Compare the shape, not the words.", button="看参考段落", color="teal", pill="A model paragraph", zh="参考写法 · 不是唯一答案"):
    """Reference writing behind one 看对照. segs: [(tag, css_class, text)] with css_class in s-side|s-a|s-b|s-c|s-x."""
    sg = "".join(f'<span class="seg {c}"><i>{E(t)}</i>{E(x)}</span>' for t, c, x in segs)
    return section(sid, "teach", zh, part, f'''
{head(pill, color, zh)}
<div class="model-body" data-beat>
  <p class="model-prompt">{E(prompt_zh)}<small>{E(prompt_en)}</small></p>
  <div class="look-wrap model-wrap"><button type="button" class="look">{E(button)}</button>
    <div class="contrast card model-card" hidden><p>{sg}</p></div></div>
</div>''')


def compare_table(sid, title, part, color, pill, zh, col_heads, rows, note_html):
    """col_heads: [(pill_text, pill_color, label_en, label_zh)]; rows: [str]; note_html raw."""
    th = "".join(f'<th><span class="pill p-{c}">{E(p)}</span> {E(en)}<span>{E(z)}</span></th>' for p, c, en, z in col_heads)
    tr = "".join(f'<tr><th>{E(r)}</th>' + '<td><span class="blank"></span></td>' * len(col_heads) + "</tr>" for r in rows)
    return section(sid, "teach", title, part, f'''
{head(pill, color, zh)}
<div class="ctable-wrap" data-beat>
<table class="ctable card"><thead><tr><th></th>{th}</tr></thead><tbody>{tr}</tbody></table>
</div>
<p class="ct-note" data-beat>{note_html}</p>''')


def homework(sid, title, part, plan_zh, items, block=True):
    """items: [(key, en, minutes_text, color, zh)]"""
    hw = "".join(f'<div class="card hw-card" data-beat><div class="hw-top"><span class="hw-k c-{col}">{E(k)}</span>'
                 f'<span class="hw-en">{E(en)}</span><span class="hw-min">{E(m)}</span></div><p class="hw-zh">{E(z)}</p></div>'
                 for k, en, m, col, z in items)
    return section(sid, "teach", title, part, f'''
{head("Daily Menu", "navy", "作业", f'<span class="hw-plan">{E(plan_zh)}</span>')}
<div class="hw-grid">{hw}</div>''', extra=f' data-block="{part}"' if block else "")


def send_two(sid, part, items, foot_zh=""):
    """items: [(icon, en, zh)]"""
    cards = "".join(f'<div class="card send-card" data-beat>{icon(ic, "send-ic")}<p class="send-en">{E(en)}</p><p class="send-zh">{E(z)}</p></div>' for ic, en, z in items)
    ft = f'<p class="foot-note" data-beat>{E(foot_zh)}</p>' if foot_zh else ""
    return section(sid, "teach", "交两样东西", part, f'''
{head("Send me two things", "navy", "下次课前发")}
<div class="send">{cards}</div>{ft}''')


def closing(title_lines, zh, art_label="SAY IT AGAIN", part="close"):
    lines = "<br>".join(E(x) for x in title_lines)
    return section("end", "cover", "下课", part, f'''
<div class="cover-grid end">
  <div class="cover-text">
    <div data-beat><span class="pill p-navy">See you next class</span><h1 class="cover-title sm">{lines}</h1></div>
    <div data-beat><p class="cover-zh">{E(zh)}</p></div>
  </div>
  <div class="cover-art"><div class="art-card" data-label="{E(art_label)}">{recorder(art_label)}{WAVES}</div></div>
</div>''')


# ───────────────────────── check-card family (error codes) ─────────────────────────
class Codes:
    """A set of colour-coded self-check codes, e.g. T/S/P/N/J. icons: {key: svg-inner (48×48)}.
    codes: {key: dict(color, name, q, rule)}"""

    def __init__(self, codes: dict, icons: dict):
        self.codes, self.icons = codes, icons

    def ic(self, k, cls):
        return (f'<svg class="{cls}" viewBox="0 0 48 48" aria-hidden="true" fill="none" stroke="#1d2a4d" '
                f'stroke-width="3" stroke-linecap="round" stroke-linejoin="round">{self.icons[k]}</svg>')

    def tile(self, k, cls="tile"):
        c = self.codes[k]
        return f'<span class="{cls} c-{c["color"]}"><span class="tile-letter">{k}</span>{self.ic(k, "tile-ic")}</span>'

    def card(self, k):
        c = self.codes[k]
        return (f'<div class="card code-card cc-{c["color"]}"><div class="cc-top c-{c["color"]}"><span class="cc-letter">{k}</span>'
                f'{self.ic(k, "cc-ic")}<span class="cc-name">{E(c["name"])}</span></div>'
                f'<div class="cc-body"><p class="cc-q">{E(c["q"])}</p><p class="cc-rule">{E(c["rule"])}</p></div></div>')

    def check_card_scene(self, sid, passes, headline, strip_html, part, secs=None):
        """passes: [(label_en, label_zh, [keys])]"""
        ps = ""
        for i, (en, z, keys) in enumerate(passes, 1):
            ps += (f'<div class="pass p{len(keys)}" data-beat><p class="pass-h"><span class="badge">{i}</span>{E(en)} <span class="zh">{E(z)}</span></p>'
                   f'<div class="pass-cards">{"".join(self.card(k) for k in keys)}</div></div>')
        return section(sid, "teach", "自查卡", part, f'''
{head("Check Card", "navy", "自查卡 · 顺序固定")}
<h2 class="title">{E(headline)}</h2>
<div class="passes">{ps}</div>
<div class="check-strip" data-beat>
  <p>{strip_html}</p>
  {timer(secs) if secs else ""}
</div>''')

    def menu_scene(self, sid, part, headline, note_zh, next_id, keys=None):
        keys = keys or list(self.codes)
        mc = ""
        for k in keys:
            c = self.codes[k]
            mc += (f'<button type="button" class="menu-card card cc-{c["color"]}" data-jump="{k}" data-remember>'
                   f'<span class="mc-top c-{c["color"]}"><span class="mc-letter">{k}</span>{self.ic(k, "mc-ic")}</span>'
                   f'<span class="mc-name">{E(c["name"])}</span><span class="mc-q">{E(c["q"])}</span></button>')
        return section(sid, "choose", "小讲解 · 选一张小卡", part, f'''
{head("Mini lesson", "navy", "小讲解 · 只讲一两张")}
<h2 class="title">{E(headline)}</h2>
<div class="menu-grid" data-beat>{mc}</div>
<p class="menu-note">{E(note_zh)}</p>''', extra=f' data-next="{next_id}"')

    def block(self, k, menu_id, next_id, rule_zh, fixes, make_zh, make_starter, part="r1"):
        """Mini-lesson branch for one code: rule → 3 cold fixes → make-your-own. Branch scenes are excluded from progress.
        fixes: [(bad, good_html, note)] (good_html raw so you can bold the repair)."""
        c, col = self.codes[k], self.codes[k]["color"]
        pill = f'{k} · {c["name"]}'
        out = section(f"{k}-rule", "teach", f"小卡 {k} · 规则", part, f'''
{head(pill, col, "小卡 · 规则", '<span class="count">规则</span>')}
<div class="rule-hero">
  <div class="card big-tile-card" data-beat>{self.tile(k, "tile huge")}<div class="bt-text"><p class="bt-name">{E(c["name"])}</p><p class="bt-q">{E(c["q"])}</p></div></div>
  <div class="card rule-card-big rc-{col}" data-beat><span class="pill p-navy">规则</span><p class="rule-zh">{E(rule_zh)}</p></div>
</div>''', cls=f"code-{col}", extra=f' data-block="{k}" data-branch data-prev="{menu_id}"')
        for i, (bad, good, note) in enumerate(fixes, 1):
            nt = f'<p class="fix-note">{E(note)}</p>' if note else ""
            out += section(f"{k}{i}", "rewrite", f"小卡 {k} · 冷修复 {i}", part, f'''
{head(pill, col, "冷修复", f'<span class="count">{i} / {len(fixes)}</span>')}
<div class="fix-body">
  <div class="card index-card fix-card" data-beat>{self.tile(k, "tile small")}<p class="fix-bad">{E(bad)}</p></div>
  <div class="fix-tools" data-beat>
    <p class="fix-prompt">改一下，说为什么。<span>Fix it. Say why.</span></p>
    <div class="look-wrap"><button type="button" class="look">看对照</button>
      <div class="contrast fix-good card" hidden><span class="ok-dot" aria-hidden="true">✓</span><p class="fix-good-en">{good}</p>{nt}</div></div>
  </div>
</div>''', cls=f"code-{col}", extra=" data-branch")
        out += section(f"{k}-make", "teach", f"小卡 {k} · 自己造", part, f'''
{head(pill, col, "自己造一句", REC)}
<div class="make-body" data-beat>
  <div class="card index-card make-card">{self.tile(k, "tile small")}<p class="make-zh">{E(make_zh)}</p><p class="make-starter">{E(make_starter)}</p></div>
  <p class="make-sub">说出来，录下来。然后：再答一遍。</p>
</div>''', cls=f"code-{col}", extra=f' data-branch data-next="{next_id}"')
        return out


# ───────────────────────── page wrapper ─────────────────────────
SND_BUTTON = ('<button type="button" id="snd" class="snd-btn" aria-pressed="true" aria-label="音效">'
              '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 9h4l5-4v14l-5-4H4z"/>'
              '<path class="snd-wave" d="M16.5 9a4.5 4.5 0 0 1 0 6M19 6.5a8 8 0 0 1 0 11"/>'
              '<path class="snd-x" d="M16 9l5 6M21 9l-5 6"/></svg><span>音效</span></button>')


def _theme_marks(scenes, rail):
    """Themed pages only: stamp every <section class="scene"> (a builder may return several) with data-no / data-total
    (main-path position; branch scenes carry their anchor's number) and data-part-label, so a theme can print folios,
    cue numbers or running heads from CSS (content: attr(data-no)). Default (D3) pages are not touched."""
    labels = {p: t for p, t, _c in rail}
    html_all = "".join(scenes)
    opens = list(re.finditer(r'<section class="scene[^>]*>', html_all))
    total = sum(1 for m in opens if " data-branch" not in m.group(0))
    n = 0
    def stamp(m):
        nonlocal n
        tag = m.group(0)
        if " data-branch" not in tag:
            n += 1
        pm = re.search(r'data-part="([^"]*)"', tag)
        lab = f' data-part-label="{E(labels.get(pm.group(1), ""))}"' if pm and pm.group(1) in labels else ""
        return tag.replace('<section class="scene', f'<section data-no="{max(n, 1):02d}" data-total="{total:02d}"{lab} class="scene', 1)
    return [re.sub(r'<section class="scene[^>]*>', stamp, html_all)]


def page(scenes, title, brand, rail, nav_jumps=(("路线", "route"),), html_lang="zh-CN", audio=True, theme=None):
    """rail: [(part, label, color)]; nav_jumps: left-hand quick jumps [(label, scene_id)].
    theme: name of a css/theme-<name>.css layer loaded after the runtime CSS (tokens, type, shapes); same DOM, same QA."""
    rl = "".join(f'<button type="button" class="rail-tab c-{c}" data-part-tab="{p}" data-jump="{p}">{E(t)}</button>' for p, t, c in rail)
    nj = "".join(f'<button type="button" data-jump="{sid}">{E(lab)}</button>' for lab, sid in nav_jumps)
    css_a = '<link rel="stylesheet" href="css/stage-audio.css">\n' if audio else ""
    js_a = '<script src="js/stage-audio.js"></script>\n' if audio else ""
    snd = SND_BUTTON if audio else ""
    th_a = f'<link rel="stylesheet" href="css/theme-{theme}.css">\n' if theme else ""
    if theme:
        scenes = _theme_marks(scenes, rail)
    th_b = f' data-theme="{theme}"' if theme else ""
    return f'''<!DOCTYPE html>
<html lang="{html_lang}"{th_b}>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{E(title)}</title>
<link rel="stylesheet" href="css/deck.css">
<link rel="stylesheet" href="css/stage-extra.css">
{css_a}{th_a}</head>
<body>
<div class="progress"><div class="progress-fill" id="bar"></div></div>
<main class="deck">
{"".join(scenes)}
</main>
<nav class="rail" aria-label="章节">{rl}</nav>
<nav class="nav" aria-label="翻页">
  <div class="nav-l">
    {nj}
    <button type="button" id="prev">← 上一拍</button>
  </div>
  <span class="mid" id="pos">封面</span>
  <div class="nav-r"><span class="brand">{E(brand)}</span>{snd}<button type="button" id="next" class="next">下一拍 →</button></div>
</nav>
<script src="vendor/gsap.min.js"></script>
<script src="js/deck.js"></script>
{js_a}</body>
</html>
'''
