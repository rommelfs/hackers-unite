#!/bin/sh
set -eu

vice="$1"
prg="$2"
log="build/test/vice.log"

"$vice" -pal -console -debugcart -limitcycles 12000000 -autostartprgmode 1 -autostart "$prg" >"$log" 2>&1 &
pid=$!

i=0
while kill -0 "$pid" 2>/dev/null; do
    i=$((i + 1))
    if test "$i" -ge 100; then
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
        echo "VICE smoke test: timeout"
        tail -n 30 "$log"
        exit 1
    fi
    sleep 0.1
done

if wait "$pid"; then
    echo "VICE PAL smoke test: OK"
else
    status=$?
    echo "VICE PAL smoke test: failed ($status)"
    tail -n 30 "$log"
    exit "$status"
fi
