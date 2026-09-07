#import "@preview/typstage:0.1.1": *

#import "@preview/cjk-spacer:0.2.1": cjk-spacer
#show: cjk-spacer

#set text(
  lang: "ja",
  font: ("Hiragino Kaku Gothic ProN", "Hiragino Mincho ProN"),
)

#show: presentation.with(
  title: [Title{{_cursor_}}],
  subtitle: [Subtitle],
  author: [Authors],
  date: datetime.today(),
  transition: "slide",
)

#import "@preview/cetz:0.5.2"
#import "@preview/fletcher:0.5.9" as fletcher: edge, node
