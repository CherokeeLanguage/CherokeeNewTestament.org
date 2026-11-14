# Plan — CherokeeNewTestament.org#17 (Workers stand-up at the theme-compatible Zola pin)

Source: CherokeeNewTestament.org#17 spec (validated clean PASS, round 2, 2026-11-14). Branch (CNT repo): `feature/17-stand-up-on-cloudflare-workers`, from `master` (= origin/master, fetched + verified at cycle start). All build/test instruments run through the repo's own documented toolchain — `./build.sh` (the pinned-Zola build entry; the parent devops repo has no build framework, per the parent's landed submodule build-surface record). Scratched-in `previews: {}` re-verification duty (R-1): noted under item 1's instrument.

## Items

- **Item 1 — `wrangler.jsonc` (R-1 → SC-1).** New tracked manifest: `name "cherokeenewtestament-org"`, `compatibility_date "2026-11-14"`, `assets { directory "./public", not_found_handling "404-page" }`, `previews {}`. No `"main"`, no bindings.
  - RED: `git ls-files wrangler.jsonc` empty; content-absence greps fail.
  - GREEN: add the manifest.
  - Instrument: SC-1's eight greps. `previews: {}` re-verification (R-1's duty): executed `npx wrangler@4.162.0 deploy --dry-run` on the completed tree (item 14) — the 4.153.0 preview-build error path is not reproducible locally (it fires inside Workers Builds preview runs); the block is retained on the sibling's observed evidence with that disposition recorded here.
- **Item 2 — `build.sh` branch-aware layer (R-2 → SC-2).** Gains the base-url logic in POSIX-sh form (no bash array `BASE_URL_ARGS` — this script is `#!/bin/sh`, unlike the sibling's bash script): branch from `WORKERS_CI_BRANCH`, git fallback resolving production-safe on detached HEAD; `master` → `--base-url "https://cherokeenewtestament.org/"`; other branches → `--base-url /`; `SITE_BASE_URL` wins in both; then `"$zola_bin" build` with the resolved `--base-url`. Pin-download-and-verify core unchanged.
  - RED: `grep -c WORKERS_CI_BRANCH build.sh` = 0.
  - GREEN: insert the resolution block before the build invocation.
  - Instrument: SC-2's four greps + the behavioral mode checks (items 10–13) execute on the completed script.
- **Item 3 — `config.toml` base_url (R-3 → SC-3).** `base_url = "https://cherokeenewtestament.org/"` (trailing slash).
  - RED: `grep -E '^base_url' config.toml` shows no trailing slash.
  - GREEN: set the canonicalized value.
  - Instrument: SC-3's greps on post-build `public/sitemap.xml` + `public/authors/timothy-legg/rss.xml` (executed in item 9's build).
- **Item 4 — `static/_headers` (R-7 → SC-4).** New tracked file: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`, Content-Security-Policy covering `self`, the **utteranc.es** comment-widget origins (`https://utteranc.es` for script-src and frame-src — the widget loads unconditionally on 288 article pages; its continued functioning is preserved behavior, surfaced by the plan-validation round-1 census and corrected into the spec before these items), and the theme font load path (`fonts.googleapis.com` style-src import, `fonts.gstatic.com` font-src binaries) — and no origin the site does not use.
  - RED: file absent.
  - GREEN: add it.
  - Instrument: SC-4's seven greps (now including the `utteranc.es` requirement and the unused-origins zero-grep).
- **Item 5 — Publish-path retirement + docs (R-6 → SC-5).** `git rm deploy.sh content/.htaccess`; README gains the Deployment section (Workers Builds, `npx wrangler deploy`, `wrangler preview`, the ops sequence: GitHub App, `cherokeenewtestament-org` name, build command `./build.sh`, production branch `master`, custom domains apex + `www`); AGENTS.md's "Deploy — manual and machine-gated" section becomes the Workers deploy path (the `.htaccess` copying step's text removed); the Build section's toolchain line keeps its pin statement (item 7 completes the verdict sentence).
  - RED: `git ls-files deploy.sh content/.htaccess` non-empty; README lacks the ops elements.
  - GREEN: delete + rewrite.
  - Instrument: SC-5's greps.
- **Item 6 — `package.json` wrangler pin (R-5 → SC-6).** New tracked file: `wrangler 4.162.0` exact.
  - RED: `git ls-files package.json` empty.
  - GREEN: add it.
  - Instrument: SC-6's greps.
- **Item 7 — Pin verdict in docs (R-4 → SC-7).** README build section gains "currently `0.22.1` — the latest release compatible with the vendored Zulma theme"; AGENTS.md build section gains the same verdict + the standing bump rule (a future pin change re-executes the compatibility gate: current-line binary build → expect exit 1 with the Tera-2 template error; pinned binary → expect exit 0). Pin files themselves unchanged (already 0.22.1).
  - RED: `grep -c 'compatible with the vendored Zulma' README.md` = 0.
  - GREEN: add the verdict sentences.
  - Instrument: SC-7's structural greps + the executed re-gate (item 8).
- **Item 8 — Compatibility gate + census re-run (SC-7 behavioral, SC-8).** In a fresh pristine shallow clone of the completed branch: 0.23.x-current-line binary build → non-zero with the Tera 2 template error; `zola 0.22.1` → exit 0, 9,140 files; post-build census: zero files > 25 MiB; count ≤ 20,000; zero `%-path` failures.
  - Commit: N/A (instrument execution).
- **Item 9 — Fresh-clone build, production-resolving + absolute-URL instrument (SC-9, SC-3 behavioral half).** In the item 8 fresh clone: executed `WORKERS_CI_BRANCH=master ./build.sh` → exit 0 (this run IS SC-9's lettered instrument — production-resolving so the config.toml-driven apex bakes in); `grep -c 'cherokeenewtestament.org' public/sitemap.xml` ≥ 1 and in `public/authors/timothy-legg/rss.xml` ≥ 1 (establishes SC-3's post-build half).
  - Commit: N/A.
- **Item 10 — Preview mode domain-neutral on the URL surface (SC-10).** In the scratch clone: `WORKERS_CI_BRANCH=feature-x ./build.sh`; `grep -c 'cherokeenewtestament.org' public/sitemap.xml` = 0; `grep -c 'href="https://cherokeenewtestament.org' public/cherokee-new-testament/titus/index.html` = 0; the taxonomy-feed metadata limitation (zola 0.22's `--base-url` does not rewrite the built-in per-taxonomy feed channel/entry URLs — observed absolute-apex in the instrument run: `<link>`, `atom:link`, `guid`, `xml:base`) is documented with a README caveat sentence (committed in the same cycle) and production builds are apex-correct per SC-3.
  - Commit: the README caveat sentence rides this item; the instrument run itself is evidence.

- **Item 11 — Override wins in preview mode (SC-11).** `WORKERS_CI_BRANCH=feature-x SITE_BASE_URL=https://example.com ./build.sh`; `https://example.com` ≥ 1 in `public/authors/timothy-legg/rss.xml`.
  - Commit: N/A.
- **Item 12 — Override wins in production mode (SC-12).** `WORKERS_CI_BRANCH=master SITE_BASE_URL=https://example.com ./build.sh`; `https://example.com` ≥ 1 in `public/authors/timothy-legg/rss.xml`.
  - Commit: N/A.
- **Item 13 — Detached HEAD production-safe (SC-13).** In the scratch clone: `git checkout --detach HEAD && ./build.sh`; apex ≥ 1 in `public/authors/timothy-legg/rss.xml`.
  - Commit: N/A.
- **Item 14 — Manifest validates under the pinned wrangler (SC-14).** In the fresh clone: `npx wrangler@4.162.0 deploy --dry-run` exit 0 with the assets directory accepted (this also discharges item 1's `previews: {}` re-verification duty with the disposition above).
  - Commit: N/A.

## Ordering

1 → 2 → 3 → 4 → 5 → 6 → 7 strictly (each content item commits before the next starts); items 8–14 are instrument executions on the completed tree (items 10–13 run in the scratch clone after a fresh branch fetch). No cycles.

## Traceability

| Item | Spec ref | SC |
|---|---|---|
| 1 | R-1 | SC-1 |
| 2 | R-2 | SC-2 (+10–13) |
| 3 | R-3 | SC-3 |
| 4 | R-7 | SC-4 |
| 5 | R-6 | SC-5 |
| 6 | R-5 | SC-6 |
| 7 | R-4 | SC-7 |
| 8 | R-4 | SC-7 (behavioral), SC-8 |
| 9 | R-3 | SC-9, SC-3 |
| 10 | R-2 | SC-10 |
| 11 | R-2 | SC-11 |
| 12 | R-2 | SC-12 |
| 13 | R-2 | SC-13 |
| 14 | R-1 | SC-14 |

## Documentation sources

- Spec: CherokeeNewTestament.org#17 (R/SC texts are the deliverable's content source; the SC instruments are the verification source).
- Sibling pattern of record: CherokeeLanguage/CherokeeLessons at `3b3634e` (README Deployment section; `build.sh` branch layer — bash; CNT's is sh — adapted; `wrangler.jsonc`; `package.json`).
- Platform facts (live, spec-dated 2026-11-14): wrangler 4.162.0 latest; zola 0.23.6 latest (Tera 2 line); the executed gate logs under /tmp/opencode (zola236-build.log, zola221-build.log).

## Enforcement gate

The CNT repo's own pre-commit/pre-push hooks are installed (session inventory: ok) — trunk-protected `master`; the commits land on the feature branch. The `.issues/<N>`-path hook rule: no added file cites issue-store paths (the added text names no store paths). No `.issues` edits ride these commits (store work commits on `issues-data` via the store tooling).

## Cost frame

Two new files + two deleted + four edited + one new config, ~100 changed lines total across the repo. One pristine clone build series (~9,140 files × 5 builds, ~2 min total). Zero dependencies; wrangler 4.162.0 fetched by npx at item 14 (network).

## Edge cases

- `deploy.sh` deletion + `content/.htaccess` deletion: `.htaccess` is content-dir-tracked zero bytes — `git rm` clean; no other file references it except AGENTS.md's deploy section (rewritten in item 5).
- The sh-vs-bash adaptation: the sibling's `(BASE_URL_ARGS=(--base-url ...))` array pattern is NOT portable to `#!/bin/sh` — CNT's layer resolves a single `BASE_URL_ARGS` string variable instead; the behavioral items 10–13 exercise exactly those branches.
- `previews: {}` on wrangler 4.162.0: config-valid either way; the re-verification disposition (item 1) records that the preview-build failure path is not locally reproducible — kept on the sibling's evidence.
- Feed greps: the pinned build emits per-taxonomy feeds only (`authors/michael-conrad/rss.xml`, `authors/timothy-legg/rss.xml`) + `sitemap.xml` — instruments name real files; no root `rss.xml` exists.
- The `_headers` CSP syntax: single line, path-scoped `/*` block (the sibling's shape); the plan-validation round-1 dispatch's full-tree origin census surfaced the unconditional utteranc.es embed (288 pages) — the spec's R-7/audit was corrected before these items consume it, and the item 4 deliverable carries the widget's origins (preserved behavior); if implementation finds any further origin the set lacks, the finding routes back to the spec before PR.

## Not included

- Cloudflare-side ops (dashboard/API — after PR merge, developer involvement where account authorization is required).
- Theme changes; the devops-repo records' refresh (its own landed-currency follow-up); CodeQL workflow; the `zola.toml` rename.
