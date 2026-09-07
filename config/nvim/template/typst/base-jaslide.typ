#import "@preview/typstage:0.1.1": *

#show: presentation.with(
  title: [Title{{_cursor_}}],
  subtitle: [Subtitle],
  author: [Authors],
  date: datetime.today(),
  transition: "slide",
)

#import "@preview/cjk-spacer:0.2.1": cjk-spacer
#show: cjk-spacer

#import "@preview/pinit:0.2.2": *

#import "@preview/cetz:0.5.2"
#import "@preview/fletcher:0.5.8" as fletcher: edge, node

#set text(
  lang: "ja",
  font: ("Hiragino Kaku Gothic ProN", "Hiragino Mincho ProN"),
)
