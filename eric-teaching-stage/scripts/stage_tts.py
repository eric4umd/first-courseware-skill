#!/usr/bin/env python3
"""stage_tts.py — natural-sounding listening audio for classroom decks.

Sub-commands
  render    script.txt  -> mp3 (+ .json timing/report)   (one or more speakers)
  audition  script.txt  -> folder of the same script in several voices + index.html
  check     mp3 script  -> Whisper round-trip: do numbers / words survive?
  voices                -> list voices the engines know

Script format (plain text, UTF-8)
  [Dana] Hi, this is Dana from the Tuesday study group.   speaker line
  Printing costs $12{twelve dollars} a month.               display{spoken}: TTS says the
                                                           braces, the transcript shows $12
  (pause 0.8)                                              silence, seconds
  # comment                                                ignored
Lines with no [Speaker] continue the previous speaker (default: narrator).

Engines (voice spec = engine:voice[@rate])
  edge:en-US-AvaMultilingualNeural@-6%     free Microsoft neural voices, needs internet
                                           when rendering (unofficial endpoint — see SKILL.md)
  kokoro:af_heart@0.95                     Kokoro-82M, Apache-2.0, fully offline
  eleven:<voice_id>                        optional, paid; reads ELEVENLABS_API_KEY only

Runtime lives in $STAGE_TTS_HOME (default ~/.local/share/eric-stage-tts): venv/ + models/.
"""
from __future__ import annotations

import argparse
import asyncio
import difflib
import html
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HOME = Path(os.environ.get("STAGE_TTS_HOME", Path.home() / ".local/share/eric-stage-tts"))
MODELS = HOME / "models"
SR = 24000


# ───────────────────────── script parsing ─────────────────────────
def parse_script(text: str):
    """-> list of dict(kind='say'|'pause', speaker, spoken, display, seconds)."""
    items, speaker = [], "narrator"
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        m = re.fullmatch(r"\(pause\s+([0-9.]+)\)", line, re.I)
        if m:
            items.append(dict(kind="pause", seconds=float(m.group(1))))
            continue
        m = re.match(r"\[([^\]]+)\]\s*(.*)", line)
        if m:
            speaker, line = m.group(1).strip().lower(), m.group(2).strip()
        if not line:
            continue
        display, spoken = split_markup(line)
        items.append(dict(kind="say", speaker=speaker, display=display, spoken=spoken))
    return items


def split_markup(line: str):
    """`204{two oh four}` -> display `204`, spoken `two oh four`. Auto-rules for $ and times."""
    display = re.sub(r"\{[^}]*\}", "", line)
    spoken = re.sub(r"(\S+?)\{([^}]*)\}", lambda m: m.group(2), line)
    spoken = auto_spoken(spoken)
    return display, spoken


_ONES = "zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen".split()
_TENS = "_ _ twenty thirty forty fifty sixty seventy eighty ninety".split()


def say_int(n: int) -> str:
    if n < 20:
        return _ONES[n]
    if n < 100:
        return _TENS[n // 10] + ("" if n % 10 == 0 else " " + _ONES[n % 10])
    if n < 1000:
        return _ONES[n // 100] + " hundred" + ("" if n % 100 == 0 else " " + say_int(n % 100))
    if n < 1_000_000:
        return say_int(n // 1000) + " thousand" + ("" if n % 1000 == 0 else " " + say_int(n % 1000))
    return str(n)


def auto_spoken(s: str) -> str:
    # $12 / $12.50
    def money(m):
        d, c = m.group(1).replace(",", ""), m.group(2)
        out = say_int(int(d)) + (" dollar" if int(d) == 1 else " dollars")
        if c and int(c):
            out += " and " + say_int(int(c)) + " cents"
        return out

    s = re.sub(r"\$(\d[\d,]*)(?:\.(\d\d))?", money, s)
    # 6:30 / 6:30 pm / 10:05
    def clock(m):
        h, mi = int(m.group(1)), int(m.group(2))
        spoken = say_int(h) + (" o'clock" if mi == 0 else (" oh " + say_int(mi) if mi < 10 else " " + say_int(mi)))
        return spoken

    s = re.sub(r"\b(\d{1,2}):(\d\d)\b", clock, s)
    s = re.sub(r"(\d+)\s?%", lambda m: say_int(int(m.group(1))) + " percent", s)
    s = re.sub(r"(\d+)¢", lambda m: say_int(int(m.group(1))) + " cents", s)
    s = re.sub(r"\b(\d{1,3}(?:,\d{3})+|\d+)\b", lambda m: say_int(int(m.group(1).replace(",", ""))), s)
    return s


# ───────────────────────── voices ─────────────────────────
def presets() -> dict:
    """Named voices from $STAGE_TTS_HOME/voices.json, e.g. {"female": "edge:en-US-AvaMultilingualNeural@-6%"}.
    Use them as `--voice dana=@female`. Eric's chosen voices live there, not in the skill."""
    f = HOME / "voices.json"
    try:
        return json.loads(f.read_text(encoding="utf-8"))
    except Exception:
        return {}


def parse_voice(spec: str):
    if spec.startswith("@"):
        spec = presets().get(spec[1:]) or sys.exit(f"voice preset {spec!r} not found in {HOME/'voices.json'}")
    eng, _, rest = spec.partition(":")
    voice, _, rate = rest.partition("@")
    return eng, voice, rate or None


async def _edge(text: str, voice: str, rate: str | None, out_mp3: Path):
    import edge_tts

    kw = {}
    if rate:
        kw["rate"] = rate if rate.endswith("%") else f"{float(rate)*100-100:+.0f}%"
    proxy = os.environ.get("HTTPS_PROXY") or os.environ.get("https_proxy")  # sandboxes route through a proxy
    comm = edge_tts.Communicate(text, voice, proxy=proxy, **kw)
    await comm.save(str(out_mp3))


_kokoro = None


def _kokoro_synth(text: str, voice: str, rate: str | None, out_wav: Path):
    global _kokoro
    import soundfile as sf
    from kokoro_onnx import Kokoro

    if _kokoro is None:
        _kokoro = Kokoro(str(MODELS / "kokoro-v1.0.onnx"), str(MODELS / "voices-v1.0.bin"))
    samples, sr = _kokoro.create(text, voice=voice, speed=float(rate or 1.0), lang="en-us")
    sf.write(str(out_wav), samples, sr)


def _eleven(text: str, voice: str, rate: str | None, out_mp3: Path):
    import urllib.request

    key = os.environ.get("ELEVENLABS_API_KEY")
    if not key:
        sys.exit("ELEVENLABS_API_KEY is not set in this process (optional paid engine).")
    req = urllib.request.Request(
        f"https://api.elevenlabs.io/v1/text-to-speech/{voice}?output_format=mp3_44100_128",
        data=json.dumps({"text": text, "model_id": "eleven_multilingual_v2"}).encode(),
        headers={"xi-api-key": key, "Content-Type": "application/json"},
    )
    out_mp3.write_bytes(urllib.request.urlopen(req).read())


def synth(text: str, spec: str, tmp: Path, tag: str) -> Path:
    eng, voice, rate = parse_voice(spec)
    if eng == "edge":
        p = tmp / f"{tag}.mp3"
        for attempt in range(3):
            try:
                asyncio.run(_edge(text, voice, rate, p))
                break
            except Exception as e:  # network hiccup
                if attempt == 2:
                    raise
                print("  edge retry:", e, file=sys.stderr)
    elif eng == "kokoro":
        p = tmp / f"{tag}.wav"
        _kokoro_synth(text, voice, rate, p)
    elif eng == "eleven":
        p = tmp / f"{tag}.mp3"
        _eleven(text, voice, rate, p)
    else:
        sys.exit(f"unknown engine {eng!r}")
    return p


# ───────────────────────── audio assembly ─────────────────────────
def ff(*args):
    r = subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *args], capture_output=True, text=True)
    if r.returncode:
        sys.exit("ffmpeg: " + r.stderr)


def duration(p: Path) -> float:
    r = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(p)], capture_output=True, text=True)
    return float(r.stdout.strip())


def to_wav(src: Path, dst: Path):
    # trim leading/trailing silence of each segment, mono 24k
    ff("-i", str(src), "-ac", "1", "-ar", str(SR),
       "-af", "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.03,areverse,"
              "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.03,areverse",
       str(dst))


def silence(sec: float, dst: Path):
    ff("-f", "lavfi", "-i", f"anullsrc=r={SR}:cl=mono", "-t", f"{sec}", str(dst))


def render(items, voices: dict, out: Path, gap: float = 0.45, head: float = 0.35, tail: float = 0.6):
    out.parent.mkdir(parents=True, exist_ok=True)
    tmp = Path(tempfile.mkdtemp(prefix="stage_tts_"))
    parts, timeline, t = [], [], 0.0

    def add(wav: Path, meta=None):
        nonlocal t
        d = duration(wav)
        if meta:
            timeline.append(dict(meta, start=round(t, 2), end=round(t + d, 2)))
        parts.append(wav)
        t += d

    def add_sil(sec):
        p = tmp / f"sil{len(parts)}.wav"
        silence(sec, p)
        add(p)

    add_sil(head)
    last_was_say = False
    for i, it in enumerate(items):
        if it["kind"] == "pause":
            add_sil(it["seconds"])
            last_was_say = False
            continue
        if last_was_say:
            add_sil(gap)
        spec = voices.get(it["speaker"]) or voices.get("narrator") or next(iter(voices.values()))
        raw = synth(it["spoken"], spec, tmp, f"s{i}")
        w = tmp / f"s{i}.w.wav"
        to_wav(raw, w)
        add(w, dict(speaker=it["speaker"], text=it["display"]))
        last_was_say = True
    add_sil(tail)
    lst = tmp / "list.txt"
    lst.write_text("".join(f"file '{p}'\n" for p in parts))
    cat = tmp / "cat.wav"
    ff("-f", "concat", "-safe", "0", "-i", str(lst), "-c", "copy", str(cat))
    # loudness: -16 LUFS mono is comfortable through a video-call; true peak -1.5 dB
    ff("-i", str(cat), "-af", "loudnorm=I=-16:TP=-1.5:LRA=7", "-ar", "44100", "-ac", "1", "-codec:a", "libmp3lame", "-b:a", "128k", str(out))
    words = sum(len(it["display"].split()) for it in items if it["kind"] == "say")
    report = dict(file=out.name, seconds=round(duration(out), 1), words=words,
                  wpm=round(words / max(duration(out) - head - tail, 1) * 60), voices=voices, timeline=timeline)
    out.with_suffix(".json").write_text(json.dumps(report, ensure_ascii=False, indent=1))
    shutil.rmtree(tmp, ignore_errors=True)
    return report


# ───────────────────────── check (Whisper round trip) ─────────────────────────
_UNITS = {w: str(i) for i, w in enumerate(_ONES[:10])}
_UNITS["oh"] = "0"
_TEENS = {w: str(i) for i, w in enumerate(_ONES) if i >= 10}
_TY = {w: str(i * 10) for i, w in enumerate(_TENS) if w != "_"}


def digit_runs(text: str):
    """canonical list of numbers heard/read in text, as digit strings."""
    t = text.lower().replace(",", "")
    t = re.sub(r"\$(\d+(?:\.\d\d)?)", r"\1 ", t)
    t = re.sub(r"(\d+):(\d\d)", r"\1\2", t)
    toks = re.findall(r"[a-z']+|\d+", t)
    out, run, literal = [], "", False

    def flush():
        nonlocal run, literal
        if run:
            out.append(run)
        run, literal = "", False

    for w in toks:
        if w.isdigit():
            flush(); out.append(w); continue
        s = _UNITS.get(w) or _TEENS.get(w) or _TY.get(w) or ("00" if w == "hundred" else None)
        if s is None:
            flush(); continue
        if w in ("oh", "zero"):
            if not run:  # interjection ("Oh, and…"), not a digit
                continue
            run += "0"; literal = True
            continue
        z = len(run) - len(run.rstrip("0"))
        if run and not literal and z >= len(s) and w != "hundred" and z:
            run = run[:-len(s)] + s
        else:
            run += s
        literal = False
    flush()
    return out


def cmd_check(args):
    from faster_whisper import WhisperModel

    model = WhisperModel(args.model, device="cpu", compute_type="int8")
    import numpy as np

    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(args.audio), "-f", "f32le", "-ac", "1", "-ar", "16000", "-"],
                         capture_output=True, check=True).stdout
    segs, _ = model.transcribe(np.frombuffer(raw, dtype=np.float32), language="en", beam_size=5)
    heard = " ".join(s.text.strip() for s in segs)
    items = parse_script(Path(args.script).read_text(encoding="utf-8"))
    expected_spoken = " ".join(it["spoken"] for it in items if it["kind"] == "say")
    norm = lambda s: re.findall(r"[a-z']+", s.lower())
    e, h = norm(re.sub(r"\d+", "", expected_spoken)), norm(re.sub(r"\d+", "", heard))
    ratio = difflib.SequenceMatcher(None, e, h).ratio()
    en, hn = digit_runs(expected_spoken), digit_runs(heard)
    glued = "".join(hn)  # Whisper may write 6:30 as "6 30" or "6.30" — compare glued digits
    missing = [n for n in en if n not in hn and n not in glued]
    print("HEARD   :", heard)
    print(f"word match {ratio:.0%} · numbers expected {en} · heard {hn}")
    if missing:
        print("!! numbers not recovered:", missing)
    return 0 if (ratio > 0.9 and not missing) else 1


# ───────────────────────── audition ─────────────────────────
DEFAULT_AUDITION = [
    "edge:en-US-AvaMultilingualNeural@-6%",
    "edge:en-US-EmmaMultilingualNeural@-6%",
    "edge:en-US-JennyNeural@-6%",
    "edge:en-US-MichelleNeural@-6%",
    "edge:en-US-AndrewMultilingualNeural@-6%",
    "edge:en-US-BrianMultilingualNeural@-6%",
    "kokoro:af_heart@0.95",
    "kokoro:af_bella@0.95",
    "kokoro:am_michael@0.95",
    "kokoro:am_adam@0.95",
]


def cmd_audition(args):
    items = parse_script(Path(args.script).read_text(encoding="utf-8"))
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    specs = args.voice or DEFAULT_AUDITION
    rows = []
    for spec in specs:
        name = re.sub(r"[^A-Za-z0-9]+", "-", spec).strip("-")
        print("rendering", spec)
        try:
            rep = render(items, {"narrator": spec}, out / f"{name}.mp3")
            rows.append((spec, name, rep))
        except Exception as ex:  # keep going — one broken engine must not kill the sheet
            print("  failed:", ex, file=sys.stderr)
    body = "".join(
        f"<div class=c><b>{html.escape(spec)}</b><span>{rep['seconds']} s · {rep['wpm']} wpm</span>"
        f"<audio controls preload=none src='{name}.mp3'></audio></div>"
        for spec, name, rep in rows)
    (out / "index.html").write_text(
        "<!doctype html><meta charset=utf-8><meta name=viewport content='width=device-width,initial-scale=1'>"
        "<title>Voice audition</title><style>body{font:16px/1.5 -apple-system,system-ui;background:#fff8ec;color:#1d2a4d;max-width:760px;margin:32px auto;padding:0 16px}"
        ".c{background:#fff;border:2px solid #1d2a4d;border-radius:12px;box-shadow:4px 4px 0 #1d2a4d;padding:12px 16px;margin:14px 0;display:grid;gap:6px}"
        "span{color:#6a7390;font-size:13px}audio{width:100%}</style>"
        "<h1>Voice audition</h1><p>Same script, different voices. Nothing autoplays — press play. Tell me the ones that sound like a real person.</p>" + body,
        encoding="utf-8")
    print("wrote", out / "index.html")


def cmd_render(args):
    items = parse_script(Path(args.script).read_text(encoding="utf-8"))
    voices = {}
    for v in args.voice:
        who, _, spec = v.partition("=")
        voices[who.lower()] = presets().get(spec[1:], spec) if spec.startswith("@") else spec
    if not voices:
        sys.exit("--voice speaker=engine:voice required (e.g. --voice narrator=edge:en-US-AvaMultilingualNeural@-6%)")
    rep = render(items, voices, Path(args.out), gap=args.gap)
    print(json.dumps({k: rep[k] for k in ("file", "seconds", "words", "wpm")}))


def cmd_voices(_):
    print("edge: run `venv/bin/edge-tts --list-voices | grep en-US`")
    print("kokoro: af_heart af_bella af_nicole af_sarah af_sky am_adam am_michael am_fenrir am_puck (American); bf_*/bm_* are British")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("render"); r.add_argument("script"); r.add_argument("out"); r.add_argument("--voice", action="append", default=[]); r.add_argument("--gap", type=float, default=0.45); r.set_defaults(fn=cmd_render)
    a = sub.add_parser("audition"); a.add_argument("script"); a.add_argument("out"); a.add_argument("--voice", action="append"); a.set_defaults(fn=cmd_audition)
    c = sub.add_parser("check"); c.add_argument("audio"); c.add_argument("script"); c.add_argument("--model", default="small.en"); c.set_defaults(fn=cmd_check)
    v = sub.add_parser("voices"); v.set_defaults(fn=cmd_voices)
    args = ap.parse_args()
    sys.exit(args.fn(args) or 0)


if __name__ == "__main__":
    main()
