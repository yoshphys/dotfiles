#import "@preview/js:0.1.3": *
#import "@preview/cjk-spacer:0.2.1": cjk-spacer

#show: cjk-spacer

#show: js.with(
  lang: "ja",
  seriffont: "New Computer Modern",
  seriffont-cjk: "Hiragino Mincho ProN",
  sansfont: "Helvetica",
  sansfont-cjk: "Hiragino Kaku Gothic ProN",
  paper: "a4",
  fontsize: 10pt,
  baselineskip: auto,
  textwidth: auto,
  lines-per-page: auto,
  book: false, // or true
  cols: 1, // 1, 2, 3, ...
  non-cjk: regex("[\u0000-\u2023]"), // or "latin-in-cjk" or any regex
  cjkheight: 0.88, // height of CJK in em
)

#maketitle(
  title: "{{_cursor_}}",
  authors: "",
  abstract: [],
)
