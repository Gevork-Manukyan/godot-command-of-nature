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

## Not done yet / explicitly deferred
- **The ~50 extra cards found on the wiki** (new Warriors like Aqua Acrobat/
  Cobra King/Rock Buck, new Attacks/Instants, and a whole new "Ritual Command"
  card type) — user explicitly chose to scope this pass to the existing 86
  only. Revisit as its own decision if/when expanding the roster.
- **Combat resolution** — the 5 actions that modify an in-progress attack
  (`REDUCE_DAMAGE`, `NEGATE_DAMAGE`, `DONT_REMOVE_BOOST`, `DONT_REMOVE_SHIELD`,
  `REDIRECT_DAMAGE_TO_SELF`) need an actual attack-sequencing system (base
  damage → +boosts → −shields → −Instant reductions → apply) that doesn't
  exist yet. `EffectExecutor` explicitly errors on these rather than
  pretending to handle them. See "Known modeling gaps" further up for the
  other unresolved nuances (conditional bonuses, "choose A or B" effects,
  contextual targets) this will also need to confront.
- **Trigger detection** — nothing decides *when* a `CardAbility` should fire
  (event wiring for things like "when this Elemental attacks" or "when an
  ally enters your formation"). Also part of the resolver, not started.
- **Market** (Elemental/Command decks with 3 face-up slots, buy/sell/refresh)
  — `Deck`/`CardZone` in `zones/` are built to support it, but the Market
  wrapper itself (face-up display, gold spending) doesn't exist yet.
- AP economy/turn phases, leveling, tokens as physical UI elements (vs. the
  plain `int` counters already on `CardInstance`) — none implemented yet.
- Old prototype's `game.gd`/`card.gd` not yet connected to any of the new
  `cards/`/`board/`/`zones/`/`resolver/` systems — still the original
  standard-deck 2-card-hand demo.
- 4-player/team rules — the data model stays ready for them (`Formation`
  supports both sizes, `TargetContext` has enemy-side hand/discard fields),
  but no actual 4-player game flow exists. Confirmed with the user: a
  teammate's hand can be *viewed*, never played from — that's the only
  4-player-specific rule interaction found so far.
- No card art (`art` is unset on every card — old repo also had `img: ""` for
  everything, so there's nothing to port yet).

## How to pick this back up
The user works in small increments and brings the next piece themselves (a card,
a mechanic, a phase). Don't pre-build ahead of what's asked. When resuming, check
this file, `rules.pdf`, and the GitHub link above before assuming any card or
mechanic details.
