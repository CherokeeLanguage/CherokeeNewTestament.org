# Spec: Pin Zola to the latest compatible release as a repo-owned pinned toolchain

Issue: CherokeeNewTestament.org#14 · Authored 2026-11-04

## Intent

The repo's builds currently depend on an unpinned, uncontrolled Zola installation that cannot build the site at all in its modern versions. This spec pins one exact Zola release — the **latest release compatible with the site as it exists today** — records the pin in tracked files, materializes the pinned binary into an ignored local tooling path, and routes every build path through it. The design targets the modern Cloudflare approach (Workers with static assets) without performing that migration. The developer's directives this spec serves, verbatim in substance: create a spec recording the changes to the repo to date; pin Zola to the correct version for the repo and track it as a root repo bin (later relaxed: an ignored local Zola under `.tools/` or similar is acceptable if better); use the modern approach as recommended by Cloudflare but with the latest Zola version compatible with the site as it exists today; the repo's AGENTS.md and similar surfaces must document this very clearly, warranting an additional SC; the sibling repositories `../michael-conrad.com` and `../brothertown-language-com` are approach references only, not templates to copy.

## Background — the repo's state to date

Recorded 2026-11-04, every claim verified against the repo or executed commands this session:

- **What the site is.** Source for cherokeenewtestament.org, an inter-linear Cherokee New Testament reader built with [Zola](https://www.getzola.org/) and the vendored `themes/Zulma` theme (in-tree, not a submodule; unmaintained upstream — last real commit 2020-05-10, `min_version = "0.6.0"`). Chapter pages are raw HTML tables inside Markdown: each verse is its own table (verse-scan image row, then English / Cherokee syllabary / phonetic rows), with page scans above.
- **Content conventions.** Books at `content/cherokee-new-testament/<book>/index.md`; chapters at `<book>/<NNNN>/index.md` (4-digit zero-padded). Slugify `paths = "on"` — case-different duplicate paths broke the site before (commit `29112cc` "Stop the madness with identical named paths being case different!"). Front matter is TOML in `+++` blocks; `weight` values are file mtimes in epoch seconds from the original 2020 conversion, not editorial order. Internal links use Zola's `@/` form. Verse-scan PNGs live beside each chapter's `index.md`.
- **Build state (the defect).** With the locally installed Zola 0.23.6, `zola build` fails outright: `config.toml` line 3 `highlight_code = true` is rejected as an unknown field (executed 2026-11-04). No Zola version is pinned anywhere in the repo; builds depend on whatever `zola` is on PATH.
- **Deploy state.** `deploy.sh` rebuilds and rsyncs `public/` to `clcom@vhost.cherokeelessons.com:./cnt/public_html/`, gated to the host `Precision-Workstation`, and manually copies the zero-byte `content/.htaccess` (an Apache-ism — inert once off Apache).
- **CI state.** The only GitHub workflow is CodeQL, which self-warns it found no supported languages; no build or test CI exists.
- **Recent repo changes.** A root `AGENTS.md` (agent guidance documenting the facts above) was added on branch `feature/agents-md` and is open as PR #15, pending human merge at spec time. `.opencode/` (the agent-governance deck) is gitignored and a separate git repo; the issue store lives at `.issues/` (a worktree of this repo on the `issues-data` branch).
- **Migration direction (developer-stated).** The site will migrate to Cloudflare. Cloudflare's currently recommended path for a static site is a Worker with static assets (assets-only `wrangler` manifest, `assets.directory = "./public"`); Pages remains supported but is feature-frozen ("start new projects with Workers" — developers.cloudflare.com, accessed 2026-11-04). Workers Builds' image preinstalls no Zola; the Pages image lists Zola 0.22.1 by default. Both sibling repos prove the build-script-owns-the-Zola-version pattern in production on these platforms.

## Root causes

1. No version pin exists: the build toolchain is whatever `zola` the invoking environment happens to have — reproducibility and correctness both uncontrolled.
2. The committed `config.toml` targets a 2020-era Zola schema; every modern Zola either rejects it (≥ 0.19.0), silently ignores parts of it (0.14–0.18), or warns (0.13).
3. The build path has no single owner: `deploy.sh` invokes bare `zola`; no build entry exists that local work, the deploy script, and a future CI build could share.

## Requirements

- **R-1 — Pin target.** The repo SHALL pin one exact Zola release: the **latest release compatible with the site as it exists today** — the site's content and templates untouched; only semantics-preserving accommodations allowed (R-2). Compatibility is decidable empirically: the pinned version's build must succeed and its output must satisfy the parity instrument in SC-4. Executed ceiling probe (2026-11-04, see Evidence appendix): with the R-2 accommodations, Zola 0.19.2, 0.20.0, 0.21.0 and 0.22.1 all build the site (288 pages / 331 HTML files, identical to the 0.10.1 baseline); Zola 0.23.x fails inside Zulma's templates with Tera "Unknown tag" errors (observed at `taxonomy_macros.html:1:4` on `{% macro %}` in one execution and `taxonomy_single.html:3:4` on `{% import %}` in another — the failing instantiation varies between runs, the incompatibility class does not; the developer independently stated the theme-template incompatibility). Pin target: **Zola 0.22.1**.
- **R-2 — Accommodations, enumerated and rendering-neutral.** The change MAY modify only these surfaces, each verified output-neutral against the current site's output:
  - (a) `config.toml`: remove top-level `highlight_code = true`. Verified neutral: zero fenced code blocks and zero `<code>`/`<pre>` elements exist in any content Markdown (grep, 2026-11-04); 0.22's highlighting schema (`[markdown.highlighting]`, theme required) would otherwise be mandatory for a key that changes nothing here.
  - (b) `config.toml`: taxonomy entries `rss = true` → `feed = true`. Same semantics under the modern key name (taxonomy-term feeds still generated — verified in the 0.22.1 probe output).
  - (c) `config.toml`: add `feed_filenames = ["rss.xml"]` (top-level key). Preserves the exact feed URLs the live site publishes today (`authors/*/rss.xml` — verified generated by the 0.22.1 probe build with this key; without it Zola emits `atom.xml`, which would silently change published feed URLs).
  - (d) `content/_index.md`: remove the section front matter's `date` and `[taxonomies]` block. Verified neutral: newer Zola dropped both keys for sections (0.19.2+ rejects them — executed); no Zulma or site template reads `section.date` (grep of all templates); the 0.10.1 baseline output never lists the home section in any taxonomy term page or feed (grep, 2026-11-04).
- **R-3 — Pin record and materialization.** The pin SHALL be recorded in tracked files: a `ZOLA_VERSION` file carrying the exact release tag (`0.22.1`), plus a tracked manifest recording the SHA256 of the official release artifact. The pinned binary SHALL be the **musl static** build (`zola-v0.22.1-x86_64-unknown-linux-musl.tar.gz` — asset verified present on the v0.22.1 release), materialized by the repo's build entry into the ignored local tooling path `.tools/zola/` (the binary itself is NOT committed; the developer sanctioned the ignored-local form). The build entry SHALL verify the artifact's SHA256 at materialization and SHALL be the only Zola the repo's build path invokes.
- **R-4 — Single build entry.** The repo SHALL have one build entry (a root `build.sh`) that: ensures the pinned release is materialized at `.tools/zola/` (fetching the exact pinned artifact from the official GitHub releases when missing or checksum-mismatched), verifies the checksum, and invokes the pinned binary to build the site to `public/`; the entry SHALL also provide a serve mode (`./build.sh serve`) that runs the pinned binary's dev server, so the dev-server path uses the pinned toolchain too. Local builds, dev servers, `deploy.sh`, and any future CI build command SHALL go through this entry.
- **R-5 — Cloudflare-modern design target.** The design SHALL aim at Cloudflare Workers with static assets (the currently recommended path): the build entry must be directly usable as the Workers Builds build command (Ubuntu x86_64, no preinstalled Zola, network available); no Apache-only assumptions may enter the build path; `deploy.sh`'s rsync delivery may persist until migration but must not be a build-path dependency. The migration itself (assets-only `wrangler` manifest, dashboard/DNS cutover, `_redirects`/`_headers` equivalents) is NOT this change.
- **R-6 — Instruction-surface currency.** After the change, the repo's agent-facing instructions SHALL document the pinned toolchain clearly: `AGENTS.md`'s build section states the pinned version, the `.tools/zola/` materialization path, the build entry and its serve mode, and the prohibition on building or serving with an unpinned/system Zola; the README's build note points at the build entry. No instruction surface may direct an agent to run bare `zola build` or bare `zola serve`.

## Success criteria

| ID | Criterion | Class | Instrument |
|---|---|---|---|
| SC-1 | A clean checkout builds completely via the build entry using only the pinned Zola | behavioral | In a shallow clean checkout (`git clone --depth 1`) of the change branch, with any system `zola` removed from PATH, run the build entry: exit 0; the output directory contains `index.html`, `404.html`, `search_index.en.js`, a chapter page (e.g. `cherokee-new-testament/1-corinthians/0701/index.html`), and taxonomy term feeds |
| SC-2 | The pin record is tracked and consistent with the materialized binary | structural | `git ls-files` lists `ZOLA_VERSION` and the manifest; after a fresh materialization, the recomputed SHA256 of the fetched release artifact equals the manifest value, and `ZOLA_VERSION` equals the binary's `--version` output |
| SC-3 | No unpinned Zola remains on the repo's build or serve paths | structural | Grep the build entry, its serve mode, and `deploy.sh`: every Zola invocation resolves to the pinned materialized path (directly or via the entry); no invocation of bare `zola` from PATH remains |
| SC-4 | Build output parity with the site as it exists today, per the inventory's parity contract | behavioral | Executed full-tree comparison of the pinned build's output against a freshly regenerated baseline — Zola 0.10.1 building trunk as-committed (the launch-era output; deterministic to reproduce) — using the normalization procedure defined in the delta-inventory section: every differing file must fall in the whitespace/escaping class or in one of the inventoried residual classes with its delta matching the described mechanism; any file or delta outside both fails the criterion |
| SC-5 | The build path is portable to Cloudflare build images | behavioral | SC-1's clean-checkout run (no system Zola, network fetch of the pinned musl-static artifact, checksum-verified build) is the portability demonstration: the musl binary is statically linked (zero runtime-library dependencies), so no host library availability can break it |
| SC-6 | Instruction surfaces document the pinned toolchain clearly and accurately | structural | Read `AGENTS.md` and `README.md` build notes against the implemented state: pinned version named, `.tools/zola/` path named, build entry and serve mode named, unpinned-build prohibition stated, and every build/serve instruction consistent with the implemented entry (no bare `zola build` or `zola serve` guidance anywhere) |

## Version-behavior delta inventory (0.10.1 baseline → 0.22.1 pinned build)

**Normalization procedure (exact, determines every set below).** For a compared file pair: (1) replace `&#x2F;` with `/` in both sides; (2) collapse runs of spaces/tabs and strip trailing whitespace per line; (2b) ensure both sides end with a final newline (append one where missing — a trailing-newline-only difference is thereby normalized); (3) diff with blank-line insensitivity (`diff -B`). Files whose normalized diff is empty are **whitespace/escaping-class**; the rest are **residual** and are classified below from full per-file inspection (no sampling).

**Procedure result (2026-11-04).** Raw full-tree diff: 346 differing files, no added/removed files (the accommodation set keeps every output path, feeds included). After normalization: 328 files are whitespace/escaping-class — every book/chapter content page, the home page, the TOC pages, the author index and pagination pages (`page/2`+), `sitemap.xml` (whose URL set is additionally verified identical as sorted `<loc>` lists), and `fonts.css` (sole delta: trailing-newline drop, 6373 → 6372 bytes — erased by the procedure). 18 files are residual:

| File(s) | Delta (full inspection) | Disposition |
|---|---|---|
| `404.html` | Zola 0.10.1's built-in unstyled 404 page ("Oops! / File Not Found: 404." — byte-identical to Zola v0.10.1's `builtins/404.html`; Zulma ships no 404 template) becomes the minimal built-in "404 Not Found" page of the pinned version | Platform built-in 404 content changed between versions; no theme template is involved. Accepted as version behavior — a custom/styled 404 template would be separate template work (out of scope) |
| `authors/timothy-legg/page/1/index.html`, `authors/michael-conrad/page/1/index.html` | Redirect page gains a JS `location.replace` mechanism while **retaining** the meta refresh, and drops the canonical link; same destination URL | Version-behavior delta in pagination-redirect structure; destination unchanged; accepted |
| `authors/timothy-legg/rss.xml`, `authors/michael-conrad/rss.xml` | Feed XML restructured; channel `<title>` gains the term suffix ("… - Timothy Legg"); **every item** gains an `<author>Unknown</author>` element and its `<description>` gains an `xml:base` attribute (288 items timothy-legg, 1 item michael-conrad) | Item `<link>`/`<guid>` sets and counts unchanged (verified); channel `<description>` empty in both builds; metadata-level delta only; accepted |
| `cherokee-new-testament/index.html` (TOC) | External anchors gain `rel="external"` (2 anchors — Zola's modern default external-links behavior); listing whitespace normalization (partially whitespace-class) | Attribute addition on external links only; accepted |
| 9 theme CSS bundles (`darkly`, `default`, `flatly`, `lux`, `pulse`, `simplex`, `slate`, `solar`, `superhero` `.css`) | Recompile artifacts, per file: UTF-8 BOM added at file head (all 9 — old head bytes `/*!`, new `EF BB BF`); numeric leading zeros stripped from minified values (e.g. `0.625em` → `.625em`; ≈330 → 14 remaining occurrences per file — value-preserving formatting); the 7 bundles carrying a Google-Fonts `@import` statement have it moved from after the Bulma banner to the file head (absent in BOTH builds for `default.css` and `slate.css`); trailing newline dropped (all 9 — last byte `0a` → `}`) | CSS declarations semantically unchanged (leading-zero removal preserves values); accepted |
| `elasticlunr.min.js` | Bundled search library version string 0.9.5 → 0.9.6 | Version-internal library bump; accepted |
| `robots.txt` | Gains `Disallow:` and `Allow: /` lines | Policy-equivalent (allow-all unchanged); accepted |
| `search_index.en.js` | Search index regenerated by newer Zola internals (31616 → 31514 bytes) | Same corpus, same consumer; accepted |

**Parity contract (what SC-4 verifies).** Every differing file in the pinned build's output must fall in exactly one of: (i) the whitespace/escaping class as defined by the normalization procedure, or (ii) one of the residual classes above, with its delta matching the described mechanism. Any differing file outside both, or any residual delta outside its class's described mechanism, fails SC-4. The sets are produced by diffing complete output trees — never samples — so completeness is checked by the same procedure that produced them.

## Analysis

- **Why 0.22.1 and not newer.** The ceiling is empirical, not stylistic: 0.23.x rejects Zulma's macro templates outright (executed probe; the developer independently stated the theme/templates incompatibility). 0.19.0 introduced `deny_unknown_fields`, turning the old config keys into hard errors; with the R-2 accommodations 0.19.2–0.22.1 all build. 0.22.1 is the newest of the compatible range — the latest version of Zola compatible with the site as it exists today.
- **Why not older (0.10.1, the launch-era version).** 0.10.1 builds the raw config without accommodations, but the developer's directive names the *latest* compatible release, and 0.22.1's accommodations are each verified rendering-neutral; older pins would carry the OpenSSL-1.1 dynamic dependency (`ldd` of the 0.10.1 binary shows `libssl.so.1.1`) with no offsetting benefit.
- **Why musl static.** The musl build is statically linked (verified for the 0.22.1 asset line by release inspection and for 0.23.6 by download + `file`/`ldd` in research): it runs identically on this workstation, on Cloudflare's Ubuntu images, and in any Linux x86_64 CI, with no host-library requirements — the portability property R-5 needs.
- **Why `.tools/zola/` + tracked manifest rather than a committed binary.** The developer explicitly sanctioned the ignored-local form if better. It keeps ~20 MB out of git history per version bump, keeps the pin fully auditable (tag + SHA256 in tracked files), matches the deck's existing vendored-tooling pattern, and matches the production-proven sibling pattern (`ZOLA_VERSION` + fetch in `build.sh`). The build entry's checksum verification keeps the fetch deterministic.
- **Why one build entry.** Root cause 3: the build path needs a single owner. One entry serves local work, `deploy.sh`, and the future Workers Builds command unchanged — the property that makes the Cloudflare migration a configuration change rather than a build rewrite.
- **Alternatives ruled out.** Committed `bin/zola` (heavier history; no offsetting benefit once the fetch is checksum-verified); Pages-specific design (feature-frozen; Workers is the recommendation); full theme/config modernization to 0.23+ (blocked by Zulma template incompatibility — migration-sized theme work, explicitly out of scope).

## Affected surfaces

- `config.toml` — three edits per R-2 (a)–(c).
- `content/_index.md` — two dead keys removed per R-2 (d); rendering verified neutral.
- `build.sh` (new), `ZOLA_VERSION` (new), SHA256 manifest (new) — tracked; the entry carries build and serve modes.
- `.gitignore` — add `.tools/`.
- `deploy.sh` — its `zola build` step routed through the build entry (delivery via rsync unchanged).
- `AGENTS.md`, `README.md` — build-section updates per R-6 (AGENTS.md currently documents the broken-with-0.23.6 state and a bare `zola serve` dev-server line; both are superseded by the pinned-toolchain documentation when this change lands — the update is part of this change, not a follow-up).
- No template, theme, or other content file is touched.

## Out of scope

- Performing the Cloudflare migration: the assets-only `wrangler` manifest, Workers Builds enablement, DNS cutover, `_redirects`/`_headers` authoring.
- Updating Zulma's templates for Zola 0.23+ (theme modernization is its own future work).
- Any content change beyond R-2 (d); any change to site content, URLs, or link structure. Rendering deltas beyond the verified inventory in the section above are out of scope by construction — the implementation must reproduce exactly that inventory and nothing more.
- Renaming `config.toml` to `zola.toml` (cosmetic; Zola accepts both).

## Traceability

| Requirement / SC | Developer statement (this session) |
|---|---|
| R-1, SC-4 | "using the latest version of zola that is compatible with the site as it exists today" |
| R-1 (spec stage), Background | "create a spec to record changes to repo to date" |
| R-3, R-4 | "pin zola to the correct version for the repo and to track as a root repo bin"; relaxed: "if it would be better to always use an ignored local zola in .tools/ or similar, that is acceptable" |
| R-4, R-5, SC-5 | "this site will be migrating to cloudflare works/pages, so take that into account"; "we want the modern approach as recommended by cloudflare" |
| R-6, SC-6 | "the repo agents.md etc needs to be very clear about this. this would need to be an additional SC possibly." |
| R-2 (bounded accommodations) | "compatible with the site as it exists today" + "the theme uses templates that the latest version of zola does not support" |
| Approach (siblings as reference) | "you can reference ../michael-conrad.com and ../brothertown-language.com for other example setups … do not cargo-cult, they are simply for approach reference" |

## Evidence appendix — executed probe records (2026-11-04)

All builds run against the repo tree (or a throwaway worktree of trunk `09eb3ce` for the front-matter variants), output to `/tmp`, repo untouched.

| Zola | Config variant | Result |
|---|---|---|
| 0.23.6 (installed) | as-committed | FAIL — `unknown field highlight_code` (config.toml:3) |
| 0.10.1 (2020-03-12) | as-committed | exit 0 — 288 pages; taxonomy `rss.xml` feeds generated; baseline recorded (331 HTML files) |
| 0.13.0 | as-committed | exit 0 — deprecation warning for `highlight_code`; taxonomy `rss` silently ignored |
| 0.18.0 | as-committed | exit 0 — `highlight_code` and taxonomy `rss` silently ignored (no warning) |
| 0.19.0+ (mechanism) | as-committed | FAIL — `deny_unknown_fields` (research: changelog + source at v0.19.0) |
| 0.19.2 / 0.20.0 / 0.21.0 | R-2 accommodations (a),(b) | FAIL — section front matter `date` unknown |
| 0.19.2 / 0.20.0 / 0.21.0 / 0.22.1 | R-2 accommodations (a)–(d) | exit 0 — 288 pages / 331 HTML files; `feed = true` honored; with (c) feeds emitted at `rss.xml` URLs |
| 0.23.6 | R-2 accommodations (a)–(d) | FAIL — Tera "Unknown tag" inside Zulma templates; observed at `taxonomy_macros.html:1:4` (`{% macro %}`) in one execution and `taxonomy_single.html:3:4` (`{% import %}`) in another (first-hit file varies between runs) |

Binary facts: `zola-v0.22.1-x86_64-unknown-linux-musl.tar.gz` exists on the v0.22.1 release (GitHub API, 2026-11-04); the 0.22.1 gnu binary links only glibc-family libraries (no OpenSSL); the 0.10.1 gnu binary requires `libssl.so.1.1`.

Delta-inventory procedure (2026-11-04): full-tree `diff -rq` of the 0.10.1 baseline vs the 0.22.1 build carrying all R-2 accommodations — 346 differing files, no added/removed paths; then the normalization procedure defined in the inventory section (`&#x2F;`→`/`, whitespace collapse, blank-line-insensitive diff) splits them into 328 whitespace/escaping-class files and 18 residual files, each residual file classified from its full diff (BOM/last-byte checks, `@import` and leading-zero counts, feed `<link>`/`<guid>` set comparisons — no sampling). Independent reproductions: the round-1 validation reviewer reproduced the baseline/pinned builds, counts, and the non-chapter delta subset; the round-2 reviewer reproduced the full 346-count procedure and its execution drove the inventory's final classification (leading-zero stripping, per-item feed deltas, per-file CSS mechanisms, the 0.23.6 second instantiation).

🤖 Co-authored with AI: OpenCode (huggingface/zai-org/GLM-5.3-Flash)
