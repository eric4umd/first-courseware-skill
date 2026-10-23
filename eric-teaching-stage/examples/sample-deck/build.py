#!/usr/bin/env python3
"""Sample deck — a fictional lesson ("Study Room, Please") that exercises every kit component.

Copy this folder as the starting point of a real lesson:
    python3 ~/.agents/skills/eric-teaching-stage/scripts/stage_scaffold.py <new-folder> --title "…"
Then replace the CONTENT block. Nothing here is student data.

Build:  python3 build.py            -> lesson.html (next to this file, with runtime/ copied in)
Audio:  see ../../SKILL.md "Listening audio" — renders audio/listening.mp3 from listening.txt
"""
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent.parent / "scripts"))
sys.path.insert(0, str(HERE))  # when scaffolded: stage_kit.py sits beside build.py
import stage_kit as K  # noqa: E402

OUT = HERE / "lesson.html"

# ───────────────────────── CONTENT ─────────────────────────
CODES = K.Codes({
    "S": dict(color="teal", name="Single or plural", q="谁在做？一个还是几个？",
              rule="找到做事的人。一般现在时：he / she / it 加 -s；is / are、was / were 跟着人数变。A and B 是两个。"),
    "J": dict(color="mustard", name="Join", q="接口后面，这半句完整吗？",
              rule="whether / if / that / because 后面保持正常语序：主语 + 动词。"),
}, K.STD_CODE_ICONS)

S = []
S.append(K.cover(["Study Room,", "Please"], "订一间自习室", "Ask clearly. Listen for the numbers.", "问得清楚，听准数字",
                 "Sample Lesson", "示例课", 1, art_label="STUDY ROOM"))
S.append(K.route([
    ("mustard", "Warm-up", "中文 → 英语", "8 min"),
    ("tomato", "Round 1 · Say", "说 → 听自己 → 修", "25 min"),
    ("sky", "Listen", "听电话，记数字", "15 min"),
    ("navy", "Home", "日志和作业", "10 min")], headline="Four stops. One phone call."))
S.append(K.rules4("cold", "Cold answer", "tomato", "冷答：不准备，直接说", "First try, no warm-up. That's the point.", [
    ("notes", "No notes", "不看笔记"), ("think", "10 seconds to think", "先想 10 秒"),
    ("speak", "30–45 seconds", "每题 30–45 秒"), ("phone", "Your phone is recording", "手机一直在录音")], part="warm"))
S.append(K.rewrite("warm1", 1, 2, "warm", "Warm-up", "mustard", "我想订一间周四下午的自习室。",
                   "I'd like to book a study room for Thursday afternoon.", "book / reserve 都可以"))
S.append(K.rewrite("warm2", 2, 2, "warm", "Warm-up", "mustard", "我不确定那间房有没有屏幕。",
                   "I'm not sure whether that room has a screen.", "if 也可以"))
S.append(K.divider("topicA", "第一轮 · 话题 A", "r1", "tomato", "Round 1", "Study spaces",
                   "Where do you study best?", "你在哪里学得最好", "ROUND 1", "TOPIC A"))
HINTS = [("A", "Give a reason.", "给一个理由"), ("B", "What happens because of that?", "这样会怎么样"), ("C", "And in the end?", "最后呢")]
S.append(K.question("qA1", "第一轮 · 问题 1", "r1", "tomato", "Round 1", 1, "Do you prefer studying at home or in a library? Why?", hints=HINTS))
S.append(K.question("qA2", "第一轮 · 问题 2", "r1", "tomato", "Round 1", 2, "What makes a good place to study?", hints=HINTS, stretch=True))
S.append(K.steps3("hear", "听见自己", "r1", "Hear yourself", "tomato", "听见自己", "Your recording is the text for today.", [
    ("play", "Play it back", "回放录音", "从头听，不跳。"),
    ("pencil", "Write what you really said", "一句一句写下来", "写你真正说的，不是你想说的。"),
    ("marker", "Mark it", "用 Check Card 标记", "S → J")], right=K.timer(480)))
S.append(K.why_passes("why2", "r1", "Check Card", "navy", "为什么分遍查", "Look for one kind of mistake at a time.",
    "这一句里有 <b>2 处错</b>。一遍读下来，你能找到几处？",
    "My <span class=\"e e1\">friends is</span> waiting, and I'm not sure <span class=\"e e2\">whether is the room</span> free.",
    [("Subjects", "只看谁在做", CODES.tile("S", "tile mini"), "<s>friends is</s> → <b>friends are</b>", "friends 是几个人，用 are。"),
     ("Joins", "只看连接处", CODES.tile("J", "tile mini"), "<s>whether is the room</s> → <b>whether the room is</b>", "whether 后面，主语在前。")],
    "一次只盯一类，比同时找所有的错更不容易漏。"))
S.append(CODES.check_card_scene("check", [("Verbs", "动词", ["S"]), ("Joins", "连接处", ["J"])],
                                "Two passes. Subjects first, then joins.",
                                "<b>自己找到的</b>，标在句子旁边。<b>老师补的</b>，用另一种笔迹。", "r1"))
S.append(CODES.menu_scene("menu", "r1", "Pick the card you need most.", "只讲这一轮出现最多的一类。", "again"))
S.append(CODES.block("S", "menu", "again", "找到做事的人。一般现在时：he / she / it 加 -s；A and B 是两个。", [
    ("Students has a lot of homework.", "Students <b>have</b> a lot of homework.", ""),
    ("Mia and Leo is meeting at six.", "Mia and Leo <b>are</b> meeting at six.", ""),
    ("The notes on the table is mine.", "The notes on the table <b>are</b> mine.", "做事的是 notes，不是 table")],
    "用 two classmates 开头，说他们现在在做什么。", "Two classmates …"))
S.append(CODES.block("J", "menu", "again", "whether / if / that / because 后面保持正常语序（主语 + 动词）。", [
    ("I don't know whether can I book it.", "I don't know whether <b>I can</b> book it.", ""),
    ("I'm not sure if will the room be free.", "I'm not sure if <b>the room will</b> be free.", ""),
    ("She asked that where was the key.", "She asked <b>where the key was</b>.", "")],
    "接着说：I'm not sure whether …", "I'm not sure whether …"))
S.append(K.section("again", "cover", "重答", "r1", '''
<div class="again-hero"><div data-beat><span class="pill p-tomato">Round 1 · Take 2</span>
<h1 class="again-title">Say it again.</h1><p class="again-zh">同样两问，再答一遍</p></div></div>''', extra=' data-prev="menu"'))
S.append(K.divider("listen", "听电话", "listen", "sky", "Listen", "A phone call", "Two plays. Catch every number.", "听两遍，数字一个都别丢", "LISTEN", "NOTES", "B"))
S.append(K.note_listen("notegrid", "听电话 · 笔记 + 播放", "listen", "audio/listening.mp3", [
    ("Day", "", ""), ("Free from → to", "", "arrow"), ("People", "", ""),
    ("Room", "", ""), ("Cost", "per hour · total", "three"), ("Arrive", "", "")],
    [("Two plays", "读两遍"), ("1st play: notes only", "第一遍只记，不回答"), ("Notes on your paper", "记在学生册上")]))
S.append(K.listen_question("lq1", 1, 2, "Which room does the student book, and why?", "The student books Room 3B, because it has a screen and holds up to six people."))
S.append(K.listen_question("lq2", 2, 2, "How much will it cost, and when should they arrive?", "It will cost eight dollars, and they should arrive ten minutes early, because the key stays at the desk.", focus_zh="先说总价，再说几点到。"))
TRANSCRIPT = " ".join(re.sub(r"\{[^}]*\}", "", l.split("] ", 1)[1]).strip() for l in open(HERE / "listening.txt", encoding="utf-8") if l.startswith("[")) if (HERE / "listening.txt").exists() else ""
S.append(K.note_check("notecheck", "核对笔记", "listen", [("Day", "Thursday"), ("Free from → to", "2:30 → 6:00"), ("People", "5"), ("Room", "3B (has a screen, up to 6 people)"),
    ("Cost", "$4 per hour · $8 total (two hours)"), ("Arrive", "ten minutes early (the key stays at the desk)")], transcript=TRANSCRIPT))
S.append(K.compare_table("compare", "第一遍 vs 第二遍", "listen", "sky", "Notes", "两次听，各记了几格", [
    ("1st play", "tomato", "boxes", "第一遍几格"), ("2nd play", "sky", "boxes", "第二遍几格")],
    ["填了几格", "最难的一格"], "<b>不评分</b>，只看第二遍补了几格。"))
S.append(K.homework("homework", "作业", "close", "每天 A · 隔一天加 B", [
    ("A", "Say it", "约 15 分钟", "tomato", "抽 1 题，录 90 秒；回放，写下来；标记；再录一次。"),
    ("B", "Write it", "约 25 分钟 · 隔天一次", "sky", "计时 15 分钟写一段，10 分钟自查。"),
    ("Floor", "Floor day", "保底日 · 约 15 分钟", "mustard", "只做 A。忙的日子也不断。")]))
S.append(K.send_two("send", "close", [("camera", "A photo of your log", "日志的照片"), ("mic", "Your best recording", "最满意的一段录音")]))
S.append(K.closing(["Say it.", "Hear it.", "Say it again."], "明天从 A 开始。", art_label="STUDY ROOM"))

RAIL = [("warm", "Warm-up", "mustard"), ("r1", "Round 1", "tomato"), ("listen", "Listen", "sky"), ("close", "Home", "navy")]
OUT.write_text(K.page(S, "Study Room, Please · sample", "Sample · Lesson 1", RAIL, nav_jumps=(("路线", "route"), ("小卡", "menu"))), encoding="utf-8")
print("wrote", OUT, "scenes", len(S))
