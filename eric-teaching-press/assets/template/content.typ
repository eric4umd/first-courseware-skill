// content.typ — ONE lesson, shared by every visual direction.
// Same words, same keys, same task order: only the design changes.
// Standards: US spelling · IPA follows Oxford Learner's (American) · body 10pt+.
// Semantic markup only: #strong = grammar target, #emph = foreign/quoted term.
// Each direction decides what strong/emph/pp look like.

// ── helpers ───────────────────────────────────────────────────────────
// A "past-perfect chunk" inside the reading text. Plain in the student
// edition; directions may switch it on for the teacher edition.
#let pp-show = state("pp-show", false)
#let pp(body) = context if pp-show.get() { strong(body) } else { body }

// Replace {1}..{9} markers with whatever the direction draws as a blank.
#let fill-blanks(s, f) = {
  let out = ()
  let last = 0
  for m in s.matches(regex("\{(\d)\}")) {
    out.push(s.slice(last, m.start))
    out.push(f(int(m.captures.at(0))))
    last = m.end
  }
  out.push(s.slice(last))
  out.join()
}

// Stems carry a plain "______" marker; each direction draws its own blank.
#let stem-with-blank(s, blank) = s.split("______").join(blank)

// ── lesson meta ───────────────────────────────────────────────────────
#let lesson = (
  series: "English Grammar & Reading",
  series-zh: "语法与阅读",
  number: "07",
  title-zh: "过去完成时",
  title-en: "Past Perfect",
  tagline-zh: "说清“过去的过去”",
  tagline-en: "What had already happened?",
  grade: "Grade 9–10",
  minutes: "45 min",
  brand: "ERIC TEACHING STUDIO",
)

// ── grammar ───────────────────────────────────────────────────────────
#let grammar = (
  form: "had + past participle",
  form-zh: "had + 过去分词",
  rule-zh: [一个过去的动作，发生在 *另一个过去的时间点或动作之前*，用过去完成时。可以把它理解为“过去的过去”。],
  rule-en: [Use it for an action that was already finished before another moment in the past.],
  // Timeline: earlier event → reference point → now
  timeline: (
    earlier: (label: "The keeper had left.", when: "a week earlier"),
    ref: (label: "Mira reached the lighthouse.", when: "past reference point"),
  ),
  signals: ("by the time", "before", "after", "when", "already", "just", "never … before", "until"),
  contrast: (
    simple: (
      en: [When Mira reached the lighthouse, the rain #strong[stopped].],
      zh: [雨是在她到达的那一刻才停的。],
      tag: "Simple past",
    ),
    perfect: (
      en: [When Mira reached the lighthouse, the rain #strong[had stopped].],
      zh: [她到达之前，雨就已经停了。],
      tag: "Past perfect",
    ),
  ),
  caution-title: "易错 Watch out",
  caution-wrong: "I had finished my homework yesterday.",
  caution-right: "I finished my homework yesterday.",
  caution-zh: [句子里没有“另一个过去的时间点”可以对照，就不要用 had done。只是讲过去发生的一件事，用一般过去时。],
  // Quick check — exactly one defensible answer each.
  check: (
    (
      stem: "By the time the bell rang, Leo ______ his essay.",
      choices: ("finishes", "had finished", "has finished", "will have finished"),
      key: 1,
    ),
    (
      stem: "When Mira got home, she realized she ______ her notebook at the lighthouse.",
      choices: ("leaves", "had left", "has left", "will leave"),
      key: 1,
    ),
  ),
  fix: (
    wrong: "By the time the guide arrived, the tourists already left the museum.",
    right: "By the time the guide arrived, the tourists had already left the museum.",
  ),
)

// ── vocabulary (words come from the reading; US IPA) ──────────────────
#let vocab = (
  (word: "keeper",  ipa: "ˈkiːpər",   pos: "n.", zh: "看守人",       ex: "The keeper had left a week earlier.",             note: "lighthouse keeper · goalkeeper · zookeeper"),
  (word: "dusty",   ipa: "ˈdʌsti",    pos: "adj.", zh: "积满灰尘的", ex: "On a dusty shelf she found a notebook.",         note: "dust (n.) + -y → dusty"),
  (word: "shelf",   ipa: "ʃɛlf",      pos: "n.", zh: "架子；搁板",   ex: "The book is on the top shelf.",                   note: "复数 shelves（f → ves）"),
  (word: "record",  ipa: "rɪˈkɔːrd",  pos: "v.", zh: "记录",         ex: "Every page recorded the weather.",                note: "名词读 ˈrɛkərd，重音在前"),
  (word: "dusk",    ipa: "dʌsk",      pos: "n.", zh: "黄昏",         ex: "The lamp was lit at dusk.",                       note: "at dusk ↔ at dawn"),
  (word: "entry",   ipa: "ˈɛntri",    pos: "n.", zh: "日记的一则；条目", ex: "The final entry was different.",              note: "diary entry · entry form"),
  (word: "trust",   ipa: "trʌst",     pos: "v.", zh: "信任",         ex: "He trusted someone else to do it.",               note: "trust sb. to do sth."),
  (word: "match",   ipa: "mætʃ",      pos: "n.", zh: "火柴",         ex: "A small boy was holding a match.",                note: "a box of matches · light a match"),
)

#let words-page = (
  title: "Eight Words from the Notebook",
  title-zh: "词汇",
  steps: ("Say it", "Cover it", "Use it"),
  steps-zh: ("读出来", "遮住释义", "造个句"),
  task-zh: [先遮住中文释义，大声读出每个词；然后任选两个词，各写一个你自己的句子。],
  task: "Pick two words and write your own sentence for each.",
)

#let sound = (
  title: "Sound check",
  title-zh: "发音小练",
  track: "03",
  pair: (
    (word: "shelf", ipa: "ʃ",  cue-zh: "气流不断，像“嘘”"),
    (word: "match", ipa: "tʃ", cue-zh: "先堵后放，像“吃”的起音"),
  ),
  prompt-zh: [听录音，写出你听到的词：],
)

// ── reading ───────────────────────────────────────────────────────────
#let reading = (
  label: "Reading",
  title: "The Keeper’s Notebook",
  words: 142,
  paras: (
    [When Mira reached the old lighthouse, the rain #pp[had already stopped]. The keeper, Mr. Aldous, #pp[had left] a week earlier, and nobody #pp[had touched] the lamp room since. On a dusty shelf she found a leather notebook.],
    [Every page recorded the same three things: the date, the weather, and one short line: “Lamp lit at dusk.” Mira read for an hour. By the time she reached the last page, the sun #pp[had set], and the sea below #pp[had turned] the color of slate.],
    [The final entry was different. It read, “Tonight I did not light the lamp. For the first time in forty years, I trusted someone else to do it.” Mira looked up. Behind her, on the stairs, a small boy was holding a match.],
  ),
  qs: (
    (
      stem: "When Mira reached the lighthouse, what had already happened?",
      choices: ("The keeper had come back.", "The rain had stopped.", "The sun had set.", "The lamp had been lit."),
      key: 1,
      evidence: "Paragraph 1, first sentence",
      why: [第一句 “the rain *had already stopped*” 说明：她到达之前，雨已经停了。],
      trap: [选 C 的学生把两个时间点混了：太阳是她 *读到最后一页时* 才落山，晚于她到达。],
      repair: [在黑板画四个点：雨停 → 到达 → 读完 → 日落，让学生指出哪个点在“到达”之前。],
    ),
    (
      stem: "What was special about the final entry?",
      choices: (
        "It was the only entry that mentioned the weather.",
        "It said the keeper had never lit the lamp.",
        "It described a night the keeper did not light the lamp himself.",
        "It was the first entry in the notebook.",
      ),
      key: 2,
      evidence: "Paragraph 3, the quoted entry",
      why: [“Tonight I did not light the lamp … I trusted someone else” 正是他这一晚没有亲手点灯。],
      trap: [选 B 是误读 “for the first time in forty years”：它说明之前四十年他每晚都点灯。],
      repair: [让学生划出 “for the first time in forty years”，再回答：这四十年里他做了什么？],
    ),
    (
      stem: "What will the boy most likely do next?",
      choices: ("Take the notebook away.", "Light the lamp.", "Ask Mira for help.", "Leave the lighthouse."),
      key: 1,
      evidence: "“trusted someone else to do it” + “holding a match”",
      why: [两条线索合在一起：守灯人把点灯托付给别人，而男孩手里拿着火柴。],
      trap: [选 A、C 的学生没有依据：文中没有任何一处提到笔记本被拿走或向 Mira 求助。],
      repair: [要求学生为答案各写出两处文中线索，只写得出一处的答案先不能定。],
    ),
  ),
)

// ── cloze (exam layout: full passage, then numbered A–D rows) ─────────
#let cloze = (
  heading: "Grandfather and the Sea",
  title: "Cloze",
  title-zh: "完形填空",
  direction-zh: [通读短文，掌握大意，然后从每题所给的四个选项中选出最佳答案。],
  passage: "My grandfather refuses to swim in the sea. When I asked him why, he {1} me a story I had never heard before. At ten, he had gone swimming alone, and by the time he noticed the danger, he {2} too far from the beach. A huge wave knocked him over. He was {3} to shore only because a stranger had thrown him a rope. He never swam in the sea again, {4} he still loves to watch the waves. “That day taught me to respect the sea,” he said, “and I have never {5} that lesson.”",
  rows: (
    (n: 1, choices: ("told", "said", "spoke", "talked"), key: 0),
    (n: 2, choices: ("drifted", "had drifted", "has drifted", "would drift"), key: 1),
    (n: 3, choices: ("pulled", "pushed", "carried", "lifted"), key: 0),
    (n: 4, choices: ("so", "because", "but", "unless"), key: 2),
    (n: 5, choices: ("forgotten", "forgot", "forget", "forgetting"), key: 0),
  ),
  notes: (
    [“tell sb. a story” 是固定搭配；say、speak、talk 后面都不能直接接 “me a story”。],
    [“by the time he noticed …” 引出过去的参照点，之前已完成的动作用 *had drifted*。],
    [绳子是“扔”过来的，所以是被 *pulled* 到岸边。],
    [前后意思转折：不再游泳，但仍然爱看海浪，用 *but*。],
    [have never + 过去分词，只有 *forgotten* 符合。],
  ),
)

// ── writing ───────────────────────────────────────────────────────────
#let writing = (
  heading: "Your Turn to Write",
  title: "Writing",
  title-zh: "写一写",
  combine: (
    (a: "The rain stopped.", b: "Mira reached the lighthouse.", use: "by the time", model: "By the time Mira reached the lighthouse, the rain had stopped."),
    (a: "Mr. Aldous left the lighthouse.", b: "Then nobody touched the lamp room.", use: "since", model: "Nobody had touched the lamp room since Mr. Aldous left."),
  ),
  story-prompt: "What had the boy done before he climbed the stairs? Write 3–4 sentences.",
  story-prompt-zh: "男孩上楼之前做过什么？写 3–4 句，至少用两次 had + 过去分词。",
  checklist: (
    "I used had + past participle at least twice.",
    "I used one time signal (by the time, before, after …).",
    "The order of events is clear to a reader.",
  ),
  model: "The boy had followed Mira from the village. He had watched her through the window for an hour, and he had waited until she finished reading. Before he came upstairs, he had borrowed a match from the kitchen.",
)

// ── student-facing small labels (kept identical across directions) ────
#let labels = (
  name: "姓名", date: "日期", class: "班级",
  student: "Student Edition · 学生版",
  teacher: "Teacher Edition · 教师版",
  answer: "Answer", why: "Why", trap: "Tempting wrong choice", repair: "Repair move",
  evidence: "依据 Evidence",
)
