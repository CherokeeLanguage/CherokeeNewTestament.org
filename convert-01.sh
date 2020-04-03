#!/bin/bash

set -e
set -o pipefail

trap 'echo ERROR; sleep 30' ERR

cd "$(dirname "$0")"
BASE="$(pwd)"

outformat="commonmark"
mapfile="$BASE/book-number-name-map.txt"

cd "$BASE/content"
if [ ! -d Cherokee-New-Testament ]; then mkdir Cherokee-New-Testament; fi
cd Cherokee-New-Testament
for x in *; do
    rm -rf "$x" || true
done

#Mapping original two digit sequences to names.
cp /dev/null "$mapfile"

bookHtml="$BASE"/original/index.html
cp "$bookHtml" index.html
chmod 0644 index.html
pandoc --eol=lf --wrap=preserve -o index.md.tmp --to=$outformat --from=html "index.html"

perl -p -i -e 's|\[(.*?)\]\((.*?)\.html\)|\[$1\]\(@/Cherokee-New-Testament/$1/index.md\)|g' index.md.tmp

date="$(ls -l --time-style='+%Y-%m-%dT%H:%M:%SZ' "$bookHtml"|cut -f 6 -d ' ')"
weight="$(ls -l --time-style='+%s' "$bookHtml"|cut -f 6 -d ' ')"
bookName="About"
(
cat << EOH
+++
draft=false
date = $date
title = "$bookName - Cherokee New Testament"
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
    bookName="$(grep '<h1>' "$bookHtml" | perl -p -e 's|<h1>(.*?)</h1>|$1|g')"
    echo "=== BOOK: $bookName"
    printf "$prefix\t$bookName\n" >> "$mapfile"
    
    if [ -d "$bookName" ]; then rm -r "$bookName"; fi
    mkdir "$bookName"
    cd "$bookName"
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
    #perl -p -i -e 's| width=\d+||g' index.html
    perl -p -i -e 's| border=\d+||g' index.html
    perl -p -i -e 's|<br>| |g' index.html
    pandoc --eol=lf --wrap=preserve -o index.md.tmp --to=$outformat --from=html "index.html"
    perl -p -i -e 's|\[(.*?)\]\((.*?)\.html\)|\[$1\]\(@/Cherokee-New-Testament/'"$bookName"'/$2/index.md\)|g' index.md.tmp
(
    cat << EOH
+++
draft=false
date = $date
title = "$bookName - Cherokee New Testament"
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
        #perl -p -i -e 's| width=\d+||g' index.html
        perl -p -i -e 's| border=\d+||g' index.html
        perl -p -i -e 's|<br>| |g' index.html
        pandoc --eol=lf --wrap=preserve -o index.md.tmp --to=$outformat --from=html "index.html"

        (
        cat << EOH
+++
draft=false
date = $date
title = "$bookName - Chapter $chapterNo - Cherokee New Testament"
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

#Post processing fixups

cd "$BASE/content/Cherokee-New-Testament"
perl -p -i -e 's|^(.*\))  +$|* $1\n|' index.md
perl -p -i -e 's|(@/Cherokee-New-Testament/[^\)]*?) ([^\)]*)|$1-$2|' index.md

for book in *; do
    cd "$BASE/content/Cherokee-New-Testament"
    if [ ! -d "$book" ]; then continue; fi
    xbook="$book"
    if [[ "$book" == *" "* ]]; then
        xbook="$(echo "$book"|sed 's| |-|g')"
        mv -v "$book" "$xbook"
    fi
    cd "$xbook"
    perl -p -i -e 's|^(.*\))$|* $1\n|' index.md
    perl -p -i -e 's|(@/Cherokee-New-Testament/[^\)]*?) ([^\)]*)|$1-$2|' index.md
done

# TODO: Fix up image scaling via img tags to be relative to the original size and viewport width.