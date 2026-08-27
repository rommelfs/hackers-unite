# Visual language

## Gameplay role key

| Role | Shape and motion contract |
|---|---|
| Solid floor / chair row / gantry | Continuous bright top lip and closed full-height support; `SOLID` flag |
| Background audience / equipment | Dark, broken silhouette with no foot-line edge; `DECORATION` flag |
| Cable / electrical trap | Open spikes or zigzag arc, warning ink, never solid; `HAZARD` flag |
| Normal / elite enemy | Red patrol silhouette / expanded many-eyed AV silhouette; fixed software boxes |
| Projectile | Small yellow pulse; power shot is bright and faster, still bounded to one slot |
| Power-up | Four stable silhouettes and colors plus an eight-frame white pulse |
| Stage exit | Closed frame around a bright cyan projection field at far right |

Shape, flag and interaction must agree. Color is secondary information and is
never the sole indication that an object can be collected or causes damage.

The supplied hack.lu 2026 banner and logo crop are the authoritative visual references. Hackers Unite does not reproduce the conference badge or its wording. It extracts a compact game vocabulary from the artwork and recombines it around the game's own title and mechanics.

## Core motifs

| Motif | Game role | C64 treatment |
|---|---|---|
| Broken monumental `2` | Terminal ruin, left portal half | 4x6-character metatile with terminal cavity |
| Broken monumental `0` | Network gate, right portal half | 4x6-character metatile; interior animated separately |
| Green vortex | Active data portal | Three 24x21 multicolor sprite frames or animated character cluster |
| Spider camera | Ground enemy and observer | Two 24x21 sprite orientations |
| Flying camera | Air enemy and searchlight hazard | Multicolor sprite plus optional beam characters |
| Padlock | Access-key collectible | 12x14 readable item sprite |
| Onion | Privacy-route collectible | 12x14 item sprite |
| Chain link | Connection/repair collectible | 12x14 item sprite |
| CRT pedestal | Checkpoint or terminal | 3x3-character environmental object |
| Cable bundles | Structural decoration | Horizontal, vertical and corner tiles |
| Ruined skyline | Parallax/background layer | Repeating black silhouette character modules |

## Palette

The conversion palette is fixed in `assets/c64-palette.ppm`. Gameplay should favor black, dark grey, muted olive and cyan. Green marks active systems and portals. Red and blue are reserved for warnings and device lights. Large black regions are intentional and preserve sprite readability.

## Gameplay affordances

Artwork must communicate the authoritative metatile flags before decoration:

- **Safe ground and landable platforms** have an uninterrupted bright top lip and
  visible supports through the entire 16-pixel metatile collision height.
- **Full blocking walls** use a closed outline and cross-bracing. They never show an
  open lower edge that could suggest a crawl route.
- **Hazards** use sharp cable/arc silhouettes, warning contrast, and no safe-looking
  top lip. They carry `HAZARD` but never `SOLID`.
- **Background audience and chairs** begin with open/black space and never reuse
  the foreground platform silhouette.
- **Decoration** may not sit on the player foot line when its shape resembles an
  obstacle. In particular, non-colliding fallen chairs are not placed on the aisle.
- **Collectibles and enemies** remain sprites; decoration must not imitate their
  silhouettes.

These rules are semantic rather than palette-only. Level 3 changes the shared
multicolor inks, so outline and fill structure must remain readable even when color
meaning changes. The asset manifest lists solid, hazardous, and decorative
metatiles, and `tools/validate_assets.py` verifies their flag contracts.

## Source and derived assets

- `assets/reference/`: untouched supplied references
- `assets/source/hackers-unite-title-concept-v1.png`: ImageGen title composition
- `assets/source/hackers-unite-asset-sheet-v1.png`: ImageGen reusable motif sheet
- `assets/source/motifs/`: deterministic crops from the sheet
- `assets/c64-preview/hackers-unite-title-320x200.png`: nearest-neighbor, fixed 16-color preview

Run `make assets` to regenerate all derived crops and the C64-sized preview. These files are design inputs, not yet packed VIC-II bitmap, character, or sprite data. Phase 2 converts the selected motifs into explicit 8x8 character and 24x21 sprite bytes.
