// D3 · 索引 Index — tabbed, colour-coded workbook.
// Idea: a student's own index-card box. Five skills each own a colour and an
// edge tab; cards have a flat offset edge; letters live in coloured circles.
// Colour never works alone: every tab, badge and bar also carries a word.

#import "../content.typ": *
#import "../shared-flat.typ": lighthouse-flat

// ── tokens ────────────────────────────────────────────────────────────
#let paper  = rgb("#fff8ec")
#let navy   = rgb("#1d2a4d")
#let navy-2 = rgb("#2d3d6b")
#let muted  = rgb("#6a7390")
#let tomato = rgb("#ee5b3e")
#let mustard = rgb("#f3b23b")
#let teal   = rgb("#169c86")
#let sky    = rgb("#4a98e6")
#let lilac  = rgb("#8574d4")

#let tint(c, p: 16%) = color.mix((c, p), (paper, 100% - p), space: oklab)

#let skills = (
  words:   (c: mustard, en: "Words",   zh: "词汇", n: "01"),
  grammar: (c: tomato,  en: "Grammar", zh: "语法", n: "02"),
  reading: (c: teal,    en: "Reading", zh: "阅读", n: "03"),
  cloze:   (c: sky,     en: "Cloze",   zh: "完形", n: "04"),
  writing: (c: lilac,   en: "Writing", zh: "写作", n: "05"),
)

#let en-font = ("Teaching Press Sans", "Noto Serif SC")
#let head-font = ("Teaching Press Sans", "Noto Serif SC")
#let zh-font = ((name: "Teaching Press Sans", covers: "latin-in-cjk"), "Noto Serif SC")
#let zh-head = ((name: "Teaching Press Sans", covers: "latin-in-cjk"), "Noto Serif SC")

// ── type helpers ──────────────────────────────────────────────────────
#let zh(body, size: auto, weight: "regular", fill: auto) = text(
  font: zh-font, lang: "zh", weight: weight,
  size: if size == auto { 1em } else { size },
  fill: if fill == auto { navy } else { fill }, body)
#let zh-h(body, size: 12pt, fill: navy) = text(font: zh-head, lang: "zh", size: size, weight: "bold", fill: fill, body)
#let head(body, size: 24pt, fill: navy) = text(font: head-font, weight: "bold", size: size, fill: fill, body)
#let ipa(s) = text(font: "Libertinus Serif", fill: muted, size: 1.04em)[/#s/]

// ── primitives ────────────────────────────────────────────────────────
#let pill(body, c: teal, fg: white, size: 7.6pt, x: 2.8mm, y: 1.1mm) = box(
  fill: c, radius: 50%, inset: (x: x, y: y), baseline: 0.2em,
  text(size: size, weight: "bold", fill: fg, tracking: 0.04em, body))

#let card(body, fill: white, c: navy, r: 3.2mm, sh: 1.5mm, inset: 4.2mm, shadow: navy) = layout(sz => {
  let b = rect(width: sz.width - sh, radius: r, fill: fill, stroke: 1.1pt + c, inset: inset, body)
  let h = measure(b).height
  box(width: sz.width, height: h + sh, {
    place(top + left, dx: sh, dy: sh, rect(width: sz.width - sh, height: h, radius: r, fill: shadow))
    place(top + left, b)
  })
})

#let num-dot(n, c: navy, size: 6mm, fg: white) = box(width: size, height: size, radius: 50%, fill: c, baseline: 0pt,
  align(center + horizon, text(size: size * 0.47, weight: "bold", fill: fg)[#n]))

#let star5(r, fill: mustard, stroke-c: navy) = {
  let pts = range(0, 10).map(i => {
    let rr = if calc.even(i) { r } else { r * 0.42 }
    let a = -90deg + i * 36deg
    (r + rr * calc.cos(a), r + rr * calc.sin(a))
  })
  box(width: 2 * r, height: 2 * r, baseline: 12%, polygon(fill: fill, stroke: 0.9pt + stroke-c, ..pts))
}

#let tick-icon(c: teal, s: 5mm) = box(width: s, height: s, baseline: 15%, {
  place(top + left, circle(radius: s / 2, fill: c, stroke: none))
  place(top + left, line(start: (s * 0.26, s * 0.52), end: (s * 0.43, s * 0.68), stroke: 1.3pt + white))
  place(top + left, line(start: (s * 0.43, s * 0.68), end: (s * 0.76, s * 0.34), stroke: 1.3pt + white))
})
#let cross-icon(c: tomato, s: 5mm) = box(width: s, height: s, baseline: 15%, {
  place(top + left, circle(radius: s / 2, fill: c, stroke: none))
  place(top + left, line(start: (s * 0.3, s * 0.3), end: (s * 0.7, s * 0.7), stroke: 1.3pt + white))
  place(top + left, line(start: (s * 0.7, s * 0.3), end: (s * 0.3, s * 0.7), stroke: 1.3pt + white))
})

#let magnifier(c: navy, s: 4.6mm) = box(width: s, height: s, baseline: 18%, {
  place(top + left, circle(radius: s * 0.32, stroke: 1pt + c, fill: none))
  place(top + left, dx: s * 0.56, dy: s * 0.56, line(angle: 45deg, length: s * 0.5, stroke: 1.3pt + c))
})

#let dotted-lines(n, gap: 8mm, c: muted) = for _ in range(0, n) {
  v(gap)
  block(height: 0pt, width: 100%, stroke: (bottom: (dash: "dotted", paint: c, thickness: 0.9pt)), above: 0pt, below: 0pt)
}

// ── edge tabs ─────────────────────────────────────────────────────────
#let tab-stack(active) = {
  let order = ("words", "grammar", "reading", "cloze", "writing")
  let h = 25mm
  for (i, k) in order.enumerate() {
    let s = skills.at(k)
    let on = k == active
    let w = if on { 13mm } else { 8.6mm }
    place(top + right, dx: 0mm, dy: 22mm + i * (h + 2.2mm),
      box(width: w, height: h, fill: if on { s.c } else { tint(s.c, p: 32%) },
        stroke: (left: 1.1pt + navy, top: 1.1pt + navy, bottom: 1.1pt + navy), radius: (left: 2.6mm),
        align(center + horizon, rotate(90deg, reflow: true,
          text(size: if on { 8.6pt } else { 7.4pt }, weight: "bold", fill: if on { if s.c == mustard { navy } else { white } } else { navy }, tracking: 0.05em,
            [#s.n #s.en])))))
  }
}

// ── page frame ────────────────────────────────────────────────────────
#let page-args(skill: "reading", running: lesson.title-en + " · " + lesson.title-zh, edition: "Student Edition") = (
  paper: "a4",
  fill: paper,
  margin: (left: 16mm, right: 24mm, top: 18mm, bottom: 16.5mm),
  foreground: tab-stack(skill),
  header: grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
    [#pill("LESSON " + lesson.number, c: navy, size: 6.8pt) #h(1.6mm) #text(size: 8pt, weight: "medium", fill: muted)[#running]],
    text(size: 8pt, weight: "medium", fill: muted)[#edition]),
  header-ascent: 5mm,
  footer: context align(center, box(fill: navy, radius: 50%, inset: (x: 3mm, y: 0.9mm), text(size: 8pt, weight: "bold", fill: white)[#counter(page).display("1")])),
  footer-descent: 6mm,
)

#let setup(body) = {
  set text(font: en-font, size: 10.6pt, lang: "en", fill: navy, ligatures: false)
  set par(leading: 0.78em, spacing: 1em, justify: false)
  show strong: set text(weight: "bold", fill: tomato)
  show emph: set text(style: "italic")
  body
}

#let std-page(skill, edition: "Student Edition", body) = page(..page-args(skill: skill, edition: edition))[#body]

// section title: pill + big rounded heading
#let title-block(skill, title, size: 25pt, meta: none) = {
  let sk = skills.at(skill)
  block(below: 4mm)[
    #set block(spacing: 0pt)
    #grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
      [
        #pill(sk.n + "  " + upper(sk.en), c: sk.c, fg: if sk.c == mustard { navy } else { white }, size: 7.6pt) #h(1.4mm) #zh-h(size: 9pt, fill: muted)[#sk.zh]
        #v(2.4mm)
        #head(size: size)[#title]
      ],
      if meta != none { text(size: 8.4pt, weight: "medium", fill: muted)[#meta] })
  ]
}

// ── answer-bar MCQ ────────────────────────────────────────────────────
#let ans-bar(i, body, accent, hit: false, pady: 0.75mm) = block(width: 100%, breakable: false, below: 0pt,
  rect(width: 100%, radius: 2.4mm, inset: (x: 2mm, y: pady),
    stroke: 1pt + navy, fill: if hit { accent } else { white },
    grid(columns: (5.4mm, 1fr), column-gutter: 2.4mm, align: horizon,
      box(width: 5.4mm, height: 5.4mm, radius: 50%, fill: if hit { white } else { accent }, stroke: if hit { 1pt + navy } else { none },
        align(center + horizon, text(size: 8.4pt, weight: "bold", fill: if hit { navy } else if accent == mustard { navy } else { white })[#("A", "B", "C", "D").at(i)])),
      text(size: 10pt, weight: if hit { "bold" } else { "regular" }, fill: if hit { if accent == mustard { navy } else { white } } else { navy })[#body])))

#let stem-blank = box(width: 15mm, height: 0.8em, stroke: (bottom: (dash: "dotted", paint: navy, thickness: 1.3pt)), baseline: 0pt)

#let mcq(n, stem, choices, accent, key: none, teacher: false, cols: 1) = block(width: 100%, breakable: false, below: 0pt)[
  #set block(spacing: 0pt)
  #set par(spacing: 0pt)
  #grid(columns: (7mm, 1fr), column-gutter: 2.6mm, align: top,
    num-dot(n, size: 7mm),
    pad(top: 1.5mm, text(weight: "bold", size: 10.6pt)[#stem-with-blank(stem, stem-blank)]))
  #v(1.4mm)
  #pad(left: 9.6mm,
    grid(columns: (1fr,) * cols, column-gutter: 1.8mm, row-gutter: 0.9mm,
      ..choices.enumerate().map(((i, c)) => ans-bar(i, c, accent, hit: teacher and key == i, pady: if teacher { 1.3mm } else { 0.75mm }))))
]

// ── COVER ─────────────────────────────────────────────────────────────
#let star(x, y, r, c) = place(top + left, dx: x, dy: y, polygon(fill: c, stroke: none,
  (0pt, -r), (r * 0.22, -r * 0.22), (r, 0pt), (r * 0.22, r * 0.22), (0pt, r), (-r * 0.22, r * 0.22), (-r, 0pt), (-r * 0.22, -r * 0.22)))

#let night-scene(w, h) = {
  let lw = 56mm
  let lx = 110mm
  let ly = 20mm
  let u = lw / 100
  let cx = lx + 50 * u
  let cy = ly + 39 * u
  block(width: w, height: h, fill: navy, radius: 4.5mm, clip: true, stroke: 1.4pt + navy, {
    place(top + left, rect(width: w, height: h * 0.72, fill: gradient.linear(navy.transparentize(100%), navy-2, angle: 90deg), stroke: none))
    place(top + left, dx: 16mm, dy: 14mm, circle(radius: 13mm, fill: rgb("#fff0c4"), stroke: none))
    place(top + left, dx: 25mm, dy: 9.5mm, circle(radius: 12mm, fill: navy, stroke: none))
    for (x, y, r, c) in ((52, 14, 2.6, mustard), (66, 36, 1.6, white), (96, 12, 2.8, white), (150, 30, 1.8, mustard), (12, 62, 1.6, white), (84, 8, 1.6, white), (160, 14, 2.1, white), (40, 44, 1.4, white), (130, 10, 1.4, mustard)) {
      star(x * 1mm, y * 1mm, r * 1mm, c)
    }
    place(top + left, polygon(fill: mustard.transparentize(66%), stroke: none, (cx - 1mm, cy), (0mm, cy - 18mm), (0mm, cy + 18mm)))
    place(top + left, polygon(fill: mustard.transparentize(66%), stroke: none, (cx + 1mm, cy), (w, cy - 16mm), (w, cy + 16mm)))
    place(top + left, polygon(fill: navy-2, stroke: none,
      (lx + 14 * u, 96mm), (lx + 22 * u, 87mm), (lx + 40 * u, 84mm), (lx + 62 * u, 84mm), (lx + 80 * u, 88mm), (lx + 90 * u, 100mm), (lx + 8 * u, 100mm)))
    place(top + left, dx: lx, dy: ly, lighthouse-flat(lw, tower: paper, band: tomato, roof: tomato, glass: mustard, base: paper))
    for (r, (c, cyr)) in ((teal, 98mm), (rgb("#0f7f6d"), 106mm), (rgb("#0a5f55"), 114mm)).enumerate() {
      for k in range(0, 20) {
        place(top + left, dx: k * 11mm - 6mm + calc.rem(r, 2) * 5.5mm, dy: cyr, circle(radius: 6.4mm, fill: c, stroke: none))
      }
    }
  })
}

#let page-cover() = page(margin: 0mm, header: none, footer: none, fill: paper, background: none, foreground: none)[
  #place(top + left, dx: 16mm, dy: 14mm, block(width: 170mm)[
    #grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
      [#pill(lesson.series, c: navy, size: 7pt) #h(1.5mm) #zh(size: 8.6pt, fill: muted, weight: "medium")[#lesson.series-zh]],
      text(size: 8pt, weight: "medium", fill: muted)[#lesson.grade · #lesson.minutes])
  ])

  #place(top + left, dx: 16mm, dy: 28mm, block(width: 174mm, height: 128mm)[
    #place(top + left, dx: 2.4mm, dy: 2.4mm, rect(width: 171.6mm, height: 125.6mm, radius: 4.5mm, fill: tomato, stroke: 1.4pt + navy))
    #night-scene(171.6mm, 125.6mm)
  ])
  #place(top + left, dx: 150mm, dy: 20mm, rotate(8deg, box(width: 30mm, height: 30mm, radius: 50%, fill: mustard, stroke: 1.4pt + navy,
    align(center + horizon, stack(spacing: 0.4mm,
      text(size: 6.8pt, weight: "bold", tracking: 0.14em, fill: navy)[LESSON],
      text(font: head-font, size: 26pt, weight: "bold", fill: navy)[#lesson.number])))))

  #place(top + left, dx: 16mm, dy: 170mm, block(width: 170mm)[
    #set par(leading: 0.1em, spacing: 0pt)
    #head(size: 56pt)[#lesson.title-en]
    #v(6mm)
    #text(size: 15pt, weight: "medium", fill: navy-2)[#lesson.tagline-en]
    #v(4.5mm)
    #pill(lesson.title-zh, c: navy, size: 12pt, x: 4.4mm, y: 1.8mm)
    #h(2mm)
    #zh(size: 10.4pt, fill: muted, weight: "medium")[#lesson.tagline-zh]
  ])

  #place(top + left, dx: 16mm, dy: 232mm, block(width: 170mm)[
    #grid(columns: (auto,) * 5 + (1fr,), column-gutter: 2mm,
      ..skills.values().map(s => box(fill: s.c, radius: 50%, inset: (x: 3.2mm, y: 1.5mm), stroke: 1pt + navy,
        text(size: 8pt, weight: "bold", fill: if s.c == mustard { navy } else { white })[#s.n #s.en])),
      [])
  ])

  #place(bottom + left, dx: 16mm, dy: -22mm, block(width: 170mm)[
    #grid(columns: (1fr, 1fr, 1fr), column-gutter: 4mm,
      ..(labels.name, labels.date, labels.class).map(l => rect(width: 100%, height: 11mm, radius: 2.6mm, stroke: (dash: "dashed", paint: muted, thickness: 0.8pt), fill: none, inset: (x: 3mm, y: 0mm),
        align(left + horizon, zh(size: 8.4pt, fill: muted, weight: "medium")[#l]))))
  ])
  #place(bottom + left, dx: 16mm, dy: -11mm, text(size: 7pt, weight: "bold", tracking: 0.14em, fill: muted)[#lesson.brand #h(2mm) · #h(2mm) STUDENT EDITION])
  #place(top + right, dx: 0mm, dy: 0mm, {
    for (i, s) in skills.values().enumerate() {
      place(top + right, dy: 170mm + i * 20mm - 2mm,
        box(width: 7mm, height: 18mm, fill: s.c, stroke: (left: 1.1pt + navy, top: 1.1pt + navy, bottom: 1.1pt + navy), radius: (left: 2.2mm), []))
    }
  })
]

// ── 01 WORDS ──────────────────────────────────────────────────────────
#let flashcard(e, i) = {
  let c = mustard
  block(width: 100%, radius: 2.6mm, stroke: 1pt + navy, inset: 0mm, fill: white, clip: true,
    stack(
      block(width: 100%, fill: tint(c, p: 70%), inset: (x: 3mm, y: 1.7mm), stroke: (bottom: 1pt + navy),
        grid(columns: (auto, auto, 1fr), column-gutter: 2mm, align: horizon,
          num-dot(i + 1, size: 4.6mm, c: navy),
          [#head(size: 14.5pt)[#e.word] #h(0.6mm) #text(size: 7.4pt, weight: "bold", fill: navy-2)[#e.pos]],
          align(right, text(size: 9pt)[#ipa(e.ipa)]))),
      block(width: 100%, inset: (x: 3mm, y: 2.6mm))[
        #set par(leading: 0.58em, spacing: 0.3em)
        #zh-h(size: 11.4pt)[#e.zh]
        #v(1mm)
        #text(size: 9.4pt, style: "italic")[#e.ex]
        #v(1mm)
        #text(size: 7.6pt, fill: muted, weight: "medium")[#e.note]
      ]))
}

#let page-words() = std-page("words", {
  title-block("words", words-page.title, size: 23pt, meta: str(vocab.len()) + " words · Track " + sound.track)

  // three steps
  block(below: 3.6mm)[
    #grid(columns: (auto, auto, auto, 1fr), column-gutter: 2.4mm, align: horizon,
      ..words-page.steps.enumerate().map(((i, st)) => box(fill: white, stroke: 1pt + navy, radius: 50%, inset: (x: 2.6mm, y: 1.2mm),
        [#num-dot(i + 1, size: 4.6mm, c: mustard, fg: navy) #h(0.8mm) #text(size: 8.8pt, weight: "bold")[#st] #zh(size: 7.8pt, fill: muted)[ #words-page.steps-zh.at(i)]])),
      [])
  ]

  grid(columns: (1fr, 1fr), column-gutter: 3.4mm, row-gutter: 3.6mm,
    ..vocab.enumerate().map(((i, e)) => flashcard(e, i)))
  v(5.4mm)

  // sound check
  card(fill: tint(sky, p: 16%), shadow: navy, {
    grid(columns: (auto, 1.75fr, 1fr), column-gutter: 4mm, align: horizon,
      [
        #pill("SOUND CHECK", c: sky, size: 7pt) #zh-h(size: 8.6pt, fill: muted)[ #sound.title-zh]
        #v(1.8mm)
        #box(fill: navy, radius: 50%, inset: (x: 2.8mm, y: 1.2mm), text(size: 7.6pt, weight: "bold", fill: white, tracking: 0.08em)[▶  TRACK #sound.track])
      ],
      grid(columns: (0.9fr, 1.1fr), column-gutter: 2mm,
        ..sound.pair.map(p => grid(columns: (auto, 1fr), column-gutter: 2mm, align: horizon,
          box(width: 13.5mm, height: 13.5mm, radius: 50%, fill: white, stroke: 1.1pt + navy, align(center + horizon, text(size: 13.5pt, weight: "bold", font: "Libertinus Serif", fill: sky.darken(25%))[/#p.ipa/])),
          [#set par(leading: 0.5em)
           #text(weight: "bold", size: 10pt)[#p.word]\
           #zh(size: 7.8pt, fill: muted)[#p.cue-zh]]))),
      [
        #set par(leading: 0.5em)
        #zh(size: 8.4pt)[#sound.prompt-zh]
        #for n in (1, 2, 3) { grid(columns: (4mm, 1fr), align: bottom, text(size: 8pt, weight: "bold", fill: sky.darken(20%))[#n], block(height: 4.6mm, width: 100%, stroke: (bottom: (dash: "dotted", paint: navy, thickness: 0.9pt)))) }
      ])
  })
  v(4mm)

  block(breakable: false)[
    #pill("USE IT", c: mustard, fg: navy, size: 7pt) #h(1mm) #zh-h(size: 8.6pt, fill: muted)[造个句]
    #v(1.2mm)
    #zh(size: 9.4pt)[#words-page.task-zh]
    #dotted-lines(4, gap: 9mm)
  ]
})

// ── 02 GRAMMAR ────────────────────────────────────────────────────────
#let time-machine(w) = {
  let ax = 11.5mm
  let x1 = w * 0.29
  let x2 = w * 0.67
  box(width: w, height: 27mm, {
    place(top + left, dy: ax - 1.6mm, block(width: w - 3mm, height: 3.2mm, radius: 1.6mm, fill: navy))
    place(top + left, dx: w - 5mm, dy: ax - 3.8mm, polygon(fill: navy, stroke: none, (0mm, 0mm), (5mm, 3.8mm), (0mm, 7.6mm)))
    place(top + left, dx: x1, dy: ax - 8.4mm, block(width: x2 - x1, height: 4.6mm, radius: (top: 2.4mm), fill: tint(tomato, p: 40%), stroke: (top: 1pt + navy, left: 1pt + navy, right: 1pt + navy),
      align(center + horizon, text(size: 6.8pt, weight: "bold", tracking: 0.12em, fill: navy)[BEFORE])))
    place(top + left, dx: x1 - 3.4mm, dy: ax - 3.4mm, circle(radius: 3.4mm, fill: tomato, stroke: 1.1pt + navy))
    place(top + left, dx: x2 - 3.4mm, dy: ax - 3.4mm, circle(radius: 3.4mm, fill: white, stroke: 1.1pt + navy))
    place(top + left, dx: x1 - 3.4mm, dy: ax - 3.4mm, box(width: 6.8mm, height: 6.8mm, align(center + horizon, text(size: 7.8pt, weight: "bold", fill: white)[1])))
    place(top + left, dx: x2 - 3.4mm, dy: ax - 3.4mm, box(width: 6.8mm, height: 6.8mm, align(center + horizon, text(size: 7.8pt, weight: "bold", fill: navy)[2])))
    place(top + left, dx: x1 - 22mm, dy: ax + 4.6mm, block(width: 44mm, align(center)[#pill(grammar.timeline.earlier.label, c: tomato, size: 8.6pt)\ #v(0.6mm) #text(size: 7.2pt, weight: "medium", fill: muted)[#grammar.timeline.earlier.when]]))
    place(top + left, dx: x2 - 26mm, dy: ax + 4.6mm, block(width: 52mm, align(center)[#pill(grammar.timeline.ref.label, c: navy, size: 8.6pt)\ #v(0.6mm) #text(size: 7.2pt, weight: "medium", fill: muted)[reference point]]))
    place(top + left, dx: w - 13mm, dy: ax + 4.6mm, text(size: 7.2pt, weight: "bold", fill: muted)[NOW])
  })
}

#let page-grammar() = std-page("grammar", {
  title-block("grammar", lesson.title-en, size: 23pt, meta: [#lesson.grade])

  // rule card + form
  grid(columns: (1fr, 41mm), column-gutter: 4mm, align: top,
    card(fill: white, {
      set par(leading: 0.66em)
      text(size: 11.6pt, weight: "bold")[#grammar.rule-en]
      v(1mm)
      zh(size: 9pt, fill: muted)[#grammar.rule-zh]
    }),
    block(width: 100%, fill: tomato, radius: 3.2mm, stroke: 1.1pt + navy, inset: 3.4mm, height: 23.5mm)[
      #set par(leading: 0.5em)
      #text(size: 6.8pt, weight: "bold", fill: white.transparentize(10%), tracking: 0.12em)[FORM]\
      #v(0.6mm)
      #head(size: 14pt, fill: white)[had\ + p.p.]
    ])
  v(2.4mm)

  card(fill: tint(tomato, p: 9%), inset: (x: 4.2mm, top: 3mm, bottom: 1.6mm), {
    place(top + left, [#pill("TIME MACHINE", c: navy, size: 6.8pt) #h(0.6mm) #zh-h(size: 8pt, fill: muted)[时间线]])
    time-machine(143mm)
  })
  v(2.4mm)

  // contrast + signals
  grid(columns: (1fr, 1fr), column-gutter: 4mm,
    card(fill: white, inset: 3.6mm, {
      pill(grammar.contrast.simple.tag, c: muted, size: 6.8pt)
      v(1.4mm)
      set par(leading: 0.6em)
      text(size: 10.2pt, weight: "medium")[#grammar.contrast.simple.en]
      v(1mm)
      zh(size: 8.6pt, fill: muted)[#grammar.contrast.simple.zh]
    }),
    card(fill: tint(tomato, p: 22%), inset: 3.6mm, {
      pill(grammar.contrast.perfect.tag, c: tomato, size: 6.8pt)
      v(1.4mm)
      set par(leading: 0.6em)
      text(size: 10.2pt, weight: "medium")[#grammar.contrast.perfect.en]
      v(1mm)
      zh(size: 8.6pt, fill: navy-2)[#grammar.contrast.perfect.zh]
    }))
  v(2.6mm)

  grid(columns: (1fr, 1fr), column-gutter: 4mm,
    block(width: 100%)[
      #text(size: 7.4pt, weight: "bold", tracking: 0.1em, fill: muted)[SIGNAL WORDS]
      #v(1.4mm)
      #for s in grammar.signals { box(fill: tint(mustard, p: 40%), radius: 50%, inset: (x: 2.4mm, y: 1mm), stroke: 0.8pt + navy, text(size: 8.2pt, weight: "semibold")[#s]); h(1mm); box(height: 5.4mm) }
    ],
    card(fill: white, c: tomato, shadow: tomato, inset: 3.2mm, {
      set par(leading: 0.58em)
      pill("OOPS · 易错", c: tomato, size: 6.8pt)
      v(1.2mm)
      grid(columns: (5mm, 1fr), column-gutter: 1.4mm, row-gutter: 1mm, align: top,
        cross-icon(s: 4.4mm), text(size: 8.8pt)[#strike(stroke: 0.9pt + tomato)[#grammar.caution-wrong]],
        tick-icon(s: 4.4mm), text(size: 8.8pt, weight: "bold")[#grammar.caution-right])
      v(0.4mm)
      zh(size: 8pt, fill: muted)[#grammar.caution-zh]
    }))
  v(2.8mm)

  // quick check
  pill("QUICK CHECK", c: tomato, size: 7pt)
  h(1mm)
  zh-h(size: 8.6pt, fill: muted)[小测]
  v(2mm)
  grid(columns: (1fr, 1fr), column-gutter: 4mm,
    ..grammar.check.enumerate().map(((i, q)) => mcq(i + 1, q.stem, q.choices, tomato, cols: 1)))
  v(2.2mm)
  block(breakable: false)[
    #grid(columns: (7mm, 1fr), column-gutter: 2.6mm, align: top,
      num-dot(3, size: 7mm),
      block(above: 1.3mm, [#text(weight: "bold")[Fix the sentence.] #zh(size: 8.6pt, fill: muted)[改正错误]]))
    #pad(left: 9.6mm)[#text(size: 10pt)[#grammar.fix.wrong] #dotted-lines(1, gap: 5.6mm)]
  ]
})

// ── 03 READING ────────────────────────────────────────────────────────
#let vocab-words = vocab.map(v => v.word)

#let page-reading(teacher: false) = std-page("reading", edition: if teacher { "Teacher Edition" } else { "Student Edition" }, {
  pp-show.update(teacher)
  let sk = skills.reading

  title-block("reading", reading.title, meta: [#reading.words words · 8 min])

  if not teacher { block(below: 3.5mm, width: 100%)[
    #grid(columns: (auto, 1fr), column-gutter: 2.6mm, align: horizon,
      text(size: 7.6pt, weight: "bold", tracking: 0.08em, fill: muted)[HUNT THE WORDS],
      {
        for w in vocab-words { box(fill: tint(mustard, p: 38%), radius: 50%, inset: (x: 2.2mm, y: 0.9mm), outset: (y: 0.3mm), text(size: 8.2pt, weight: "semibold")[#w]); h(1mm) }
      })
  ] }

  card(fill: tint(sk.c, p: 11%), c: navy, {
    set text(size: 10.6pt)
    set par(leading: if teacher { 0.8em } else { 0.88em })
    show regex("\\b(keeper|dusty|shelf|recorded|dusk|entry|trusted|match)\\b"): it => highlight(fill: mustard.transparentize(45%), top-edge: "ascender", bottom-edge: "descender", extent: 0.8pt, radius: 1pt)[#it]
    grid(columns: (7mm, 1fr), column-gutter: 2.8mm, row-gutter: if teacher { 3.4mm } else { 4.6mm }, align: top,
      ..reading.paras.enumerate().map(((i, p)) => (
        box(width: 5.6mm, height: 5.6mm, radius: 50%, fill: sk.c, align(center + horizon, text(size: 8pt, weight: "bold", fill: white)[#(i + 1)])),
        p)).flatten())
  })
  v(if teacher { 3.4mm } else { 5mm })

  for (i, q) in reading.qs.enumerate() {
    mcq(i + 1, q.stem, q.choices, sk.c, key: q.key, teacher: teacher, cols: if teacher { 2 } else { 1 })
    v(1mm)
    if teacher {
      pad(left: 9.6mm, rect(width: 100%, radius: 2.6mm, fill: tint(sk.c, p: 14%), stroke: 1pt + navy, inset: (x: 3mm, y: 2mm),
        grid(columns: (1fr, 1fr, 1fr), column-gutter: 3.6mm,
          ..((("Answer · " + ("A", "B", "C", "D").at(q.key)), q.why, sk.c), ("Tempting wrong choice", q.trap, tomato), ("Repair move", q.repair, navy)).map(((t, b, c)) => block[
            #pill(t, c: c, size: 6.4pt, y: 0.8mm)
            #v(1mm)
            #set par(leading: 0.58em)
            #zh(size: 8.4pt)[#b]
          ]))))
      v(1.8mm)
    } else {
      pad(left: 9.6mm, grid(columns: (auto, auto, 1fr), column-gutter: 1.6mm, align: bottom,
        magnifier(c: muted), text(size: 7.6pt, weight: "bold", fill: muted, tracking: 0.06em)[EVIDENCE 依据],
        block(height: 3mm, width: 100%, stroke: (bottom: (dash: "dotted", paint: muted, thickness: 0.9pt)))))
      v(2.2mm)
    }
  }
})

// ── 04 CLOZE ──────────────────────────────────────────────────────────
#let blank(n) = box(fill: white, stroke: 1pt + navy, radius: 50%, inset: (x: 1.4mm, y: 0.55mm), baseline: 0.5mm,
  [#box(width: 4.2mm, height: 4.2mm, radius: 50%, fill: sky, align(center + horizon, text(size: 7.6pt, weight: "bold", fill: white)[#n])) #h(7mm)])

#let cloze-bars(teacher: false) = for r in cloze.rows {
  block(width: 100%, breakable: false, below: 3.2mm)[
    #grid(columns: (7mm, 1fr, 1fr, 1fr, 1fr), column-gutter: 1.8mm, align: horizon,
      num-dot(r.n, size: 7mm),
      ..r.choices.enumerate().map(((i, c)) => ans-bar(i, c, sky, hit: teacher and r.key == i, pady: 1.7mm)))
  ]
}

#let page-cloze() = std-page("cloze", {
  title-block("cloze", cloze.heading, size: 25pt)
  block(below: 3.6mm)[#zh(size: 9.4pt, fill: muted)[#cloze.direction-zh]]
  card(fill: tint(sky, p: 10%), inset: 5mm, {
    set text(size: 12.6pt)
    set par(leading: 1.3em)
    fill-blanks(cloze.passage, blank)
  })
  v(7mm)
  pill("OPTIONS", c: sky, size: 7pt)
  h(1mm)
  zh-h(size: 8.6pt, fill: muted)[选项 · 与空格编号对应]
  v(3.4mm)
  cloze-bars()
  v(1fr)
  card(fill: tint(sky, p: 16%), inset: (x: 4.2mm, y: 3mm), {
    grid(columns: (auto, 1fr), column-gutter: 5mm, align: horizon,
      [#pill("MY ANSWERS", c: navy, size: 7pt) #h(1mm) #zh-h(size: 8.6pt, fill: muted)[我的答案]],
      grid(columns: (1fr,) * 5, column-gutter: 2.4mm,
        ..range(1, 6).map(n => grid(columns: (auto, 1fr), column-gutter: 1.4mm, align: horizon,
          num-dot(n, size: 5.6mm, c: sky),
          block(height: 6.4mm, width: 100%, radius: 1.8mm, fill: white, stroke: 1pt + navy)))))
  })
})

// ── 05 WRITING ────────────────────────────────────────────────────────
#let page-writing() = std-page("writing", {
  title-block("writing", writing.heading, size: 25pt)

  pill("A · COMBINE", c: lilac, size: 7pt)
  h(1mm)
  zh-h(size: 8.6pt, fill: muted)[合并句子]
  v(2.6mm)
  for (i, c) in writing.combine.enumerate() {
    block(width: 100%, breakable: false, below: 3.4mm)[
      #card(fill: white, inset: 3.4mm, {
        grid(columns: (7mm, 1fr), column-gutter: 2.6mm, align: top,
          num-dot(i + 1, size: 7mm, c: lilac),
          [
            #set par(leading: 0.62em)
            #box(fill: tint(lilac, p: 22%), radius: 2mm, inset: (x: 2mm, y: 1.2mm), text(size: 10pt)[#c.a])
            #h(0.8mm) #text(weight: "bold", fill: lilac, size: 11pt)[+] #h(0.8mm)
            #box(fill: tint(lilac, p: 22%), radius: 2mm, inset: (x: 2mm, y: 1.2mm), text(size: 10pt)[#c.b])
            #h(2mm)#pill("USE: " + upper(c.use), c: lilac, size: 6.8pt)
            #dotted-lines(2, gap: 8mm)
          ])
      })
    ]
  }

  v(1mm)
  pill("B · CONTINUE THE STORY", c: lilac, size: 7pt)
  h(1mm)
  zh-h(size: 8.6pt, fill: muted)[续写]
  v(2.6mm)
  card(fill: tint(lilac, p: 9%), inset: 4mm, {
    grid(columns: (1fr, 38mm), column-gutter: 4mm, align: top,
      [
        #set par(leading: 0.64em)
        #text(weight: "bold", size: 10.6pt)[#writing.story-prompt]\
        #zh(size: 9pt, fill: muted)[#writing.story-prompt-zh]
        #dotted-lines(12, gap: 8.6mm)
      ],
      [
        #pill("STAR CHECK", c: navy, size: 6.8pt)
        #v(1.6mm)
        #for c in writing.checklist {
          grid(columns: (5.4mm, 1fr), column-gutter: 1mm, align: top,
            star5(2.4mm, fill: white),
            text(size: 8.2pt)[#c])
          v(1.8mm)
        }
      ])
  })
})
