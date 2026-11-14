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

- The build toolchain is **pinned**: `ZOLA_VERSION` records the exact Zola
  release (currently `0.22.1` — the latest release compatible with the
  vendored Zulma theme) and `ZOLA_VERSION.sha256` the release artifact's
  checksum. Any pin change re-executes the compatibility gate before it
  lands: the 0.23.x line ships the Tera 2 template major, and its binary
  fails this tree with `ERROR error: Unknown tag` at
  `Zulma/templates/taxonomy_single.html:3`; the pinned 0.22.1 builds the
  full unit (9,140 files) cleanly.
- **Build with `./build.sh`** — the repo's single build entry. It fetches the
  pinned musl-static Zola from the official release (verifying the checksum)
  into the ignored `.tools/zola/` on first use, then builds to `public/`
  (gitignored). **Dev server: `./build.sh serve`.**
- Never build or serve with an unpinned/system `zola` — the system binary
  rejects this site's config (and older/newer versions silently change
  behavior). `.tools/` is gitignored; the pin lives in the two tracked
  version files.
- No CI build or test exists. The only GitHub workflow is CodeQL, which
  self-warns it found no supported languages — don't expect CI validation.

## Deploy — Cloudflare Workers Static Assets

- **Push-to-deploy through Workers Builds**: a merge to `master` (this repo's
  branch of record; the builds default is `main` — set it explicitly) runs
  `./build.sh` and `npx wrangler deploy` automatically; PR branches get
  preview builds (`npx wrangler preview`). There is no deploy script.
- The deploy unit is the assets-only `wrangler.jsonc` (`./public`, 404-page
  handling, `previews {}` — no Worker script, no bindings); wrangler is
  pinned in `package.json`.
- One-time setup (Cloudflare dashboard): connect the GitHub App; create the
  Worker with the exact name `cherokeenewtestament-org` (name-match is a
  builds-fail condition); set the build command `./build.sh`; set the
  production branch `master`; attach the custom domains
  `cherokeenewtestament.org` and `www.cherokeenewtestament.org`.

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
