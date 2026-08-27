---
name: pdf-docker
description: >
  Render a Markdown file to a print-ready PDF using Docker pandoc/latex, with no
  Python, LaTeX, or pandoc installed on the host. Use this whenever the user wants
  a PDF produced from Markdown or plain text — a letter, report, invoice, contract,
  handout, spec, or any document they intend to print, sign, or post. Covers German
  business-letter layout (DIN 5008 header, right-aligned sender and date, signature
  block) and embedding a real font instead of the LaTeX default. Triggers on
  "make a PDF", "as PDF", "PDF daraus", "PDF erstellen", "print-ready", "druckfertig",
  "Briefkopf", or when the user finishes a Markdown document and asks to send or print
  it. Also use it before hand-rolling a reportlab/weasyprint script — that
  experimentation is exactly what this skill exists to skip. For reading, merging,
  splitting, or filling EXISTING PDFs use the `pdf` skill instead; this one only
  creates them.
---

# Markdown to PDF via Docker

The host has no pandoc, LaTeX, wkhtmltopdf, or typst, and `CLAUDE.md` forbids
installing Python packages on the host. Docker is the only route. Use the
`pandoc/latex` image — one command, no glue code.

## The command

```sh
cd "<dir containing the .md>" && docker run --rm --platform linux/amd64 \
  -v "$PWD:/data" -v "$HOME/.claude/fonts:/hostfonts:ro" -w /data \
  pandoc/latex:latest \
  -f markdown+hard_line_breaks-smart \
  --pdf-engine=xelatex \
  -V geometry:a4paper \
  -V geometry:left=25mm,right=20mm,top=20mm,bottom=25mm \
  -V fontsize=11pt \
  -V lang=de \
  -V mainfont="Arial.ttf" \
  -V mainfontoptions="Path=/hostfonts/,BoldFont=Arial Bold.ttf,ItalicFont=Arial Italic.ttf,BoldItalicFont=Arial Bold Italic.ttf" \
  -o output.pdf input.md
```

Read the PDF back and look at the rendered pages before reporting done. Pandoc
fails soft: a missing flag or an unrecognised raw block yields a valid PDF with
wrong layout, and nothing on stderr says so.

## Why each flag

| Flag | Reason |
| --- | --- |
| `--platform linux/amd64` | `pandoc/latex` publishes no arm64 manifest. Without this, Apple Silicon fails with `no matching manifest for linux/arm64/v8`. Emulation is slow but fine for one document. |
| `+hard_line_breaks` | Markdown collapses single newlines into spaces, which destroys address blocks and any stacked short lines. See the raw-LaTeX caveat below — this flag is what makes it necessary. |
| `-smart` | Disables curly quotes. Pandoc's smart quotes ignore `lang`, so a German document otherwise gets English `“ ”`. Straight quotes are neutral; for real German `„ "`, type them into the Markdown directly. |
| `--pdf-engine=xelatex` | Unicode support. The default `pdflatex` chokes on umlauts and `§`. |
| `-V lang=de` | German hyphenation. Drop or change for other languages. |
| `-V mainfont` + `mainfontoptions` | See Fonts below. Omit both for LaTeX's Latin Modern, which visibly reads as "a LaTeX document". |

## Fonts

The image ships only Latin Modern — no TeX Gyre, no Liberation, and `fc-list` is
absent. `-V mainfont="TeX Gyre Heros"` fails with a fontspec "font not installed"
error.

Docker Desktop refuses to mount `/System/Library/Fonts`, so copy the family you
want into a directory Docker may share, once:

```sh
mkdir -p ~/.claude/fonts && cp /System/Library/Fonts/Supplemental/Arial*.ttf ~/.claude/fonts/
```

Then address the faces by filename via `Path=`, as in the command above —
filenames sidestep fontconfig entirely. Arial suits German business
correspondence and matches what most property managers and insurers send. For a
serif letter, copy `Times New Roman*.ttf` instead. Embedding a system font in
your own document is ordinary use; don't redistribute the font files themselves.

## German business letter layout (DIN 5008)

Markdown alone cannot right-align a block or position the address field for a
window envelope. Embed raw LaTeX for the header and signature, keep the body in
Markdown:

```latex
\begin{flushright}
\begin{minipage}[t]{75mm}
Sender Name\\
Street 1\\
12345 City
\end{minipage}
\end{flushright}

\vspace{9mm}

\begin{minipage}[t]{85mm}
Recipient GmbH\\
Department\\
Street 2\\
54321 City
\end{minipage}

\vspace{10mm}

\begin{flushright}
City, 23.08.2026
\end{flushright}
```

`flushright` + `minipage` is the idiom for "block sits right, text inside stays
left-aligned".

**Horizontal position is set by the minipage width, not by the alignment.** A
right-aligned block starts at `sheet width − right margin − minipage width`, so
compute the width backwards from where the block should start. On A4 with
`right=20mm`: 75mm starts at 115mm (≈55 % across, reads as centred), 50mm starts
at 140mm (right third), 35mm starts at 155mm (right quarter).

Keep one font size throughout the letter and choose the width so the longest line
still fits — a street line is roughly 34mm at Arial 11pt, so 50mm is comfortable.
Shrinking the block until it needs `\small` trades a uniform document for a few
millimetres of position; widen the box instead.

**Vertical position** is set by the `\vspace` after the sender block. Measure it
rather than deriving it: render once, note where the recipient lands, then adjust
the `\vspace` by the difference. With `top=20mm` and a three-line 11pt sender
block, the offset before the `\vspace` is about 42mm, so `\vspace{33mm}` puts the
first recipient line near 75mm.

Target 75mm from the sheet edge with a left margin near 22.5mm. That is what
Deutsche Post's BriefKlick template uses, and matching a carrier's own template
is safer than reasoning about envelope windows. If the user has a sample from
their mail service, measure that page and match it — a couple of millimetres in
either direction is fine.

Signature block, with room to actually sign:

```latex
\vspace{6mm}

Mit freundlichen Grüßen

\vspace{22mm}

\begin{minipage}[t]{65mm}
\rule{65mm}{0.4pt}\\
Name
\end{minipage}
```

### Headings in a letter

Markdown `##` becomes `\subsection`, which LaTeX sets in a larger face. A letter
should read at one type size throughout, so write section headings as bold
paragraphs (`**1. Subject**`) rather than Markdown headings. Bold is the one
place emphasis belongs in correspondence; a letter has no need for the PDF
outline that real headings would produce.

Vertical whitespace then has to be placed by hand, since `\subsection`'s own
spacing is gone. `\vspace{5mm}` before the salutation and `\vspace{6mm}` before
the closing are good starting values.

### The raw-LaTeX caveat

**A raw LaTeX block must start with `\begin{...}`.** Pandoc only recognises raw
LaTeX when the block opens with an environment. Anything starting with a bare
macro — `\noindent Text\\`, `\noindent\rule{...}\\` — is parsed as a Markdown
paragraph instead, and because `hard_line_breaks` is on, every `\\` renders as a
literal backslash in the output. Wrapping the same content in a `minipage` fixes
it. This is the single most likely thing to go wrong; it is also invisible unless
you look at the rendered page.

## Notes

`pandoc: Ticker: poll failed: Interrupted system call` on stderr is an emulation
artefact, not a failure. Check for the output file rather than trusting the exit
path, and pipe through `grep -v Ticker` to keep the log readable.

Give the Markdown no YAML title block unless you want a title page; a letter or
memo shouldn't have one.

Re-running the command overwrites the PDF, so iterating is cheap.

Business letters legitimately violate `markdownlint` MD041 (first line not a
heading) and MD036 (bold where a heading would go) — the sender address and the
subject line. Don't restructure a letter to satisfy the linter. Table rows also
trip MD013; run with `--disable MD013`.

In letter body text, reserve bold for headings. Bolding amounts or phrases mid
-sentence reads as shouting in correspondence, even where it aids scanning in a
report.
