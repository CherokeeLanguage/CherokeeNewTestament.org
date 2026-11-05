#!/bin/sh
# Repo build entry: materializes the pinned Zola (ZOLA_VERSION) into
# .tools/zola/ and builds or serves the site with that binary only.
# Checksum of the fetched release artifact is verified against
# ZOLA_VERSION.sha256; a mismatch refuses to build (fail closed).
set -eu

version="$(tr -d '[:space:]' < ZOLA_VERSION)"
tools_dir=".tools/zola"
zola_bin="$tools_dir/zola"

version_ok() {
    [ -x "$zola_bin" ] && "$zola_bin" --version 2>/dev/null | grep -qF "zola $version"
}

if ! version_ok; then
    echo "Materializing pinned Zola $version ..."
    mkdir -p "$tools_dir"
    artifact="zola-v$version-x86_64-unknown-linux-musl.tar.gz"
    url="https://github.com/getzola/zola/releases/download/v$version/$artifact"
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT INT TERM
    curl -fsSL -o "$tmp/$artifact" "$url"
    checksum="$(cut -d' ' -f1 ZOLA_VERSION.sha256)"
    printf '%s  %s\n' "$checksum" "$tmp/$artifact" | sha256sum -c - >/dev/null
    tar -xzf "$tmp/$artifact" -C "$tmp"
    mv "$tmp/zola" "$zola_bin"
    chmod +x "$zola_bin"
fi

"$zola_bin" --version

if [ "${1:-}" = "serve" ]; then
    shift
    exec "$zola_bin" serve "$@"
fi
exec "$zola_bin" build "$@"
