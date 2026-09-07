class_name PlayerSetup

## Builds a fresh PlayerState for a chosen Sage, following the rulebook's
## 2-player setup steps: split the Sage pack (1 Sage, 3 Champions, 3 starter
## Warriors, 4 copies of 1 starter Basic, 5 Commands = 16 cards total) into
## what goes on the formation vs. into the deck, shuffle the deck, and draw
## a 5-card hand.
##
## chosen_warrior_names picks which 2 of the pack's 3 starter Warriors go
## into the formation (left/right of the Sage in Row III) -- the rulebook
## makes this the player's choice, not automatic, so it's a parameter here
## too rather than something this class decides. The third Warrior, plus
## the pack's 4th Basic copy, go into the deck along with the 5 Commands.
##
## goes_first sets starting gold (0 for the first player, 3 for the second,
## per the rulebook) -- who actually goes first is a decision for whatever
## calls this, not something to guess at here.
static func new_player(sage_name: String, chosen_warrior_names: Array, goes_first: bool) -> PlayerState:
	var state := PlayerState.new()
	var sage_def := _find_sage(sage_name)
	if sage_def == null:
		push_error("PlayerSetup: unknown Sage %s" % sage_name)
		return state
	var element: CardEnums.Element = sage_def.element

	var champions := ChampionCards.by_element(element)
	var starter_warriors := _starters(WarriorCards.by_element(element))
	var starter_basics := _starters(BasicCards.by_element(element))
	if champions.size() != 3 or starter_warriors.size() != 3 or starter_basics.size() != 1:
		push_error("PlayerSetup: expected 3 Champions, 3 starter Warriors, 1 starter Basic for %s" % CardEnums.Element.keys()[element])
		return state
	var starter_basic: ElementalCardDefinition = starter_basics[0]

	var chosen: Array = []
	var leftover_warrior: ElementalWarriorCardDefinition = null
	for warrior in starter_warriors:
		if chosen_warrior_names.has(warrior.card_name) and chosen.size() < 2:
			chosen.append(warrior)
		else:
			leftover_warrior = warrior
	if chosen.size() != 2:
		push_error("PlayerSetup: chosen_warrior_names must name exactly 2 of %s" % [_names(starter_warriors)])
		return state

	state.locked_champions = champions

	# Formation: Row I + Row II = 3 copies of the starter Basic (a 4th stays
	# for the deck); the Sage centers Row III with the 2 chosen Warriors
	# either side (space numbering matches the old reference's setup: 4-5-6
	# = left-center-right of Row III).
	state.formation.add_card(CardInstance.new(starter_basic), 1)
	state.formation.add_card(CardInstance.new(starter_basic), 2)
	state.formation.add_card(CardInstance.new(starter_basic), 3)
	state.formation.add_card(CardInstance.new(chosen[0]), 4)
	state.formation.add_card(CardInstance.new(sage_def), 5)
	state.formation.add_card(CardInstance.new(chosen[1]), 6)

	# Deck: the leftover Basic copy, the leftover Warrior, and the 5
	# Commands (2x Close Strike, 2x Far Strike, 1 faction Charm).
	var leftover_elementals: Array[CardDefinition] = [starter_basic, leftover_warrior]
	state.deck.add_cards(leftover_elementals)
	state.deck.add_cards(_starter_commands(element))
	state.deck.shuffle()

	for i in range(5):
		var drawn := state.deck.draw(state.discard_pile)
		if drawn == null:
			break
		state.hand.add(drawn)

	state.gold.add(0 if goes_first else 3)
	return state

static func _find_sage(sage_name: String) -> ElementalSageCardDefinition:
	for sage in SageCards.all():
		if sage.card_name == sage_name:
			return sage
	return null

static func _starters(cards: Array) -> Array:
	var result := []
	for card in cards:
		if card.is_starter:
			result.append(card)
	return result

static func _names(cards: Array) -> Array:
	var result := []
	for card in cards:
		result.append(card.card_name)
	return result

static func _starter_commands(element: CardEnums.Element) -> Array[CardDefinition]:
	var all_cards := CardLibrary.get_all()
	var close_strike: CardDefinition = all_cards[CardNames.CLOSE_STRIKE]
	var far_strike: CardDefinition = all_cards[CardNames.FAR_STRIKE]
	var charm: CardDefinition = all_cards[_charm_name_for(element)]
	var result: Array[CardDefinition] = [close_strike, close_strike, far_strike, far_strike, charm]
	return result

static func _charm_name_for(element: CardEnums.Element) -> String:
	match element:
		CardEnums.Element.TWIG:
			return CardNames.TWIG_CHARM
		CardEnums.Element.PEBBLE:
			return CardNames.PEBBLE_CHARM
		CardEnums.Element.LEAF:
			return CardNames.LEAF_CHARM
		CardEnums.Element.DROPLET:
			return CardNames.DROPLET_CHARM
	return ""
