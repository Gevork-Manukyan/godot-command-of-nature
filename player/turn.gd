class_name Turn
extends RefCounted

## One player's turn: phase tracking, AP spending, and the per-turn limits
## the rulebook attaches to them (each Daybreak ability once, one faction
## action, each Elemental attacking at most once). A fresh Turn should be
## created for each player's turn rather than reusing/resetting one -- the
## caller advances through Phase.DAYBREAK -> ACTIONS -> MARKET -> CLEANUP
## via advance_phase() and starts a new Turn for whoever goes next.
##
## MAX_AP (4) and PlayerState are both scoped to 2-player for now; 4-player
## team mode shares 6 AP and shares PlayerState's formation/gold at the team
## level instead of per-player, which is a different composition not built
## yet (see PlayerState).
##
## Faction actions: can_use_faction_action(level)/spend_faction_action_ap(level)
## track the AP cost, once-per-turn limit, and that the given level's action
## has actually been unlocked (player.unlocked_faction_action_levels) --
## the actual per-Sage mechanics live in FactionActions, called separately
## once AP is spent (see FactionActions for why they're not Turn methods).
##
## Standard actions never guess a player's choice -- draw/summon/swap take
## the caller's chosen space/index and validate it; play_command()/
## play_attack_command() return whatever AbilityFirer/CombatResolver
## couldn't resolve on their own for the caller to finish.

enum Phase { DAYBREAK, ACTIONS, MARKET, CLEANUP }

const MAX_AP := 4
const STANDARD_ACTION_COST := 1
const FACTION_ACTION_COST := 1
const MAX_HAND_SIZE := 5

var player: PlayerState
var opponent: PlayerState
var phase: Phase = Phase.DAYBREAK
var ap_remaining: int = MAX_AP
var used_daybreak_cards: Array[CardInstance] = []
var used_faction_action: bool = false
var attacked_this_turn: Array[CardInstance] = []

func _init(p_player: PlayerState, p_opponent: PlayerState):
	player = p_player
	opponent = p_opponent

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
				push_error("Turn: hand must be at most %d cards before ending the turn" % MAX_HAND_SIZE)
				return false
			return true
	return false

# ------------ PHASE I: DAYBREAK ------------

func get_available_daybreak_abilities() -> Array:
	if phase != Phase.DAYBREAK:
		return []
	var available := []
	for entry in TriggerDetector.find_eligible(CardEnums.AbilityTrigger.DAYBREAK, player.formation):
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
	if TriggerDetector.find_eligible_on_card(card, CardEnums.AbilityTrigger.DAYBREAK, player.formation) != ability:
		push_error("Turn: that ability isn't currently eligible")
		return []
	used_daybreak_cards.append(card)
	return AbilityFirer.fire(ability, context)

# ------------ PHASE II: STANDARD & FACTION ACTIONS ------------

func draw_card() -> CardDefinition:
	if not _spend_ap(STANDARD_ACTION_COST):
		return null
	var drawn := player.deck.draw(player.discard_pile)
	if drawn != null:
		player.hand.add(drawn)
	return drawn

func summon_from_hand(hand_index: int, space_number: int) -> CardInstance:
	var definition := _peek_hand(hand_index)
	if definition == null or not (definition is ElementalCardDefinition):
		push_error("Turn: summon_from_hand needs a valid Elemental card in hand")
		return null
	if not player.formation.get_valid_summon_spaces().has(space_number):
		push_error("Turn: %d is not a legal summon space right now" % space_number)
		return null
	if not _spend_ap(STANDARD_ACTION_COST):
		return null
	player.hand.remove_at(hand_index)
	var instance := CardInstance.new(definition)
	player.formation.summon(instance, space_number)
	return instance

func swap_connected(space1: int, space2: int) -> bool:
	if not player.formation.are_connected(space1, space2):
		push_error("Turn: spaces %d and %d aren't connected" % [space1, space2])
		return false
	if not _spend_ap(STANDARD_ACTION_COST):
		return false
	return player.formation.swap_cards(space1, space2)

## Plays a non-Attack Command (Instant or Utility) from hand. Returns
## whatever its ON_PLAY effects couldn't resolve on their own (see
## AbilityFirer.fire()).
func play_command(hand_index: int, context: EffectContext) -> Array:
	var definition := _peek_hand(hand_index)
	if definition == null or definition is ItemAttackCardDefinition or not (definition is ItemCardDefinition):
		push_error("Turn: play_command needs an Instant/Utility Command in hand (use play_attack_command for Attacks)")
		return []
	if not _spend_ap(STANDARD_ACTION_COST):
		return []
	player.hand.remove_at(hand_index)
	player.discard_pile.add(definition)
	var pending := []
	for ability in definition.ability:
		if ability.trigger == CardEnums.AbilityTrigger.ON_PLAY:
			pending.append_array(AbilityFirer.fire(ability, context))
	return pending

## Plays an Attack Command from hand, using `attacker` (must be on
## player.formation, in one of the card's legal rows, and not already
## attacked this turn). chosen_per_target/instant_effects are passed
## straight through to CombatResolver.resolve_attack(). Returns just the
## "pending" abilities needing a target choice (see there) -- defeats are
## applied to player.level internally (level_up() once per target this
## attack defeated), not returned, since nothing outside this method needs
## the raw count.
func play_attack_command(hand_index: int, attacker: CardInstance, chosen_per_target: Array, context: EffectContext, instant_effects: Array[AbilityEffect] = []) -> Array:
	var definition := _peek_hand(hand_index)
	if definition == null or not (definition is ItemAttackCardDefinition):
		push_error("Turn: play_attack_command needs an Attack Command in hand")
		return []
	if attacked_this_turn.has(attacker):
		push_error("Turn: %s has already attacked this turn" % attacker.definition.card_name)
		return []
	var attacker_space := player.formation.find_space_of(attacker)
	if attacker_space == -1:
		push_error("Turn: the attacker isn't on your formation")
		return []
	var attacker_row := player.formation.get_space(attacker_space).row
	if not definition.row_requirement.is_empty() and not definition.row_requirement.has(attacker_row):
		push_error("Turn: %s can't be used from Row %d" % [definition.card_name, attacker_row])
		return []
	if not _spend_ap(STANDARD_ACTION_COST):
		return []

	player.hand.remove_at(hand_index)
	player.discard_pile.add(definition)
	attacked_this_turn.append(attacker)
	var result := CombatResolver.resolve_attack(definition.ability[0].effects[0], definition.attack_type, chosen_per_target, context, instant_effects)
	for i in range(result["defeated_count"]):
		player.level_up()
	return result["pending"]

func has_attacked(card: CardInstance) -> bool:
	return attacked_this_turn.has(card)

## Exposed for actions that trigger an attack outside play_attack_command
## (e.g. Porella's level-4 faction action, playing an Attack Command from
## the discard pile instead of hand) so they can still respect "each
## Elemental attacks at most once per turn."
func mark_attacked(card: CardInstance) -> void:
	attacked_this_turn.append(card)

func can_use_faction_action(level: int) -> bool:
	return phase == Phase.ACTIONS and not used_faction_action \
		and ap_remaining >= FACTION_ACTION_COST and player.unlocked_faction_action_levels.has(level)

func spend_faction_action_ap(level: int) -> bool:
	if not can_use_faction_action(level):
		return false
	ap_remaining -= FACTION_ACTION_COST
	used_faction_action = true
	return true

# ------------ PHASE III: MARKET ------------

func buy_from_market(market: Market, index: int) -> CardDefinition:
	if phase != Phase.MARKET:
		push_error("Turn: not in the Market phase")
		return null
	var card := market.buy(index, player.gold)
	if card != null:
		player.discard_pile.add(card)
	return card

## Per the rulebook, paying Market.ELEMENTAL_DIRECT_SUMMON_SURCHARGE on top
## of an Elemental's price brings it straight into the formation instead of
## the discard pile, if there's room.
func buy_and_summon_from_market(market: Market, index: int, space_number: int) -> CardInstance:
	if phase != Phase.MARKET:
		push_error("Turn: not in the Market phase")
		return null
	if index < 0 or index >= market.face_up.size() or not (market.face_up[index] is ElementalCardDefinition):
		push_error("Turn: buy_and_summon_from_market needs a valid Elemental market index")
		return null
	var total_cost := market.face_up[index].price + Market.ELEMENTAL_DIRECT_SUMMON_SURCHARGE
	if player.gold.amount < total_cost or not player.formation.get_valid_summon_spaces().has(space_number):
		return null
	var card := market.buy(index, player.gold)
	if card == null:
		return null
	player.gold.remove(Market.ELEMENTAL_DIRECT_SUMMON_SURCHARGE)
	var instance := CardInstance.new(card)
	player.formation.summon(instance, space_number)
	return instance

func sell_from_hand(hand_index: int) -> void:
	if phase != Phase.MARKET:
		push_error("Turn: not in the Market phase")
		return
	var card := player.hand.remove_at(hand_index)
	if card == null:
		return
	player.gold.add(Market.sell_value(card))
	player.removed_pile.add(card)

func refresh_market(market: Market) -> bool:
	if phase != Phase.MARKET:
		push_error("Turn: not in the Market phase")
		return false
	return market.refresh(player.gold)

# ------------ PHASE IV: CLEANUP ------------

func discard_from_hand(hand_index: int) -> CardDefinition:
	if phase != Phase.CLEANUP:
		push_error("Turn: not in the Cleanup phase")
		return null
	var card := player.hand.remove_at(hand_index)
	if card != null:
		player.discard_pile.add(card)
	return card

func draw_to_hand_size() -> void:
	if phase != Phase.CLEANUP:
		push_error("Turn: not in the Cleanup phase")
		return
	while player.hand.size() < MAX_HAND_SIZE:
		var drawn := player.deck.draw(player.discard_pile)
		if drawn == null:
			break
		player.hand.add(drawn)

func can_end_cleanup() -> bool:
	return player.hand.size() <= MAX_HAND_SIZE

# ------------ shared ------------

func _spend_ap(cost: int) -> bool:
	if phase != Phase.ACTIONS:
		push_error("Turn: not in the Actions phase")
		return false
	if ap_remaining < cost:
		return false
	ap_remaining -= cost
	return true

func _peek_hand(hand_index: int) -> CardDefinition:
	var cards := player.hand.get_all()
	if hand_index < 0 or hand_index >= cards.size():
		return null
	return cards[hand_index]
