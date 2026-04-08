# Copyright (c) 2026 Philip Meyer <philip@meyer-devices.com>

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#!/bin/bash

# Usage:
#   Single file: ./adv-update.sh "/path/to/Preset Name.adv" "Device Name.amxd" [1|3]
#   Folder:      ./adv-update.sh "/path/to/Presets/" "Device Name.amxd" [1|3]
# (Use an absolute path for the preset file or folder; device is the .amxd filename only.
#  Third arg is RelativePathType: 1 or 3, default 3.)

ADV_PATH="$1"
AMXD="$2"
REL_PATH_TYPE="${3:-3}"

if [[ -z "$ADV_PATH" || -z "$AMXD" ]]; then
    echo "Usage: $0 <path/to/preset.adv or path/to/presets/> <device.amxd> [1|3]"
    exit 1
fi

if [[ "$REL_PATH_TYPE" != "1" && "$REL_PATH_TYPE" != "3" ]]; then
    echo "RelativePathType must be 1 or 3 (got: $REL_PATH_TYPE)"
    exit 1
fi

# Grep -E patterns for stray absolute paths (/Users/...)
STRAY_PATH_RE='^[ \t]*<Path Value="/Users'
STRAY_BROWSER_RE='^[ \t]*<BrowserContentPath Value=".*/Users'

check_stray_absolute_paths() {
    local f="$1"
    local matches
    matches=$(grep -n -E "($STRAY_PATH_RE|$STRAY_BROWSER_RE)" "$f" 2>/dev/null)
    if [[ -n "$matches" ]]; then
        echo "Warning: stray absolute paths in $f:"
        echo "$matches"
    fi
}

# Escape a string for use as a literal in sed's LHS (BRE). AMXD is expected to be a basename like Foo.amxd.
amxd_sed_lhs_escape() {
    printf '%s' "$1" | sed 's/[.[\\*^$.]/\\&/g'
}

process_adv() {
    local f="$1"
    local amxd_lhs
    amxd_lhs=$(amxd_sed_lhs_escape "$AMXD")
    # Decompress if gzipped
    if file "$f" | grep -q gzip; then
        gunzip -c "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    fi
    # Apply edits
    # Collapse any non-empty RelativePath that points at this device (path ending in /basename.amxd)
    # to just the basename. Leaves .adv chain refs and other RelativePath values unchanged.
    # Do NOT delete every <Type Value="..."/> line: FileRef uses Type, but so does every
    # MxD*Parameter (float/int/enum). A global Type delete strips parameter types and Live
    # falls back to defaults. Only strip absolute <Path> lines under FileRef (portability).
    sed -i '' \
      -e 's|<RelativePathType Value="0" />|<RelativePathType Value="'"$REL_PATH_TYPE"'" />|' \
      -e "s|<RelativePath Value=\"\\(.*\\)/${amxd_lhs}\" />|<RelativePath Value=\"${AMXD}\" />|" \
      -e 's|<RelativePath Value="" />|<RelativePath Value="'"$AMXD"'" />|' \
      -e '/^[[:space:]]*<Path Value="\//d' \
      -e '/^[[:space:]]*<Path Value="[A-Za-z]:\\/d' \
      "$f"
    echo "Done: $f now references $AMXD relatively"
    check_stray_absolute_paths "$f"
}

if [[ -d "$ADV_PATH" ]]; then
    shopt -s nullglob
    count=0
    for f in "$ADV_PATH"/*.adv; do
        process_adv "$f"
        ((count++))
    done
    shopt -u nullglob
    if [[ $count -eq 0 ]]; then
        echo "No .adv files found in $ADV_PATH"
        exit 1
    fi
elif [[ -f "$ADV_PATH" ]]; then
    process_adv "$ADV_PATH"
else
    echo "Not a file or directory: $ADV_PATH"
    exit 1
fi