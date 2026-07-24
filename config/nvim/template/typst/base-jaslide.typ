#import "@preview/touying:0.7.4": *
#import themes.university: *

#import "@preview/numbly:0.1.0": numbly

#import "@preview/cjk-spacer:0.2.1": cjk-spacer
#show: cjk-spacer

#import "@preview/pinit:0.2.2": *

#import "@preview/cetz:0.5.2"
#import "@preview/fletcher:0.5.8" as fletcher: node, edge

// cetz and fletcher bindings for touying
#let cetz-canvas = touying-reduce.with(cetz) // new syntax for packages that expose their name
#let fletcher-diagram = touying-reduce.with(fletcher)

#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.10": *

#import "@preview/theorion:0.6.0": *
#import cosmos.clouds: *
#show: show-theorion

#show: university-theme.with(
  aspect-ratio: "16-9",
  config-common(
    frozen-counters: (theorem-counter,),  // freeze theorem counter for animation
    preamble: {
      codly(languages: codly-languages)
    }
  ),
  config-info(
    title: [Title{{_cursor_}}],
    subtitle: [Subtitle],
    author: [Authors],
    date: datetime.today(),
    institution: [Institution],
    contact: [contact\@mail.com],
    logo: emoji.school,
  ),
)

#set text(
  lang: "ja",
  font: ("Hiragino Kaku Gothic ProN", "Hiragino Mincho ProN"),
)

#set heading(numbering: numbly("{1}.", default: "1.1"))

#title-slide()
