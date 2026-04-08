#!/bin/bash
# Copyright (c) 2026 Philip Meyer <philip@meyer-devices.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Re-insert <Type Value="N"/> after each <Index/> inside MxDFloatParameter / MxDIntParameter / MxDEnumParameter
# when a buggy adv-update removed those lines. Idempotent: skips if <Type> already follows <Index>.
#
# Usage:
#   ./adv-repair-parameter-types.sh "/path/to/Preset.adv"
#   ./adv-repair-parameter-types.sh "/path/to/Presets/"

set -euo pipefail

repair_adv() {
    local f="$1"
    local tmp lines_before lines_after inserted
    if file "$f" | grep -q gzip; then
        gunzip -c "$f" > "${f}.tmp.repair" && mv "${f}.tmp.repair" "$f"
    fi
    tmp=$(mktemp)
    lines_before=$(wc -l < "$f" | tr -d ' ')
    awk '
        /<MxDFloatParameter/  { param_kind = "0" }
        /<MxDIntParameter/    { param_kind = "1" }
        /<MxDEnumParameter/   { param_kind = "2" }
        /<\/MxD(Float|Int|Enum)Parameter>/ {
            print
            param_kind = ""
            next
        }
        param_kind != "" && /<Index Value=/ {
            match($0, /^[[:space:]]*/)
            indent = substr($0, RSTART, RLENGTH)
            print
            if (getline nextline <= 0) exit
            if (nextline ~ /<Type Value="[012]"/) {
                print nextline
            } else if (nextline ~ /<Name/) {
                print indent "<Type Value=\"" param_kind "\" />"
                print nextline
            } else {
                print nextline
            }
            next
        }
        { print }
    ' "$f" > "$tmp"
    lines_after=$(wc -l < "$tmp" | tr -d ' ')
    inserted=$((lines_after - lines_before))
    if [[ "$inserted" -gt 0 ]]; then
        mv "$tmp" "$f"
        echo "Repaired $f: inserted $inserted <Type> line(s)"
    else
        rm -f "$tmp"
        echo "Skipped $f: no missing parameter <Type> lines"
    fi
}

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <path/to/preset.adv or path/to/presets/> [...]" >&2
    exit 1
fi

for TARGET in "$@"; do
    if [[ -d "$TARGET" ]]; then
        shopt -s nullglob
        count=0
        for f in "$TARGET"/*.adv; do
            repair_adv "$f"
            ((count++)) || true
        done
        shopt -u nullglob
        if [[ $count -eq 0 ]]; then
            echo "No .adv files found in $TARGET" >&2
            exit 1
        fi
    elif [[ -f "$TARGET" ]]; then
        repair_adv "$TARGET"
    else
        echo "Not a file or directory: $TARGET" >&2
        exit 1
    fi
done
