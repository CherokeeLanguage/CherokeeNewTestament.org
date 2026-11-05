# Plan: Pin Zola to the latest compatible release as a repo-owned pinned toolchain

Issue: CherokeeNewTestament.org#14 · Spec: `.issues/14/spec.md` (validated round 4, PASS, zero findings) · Authored 2026-11-04

## Dependency order

1 → 2 → 3 → 4 → 5 → 6 → 7. Item 2 consumes item 1's record; item 3 needs item 2's pinned binary to run its RED and instrument; item 4 needs item 3's accommodated build; item 5 routes existing invocations through item 2's entry; item 6 documents the implemented state of items 1–5; item 7 re-verifies the assembled whole in a clean checkout. No cycles.

## Item 1 — Pin record (SC-2)

- **Deliverable:** tracked `ZOLA_VERSION` (content exactly `0.22.1`, no `v` prefix, trailing newline) and tracked `ZOLA_VERSION.sha256` (`<sha256>  zola-v0.22.1-x86_64-unknown-linux-musl.tar.gz` — the SHA256 of the official musl release artifact).
- **RED:** `git ls-files ZOLA_VERSION ZOLA_VERSION.sha256` outputs nothing and `test -f ZOLA_VERSION` fails — the pin does not exist.
- **GREEN:** fetch `https://github.com/getzola/zola/releases/download/v0.22.1/zola-v0.22.1-x86_64-unknown-linux-musl.tar.gz` to a temp path, `sha256sum` it, write both files at the repo root.
- **Instrument:** `git ls-files` lists both files; `cat ZOLA_VERSION` prints `0.22.1`; `sha256sum` of a freshly fetched copy of the artifact equals the value in `ZOLA_VERSION.sha256`.

## Item 2 — Build entry with build and serve modes (SC-1 local form, SC-5 mechanism, SC-3 partial)

- **Deliverable:** executable root `build.sh` (`#!/bin/sh`, `set -eu`): resolves the pinned version from `ZOLA_VERSION`; ensures `.tools/zola/zola` exists and `--version` output matches the pin — when absent or mismatched, fetches the exact release artifact named in `ZOLA_VERSION.sha256`, verifies its SHA256 against that file, extracts the binary to `.tools/zola/zola`, `chmod +x`; refuses to proceed on checksum mismatch. Build mode (default): `./build.sh [zola-build-args…]` executes the pinned binary's `build`. Serve mode: `./build.sh serve [zola-serve-args…]` executes the pinned binary's `serve`.
- **RED:** `test -x build.sh` fails (no entry exists), and the only Zola available (system 0.23.6) fails the build — executed evidence recorded in the spec's appendix.
- **GREEN:** write `build.sh` as specified.
- **Instrument:** with every `zola` binary removed from `PATH`, the entry materializes the pinned binary and invokes it — `.tools/zola/zola --version` prints `zola 0.22.1`, and the entry's build attempt against the then-unmodified config fails with the pinned binary's config-parse error (proving the pinned binary, not a PATH Zola, executed). The build-success and serve-success assertions are config-dependent and are verified in item 3 (build) and item 7 (clean-checkout build + serve smoke) once the accommodations land. (Amendment 2026-11-04, implement-cycle discovery: the original instrument asserted build success at item 2, which the unmodified config cannot satisfy; the assertions moved to their config-dependent items. Recorded in the work record.)

## Item 3 — Semantics-preserving accommodations (R-2 a–d; prerequisite of SC-4)

- **Deliverable:** `config.toml`: (a) remove top-level `highlight_code = true`; (b) taxonomy entries `rss = true` → `feed = true`; (c) add top-level `feed_filenames = ["rss.xml"]`. `content/_index.md`: (d) remove the section front matter's `date` line and `[taxonomies]` block (title/weight/`[extra]` remain).
- **RED:** `.tools/zola/zola build -o /tmp/opencode/build-item3-red` exits non-zero on the unmodified config (config-parse failure — executed in the probe; re-confirm at cycle start).
- **GREEN:** apply the four edits exactly as enumerated.
- **Instrument:** the same build command now exits 0 and reports 288 pages; `grep -c 'rss = true' config.toml` returns 0 and `feed = true` appears in all three taxonomy entries; `grep -c '^date\|^\[taxonomies\]' content/_index.md` returns 0.

## Item 4 — Output parity verification (SC-4)

- **Deliverable:** executed parity evidence per the spec's delta inventory and parity contract.
- **RED:** before item 3, the pinned build does not exist (item 3's RED demonstrates this), so the parity assertion cannot hold — the criterion is unmet.
- **GREEN:** no code change; this item is the executed comparison: build the 0.10.1 baseline (fetch `zola-v0.10.1-x86_64-unknown-linux-gnu.tar.gz` from the official release, build trunk as-committed to a temp dir) and the pinned build (item 3's output), then run the spec's normalization procedure over the full tree and classify every differing file against the inventory.
- **Instrument:** the classification output shows zero files outside the whitespace/escaping class and zero residual deltas outside their inventoried mechanisms; page/HTML counts match the recorded figures (288 pages / 331 HTML files both sides).

## Item 5 — Build-path routing (SC-3)

- **Deliverable:** `.gitignore` gains a `.tools/` entry; `deploy.sh`'s build step (`rm -rf public` + `zola build`) becomes `rm -rf public` + `./build.sh` — the rsync delivery lines untouched.
- **RED:** `git check-ignore -q .tools/zola/zola` exits non-zero (not ignored); `grep -n '^zola build' deploy.sh` finds the bare invocation.
- **GREEN:** add the ignore entry; replace the `zola build` line in `deploy.sh` with `./build.sh`.
- **Instrument:** `git check-ignore -q .tools/zola/zola` exits 0; `grep -nE '(^|[^./])zola (build|serve)' deploy.sh` finds nothing and `grep -n './build.sh' deploy.sh` finds the routed invocation.

## Item 6 — Instruction-surface currency (SC-6)

- **Deliverable:** `AGENTS.md` build section rewritten to the implemented state: pinned version 0.22.1, the `.tools/zola/` materialization path, `./build.sh` with its build and serve modes, and the prohibition on building/serving with an unpinned or system Zola; the stale "build fails with 0.23.6 / migrating config.toml is a deliberate change" passage replaced accordingly (the migration this change performs is now the documented state). `README.md` build note points at `./build.sh`.
- **RED:** `grep -nE 'zola (build|serve)' AGENTS.md` currently finds bare-tool guidance ("Build: `zola build`…", "Dev server: `zola serve`") — the surfaces contradict the implemented state.
- **GREEN:** rewrite the two sections per the deliverable.
- **Instrument:** `grep -nE '\bzola (build|serve)\b' AGENTS.md README.md` finds no bare-tool instruction; `grep -n '0.22.1' AGENTS.md` and `grep -n '.tools/zola' AGENTS.md` both hit; `grep -n 'build.sh' README.md` hits; the documented version equals `cat ZOLA_VERSION`.

## Item 7 — Clean-checkout end-to-end verification (SC-1 full, SC-5)

- **Deliverable:** executed clean-room evidence.
- **RED:** a fresh `git clone` of the current trunk state has no `build.sh` (`test -x build.sh` fails in the clone) — the criterion is unmet until items 1–6 land.
- **GREEN:** none — verification of the assembled items.
- **Instrument:** `git clone` the feature branch (local path clone is sufficient; depth 1) into a temp dir; inside it, with every `zola` binary removed from `PATH`: `./build.sh` exits 0; output contains `index.html`, `404.html`, `search_index.en.js`, `cherokee-new-testament/1-corinthians/0701/index.html`, and `authors/timothy-legg/rss.xml`; `sha256sum` of the tarball fetched during materialization equals `ZOLA_VERSION.sha256`; `timeout 15 ./build.sh serve --port 18812` prints a "Web server is available" line. This run is also SC-5's portability demonstration (musl-static binary, no host-library dependencies, no preinstalled Zola).

## Traceability

| Item | SC |
|---|---|
| 1 | SC-2 |
| 2 | SC-1 (local form), SC-5 (mechanism), SC-3 (entry ownership) |
| 3 | R-2, enables SC-4 |
| 4 | SC-4 |
| 5 | SC-3 |
| 6 | SC-6 |
| 7 | SC-1 (full), SC-5 |

Every SC is covered by at least one item; every item traces to the spec. Surfaces touched: `ZOLA_VERSION`, `ZOLA_VERSION.sha256`, `build.sh`, `config.toml`, `content/_index.md`, `.gitignore`, `deploy.sh`, `AGENTS.md`, `README.md` — exactly the spec's affected-surfaces set (`.tools/` content is materialized, never committed).

## Safety

No destructive operations: the entry writes only under `.tools/zola/` and the build output; `deploy.sh`'s behavior beyond the build step is unchanged; every change is git-revertable. The checksum refusal path fails closed (no build on mismatch).
