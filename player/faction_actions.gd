class_name FactionActions

## The 12 per-Sage faction actions (3 per Sage, unlocked at level 4/6/8),
## transcribed directly from the physical Sage boards -- the wiki's board
## photos weren't legible enough to transcribe reliably (low resolution +
## a watermark over the text), so this data came from the user directly
## rather than being guessed at from a blurry image.
##
## These are static functions on EffectContext, not Turn methods: like
## EffectExecutor/CombatResolver, they're pure mechanics and don't know
## about AP or once-per-turn limits. The caller is expected to check
## Turn.can_use_faction_action(level) and call
## Turn.spend_faction_action_ap(level) BEFORE calling one of these -- same
## "validate first, spend AP only once the action will actually happen"
## rule as every Turn action. Porella's level-4 action additionally
## triggers a real attack; the caller should also check
## Turn.has_attacked()/call Turn.mark_attacked() around it, since
## FactionActions has no access to Turn's per-turn attacked-tracking.
##
## None of these re-validate that a chosen space/index is legal beyond a
## null check -- same contract as EffectExecutor: callers choose, these
## execute.

# ------------ TORRENT (Droplet) ------------

## Level 4: "Draw 2 cards."
static func torrent_level_4(context: EffectContext) -> void:
	for i in range(2):
		var drawn := context.self_deck.draw(context.targets.self_discard_pile)
		if drawn == null:
			break
		context.targets.self_hand.add(drawn)

## Level 6: "Swap the positions of 2 Elementals in your formation." Unlike
## the standard swap action, the rulebook doesn't require these two to be
## connected.
static func torrent_level_6(context: EffectContext, space1: int, space2: int) -> bool:
	return context.targets.self_formation.swap_cards(space1, space2)

## Level 8: "Deal DMG to an Elemental in your opponent's formation based on
## your Sage's position in your formation. Row I: 4 DMG, Row II: 3 DMG,
## Row III: 2 DMG."
static func torrent_level_8(context: EffectContext, target_space: int) -> void:
	var sage := context.targets.self_formation.get_sage()
	if sage == null:
		return
	var sage_row := context.targets.self_formation.get_space(context.targets.self_formation.find_space_of(sage)).row
	var damage_by_row := {1: 4, 2: 3, 3: 2}
	var amount: int = damage_by_row.get(sage_row, 0)
	if amount > 0:
		_deal_fixed_damage(amount, target_space, context)

# ------------ GRAVEL (Pebble) ------------

## Level 4: "Add 1 shield to each Pebble Elemental connected to your Sage."
static func gravel_level_4(context: EffectContext) -> void:
	var formation := context.targets.self_formation
	var sage := formation.get_sage()
	if sage == null:
		return
	for card in formation.get_connected_cards(formation.find_space_of(sage)):
		if card.definition is ElementalCardDefinition and card.definition.element == CardEnums.Element.PEBBLE:
			card.shield_count += 1

## Level 6, step 1 of 2: "Remove all shields from Elementals in your
## formation..." -- returns the total removed, which the player then
## redistributes via gravel_level_6_distribute(). Split into two calls
## because "in any distribution" is the player's choice, not something to
## guess at here.
static func gravel_level_6_collect(context: EffectContext) -> int:
	var total := 0
	for space in context.targets.self_formation.spaces:
		if space.card != null:
			total += space.card.shield_count
			space.card.shield_count = 0
	return total

## Level 6, step 2 of 2: "...then add the same number of shields to
## Elementals in your formation in any distribution." distribution maps
## space_number -> shield count to add there; the caller is responsible for
## its values summing to what gravel_level_6_collect() returned.
static func gravel_level_6_distribute(context: EffectContext, distribution: Dictionary) -> void:
	for space_number in distribution:
		var card := context.targets.self_formation.get_card(space_number)
		if card != null:
			card.shield_count += distribution[space_number]

## Level 8: "Remove up to 2 shields from your Sage to deal DMG to an
## Elemental in your opponent's formation. 1 shield: 2 DMG, 2 shields: 4 DMG."
static func gravel_level_8(context: EffectContext, shields_to_spend: int, target_space: int) -> bool:
	var sage := context.targets.self_formation.get_sage()
	if sage == null or shields_to_spend < 1 or shields_to_spend > 2 or sage.shield_count < shields_to_spend:
		return false
	sage.shield_count -= shields_to_spend
	_deal_fixed_damage(shields_to_spend * 2, target_space, context)
	return true

# ------------ CEDAR (Twig) ------------

## Level 4: "Add 2 boosts to your Row I Elemental." Row I has exactly one
## slot in a 2-player formation, so there's no real choice to make here --
## if it's empty, nothing happens.
static func cedar_level_4(context: EffectContext) -> void:
	var row1 := context.targets.self_formation.get_row_cards(1)
	if not row1.is_empty():
		row1[0].boost_count += 2

## Level 6: "Add 1 boost to an Elemental in your formation for each
## connected Twig Elemental." target_space is which Elemental receives the
## boost (the player's choice); the amount is however many Twig Elementals
## are connected to that same space.
static func cedar_level_6(context: EffectContext, target_space: int) -> bool:
	var formation := context.targets.self_formation
	var target_card := formation.get_card(target_space)
	if target_card == null:
		return false
	var count := 0
	for card in formation.get_connected_cards(target_space):
		if card.definition is ElementalCardDefinition and card.definition.element == CardEnums.Element.TWIG:
			count += 1
	target_card.boost_count += count
	return true

## Level 8: "Remove up to 3 boosts from an Elemental in your formation to
## deal DMG to an Elemental in your opponent's formation. 1 boost: 1 DMG,
## 2 boosts: 3 DMG, 3 boosts: 5 DMG" (damage = 2*boosts - 1).
static func cedar_level_8(context: EffectContext, source_space: int, boosts_to_spend: int, target_space: int) -> bool:
	var source := context.targets.self_formation.get_card(source_space)
	if source == null or boosts_to_spend < 1 or boosts_to_spend > 3 or source.boost_count < boosts_to_spend:
		return false
	source.boost_count -= boosts_to_spend
	_deal_fixed_damage(2 * boosts_to_spend - 1, target_space, context)
	return true

# ------------ PORELLA (Leaf) ------------

## Level 4: "Play an attack command from your discard pile." Mirrors
## Turn.play_attack_command()'s validation (attacker on formation, in a
## legal row for the card) but sources the card from the discard pile
## instead of hand, and returns it there afterward instead of removing it
## a second time. Does NOT check/update "attacked this turn" itself --
## see the class comment.
static func porella_level_4(context: EffectContext, discard_index: int, attacker: CardInstance, chosen_per_target: Array, instant_effects: Array[AbilityEffect] = []) -> Array:
	var discard := context.targets.self_discard_pile
	var cards := discard.get_all()
	if discard_index < 0 or discard_index >= cards.size():
		push_error("FactionActions: invalid discard_index")
		return []
	var definition: CardDefinition = cards[discard_index]
	if not (definition is ItemAttackCardDefinition):
		push_error("FactionActions: porella_level_4 needs an Attack Command in the discard pile")
		return []
	var formation := context.targets.self_formation
	var attacker_space := formation.find_space_of(attacker)
	if attacker_space == -1:
		push_error("FactionActions: the attacker isn't on your formation")
		return []
	var attacker_row := formation.get_space(attacker_space).row
	if not definition.row_requirement.is_empty() and not definition.row_requirement.has(attacker_row):
		push_error("FactionActions: %s can't be used from Row %d" % [definition.card_name, attacker_row])
		return []

	discard.remove_at(discard_index)
	context.targets.attacking_card = attacker
	var result := CombatResolver.resolve_attack(definition.ability[0].effects[0], definition.attack_type, chosen_per_target, context, instant_effects)
	discard.add(definition)
	return result["pending"]

## Level 6: "Move a card from your discard pile to the top of your deck."
## Deck.draw() takes from the same end CardZone.add() appends to, so
## "adding" a card to the deck already places it on top -- no separate
## "add to top" method needed.
static func porella_level_6(context: EffectContext, discard_index: int) -> CardDefinition:
	var card := context.targets.self_discard_pile.remove_at(discard_index)
	if card != null:
		context.self_deck.add(card)
	return card

## Level 8: "Move an Elemental connected to your Sage to your discard pile,
## then deal 3 DMG to an Elemental in your opponent's formation."
static func porella_level_8(context: EffectContext, source_space: int, target_space: int) -> bool:
	var formation := context.targets.self_formation
	var sage := formation.get_sage()
	if sage == null:
		return false
	var sage_space := formation.find_space_of(sage)
	if not formation.are_connected(sage_space, source_space) or formation.get_card(source_space) == null:
		push_error("FactionActions: source_space must hold an Elemental connected to your Sage")
		return false
	var moved := formation.remove_card(source_space)
	context.targets.self_discard_pile.add(moved.definition)
	_deal_fixed_damage(3, target_space, context)
	return true

# ------------ shared ------------

## Builds a throwaway DEAL_DAMAGE effect targeting the enemy formation and
## runs it through EffectExecutor, so shield reduction, defeat, and
## removed-pile handling all go through the one general path instead of
## being reimplemented here.
static func _deal_fixed_damage(amount: int, target_space: int, context: EffectContext) -> void:
	var target := AbilityTarget.new()
	target.scope = CardEnums.TargetScope.FORMATION
	target.team = CardEnums.Team.ENEMY
	var effect := AbilityBuilder.effect(CardEnums.AbilityAction.DEAL_DAMAGE, [target], amount)
	EffectExecutor.execute(effect, [[target_space]], context)
