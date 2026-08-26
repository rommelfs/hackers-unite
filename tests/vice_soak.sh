#!/bin/sh
set -eu

vice="$1"
prg="$2"
log="build/soak/vice.log"

"$vice" -pal -console -warp -sound -debugcart -limitcycles 250000000 -autostartprgmode 1 -autostart "$prg" >"$log" 2>&1 &
pid=$!

i=0
while kill -0 "$pid" 2>/dev/null; do
    i=$((i + 1))
    if test "$i" -ge 600; then
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
        echo "VICE soak test: timeout"
        tail -n 30 "$log"
        exit 1
    fi
    sleep 0.1
done

if wait "$pid"; then
    echo "VICE PAL soak test: OK (7,680 frames / 153.6 emulated seconds)"
else
    status=$?
    echo "VICE PAL soak test: failed ($status)"
    tail -n 30 "$log"
    exit "$status"
fi
