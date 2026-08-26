#!/bin/sh
set -eu

output=$(ca65 -W 1 "$@" 2>&1) || {
    status=$?
    printf '%s\n' "$output" >&2
    exit "$status"
}
printf '%s\n' "$output"
if printf '%s\n' "$output" | rg -qi 'warning:'; then
    echo "ca65-strict: warnings are build failures" >&2
    exit 1
fi
