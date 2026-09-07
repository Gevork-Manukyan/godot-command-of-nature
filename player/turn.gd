class_name Turn
extends RefCounted

## One side's turn: phase tracking, AP spending, and the per-turn limits the
## rulebook attaches to them (each Daybreak ability once, one faction action,
## each Elemental attacking at most once). A fresh Turn should be created for
## each turn rather than reusing/resetting one -- the caller advances through
## Phase.DAYBREAK -> ACTIONS -> MARKET -> CLEANUP via advance_phase() and
## starts a new Turn for whoever goes next.
##
## `players` holds the 1 (2-player) or 2 (4-player team) PlayerStates taking
## this turn. AP, phase, and the per-turn limits above are genuinely shared
## across a team's turn (6 AP total, not 4+4, per the rulebook -- confirmed
## by the user, not simply double the 2-player value of 4) and live once on
## this Turn instance; `used_daybreak_cards`/`attacked_this_turn` already
## work unchanged for a team since they're keyed by CardInstance, not by
## which teammate acted (the rulebook: either teammate can attack with any
## Elemental in the shared formation, just not the same one twice).
##
## Hand/deck/discard/removed pile/level/locked-Champions stay individual per
## teammate even in team mode (confirmed by the user: a teammate's hand can
## be viewed, never played from) -- every action touching one of those takes
## a `player_index` (default 0, so 2-player call sites are unaffected).
## Actions that only touch shared state (formation, gold) never take one:
## swap_connected(), buy_and_summon_from_market(), refresh_market().
##
## Faction actions: can_use_faction_action(level, player_index)/
## spend_faction_action_ap(level, player_index) track the AP cost,
## once-per-team-turn limit, and that the acting player specifically has
## that level unlocked (leveling is per-player even in team mode, see
## PlayerState) -- the actual per-Sage mechanics live in FactionActions,
## called separately once AP is spent (see FactionActions for why they're
## not Turn methods).
##
## Standard actions never guess a player's choice -- draw/summon/swap take
## the caller's chosen space/index and validate it; play_command()/
## play_attack_command() return whatever AbilityFirer/CombatResolver
## couldn't resolve on their own for the caller to finish.

enum Phase { DAYBREAK, ACTIONS, MARKET, CLEANUP }

const MAX_AP_2_PLAYER := 4
const MAX_AP_4_PLAYER := 6
const STANDARD_ACTION_COST := 1
const FACTION_ACTION_COST := 1
const MAX_HAND_SIZE := 5

var players: Array[PlayerState]
var opponents: Array[PlayerState]
var phase: Phase = Phase.DAYBREAK
var ap_remaining: int
var used_daybreak_cards: Array[CardInstance] = []
var used_faction_action: bool = false
var attacked_this_turn: Array[CardInstance] = []

func _init(p_players: Array[PlayerState], p_opponents: Array[PlayerState]):
	players = p_players
	opponents = p_opponents
	ap_remaining = MAX_AP_2_PLAYER if players.size() == 1 else MAX_AP_4_PLAYER

func advance_phase() -> bool:
	match phase:
		Phase.DAYBREAK:
			phase = Phase.ACTIONS
			return true
		Phase.ACTIONS:
			phase = Phase.MARKET
			return true
		Phase.MARKET:
			phase = Phase.CLEANUP
			return true
		Phase.CLEANUP:
			if not can_end_cleanup():
				push_error("Turn: every hand must be at most %d cards before ending the turn" % MAX_HAND_SIZE)
				return false
			return true
	return false

# ------------ PHASE I: DAYBREAK ------------

func get_available_daybreak_abilities() -> Array:
	if phase != Phase.DAYBREAK:
		return []
	var available := []
	for entry in TriggerDetector.find_eligible(CardEnums.AbilityTrigger.DAYBREAK, _formation()):
		if not used_daybreak_cards.has(entry["card"]):
			available.append(entry)
	return available

## Returns whatever AbilityFirer couldn't resolve on its own (see
## AbilityFirer.fire()) -- an empty array means the ability fully executed.
func use_daybreak_ability(card: CardInstance, ability: CardAbility, context: EffectContext) -> Array:
	if phase != Phase.DAYBREAK:
		push_error("Turn: not in the Daybreak phase")
		return []
	if used_daybreak_cards.has(card):
		push_error("Turn: %s already used its Daybreak ability this turn" % card.definition.card_name)
		return []
	if TriggerDetector.find_eligible_on_card(card, CardEnums.AbilityTrigger.DAYBREAK, _formation()) != ability:
		push_error("Turn: that ability isn't currently eligible")
		return []
	used_daybreak_cards.append(card)
	return AbilityFirer.fire(ability, context)

# ------------ PHASE II: STANDARD & FACTION ACTIONS ------------

func draw_card(player_index: int = 0) -> CardDefinition:
	if not _spend_ap(STANDARD_ACTION_COST):
		return null
	var acting := _player(player_index)
	var drawn := acting.deck.draw(acting.discard_pile)
	if drawn != null:
		acting.hand.add(drawn)
	return drawn

func summon_from_hand(hand_index: int, space_number: int, player_index: int = 0) -> CardInstance:
	var acting := _player(player_index)
	var definition := _peek_hand(hand_index, player_index)
	if definition == null or not (definition is ElementalCardDefinition):
		push_error("Turn: summon_from_hand needs a valid Elemental card in hand")
		return null
	if not _formation().get_valid_summon_spaces().has(space_number):
		push_error("Turn: %d is not a legal summon space right now" % space_number)
		return null
	if not _spend_ap(STANDARD_ACTION_COST):
		return null
	acting.hand.remove_at(hand_index)
	var instance := CardInstance.new(definition)
	_formation().summon(instance, space_number)
	return instance

func swap_connected(space1: int, space2: int) -> bool:
	if not _formation().are_connected(space1, space2):
		push_error("Turn: spaces %d and %d aren't connected" % [space1, space2])
		return false
	if not _spend_ap(STANDARD_ACTION_COST):
		return false
	return _formation().swap_cards(space1, space2)

## Plays a non-Attack Command (Instant or Utility) from hand. Returns
## whatever its ON_PLAY effects couldn't resolve on their own (see
## AbilityFirer.fire()).
func play_command(hand_index: int, context: EffectContext, player_index: int = 0) -> Array:
	var acting := _player(player_index)
	var definition := _peek_hand(hand_index, player_index)
	if definition == null or definition is ItemAttackCardDefinition or not (definition is ItemCardDefinition):
		push_error("Turn: play_command needs an Instant/Utility Command in hand (use play_attack_command for Attacks)")
		return []
	if not _spend_ap(STANDARD_ACTION_COST):
		return []
	acting.hand.remove_at(hand_index)
	acting.discard_pile.add(definition)
	var pending := []
	for ability in definition.ability:
		if ability.trigger == CardEnums.AbilityTrigger.ON_PLAY:
			pending.append_array(AbilityFirer.fire(ability, context))
	return pending

## Plays an Attack Command from hand, using `attacker` (must be on the
## (possibly shared) formation, in one of the card's legal rows, and not
## already attacked this turn). Sets context.targets.attacking_card to
## `attacker` before resolving -- CombatResolver needs it for
## ATTACKER_STRENGTH-based damage (Close Strike/Far Strike and most other
## Attack Commands), and since this method already has `attacker` as its own
## parameter, the caller shouldn't have to separately duplicate it onto the
## context too. chosen_per_target/instant_effects are passed straight
## through to CombatResolver.resolve_attack(). Returns just the "pending"
## abilities needing a target choice (see there) -- defeats are applied to
## the acting player's level internally (level_up() once per target this
## attack defeated -- leveling is per-player even in team mode), not
## returned, since nothing outside this method needs the raw count.
func play_attack_command(hand_index: int, attacker: CardInstance, chosen_per_target: Array, context: EffectContext, instant_effects: Array[AbilityEffect] = [], player_index: int = 0) -> Array:
	var acting := _player(player_index)
	var definition := _peek_hand(hand_index, player_index)
	if definition == null or not (definition is ItemAttackCardDefinition):
		push_error("Turn: play_attack_command needs an Attack Command in hand")
		return []
	if attacked_this_turn.has(attacker):
		push_error("Turn: %s has already attacked this turn" % attacker.definition.card_name)
		return []
	var attacker_space := _formation().find_space_of(attacker)
	if attacker_space == -1:
		push_error("Turn: the attacker isn't on the formation")
		return []
	var attacker_row := _formation().get_space(attacker_space).row
	if not definition.row_requirement.is_empty() and not definition.row_requirement.has(attacker_row):
		push_error("Turn: %s can't be used from Row %d" % [definition.card_name, attacker_row])
		return []
	if not _spend_ap(STANDARD_ACTION_COST):
		return []

	acting.hand.remove_at(hand_index)
	acting.discard_pile.add(definition)
	attacked_this_turn.append(attacker)
	context.targets.attacking_card = attacker
	var result := CombatResolver.resolve_attack(definition.ability[0].effects[0], definition.attack_type, chosen_per_target, context, instant_effects)
	for i in range(result["defeated_count"]):
		acting.level_up()
	return result["pending"]

func has_attacked(card: CardInstance) -> bool:
	return attacked_this_turn.has(card)

## Exposed for actions that trigger an attack outside play_attack_command
## (e.g. Porella's level-4 faction action, playing an Attack Command from
## the discard pile instead of hand) so they can still respect "each
## Elemental attacks at most once per turn."
func mark_attacked(card: CardInstance) -> void:
	attacked_this_turn.append(card)

## False once the acting player's own Sage is defeated, even if the level
## was already unlocked before that happened -- per the rulebook (4-player:
## a teammate whose Sage falls keeps playing but permanently loses faction
## actions and leveling; see PlayerState.level_up()).
func can_use_faction_action(level: int, player_index: int = 0) -> bool:
	var acting := _player(player_index)
	return phase == Phase.ACTIONS and not used_faction_action and ap_remaining >= FACTION_ACTION_COST \
		and acting.unlocked_faction_action_levels.has(level) \
		and not (acting.sage != null and acting.sage.is_defeated())

func spend_faction_action_ap(level: int, player_index: int = 0) -> bool:
	if not can_use_faction_action(level, player_index):
		return false
	ap_remaining -= FACTION_ACTION_COST
	used_faction_action = true
	return true

# ------------ PHASE III: MARKET ------------

func buy_from_market(market: Market, index: int, player_index: int = 0) -> CardDefinition:
	if phase != Phase.MARKET:
		push_error("Turn: not in the Market phase")
		return null
	var card := market.buy(index, _gold())
	if card != null:
		_player(player_index).discard_pile.add(card)
	return card

## Per the rulebook, paying Market.ELEMENTAL_DIRECT_SUMMON_SURCHARGE on top
## of an Elemental's price brings it straight into the formation instead of
## the discard pile, if there's room. Doesn't touch any individual zone --
## gold and formation are both shared -- so there's no player_index; either
## teammate can spend the team's gold to summon onto the team's formation.
func buy_and_summon_from_market(market: Market, index: int, space_number: int) -> CardInstance:
	if phase != Phase.MARKET:
		push_error("Turn: not in the Market phase")
		return null
	if index < 0 or index >= market.face_up.size() or not (market.face_up[index] is ElementalCardDefinition):
		push_error("Turn: buy_and_summon_from_market needs a valid Elemental market index")
		return null
	var total_cost := market.face_up[index].price + Market.ELEMENTAL_DIRECT_SUMMON_SURCHARGE
	if _gold().amount < total_cost or not _formation().get_valid_summon_spaces().has(space_number):
		return null
	var card := market.buy(index, _gold())
	if card == null:
		return null
	_gold().remove(Market.ELEMENTAL_DIRECT_SUMMON_SURCHARGE)
	var instance := CardInstance.new(card)
	_formation().summon(instance, space_number)
	return instance

func sell_from_hand(hand_index: int, player_index: int = 0) -> void:
	if phase != Phase.MARKET:
		push_error("Turn: not in the Market phase")
		return
	var acting := _player(player_index)
	var card := acting.hand.remove_at(hand_index)
	if card == null:
		return
	_gold().add(Market.sell_value(card))
	acting.removed_pile.add(card)

func refresh_market(market: Market) -> bool:
	if phase != Phase.MARKET:
		push_error("Turn: not in the Market phase")
		return false
	return market.refresh(_gold())

# ------------ PHASE IV: CLEANUP ------------

func discard_from_hand(hand_index: int, player_index: int = 0) -> CardDefinition:
	if phase != Phase.CLEANUP:
		push_error("Turn: not in the Cleanup phase")
		return null
	var acting := _player(player_index)
	var card := acting.hand.remove_at(hand_index)
	if card != null:
		acting.discard_pile.add(card)
	return card

func draw_to_hand_size(player_index: int = 0) -> void:
	if phase != Phase.CLEANUP:
		push_error("Turn: not in the Cleanup phase")
		return
	var acting := _player(player_index)
	while acting.hand.size() < MAX_HAND_SIZE:
		var drawn := acting.deck.draw(acting.discard_pile)
		if drawn == null:
			break
		acting.hand.add(drawn)

## Team-wide: every teammate's hand must be at most MAX_HAND_SIZE, not just
## whichever one a caller happens to be looking at.
func can_end_cleanup() -> bool:
	for p in players:
		if p.hand.size() > MAX_HAND_SIZE:
			return false
	return true

# ------------ shared ------------

func _spend_ap(cost: int) -> bool:
	if phase != Phase.ACTIONS:
		push_error("Turn: not in the Actions phase")
		return false
	if ap_remaining < cost:
		return false
	ap_remaining -= cost
	return true

func _player(player_index: int) -> PlayerState:
	return players[player_index]

## Formation/gold are the same shared object across every entry in `players`
## in team mode (see PlayerSetup.new_team()) and the sole player's own in
## 2-player -- either way, reading them off players[0] is always correct.
func _formation() -> Formation:
	return players[0].formation

func _gold() -> GoldPool:
	return players[0].gold

func _peek_hand(hand_index: int, player_index: int = 0) -> CardDefinition:
	var cards := _player(player_index).hand.get_all()
	if hand_index < 0 or hand_index >= cards.size():
		return null
	return cards[hand_index]
