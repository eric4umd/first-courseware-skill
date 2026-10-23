// shared-flat.typ — flat geometric lighthouse used by the colour-based directions.
// Pure vector shapes; every colour is a parameter so each direction owns its palette.

#let lighthouse-flat(
  w,
  tower: white, band: blue, roof: black, glass: yellow, base: black,
  stroke-c: none, stroke-w: 0pt,
  beam: none, ground: none,
) = {
  let u = w / 100
  let st = if stroke-c == none { none } else { stroke-w + stroke-c }
  let lx(y) = 36 + (42 - 36) * (118 - y) / (118 - 52)
  let rx(y) = 64 - (64 - 58) * (118 - y) / (118 - 52)
  let band-poly(y1, y2, fill) = place(top + left, polygon(
    fill: fill, stroke: none,
    (lx(y2) * u, y2 * u), (rx(y2) * u, y2 * u), (rx(y1) * u, y1 * u), (lx(y1) * u, y1 * u)))
  box(width: w, height: 128 * u, {
    if beam != none {
      place(top + left, polygon(fill: beam, stroke: none, (49 * u, 40 * u), (-60 * u, 24 * u), (-60 * u, 56 * u)))
      place(top + left, polygon(fill: beam, stroke: none, (51 * u, 40 * u), (160 * u, 24 * u), (160 * u, 56 * u)))
    }
    if ground != none {
      place(top + left, dx: 18 * u, dy: 118 * u, rect(width: 64 * u, height: 8 * u, fill: ground, stroke: none, radius: (top: 4 * u)))
    }
    // tower
    place(top + left, polygon(fill: tower, stroke: st,
      (36 * u, 118 * u), (64 * u, 118 * u), (58 * u, 52 * u), (42 * u, 52 * u)))
    band-poly(64, 78, band)
    band-poly(90, 104, band)
    // door
    place(top + left, dx: 46 * u, dy: 106 * u, rect(width: 8 * u, height: 12 * u, fill: roof, stroke: none, radius: (top: 4 * u)))
    // gallery
    place(top + left, dx: 37.5 * u, dy: 47 * u, rect(width: 25 * u, height: 5 * u, fill: base, stroke: none))
    // lantern
    place(top + left, dx: 43.5 * u, dy: 31 * u, rect(width: 13 * u, height: 16 * u, fill: glass, stroke: none))
    place(top + left, dx: 49.5 * u, dy: 31 * u, rect(width: 1 * u, height: 16 * u, fill: roof.transparentize(30%), stroke: none))
    // roof
    place(top + left, polygon(fill: roof, stroke: none, (41 * u, 31 * u), (59 * u, 31 * u), (50 * u, 19 * u)))
    place(top + left, dx: 48.6 * u, dy: 14 * u, circle(radius: 1.6 * u, fill: roof, stroke: none))
  })
}
