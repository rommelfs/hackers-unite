# Game redesign: the path to the hack.lu stage

Status: approved concept, implementation not started  
Working product name: **Product X** (deliberately a placeholder)

## One-sentence pitch

A hacker makes their way through a recognizably hack.lu conference journey—from a
hotel starting point through the shared conference areas—evades Product X's staff,
agents, traps, and projectiles, gathers material for a live demonstration, and
reaches the stage to present a proof of concept for a remote-code-execution flaw.

The tone is playful conference fiction. Product X and all people remain invented;
the game must not imply a vulnerability in a real product or depict identifiable
people without permission.

## Player promise

The redesign should make three things clear without a manual:

1. **Destination:** the illuminated stage is always the narrative goal.
2. **Progress:** collected PoC components make the talk increasingly ready.
3. **Payoff:** reaching the stage with the required components starts a distinct
   talk/demo finale rather than another generic portal transition.

The moment-to-moment play remains a deterministic PAL platform game: run, jump,
duck/crawl, avoid hazards, use limited attacks, find safer or more rewarding
routes, collect objects, and advance through the hall.

## Fiction and terminology

| Game concept | Presentation |
|---|---|
| Player | The speaker/hacker, represented as an original fictional character |
| World | Hotel and conference spaces leading through recognizable hack.lu areas to the stage |
| Ordinary enemies | Fictional Product X employees trying to delay the talk |
| Advanced enemies | Fictional Product X agents with patrol, blocking, or ranged behaviors |
| Static hazards | Cable tangles, equipment cases, warning barriers, and planted traps |
| Projectiles | Clearly fantastical signal pulses or thrown conference objects |
| Required pickups | Three PoC components: `ENTRY`, `PAYLOAD`, and `TRIGGER` |
| Optional pickups | Data fragments/badges for points and route exploration |
| Rare pickup | Coffee/energy token for an extra life or recovery |
| Exit | Stage stairs or stage access, closed until the PoC is complete |
| Finale | Talk title, short setup animation, PoC execution, applause/system-success beat |

Names shown on screen must fit the C64 status and text budgets. The longer names
above are design vocabulary; final labels may use compact icons or abbreviations.

## Core loop

1. Enter a level of the lecture hall with the stage direction visually legible.
2. Read patrols, traps, projectiles, platforms, and alternate paths.
3. Traverse the rows and aisles while collecting optional score objects.
4. Obtain the level's required PoC component or overcome its gatekeeper.
5. Reach the marked transition toward the stage.
6. Continue with score, lives, and collected talk progress preserved.
7. In the final level, reach stage access with all three components and survive
   the final blocker.
8. Trigger the talk finale, award the completion bonus, then offer replay at the
   next danger rank.

Failure retains the existing Continue/Game Over contract. A respawn must never
erase already persistent pickups from the current run.

## Campaign route and level structure

The journey is divided into distinct location-based levels, not presented as one
homogeneous hallway. Each level introduces its own visual identity, route idea,
enemy mix, hazard combination, and climax. Difficulty rises continuously across
the campaign, but every increase must remain readable, deterministic, and
demonstrably solvable.

### Variable origins and shared route

The campaign can begin in one of four origin modules. After that opening, routes
converge on a shared sequence that carries the player toward the talk:

| Route | Ordered levels |
|---|---|
| Hotel arrival | Hotel entrance → hotel lobby/chill-out area → hack.lu main-room entrance → registration → conference-room entrance and stage route |
| Wake-up | Hotel room → corridor → hotel lobby/chill-out area → hack.lu main-room entrance → registration → conference-room entrance and stage route |
| Restroom escape | Restrooms → corridor → hotel lobby/chill-out area → hack.lu main-room entrance → registration → conference-room entrance and stage route |
| Bar aftermath | Bar → corridor → hotel lobby/chill-out area → hack.lu main-room entrance → registration → conference-room entrance and stage route |

The route must never be chosen by uncontrolled randomness. It can be selected on a
route screen, assigned deterministically by danger rank, or unlocked after a
completed run. The chosen origin changes early geometry, collectibles, enemies,
and jokes, while the common route preserves the clear narrative destination.

### Level roles

1. **Origin level:** hotel entrance, hotel room, restrooms, or bar. It introduces
   movement with a distinct miniature story and cannot be a mere palette swap.
2. **Corridor:** used by the room, restroom, and bar routes. Doors, service carts,
   luggage, and sight-line changes introduce vertical and crawl alternatives.
3. **Hotel lobby and chill-out area:** the first unmistakable social conference
   space, with seating islands, attendees, cables, tables, and optional detours.
4. **hack.lu main-room entrance:** event branding becomes dominant; crowd flow,
   barriers, signage, and Product X blockers raise pressure.
5. **Registration:** badge desks and queues create lanes and choke points. The
   player secures the last access prerequisite while ranged agents appear.
6. **Conference-room entrance and stage route:** chair rows, AV equipment,
   lighting, aisles, lectern, and screen form the final traversal and gatekeeper.
   The stage is visible before it is reachable and hosts the talk finale.

The three PoC components are distributed along the complete route rather than one
per technical layout. A route manifest defines which level owns `ENTRY`, `PAYLOAD`,
and `TRIGGER`, and validation ensures no selected route can omit one.

### Runtime migration

The current runtime has only three layouts. The location list above is the target
campaign, not permission to alias six names onto three visually identical maps.
Implementation therefore proceeds in two capacity-gated increments:

1. Build a three-layout vertical slice covering one origin, one shared conference
   space, and the final stage route to prove the art and narrative direction.
2. Before adding the remaining location levels, design and test an expanded layout
   manifest, loader tables, persistence scope, memory ownership, transition state,
   disk footprint, and automated route selection.

A palette or label swap alone does not count as a new location. Each added level
must meet the same PAL frame, loading, sprite, collision, and solvability gates.

## Recognizable hack.lu identity

The player should recognize that this is hack.lu rather than a generic technology
conference. The authoritative visual source remains the supplied hack.lu 2026
banner and circular-logo references. Their palette and original project-derived
motifs should recur coherently in signage, badges, screens, stage dressing, route
markers, and the finale.

Every shared-route level needs at least two clear conference anchors:

- readable `hack.lu` wayfinding or stage text where the character budget permits;
- the supplied 2026 palette and recognizable project-derived banner/logo motifs;
- attendee badges, lanyards, registration desks, schedules, talk-room signs, and
  chill-out seating appropriate to the location;
- a consistent directional stage symbol that guides the player across levels;
- the hack.lu stage treatment, lectern, projection screen, and audience seating in
  the final level.

Hotel rooms, corridors, restrooms, and the bar establish the journey but must lead
visually into hack.lu: badges, stickers, directional signs, conference bags, or
attendees provide continuity before the main event space is reached.

Authenticity does not mean reproducing a real hotel's floor plan, access controls,
staff, attendee likenesses, private spaces, or security arrangements. Unless the
owner supplies and clears a specific reference, hotel architecture remains an
original fictional layout. The official event identity and supplied references
may anchor the setting; Product X, its vulnerability, its staff, and all incidental
people remain fictional.

## Variety, escalation, and solvability

Each level must differ along at least three axes: traversal geometry, dominant
hazard, enemy behavior, optional scoring route, palette/decoration, or climax.
Later levels should test learned skills in new combinations rather than merely
increasing movement speed or enemy health.

The intended difficulty curve is expressed by campaign position rather than a
fixed three-row table:

| Campaign position | Teaching focus | Escalation | Required fairness proof |
|---|---|---|---|
| Origin | Basic movement, one patrol, one visible location-specific hazard | One mechanic at a time and generous recovery space | Required route works without damage and without advanced attacks |
| Corridor/lobby | Running jumps, crawl routes, route choice | Two learned mechanics begin to overlap | Every route branch rejoins and remains reachable |
| Main-room entrance/registration | Blocking and ranged agents, moving hazards | Short bounded combinations with visible recovery space | Every projectile pattern exposes a safe response window |
| Conference room/stage | Route commitment, mastered hazards, final gatekeeper | Strongest combinations followed by recovery | Complete route and boss pattern work with production physics and no forced hit |

Difficulty may increase through more demanding layouts, shorter but still visible
telegraphs, combined patterns, scarcer safe ground, and optional high-risk score
routes. It must not increase through blind jumps, off-screen shots, random outcomes,
unavoidable spawn damage, misleading collision, excessive enemy health, or inputs
that require faster-than-frame precision.

For every level there must be:

- at least one validated mandatory route from spawn to exit;
- a damage-free solution under normal production physics;
- safe spawn and respawn positions with time to read the next threat;
- reachable required pickups and an exit that cannot deadlock;
- bounded enemy and projectile patterns with repeatable timing;
- recovery space after each major challenge;
- automated reachability/state checks and a human playthrough in PAL `x64sc`.

Optional routes may be harder and may demand mastery, but they cannot contain a
required PoC component. Danger ranks may tighten established patterns only up to
tested caps; they must never turn a valid pattern into an unavoidable one.

## Finale: successful talk

The finale is a short, skippable state sequence, not live gameplay:

1. **Arrival:** the player walks to the lectern; controls and damage are frozen.
2. **Title:** a compact fictional talk title identifies an RCE PoC for Product X.
3. **Demo:** laptop/terminal activity advances through `ENTRY`, `PAYLOAD`, and
   `TRIGGER`; a large `SHELL` or `SYSTEM OPEN` result confirms success.
4. **Reaction:** audience lights or sprites animate and a short success cue plays.
5. **Result:** completion bonus and rank are shown; Fire starts the next run.

No real exploit code, real target details, credentials, commands, or actionable
instructions appear in the animation. It communicates a fictional result only.
The authorized soundtrack attribution and once-per-logical-frame playback contract
remain unchanged.

## Scoring and progression

- **Required PoC components:** unlock progress and award a modest fixed score.
- **Data fragments/badges:** optional, placed on detours and higher-risk routes;
  these are the main exploration score source.
- **Opponents:** reward bypass as well as defeat where possible, so combat is not
  the only optimal play style.
- **Section clear:** fixed bonus.
- **Talk complete:** large fixed bonus plus an optional remaining-lives bonus.
- **Danger rank:** preserves the current endless-loop model and may tighten patrol,
  projectile, and boss timing only within tested limits.

Score objects must be visually distinct from decoration. Required components need
unique silhouettes and a persistent three-part HUD indicator. Nothing that looks
collectible may be non-interactive.

## Enemy and hazard grammar

Every threat needs an anticipation cue, an active state, and a recovery window.
Difficulty should come from combining readable patterns rather than surprise hits.

- **Employee patrol:** walks a fixed platform; contact hurts; can be avoided,
  stomped, or attacked.
- **Blocking agent:** pauses at aisle choke points and periodically opens a safe
  movement window.
- **Ranged agent:** telegraphs aim, fires one bounded pulse, then reloads. Only the
  existing sprite budget may decide whether its projectile can become active.
- **Cable/equipment trap:** fixed metatile hazard, visually distinct from solid
  floor and never inferred from sprite pixels.
- **Falling equipment:** map warning first, falling collision second.
- **Rolling case:** bounded floor motion with a safe jump/read window.
- **Final representative:** a multi-hit gatekeeper with a visible weak area and a
  deterministic, learnable pattern.

New enemy families are explicitly allowed. They should add a genuinely different
decision—timing, positioning, route choice, ducking, jumping, or attack use—rather
than being faster copies of an existing patrol. Only a small, level-specific
selection should be active at once so silhouettes and patterns remain legible.

The fiction may become surreal and grotesque as the player approaches the stage:
for example, an animated badge mass, a cable creature, a many-eyed projector, a
chair swarm, or an absurd compliance monster. Such designs must be original,
stylized, readable at C64 resolution, and clearly fictional. Grotesque artwork
does not relax collision, telegraph, sprite-budget, or solvability rules, and
should avoid realistic gore or identifiable real people.

Employees and agents are obstacles in light fiction, not realistic targets. Avoid
company logos, uniforms associated with real organizations, or realistic weapons.

## Non-negotiable technical constraints

The redesign changes content and presentation, not the runtime contract:

- one deterministic gameplay update per logical 50 Hz PAL frame;
- joystick port 2 and the existing movement/action chords;
- fixed status raster zone and 38-column horizontal scrolling;
- Screen A/B buffering with zero steady-state Color-RAM scroll writes;
- sprite 0 reserved for the player and sprites 1–7 shared by bounded objects;
- no additional simultaneous object promised without a designed sprite multiplexer;
- all interaction through fixed software AABBs and authoritative metatile flags;
- staged layout loading, at most 16 patch records per frozen loading frame;
- SID at `$1800`, BSS at `$2600`, secondary projectile code at `$5500-$5754`,
  respawn renderer code at `$5800`, primary code at `$6000`, and RODATA at `$8000`;
- music play called exactly once per logical frame.

New narrative state must be budgeted before implementation. Prefer reusing the
current persistence byte for the three PoC bits and re-theming existing bounded
objects before allocating new RAM or sprite ownership.

## Delivery plan

Each step ends in a playable, reviewable build. Do not combine the complete
re-theme, new layouts, and finale into one high-risk patch.

### Step 0 — Lock the paper design

- Confirm the fictional player silhouette, tone, compact pickup labels, talk title,
  and whether attacks are signal-themed or slapstick conference objects.
- Choose the first vertical-slice origin and draw its three coarse 64x12 metatile
  diagrams, including spawn, checkpoint, component, optional pickup, hazard,
  enemy, and exit locations.
- Draft the complete route manifest for all four origins and shared locations,
  including deterministic selection/unlock rules and PoC-component placement.
- Inventory all current object IDs, persistence bits, sprite cells, charset cells,
  layout records, RAM, and raster time that can be reused.

**Exit criteria:** a signed-off vocabulary, route sketch, asset list, and budget;
no assembly change is required.

### Step 1 — Narrative shell and HUD

- Add a title/attract screen and a compact mission briefing.
- Replace generic level labels with distinct lecture-hall level labels where space
  permits.
- Show the three PoC components as persistent HUD states.
- Keep gameplay layouts and mechanics otherwise unchanged.

**Exit criteria:** a first-time player can state who they are, where they are
going, and what three things they need.

### Step 2 — Conference visual language

- Create original chair, aisle, signage, lectern, AV, cable, equipment, and stage
  tiles from the supplied hack.lu references without copying other games.
- Define a small reusable hack.lu identity kit for wayfinding, badges, 2026 motifs,
  room signs, registration, stage screen, and lectern treatment.
- Re-theme enemies, hazards, pickups, and projectiles while retaining fixed boxes.
- Validate every collectible affordance and hazard contrast in screenshots.

**Exit criteria:** every vertical-slice screenshot is identifiable as part of a
hack.lu journey without explanatory text; its locations remain distinct, with safe
floor, solid geometry, hazards, and pickups distinguishable at a glance.

### Step 3 — Vertical-slice route

- Implement the chosen origin, a shared conference space, and final stage route in
  the existing three layouts.
- Prove every required component and exit reachable with production physics.
- Add optional scoring detours without forcing blind jumps.
- Give each level at least three of the documented variety axes and validate its
  mandatory damage-free route.
- Preserve the 16-record-per-loading-frame cap.

**Exit criteria:** automated traversal checks plus human play confirm every route,
landing, pickup, respawn, and transition.

### Step 3B — Expanded location campaign

- Implement the capacity work for the expanded layout manifest before adding
  hotel entrance, hotel room, restrooms, bar, corridor, lobby/chill-out area,
  main-room entrance, registration, and conference-room/stage levels.
- Add one location at a time, keeping all previously shipped routes valid.
- Verify every origin reaches the complete shared route and all three PoC parts.
- Reject name-only or palette-only duplicates.

**Exit criteria:** all four deterministic route variants can be completed, each
location is visually and mechanically distinct, and loading/persistence remains
within documented memory and PAL timing budgets.

### Step 4 — Product X encounter pass

- Tune patrol, blocker, ranged, rolling, falling, and gatekeeper patterns to the
  new geometry.
- Add new or grotesque enemy families only where they introduce a distinct,
  readable decision and fit the bounded object, sprite, memory, and raster budgets.
- Ensure telegraphs remain visible amid the conference palette.
- Test object/projectile contention under the seven shared sprite slots.

**Exit criteria:** no invisible attack, unavoidable spawn hit, forced-damage
pattern, collision/artwork mismatch, dropped frame, or sprite overbooking.

### Step 5 — Stage and PoC finale

- Replace the generic terminal success state with the staged talk sequence.
- Consume the complete-PoC condition only at stage access.
- Add the completion score/rank result and replay transition.
- Add deterministic automated hooks for every finale state and skip path.

**Exit criteria:** the complete journey ends in an unmistakable talk/demo payoff,
then returns safely to the existing endless rank loop.

### Step 6 — Balance, polish, and release candidate

- Balance score routes, checkpoints, lives, Continue, boss durability, and ranks.
- Review text and art for fictional Product X consistency and non-actionable PoC
  presentation.
- Perform full PAL soak, disk, screenshot, and (when available) real-hardware tests.

**Exit criteria:** all automated tests pass with zero dropped frames and no VIC
artifacts; screenshots are approved; remaining limitations are documented.

## Validation gate for every implementation step

For any gameplay or rendering step, run:

```sh
make build test
make soak
make disk
```

Also inspect screenshots in PAL `x64sc`. A successful process exit is not enough:
reject assembler/linker warnings, dropped frames, stale columns, split artifacts,
ambiguous hazards, false pickups, and collision that disagrees with visuals.

Narrative-only documentation changes may use documentation and repository checks;
the full emulator gate begins when code or generated assets change.

## Decisions needed before Step 1

1. Final fictional name and visual traits of the speaker.
2. Compact on-screen names/icons for `ENTRY`, `PAYLOAD`, and `TRIGGER`.
3. Fictional talk title; Product X remains a placeholder until explicitly renamed.
4. Desired comic intensity: harmless signal duel, slapstick objects, or a mixture.
5. Whether optional items represent badges, data fragments, or both.

Until these are decided, implementation should use replaceable identifiers and
must not bake a real vendor or product into assets, strings, or mechanics.
