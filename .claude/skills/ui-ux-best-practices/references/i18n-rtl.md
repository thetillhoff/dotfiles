# Internationalization & RTL

Designing for other languages is a layout and content decision made up front, not
a translation step bolted on. Retrofitting i18n is expensive; the rules below are
cheap if applied from the start.

## Layout must flex to text length

- **Text expands ~30-40% from English** (German, Finnish, Russian run long; some
  run much longer). **Never fix a width/height to the English string** - buttons,
  tabs, labels, nav items must grow. Test with pseudo-localization (pad every
  string ~40% and bracket it) to catch clipping and truncation early.
- Single words can be very long (German compounds) - allow wrapping, avoid
  `white-space: nowrap` on translatable text, consider `hyphens: auto`.
- Don't build sentences by concatenating translated fragments - grammar,
  word order, and pluralization differ per language. Use full templated strings
  with named placeholders and a plural-rules library (ICU MessageFormat / CLDR).

## RTL (Arabic, Hebrew, Persian, Urdu)

- **Set `dir="rtl"` on `<html>`** (and `lang`); the whole layout mirrors -
  reading order, float/flex direction, text alignment, list markers.
- **Use logical properties** (`margin-inline-start`, `padding-block`,
  `inset-inline-end`, `text-align: start`) instead of physical
  `left`/`right`/`margin-left` - they flip automatically with `dir`. This is the
  single biggest lever for RTL support and the main reason logical properties
  exist (see web-implementation.md).
- **Mirror directional icons** (back/forward arrows, chevrons, progress) - but do
  **not** mirror logos, media playback controls, clocks, or icons of physical
  objects. Use `transform: scaleX(-1)` scoped, or `[dir=rtl]` variants.
- Numbers and inline LTR runs (code, URLs, phone numbers) inside RTL text need
  bidi isolation (`<bdi>`, or `unicode-bidi: isolate`) to render correctly.
- Test with a real RTL locale, not just `dir=rtl` on English - the two reveal
  different bugs.

## Locale-aware formatting

- **Never hand-format dates, numbers, currency, or times** - use
  `Intl.DateTimeFormat` / `Intl.NumberFormat` (or the platform equivalent).
  Decimal/thousands separators, currency symbol position, date order (D/M/Y vs
  M/D/Y), 12h/24h, first day of week, and measurement units all vary by locale.
- Store timestamps in UTC; format to the user's timezone at display.
- Sort/collate with locale rules (`Intl.Collator`), not byte order.

## Type & content

- **Font must cover the target scripts** - CJK, Arabic, Devanagari, Cyrillic,
  Greek need glyph coverage and correct line-height; a Latin-only font falls back
  to tofu (□) or an ugly system fallback. Verify the stack per language.
- CJK has no spaces between words and different line-breaking rules; Arabic is
  cursive/contextual - don't letter-space or force-uppercase it.
- Keep text out of images (untranslatable, not selectable); if unavoidable,
  provide localized alternates.
- Provide a clear, persistent language switcher; remember the choice; set `lang`
  correctly so screen readers pronounce content in the right voice.
