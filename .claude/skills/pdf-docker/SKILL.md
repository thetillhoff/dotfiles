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
  -V header-includes='\usepackage{atbegshi}' \
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

On Linux (no system Arial), get the real ArialMT from Debian's
`ttf-mscorefonts-installer`. Do not use the `arial.ttf` in Wine/Proton
prefixes - it is a look-alike that embeds as `Arial`, not `ArialMT`:

```sh
mkdir -p ~/.claude/fonts && docker run --rm -v "$HOME/.claude/fonts:/out:z" debian:stable-slim sh -c '
sed -i "s/Components: main/Components: main contrib/" /etc/apt/sources.list.d/debian.sources
apt-get -qq update && echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get -qq install -y ttf-mscorefonts-installer
cd /usr/share/fonts/truetype/msttcorefonts
cp Arial.ttf /out/; cp Arial_Bold.ttf "/out/Arial Bold.ttf"; cp Arial_Italic.ttf "/out/Arial Italic.ttf"; cp Arial_Bold_Italic.ttf "/out/Arial Bold Italic.ttf"'
```

On SELinux hosts, add `:z` to the bind mounts in the pandoc command too.

Then address the faces by filename via `Path=`, as in the command above —
filenames sidestep fontconfig entirely. Arial suits German business
correspondence and matches what most property managers and insurers send. For a
serif letter, copy `Times New Roman*.ttf` instead. Embedding a system font in
your own document is ordinary use; don't redistribute the font files themselves.

## German business letter layout (DIN 5008)

Use DIN 5008 Form B. Its address field sits in the window of both DL envelopes
(A4 folded in three) and C4 window envelopes (A4 unfolded):

| Element | Position from the top-left sheet corner |
| --- | --- |
| Address field | x 20 mm, y 45-90 mm, 85 mm wide |
| Return-address line | bottom of the note zone, baseline about 60.5 mm, small type |
| Recipient address | text at x 25 mm, from y 62.7 mm |
| Fold marks | y 105 mm and 210 mm |
| Punch mark | y 148.5 mm |
| Subject / body start | about y 98.5 mm |

Do not position these blocks with `\vspace` in the text flow. Pin them to the
page with `atbegshi` (in the image; `eso-pic`, `textpos` and `scrlttr2` are
not). Add `-V header-includes='\usepackage{atbegshi}'` to the command, and start
the Markdown with a raw `{=latex}` fence:

````markdown
```{=latex}
% DIN 5008 Form B: fits DL (folded in three) and C4 window envelopes.
\AtBeginShipoutNext{\AtBeginShipoutUpperLeft{\setlength{\unitlength}{1mm}%
\put(140,-20){\begin{minipage}[t]{50mm}\vspace{0pt}
Sender Name\\
Street 1\\
12345 City
\end{minipage}}%
\put(25,-60.5){\makebox(0,0)[bl]{\scriptsize Sender Name $\cdot$ Street 1 $\cdot$ 12345 City}}%
\put(25,-62.7){\begin{minipage}[t]{75mm}\vspace{0pt}
Recipient GmbH\\
Street 2\\
54321 City
\end{minipage}}%
\put(190,-90){\makebox(0,0)[br]{City, 08.10.2026}}%
}}
\vspace*{70.5mm}
```
````

- `\AtBeginShipoutNext` draws on page 1 only.
- Fold and punch marks are optional, and the user does not want them. To add them, use `\put(3.5,-105){\line(1,0){5}}` (repeat at 148.5 and 210).
- `\vspace{0pt}` as the first item of a `[t]` minipage puts the top of the block,
  not the first baseline, at the `\put` point.
- `\vspace*{70.5mm}` moves the body start to about 98.5 mm, with `top=20mm` and
  11pt. Change it if the margins or the font size change.
- Measure the result instead of trusting the numbers. In the image, `pdfplumber`
  in a `python:3-slim` container prints the top of each text line and each rule in
  mm (`value * 25.4 / 72`).
- Keep one font size for the letter, except the return-address line. A street
  line is about 34 mm wide at Arial 11pt, so a 50 mm sender box is enough.
- The fenced `{=latex}` block passes any LaTeX through. A raw block without the
  fence must start with `\begin{...}`; see the caveat below.

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

Put a `YYYY-MM-DD` date in the file name, so alphabetical order is date
order. Use the position of the date (start or end) that other files in the
folder use. If the folder has no such scheme, ask the user. Keep the rest of
the name the same for each version of a document: a new version changes only
the date.

Keep a number and its unit on one line with an escaped space (`+64\ %`,
`25\ EUR`). Pandoc turns it into a non-breaking space; a plain space lets
LaTeX break between them.

Business letters legitimately violate `markdownlint` MD041 (first line not a
heading) and MD036 (bold where a heading would go) — the sender address and the
subject line. Don't restructure a letter to satisfy the linter. Table rows also
trip MD013; run with `--disable MD013`.

In letter body text, reserve bold for headings. Bolding amounts or phrases mid
-sentence reads as shouting in correspondence, even where it aids scanning in a
report.
