// D1 · 页边 Marginalia — annotated-edition design system.
// Idea: a well-annotated book. Wide reading column on the left, a narrow
// "margin rail" on the right that carries glosses, strategy and teacher notes.
// Color is a signal, not decoration: oxblood = mark / label / answer,
// brass = hairlines only, everything else is warm ink on ivory.

#import "../content.typ": *

// ── tokens ────────────────────────────────────────────────────────────
#let paper    = rgb("#f6f0e3")
#let ink      = rgb("#1e1915")
#let muted    = rgb("#6f6458")
#let rule-c   = rgb("#cdbda3")
#let oxblood  = rgb("#8b2e3a")
#let oxb-wash = rgb("#f0dcd9")
#let brass    = rgb("#a98a56")
#let wash     = rgb("#ece2cf")

#let en-font = ("Libertinus Serif", "Noto Serif SC")
#let zh-font = ((name: "Libertinus Serif", covers: "latin-in-cjk"), "Noto Serif SC")

// page geometry (mm): 20 + 118 + 8 + 48 + 16 = 210
#let m-left = 20mm
#let w-main = 118mm
#let w-gut  = 8mm
#let w-rail = 48mm
#let m-right = 16mm
#let w-full = w-main + w-gut + w-rail

// ── type helpers ──────────────────────────────────────────────────────
#let zh(body, size: auto, weight: "regular", fill: auto) = text(
  font: zh-font, lang: "zh", weight: weight,
  size: if size == auto { 1em } else { size },
  fill: if fill == auto { ink } else { fill },
  body,
)
#let label(body, fill: oxblood, size: 7.6pt) = text(
  size: size, fill: fill, tracking: 0.16em, weight: "regular", smallcaps(lower(body)),
)
#let ipa(s) = text(font: "Libertinus Serif", style: "normal", fill: muted, size: 0.92em)[/#s/]
#let hair(w: 100%, c: rule-c, t: 0.4pt) = block(width: w, height: t, fill: c, above: 0pt, below: 0pt)

// ── page frame ────────────────────────────────────────────────────────
#let page-args(running: lesson.title-en + " · " + lesson.title-zh, edition: "Student Edition") = (
  paper: "a4",
  fill: paper,
  margin: (left: m-left, right: m-right, top: 24mm, bottom: 22mm),
  background: place(top + left, dx: m-left + w-main + w-gut / 2, dy: 24mm,
    block(width: 0.35pt, height: 251mm, fill: rule-c.transparentize(35%))),
  header: {
    set text(size: 8pt, fill: muted)
    grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
      label(running, fill: muted), label(edition, fill: muted))
    v(1.4mm)
    hair(c: brass, t: 0.35pt)
  },
  header-ascent: 5mm,
  footer: context align(center)[#text(size: 8.4pt, fill: muted, style: "italic")[— #counter(page).display("1") —]],
  footer-descent: 6mm,
)

#let setup(body) = {
  set text(font: en-font, size: 11pt, lang: "en", fill: ink, number-type: "old-style", ligatures: true)
  set par(leading: 0.8em, spacing: 1.05em, justify: true, linebreaks: "optimized")
  show strong: set text(fill: oxblood, weight: "semibold")
  show emph: set text(style: "italic")
  body
}

#let std-page(edition: "Student Edition", body) = page(..page-args(edition: edition))[#body]

// ── lighthouse: hairline engraving ────────────────────────────────────
#let lighthouse(w, stroke-c: ink, accent: oxblood, beam: true, sea: true) = {
  let u = w / 100
  let st = 0.5pt + stroke-c
  let lx(y) = 37 + (43 - 37) * (118 - y) / (118 - 56)
  let rx(y) = 63 - (63 - 57) * (118 - y) / (118 - 56)
  let band(y1, y2, fill) = place(top + left, polygon(
    fill: fill, stroke: 0.35pt + stroke-c,
    (lx(y2) * u, y2 * u), (rx(y2) * u, y2 * u), (rx(y1) * u, y1 * u), (lx(y1) * u, y1 * u),
  ))
  box(width: w, height: 150 * u, {
    if beam {
      place(top + left, polygon(
        fill: gradient.linear(brass.transparentize(55%), brass.transparentize(100%), angle: 180deg),
        stroke: none,
        (49 * u, 45 * u), (-70 * u, 28 * u), (-70 * u, 64 * u)))
      place(top + left, polygon(
        fill: gradient.linear(brass.transparentize(55%), brass.transparentize(100%), angle: 0deg),
        stroke: none,
        (51 * u, 45 * u), (170 * u, 28 * u), (170 * u, 64 * u)))
    }
    if sea {
      for i in range(0, 11) {
        let y = 125 + i * 2.7
        let fade = calc.min(8 + i * 8, 80) * 1%
        let x = 8 + calc.rem(i * 13, 17)
        for k in range(0, 5) {
          let seg = 9 + calc.rem(i * 7 + k * 5, 8)
          place(top + left, dx: (x + k * 20 + calc.rem(i * 6, 9)) * u, dy: y * u,
            line(length: seg * u, stroke: 0.3pt + stroke-c.transparentize(fade)))
        }
      }
    }
    place(top + left, polygon(
      fill: paper, stroke: st,
      (24 * u, 126 * u), (31 * u, 119 * u), (38 * u, 121 * u), (62 * u, 120 * u),
      (70 * u, 118 * u), (78 * u, 126 * u), (68 * u, 129 * u), (40 * u, 130 * u)))
    for k in range(0, 6) {
      place(top + left, dx: (30 + k * 6) * u, dy: (122 + calc.rem(k, 2) * 1.6) * u, line(angle: 60deg, length: 4 * u, stroke: 0.3pt + stroke-c))
    }
    place(top + left, polygon(fill: paper, stroke: st,
      (37 * u, 118 * u), (63 * u, 118 * u), (57 * u, 56 * u), (43 * u, 56 * u)))
    band(70, 82, accent)
    band(96, 108, accent)
    place(top + left, dx: 47.2 * u, dy: 108 * u, rect(width: 5.6 * u, height: 10 * u, stroke: 0.4pt + stroke-c, radius: (top: 2.8 * u), fill: paper))
    place(top + left, dx: 48.6 * u, dy: 88 * u, rect(width: 2.8 * u, height: 5 * u, stroke: 0.4pt + stroke-c, radius: (top: 1.4 * u), fill: paper))
    place(top + left, dx: 39 * u, dy: 52.6 * u, rect(width: 22 * u, height: 3.4 * u, stroke: st, fill: paper))
    for k in range(0, 9) {
      place(top + left, dx: (40 + k * 2.4) * u, dy: 47.4 * u, line(angle: 90deg, length: 5.2 * u, stroke: 0.3pt + stroke-c))
    }
    place(top + left, dx: 39.6 * u, dy: 47.4 * u, line(length: 20.8 * u, stroke: 0.4pt + stroke-c))
    place(top + left, dx: 44.6 * u, dy: 38 * u, rect(width: 10.8 * u, height: 9.4 * u, stroke: st, fill: brass.transparentize(75%)))
    place(top + left, dx: 50 * u, dy: 38 * u, line(angle: 90deg, length: 9.4 * u, stroke: 0.3pt + stroke-c))
    place(top + left, polygon(fill: accent, stroke: st,
      (43 * u, 38 * u), (57 * u, 38 * u), (50 * u, 29 * u)))
    place(top + left, dx: 49 * u, dy: 26 * u, circle(radius: 1.1 * u, fill: paper, stroke: 0.4pt + stroke-c))
    for (gx, gy, gs) in ((18, 22, 3.2), (26, 14, 2.4), (80, 18, 2.8)) {
      place(top + left, dx: gx * u, dy: gy * u, curve(stroke: 0.4pt + stroke-c,
        curve.move((0pt, 0pt)),
        curve.cubic((gs * u * 0.4, -gs * u * 0.6), (gs * u * 0.8, -gs * u * 0.6), (gs * u, 0pt)),
        curve.cubic((gs * u * 1.2, -gs * u * 0.6), (gs * u * 1.6, -gs * u * 0.6), (gs * 2 * u, 0pt))))
    }
  })
}

// ── building blocks ───────────────────────────────────────────────────
#let opt-letter(i, filled: false) = box(
  width: 4.5mm, height: 4.5mm, radius: 50%, baseline: 22%,
  stroke: 0.5pt + (if filled { oxblood } else { ink }),
  fill: if filled { oxblood } else { none },
  align(center + horizon, text(size: 7.8pt, style: "italic", fill: if filled { white } else { ink }, weight: "regular")[#("A", "B", "C", "D").at(i)]),
)

#let stem-blank = box(width: 15mm, height: 0.8em, stroke: (bottom: 0.5pt + ink), baseline: 0pt)

#let mcq(n, stem, choices, key: none, teacher: false, cols: 1) = block(breakable: false, width: 100%)[
  #set block(spacing: 0pt)
  #grid(
    columns: (6mm, 1fr), column-gutter: 1mm,
    text(size: 12pt, style: "italic", fill: oxblood, number-type: "lining")[#n],
    [
      #set par(justify: false, leading: 0.62em, spacing: 0.5em)
      #text(weight: "medium")[#stem-with-blank(stem, stem-blank)]
      #v(2.2mm)
      #let one(i, c) = {
        let hit = teacher and key == i
        grid(columns: (6.4mm, 1fr), column-gutter: 0pt, align: top,
          opt-letter(i, filled: hit),
          if hit { text(fill: oxblood, weight: "medium")[#c] } else { c })
      }
      #if cols == 1 {
        for (i, c) in choices.enumerate() { block(breakable: false, above: 0pt, below: 1.5mm, one(i, c)) }
      } else {
        grid(columns: (1fr,) * cols, column-gutter: 3mm, row-gutter: 1.8mm,
          ..choices.enumerate().map(((i, c)) => one(i, c)))
      }
    ],
  )
]

#let rail-note(title, body, accent: oxblood, size: 8.6pt) = block(width: 100%, breakable: false, below: 3.2mm)[
  #set text(size: size, lang: "en")
  #set par(justify: false, leading: 0.6em, spacing: 0.5em)
  #label(title, fill: accent)
  #v(0.6mm)
  #body
]

#let gloss(word, pos, ipa-s, zh-s) = block(width: 100%, breakable: false, below: 1.7mm)[
  #set par(justify: false, leading: 0.5em, spacing: 0.3em)
  #text(size: 8.9pt)[#text(style: "italic", weight: "semibold")[#word] #text(size: 7.8pt, fill: muted)[#pos] #ipa(ipa-s) #h(0.5mm) #zh(size: 8.2pt, fill: muted)[#zh-s]]
]

#let row(main, rail, below: 6.5mm) = block(width: 100%, below: below, breakable: false)[
  #grid(columns: (w-main, w-gut, w-rail), column-gutter: 0pt, main, [], rail)
]

// chapter opener: part label, title (+ optional rail content), double rule
#let opener(part, zh-label, title, rail: [], size: 30pt) = block(below: 5mm)[
  #set block(spacing: 0pt)
  #grid(columns: (w-main, w-gut, w-rail), align: (left + bottom, left, right + top),
    [
      #label(part, fill: oxblood, size: 8.4pt) #h(1.5mm) #zh(size: 8.4pt, fill: muted)[#zh-label]
      #v(3.5mm)
      #text(size: size, style: "italic", tracking: -0.005em)[#title]
    ],
    [],
    align(left, rail))
  #v(1mm)
  #hair(w: w-full, c: ink, t: 0.7pt)
  #v(0.9mm)
  #hair(w: w-full, c: ink, t: 0.25pt)
]

#let sect(title, zh-title) = block(below: 3mm, above: 1mm)[
  #label(title, fill: oxblood, size: 8.4pt) #h(1.5mm) #zh(size: 8.4pt, fill: muted)[#zh-title]
  #v(1.5mm)
  #hair(w: w-full, c: rule-c)
]

#let ruled(n, gap: 8mm, w: 100%) = for _ in range(0, n) {
  v(gap)
  hair(w: w, c: rule-c)
}

#let check-circle(done: false) = box(width: 3.6mm, height: 3.6mm, radius: 50%, stroke: 0.5pt + ink, baseline: 12%, fill: if done { oxblood } else { none })

// ── COVER ─────────────────────────────────────────────────────────────
#let page-cover() = page(margin: 0mm, header: none, footer: none, fill: paper, background: none)[
  #place(top + left, dx: 10mm, dy: 10mm, rect(width: 190mm, height: 277mm, stroke: 0.7pt + brass))
  #place(top + left, dx: 12.2mm, dy: 12.2mm, rect(width: 185.6mm, height: 272.6mm, stroke: 0.3pt + brass))

  #place(top + left, dx: 12.6mm, dy: 100mm, box(width: 184.8mm, height: 184mm, clip: true,
    place(top + left, dx: 92mm, dy: 40mm, lighthouse(88mm))))

  #place(top + left, dx: 26mm, dy: 28mm, block(width: 158mm)[
    #grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
      label(lesson.series, fill: muted, size: 8.4pt),
      zh(size: 8.6pt, fill: muted)[#lesson.series-zh])
    #v(2.4mm)
    #hair(c: brass, t: 0.35pt)
  ])

  #place(top + left, dx: 26mm, dy: 50mm, block(width: 150mm)[
    #text(size: 10.5pt, fill: oxblood, tracking: 0.22em)[#smallcaps[lesson]]
    #h(2mm)
    #text(size: 10.5pt, fill: oxblood, number-type: "lining", tracking: 0.1em)[#lesson.number]
    #v(8mm)
    #set par(leading: 0.13em, justify: false)
    #text(size: 80pt, style: "italic", tracking: -0.012em)[#lesson.title-en.split(" ").at(0)\
      #lesson.title-en.split(" ").at(1)]
    #v(7mm)
    #hair(w: 22mm, c: oxblood, t: 1pt)
    #v(5mm)
    #text(size: 19pt, style: "italic", fill: muted)[#lesson.tagline-en]
    #v(3.2mm)
    #zh(size: 17pt, weight: "semibold")[#lesson.title-zh]#zh(size: 12.5pt, fill: muted)[ · #lesson.tagline-zh]
  ])

  #place(bottom + left, dx: 26mm, dy: -29mm, block(width: 70mm)[
    #grid(columns: (auto, 1fr), row-gutter: 4mm, column-gutter: 2.5mm, align: bottom,
      zh(size: 8.8pt, fill: muted)[#labels.name], block(height: 0.4pt, fill: muted, width: 100%),
      zh(size: 8.8pt, fill: muted)[#labels.date], block(height: 0.4pt, fill: muted, width: 100%),
      zh(size: 8.8pt, fill: muted)[#labels.class], block(height: 0.4pt, fill: muted, width: 100%))
  ])
  #place(bottom + left, dx: 26mm, dy: -19mm, label(lesson.brand + "  ·  student edition", fill: muted, size: 7.6pt))
  #place(bottom + right, dx: -26mm, dy: -19mm, label(lesson.grade + "  ·  " + lesson.minutes, fill: muted, size: 7.6pt))
]

// ── 01 WORDS ──────────────────────────────────────────────────────────
#let page-words() = std-page({
  opener("Part one  ·  Words", "词汇", words-page.title, size: 25pt,
    rail: rail-note("Say it · Cover it · Use it", [#zh(size: 8.4pt)[读出来 → 遮住释义 → 造个句。]]))

  for (i, e) in vocab.enumerate() {
    row(
      [
        #set par(justify: false, leading: 0.6em, spacing: 0.4em)
        #text(size: 16.5pt, style: "italic", weight: "semibold")[#e.word]#h(1.6mm)#text(size: 8.6pt, fill: muted)[#e.pos]#h(2mm)#ipa(e.ipa)#h(2.4mm)#zh(size: 10pt)[#e.zh]
        #v(0.8mm)
        #text(size: 11pt, style: "italic", fill: ink.lighten(15%))[#e.ex]
      ],
      [
        #set par(justify: false, leading: 0.6em)
        #v(1.2mm)
        #text(size: 8.4pt, fill: muted, style: "italic")[#e.note]
      ],
      below: 3.4mm,
    )
    if i < vocab.len() - 1 { hair(w: w-main, c: rule-c.transparentize(40%), t: 0.3pt); v(3.4mm) }
  }
  v(3mm)

  // sound check
  block(width: 100%, breakable: false, below: 4mm, stroke: (top: 0.7pt + ink, bottom: 0.25pt + ink), inset: (y: 3.2mm))[
    #grid(columns: (w-main, w-gut, w-rail), column-gutter: 0pt, align: horizon,
      [
        #label(sound.title, size: 8.4pt) #h(1.5mm) #zh(size: 8.4pt, fill: muted)[#sound.title-zh] #h(2mm) #label("Track " + sound.track, fill: muted, size: 7.4pt)
        #v(2.4mm)
        #grid(columns: (1fr, 1fr), column-gutter: 6mm,
          ..sound.pair.map(p => grid(columns: (auto, 1fr), column-gutter: 3mm, align: horizon,
            text(size: 30pt, style: "italic", fill: oxblood, font: "Libertinus Serif")[/#p.ipa/],
            [
              #set par(leading: 0.5em, spacing: 0.3em)
              #text(style: "italic", weight: "semibold")[#p.word]\
              #zh(size: 8.6pt, fill: muted)[#p.cue-zh]
            ])))
      ],
      [],
      [
        #set par(leading: 0.5em)
        #zh(size: 8.6pt)[#sound.prompt-zh]
        #v(1mm)
        #for n in (1, 2, 3) { grid(columns: (4mm, 1fr), align: bottom, text(size: 8.4pt, style: "italic", fill: oxblood)[#n], block(height: 5.2mm, width: 100%, stroke: (bottom: 0.4pt + muted))) }
      ])
  ]

  // use it
  row(
    [
      #label("Use it", size: 8.4pt) #h(1.5mm) #zh(size: 8.4pt, fill: muted)[造个句]
      #v(1mm)
      #set par(justify: false)
      #zh(size: 9.6pt)[#words-page.task-zh]
      #ruled(2, gap: 8mm)
    ],
    [],
    below: 0mm,
  )
})

// ── 02 GRAMMAR ────────────────────────────────────────────────────────
#let timeline(w) = {
  let ax = 15mm
  let x1 = w * 0.20
  let x2 = w * 0.62
  box(width: w, height: 30mm, {
    place(top + left, dy: ax, line(length: w - 3mm, stroke: 0.7pt + ink))
    place(top + left, dx: w - 3.6mm, dy: ax - 1.4mm, polygon(fill: ink, stroke: none, (0mm, 0mm), (3.6mm, 1.4mm), (0mm, 2.8mm)))
    place(top + left, dx: x1 - 1.8mm, dy: ax - 1.8mm, circle(radius: 1.8mm, fill: oxblood, stroke: none))
    place(top + left, dx: x1 - 18mm, dy: 2.5mm, block(width: 36mm, align(center)[#text(size: 10pt, style: "italic")[#strong[#grammar.timeline.earlier.label]]]))
    place(top + left, dx: x1 - 18mm, dy: ax + 3.6mm, block(width: 36mm, align(center)[#label(grammar.timeline.earlier.when, fill: muted, size: 7.4pt)]))
    place(top + left, dx: x2 - 1.8mm, dy: ax - 1.8mm, circle(radius: 1.8mm, fill: paper, stroke: 0.9pt + ink))
    place(top + left, dx: x2 - 22mm, dy: 2.5mm, block(width: 44mm, align(center)[#text(size: 10pt, style: "italic")[#grammar.timeline.ref.label]]))
    place(top + left, dx: x2 - 22mm, dy: ax + 3.6mm, block(width: 44mm, align(center)[#label("reference point", fill: muted, size: 7.4pt)]))
    place(top + left, dx: w - 11mm, dy: ax + 3.6mm, label("now", fill: muted, size: 7.4pt))
    place(top + left, dx: x1, dy: ax - 4.4mm, curve(stroke: 0.5pt + oxblood,
      curve.move((0pt, 0pt)),
      curve.cubic((0pt, -3mm), (x2 - x1, -3mm), (x2 - x1, 0pt))))
  })
}

#let page-grammar() = std-page({
  opener("Part two  ·  Grammar", "语法", lesson.title-en,
    rail: rail-note("Form 构成", [
      #text(size: 15pt, style: "italic", fill: oxblood)[had + p.p.]\
      #zh(size: 8.4pt, fill: muted)[#grammar.form-zh]
    ]))

  block(width: w-main, below: 8mm, above: 3mm, stroke: (bottom: 0.3pt + rule-c), inset: (bottom: 6mm, x: 4mm))[
    #set par(justify: false, leading: 0.7em, spacing: 0.7em)
    #align(center)[
      #text(size: 16pt, style: "italic")[#grammar.rule-en]
      #v(3mm)
      #zh(size: 10.6pt)[#grammar.rule-zh]
    ]
  ]

  row(
    [
      #label("On the timeline", size: 8.4pt) #h(1.5mm) #zh(size: 8.4pt, fill: muted)[时间线]
      #v(2mm)
      #timeline(w-main)
    ],
    rail-note("Signals 信号词", [
      #set par(leading: 0.62em)
      #for (i, s) in grammar.signals.enumerate() { text(style: "italic")[#s]; if i < grammar.signals.len() - 1 [ · ] }
    ]),
    below: 6mm,
  )

  row(
    [
      #label("Same sentence, two meanings", size: 8.4pt) #h(1.5mm) #zh(size: 8.4pt, fill: muted)[同一句话，两种意思]
      #v(2.4mm)
      #grid(columns: (1fr, 1fr), column-gutter: 6mm,
        ..(grammar.contrast.simple, grammar.contrast.perfect).map(c => [
          #hair(c: ink, t: 0.5pt)
          #v(1.6mm)
          #label(c.tag, fill: if c.tag.starts-with("Past") { oxblood } else { muted }, size: 7.8pt)
          #v(1mm)
          #set par(justify: false, leading: 0.6em)
          #text(size: 11.4pt, style: "italic")[#c.en]
          #v(1.2mm)
          #zh(size: 9pt, fill: muted)[#c.zh]
        ]))
    ],
    rail-note(grammar.caution-title, [
      #set par(leading: 0.62em)
      #strike(stroke: 0.6pt + oxblood)[#text(style: "italic", fill: muted)[#grammar.caution-wrong]]\
      #text(style: "italic", weight: "semibold")[#grammar.caution-right]
      #v(1mm)
      #zh(size: 8.2pt, fill: muted)[#grammar.caution-zh]
    ]),
  )

  v(3mm)
  sect("Quick check", "小测")
  for (i, q) in grammar.check.enumerate() {
    row(mcq(i + 1, q.stem, q.choices, cols: 2), [], below: 5mm)
  }
  row(
    [
      #grid(columns: (6mm, 1fr), column-gutter: 1mm,
        text(size: 12pt, style: "italic", fill: oxblood, number-type: "lining")[3],
        [
          #set par(justify: false, leading: 0.62em)
          #text(weight: "medium")[Fix the sentence.] #zh(size: 9pt, fill: muted)[改正错误]
          #v(1.4mm)
          #text(style: "italic")[#grammar.fix.wrong]
          #ruled(1, gap: 8mm)
        ])
    ],
    [],
    below: 0mm,
  )
})

// ── 03 READING ────────────────────────────────────────────────────────
#let page-reading(teacher: false) = std-page(edition: if teacher { "Teacher Edition" } else { "Student Edition" }, {
  pp-show.update(teacher)

  opener("Part three  ·  " + reading.label, "阅读", reading.title,
    rail: [
      #rail-note("Strategy 策略", [#zh(size: 8.4pt)[圈出时间词，它们告诉你事情发生的先后。]])
    ])

  let p = reading.paras
  row(
    { set par(first-line-indent: 0pt, justify: true); if not teacher { set text(size: 11.6pt); set par(leading: 0.78em); p.at(0) } else { p.at(0) } },
    {
      if teacher {
        rail-note("Teacher", [Three chunks (#emph[had already stopped, had left, had touched]) all happen *before* “reached”.])
      } else {
        gloss("keeper", "n.", "ˈkiːpər", "看守人")
        gloss("dusty", "adj.", "ˈdʌsti", "积满灰尘的")
        gloss("shelf", "n.", "ʃɛlf", "架子；搁板")
      }
    },
  )
  row(
    { set par(first-line-indent: 0pt, justify: true); if not teacher { set text(size: 11.6pt); set par(leading: 0.78em); p.at(1) } else { p.at(1) } },
    {
      if teacher {
        rail-note("Teacher", [Reference point: *she reached the last page*. The sunset came before it.])
      } else {
        gloss("record", "v.", "rɪˈkɔːrd", "记录")
        gloss("dusk", "n.", "dʌsk", "黄昏")
        gloss("slate", "n.", "sleɪt", "青灰色；石板")
      }
    },
  )
  row(
    { set par(first-line-indent: 0pt, justify: true); if not teacher { set text(size: 11.6pt); set par(leading: 0.78em); p.at(2) } else { p.at(2) } },
    {
      if not teacher {
        gloss("entry", "n.", "ˈɛntri", "日记的一则")
        gloss("trust", "v.", "trʌst", "信任")
        gloss("match", "n.", "mætʃ", "火柴")
      }
    },
    below: 9mm,
  )

  sect("Questions", "阅读理解 · 选出最佳答案")
  for (i, q) in reading.qs.enumerate() {
    row(
      mcq(i + 1, q.stem, q.choices, key: q.key, teacher: teacher),
      if teacher {
        rail-note("Answer · " + ("A", "B", "C", "D").at(q.key), [#zh(size: 8pt)[#q.why]])
        rail-note("Tempting wrong choice", [#zh(size: 8pt)[#q.trap]], accent: muted)
        rail-note("Repair move", [#zh(size: 8pt)[#q.repair]], accent: muted)
      } else {
        rail-note("Evidence 依据", [
          #v(2.6mm)
          #hair(c: rule-c)
          #v(4.4mm)
          #hair(c: rule-c)
        ], accent: muted)
      },
      below: if teacher { 3.2mm } else { 6.5mm },
    )
  }
  if not teacher {
    v(2mm)
    row([], rail-note("Margin notes 页边笔记", {
      v(1mm)
      for _ in range(0, 5) { v(5.6mm); hair(c: rule-c) }
    }, accent: muted), below: 0mm)
  }
})

// ── 04 CLOZE ──────────────────────────────────────────────────────────
#let blank(n) = box(width: 15mm, stroke: (bottom: 0.5pt + ink), inset: (bottom: 0.3mm), baseline: 0.3mm,
  align(center, text(size: 8.6pt, style: "italic", fill: oxblood, number-type: "lining")[#n]))

#let cloze-rows(teacher: false) = {
  for r in cloze.rows {
    block(width: 100%, breakable: false, above: 0pt, below: 0pt, stroke: (bottom: 0.3pt + rule-c), inset: (y: 6mm))[
      #grid(columns: (8mm, 1fr, 1fr, 1fr, 1fr), column-gutter: 2mm, align: horizon,
        text(size: 12pt, style: "italic", fill: oxblood, number-type: "lining")[#r.n],
        ..r.choices.enumerate().map(((i, c)) => {
          let hit = teacher and r.key == i
          grid(columns: (4.5mm, 1fr), column-gutter: 1mm, align: horizon,
            opt-letter(i, filled: hit),
            if hit { text(fill: oxblood, weight: "medium")[#c] } else { c })
        }))
    ]
  }
}

#let page-cloze() = std-page({
  opener("Part four  ·  Cloze", "完形填空", cloze.heading, size: 28pt,
    rail: rail-note("Directions 说明", [#zh(size: 8.4pt)[#cloze.direction-zh]]))

  row(
    {
      set par(first-line-indent: 0pt, justify: true, leading: 1.5em)
      set text(size: 13pt)
      fill-blanks(cloze.passage, blank)
    },
    {
      rail-note("Strategy 策略", [#zh(size: 8.4pt)[先看空格前后的时间词，再判断动词形式。]])
      rail-note("Margin notes 页边笔记", {
        v(1mm)
        for _ in range(0, 5) { v(5.6mm); hair(c: rule-c) }
      }, accent: muted)
    },
    below: 10mm,
  )

  sect("Options", "选项 · 与空格编号对应")
  block(width: w-main)[#cloze-rows()]
  v(1fr)
  block(width: 100%, above: 0pt)[
    #hair(w: w-full, c: rule-c)
    #v(2.2mm)
    #grid(columns: (w-main, w-gut, w-rail), column-gutter: 0pt,
      [#label("Read it back", fill: oxblood, size: 8.4pt) #h(1.5mm) #zh(size: 8.4pt, fill: muted)[填完后通读一遍]
        #v(1.2mm)
        #text(size: 9.6pt, style: "italic")[Does every sentence still make sense in order?]],
      [], [])
  ]
})

// ── 05 WRITING ────────────────────────────────────────────────────────
#let page-writing() = std-page({
  opener("Part five  ·  Writing", "写作", writing.heading, size: 30pt,
    rail: rail-note("Three sentences or more", [#zh(size: 8.4pt)[先写，再对照页底的清单检查。]]))

  sect("A · Combine", "合并句子")
  for (i, c) in writing.combine.enumerate() {
    row(
      [
        #grid(columns: (6mm, 1fr), column-gutter: 1mm,
          text(size: 12pt, style: "italic", fill: oxblood, number-type: "lining")[#(i + 1)],
          [
            #set par(justify: false, leading: 0.62em, spacing: 0.5em)
            #text(style: "italic")[#c.a #h(1mm) #c.b]
            #v(2mm)
            #label("use: " + c.use, fill: oxblood, size: 7.8pt)
            #ruled(2, gap: 8.4mm)
          ])
      ],
      if i == 0 { rail-note("Tip 提示", [#zh(size: 8.4pt)[先想：哪件事先发生？先发生的那件用 had + 过去分词。]]) } else { [] },
      below: 4mm,
    )
  }

  sect("B · Continue the story", "续写")
  row(
    [
      #set par(justify: false, leading: 0.66em)
      #text(size: 11.4pt, style: "italic")[#writing.story-prompt]
      #v(1.4mm)
      #zh(size: 9.4pt, fill: muted)[#writing.story-prompt-zh]
      #ruled(10, gap: 8.8mm)
    ],
    [
      #rail-note("Length 篇幅", [#zh(size: 8.4pt)[3–4 句，约 40–60 词。]])
      #rail-note("Margin notes 页边笔记", {
        v(1mm)
        for _ in range(0, 4) { v(5.6mm); hair(c: rule-c) }
      }, accent: muted)
    ],
    below: 0mm,
  )
  v(1fr)
  block(width: 100%, above: 0pt, breakable: false)[
    #hair(w: w-full, c: ink, t: 0.5pt)
    #v(2.4mm)
    #label("Before you hand in", fill: oxblood, size: 8.4pt) #h(1.5mm) #zh(size: 8.4pt, fill: muted)[交作业前]
    #v(2mm)
    #block(width: w-main)[
      #set par(leading: 0.6em)
      #for c in writing.checklist {
        block(below: 1.8mm, grid(columns: (4.8mm, 1fr), column-gutter: 0.6mm, align: top,
          check-circle(), text(size: 9.4pt)[#c]))
      }
    ]
  ]
})
