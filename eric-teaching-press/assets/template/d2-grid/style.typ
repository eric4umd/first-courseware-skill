// D2 · 网格 Grid — Swiss-modernist workbook system.
// Idea: information architecture. A strict 12-column grid, a left "index zone" of
// big numerals and labels, one saturated colour (cobalt) used only for things the
// learner acts on, a highlighter yellow used only for cautions.

#import "../content.typ": *
#import "../shared-flat.typ": lighthouse-flat

// ── tokens ────────────────────────────────────────────────────────────
#let paper   = rgb("#fcfcfb")
#let ink     = rgb("#0f1115")
#let mid     = rgb("#565c68")
#let line-c  = rgb("#d3d7de")
#let tint    = rgb("#eef1f6")
#let cobalt  = rgb("#2340e0")
#let cobalt-t = rgb("#e4e9ff")
#let hilite  = rgb("#ffe14d")

#let en-font = ("Teaching Press Sans", "Noto Serif SC")
#let zh-font = ((name: "Teaching Press Sans", covers: "latin-in-cjk"), "Noto Serif SC")

// grid: 12 cols across 178mm (16mm margins), 4mm gutters
#let mg   = 16mm
#let gut  = 4mm
#let colw = (178mm - 11 * gut) / 12
#let span(n) = n * colw + (n - 1) * gut
#let w-idx  = span(3)
#let w-main = span(9)

// ── type helpers ──────────────────────────────────────────────────────
#let zh(body, size: auto, weight: "regular", fill: auto) = text(
  font: zh-font, lang: "zh", weight: weight,
  size: if size == auto { 1em } else { size },
  fill: if fill == auto { ink } else { fill }, body)
#let cap(body, fill: mid, size: 7.4pt, weight: "medium") = text(
  size: size, fill: fill, weight: weight, tracking: 0.1em, upper(body))
#let ipa(s) = text(font: "Libertinus Serif", fill: mid, size: 1.02em)[/#s/]
#let bar(w: 100%, h: 0.5pt, c: ink) = block(width: w, height: h, fill: c, above: 0pt, below: 0pt)

// ── page frame ────────────────────────────────────────────────────────
#let page-args(running: lesson.title-en + " · " + lesson.title-zh, edition: "Student Edition") = (
  paper: "a4",
  fill: paper,
  margin: (left: mg, right: mg, top: 22mm, bottom: 18mm),
  header: place(top + left, dy: 0mm, block(width: 100%, height: 2.2mm, fill: cobalt)),
  header-ascent: 0mm,
  footer: context grid(columns: (1fr, auto, 1fr), align: (left + horizon, center + horizon, right + horizon),
    cap(running, size: 6.8pt), [],
    [#cap(edition, size: 6.8pt) #h(3mm) #text(size: 7.6pt, weight: "bold", fill: cobalt)[#counter(page).display("01")]]),
  footer-descent: 6mm,
)

#let setup(body) = {
  set text(font: en-font, size: 10.4pt, lang: "en", fill: ink, weight: "regular", ligatures: false)
  set par(leading: 0.78em, spacing: 1em, justify: false)
  show strong: set text(weight: "bold", fill: cobalt)
  show emph: set text(style: "italic")
  body
}

#let std-page(edition: "Student Edition", body) = page(..page-args(edition: edition))[#body]

// ── building blocks ───────────────────────────────────────────────────
#let letter-tile(i, filled: false, size: 6.4mm) = box(
  width: size, height: size, baseline: 0pt,
  fill: if filled { white } else { cobalt }, stroke: none,
  align(center + horizon, text(size: 8.6pt, weight: "bold", fill: if filled { cobalt } else { white })[#("A", "B", "C", "D").at(i)]))

#let num-tile(n, size: 7mm, fill: ink) = box(width: size, height: size, fill: fill, align(center + horizon, text(size: 10pt, weight: "bold", fill: white)[#n]))

#let stem-blank = box(width: 15mm, height: 0.8em, stroke: (bottom: 1pt + cobalt), baseline: 0pt)

// 2×2 tile MCQ — grid cells share row height, gutters stay open
#let mcq(n, stem, choices, key: none, teacher: false, compact: false, cols: 2) = block(width: 100%, breakable: false, below: 0pt)[
  #set block(spacing: 0pt)
  #set par(spacing: 0pt)
  #grid(columns: (7mm, 1fr), column-gutter: 2.5mm, align: horizon,
    num-tile(n),
    text(weight: "bold", size: 10.4pt)[#stem-with-blank(stem, stem-blank)])
  #v(2.2mm)
  #pad(left: 9.5mm,
    grid(columns: (1fr,) * cols, column-gutter: 2.4mm, row-gutter: 2.4mm,
      inset: (x: 2.6mm, y: if compact { 1.7mm } else { 2.4mm }),
      ..choices.enumerate().map(((i, c)) => {
        let hit = teacher and key == i
        grid.cell(
          stroke: 0.7pt + (if hit { cobalt } else { ink }),
          fill: if hit { cobalt } else { none },
          grid(columns: (6.4mm, 1fr), column-gutter: 2.2mm, align: horizon,
            letter-tile(i, filled: hit),
            text(size: 10pt, fill: if hit { white } else { ink }, weight: if hit { "bold" } else { "regular" })[#c]))
      })))
]

#let note-col(title, body, fill: ink) = block(width: 100%)[
  #cap(title, fill: fill, size: 6.8pt, weight: "bold")
  #v(1mm)
  #set text(size: 8.4pt, lang: "zh")
  #set par(leading: 0.58em)
  #zh(size: 8.4pt)[#body]
]

// page opener: big numeral in the index zone, bold title in the main zone
#let opener(n, title, size: 27pt) = {
  grid(columns: (w-idx, gut, w-main), align: bottom,
    text(size: 52pt, weight: "light", fill: cobalt, tracking: -0.04em, bottom-edge: "baseline")[#n],
    [],
    block(below: 1.5mm)[#text(size: size, weight: "bold", tracking: -0.03em, bottom-edge: "baseline")[#title]],
  )
  v(3.5mm)
  bar(h: 1.2pt)
  v(4mm)
}

// two-zone body: index zone (left) + main (right)
#let zones(idx, main) = grid(columns: (w-idx, gut, w-main), row-gutter: 0mm, idx, [], main)

#let index-label(en, zh-s, meta: none) = [
  #cap(en, fill: ink, weight: "bold", size: 8pt) #h(1.6mm) #zh(size: 8.6pt, fill: mid)[#zh-s]
  #if meta != none { v(1mm); text(size: 8.4pt, fill: mid)[#meta] }
]

#let hilite-box(title, body) = block(width: 100%, inset: (x: 2.6mm, y: 2.4mm), fill: hilite)[
  #cap(title, fill: ink, weight: "bold", size: 6.8pt)
  #v(0.8mm)
  #set par(leading: 0.58em)
  #body
]

#let write-lines(n, gap: 8mm) = for _ in range(0, n) {
  v(gap)
  bar(h: 0.5pt, c: line-c)
}

#let check-box(done: false) = box(width: 3.6mm, height: 3.6mm, stroke: 0.9pt + cobalt, baseline: 12%, fill: if done { cobalt } else { none })

// ── COVER ─────────────────────────────────────────────────────────────
#let page-cover() = {
  let t = (178mm - 2 * gut) / 3
  page(margin: 0mm, header: none, footer: none, fill: paper, background: none)[
    #place(top + left, dx: mg, dy: 14mm, block(width: 178mm)[
      #grid(columns: (1fr, 1fr, 1fr), align: (left, center, right),
        cap(lesson.series, fill: ink, size: 7.4pt, weight: "bold"),
        cap("Lesson " + lesson.number, size: 7.4pt),
        cap(lesson.grade + "  ·  " + lesson.minutes, size: 7.4pt))
      #v(2.4mm)
      #bar(h: 1.2pt)
    ])

    #place(top + left, dx: mg, dy: 31mm, block(width: 178mm)[
      #set par(leading: 0.02em, spacing: 0pt)
      #block(below: 0pt)[#text(size: 72pt, weight: "bold", tracking: -0.04em)[#lesson.title-en.split(" ").join(linebreak())]]
      #v(8mm)
      #grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
        text(size: 15pt, weight: "medium")[#lesson.tagline-en],
        zh(size: 11pt, fill: mid)[#lesson.title-zh · #lesson.tagline-zh])
    ])

    #place(top + left, dx: mg, dy: 124mm, grid(
      columns: (t, t, t), rows: (t, t), column-gutter: gut, row-gutter: gut,
      grid.cell(colspan: 2, block(width: 100%, height: 100%, fill: cobalt, inset: 0mm, clip: true, {
        place(top + left, dx: 6mm, dy: 5mm, cap("auxiliary verb", fill: white.transparentize(15%), size: 7pt))
        place(bottom + left, dx: 3.5mm, dy: -5mm, text(size: 150pt, weight: "bold", fill: white, tracking: -0.05em, bottom-edge: "baseline")[had])
      })),
      block(width: 100%, height: 100%, fill: ink, inset: 0mm, clip: true, {
        place(top + left, dx: 6mm, dy: 5mm, cap("lesson", fill: white.transparentize(30%), size: 7pt))
        place(bottom + left, dx: 4.5mm, dy: -5mm, text(size: 104pt, weight: "light", fill: white, tracking: -0.05em, bottom-edge: "baseline")[#lesson.number])
      }),
      rect(width: 100%, height: 100%, fill: none, stroke: 1.2pt + ink, inset: 5mm, {
        cap("中文", size: 7pt)
        v(1fr)
        zh(size: 25pt, weight: "semibold")[#lesson.title-zh]
        v(2mm)
        zh(size: 9pt, fill: mid)[#lesson.tagline-zh]
      }),
      rect(width: 100%, height: 100%, fill: tint, inset: 5mm, {
        cap("signals", size: 7pt)
        v(2.5mm)
        set text(size: 12.5pt, weight: "bold")
        set par(leading: 0.55em)
        for s in grammar.signals.slice(0, calc.min(4, grammar.signals.len())) {
          [#highlight(fill: hilite, top-edge: "ascender", bottom-edge: "descender", extent: 1.2pt)[#s]\ ]
        }
      }),
      block(width: 100%, height: 100%, fill: cobalt-t, inset: 0mm, clip: true, {
        place(bottom + center, dy: -3mm, lighthouse-flat(30mm, tower: white, band: cobalt, roof: ink, glass: hilite, base: ink, beam: hilite.transparentize(55%)))
      }),
    ))

    #place(bottom + left, dx: mg, dy: -24mm, block(width: 178mm)[
      #grid(columns: (1fr, 1fr, 1fr), column-gutter: 6mm,
        ..(labels.name, labels.date, labels.class).map(l => block[
          #zh(size: 8pt, fill: mid)[#l]
          #v(5.4mm)
          #bar(h: 0.6pt, c: ink)
        ]))
    ])
    #place(bottom + left, dx: mg, dy: -12mm, block(width: 178mm)[
      #grid(columns: (1fr, auto), cap(lesson.brand, fill: ink, size: 6.8pt, weight: "bold"), cap("Student Edition · 学生版", size: 6.8pt))
    ])
  ]
}

// ── 01 WORDS ──────────────────────────────────────────────────────────
#let page-words() = std-page({
  opener("01", words-page.title, size: 24pt)
  zones(
    [
      #index-label("Words", "词汇", meta: str(vocab.len()) + " words · Track " + sound.track)
      #v(5mm)
      #cap("How to use", fill: ink, weight: "bold", size: 6.8pt)
      #v(2mm)
      #for (i, st) in words-page.steps.enumerate() {
        grid(columns: (6mm, 1fr), column-gutter: 2mm, align: horizon, row-gutter: 2.4mm,
          num-tile(i + 1, size: 6mm, fill: cobalt),
          [#text(weight: "bold", size: 9.4pt)[#st] #zh(size: 8pt, fill: mid)[ #words-page.steps-zh.at(i)]])
        v(2.4mm)
      }
    ],
    [
      #set block(spacing: 0pt)
      #table(
        columns: (6mm, 33mm, 24mm, 1fr),
        stroke: (x: none, y: 0.5pt + line-c), inset: (x: 1.6mm, y: 2.7mm), align: (center + top, left + top, left + top, left + top),
        table.header(
          table.cell(stroke: (bottom: 1.2pt + ink))[#cap("#", size: 6.6pt)],
          table.cell(stroke: (bottom: 1.2pt + ink))[#cap("Word · IPA", size: 6.6pt)],
          table.cell(stroke: (bottom: 1.2pt + ink))[#cap("中文", size: 6.6pt)],
          table.cell(stroke: (bottom: 1.2pt + ink))[#cap("In the story · Note", size: 6.6pt)],
        ),
        ..vocab.enumerate().map(((i, e)) => (
          text(size: 8.4pt, weight: "bold", fill: cobalt)[#(i + 1)],
          [#text(size: 11.4pt, weight: "bold")[#e.word] #text(size: 7.6pt, fill: mid)[#e.pos]\ #ipa(e.ipa)],
          zh(size: 9.4pt)[#e.zh],
          [#set par(leading: 0.5em)
           #text(size: 9.8pt)[#e.ex]\
           #text(size: 8pt, fill: mid)[#e.note]],
        )).flatten(),
      )
    ],
  )
  v(5mm)

  // sound check panel
  block(width: 100%, breakable: false, fill: cobalt-t, inset: (x: 5mm, y: 4mm))[
    #grid(columns: (w-idx, gut, 1fr), align: horizon,
      [
        #cap(sound.title, fill: cobalt, weight: "bold", size: 7pt) #h(1.4mm) #zh(size: 8.2pt, fill: mid)[#sound.title-zh]
        #v(1.8mm)
        #box(fill: ink, inset: (x: 2.4mm, y: 1.1mm), text(size: 7.6pt, weight: "bold", fill: white, tracking: 0.08em)[▶  TRACK #sound.track])
      ],
      [],
      grid(columns: (0.92fr, 1.18fr, 1.1fr), column-gutter: 4mm, align: horizon,
        ..sound.pair.map(p => grid(columns: (auto, 1fr), column-gutter: 2.6mm, align: horizon,
          text(size: 32pt, weight: "bold", fill: cobalt, font: "Libertinus Serif", tracking: -0.01em)[/#p.ipa/],
          [#text(weight: "bold", size: 10.4pt)[#p.word]\ #zh(size: 8pt, fill: mid)[#p.cue-zh]])),
        [
          #zh(size: 8.4pt)[#sound.prompt-zh]
          #v(0.4mm)
          #for n in (1, 2, 3) { grid(columns: (3.6mm, 1fr), align: bottom, text(size: 8pt, weight: "bold", fill: cobalt)[#n], block(height: 4.8mm, width: 100%, stroke: (bottom: 0.6pt + mid))) }
        ]))
  ]
  v(5mm)

  zones(
    [#index-label("Use it", "造个句")],
    [
      #zh(size: 9.6pt)[#words-page.task-zh]
      #write-lines(4, gap: 9mm)
    ],
  )
})

// ── 02 GRAMMAR ────────────────────────────────────────────────────────
#let timeline(w) = {
  let ax = 14.5mm
  let x1 = w * 0.22
  let x2 = w * 0.64
  box(width: w, height: 29mm, {
    // axis
    place(top + left, dy: ax - 0.8pt, line(length: w - 4mm, stroke: 2pt + ink))
    place(top + left, dx: w - 5mm, dy: ax - 2.2mm, polygon(fill: ink, stroke: none, (0mm, 0mm), (5mm, 2.2mm), (0mm, 4.4mm)))
    // span between the two events
    place(top + left, dx: x1, dy: ax - 5.2mm, block(width: x2 - x1, height: 2.6mm, fill: cobalt-t, stroke: (top: 1.4pt + cobalt)))
    place(top + left, dx: x1, dy: ax - 10.5mm, block(width: x2 - x1, align(center, cap("before", fill: cobalt, weight: "bold", size: 7pt))))
    // events
    place(top + left, dx: x1 - 2.6mm, dy: ax - 2.6mm, circle(radius: 2.6mm, fill: cobalt, stroke: none))
    place(top + left, dx: x2 - 2.6mm, dy: ax - 2.6mm, circle(radius: 2.6mm, fill: paper, stroke: 2pt + ink))
    place(top + left, dx: x1 - 24mm, dy: ax + 5.4mm, block(width: 48mm, align(center)[#text(weight: "bold", size: 10.4pt, fill: cobalt)[#grammar.timeline.earlier.label]\ #cap(grammar.timeline.earlier.when, size: 6.8pt)]))
    place(top + left, dx: x2 - 26mm, dy: ax + 5.4mm, block(width: 52mm, align(center)[#text(weight: "bold", size: 10.4pt)[#grammar.timeline.ref.label]\ #cap("reference point", size: 6.8pt)]))
    place(top + left, dx: w - 14mm, dy: ax + 5.4mm, cap("now", size: 6.8pt))
  })
}

#let page-grammar() = std-page({
  opener("02", lesson.title-en)
  zones(
    [
      #index-label("Grammar", "语法")
      #v(4.5mm)
      #cap("Form", fill: ink, weight: "bold", size: 6.8pt)
      #v(1mm)
      #block(width: 100%, fill: cobalt, inset: (x: 2.6mm, y: 3mm), text(size: 13pt, weight: "bold", fill: white, tracking: -0.01em)[had\ + p.p.])
      #v(1.4mm)
      #zh(size: 8.4pt, fill: mid)[#grammar.form-zh]
      #v(5mm)
      #cap("Signals", fill: ink, weight: "bold", size: 6.8pt)
      #v(1.6mm)
      #set text(size: 9.2pt, weight: "bold")
      #set par(leading: 0.74em)
      #for s in grammar.signals { [#highlight(fill: hilite, top-edge: "ascender", bottom-edge: "descender", extent: 0.8pt)[#s]\ ] }
      #v(6mm)
      #block(width: 100%, fill: hilite, inset: (x: 2.6mm, y: 2.6mm))[
        #set text(size: 8.6pt)
        #set par(leading: 0.58em, spacing: 0.5em)
        #cap(grammar.caution-title, fill: ink, weight: "bold", size: 6.8pt)
        #v(1.4mm)
        #strike(stroke: 1.1pt + ink)[#grammar.caution-wrong]
        #v(0.6mm)
        #text(weight: "bold")[→ #grammar.caution-right]
        #v(1.4mm)
        #zh(size: 8.2pt)[#grammar.caution-zh]
      ]
    ],
    [
      #text(size: 14.6pt, weight: "medium", tracking: -0.01em)[#grammar.rule-en]
      #v(2.4mm)
      #set par(leading: 0.7em)
      #zh(size: 9.8pt, fill: mid)[#grammar.rule-zh]
      #v(4mm)
      #cap("On the timeline · 时间线", fill: ink, weight: "bold", size: 6.8pt)
      #v(2mm)
      #timeline(w-main)
      #v(3.5mm)
      #cap("Same sentence, two meanings · 同一句话，两种意思", fill: ink, weight: "bold", size: 6.8pt)
      #v(2.2mm)
      #grid(columns: (1fr, 1fr), column-gutter: gut, inset: 3.4mm,
        grid.cell(stroke: 1.2pt + ink, [
          #cap(grammar.contrast.simple.tag, fill: ink, weight: "bold", size: 6.8pt)
          #v(1.6mm)
          #text(size: 10.4pt, weight: "medium")[#grammar.contrast.simple.en]
          #v(1.6mm)
          #zh(size: 8.8pt, fill: mid)[#grammar.contrast.simple.zh]
        ]),
        grid.cell(fill: cobalt, [
          #cap(grammar.contrast.perfect.tag, fill: white, weight: "bold", size: 6.8pt)
          #v(1.6mm)
          #text(size: 10.4pt, weight: "medium", fill: white)[#show strong: set text(fill: hilite); #grammar.contrast.perfect.en]
          #v(1.6mm)
          #zh(size: 8.8pt, fill: white.transparentize(8%))[#grammar.contrast.perfect.zh]
        ]))
    ],
  )
  v(3.5mm)
  block(width: 100%, below: 3mm)[
    #cap("Quick check", fill: ink, weight: "bold", size: 8pt) #h(1.6mm) #zh(size: 8.6pt, fill: mid)[小测]
    #v(1.6mm)
    #bar(h: 0.5pt, c: line-c)
  ]
  for (i, q) in grammar.check.enumerate() { mcq(i + 1, q.stem, q.choices, compact: true, cols: 4); v(3mm) }
  block(breakable: false)[
    #grid(columns: (7mm, 1fr), column-gutter: 2.5mm, align: horizon,
      num-tile(3),
      [#text(weight: "bold")[Fix the sentence.] #zh(size: 8.6pt, fill: mid)[改正错误]])
    #v(1.6mm)
    #pad(left: 9.5mm)[#grammar.fix.wrong #write-lines(1, gap: 7mm)]
  ]
})

// ── 03 READING ────────────────────────────────────────────────────────
#let page-reading(teacher: false) = std-page(edition: if teacher { "Teacher Edition" } else { "Student Edition" }, {
  pp-show.update(teacher)

  opener("03", reading.title)

  let passage = block(width: 100%, inset: (left: 4.2mm), stroke: (left: 2pt + cobalt))[
    #set text(size: 10.6pt)
    #set par(leading: if teacher { 0.8em } else { 0.86em }, spacing: if teacher { 1.1em } else { 1.55em })
    #for p in reading.paras { p; parbreak() }
  ]
  let questions = for (i, q) in reading.qs.enumerate() {
    mcq(i + 1, q.stem, q.choices, key: q.key, teacher: teacher, compact: teacher, cols: if teacher { 4 } else { 2 })
    v(1.6mm)
    if teacher {
      pad(left: 9.5mm, block(width: 100%, fill: cobalt-t, inset: (x: 3mm, y: 1.9mm),
        grid(columns: (1fr, 1fr, 1fr), column-gutter: 4mm,
          note-col("Answer · " + ("A", "B", "C", "D").at(q.key), q.why, fill: cobalt),
          note-col("Tempting wrong choice", q.trap),
          note-col("Repair move", q.repair))))
      v(3mm)
    } else {
      pad(left: 9.5mm, grid(columns: (auto, 1fr), column-gutter: 2.4mm, align: bottom,
        cap("Evidence 依据", size: 6.6pt),
        block(height: 3.4mm, width: 100%, stroke: (bottom: 0.5pt + line-c))))
      v(5.2mm)
    }
  }

  if teacher {
    // teacher edition: no index zone, the whole 12 columns carry the page
    block(below: 3mm)[#cap("Reading", fill: ink, weight: "bold", size: 8pt) #h(1.6mm) #zh(size: 8.6pt, fill: mid)[阅读 · 教师版]]
    passage
    v(4mm)
    questions
  } else {
    zones(
      [
        #index-label("Reading", "阅读", meta: [#reading.words words · 8 min])
        #v(4.5mm)
        #hilite-box("Strategy", zh(size: 8.6pt, weight: "medium")[圈出时间词，它们告诉你事情发生的先后。])
        #v(5mm)
        #cap("Words", fill: ink, weight: "bold", size: 6.8pt)
        #v(1.6mm)
        #for g in vocab {
          block(width: 100%, below: 2.4mm, breakable: false)[
            #set par(leading: 0.5em, spacing: 0.3em)
            #text(size: 9.2pt, weight: "bold")[#g.word] #text(size: 7.6pt, fill: mid)[#g.pos]\
            #ipa(g.ipa) #h(0.8mm) #zh(size: 8pt, fill: mid)[#g.zh]
          ]
        }
      ],
      [#passage #v(4.5mm) #questions],
    )
  }
})

// ── 04 CLOZE ──────────────────────────────────────────────────────────
#let blank(n) = box(fill: cobalt-t, stroke: (bottom: 1.4pt + cobalt), width: 13mm, inset: (y: 0.7mm), baseline: 0.6mm,
  align(center, text(size: 8.4pt, weight: "bold", fill: cobalt)[#n]))

#let cloze-table(teacher: false) = table(
  columns: (8mm, 1fr, 1fr, 1fr, 1fr),
  stroke: (x: none, y: 0.5pt + line-c), inset: (x: 1.6mm, y: 4.8mm), align: horizon + left,
  ..cloze.rows.map(r => (
    num-tile(r.n, size: 6.4mm),
    ..r.choices.enumerate().map(((i, c)) => {
      let hit = teacher and r.key == i
      grid(columns: (6mm, 1fr), column-gutter: 2mm, align: horizon,
        letter-tile(i, filled: hit, size: 5.8mm),
        text(size: 11pt, weight: if hit { "bold" } else { "regular" }, fill: if hit { cobalt } else { ink })[#c])
    }),
  )).flatten(),
)

#let page-cloze() = std-page({
  opener("04", cloze.heading)
  zones(
    [
      #index-label("Cloze", "完形填空")
      #v(4.5mm)
      #zh(size: 8.8pt, fill: mid)[#cloze.direction-zh]
      #v(5mm)
      #hilite-box("Strategy", zh(size: 8.6pt, weight: "medium")[先看空格前后的时间词，再判断动词形式。])
    ],
    [
      #block(width: 100%, inset: (left: 4.2mm), stroke: (left: 2pt + cobalt))[
        #set text(size: 12.4pt)
        #set par(leading: 1.2em)
        #fill-blanks(cloze.passage, blank)
      ]
    ],
  )
  v(8mm)
  zones(
    [#index-label("Options", "选项")],
    [#cloze-table()],
  )
  v(1fr)
  zones(
    [#index-label("Your answers", "我的答案")],
    [
      #grid(columns: (1fr,) * 5, column-gutter: 3mm,
        ..range(1, 6).map(n => block(width: 100%, fill: cobalt-t, inset: (x: 3mm, y: 2.6mm),
          grid(columns: (auto, 1fr), column-gutter: 2.4mm, align: horizon,
            text(size: 9pt, weight: "bold", fill: cobalt)[#n],
            block(height: 6.4mm, width: 100%, fill: white, stroke: 0.6pt + ink)))))
    ],
  )
})

// ── 05 WRITING ────────────────────────────────────────────────────────
#let page-writing() = std-page({
  opener("05", writing.heading)
  zones(
    [
      #index-label("Writing", "写作")
      #v(4.5mm)
      #cap("Before you hand in", fill: ink, weight: "bold", size: 6.8pt)
      #v(2mm)
      #set par(leading: 0.6em, spacing: 2mm)
      #for c in writing.checklist {
        grid(columns: (4.6mm, 1fr), column-gutter: 0.6mm, align: top, check-box(), text(size: 8.4pt)[#c])
        v(2mm)
      }
    ],
    [
      #grid(columns: (7mm, 1fr), column-gutter: 2.5mm, align: horizon, num-tile("A", fill: cobalt), [#text(weight: "bold", size: 11pt)[Combine] #zh(size: 9pt, fill: mid)[合并句子]])
      #v(3mm)
      #for (i, c) in writing.combine.enumerate() {
        block(width: 100%, breakable: false)[
          #grid(columns: (5mm, 1fr), column-gutter: 1mm,
            text(weight: "bold", fill: cobalt)[#(i + 1)],
            [
              #c.a #h(1mm) #c.b \
              #v(1.4mm)
              #box(stroke: 1pt + cobalt, inset: (x: 1.8mm, y: 0.8mm), text(size: 7.4pt, weight: "bold", fill: cobalt, tracking: 0.08em)[USE: #upper(c.use)])
              #write-lines(2, gap: 8.4mm)
            ])
        ]
        v(4mm)
      }
      #v(2mm)
      #grid(columns: (7mm, 1fr), column-gutter: 2.5mm, align: horizon, num-tile("B", fill: cobalt), [#text(weight: "bold", size: 11pt)[Continue the story] #zh(size: 9pt, fill: mid)[续写]])
      #v(3mm)
      #text(weight: "medium")[#writing.story-prompt]\
      #zh(size: 9pt, fill: mid)[#writing.story-prompt-zh]
      #write-lines(11, gap: 8.8mm)
    ],
  )
})
