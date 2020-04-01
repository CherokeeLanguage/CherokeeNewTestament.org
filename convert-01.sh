#!/bin/bash

set -e
set -o pipefail

trap 'echo ERROR; sleep 30' ERR

pandoc -t commonmark +empty_paragraphs --extract-media=../static/images/ --eol=lf --wrap=preserve
