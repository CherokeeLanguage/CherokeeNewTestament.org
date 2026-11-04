# AGENTS.md

Guidance for AI agents working in this repo. The agent governance layer
(floor, skills) lives in `.opencode/` — gitignored here and a separate git
repo; its floor is auto-injected for OpenCode sessions. The issue store is
`.issues/` at the repo root (a worktree of this repo on the `issues-data`
branch).

## What this is

Source for <https://cherokeenewtestament.org> — an inter-linear Cherokee New
Testament reader built with [Zola](https://www.getzola.org/) and the vendored
`themes/Zulma` theme (in-tree, not a submodule). Chapter pages are raw HTML
tables inside Markdown: each verse is its own table — a row with the
verse-scan image (`<book><chapter><verse>.png`, e.g. `070101.png`) followed by
rows for English / Cherokee syllabary / phonetic lines — with page scans
(`<book>0000.png`, `<book><chapter>00.png`) above.

## Build

- Build: `zola build` → `public/` (gitignored). Dev server: `zola serve`.
- **`zola build` fails with the installed Zola 0.23.6** (verified 2026-11-04):
  `config.toml` line 3 `highlight_code = true` is rejected as an unknown
  field. The site targets a 2020-era Zola and no version is pinned anywhere;
  current Zola moved highlighting config under `[markdown]`
  (`[markdown.highlighting]`, and pre-0.22 CSS-class-only output is gone).
  Migrating `config.toml` is a deliberate change, not a drive-by fix.
- No CI build or test exists. The only GitHub workflow is CodeQL, which
  self-warns it found no supported languages — don't expect CI validation.

## Deploy — manual and machine-gated

- `./deploy.sh` rebuilds and rsyncs `public/` to production, but exits on any
  host other than `Precision-Workstation`. Do not run it elsewhere.
- It manually copies `content/.htaccess` (a zero-byte file) into the build
  output before rsync.

## Content conventions

- Books: `content/cherokee-new-testament/<book>/index.md`; chapters:
  `<book>/<NNNN>/index.md` (4-digit zero-padded, e.g. `1-corinthians/0701/`).
  Scan PNGs live in the chapter directory next to its `index.md`.
- Slugify is on (`slugify.paths = "on"`): paths stay lowercase and
  hyphenated. Case-different duplicate paths broke the site before (history:
  "Stop the madness with identical named paths being case different!") —
  don't reintroduce mixed case.
- Front matter is TOML in `+++` blocks: `draft=false`, `date`,
  `title = "<Book> - Chapter <N> - Cherokee New Testament"`, and `weight` —
  weights are file mtimes in epoch seconds left over from the original
  conversion, not editorial order. Don't renumber them as if they were.
- Internal links use Zola's `@/` form, e.g.
  `@/cherokee-new-testament/1-corinthians/0701/index.md`.

## Do not run

- `convert-01.sh`: the one-time converter that generated the content from
  `original/` (the pre-conversion HTML snapshot). It `rm -rf`s the book tree
  and is deliberately disabled with an early `exit 0` so it cannot clobber
  the hand-maintained content. Leave it disabled; don't clean up `original/`.

## Misc

- `reference/` is maintainer-only source material: parallel Bible text
  corpora in Drupal-Bible `.bc` format (English translations, Greek, and
  Cherokee with case markings) used for inter-linear work — not site content.
- Cherokee fonts ship in `static/CherokeeFonts/`, wired up by
  `sass/fonts.scss` (`compile_sass = true`).
- Git: trunk is `master`; feature branches are `feature/<issue#>-<slug>`,
  merged via PR with `type(#issue): summary` commit messages (e.g.
  `chore(#12): ignore .opencode/ in .gitignore`).
