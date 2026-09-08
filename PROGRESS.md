# Command of Nature — Digital Port Progress

## What this is
This Godot project started as a tutorial-built 2-player card game prototype and is
being turned into a digital adaptation of **Command of Nature**, a published
deck-building board game (from the makers of *Here to Slay* / *Casting Shadows*).
Full paper rules are saved as `rules.pdf` at the repo root.

## Reference: earlier implementation attempt
An earlier attempt at this game exists in a different stack (Node/TypeScript, with
Zod-validated types):

https://github.com/Gevork-Manukyan/Command-of-Nature

Card type definitions specifically live at:

https://github.com/Gevork-Manukyan/Command-of-Nature/tree/master/shared-types/src

Useful pieces found there so far:
- `card-types.ts`, `ability-types.ts` — Element/Sage/ItemType enums, and an
  `AbilityAction` enum + `AbilityResult` shape describing abilities as **data**
  (deal damage, add shield, draw, swap position, etc.) rather than hardcoded
  per-card logic.
- `card-classes/*.ts` — a Card class hierarchy: `Card` → `ElementalCard` →
  `ElementalWarriorCard` → `ElementalChampionCard` / `ElementalSageCard`, and
  `Card` → `ItemCard` → `ItemAttackCard`.
- `cards.ts` — factory functions for ~90 named cards (4 Sages, 12 Champions,
  ~36 Warriors, 12 Basics, 10 Attacks, 8 Instants, 4 Utilities) with real stats
  (attack/health/price/row requirement/daybreak flag). **Every card's `ability`
  is still a stub (`() => []`)** — no ability logic was ever actually implemented.
  Stats are directly portable; abilities are not — those need to come from the
  physical cards (photos or memory), not from this old code.
- `card-names.ts` — the full canonical name list for every card in the game,
  useful once we're ready to port the complete roster.

## Decisions made so far
- Abilities will be **data-driven**: cards carry ability *data* (an action + params)
  executed by a shared effect engine, not one script per card.
- The data model is being designed with **4-player/team play in mind** from the
  start (shared AP pools, team formations), even though 2-player interactions get
  built/tested first.
- Godot-specific design choice (diverges from the old TS code): split **static
  template data** from **mutable runtime state**. `CardDefinition` (a `Resource`)
  holds the unchanging template — name, price, art, stats, abilities.
  `CardInstance` (a `RefCounted`) wraps a reference to a `CardDefinition` plus
  per-copy mutable state (current damage, boosts, shields). This matters because a
  deck can contain multiple copies of the same card, each needing independent
  battlefield state.
- The user works in **small increments** they bring themselves — don't get ahead
  of what's explicitly requested, and don't assume scope on unresolved questions.

## Current codebase state

### Original tutorial prototype (pre-existing; still 2-player only, no turn structure)
- `card.gd` — a `Button` with `rank`/`suit`/`face_up` data, `setup()`/`update_display()`.
- `game.gd` — builds a 52-card deck, deals to `PlayerHand`/`OpponentHand`, lets
  Player 1 select+play a card into `PlayArea`. No AP economy, no win condition.
  This is leftover tutorial scaffolding — **not yet wired to the new card system
  below.**

### New Command of Nature card type system (`cards/` folder)
- `cards/card_enums.gd` — `CardEnums`: `Element`, `Sage`, `ItemType`,
  `AbilityAction`, `Team` enums (ported from the old TS enums).
- `cards/ability_effect.gd` — `AbilityEffect` (Resource): `action`, `amount`,
  `target_team`, `target_positions`. The data-driven ability record — not yet
  wired to any actual effect-resolution logic.
- `cards/definitions/card_definition.gd` — `CardDefinition` (Resource, base):
  `card_name`, `price`, `art`.
- `cards/definitions/elemental_card_definition.gd` — `ElementalCardDefinition`
  extends `CardDefinition`: `element`, `attack`, `health`. (Used directly for
  Basic Elementals, which have no ability.)
- `cards/definitions/elemental_warrior_card_definition.gd` —
  `ElementalWarriorCardDefinition` extends `ElementalCardDefinition`: `ability`,
  `row_requirement`, `is_daybreak`.
- `cards/definitions/elemental_champion_card_definition.gd` — extends Warrior:
  + `level_requirement`.
- `cards/definitions/elemental_sage_card_definition.gd` — extends Warrior:
  + `sage`.
- `cards/definitions/item_card_definition.gd` — `ItemCardDefinition` extends
  `CardDefinition`: `item_type`, `ability`.
- `cards/definitions/item_attack_card_definition.gd` — extends Item:
  + `row_requirement`, forces `item_type = ATTACK`.
- `cards/card_instance.gd` — `CardInstance` (RefCounted): wraps a
  `CardDefinition` + `current_damage`/`shield_count`/`boost_count`;
  `get_effective_attack()`, `is_defeated()`.
- `cards/card_names.gd` — `CardNames`: string constants for all 86 canonical
  card names (ported from `card-names.ts`), used everywhere instead of raw
  string literals.
- `cards/card_library.gd` — `CardLibrary`: aggregator across all 5 category
  files below. `all() -> Array[CardDefinition]` (all 86 cards), `get_all() ->
  Dictionary` (keyed by `card_name`, for lookup by name).
- `cards/library/sage_cards.gd` — `SageCards`: all 4 Sages (Cedar/Gravel/
  Porella/Torrent). Every Sage shares identical base stats (price 1, atk 3,
  hp 12, occupies all 3 rows, daybreak) except `element`/`sage` — captured via
  a single private `_make()` helper rather than 4 near-duplicate bodies.
  `all()` and `by_element()`.
- `cards/library/champion_cards.gd` — `ChampionCards`: all 12 Champions (3 per
  faction). `price`/`is_starter` are constant across the category (hardcoded in
  `_make()`); attack/health/rows/level/daybreak genuinely vary per card and are
  passed as parameters. `all()` and `by_element()`.
- `cards/library/basic_cards.gd` — `BasicCards`: all 12 Basic Elementals.
  Discovered every faction reuses the same 3 archetypes — Starter (atk2/hp2/
  price1), Attacker (atk3/hp3/price2), Defender (atk1/hp3/price1) — so there
  are 3 private makers (`_make_starter/_make_attacker/_make_defender`)
  parameterized only by name+element. `all()` and `by_element()`.
- `cards/library/warrior_cards.gd` — `WarriorCards`: all 36 Warriors (9 per
  faction: 3 starters + 6 market-only). Starters always cost 1 gold
  (`_make_starter()` wraps `_make()` and forces that); no other cross-faction
  stat pattern exists here — attack/health/rows/daybreak/price are genuinely
  per-card. `all()` and `by_element()`.
- `cards/library/item_cards.gd` — `ItemCards`: all 22 Items (10 Attacks, 8
  Instants, 4 Utilities). Starter Attacks/Instants are always price 1;
  non-starter Instants are always exactly price 3; Utilities have no shared
  price pattern. Three private makers: `_make_attack/_make_instant/
  _make_utility`. `all()`, `all_attacks()`, `all_instants()`, `all_utilities()`.

**Code style established for this library**: when several cards in a
category share a value for a real game-design reason, bake it directly into a
private `_make()` helper's body rather than declaring a separate top-level
`const` — the maker function is already the one place that value lives, so a
`const` on top adds indirection without reducing duplication. Per-category
`by_element()` helpers are intentionally duplicated (~5 lines each) rather than
factored into one shared generic utility, because GDScript's typed arrays
(`Array[ElementalSageCardDefinition]` vs `Array[ElementalWarriorCardDefinition]`,
etc.) don't convert into each other automatically — a fully shared version
would have to return a loosely-typed `Array` and lose some type safety. Decided
the small duplication was worth keeping the stronger typing.

Verified twice by running headlessly via
`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script <temp script> --quit`:
first for the original 7 example cards (boost/damage math on `CardInstance`
checked out), then again for the full 86-card roster — correct counts per
category (4/12/12/36/10/8/4 = 86), no name collisions in `get_all()`, and spot
checks (Stone Defender, Willow, Melee Shield, Close Strike, all 9 Pebble
Warriors) matched the source data exactly. No permanent test file was kept;
both were one-off scratch verifications, deleted after passing.

## Ability data — now populated for all 74 cards that have one (2026-09-06)

Source: **https://www.unstablegameswiki.com** (community wiki), specifically the
"CNAT - KSE Base Deck - Cards In This Deck" index page and each card's own page
(URL pattern `index.php?title=CNAT_-_<Card_Name>`, spaces→underscores). The wiki
lists a bigger card pool (~50 more cards + a whole "Ritual Command" type) than our
86 — that's out of scope for now, explicitly deferred, see "Not done yet" below.

**Site quirks worth knowing if resuming this**: Cloudflare fronts the site — plain
`curl`/API requests get a JS challenge page and never reach content; only the
real browser gets through. Firing >5 navigations back-to-back with no delay
re-triggers the challenge mid-session — pace requests with a ~2s wait between
navigations (worked reliably up to 5 pages per batch). The wiki also has minor
data-entry errors (e.g. Riptide Tiger/Roaming Razor mislabeled "Elemental
Champion" instead of Warrior, Gravel/Porella both say "Wind Formation") — trust
our existing stats/element assignments over any field that conflicts with them;
only the "Card Texts" ability wording was treated as authoritative.

**The ability schema grew substantially** once real card text was in hand — the
original `AbilityEffect` (action + amount + team + row) couldn't express what's
actually on the cards. Current shape, in `cards/`:
- `card_ability.gd` — `CardAbility`: `trigger` (`CardEnums.AbilityTrigger` — now
  16 values: `DAYBREAK`, `ON_PLAY`, `ON_ATTACK`/`ON_MELEE_ATTACK`/`ON_RANGED_ATTACK`
  (self attacks), `ON_ATTACKED`/`ON_MELEE_ATTACKED`/`ON_RANGED_ATTACKED` (self is
  attacked), `ON_DAMAGE_DEALT`, `ON_DEFEAT_ENEMY`, `ON_DEFEATED`,
  `ON_SHIELD_ADDED`/`ON_SHIELD_REMOVED`, `ON_ENTER_ROW` (self enters a row),
  `ON_ALLY_ENTER_FORMATION`/`ON_ALLY_LEAVE_FORMATION`,
  `ON_DAMAGE_ABOUT_TO_BE_DEALT_TO_ALLY` (redirect effects)), an optional
  `condition` (`AbilityCondition`: subject/stat/comparator/amount — e.g. "if this
  has ≥1 boost"), `is_optional` (for "you may" effects), `effects` (`Array[AbilityEffect]`,
  executed in order), and `raw_text` (the exact wiki wording, kept as a fidelity
  backstop — see below).
- `ability_effect.gd` — `AbilityEffect`: `action` (`CardEnums.AbilityAction`, now
  18 values, added `REMOVE_ALL_BOOSTS_AND_SHIELDS`/`REDIRECT_DAMAGE_TO_SELF`/
  `NEGATE_DAMAGE` beyond the original port), `amount` (used as a flat value, or as
  a **modifier** when `amount_source != FIXED`, e.g. STR-1), `amount_source`
  (`CardEnums.AmountSource`: `FIXED`, `ATTACKER_STRENGTH`, `SELF_DAMAGE_COUNT`,
  `SELF_SHIELD_COUNT`, `DISCARDED_COUNT`), `targets` (`Array[AbilityTarget]` —
  plural, because effects like swaps need two).
- `ability_target.gd` — `AbilityTarget`: `scope` (`CardEnums.TargetScope`: `NONE`,
  `SELF`, `SELF_SAGE`/`ENEMY_SAGE`, `ROW`, `FORMATION`, `DISCARD_PILE`, `HAND`,
  `ATTACKING_ELEMENTAL`), `team`, `rows`, `selection` (`ALL` or `CHOOSE_N`), `count`
  (added per explicit request — "choose up to 2" is a real, recurring pattern,
  not just "choose 1").
- `cards/library/abilities/ability_builder.gd` — `AbilityBuilder`: 4 static
  helpers (`ability()`, `effect()`, `target()`, `cond()`) used by every card
  entry to keep the data compact despite the richer schema.
- `cards/library/abilities/{sage,champion,warrior,item}_abilities.gd` — one
  `get_all() -> Dictionary` (name → `Array[CardAbility]`) per category, wired
  into `CardLibrary.all()`/`get_all()` via `_attach_abilities()`, which assigns
  `card.ability` on every `ElementalWarriorCardDefinition`/`ItemCardDefinition`
  whose name has an entry. Basics correctly get nothing (they have no `ability`
  field at all — confirmed via `"ability" in card` at verification time).

**Known modeling gaps — real, not oversights** (this is *why* `raw_text` exists on
every `CardAbility`, so nothing is silently lost even where the structured
fields are an approximation):
- **Conditional bonus clauses** are not structurally encoded, only the
  guaranteed part of the effect is. E.g. Geo Weasel/Botanic Fangs ("collect 1
  gold, +1 more if it's a Pebble/Leaf Elemental") only encode the base 1 gold.
  Same for the "if the attacking Elemental is a Basic Elemental, add N to its
  STR" clauses on Nature's Wrath/Primitive Strike, and Focused Fury's
  shield-consumption bonus.
- **"Choose A or B" effects** (Thorn Fencer: "Add 1 boost *or* 1 shield") are
  currently encoded as both effects in sequence (AND), not a real choice —
  there's no "pick one of these effects" concept in the schema yet.
- **Contextual targets** ("that Elemental" meaning whichever ally just entered/
  attacked, or "a connected Elemental") are approximated as a row/formation
  pick rather than a true reference to the triggering card — e.g. Current
  Conjurer, Splash Basilisk, Roaming Razor.
- **Multi-effect same-target assumption isn't enforced.** Redstone ("add 1
  boost *and* 1 shield to an Elemental") and Obliterate ("remove
  boosts/shields... then deal 2 DMG to *that* Elemental") each have two
  effects that should hit the *same* chosen card — the data doesn't yet force
  that; each effect's target selection is independent.
- **Row-of-the-triggering-event filters** (Coastal Coyote: "enters your Row
  II" specifically, regardless of where Coastal Coyote itself sits) aren't
  captured as structured data — only in `raw_text`.

None of this blocks having the data; it blocks *executing* it correctly. Any of
these will need revisiting once the effect-resolution engine is actually built
and these cards get played for real — expect the schema to keep evolving at
that point, this isn't assumed to be the final shape.

**Godot gotcha hit twice this session**: after adding new `class_name` scripts
in a **new subfolder** (`cards/library/abilities/`), a plain
`godot --headless --path . --quit` did NOT pick them up for global class
registration (silent — no error, just "not declared" later). Fix: run
`godot --headless --editor --path . --quit` once to force a full editor
filesystem scan, then the normal headless `--script` runs see the new classes.
Worth trying this first if a newly-added `class_name` script is mysteriously
"not declared in the current scope."

## Formation board — data structure only, no visuals yet (2026-09-06)

Before building this, the user shared their old project's actual board
implementation: **websocket-server/src/models/Battlefield/** (`Battlefield.ts` +
`BattlefieldSpace.ts`) in the same GitHub repo. That turned out to use a
**numbered-space model**, not a "rows as unordered bags" model: each formation
is a fixed array of individually-numbered spaces (6 for a 2-player game, 12 for
a 4-player team — confirming the `[2,4,6]` row capacities we'd only inferred
earlier), and each space stores explicit **8-directional connections**
(TL/T/TR/L/R/BL/B/BR) to specific neighboring space numbers. This precisely
answers the rulebook's "connected Elementals" concept (used by swap effects),
which an unordered-row model couldn't have answered correctly.

**Two things learned by cross-checking `Team.ts`/`Player.ts` against
`rules.pdf`, per the user's request to verify consistency**:
1. Their `damageCardAtPosition` calls `removeCard()` on defeat, which just
   nulls that one space — **the rulebook's "shift cards forward to fill
   gaps" rule was never actually implemented** in the old project.
2. Re-reading that rulebook text carefully: "move an Elemental from Row II to
   Row I" doesn't say *which* one when there's more than one candidate — that's
   a **player choice**, not something a data structure can auto-resolve. So
   the shift-forward rule can't just be "auto-compact on removal" the way I'd
   originally assumed; it needs the (not-yet-built) resolver to ask the player.

**What got built**, in `board/`:
- `formation_space.gd` — `FormationSpace` (RefCounted): `space_number`, `row`,
  `neighbors` (`Array[int]`, undirected — simplified from the old code's
  8-directional dict since no card ability actually needs *which* direction,
  only whether two spaces are connected), `card` (`CardInstance` or null).
- `formation.gd` — `Formation` (RefCounted): `spaces` + `row_capacities`.
  - `Formation.new_two_player()` — 6 spaces, rows `[1,2,3]`, adjacency ported
    exactly from the old `initOnePlayerBattlefield()`.
  - `Formation.new_four_player_team()` — 12 spaces, rows `[2,4,6]`, adjacency
    ported exactly from `initTwoPlayerBattlefield()` (all 28 edges hand-verified
    against the original's TL/T/TR/L/R/BL/B/BR dump before porting).
  - `get_card`/`add_card`/`remove_card`/`move_card`/`swap_cards` — direct
    space-number operations, matching the old `Battlefield` API shape.
  - `are_connected(a, b)` — the adjacency query the old model couldn't
    conveniently offer without manually reading 8 dict keys.
  - `get_row_spaces`/`get_row_cards`/`is_row_full`/`has_space` — row-level
    queries (needed by `AbilityTarget`'s `ROW`/`FORMATION` scopes from the
    ability data work).
  - `get_valid_summon_spaces() -> Array[int]` / `summon(card, space_number) -> bool`
    — the *row* restriction is deterministic (must be the frontmost row that
    has any empty space, per the rulebook), but **which specific space within
    that row is a player choice**, not something the board should decide
    unilaterally (corrected after an initial version auto-picked the
    lowest-numbered space — the user caught this). `summon()` validates the
    chosen space is actually one of the currently-legal targets before placing.
  - `get_sage()`/`has_sage()` — scans for whichever `CardInstance`'s
    `definition` is an `ElementalSageCardDefinition`; needed for `SELF_SAGE`/
    `ENEMY_SAGE` target scopes and the "no Sage = you lose" condition.
  - Deliberately **no auto-compaction on `remove_card`** — matches the old
    reference's actual behavior, and is correct per the player-choice finding
    above. The resolver will need to detect "a row needs filling" and prompt
    for which card moves, then call `move_card()` itself.

Verified headlessly: adjacency spot-checks against the hand-derived edge list
for both formation sizes, a full 2-player setup reproducing the old
`Team.initBattlefield` space assignments (Basics at 1/2/3, Sage at 5, Warriors
at 4/6 — center/left/right of Row III, matching the rulebook's setup diagram),
summon-when-full returning -1, remove-then-summon landing back in the freed
space, and swap_cards exchanging two specific cards. No visual scene yet —
explicitly deferred; this pass was scoped to the data structure only.

## Target resolution — first piece of the resolver (2026-09-06)

Every `AbilityEffect` has `targets: Array[AbilityTarget]`, but nothing turned
those into actual board positions yet. Built that piece, in `resolver/`:

- `target_context.gd` — `TargetContext`: bundles what resolution needs beyond
  the target itself — which `Formation` is "self" vs "enemy" (from the
  resolving player's POV), the `source_card` (for `SELF` scope — the ability's
  owner), and `attacking_card` (for `ATTACKING_ELEMENTAL` scope — the card
  currently attacking, when an Attack Command is being resolved).
- `target_resolver.gd` — `TargetResolver`, two static functions:
  - `get_candidates(target, context, require_occupied=true) -> Array[int]` —
    resolves a target's scope/team/rows into actual matching space numbers.
    `SELF`/`SELF_SAGE`/`ENEMY_SAGE`/`ATTACKING_ELEMENTAL` resolve to a single
    space (via `Formation.find_space_of()`/`get_sage()`); `ROW`/`FORMATION`
    resolve to every matching space, filtered by whether it's occupied —
    default is occupied (matches "an Elemental in your Row I"-style wording),
    but effects that place a card *into* a formation (e.g. Komodo Kin's move-
    from-discard) will need `require_occupied=false` to find open spots.
    `DISCARD_PILE`/`HAND` correctly return empty + a `push_error` — no
    Hand/Discard data model exists yet, so this is an honest "not implemented,"
    not a silent wrong answer.
  - `validate_choice(target, chosen, context, require_occupied=true) -> bool`
    — checks a specific choice is actually legal: every chosen space must be
    a real candidate, and the count must respect `ALL` vs `CHOOSE_N`/`count`.
  - Follows the same pattern `Formation.summon()` was corrected to use: expose
    *what's legal*, take the caller's *choice* as a parameter, and validate it
    — never decide on the caller's behalf. See "board player-choice" note.

Verified against two real cards from the ability library (Slumber Jack's
Row-I boost target, Oxen Avenger's enemy-formation damage target) resolving
correctly against a populated `Formation`, plus every scope/occupancy/
selection-count combination individually.

**Not yet built**: the actual effect *execution* (taking a resolved target and
an `AbilityAction` and mutating game state — damage, boosts, draws, moves,
etc.), and anything that decides *when* a `CardAbility` should fire (trigger
detection/event wiring). Also still missing: a Hand/Discard/Deck model, which
`DISCARD_PILE`/`HAND` targeting needs before it can do anything.

## Hand / Discard / Deck / Removed-pile models (2026-09-06)

Built in `zones/`:
- `card_zone.gd` — `CardZone`: a plain ordered `Array[CardDefinition]` with
  `add`/`add_cards`/`remove_at`/`remove_card`/`get_all`/`take_all`/`size`/
  `is_empty`/`clear`. Used directly (no subclass needed) for **Hand**,
  **Discard Pile**, and the **Removed-From-Game pile** (defeated Elementals
  and sold cards — per the rulebook and the old `Team.removedCards`, these
  never come back, unlike discard). Holds `CardDefinition`, not
  `CardInstance` — a card's damage/shield/boost state only exists on the
  Formation and resets when it leaves (re-summoning later makes a fresh
  `CardInstance`).
- `deck.gd` — `Deck extends CardZone`, adds `shuffle()`, `draw(discard_pile)`,
  and `add_cards_to_bottom(cards)`. Also doubles as the base for the
  **Elemental/Command Market decks** (confirmed with the user) — those don't
  need `draw()`'s discard-reshuffle (they're refreshed differently: spend
  gold to move the 3 face-up cards to the *bottom* of that market's deck,
  then reveal 3 new ones — that's what `add_cards_to_bottom()` is for), but
  do need plain shuffle+draw to fill their face-up slots. The actual Market
  wrapper (face-up display, buy/sell/refresh) isn't built yet.

**Bug fixed vs. the old reference**: `drawCardFromDeck` in the old TS project
just throws when the deck is empty — no reshuffle-from-discard, despite the
rulebook being explicit about it. `Deck.draw()` implements the rule correctly:
shuffles the given discard pile into the deck first if the deck is empty,
returns null only if both are empty.

**Checked and confirmed with the user**: 4-player mode does NOT let a player
act on their teammate's hand — the rulebook only grants *visibility* ("you may
look at your teammate's hand"), not the ability to play from it. What's
actually shared in 4-player mode is the combined AP pool and the team's
formation (either teammate can attack with any Elemental in the shared
formation, just not the same one twice in a turn). So there's no "play from
teammate's hand" mechanic to build — each player's hand stays exclusively
theirs to play from.

**`TargetResolver` extended** to actually resolve `HAND`/`DISCARD_PILE`
(previously explicit stubs): `TargetContext` gained `self_hand`/`enemy_hand`/
`self_discard_pile`/`enemy_discard_pile` (`CardZone` references — enemy-side
ones added for symmetry with `ROW`/`FORMATION`, even though no card currently
targets an opponent's hand/discard). Resolving these scopes returns *indices
into that zone's card list* rather than Formation space numbers — there's no
shared identifier space between a board and a flat zone, documented clearly
on `get_candidates()` so this doesn't get confused later.

Verified: `CardZone` add/remove/take_all, `Deck` shuffle/draw, the
discard-reshuffle-on-empty fix, both-empty returns null, `add_cards_to_bottom`
ordering, and `HAND`/`DISCARD_PILE` resolution against real ability data
(Petal Mage's move-from-discard-to-hand target).

## Effect execution (2026-09-06)

Built `resolver/effect_executor.gd` + `resolver/effect_context.gd` +
`zones/gold_pool.gd` — the piece that actually mutates game state once a
target has been resolved and chosen, instead of just describing where an
effect applies.

- `zones/gold_pool.gd` — `GoldPool`: `amount`/`max_amount`, `add()`/`remove()`
  clamp to the rulebook's cap (12 for 2-player, 20 for 4-player team) —
  matches the old `Team.ts` behavior of silently capping rather than erroring.
- `resolver/effect_context.gd` — `EffectContext`: wraps a `TargetContext` plus
  what execution needs beyond targeting — `self_deck`/`self_gold` (for DRAW/
  COLLECT_GOLD), `self_removed_pile`/`enemy_removed_pile` (defeated cards'
  permanent home), and `last_discarded_count` — a running value carried
  *between* effects in the same `CardAbility`, since several cards read
  "discard up to N... then X for each card discarded" (Oak Lumbertron, Ruby
  Guardian, Forage Thumper) and the second effect needs to know how many the
  first one actually discarded.
- `resolver/effect_executor.gd` — `EffectExecutor.execute(effect,
  chosen_per_target, context, destination_space=-1)`. `chosen_per_target` has
  one `Array[int]` entry per `effect.targets[i]` (validate each with
  `TargetResolver` first — this class re-validates nothing). Implements all
  13 "direct mutation" actions: `COLLECT_GOLD`, `DRAW`, `DEAL_DAMAGE` (including
  defeat → remove from Formation → add to the removed pile), `ADD_SHIELD`/
  `ADD_BOOST`, `REMOVE_ALL_DAMAGE`, `REMOVE_ALL_BOOSTS_AND_SHIELDS`,
  `SWAP_FIELD_POSITION`, and all 6 `MOVE_*` actions between field/hand/discard
  (moving off the field converts a `CardInstance` back to a bare
  `CardDefinition`; moving onto the field wraps one in a fresh `CardInstance`,
  consistent with state resetting when a card leaves the board).

**Deliberately deferred**: the 5 actions that modify an *in-progress attack*
rather than mutating state directly — `REDUCE_DAMAGE`, `NEGATE_DAMAGE`,
`DONT_REMOVE_BOOST`, `DONT_REMOVE_SHIELD`, `REDIRECT_DAMAGE_TO_SELF`. These
only make sense inside a combat-resolution sequence (base damage → +boosts →
−shields → −Instant reductions → apply) that doesn't exist yet — calling
`execute()` on one of them `push_error`s with a clear "needs combat
resolution" message rather than silently no-oping.

**Two real bugs found and fixed while building this**:
1. **Ruby Guardian's data was wrong.** "Add 2 shields... for each card
   discarded" is `2 × discarded_count` (multiplicative), but it was encoded
   with the same `amount` field used for additive cases like "STR − 1",
   giving `discarded_count + 2` instead — coincidentally right at exactly 2
   discards, wrong everywhere else. Fixed by adding a proper `multiplier`
   field to `AbilityEffect` (`resolved = base * multiplier + amount`,
   multiplier defaults to 1) and correcting Ruby Guardian's entry.
2. **`EffectExecutor` initially duplicated `TargetResolver`'s scope-to-
   formation logic, and got it wrong.** `AbilityTarget.team` defaults to
   `ENEMY` and is meaningless for `SELF`/`SELF_SAGE`/`ATTACKING_ELEMENTAL`
   scopes (`TargetResolver` already ignores it for those) — but a first draft
   of `EffectExecutor` read `target.team` directly for every scope, so any
   self-referential ability (Horned Hollow, Calamity Leopard, Splinter
   Stinger, Moss Viper, Jade Titan's Sage target, and others) silently
   mutated the wrong formation. Root cause was two files independently
   deciding how to interpret a target's scope. Fixed by extracting
   `TargetResolver.formation_for(target, context) -> Formation` as the one
   shared, public source of truth; `EffectExecutor` now calls that instead of
   re-deriving the rule (confirmed via audit: every `ROW`/`FORMATION`/`HAND`/
   `DISCARD_PILE` target in the library already sets `team` explicitly — the
   unset default only ever silently applied to scopes that don't use it).

Verified end-to-end: gold clamping, draw shrinking the deck, boost/shield
mutation reflected in `get_effective_attack()`, damage correctly defeating and
relocating a card to the removed pile, a real swap, all 6 move variants
(including the Oak-Lumbertron-style 1× and Ruby-Guardian-style 2× multiplier
cases side by side, proving the fix), move-to-field via a validated
`get_valid_summon_spaces()` destination, and the combat-modifier stub erroring
without crashing.

## Combat resolution (2026-09-06)

Built `resolver/combat_resolver.gd`, plus a real fix inside
`EffectExecutor._deal_damage` discovered while working this out.

**Shield rule was missing entirely, and it's more general than "combat."**
The rulebook's shield token rule ("each shield reduces incoming DMG by 1...
after an Elemental with shields on it is dealt *any* DMG, remove all
shields") applies to *any* source of damage, not just Attack Commands — so it
belongs in `EffectExecutor._deal_damage` itself (it now reduces the incoming
amount by `shield_count`, floors at 0, and always clears shields regardless
of whether the floored damage was 0), not gated behind combat resolution.
Confirmed against the rulebook's own worked example (3 shields vs. 1 DMG →
shields clear, 0 DMG taken) and a non-combat direct-damage test (e.g. what
Frostfall Emperor's ON_ENTER_ROW would do).

**What's actually combat-specific**, in `CombatResolver.resolve_attack(attack_effect,
chosen_per_target, context, instant_effects=[])`:
- Computes base attack damage via `EffectExecutor.resolve_amount()` (made
  public for this — same "one shared function, not two independent
  re-derivations" principle as `TargetResolver.formation_for` from the
  effect-execution pass).
- Applies the defending player's chosen Instant Command responses:
  `REDUCE_DAMAGE` effects subtract their resolved amount, a `NEGATE_DAMAGE`
  effect zeroes it outright, floored at 0. Which Instants (if any) got played
  is the caller's decision, passed in — this class never chooses on the
  player's behalf, consistent with everywhere else in this codebase.
  Confirms the rulebook's note that Utility Command damage can't be Instant-
  reduced: callers just shouldn't route Utility damage through this function.
- Builds a `.duplicate()`d copy of the attack effect with the final computed
  amount (as `FIXED`) and hands it to `EffectExecutor.execute()` — so shield
  reduction, defeat, and removal-to-the-removed-pile all still happen through
  the one general path, not reimplemented here. `.duplicate()` matters:
  mutating the original `AbilityEffect` in place would corrupt the shared
  `CardDefinition` singleton for every future play of that card.
- Clears the attacker's boosts after the attack, unconditionally — per the
  rulebook this happens whenever an Elemental attacks, independent of whether
  damage actually landed (confirmed: still clears after a fully-negated hit).

**Still not handled** (needs trigger detection to know *when* they apply, not
just what they do): `DONT_REMOVE_BOOST` (e.g. Calamity Leopard's own
attacker-side ability), `DONT_REMOVE_SHIELD`, `REDIRECT_DAMAGE_TO_SELF`
(King Crustacean/Terrain Tumbler). `EffectExecutor.execute()` still
`push_error`s clearly on all 5 combat-only actions if called directly,
distinguishing "use CombatResolver instead" (REDUCE_DAMAGE/NEGATE_DAMAGE)
from "needs trigger detection" (the other 3).

**Also fixed while here**: a Godot gotcha, not a logic bug — `var x := max(a, b)`
triggers a "type inferred from Variant" warning-treated-as-error in this
project's editor scan, because the global `max()`/`min()` are untyped/
variadic. Fixed by using the explicitly-typed `maxi()`. Worth remembering if
a future `:=` assignment from `max()`/`min()` mysteriously fails to load.

Verified end-to-end: the shield-rule fix against a non-combat direct-damage
case, a full attack with boosted attacker + shielded defender defeating the
target and relocating it to the removed pile, boosts clearing after
attacking, a Melee-Shield-style `REDUCE_DAMAGE` instant combining correctly
with the defender's own shields, a negate-damage instant still clearing
attacker boosts despite dealing 0, and real card data (Close Strike vs. Melee
Shield) end-to-end.

## Trigger detection (2026-09-06)

Built the piece that decides *when* a `CardAbility` is currently eligible to
fire, in `resolver/`, plus one real data gap found and fixed along the way.

**Data gap**: no card had an `attack_type` (melee/ranged) at all, even though
several triggers (`ON_MELEE_ATTACK`/`ON_RANGED_ATTACK`) depend on knowing it,
and the wiki had captured it for all 10 Attack cards without it ever being
stored. Added `CardEnums.AttackType` and an `attack_type` field on
`ItemAttackCardDefinition`, populated from the original wiki research (Close
Strike/Focused Fury/Nature's Wrath/Reinforced Impact = melee; the other 6 =
ranged).

- `resolver/condition_evaluator.gd` — `ConditionEvaluator.evaluate(condition,
  source_card)`: the first thing to actually check an `AbilityCondition`
  against anything. Every condition in the library so far is `subject=SELF`
  checking `BOOST_COUNT`/`SHIELD_COUNT` on the ability's own owner (Vix
  Vanguard, Granite Rampart) — that's what's implemented; `GOLD`/`HAND_SIZE`
  need a `GoldPool`/`CardZone` rather than just a card and aren't used by any
  current card, so they `push_error` rather than guess.
- `resolver/trigger_detector.gd` — `TriggerDetector`: given a trigger type,
  finds every currently-eligible `(card, ability)` match across a
  `Formation` (`find_eligible`), or checks one specific card
  (`find_eligible_on_card`). "Eligible" = trigger matches, the card is
  *currently* positioned in one of its allowed rows (the wiki's "Row
  Required to Use Daybreak/Trigger" applies to both Daybreak and
  event-triggered abilities alike — this only checks Elemental cards, since
  Item cards' own "Row Required to Use" is a different, not-yet-built
  card-play validation), and its condition (if any) passes. Pure detection —
  doesn't fire anything or decide whether an optional ability gets used.
  `has_eligible_effect(card, triggers, action, formation)` is the convenience
  `CombatResolver` needed: "does this card have an eligible ability among
  these triggers containing an effect with this action."
- **`CombatResolver.resolve_attack()` updated**: now takes an `attack_type`
  parameter and uses `TriggerDetector` to check whether the attacker has an
  eligible `DONT_REMOVE_BOOST` ability among `ON_ATTACK` and whichever of
  `ON_MELEE_ATTACK`/`ON_RANGED_ATTACK` matches — if so, boosts survive the
  attack instead of clearing. This is the first of the 5 previously-deferred
  combat-modifier actions to actually work (Calamity Leopard).

**Still deferred, deliberately**: `DONT_REMOVE_SHIELD` (zero cards use it —
nothing to wire against) and `REDIRECT_DAMAGE_TO_SELF` (King Crustacean and
Terrain Tumbler have *different* redirect mechanics — one involves a position
swap, one doesn't — and both require the player to opt in, which needs its
own explicit parameter once a caller exists to decide it; detection alone
isn't the missing piece there).

**Test-writing gotcha worth remembering**: constructing a card via e.g.
`WarriorCards.slumber_jack()` directly only gives you its *stats* — abilities
only get attached when going through `CardLibrary.get_all()`/`all()` (see
`_attach_abilities()`). Hit this firsthand: an early verification pass built
cards the wrong way and every trigger check silently came back empty. Always
pull test cards from `CardLibrary.get_all()` for anything ability-related.

Verified: condition evaluation (both branches, null-passes), the new
`attack_type` data, a `DAYBREAK` scan across three cards correctly excluding
the one in an ineligible row, a condition-gated trigger (Vix Vanguard
eligible with a boost, not without), `DONT_REMOVE_BOOST` eligibility
including the row-eligibility check, and the full `CombatResolver`
integration side by side — Calamity Leopard keeps its boosts after attacking,
Acorn Squire (no such ability) still loses them as normal.

## Combat now fires the attacker's other abilities, not just DONT_REMOVE_BOOST (2026-09-06)

`CombatResolver.resolve_attack()` previously only checked for `DONT_REMOVE_BOOST`
and otherwise ignored the rest of an attacker's on-attack-family abilities
entirely — Acorn Squire's gold collection, Jade Titan's shield-to-Sage, etc.
never actually happened. Closed that gap.

**New behavior**: after applying damage, it now finds and fires the
attacker's eligible abilities on `ON_ATTACK`/whichever of
`ON_MELEE_ATTACK`/`ON_RANGED_ATTACK` matches `attack_type` (now a required
parameter), then `ON_DAMAGE_DEALT` (only if some target's `current_damage`
actually increased — checked via a before/after snapshot, not just "was
amount > 0 pre-shields", since shields can floor it to nothing), then
`ON_DEFEAT_ENEMY` once per target this specific attack defeated (matches the
rulebook's "each time you defeat" leveling language — a multi-defeat attack
fires it multiple times, though nothing consumes that yet since leveling
isn't built).

**Ordering matters and was deliberate**: boosts are cleared *before* firing
these triggers, not after — otherwise an ability that adds a fresh boost
after dealing damage (Splinter Stinger) would have it immediately stripped
by this same attack's own clear step. Verified this specifically: Splinter
Stinger starts with 2 boosts, attacks, ends with exactly 1 (the pre-existing
2 cleared, then its own ability adds 1 back) — not 3, not 0.

**The "needs a real choice" split**: an ability only auto-fires if every one
of its effects resolves without ambiguity (`NONE`/`SELF`/`SELF_SAGE`/
`ENEMY_SAGE`/`ATTACKING_ELEMENTAL` scopes — there's exactly one legal
answer). Anything with a `ROW`/`FORMATION`/`DISCARD_PILE`/`HAND`-scoped
effect (Lumber Claw choosing which enemies to hit, Roaming Razor choosing a
swap partner, Komodo Kin choosing a discard card *and* a destination space)
gets returned in `resolve_attack()`'s new return value — a list of
`{card, ability}` entries needing target resolution, same shape as
`TriggerDetector.find_eligible()` — rather than silently skipped or guessed
at. `COMBAT_MODIFIER_ACTIONS` (the 5 originally-deferred actions) are
excluded from "things to auto-fire or defer" entirely, since they're applied
as modifiers elsewhere in this function, not as standalone effects — this is
also what stops Calamity Leopard's ability (which is *only* a
`DONT_REMOVE_BOOST` effect) from being wrongly treated as "nothing to do,
but let's error about it anyway."

Verified: Acorn Squire's gold collection, Jade Titan's shield-to-its-Sage,
Splinter Stinger's boost-survives-the-clear ordering, Horned Hollow's
self-damage-clear firing only after an actual defeat, Calamity Leopard still
correctly keeping boosts with zero pending/errors, and Lumber Claw + Komodo
Kin both correctly deferring instead of executing or crashing.

## Market (2026-09-06)

Built `market/market.gd` — the Elemental and Command Markets from Phase III
(buy/sell/refresh), backed by `Deck`/`GoldPool` from `zones/` as intended
when those were built.

- `Market.new_elemental_market()` / `Market.new_command_market()` — filter
  `CardLibrary.all()` by type + `is_starter == false`. This is the payoff of
  keeping `is_starter` as a real, careful distinction rather than folding it
  into price: every Sage/Champion is always `is_starter=true`, so filtering
  the *entire* card pool this way naturally produces exactly "all Elementals/
  Commands that don't belong to a Sage pack" (the rulebook's own phrasing)
  with no need to hand-pick which categories to exclude. Verified counts:
  32 cards for the Elemental market (8 non-starter Basics + 24 non-starter
  Warriors), 15 for Command (8 non-starter Attacks + 3 non-starter Instants +
  4 Utilities, which are never part of a Sage pack at all).
- `buy(index, gold)` / `can_afford(index, gold)` — pay the face-up card's
  price, remove it, refill from the deck. Returns the bought `CardDefinition`
  and stops there — what happens next (discard pile, or paying the separate
  `ELEMENTAL_DIRECT_SUMMON_SURCHARGE` to summon it straight into the
  formation) is the caller's decision, consistent with everywhere else in
  this codebase.
- `refresh(gold)` / `can_refresh(gold)` — moves the current face-up cards to
  the *bottom* of the deck (not discarded — `Deck.add_cards_to_bottom()`,
  built during the Hand/Discard/Deck pass specifically for this) and reveals
  3 new ones for `REFRESH_COST` gold.
- `Market.sell_value(card)` — `ceil(price / 2)`. The rulebook states this as
  the general rule, then separately calls out that Sage-pack cards always
  net exactly 1 gold when sold — those two statements turn out to agree for
  every `is_starter` card in the library (they're all price 1, and
  `ceil(1/2) = 1`), so one formula covers both without a special case.

Verified: both markets' total pool sizes and composition (no Sage/Champion/
starter card ever appears), buying (price deducted, slot refilled, deck
shrinks), buying without enough gold correctly failing, refresh (net deck
size unchanged since cards return to the bottom rather than vanishing), and
sell values for a starter and two different non-starter prices.

## Turn / AP economy (2026-09-06)

Built the piece that ties everything else together into an actual playable
turn: `player/player_state.gd` + `player/turn.gd`, plus a prerequisite
refactor (`resolver/ability_firer.gd`) and one real ordering bug caught and
fixed before it shipped.

**Prerequisite refactor**: `CombatResolver` already had private "fire this
ability, or defer it if it needs a target choice" logic, and Daybreak
activation needed the exact same thing. Rather than reimplementing it a
second time (the same category of mistake as the earlier
`TargetResolver`/`EffectExecutor` duplication bug), extracted
`resolver/ability_firer.gd` — `AbilityFirer.fire(ability, context)` — as the
one shared place that logic lives, refactored `CombatResolver` to call it,
and re-verified all the existing combat-trigger tests still passed
identically before building anything new on top. One refinement made while
extracting it: `fire()` now stops at the *first* effect needing a choice and
returns it plus everything after it, in order, rather than deferring only
that one effect — needed for chains like Ruby Guardian's "discard up to 2,
then add 2 shields for each discarded," where the second effect's amount
depends on the first one's actual result and can't resolve out of order.

- `player/player_state.gd` — `PlayerState`: bundles one player's Formation,
  Hand, Deck, Discard/Removed piles, and Gold. Scoped to 2-player
  deliberately — 4-player team mode shares Formation *and* Gold at the team
  level (both teammates act on the same ones) while Hand/Deck/Discard/
  Removed stay individual, which is a different composition than "one
  bundle per player," not built yet.
- `player/turn.gd` — `Turn`: phase tracking (`DAYBREAK → ACTIONS → MARKET →
  CLEANUP` via `advance_phase()`), AP tracking (4 for 2-player), and the
  rulebook's per-turn limits (each Daybreak ability once, one faction action,
  each Elemental attacking at most once). A fresh `Turn` per turn, not a
  reset — the caller starts a new one for whoever goes next.
  - **Daybreak**: `get_available_daybreak_abilities()` / `use_daybreak_ability()`
    — thin wrappers around `TriggerDetector` + the new `AbilityFirer`.
  - **Standard actions**: `draw_card()`, `summon_from_hand()`,
    `swap_connected()`, `play_command()` (Instant/Utility, via `AbilityFirer`),
    `play_attack_command()` (validates the attacker is on the formation,
    hasn't attacked yet this turn, and is in a row the specific Attack Command
    allows, then delegates to `CombatResolver`).
  - **Faction actions**: only the AP cost + once-per-turn limit are tracked
    (`can_use_faction_action()`/`spend_faction_action_ap()`) — what a
    faction action actually *does* depends on the acting Sage and hasn't
    been researched yet (see "next options" below).
  - **Market phase**: `buy_from_market()`, `buy_and_summon_from_market()`
    (the rulebook's pay-2-more-to-summon-directly option),
    `sell_from_hand()`, `refresh_market()` — thin wrappers around `Market`.
  - **Cleanup**: `discard_from_hand()`, `draw_to_hand_size()`,
    `can_end_cleanup()` (gates ending the turn on hand size ≤ 5).

**Real bug caught before it shipped**: every action method originally spent
AP *before* validating whether the action was actually legal — so an
illegal swap (spaces not connected) or an attack from the wrong row would
still burn the player's AP even though nothing happened. Traced this while
writing the very first test scenario, before ever running it. Fixed by
reordering every method to validate fully first and spend AP only once the
action is guaranteed to succeed — then specifically re-verified with a
deliberately-illegal swap and a deliberately-illegal repeat-attack, both
confirmed to leave AP untouched.

Verified with a full simulated turn against real card/market data: Daybreak
(Cedar collects gold, reusing it correctly rejected), Actions (draw, an
actual attack via Close Strike that defeats a real target *and*
auto-fires Acorn Squire's own gold-collecting on-attack ability through the
now-shared `AbilityFirer`, a legal swap, an illegal swap correctly rejected
without costing AP, AP exhaustion), Market (buy, sell), and Cleanup (draw
back up to 5, `can_end_cleanup` gating, a clean `advance_phase()` finish).

## Game setup / initialization (2026-09-06)

Built `player/player_setup.gd` — `PlayerSetup.new_player(sage_name,
chosen_warrior_names, goes_first)` builds a real starting `PlayerState`
following the rulebook's setup steps exactly, instead of every prior
verification hand-building the starting state directly.

**Data correction found while building this**: the rulebook states a Sage
pack has exactly **5 Command cards**. Checking the wiki's per-card counts —
Close Strike (2 per faction deck) + Far Strike (2 per faction deck) + 1
faction-specific Charm = 5, exactly. But `Natural Restoration` was also
marked `is_starter=true`, and its wiki page *also* claims "1 in each faction
deck," which would make 6. Natural Restoration's own "Deck:" field
categorizes it as **Sand & Wind Expansion**-primary (unlike Melee Shield/
Natural Defense/Ranged Barrier, which explicitly say "Command Market") — so
its appearance in the 4 base faction decks looks like a later unified-print
artifact the original rulebook's "5 cards" statement predates. Fixed:
`is_starter=false`, so it's now a regular Command Market card. This also
bumped the Command Market's verified pool from 15 to 16 cards (re-confirmed).

**Sage pack composition** (16 cards total, matching the rulebook's own
count: 1 Sage + 3 Champions + 3 Warriors + 5 Commands + 4 Basics):
- 1 Sage, 3 Champions (by element) — Champions go to `PlayerState.locked_champions`
  (face down, inert until leveling exists), not the deck or formation.
- 3 starter Warriors (by element + `is_starter`) — the rulebook makes
  choosing 2 of these for the formation the *player's* decision, so
  `chosen_warrior_names` is a required parameter, not something this class
  picks. The 3rd goes into the deck.
- 1 starter Basic (by element + `is_starter`), needed as **4 physical
  copies** — 3 on the formation (Row I + both Row II slots), 1 into the
  deck. Multiple "copies" are just the same shared `CardDefinition`
  reference wrapped in separate `CardInstance`s, same pattern used
  everywhere else a card can appear more than once.
- 5 Commands (2× Close Strike, 2× Far Strike, 1 faction Charm) — hardcoded
  directly rather than derived from `is_starter`, since `is_starter` is a
  boolean and can't express "2 copies of this one."

Formation layout matches the rulebook's setup diagram and the old
reference's space numbering exactly: Row I + Row II = the 3 Basic copies,
Row III = chosen Warrior (space 4, "left") / Sage (space 5, center) /
chosen Warrior (space 6, "right"). Deck is shuffled, 5 cards drawn to hand.
Starting gold: 0 if `goes_first`, 3 otherwise (per the rulebook — which
player actually goes first is left to the caller, same as always).

Verified for two different Sages (Cedar and Torrent) with the full
resulting formation, locked Champions (correct level thresholds), and the
complete 7-card deck+hand composition checked card-by-card against what the
16-card pack math predicts. Also verified an invalid Warrior choice fails
cleanly (aborts with a clear error, leaves a safely-incomplete state)
instead of partially applying.

## Leveling + faction actions (2026-09-06)

**Research dead end, then a pivot**: tried to find the 12 per-Sage faction
actions (3 each, unlocked at level 4/6/8) on unstablegameswiki.com the same
way the card abilities were sourced. The wiki only has photos of the
physical Sage boards, and they were too low-resolution and watermarked to
transcribe reliably — attempted to zoom in via the browser tool, but it
also started intermittently timing out (`Page.captureScreenshot` timed
out). Stopped after a few failed attempts rather than guessing at illegible
numbers, reported the dead end honestly, and the user then typed out all 12
actions' exact text directly. Lesson: for card-board-photo-only rules
content, don't burn more than 2-3 attempts on wiki image legibility before
asking the user to transcribe — same "stop after 2-3 failures" instinct as
any other blocked tool loop.

**Leveling**: `PlayerState` gained `level` (1-8), `unlocked_faction_action_levels`,
and `level_up()` — called once per Elemental a player's attack defeats.
Crossing 4/6/8 unlocks that level's faction action permanently and reveals
the matching `locked_champions` entry into the discard pile (matched by
`level_requirement`, not position — order isn't guaranteed). To expose
defeat counts without duplicating `CombatResolver`'s existing
before/after-damage snapshot logic, `resolve_attack()`'s return type changed
from a plain pending-abilities `Array` to `{"pending": Array, "defeated_count":
int}`; `Turn.play_attack_command()` unpacks it and calls `level_up()` per
defeat. `Turn` also gained `has_attacked()`/`mark_attacked()` (exposed
publicly so faction actions that trigger an attack outside the normal
hand-based flow can still respect "each Elemental attacks at most once per
turn"), and `can_use_faction_action()`/`spend_faction_action_ap()` now take
a `level` param, checking `player.unlocked_faction_action_levels.has(level)`
in addition to the existing AP/once-per-turn gating.

`Formation` gained `get_connected_cards(space_number)` — several faction
actions ("shield each connected Pebble," "boost per connected Twig")
needed actual neighbor *cards*, not just neighbor space numbers.

**`player/faction_actions.gd`** — new file, `FactionActions`: 12 static
functions (`torrent_level_4/6/8`, `gravel_level_4/6/8`, `cedar_level_4/6/8`,
`porella_level_4/6/8`), one per Sage's per-level action, transcribed
verbatim from what the user provided. Like `EffectExecutor`/`CombatResolver`,
these are pure mechanics functions on `EffectContext` — not `Turn` methods —
so the same "`Turn.can_use_faction_action(level)`/`spend_faction_action_ap(level)`
first, then call the mechanic" split applies as every other Turn action.
Notable design points:
- **Gravel level 6** ("remove all shields, then redistribute in any
  distribution") is split into `gravel_level_6_collect()` (returns the
  total removed) and `gravel_level_6_distribute(distribution)` (a
  space→count `Dictionary`) — the redistribution is the player's choice,
  not something to guess at in one function.
- **Porella level 4** ("play an attack command from your discard pile")
  mirrors `Turn.play_attack_command()`'s row/attacker validation but sources
  the card from the discard pile and returns it there afterward instead of
  a second removal. It does **not** check/update attacked-this-turn itself —
  `FactionActions` has no access to `Turn`'s tracking, so the caller is
  expected to check `Turn.has_attacked()`/call `Turn.mark_attacked()`
  around it, same as it already checks `can_use_faction_action()` first.
- All three "deal fixed damage" actions (Torrent/Gravel/Cedar level 8) route
  through one shared `_deal_fixed_damage()` helper that builds a throwaway
  `DEAL_DAMAGE` effect and runs it through `EffectExecutor.execute()`, so
  shield reduction, defeat, and removed-pile handling all go through the
  one general path instead of being reimplemented three times.

Verified with a temporary headless script covering all 12 functions plus
leveling/unlock progression 1→8 and the `Turn` gating checks. Two real
test-setup bugs were caught and fixed along the way (not `FactionActions`
bugs): a card placed at an already-occupied formation space silently didn't
overwrite what was there, so the "wrong" card ended up under test; and a
defeated-and-removed card was reused in a later sub-test without being
re-added to the formation, so damage dealt "to" its old space hit nothing.
Both are reminders that shared formation state across sequential test
sections needs each section to account for what earlier sections did to it.
Deleted the temporary script after all values matched expected output.

## 4-player team setup (2026-09-06)

Extended `PlayerSetup` to build a 4-player team (2 players sharing one
Formation and one GoldPool) alongside the existing 2-player `new_player()`,
without duplicating the Sage-pack-splitting logic between them.

**Source for the space layout**: the old TS repo's `Team.ts`
(`initBattlefield`/`initWarriors2Decks`), fetched directly from GitHub since
this wasn't something the wiki (card text only) or a quick rules.pdf lookup
could answer — text extraction on `rules.pdf` failed outright (`textutil`
silently returned the original PDF bytes rather than real text, and this
repo has no `pdftottext`/poppler installed; declined to install it
mid-session rather than reach for a new system tool without asking first).
The user answered the one remaining open question directly instead
(4-player's second-team starting gold is **4**, not simply double the
2-player value of 3 — confirmed by the user, not derived).

`Team.ts` confirmed the shared 12-space formation splits into two disjoint
per-player halves, each laid out exactly like the 2-player case's spaces
1-3/4-6, just at different space numbers: player 1 gets Row I/II spaces
1,3,4 and Row III spaces 7 (left warrior)/8 (Sage)/9 (right warrior); player
2 gets 2,5,6 and 10,11,12. Confirmed this against `Formation.new_four_player_team()`'s
existing adjacency data (row_capacities `[2,4,6]`, spaces 1-2 = row 1, 3-6 =
row 2, 7-12 = row 3) — no changes needed there, it already matched.

**Refactor**: extracted `PlayerSetup._setup_player(state, sage_name,
chosen_warrior_names, basic_spaces, warrior_sage_warrior_spaces)` as the one
place the Sage-pack-splitting logic lives — `new_player()` calls it once
with spaces `[1,2,3]`/`[4,5,6]`, `new_team()` calls it twice with
`[1,3,4]`/`[7,8,9]` and `[2,5,6]`/`[10,11,12]`. Only the space numbers
differ; hand/deck/discard/locked-Champions logic is identical, applying
[[feedback-shared-logic-not-duplicated]] proactively rather than copy-pasting
`new_player()`'s body a second time with different literals.

**`PlayerState` constructor** gained optional `shared_formation`/`shared_gold`
params (defaulting to `null`, which preserves the existing "build my own"
2-player behavior exactly) so `new_team()` can construct both teammates
against the same `Formation`/`GoldPool` instances instead of each getting
their own.

Verified headlessly: 2-player `new_player()` behavior unchanged; a 4-player
team's two `PlayerState`s share the same `Formation`/`GoldPool` object
identity; each player's 6 cards land on their own disjoint half with no
space collisions (all 12 spaces filled, zero overlap); starting gold is 0/4
for goes_first/not (not 0/3 — team, not individual, and a different
number); hand/deck/level/locked-Champions stay individual per player; and
an invalid Warrior choice for the second player fails cleanly, leaving that
player's 6 spaces empty while the first player's cards (already placed)
are untouched.

**New gap found, not yet closed**: `Formation.get_sage()`/`has_sage()`
return the *first* Sage found and assume there's only one — true for
2-player, but a 4-player shared formation has two. Nothing calls these
during setup, but `FactionActions`' Torrent/Gravel/Cedar level-8 functions
(and Porella level-8) all call `formation.get_sage()` to find "your Sage,"
which will silently return the wrong player's Sage half the time in
4-player. This blocks 4-player faction actions specifically until
`Formation` gets some notion of "whose Sage" (an owner-scoped lookup, or
`get_sages()` plural with the caller picking).

## Owner-aware Sage lookup (2026-09-06)

Closed the gap noted just above. `Formation.get_sage()` can't tell two
Sages apart on a shared 4-player formation, and it turned out to have
**two** real call sites, not one: `FactionActions`' level-4/8 functions
(already known), plus `TargetResolver.get_candidates()`'s `SELF_SAGE`/
`ENEMY_SAGE` case — used by real card data (Jade Titan: "add 1 shield to
your Sage"), so this was a latent 4-player bug in card abilities too, not
just faction actions.

**Fix**: stopped deriving "my Sage" by searching the formation at all.
`PlayerState` gained a `sage: CardInstance` field, set once by
`PlayerSetup._setup_player()` at the exact moment it places the Sage (no
search needed — the setup code already knows). `TargetContext` gained
`self_sage`/`enemy_sage` fields (symmetric, matching the existing
`self_hand`/`enemy_hand` pattern — `enemy_sage` has no real caller yet,
same as `enemy_hand`/`enemy_discard_pile` when those were added). Both
`TargetResolver`'s `SELF_SAGE`/`ENEMY_SAGE` case and all 4 of
`FactionActions`' Sage-needing functions now read `context.targets.self_sage`
directly instead of calling `formation.get_sage()`. `Formation.get_sage()`/
`has_sage()` themselves are unchanged (still useful for 2-player and any
"is there any Sage here at all" check) but their doc comments now say
plainly that they return *a* Sage, not a specific player's, and shouldn't
be used where ownership matters.

Verified headlessly with a 4-player team (Torrent + Gravel sharing one
formation, Sages at spaces 8 and 11): confirmed `Formation.get_sage()`
really does always return player 1's Sage first (proving the bug was real,
not hypothetical — spaces are scanned in ascending order and player 1
always occupies the lower half); then ran `gravel_level_8` as player 2 —
the exact case the old code would have gotten wrong — and confirmed it
correctly spent player 2's own Sage's shields (not player 1's, which stayed
untouched) and dealt the right damage; also confirmed `torrent_level_8` as
player 1 and the `SELF_SAGE` target-resolution path directly, both
resolving the correct owner's Sage. One test-setup bug caught along the
way (not a real bug): a card defeated in an earlier sub-test needed
re-adding to the formation before reuse in a later one — same pattern
already seen once before in the faction-actions verification pass.

## 4-player team turn/game flow (2026-09-07)

Generalized `Turn` to run either a 2-player turn or a 4-player team's turn,
instead of building a separate class. Confirmed with the user first: 4-player
AP is a flat **6** shared between the 2 teammates for their whole team-turn,
*not* simply double the 2-player value of 4 (the old TS repo's `ActiveConGame`
suggested 3/6 — a clean double — but that 3 conflicts with our own
already-verified 4 for 2-player, so it wasn't trustworthy here; asked the
user directly rather than guess).

**Source for the team-turn structure**: fetched `ConGame.ts` (specifically
`ActiveConGame`) from the old repo, which confirmed turns are per-*team*, not
per-player — one team is "active," both teammates act against one shared AP
pool during that team's turn, then it flips. This matches what was already
confirmed earlier about 4-player sharing (shared Formation + AP; hand/deck/
discard/level stay individual; either teammate can attack with any Elemental
on the shared formation, just not the same one twice) — no new rule
questions needed there.

**Design**: `Turn.players: Array[PlayerState]` replaces the old single
`player: PlayerState` (1 entry = 2-player, 2 = a team) — `opponents` is now
an array too, for symmetry, though nothing inside `Turn` reads it either way
(same as before). Every action touching an individual zone (hand/deck/
discard/removed pile) gained a `player_index: int = 0` parameter, defaulting
to 0 so every 2-player call site is unaffected. Actions that only touch
shared state never got one: `swap_connected()`, `buy_and_summon_from_market()`,
`refresh_market()` all work identically whichever teammate calls them, since
formation/gold are the literal same shared objects PlayerSetup.new_team()
already wired up — no new sharing logic needed in `Turn` itself, just reading
off `players[0]` for those (any index works, they're the same object).
`can_end_cleanup()` became a team-wide check (every player's hand ≤ 5, not
just one) since ending a team's turn requires both teammates' hands legal.
`can_use_faction_action()`/`spend_faction_action_ap()` gained `player_index`
too, since the once-per-turn/AP-cost checks are team-wide but the *unlocked
levels* check is per-player (leveling is per-player even in team mode,
confirmed earlier).

**Real bug found and fixed, not new to this session's changes**: while
verifying, a Close Strike attack dealt 0 damage instead of the attacker's
STR. Traced it to `Turn.play_attack_command()` never setting
`context.targets.attacking_card` before calling `CombatResolver.resolve_attack()`
— `ATTACKER_STRENGTH`-sourced damage (what Close Strike/Far Strike and most
other Attack Commands use) reads that field and silently resolves to 0 if
it's null. `FactionActions.porella_level_4` already did this correctly
(explicitly setting it before its own `resolve_attack()` call), which is
what made the gap in `Turn` visible by contrast. Fixed by having
`play_attack_command()` set it itself from its own `attacker` parameter,
rather than leaving it as a caller footgun — it already receives `attacker`,
so there's no reason to make every caller separately duplicate it onto the
context too.

Verified headlessly: 2-player `Turn` behavior fully unchanged (4 AP); a
4-player team's `Turn` starts at 6 AP shared across both teammates' draws;
either teammate can attack with any card on the shared formation (tested
player 2 successfully attacking with player 1's Elemental); the same card
can't be attacked with twice by either teammate (team-wide
`attacked_this_turn`); a defeated attack raises the *acting* player's level
specifically, leaving the other teammate's level untouched; faction-action
eligibility correctly differs per player even though AP/phase are shared;
a market purchase lands in the *buying* player's own discard pile;
`buy_and_summon_from_market` needs no player attribution since it only
touches shared state; and `can_end_cleanup()` correctly goes false when
either teammate's hand is oversized and true again once both are fixed.

## Match-level orchestration + a working PDF pipeline (2026-09-07)

**Tooling first**: every prior phase that needed a rules.pdf fact had to ask
the user directly, because text extraction kept failing on this machine —
no `pdftotext`/poppler installed, and macOS `textutil`/Spotlight indexing
turned out not to actually extract PDF text either (silently returned raw
PDF bytes or nothing). With the user's explicit go-ahead, installed poppler
via `brew install poppler`, ran `pdftotext -layout rules.pdf`, and got real,
searchable rules text for the first time this project. Read directly:

- **"How to Win"**: 2-player — defeat your opponent's Sage. 4-player — your
  team wins once you've defeated **both** of the opposing team's Sages.
  Confirms exactly what the user had already told us when asked directly
  (every fact-check this session — 2p/4p gold, AP, this loss condition —
  matched the user's answers exactly; the old TS repo's numbers were the
  only source that ever disagreed).
- **A genuinely new rule, not previously modeled**: "If your Sage is
  defeated but your teammate's Sage is not, you may continue playing;
  however, you cannot use any faction actions or increase your level ... for
  the remainder of the game." A half-defeated 4-player teammate keeps
  drawing/summoning/attacking/buying normally — only faction actions and
  leveling are permanently cut off for *that player specifically*, not their
  still-alive teammate.
- Everything else already built (2p/4p AP values, both starting-gold
  numbers, once-faction-action-per-turn, teammate hand visibility without
  play access, the row-shift-forward-on-defeat direction) matched the
  extracted text exactly — a full retroactive confirmation that nothing
  built on user-provided facts alone was actually wrong.

Per the user's explicit instruction, uninstalled poppler (`brew uninstall
poppler`) once done reading — it was a one-time extraction tool for this
session, not a project dependency, and the extracted text (kept only in a
scratch file) was deleted after use.

**Closed the "new rule" gap**: `PlayerState.level_up()` now no-ops once that
player's own Sage is defeated; `Turn.can_use_faction_action()` now also
checks the acting player's own Sage isn't defeated (in addition to the
existing unlock/AP/once-per-turn checks) — both read `PlayerState.sage.is_defeated()`
directly rather than introducing separate tracked state, since it's already
the ground truth.

**`game/match.gd`** — new `Match` class, the orchestration layer above
`Turn`: tracks `side_a`/`side_b` (each 1 PlayerState for 2-player, 2 for a
4-player team — built beforehand by `PlayerSetup`, `Match` doesn't build
rosters itself), `active_side`, and `current_turn: Turn`. `winner()`/
`is_over()` implement the win condition above generically for both player
counts (a side loses once *every* one of its Sages is defeated — trivially
just the one Sage in 2-player). `finish_turn()` validates the active side's
`Turn` actually reached and passed `CLEANUP` (via `Turn.advance_phase()`,
which already gates on `can_end_cleanup()`), checks the win condition before
handing off, and only starts a new `Turn` for the other side if the match
isn't already over. Which side goes first is a parameter, not something
`Match` decides — the rulebook's tiebreak ("most house plants") is a
real-world decision outside the game state, same as who chooses gold/goes
first already was.

The "which formation is enemy in 4-player" question from the earlier
deferred note turned out not to be a real gap: since each team has exactly
one shared formation (not one per player), `Turn.opponents[0].formation` —
already exposed since the team-turn work — is unambiguous. No new lookup
was needed.

Verified headlessly: 2-player match end-to-end (`finish_turn()` correctly
refuses before `CLEANUP`, correctly hands off to the other side once legal,
`winner()` flips to 0 once the opposing Sage is defeated, and a further
`finish_turn()` call on an already-decided match advances the phase but
does not start a new turn); 4-player team match where one teammate's Sage
falls first (match correctly stays ongoing, that teammate's own
`can_use_faction_action`/`level_up()` are blocked while their still-alive
teammate's are proven unaffected — tested by unlocking the same level on
both and getting different results), then the second Sage falls and the
match correctly ends with the right side declared winner.

## Old prototype removed; first visual piece built (2026-09-07)

**Removed the tutorial prototype**: `game.gd`/`card.gd`/`game.tscn`/`card.tscn`
(the original standard-52-card-deck demo) deleted outright — confirmed
nothing else in the repo referenced them first. Cleared `project.godot`'s
now-dangling `run/main_scene` (it pointed at the deleted `game.tscn`); the
project currently has no main scene at all, which is expected until a real
one exists. Also swept up `verify_abilities.gd.uid`, an orphaned sidecar
file left over from an early deleted verify script.

**`ui/card_display.gd` + `ui/card_display.tscn`** — the first actual visual
piece: a single reusable `CardDisplay` (`PanelContainer`) that renders any
`CardDefinition` alone (e.g. a Market listing) or paired with a live
`CardInstance` for board state (remaining HP instead of base HP, shield/
boost/damage badges). No card art exists yet (every `CardDefinition.art` is
unset), so the art area is an element-tinted `ColorRect` placeholder —
swappable for a `TextureRect` later without touching anything else.

**Real bug found and fixed while verifying, not a test-only issue**: caching
node references via `@onready var x = %Name` meant `set_card()` silently
no-op'd (nulls internally) if called before the instantiated scene ever
entered a `SceneTree` — e.g. building a card display and configuring it
*before* adding it to a hand/board container, which is a completely normal
thing for a caller to want to do. Fixed by resolving `%UniqueName` lookups
live inside `_refresh()` instead of caching them — unique-name resolution
only needs `owner` to be set (already true immediately after
`PackedScene.instantiate()`), not a live tree, so this works whether the
node has entered a tree yet or not.

**Verified two ways**: headlessly (wiring/values correct for a Warrior with
an ability, a Basic with no ability, a Command with no stats, a Sage, and a
null card hiding the whole display — both before and after entering a live
tree, to specifically re-exercise the bug above) and visually — actually
launched Godot non-headless (a real window opened fine, Metal renderer) and
captured a real screenshot via `get_viewport().get_texture().get_image().save_png()`.
That screenshot caught two real visual defects neither the headless check
nor just reading the code would have: long ability text overflowed the
card's fixed height and bled onto the background (fixed: taller card, a
smaller ability-text font, `clip_contents = true` as a safety net for
whatever's still too long), and Pebble-element cards landed on almost the
exact same gray as the neutral Command placeholder color (fixed: Commands
now use a distinct indigo, Pebble a warmer stone tan). Confirmed the fix
with a second screenshot. All capture/verification scripts and the PNG were
temporary and deleted after use, per the established pattern.

## Formation board visual (2026-09-07)

`ui/formation_display.gd` — `FormationDisplay` (`VBoxContainer`), the
second visual piece: renders an entire `Formation` (any size) as one
horizontal row per `row_capacities` entry, Row I at the top, each space in
ascending `space_number` order. Occupied spaces get a `CardDisplay`
instance (definition + live `CardInstance`, so damage/shield/boost badges
show correctly); empty spaces get a dim placeholder showing the space
number (useful now as a debugging aid, later for picking a target/summon
space in the real game UI). Pure GDScript, no `.tscn` — unlike
`CardDisplay`'s fixed layout, everything here is built dynamically from
whatever `Formation` it's given, so there was no static structure worth
hand-authoring a scene file for. Rebuilds from scratch on every
`set_formation()` call rather than diffing — fine for a handful of Control
nodes at a time; revisit if this ever needs to update every frame during
live play instead of on-demand.

Verified visually the same way as `CardDisplay` (see the entry above,
[[reference-godot-gotchas]]): captured a real non-headless screenshot for
both a 2-player formation (1/2/3 rows, one card pre-damaged+shielded to
confirm the badge shows on the *right* card) and a 4-player team's shared
12-space formation (2/4/6 rows) — the latter is a genuinely useful
confirmation, since it visually shows **both Sages sitting on one shared
board** (Torrent and Gravel, Row III), the exact structure the 4-player
team-setup work built and verified headlessly earlier, now visibly correct
too. The narrower front rows (2 of 6, 4 of 6 possible slots in 4-player)
centered naturally from `HBoxContainer.ALIGNMENT_CENTER` — no extra layout
code needed to get the "staggered pyramid" shape described in the
rulebook's setup diagrams. One small `CardDisplay` polish surfaced along
the way and folded back in since it affects every card, not just this
view: long names (e.g. "Granite Rampart") were clipping flush against the
cost number with no indication of truncation — added ellipsis trimming
(`text_overrun_behavior`) and a slightly smaller name font.

## Hand/discard/market row visual (2026-09-07)

`ui/card_row_display.gd` — `CardRowDisplay` (`HBoxContainer`), the third
visual piece: a horizontal row of `CardDisplay` instances for a flat list
of cards. `set_zone(zone: CardZone)` covers hand/discard/removed pile;
`set_cards(cards: Array[CardDefinition])` covers a `Market`'s `face_up`
listing directly, since `Market` isn't a `CardZone`. Deliberately **one**
generalized component instead of separate `HandDisplay`/`MarketDisplay`
classes — a hand, a discard pile, and a market listing are all just "a row
of cards" at the display level; the difference is entirely in what data
feeds them, not how they render. Same as `FormationDisplay`: pure GDScript
(no static layout worth a `.tscn`), read-only, rebuilds from scratch on
every call.

Verified visually: a real 5-card hand (mixed Commands/Basics, ability text
wrapping correctly for each) and a real Elemental Market's 3-card face-up
listing (`Market.new_elemental_market().face_up`) side by side in one
screenshot — confirmed the same `CardDisplay` component reused cleanly
across three different data sources (board, hand, market) with zero
per-context special-casing needed.

`ui/` now has three components — `CardDisplay` (one card), `FormationDisplay`
(a whole board), `CardRowDisplay` (any flat list of cards) — covering every
place cards appear except a Sage board / faction-action panel, which
doesn't have card-shaped content to reuse `CardDisplay` for anyway.

## Turn status HUD (2026-09-07)

`ui/turn_status_display.gd` — `TurnStatusDisplay` (`VBoxContainer`), the
fourth visual piece: a read-only HUD for a `Turn` — phase, AP remaining/max
(4 or 6, matching `Turn.MAX_AP_2_PLAYER`/`MAX_AP_4_PLAYER`), the shared gold
pool, and **each player's level shown separately** with their unlocked
faction-action levels (only rendered when non-empty). Level is individual
per player even in 4-player team mode — showing one combined number would
have been actively wrong, since a team's two players can be at different
levels (or one can be capped out after their Sage falls, see the earlier
Match section). No card-based content here, so this doesn't reuse
`CardDisplay`/`CardRowDisplay` — just plain `Label`s built the same
rebuild-from-scratch way as the other three components.

Verified visually with two real `Turn`s side by side in one screenshot: a
2-player turn (AP correctly down from 4 after 2 draws, level correctly at 5
with `[4]` unlocked after 4 defeats) and a 4-player team turn where only
one of the two teammates was leveled up — confirmed the display shows
"Level: 1 (Player 1)" / "Level: 5 (Player 2) / Unlocked faction actions:
[4]" separately and correctly, not a single merged number.

## First interactive game screen (2026-09-07)

The first genuinely *interactive* piece — click a hand card, click a board space,
watch the actual `Turn`/`Match` state resolve and every display refresh — not
just another read-only view. Plan file:
`.claude/plans/okay-i-want-you-sleepy-lagoon.md` has the full design writeup
(state machine, scoping rationale); this section covers what actually
happened building and verifying it, including several real Godot gotchas
this specific kind of work finally surfaced.

**Scope, confirmed with the user up front**: a hardcoded 2-player dev
`Match` (Cedar vs. Gravel, the same pairs used throughout this session's
verify scripts) rather than a Sage/Warrior picker screen; and a minimal
action slice (draw, summon, one single-target Attack Command) rather than
every standard action — swap, non-attack Commands, Market, faction
actions, and Daybreak all reuse the exact same click-to-select/click-to-
target/refresh pattern built here, so they're fast follow-ups, not a
redesign.

**Click primitives added to the existing display components**:
- `CardDisplay` gained `signal pressed(display)` (via `_gui_input()`, left-click)
  and `set_selected(bool)` (a `modulate` tint highlight).
- `FormationDisplay` gained `signal space_pressed(space_number)` and
  `highlight_spaces()`/`clear_highlight()` (a `self_modulate` tint per slot —
  deliberately `self_modulate`, not `modulate`, so a highlighted board slot
  never visually compounds with a `CardDisplay` child's own independent
  `modulate`-based selection tint). A real wiring subtlety caught before it
  became a bug: an *occupied* slot's `CardDisplay` child has its own
  `mouse_filter = STOP`, which consumes the click before it can bubble to
  the slot's own `gui_input` — so occupied-slot clicks are bridged by
  connecting the child `CardDisplay.pressed` signal into `space_pressed`
  too, not by relying on the slot's own `gui_input` (which only ever
  actually fires for *empty* slots).

**`ui/game_screen.gd` + `.tscn`** — composes all four existing display
components. One shared `_build_context()` builds the `TargetContext`/
`EffectContext` from `current_turn.players[0]`/`opponents[0]` once, instead
of re-assembling the same constructor call per action (same "one shared
function" principle as `TargetResolver.formation_for()`). A small explicit
`InteractionState` enum (IDLE / SUMMON_SELECT_SPACE / ATTACK_SELECT_ATTACKER
/ ATTACK_SELECT_TARGET) drives the click flow; a mis-click in any non-IDLE
state just cancels back to IDLE rather than erroring. `_refresh_all()` is
the single place that re-syncs all four displays from `current_turn` state
and resets interaction state after every resolved action.

**Custom class_name types (`type="FormationDisplay"` etc.) don't reliably
resolve as `.tscn` node types outside the editor process.** `game_screen.tscn`
originally declared its `FormationDisplay`/`CardRowDisplay`/`TurnStatusDisplay`
children directly by class name; this parsed fine under `--editor --quit`
but failed with "Cannot get class" under a plain `--headless --script` run
(placeholder nodes got created instead). Fixed by using the same reliable
pattern `CardDisplay.tscn` already used: a plain built-in base type
(`VBoxContainer`/`HBoxContainer`) with the script attached via
`[ext_resource type="Script"]`, not the class name as the node `type=`.

**Real bug found and fixed, would have hit any repeatedly-refreshed
component**: `CardRowDisplay.set_cards()` and `FormationDisplay._rebuild()`
both cleared old children with `child.queue_free()` alone — which *defers*
removal to end-of-frame, so `get_children()`/`get_child_count()` still saw
the stale children if the same component got rebuilt again before that
deferred free actually ran (exactly what happens every time `GameScreen`
calls `_refresh_all()` after an action). Caught via a genuine symptom, not
by inspection: after a second refresh, hand-card click signals were
"already connected" (re-connecting to stale un-freed nodes) and
`hand_row.get_child_count()` read 11 instead of 6. Fixed by calling
`remove_child(child)` (synchronous) before `child.queue_free()` (still
deferred, since this can run from inside a child's own click-signal
handler — freeing it synchronously mid-signal would be unsafe) — this is
now documented in [[reference-godot-gotchas]] as a general pattern for any
future rebuild-on-refresh UI component.

**Two more gotchas hit specifically while getting real interactive/visual
verification working, both folded into [[reference-godot-gotchas]]**:
1. `_ready()`/`@onready` don't fire reliably when a scene is manually
   `add_child()`-ed from inside a bare `SceneTree` script's `_init()` (the
   pattern almost every `verify_*.gd` script this session used) — confirmed
   again here (this is the same root cause `CardDisplay`'s `%UniqueName`
   fix addressed earlier, now hit at the whole-scene level). Fixed the
   *verification* script with `await process_frame` (twice) before reading
   state — `GameScreen` itself correctly keeps using `@onready`, since real
   engine-driven scene loading (running it as the actual main scene) calls
   `_ready()` synchronously and reliably; this is purely an artifact of the
   SceneTree-script harness, not something `GameScreen` needs to guard against.
2. A real OS window gets silently clamped to the physical display's usable
   height (requested 2200px, macOS granted ~1674px) — resizing the window
   wider than the screen doesn't get you more space to screenshot. Fixed
   by rendering into a `SubViewport` instead (no physical-display limit,
   also sidesteps the project's `canvas_items` window-stretch settings
   entirely) — but a `SubViewport` also defaults to
   `render_target_update_mode = UPDATE_WHEN_VISIBLE`, and one that's never
   attached to an on-screen `SubViewportContainer` is never "visible," so
   it renders nothing (a fully black capture) until forced with
   `UPDATE_ALWAYS`.

**Verified two ways**: headlessly (scene builds without errors; initial
state — phase, AP, hand size, both formations' full starting rosters —
matches the dev `Match` exactly; the child-accumulation fix confirmed by
refreshing twice and checking child count stays correct instead of
growing) and with genuine synthetic-input interaction (not just screenshots
of static state) — injected two known cards for determinism, then actually
drove the full click sequence: click an Elemental in hand → confirm
`SUMMON_SELECT_SPACE` and the right spaces highlighted → click a highlighted
space → confirm the card left the hand, landed on the board, and AP dropped
→ click an Attack Command → click an eligible attacker → click a
highlighted enemy target → confirm the target actually took damage (a
2-HP `Cobble` correctly defeated by 2 `STR` damage) and AP dropped again.
Screenshot captured at the end showed the whole thing consistently: both
full formations, the correct hand contents, and the status panel showing
**Level: 2** — confirming the defeat correctly triggered `level_up()`
through the entire `Turn.play_attack_command()` → `CombatResolver` chain,
a detail the printed checks hadn't even explicitly tested for.

**Set as the project's main scene** (`project.godot`'s `run/main_scene`) so
it's actually playable via the normal Play button, not just from verify
scripts.

**Real usability gap found from the user actually running it, not from any
of the above verification**: the full stacked layout (two boards + hand +
status) is far taller than the project's default window (1152×648) — and
with `window/stretch/mode="canvas_items"`, a too-small window doesn't just
require scrolling, it shows an arbitrary *middle* slice of the content
rather than the top. All of this session's verification used a full-size
(or `SubViewport`-rendered) capture, so this never surfaced until the user
tried it in a normal window. Fixed by wrapping `Margin`/`Layout` in a
`ScrollContainer` (`horizontal_scroll_mode` disabled, vertical left on
auto) so any window size now shows the top of the content with a working
scrollbar for the rest, instead of a confusing unscrollable partial view.
A reminder that a screenshot from a script-controlled capture isn't the
same check as someone actually opening the thing.

## Turn hand-off wired up (2026-09-07)

Extended `GameScreen` to actually call `Match.finish_turn()` instead of
stopping at "act within one Turn." `_on_advance_phase_pressed()` now checks
whether the current phase is already `CLEANUP`: if so, pressing the button
calls `current_match.finish_turn()` (which itself re-validates the Cleanup
hand-size gate, checks the win condition, and only then hands off) instead
of `Turn.advance_phase()`. The button's label switches to "End Turn" once
in Cleanup so it's clear the same button now does something different.
Once `current_match.is_over()`, the Draw/Advance Phase buttons disable and
every click handler (hand card, self space, enemy space) no-ops instead of
acting on a decided match — this slice has no "start a new match" flow, so
stopping cleanly there is the intended end state, not a gap.

Verified headlessly: walked a full turn to Cleanup and pressed "End Turn"
— confirmed `players[0]`/`opponents[0]` actually swapped (Cedar → Gravel
acting), the new `Turn` started fresh at `DAYBREAK`, and the button label
reset. Separately defeated a Sage and confirmed `is_over()`/`winner()`
resolve correctly, the status label reports the winner, and both buttons
disable.

## Board orientation + attack-flow feedback fixes (2026-09-07)

Two real problems found by the user actually playing it, not by any of
this session's verification:

**Board orientation was backwards.** Both `FormationDisplay`s rendered Row I
at the top, so the two boards' front lines (Row I) ended up at opposite
ends of the screen instead of facing each other in the middle — not how
the physical board reads. `FormationDisplay` gained `reverse_rows: bool`
(set before `set_formation()`); `GameScreen` sets it on
`enemy_formation_display` only. Top to bottom is now: opponent Row III,
II, I, then your Row I, II, III — both Row Is meeting in the middle.
Verified visually and by checking the actual rendered row order (first
`HBoxContainer` child has 3 slots — Row III — for the reversed side,
1 slot — Row I — for the normal side).

**Attack flow gave no feedback when nothing was eligible.** If the acting
player has no unattacked Elemental in the Attack Command's required row,
or the opponent has nothing in the targeted spot, `_eligible_attacker_spaces()`/
`_attack_target_candidates()` correctly returned empty arrays — but
`GameScreen` highlighted nothing and left the generic "Choose an
attacker..."/"Choose a target..." message up, so the player was just stuck
looking at an unresponsive board with no idea why. Easy to hit even in the
demo's starting position (the opponent only has one card in Row I to begin
with, defeat it once and the next Close Strike attempt would silently do
nothing). Fixed: both selection steps now check for an empty candidate
list *before* transitioning state, and show a specific explanation instead
("No eligible attacker for Close Strike right now (needs an Elemental in
Row I that hasn't attacked yet)." / "No legal target for Close Strike
right now (the opponent has nothing there to hit)."), reverting to IDLE
rather than leaving the player in a dead-end state. The two "in-progress"
messages also now name which board to look at ("highlighted on your
board" / "highlighted on the opponent's board").

Verified headlessly: confirmed the row-reversal renders the expected slot
counts per visual row, and both zero-candidate paths (attacker, target)
correctly stay/return to IDLE with the specific explanatory message
instead of silently stalling.

## CardDisplay layout: attack/health flank the name (2026-09-07)

User-requested layout change: attack value top-left, card name top-middle,
health top-right, cost moved to bottom-right (previously cost sat next to
the name in the header, and attack/health were a single combined
`STR / HP`-style line under the art). `card_display.tscn`'s header row is
now `AttackLabel | NameLabel (centered, expanding) | HealthLabel`;
`CostLabel` moved out of the header to the bottom of the card, right-
aligned. `card_display.gd._refresh()` now sets `AttackLabel`/`HealthLabel`
directly instead of a combined `StatsLabel` string, still hiding both for
non-Elemental cards (Commands) exactly as the old combined stats line did.

Verified visually (Elemental with live damage/shield, a Command hiding
attack/health correctly, cost bottom-right on every card) and confirmed
`FormationDisplay`/`CardRowDisplay` (which just embed `CardDisplay`
unchanged) still render correctly on top of the new internal layout — no
changes needed there, since they never depended on `CardDisplay`'s internal
node structure, only its public `set_card()` API.

## Real ability-data bug: "N rows away" targeting (2026-09-07)

User asked "what does Far Strike do?" while testing attacks — led to
finding a genuine, previously unnoticed bug in the card *data*, not the UI.
Four ranged Attack Commands' `raw_text` says "an Elemental **N rows away**
in your opponent's formation" (Far Strike: 2, Farsight Frenzy: 3, Primitive
Strike: 2, Projectile Blast: 2), but all four were structurally implemented
as `TargetScope.FORMATION` with no row restriction at all — meaning they
could actually hit *any* occupied enemy space, anywhere on the board,
completely ignoring their own stated row restriction. Confirmed by reading
`TargetResolver._by_occupancy()` directly: an empty `rows` array (what
`FORMATION` scope always passes) is treated as "every row qualifies," not
"no rows." Checked every other Attack Command's text for the same pattern
first (`grep -rn "rows away"`) — exactly these 4, nothing missed.
`Distant Double Strike` (fixed Row II, not relative) and `Magic Ether
Strike` ("in your opponent's formation," no distance stated) were already
correctly modeled and left untouched.

**The exact meaning of "N rows away" needed the user's own explanation**,
not something derivable from the card text alone: the count runs along the
*whole* board as one continuous line — through the attacker's own rows,
across the boundary, into the opponent's — not restarting at 0 inside the
opponent's formation. Confirmed directly: "if you use \[Far Strike\] in my
row 2, that's the opponent's row 1, because the counting includes my own
rows." Worked out the formula from that one example and verified it
produces a valid row (1–3) for every row each of the 4 cards can legally
be played from: **target_row = N − attacker_row + 1**.

**New targeting concept added**: `CardEnums.TargetScope.ROWS_AWAY` (target
data-driven card abilities didn't have a "distance from the attacker"
concept before this — every existing scope was either fixed-row or
unrestricted). `AbilityTarget.rows[0]` reused to hold N rather than adding
a new field, mirroring how `ROW` already uses `rows` for literal row
numbers.
`TargetResolver._rows_away_candidates()`: finds the attacker's current row
via `context.self_formation.find_space_of(context.attacking_card)`,
applies the formula, and resolves via the same `_by_occupancy()` helper
every other row-based scope uses — no candidates if the computed row falls
off the board (doesn't happen for any of the 4 real cards, but a card with
a different N/row_requirement combination could hit this) or if
`attacking_card` isn't set yet.

**Real integration bug found and fixed alongside it**: `GameScreen._build_context()`
built a fresh `TargetContext` without ever passing `attacking_card` —
harmless for every other scope, since `Turn.play_attack_command()` sets it
internally right before resolving, but fatal for the *pre-resolution*
highlight step (`_attack_target_candidates()`, called to decide what to
light up *before* the player clicks a target), which calls
`TargetResolver.get_candidates()` directly. Fixed by passing
`selected_attacker` through — it's `null` until an attacker's actually
chosen, which is fine, since `ROWS_AWAY` is the only scope that needs it at
that stage and nothing reads it before then.

Verified: the formula against all 4 cards' full legal-row range (12 cases
total across the two distinct N values); a full `CombatResolver.resolve_attack()`
call proving Far Strike cast from Row II actually deals damage to a card
sitting in the opponent's Row I; Close Strike unaffected (regression
check); and the `GameScreen` integration end-to-end — choosing an attacker
in Row II for Far Strike correctly highlights only the opponent's Row I,
not Row II.

## Wired up Swap and Utility Commands (2026-09-07)

Extended `GameScreen` with two more actions from the deferred list, reusing
the same click-to-select/click-to-target/refresh pattern the first
interactive pass established.

**Real bug found and fixed before wiring up "play a non-attack Command" at
all**: `Turn.play_command()` accepted *any* non-Attack Item card, including
Instants — but every Instant's ability triggers on `ON_ATTACKED`/
`ON_MELEE_ATTACKED`/`ON_RANGED_ATTACKED`, never `ON_PLAY`. Per the
rulebook, Instants are the only Command playable on the *opponent's* turn,
in response to being attacked (resolved via `CombatResolver.resolve_attack()`'s
`instant_effects` parameter, chosen by the defending player — a "respond to
attack" flow this project hasn't built yet). Routing an Instant through
`play_command()` would silently no-op: spend AP, discard it, find no
`ON_PLAY` ability to fire, and do nothing the card actually says. Fixed
`Turn.play_command()` to only accept `ItemType.UTILITY`; `GameScreen` shows
a clear explanation instead of a silent no-op if you click an Instant
during your own turn.

**Second real bug found and fixed, in `Turn` itself**: `swap_connected()`
only checked `Formation.are_connected()`, not that both spaces actually
held an Elemental — the rulebook says "swap the positions of 2 connected
**Elementals**." Without the check, you could "swap" an occupied space
with an empty one, effectively a free unvalidated move. Fixed by requiring
both `get_card()` calls to be non-null.

**Swap**: a new `Swap` button starts `SWAP_SELECT_FIRST`/`SWAP_SELECT_SECOND`
— pick any occupied space on your board, then any occupied space connected
to it (`_connected_occupied_spaces()`, a new small query mirroring
`Formation.get_valid_summon_spaces()`), then `Turn.swap_connected()`.

**Utility Commands** — the more involved piece: `Turn.play_command()`
already fires whatever a Utility Command's `ON_PLAY` ability can resolve on
its own and returns the leftover effects still needing a target (per
`AbilityFirer.fire()`'s existing contract). `GameScreen` now walks through
those one target at a time, in declared order (`pending_effects`/
`pending_target_index`/`pending_chosen`), generalizing the attack-target
pattern to handle what none of the 4 Utility Commands avoid: **more than
one target per effect** (`SWAP_FIELD_POSITION` — Elemental Swap, Exchange
of Nature — needs two separate picks resolved in sequence before the swap
itself executes) and **more than one effect per command** (Obliterate:
remove-boosts-and-shields, then deal damage, executed as two sequential
single-target steps). A new "Confirm Selection" button appears whenever a
target's `count > 1`, since `TargetSelection.CHOOSE_N` always means "up to
count," not "exactly" (already the case elsewhere in the codebase, e.g.
`TargetResolver.validate_choice()`) — without it there'd be no way to
stop early on a target that allows fewer picks than its max.

**Explicitly out of scope this round**: Utility Commands needing a
`HAND`/`DISCARD_PILE` target (Elemental Incantation's "discard 3 from your
hand") — picking a hand card to fulfill a pending target needs to be told
apart from "click this hand card to play it," a distinction `GameScreen`
doesn't make yet. `_begin_pending_effect()` detects this up front and says
so explicitly rather than breaking silently; whatever the command already
resolved automatically before hitting that effect still happened.

**A real bug caught while testing, not by inspection**: re-clicking an
already-selected space during multi-select was treated as an invalid
click and cancelled the *entire* selection, instead of being a harmless
no-op. Fixed by checking "already chosen" before "is it a legal candidate
at all," and returning early without touching any state.

Verified headlessly: Swap (by reference identity, not just matching card
names — Cedar's Row I/II cards actually traded places); Obliterate's two
sequential single-target effects (boosts/shields cleared, *then* damage
landed, in that order); Elemental Swap's two-targets-in-one-effect case
(confirmed by object identity, since both spaces coincidentally held
same-named cards — matching names alone wouldn't have proven anything
actually moved); Instants correctly refused with an explanatory message
and no state consumed; and, via a synthetic multi-select effect (since
none of the 4 real Utility Commands currently reach a working `count > 1`
case — Incantation's is blocked by the `HAND`-scope gap above), the
Confirm-early and duplicate-click-is-a-no-op paths specifically.

## Wired up the Market (2026-09-07)

Added the Elemental and Command Markets to `GameScreen`, reusing
`CardRowDisplay` exactly as designed back when it was built (`set_cards(market.face_up)`
was already spot-tested with a real `Market` at that point — this just
makes it live and clickable). Two `Market` instances built alongside the
dev `Match`; a `MarketSection` (both markets side by side, each with its
own `CardRowDisplay` + "Refresh" button) is shown only during the Market
phase.

**Buying** resolves immediately on click (`Turn.buy_from_market()`, no
target choice needed — it always goes to the discard pile). **Selling**
reuses the existing hand-click entry point: `_on_hand_card_pressed()` now
checks the phase first and sells instead of playing when in Market phase,
since summon/attack/play_command are all Actions-phase-only anyway, so a
hand click could never have meant "play" during Market phase regardless.
**Refresh** is a plain button per market.

**Explicitly out of scope**: "buy and summon directly"
(`Market.ELEMENTAL_DIRECT_SUMMON_SURCHARGE`) — a plain purchase always
lands in the discard pile; paying the surcharge to summon straight onto
the board needs its own space-selection step layered on top of buying,
deferred for now (noted in `GameScreen`'s class doc alongside the other
explicit scope cuts).

**Real usability bug caught from the screenshot, not a script check**:
the Draw and Swap buttons stayed enabled during the Market/Cleanup phases,
even though both are Actions-phase-only under the hood
(`Turn._spend_ap()`) — clicking either outside Actions would silently
no-op with no feedback. Fixed by disabling both outside the Actions phase
(Market cards/refresh were already correctly gated for free, since the
whole `MarketSection` is hidden outside the Market phase). Another
reminder that a screenshot catches things headless data checks don't.

Verified headlessly: the Market panel only appears during the Market
phase with 3 real face-up cards each; buying moves the right card to
discard, spends the right gold, and the slot refills; an unaffordable
purchase is rejected cleanly with a clear message and the listing
unchanged; selling a hand card during Market phase adds the correct
`sell_value` gold and shrinks the hand; refreshing changes the face-up
listing while keeping it at 3 cards; and Draw/Swap are correctly disabled
outside the Actions phase (both during Market and Cleanup).

## Real bug: buying from either Market silently did nothing (2026-09-07)

User report: "everything seems to work except buying from either shop." The
headless verification of the Market wiring above only ever called
`_on_market_card_pressed()` directly, never through an actual click — so it
never exercised the signal-binding path a real click goes through, and it
missed a real signature bug there.

`CardDisplay.pressed` always emits with `self` as its one argument
(`pressed.emit(self)`); `_refresh_all()` binds `(market, index)` on top of
that with `.connect(_on_market_card_pressed.bind(elemental_market, i))`, so
the actual call is `_on_market_card_pressed(display, market, index)` — 3
arguments. The handler was declared `_on_market_card_pressed(market: Market,
index: int)`, missing the leading `display` parameter the signal always
sends (the hand-card handler got this right:
`_on_hand_card_pressed(display: CardDisplay, hand_index: int)` — the market
one just didn't match the pattern). Every click threw "Method expected 2
argument(s), but called with 3" and the click silently did nothing — no
crash visible to a player, no status update either.

Fixed by adding the missing leading parameter:
`_on_market_card_pressed(_display: CardDisplay, market: Market, index: int)`.

Caught this time by actually driving a real click — a synthetic
`InputEventMouseButton` pushed through `Viewport.push_input(event, true)` (the
`true` is `in_local_coords`; without it the event is interpreted in real
desktop screen coordinates, which don't line up with the window's own
coordinate space and every synthetic click silently misses, hand cards
included — a second gotcha this same investigation turned up, see
`reference_godot_gotchas.md`) at the card's `get_global_rect()` center,
after scrolling it into view within the window's actual clamped height. This
is a stronger verification technique than either plain data-assertion
scripts or a static screenshot — it's the first time this session a signal
*call itself* was exercised end-to-end rather than just the handler function
called directly. Re-verified: buying from both markets now spends the right
gold, discards the right card, refills the slot, and an unaffordable buy
still correctly says so.

## Buy and summon directly (2026-09-07)

Wired up `Turn.buy_and_summon_from_market()` (already existed, backed by real
game logic since the Market module was built — see `market/market.gd`'s
`ELEMENTAL_DIRECT_SUMMON_SURCHARGE`, never previously exposed in
`GameScreen`). The rulebook makes this always-optional: pay 2 extra gold
on top of an Elemental's price and it lands straight in an empty formation
space instead of the discard pile.

Since a plain buy and a surcharged direct summon are both always legal and
it's the player's choice which one they want, this isn't guessed from
context (e.g. "auto-summon whenever there's room") — a new `DirectSummonToggle`
`CheckButton` in the Elemental Market column makes the choice explicit
before the click: toggle off, a click buys normally (unchanged); toggle on,
a click on an Elemental Market card starts a click-to-target flow
(`InteractionState.MARKET_SUMMON_SELECT_SPACE`, same shape as summoning
from hand) highlighting `Formation.get_valid_summon_spaces()`, and clicking
a highlighted space resolves the buy+surcharge+summon atomically through
the existing `Turn` method. If gold or space isn't there when the card's
clicked, it says so and doesn't change any state, rather than starting a
targeting flow doomed to fail. The Command Market has no such toggle
effect at all (Commands are never `ElementalCardDefinition`s) — clicking
there always plain-buys regardless of the toggle's state.

Verified headlessly: plain buy still works with the toggle off; with it on,
buying spends `price + surcharge` gold, puts the card on the board (not the
discard pile) at the chosen space, and leaves the discard pile untouched;
an unaffordable-or-no-space attempt is rejected with a specific message and
no state change; the Command Market ignores the toggle entirely; a mis-click
cancels back to idle. Note: a fresh 2-player formation starts completely
full (1+2+3 row capacities, exactly what setup places), so this path is
only reachable once a formation space actually opens up (a card defeated,
or the not-yet-built shift-forward flow) — the test freed a space manually
to exercise it, same as a real game would need a defeat to happen first.

## Wired up Daybreak and faction actions (2026-09-07)

Two whole turn phases had no UI at all until now: Phase I (Daybreak) was
skipped once at match start with no way for any *later* turn to leave it,
and faction actions were never exposed even though `player/faction_actions.gd`
already had all 12 Sages' mechanics implemented from an earlier session.

**Real, previously-undiscovered bug found and fixed first**: `PlayerSetup`
built every Sage/Warrior/Champion for a starting formation by calling
`SageCards.all()`/`WarriorCards.by_element()`/`ChampionCards.by_element()`
directly, bypassing `CardLibrary.all()` — the only place abilities actually
get attached (`CardLibrary._attach_abilities()`). That meant every card
placed on a starting formation had a permanently empty `.ability` array —
Daybreak, on-attack, everything — while anything bought later from a Market
(which does route through `CardLibrary.all()`) worked fine. This was
completely invisible before now because Daybreak itself was never reachable
in the UI. Fixed by re-mapping each selected Sage/Warrior/Champion to its
`CardLibrary`-sourced (ability-attached) counterpart by name inside
`PlayerSetup._setup_player()`/`_find_sage()`, without touching the
selection/filtering logic itself.

**Daybreak**: found a second real gap while researching — eligibility was
checked against the *live* formation on every call
(`get_available_daybreak_abilities()`/`use_daybreak_ability()` via
`TriggerDetector`), not a snapshot from turn start. Two real cards (River
Rogue, Whirl Whipper) move Elementals between rows as their own Daybreak
effect, which could incorrectly show/hide *other* cards' Daybreak
eligibility mid-phase. Fixed with `Turn._daybreak_row_snapshot` (populated
once in `_init()`, since `phase` always starts at `DAYBREAK`) and a new
`TriggerDetector.find_eligible_at_row()` that checks a given row instead of
deriving it live — `find_eligible()`/`find_eligible_on_card()` are
untouched, since every other trigger correctly wants live position.
Verified with a hand-built formation (River Rogue swapping a shielded
Granite Rampart out of Row II and an Onyx Bearer into it): Granite Rampart
stayed eligible after moving out, Onyx Bearer stayed ineligible after moving
in — both directions of the fix confirmed.

With that fixed, `GameScreen` highlights every self-formation space with a
currently-eligible, unused Daybreak ability (no new `InteractionState` —
it's a per-phase overlay on `IDLE`, since nothing else is selectable during
Daybreak); clicking one fires it through `Turn.use_daybreak_ability()` and
feeds any leftover targets straight into the *same* `_start_command_targeting()`
sequencer Utility Commands already use. `_ready()`'s one-time auto-skip past
Daybreak is gone — turn 1 behaves like every other turn. Hand-card clicks
during Daybreak now say so explicitly instead of silently failing deep
inside `Turn._spend_ap()`'s phase check.

**Faction actions (Cedar + Gravel only — Torrent/Porella deferred, they need
discard-pile browsing UI that doesn't exist yet)**: unlike card abilities,
`FactionActions`'s 12 functions are bespoke (numeric amounts, an arbitrary
multi-space distribution) and don't produce `AbilityEffect`/`AbilityTarget`
arrays, so none of the existing sequencer applies. Added 5 new named
`InteractionState`s and a dynamically-rebuilt `FactionActionRow` (one Button
per currently-unlocked-and-usable level) plus a `FactionAmountSpinBox` +
the existing `ConfirmButton` for the two actions needing a numeric spend
(1-3 boosts, 1-2 shields):
- **Cedar L4**/**Gravel L4**: no target, one-shot on click.
- **Cedar L6**: click a self Elemental to boost (amount = connected Twig count).
- **Cedar L8**/**Gravel L8**: source (Cedar only — Gravel's is always its
  Sage) → amount via SpinBox+Confirm → enemy target → damage.
- **Gravel L6**: the one genuinely irreversible-from-the-first-click action —
  `collect()` zeroes every shield on the board before any are placed back, so
  AP is spent and `collect()` runs immediately, before any UI appears; then a
  repeat-until-done loop (pick a self space → amount → repeat) accumulates a
  distribution and only calls `distribute()`/refreshes once every shield's
  placed. A mis-click during this specific loop is a no-op, not the usual
  cancel-back-to-IDLE, since the shields are already off the board and
  abandoning would strand them.

AP is spent at the point each action becomes irreversible, not on the first
click, matching `faction_actions.gd`'s own stated contract.

Verified headlessly (all 6 flows, both sides, across a real turn hand-off via
`Match.finish_turn()`, including a multi-chunk Gravel L6 distribute and both
insufficient-resource rejections) and via real synthetic clicks
(`Viewport.push_input(event, true)`) driving one full Daybreak ability and
the entire Cedar L8 source→amount→Confirm→enemy-target chain end-to-end —
the lesson from the Market `.bind()` bug was to exercise the actual signal
path, not call handlers directly.

## Not done yet / explicitly deferred
- **Shift-forward-on-defeat.** When a card is defeated, `Formation.remove_card()`
  correctly just clears that space rather than auto-compacting (see the
  "Formation board" section above — the rulebook makes *which* card moves
  up the player's choice whenever more than one connected back-row
  candidate exists, so it can't be a mechanical auto-shift). But the actual
  player-facing flow was never built: detect that a front row now has an
  empty space with an occupied space behind it, offer the player the
  connected candidate(s) to move up (`Formation.move_card()` already
  exists as the primitive), and check whether *that* move opened a new gap
  one row further back — repeating until every row that can be filled is
  filled. Flagged back when `Formation` was first built and explicitly
  deferred to "the future resolver," but never circled back to despite all
  the resolver/UI work since — rediscovered when the user asked directly
  whether this was handled. **Deliberately left deferred** (user's own
  call): this needs the same underlying capability as playing Instants in
  response to being attacked (also deferred — see `Turn.play_command()`'s
  doc comment) — pausing the *active* player's action to prompt the
  *non-active* side for input, then resuming. `GameScreen` has no such
  flow at all yet (everything so far is single-side, one action at a
  time). Bundle these two together as one future increment once that
  prompt-the-other-side capability gets built, rather than building it
  twice.
- **The ~50 extra cards found on the wiki** (new Warriors like Aqua Acrobat/
  Cobra King/Rock Buck, new Attacks/Instants, and a whole new "Ritual Command"
  card type) — user explicitly chose to scope this pass to the existing 86
  only. Revisit as its own decision if/when expanding the roster.
- **2 of the 5 combat-modifier actions**: `DONT_REMOVE_SHIELD` (zero cards
  use it) and `REDIRECT_DAMAGE_TO_SELF` (King Crustacean/Terrain Tumbler —
  needs a player-opt-in parameter and per-card handling of the
  position-swap nuance, not just detection). `DONT_REMOVE_BOOST` and both
  Instant Command actions (`REDUCE_DAMAGE`/`NEGATE_DAMAGE`) are done.
- **Event wiring for the other 10 `AbilityTrigger`s** not touched by combat
  (`ON_ALLY_ENTER_FORMATION`, `ON_SHIELD_ADDED`/`ON_SHIELD_REMOVED`,
  `ON_ENTER_ROW`, `ON_ALLY_LEAVE_FORMATION`, `ON_DEFEATED`,
  `ON_ATTACKED`/`ON_MELEE_ATTACKED`/`ON_RANGED_ATTACKED` — for surfacing
  which Instants are eligible to play in response — and
  `ON_DAMAGE_ABOUT_TO_BE_DEALT_TO_ALLY`). `TriggerDetector` works generically
  for all of them; what's missing is a higher-level game-flow loop to call
  `find_eligible()` at the right moments (after every Formation mutation) —
  that loop doesn't exist yet, same as the turn/AP economy below. Combat
  itself now fires everything it can find on the attacker (`ON_ATTACK`/
  `ON_MELEE_ATTACK`/`ON_RANGED_ATTACK`/`ON_DAMAGE_DEALT`/`ON_DEFEAT_ENEMY`),
  returning anything needing a fresh target choice rather than executing or
  dropping it silently.
- **Game setup flow above `Match`** — `Match` orchestrates turns/win
  condition once both sides already exist, but there's still no code path
  from "players pick Sages/Warriors" through to a running `Match` (the old
  repo's `GameState`'s JOINING_GAME/SAGE_SELECTION/WARRIOR_SELECTION phases
  have no equivalent here) — not needed until there's a UI to drive it.
- **The rest of the interactive game screen** — draw/summon/single-target
  Attack Command/swap/Utility Commands/Market/turn hand-off/win
  condition/Daybreak/faction actions (Cedar+Gravel) all work now, but still
  not wired up: Torrent's and Porella's faction actions (need discard-pile
  browsing UI that doesn't exist yet), multi-target Attack Commands, and
  Utility Commands needing a `HAND`/`DISCARD_PILE` target (Elemental
  Incantation) — all reuse patterns already built, so each is a fast
  follow-up, not a redesign. Also still no Sage/Warrior setup-picker screen
  (the dev `Match` is hardcoded) and no 4-player screen support (the
  interaction code assumes `players[0]`/a single hand; extending to a
  team's two hands is its own increment). No "start a new match" flow
  either — the screen just stops once `is_over()`.
- Tokens as physical/visual game elements (vs. the plain `int` counters
  already on `CardInstance`) — `CardDisplay` shows them as text badges for
  now; real token art can replace that later without changing the data path.
- No card art (`art` is unset on every card — old repo also had `img: ""` for
  everything, so there's nothing to port yet). `CardDisplay` uses an
  element-tinted placeholder in the meantime.

## How to pick this back up
The user works in small increments and brings the next piece themselves (a card,
a mechanic, a phase). Don't pre-build ahead of what's asked. When resuming, check
this file, `rules.pdf`, and the GitHub link above before assuming any card or
mechanic details.
