# Bundled fonts (invoice PDF)

Used only by the invoice PDF in `lib/screens/invoice_view_screen.dart`
(`_pdfTheme()`). They are declared under `flutter: assets:` rather than
`fonts:` because they are loaded through `rootBundle` and handed to
`pw.Font.ttf()`; the Flutter UI itself does not use them.

| File | Role |
| --- | --- |
| `NotoSans-Regular.ttf` / `NotoSans-Bold.ttf` | base / bold — Latin, digits, punctuation, currency |
| `NotoNaskhArabic-Regular.ttf` / `NotoNaskhArabic-Bold.ttf` | `fontFallback` — Arabic |

## Why two families

The `pdf` package defaults to Helvetica, a Type1 font with no Unicode support,
so Arabic rendered as empty boxes.

Noto Naskh cannot just replace it: this cut is Arabic-only and covers just
15 of the 95 printable ASCII characters and none of the Latin punctuation, so
promoting it to the base font breaks the English labels and the numbers
instead. Noto Sans carries Latin, Noto Naskh is the Arabic fallback; together
they leave no gaps. `test/invoice_pdf_font_test.dart` locks that down.

Source: Google Noto Fonts. Licence: SIL Open Font License 1.1 —
https://scripts.sil.org/OFL
