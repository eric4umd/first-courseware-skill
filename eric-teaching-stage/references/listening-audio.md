# Listening audio — natural voice, exam-ready

Goal: a clip a student can mistake for a person on a call, that tests listening and not "decoding a robot".

## 1. Half of "natural" is the script

TTS reads whatever you give it. Write for the ear, not the eye.

- Contractions everywhere (I'd, we're, it's). Short clauses, one idea each. Average sentence 8–14 words.
- Spoken openers and repairs belong: "Hi, this is…", "Oh, and…", "Sorry, I mean…", "so that's…". For IELTS-style traps add a self-correction: "It starts at seven thirty — sorry, seven forty-five." The correction is the tested number; mark it in the answer key, not in the script.
- Numbers: write what the speaker would say. `Room 204{two oh four}`, `$12{twelve dollars}`, `6:30` (auto → "six thirty"), `3B{three B}`. The braces change only what is *spoken*; the transcript keeps `204`. Dates: "the third of May" / "May third" — pick one and match the lesson's convention. Phone numbers: digits with pauses: `0 7 3 5 {oh seven three five}`.
- Names and spellings that will be dictated: spell via pauses, one letter per line with `(pause 0.25)` if the task is spelling.
- Avoid read-aloud-only constructions: lists with "firstly… secondly…" for 40 words, parentheticals, long noun stacks.
- Pace for the learner level (starting points, not measured norms): lower levels ≈ 130–150 wpm, upper-intermediate ≈ 150–170, exam-like ≈ 160–180. The tool reports wpm after rendering; the default voice rate −6 % lands near 160 wpm in the original sample clips.

## 2. Speakers

`[Name] text` lines. Each speaker gets one voice: `--voice marco=@male --voice yuna=@female`. Two voices of different gender and register make a dialogue easy to follow (IELTS Parts 1 and 3 are conversations; Parts 2 and 4 are monologues). Gap between turns: 0.45 s default (`--gap`), `(pause 0.3)` for hesitation. Start with short turns; a dialogue where every turn is one sentence is easier to follow than long paragraphs per speaker.

## 3. Engines and voices

Presets live in `~/.local/share/eric-stage-tts/voices.json` (`@female`, `@male`, offline variants). Edit them after the teacher's audition.

| Engine | Voice examples (US) | Notes |
|---|---|---|
| `edge` | en-US-AvaMultilingualNeural, EmmaMultilingualNeural, JennyNeural, MichelleNeural / AndrewMultilingualNeural, BrianMultilingualNeural | needs internet *when rendering only*; unofficial endpoint (see SKILL.md); sandboxes need the proxy — the tool reads `HTTPS_PROXY` |
| `kokoro` | af_heart, af_bella, af_sarah / am_michael, am_adam | offline, Apache-2.0; `bf_*` / `bm_*` are British |
| `eleven` | voice_id | paid, optional |

Other accents (en-GB-SoniaNeural, en-AU-NatashaNeural, en-CA-ClaraNeural, en-IN-NeerjaNeural for edge) for exam variety. Never describe a voice as "natural" or "human" in a report — say which voice and that the teacher must listen.

Rate: `@-6%` (edge) or `@0.95` (kokoro). Slower for lower levels; do not exceed −15 % — it starts to sound like a lesson recording rather than a person.

## 4. Pipeline (what `render` does)

per line → synth → trim head/tail silence → add gap/pauses → 24 kHz mono → concatenated → `loudnorm` to −16 LUFS, true peak −1.5 dB → 44.1 kHz mp3 128 k. A `.json` beside the mp3 holds duration, wpm, voices and a per-line timeline (start/end seconds) — use it to time teacher notes, never to show text.

## 5. Always check

`stage_tts.py check clip.mp3 listening.txt` runs Whisper (`small.en`, local) over the clip and compares: word match (expect ≥ 90 %; "ID", "third → 3rd" and punctuation cause the rest) and **every number** (digits, "two thirty", "one eighteen" are canonicalized). Any "!! numbers not recovered" means the voice garbled it — change the markup (`{spoken}`), the voice, or the sentence, and re-render. This catches mispronounced numbers; it cannot judge warmth, rhythm or accent. The teacher listens.

## 6. Teacher audition

1. Run `audition` on the lesson's real script (default: 5 US voices on edge, 4 on kokoro). It writes a page of `<audio>` controls; open it, do not autoplay.
2. The teacher picks 1–2 voices; save to `voices.json`.
3. For a dialogue pick two contrasting voices; render the dialogue once and ask the teacher to listen to the *turn-taking* (gaps), not only the voices.
4. Keep the chosen preset for later lessons so the class gets one familiar "teacher assistant" voice.

## 7. Playing it in class

`<div class="listen" data-src="audio/listening.mp3" data-plays="2" data-gap="45">` (via `stage_kit.listening`). Flow: Play 1 → (a 0.3 s beat) → clip → gap ring counts down (note-taking time) → Play 2 ready → done. The player makes no sound of its own by default. `stage_kit.listening(..., chime=True)` (`data-chime="1"`) brings all three back for one deck. Afterwards a small "再听一次（核对用）" link allows a check replay. `data-auto2="1"` starts Play 2 by itself after the gap (default off: teacher presses). P = play/pause. Leaving the scene resets it. If the file fails to load, the status line tells the teacher to read the script aloud — the teacher PDF carries the script.

Tencent Meeting: tick 共享电脑声音 when sharing. Test once with the student before relying on it; sound can arrive slightly late or compressed.

### Teacher note for any deck with audio (paste into the lesson README or the teacher PDF, in the same pass as the deck)

> 上网课注意（有声版）：① 共享屏幕时勾选"共享电脑声音"，否则学生听不到听力；② 听力是 AI 合成的语音（声音可按同名替换音频文件）；③ 如果音频放不出来，老师按教师册里的听力朗读稿自己读，网页上的状态行会提示文件没加载；④ 听力页只播放录音，没有提示铃；其余页面的音效很轻，会议软件可能压掉，不影响上课（M 键开关）。
