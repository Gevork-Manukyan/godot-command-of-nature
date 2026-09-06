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
- `cards/card_library.gd` — `CardLibrary`: static factory functions, **one
  example card per type only** (explicit scope decision, not the full roster):
  `cedar()` (Sage), `vix_vanguard()` (Champion), `acorn_squire()` (Warrior),
  `timber()` (Basic Elemental), `close_strike()` (Attack item), `droplet_charm()`
  (Instant item), `elemental_incantation()` (Utility item).

Verified by running headlessly via
`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script <temp script> --quit`
— all 7 factories instantiate correctly, `CardInstance` boost/damage math checked
out. No permanent test file was kept; that was a one-off scratch verification.

## Not done yet / explicitly deferred
- No ability *logic* — only the data shape (`AbilityEffect`) exists. Real
  per-card abilities need the physical card text, which isn't available yet.
- Full ~90-card roster not ported — only 1 example per type exists, by explicit
  choice, to prove the shape first.
- Formation board (3 rows, slot rules), AP economy/turn phases, combat
  resolution, market (buy/sell/refresh), leveling, tokens (boost/shield/damage/
  gold) — none implemented yet.
- Old prototype's `game.gd`/`card.gd` not yet connected to the new `cards/` system.
- 4-player/team rules not implemented (just kept in mind structurally).

## How to pick this back up
The user works in small increments and brings the next piece themselves (a card,
a mechanic, a phase). Don't pre-build ahead of what's asked. When resuming, check
this file, `rules.pdf`, and the GitHub link above before assuming any card or
mechanic details.
