# CherokeeNewTestament.org

The source code for the website https://cherokeenewtestament.org/

The [original folder](original/) contains a copy of the site pre-conversion to Common Markdown.

The site is generated using [Zola](https://www.getzola.org/), pinned to the
exact release recorded in `ZOLA_VERSION` — currently `0.22.1`, the latest
release compatible with the vendored Zulma theme. Build with `./build.sh` (it
fetches and checksum-verifies the pinned Zola into `.tools/zola/` on first
use); serve locally with `./build.sh serve`. Any pin change re-executes the
compatibility gate first: a current-line Zola binary (the 0.23.x Tera 2
major) fails on the theme's Tera-1 template syntax (`Unknown tag` at
`taxonomy_single.html:3`), while the pinned 0.22.1 builds the full 9,140-file
unit cleanly.

## Deployment (Cloudflare Workers Static Assets)

The site deploys through **Workers Builds**: a merge to `master` triggers a
build + `npx wrangler deploy` automatically; PR branches get preview builds
(inspect one with `npx wrangler preview`). The deploy unit is the assets-only
`wrangler.jsonc` manifest — no Worker script, no bindings — and wrangler is
pinned in `package.json`.

One-time setup (Cloudflare dashboard):

1. Connect the GitHub App to this repository.
2. Worker creation with the exact name `cherokeenewtestament-org` — a name
   mismatch is a builds-fail condition.
3. The build command: `./build.sh` (unset means no build runs and the
   Wrangler config is not consulted for it).
4. Production branch: `master` (the builds default is `main`).
5. Attach the custom domain names `cherokeenewtestament.org` and
   `www.cherokeenewtestament.org` — the attachments create the DNS records
   the zone currently lacks.

Preview-host feeds: Zola 0.22's `--base-url` does not rewrite the built-in
per-taxonomy feed metadata, so a preview build's `authors/*/rss.xml` carries
production URLs; production (`master`) builds carry the correct production
feeds.
