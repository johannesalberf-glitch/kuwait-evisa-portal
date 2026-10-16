# Kuwait eVisa status inquiry · single-file prototype

A dual-language (English / Arabic) demonstration of a visa-status inquiry page and a
staff console, built as one `index.html` with Tailwind CSS and vanilla JavaScript, plus
an optional Supabase table for cloud persistence.

**This is a prototype for layout review and flow testing.** It is not connected to any
government system. Every emblem, seal, barcode, QR block and MRZ line is a labelled
placeholder, the download and print actions exist to check the printed look, and no real
applicant data belongs in it.

## Files

| File | Purpose |
| --- | --- |
| `index.html` | The whole application: markup, styles, storage, document renderer, admin console. |
| `supabase-schema.sql` | Creates the `kuwait_visas` table with indexes, an `updated_at` trigger, row level security and demo policies. |

## Run it

Open `index.html` in a browser and it works immediately, in local mode, from a plain
`file://` path. Safari refuses `localStorage` on `file://` pages, so serve the folder over
HTTP if records need to survive a reload there; everywhere else the app falls back to
in-memory storage and says so when a save cannot be kept.

For cloud mode and to mirror real hosting, serve the folder over HTTP:

```bash
cd "kuwati e visa"
python3 -m http.server 8000
# then open http://localhost:8000/index.html
```

## Two things to try first

1. **Check a reference.** The inquiry card accepts a six-character reference. Type
   `123456` or press *Use sample reference 123456* to see the electronic visa document.
2. **Open the staff console.** Navigate to `#admin` (or use the *Staff console* tab) and
   unlock it with the demo passcode `admin2026`. From there you can create, edit and
   delete records, and copy a share link for any of them.

## Links between people

Every document has a **Copy share link** action that produces:

```
https://your-host/index.html?code=XXXXXX
```

Opening that link verifies the reference automatically. `?visa=XXXXXX` works the same
way, so the link survives whatever a chat app does with the query string. When the
clipboard is blocked, the app falls back to a panel with the link already selected,
which is the path that works inside restricted in-app browsers.

## Storage: local by default, Supabase when configured

The status badge in the console says which mode is live.

* **Local demo store** (default) keeps records in this browser's `localStorage` under the
  key `kw_visas_demo_v1`. A single sample record (`123456`, clearly named
  `SAMPLE APPLICANT NAME`) is seeded once so a fresh clone has something to verify.
* **Supabase cloud store** is the live mode on the deployed site: the two constants at the
  top of the script in `index.html` point at the `kuwait` project, where
  `supabase-schema.sql` has already been run, so the `kuwait_visas` table exists and every
  phone that opens a share link reads the same rows. To move the app to a different
  project, run that SQL file in the new project's SQL editor and swap the two constants.
  Either key format works there: the publishable key, or the legacy anon JWT.

  Cloud mode needs an `http` or `https` origin: a `file://` page is blocked from calling
  the API, so it stays in local mode there. If the connection fails, the console shows
  the reason and quietly keeps working locally.

The shipped policies allow anyone holding the anon key to read and write. That matches
the demo brief and it is exactly why the table must stay free of real personal data.
Before any real use, put writes behind Supabase Auth or an Edge Function and leave only
a read-by-reference policy public.

## What the console records

Reference (six characters, with a *Generate random six-digit code* action), full name in
English and Arabic, passport number, nationality, sex, date of birth, profession, visa
type, issue date, validity preset (30/60/90/180/365 days) with an editable expiry date,
and a photograph, either uploaded from the device or given as an image URL.

Nationality, profession and visa type each have a preset list that fills the English and
Arabic fields, and every filled value stays editable, so an unlisted nationality or
profession is just typed in. Professions carry a feminine Arabic form that follows the
sex field. Missing values print as `-` rather than being invented.

### Photographs

*Upload image* takes a JPG, PNG or WebP from the device, draws it onto a canvas, keeps it
at 720 px on the longest edge as a JPEG and stores that picture inside the record's
`photo_url` field. Keeping the picture in the record means a share link carries the face
with it, and the PNG export never runs into a cross-origin block. Pasting an image URL
still works for pictures that already live online. Leaving the field empty keeps the
placeholder portrait. A record with a photo is roughly 40 to 150 KB, fine for a demo table
but worth knowing before adding hundreds of rows.

Drafts are kept in `localStorage` (`kw_visa_draft_v1`) while a form is half finished, and
the console remembers the unlocked session for 12 hours (`kw_admin_session_v1`).

## Notes on the document

* The English/Arabic pairs, the MRZ-style lines, the barcode and the pseudo-QR block are
  drawn from the record, in the browser, on canvases. The QR block is not a real QR code
  and neither block carries a credential; both are labelled on the document face.
* The reference code is also the serial (`KW-<year>-<code>`) and the barcode's
  human-readable text.
* Expiry is live: a record past its expiry date shows a red strip reading `Expired`,
  with the Arabic line `حالة التأشيرة: منتهية الصلاحية`, instead of the green `Valid` one.
* **Download image** renders the document face through html2canvas and saves a PNG.
  **Print or save as PDF** uses the print stylesheet, which prints only the document.
  Both need the page to be visible: an action fired while the document is off screen
  reports that instead of exporting a blank image.

## Browser notes

* Measured layout widths: 360, 390, 768 and 1007 px. No horizontal scrolling at any of
  them, with the register table swapping to stacked cards below 768.
* Inputs stay at 16px or larger so mobile Safari does not zoom on focus, and the shell
  uses `100dvh` with a `vh` fallback for in-app browsers.
* Clipboard writes fall back to `document.execCommand('copy')`, then to a visible link
  panel, because Telegram's webview and some iOS versions refuse the modern API.
* The console passcode check happens in the browser and is readable in the page source.
  It is a demo gate, not authentication, and the console says so on the gate itself.

## Testing hooks

`window.KW` is exposed for scripted checks:

| Hook | Does |
| --- | --- |
| `KW.verify('123456')` | Runs a lookup exactly like the form does, and returns when the result is on screen. |
| `KW.capture()` | Returns the html2canvas element for the visible document, or throws with a readable reason. |
| `KW.refresh()` | Reloads the register list from the active store. |
| `KW.shareLinkFor('123456')` | Returns the share URL for a reference. |
| `KW.copyText('...')` | Resolves `true` when the text reached the clipboard. |
| `KW.state` | `{ mode, records, record, editingId }`. |

To start clean, clear these `localStorage` keys: `kw_visas_demo_v1`,
`kw_visas_demo_seeded_v1`, `kw_visa_draft_v1`, `kw_admin_session_v1`.
