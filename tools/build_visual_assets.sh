#!/bin/sh
set -eu

magick_bin=${MAGICK:-magick}
title="assets/source/hackers-unite-title-concept-v1.png"
sheet="assets/source/hackers-unite-asset-sheet-v1.png"
palette="assets/c64-palette.ppm"
preview_dir="assets/c64-preview"
motif_dir="assets/source/motifs"

mkdir -p "$preview_dir" "$motif_dir"

"$magick_bin" "$title" -filter point -resize '320x200!' +dither -remap "$palette" "$preview_dir/hackers-unite-title-320x200.png"

"$magick_bin" "$sheet" -crop 170x160+30+25 +repage "$motif_dir/spider-drone-front.png"
"$magick_bin" "$sheet" -crop 180x160+200+25 +repage "$motif_dir/spider-drone-side.png"
"$magick_bin" "$sheet" -crop 210x150+390+20 +repage "$motif_dir/flying-drone-wide.png"
"$magick_bin" "$sheet" -crop 200x150+585+20 +repage "$motif_dir/flying-drone-searchlight.png"
"$magick_bin" "$sheet" -crop 690x145+790+20 +repage "$motif_dir/items-lock-onion-chain-lights.png"
"$magick_bin" "$sheet" -crop 730x285+25+170 +repage "$motif_dir/data-vortex-frames.png"
"$magick_bin" "$sheet" -crop 320x365+805+175 +repage "$motif_dir/portal-number-two.png"
"$magick_bin" "$sheet" -crop 350x380+1120+165 +repage "$motif_dir/portal-number-zero.png"
"$magick_bin" "$sheet" -crop 230x215+30+440 +repage "$motif_dir/terminal-pedestal.png"
"$magick_bin" "$sheet" -crop 590x180+270+455 +repage "$motif_dir/cable-modules.png"
"$magick_bin" "$sheet" -crop 1450x170+20+650 +repage "$motif_dir/floor-wall-platform-modules.png"
"$magick_bin" "$sheet" -crop 1450x190+20+825 +repage "$motif_dir/skyline-modules.png"

echo "visual assets: built"
