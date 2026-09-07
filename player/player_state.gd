class_name PlayerState
extends RefCounted

## One player's state: hand, deck, discard/removed piles, level, and locked
## Champions are always individual. Formation and gold are individual too in
## 2-player (the default constructor builds a fresh one of each), but the
## rulebook shares both at the TEAM level in 4-player mode -- so
## PlayerSetup.new_team() passes an existing shared Formation/GoldPool in
## instead of letting this class build its own. Leveling is confirmed
## per-player even in 4-player mode (not shared), so level/
## unlocked_faction_action_levels never take a shared override.

const LEVEL_THRESHOLDS: Array[int] = [4, 6, 8]
const MAX_LEVEL := 8

var formation: Formation
var hand: CardZone
var deck: Deck
var discard_pile: CardZone
var removed_pile: CardZone
var gold: GoldPool
## This player's own Sage card instance, set once by PlayerSetup when it's
## placed on the formation. Anything that needs "your Sage" (SELF_SAGE
## target resolution, FactionActions' level-8 abilities) should read this
## directly rather than searching `formation` for one -- on a 4-player
## team's shared formation there are two Sages, and Formation.get_sage()
## can't tell them apart.
var sage: CardInstance
## The 3 Champions from this player's Sage pack, face down until level_up()
## reveals them.
var locked_champions: Array[ElementalChampionCardDefinition] = []
var level: int = 1
## Which of LEVEL_THRESHOLDS this player has reached -- once unlocked, a
## faction action stays usable "for the remainder of the game" per the
## rulebook, so this only ever grows. Turn.can_use_faction_action() checks it.
var unlocked_faction_action_levels: Array[int] = []

func _init(shared_formation: Formation = null, shared_gold: GoldPool = null):
	formation = shared_formation if shared_formation != null else Formation.new_two_player()
	hand = CardZone.new()
	deck = Deck.new()
	discard_pile = CardZone.new()
	removed_pile = CardZone.new()
	gold = shared_gold if shared_gold != null else GoldPool.new(12)

## Call once per Elemental this player defeats in combat (see
## CombatResolver.resolve_attack()'s defeated_count). Crossing a threshold
## unlocks that level's faction action and moves the matching locked
## Champion into the discard pile, per the rulebook. No-ops once this
## player's own Sage is defeated -- per the rulebook (4-player mode: "if
## your Sage is defeated but your teammate's Sage is not, you may continue
## playing; however, you cannot use any faction actions or increase your
## level ... for the remainder of the game"). In 2-player this is moot --
## the match is already over once your lone Sage falls (see Match) -- but
## the check is harmless there too.
func level_up() -> void:
	if level >= MAX_LEVEL or (sage != null and sage.is_defeated()):
		return
	level += 1
	if LEVEL_THRESHOLDS.has(level):
		_unlock(level)

func _unlock(threshold: int) -> void:
	unlocked_faction_action_levels.append(threshold)
	for i in range(locked_champions.size()):
		if locked_champions[i].level_requirement == threshold:
			var champion: ElementalChampionCardDefinition = locked_champions.pop_at(i)
			discard_pile.add(champion)
			return
