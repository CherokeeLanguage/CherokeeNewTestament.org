#!/bin/bash

set -e
set -o pipefail

trap 'echo ERROR; sleep 30' ERR

cd "$(dirname "$0")"
BASE="$(pwd)"

cd "$BASE/content"
if [ ! -d Cherokee-New-Testament ]; then mkdir Cherokee-New-Testament; fi
cd Cherokee-New-Testament
for x in *; do
    rm -rf "$x" || true
done

#Mapping original two digit sequences to names.
cp /dev/null book-name-number-map.txt

bookHtml="$BASE"/original/index.html
cp "$bookHtml" index.html
chmod 0644 index.html
pandoc --eol=lf --wrap=preserve -o index.md.tmp --to=gfm --from=html "index.html"
date="$(ls -l --time-style='+%Y-%m-%dT%H:%M:%SZ' "$bookHtml"|cut -f 6 -d ' ')"
weight="$(ls -l --time-style='+%s' "$bookHtml"|cut -f 6 -d ' ')"
pageName="About"
(
cat << EOH
+++
draft=false
date = $date
title = "$pageName - Cherokee New Testament"
weight = $weight

[taxonomies]

authors = ["Timothy Legg"]
categories = []
tags = []

[extra]
+++
EOH
) > index.md

cat index.md.tmp >> index.md
rm index.md.tmp
rm index.html

#Books are two digit sequences
for bookHtml in "$BASE"/original/[0-2][0-9].html; do
    cd "$BASE/content/Cherokee-New-Testament"
    date="$(ls -l --time-style='+%Y-%m-%dT%H:%M:%SZ' "$bookHtml"|cut -f 6 -d ' ')"
    weight="$(ls -l --time-style='+%s' "$bookHtml"|cut -f 6 -d ' ')"
    prefix="$(basename -s .html "$bookHtml")"
    pageName="$(grep '<h1>' "$bookHtml" | perl -p -e 's|<h1>(.*?)</h1>|$1|g')"
    echo "=== BOOK: $pageName"
    printf "$prefix\t$pageName\n" >> book-number-name-map.txt
    
    if [ -d "$pageName" ]; then rm -r "$pageName"; fi
    mkdir "$pageName"
    cd "$pageName"
    if [ -f "$BASE/original/$prefix"_.png ]; then
        cp -p "$BASE/original/$prefix"_.png .
    else
        cp -v -p "$BASE/original/$prefix"0000.png "$prefix"_.png
    fi
    chmod 0644 *.png
    cp -f "$bookHtml" index.html
    chmod 0644 index.html
    perl -p -i -e 's|<head>|<head><meta charset="UTF-8"/>|g' index.html
    perl -p -i -e 's|(<tr><th>.*)$|\1</th></tr>|g' index.html
    perl -p -i -e 's|^<br>$||g' index.html
    perl -p -i -e 's|<th>|<td>|g' index.html
    perl -p -i -e 's|</th>|</td>|g' index.html
    perl -p -i -e 's| width=\d+||g' index.html
    perl -p -i -e 's| border=\d+||g' index.html
    perl -p -i -e 's|<br>| |g' index.html
    pandoc --eol=lf --wrap=preserve -o index.md.tmp --to=gfm --from=html "index.html"
(
    cat << EOH
+++
draft=false
date = $date
title = "$pageName - Cherokee New Testament"
weight = $weight

[taxonomies]

authors = ["Timothy Legg"]
categories = []
tags = []

[extra]
+++
EOH
    ) > index.md

    cat index.md.tmp >> index.md
    rm index.md.tmp
    rm index.html
    
    cwd="$(pwd)"
    #Chapters are four digit sequences.
    for chapter in "$BASE/original/$prefix"[0-9][0-9].html; do
        cd "$cwd"
        folder="$(basename -s .html "$chapter")"
        if [ -d "$folder" ]; then rm -rf "$folder"; fi
        mkdir "$folder"
        cd "$folder"
        date="$(ls -l --time-style='+%Y-%m-%dT%H:%M:%SZ' "$chapter"|cut -f 6 -d ' ')"
        weight="$(ls -l --time-style='+%s' "$chapter"|cut -f 6 -d ' ')"
        chapterPrefix="$(basename -s .html "$chapter")"
        chapterNo="$(echo "$chapterPrefix"|sed "s/^${prefix}0*//")"
        if [ -f "$BASE/original/$prefix"_.png ]; then
            cp -p "$BASE/original/$prefix"_.png .
        else
            cp -v -p "$BASE/original/$prefix"0000.png "$prefix"_.png
        fi
        cp -p "$BASE/original/$prefix"0000.png "$prefix"0000.png
        cp -p "$BASE/original/$chapterPrefix"[0-9][0-9].png .
        chmod 0644 *.png
        cp -p -f "$chapter" index.html
        chmod 0644 index.html
        perl -p -i -e 's|<head>|<head><meta charset="UTF-8"/>|g' index.html
        perl -p -i -e 's|(<tr><th>.*)$|\1</th></tr>|g' index.html
        perl -p -i -e 's|^<br>$||g' index.html
        perl -p -i -e 's|<th>|<td>|g' index.html
        perl -p -i -e 's|</th>|</td>|g' index.html
        perl -p -i -e 's| width=\d+||g' index.html
        perl -p -i -e 's| border=\d+||g' index.html
        perl -p -i -e 's|<br>| |g' index.html
        pandoc --eol=lf --wrap=preserve -o index.md.tmp --to=gfm --from=html "index.html"

        (
        cat << EOH
+++
draft=false
date = $date
title = "$pageName - Chapter $chapterNo - Cherokee New Testament"
weight = $weight

[taxonomies]

authors = ["Timothy Legg"]
categories = []
tags = []

[extra]
+++
EOH
        ) > index.md

        cat index.md.tmp >> index.md
        rm index.md.tmp
        rm index.html

    done
done
