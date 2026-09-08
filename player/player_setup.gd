class_name PlayerSetup

## Builds fresh PlayerState(s) for chosen Sage(s), following the rulebook's
## setup steps: split each Sage pack (1 Sage, 3 Champions, 3 starter
## Warriors, 4 copies of 1 starter Basic, 5 Commands = 16 cards total) into
## what goes on the formation vs. into the deck, shuffle the deck, and draw
## a 5-card hand. `new_player()` covers 2-player (each player owns their own
## Formation/GoldPool); `new_team()` covers a 4-player team (two players
## sharing one Formation and one GoldPool, per the rulebook -- hand/deck/
## discard/removed/level/locked_champions stay individual either way, see
## PlayerState). Both funnel through `_setup_player()`, which only differs
## between them in which formation space numbers a player's cards land on.
##
## chosen_warrior_names (per player) picks which 2 of that pack's 3 starter
## Warriors go into the formation (left/right of that player's Sage in Row
## III) -- the rulebook makes this the player's choice, not automatic, so
## it's a parameter here too rather than something this class decides. The
## third Warrior, plus the pack's 4th Basic copy, go into that player's deck
## along with their 5 Commands.
##
## goes_first sets starting gold -- 0 for whoever/whichever team goes first,
## 3 for the second player in 2-player, **4** for the second team in
## 4-player (rulebook value, confirmed by the user -- not simply double the
## 2-player number). Who actually goes first is a decision for whatever
## calls this, not something to guess at here.
static func new_player(sage_name: String, chosen_warrior_names: Array, goes_first: bool) -> PlayerState:
	var state := PlayerState.new()
	if not _setup_player(state, sage_name, chosen_warrior_names, [1, 2, 3], [4, 5, 6]):
		return state
	state.gold.add(0 if goes_first else 3)
	return state

## Builds the 2 teammates sharing one 12-space Formation and one 20-gold
## GoldPool. Space numbering matches the old reference's team setup exactly:
## player 1 gets Row I/II spaces 1,3,4 and Row III spaces 7 (left warrior),
## 8 (sage), 9 (right warrior); player 2 gets 2,5,6 and 10,11,12 -- two
## disjoint halves of the same board, each laid out identically to the
## 2-player case's 1,2,3 / 4,5,6. Returns whatever was successfully built if
## either player's setup fails partway (see `_setup_player()`), same
## fail-safely-incomplete behavior as `new_player()`.
static func new_team(sage_name_1: String, chosen_warrior_names_1: Array, sage_name_2: String, chosen_warrior_names_2: Array, goes_first: bool) -> Array[PlayerState]:
	var shared_formation := Formation.new_four_player_team()
	var shared_gold := GoldPool.new(20)
	var state1 := PlayerState.new(shared_formation, shared_gold)
	var state2 := PlayerState.new(shared_formation, shared_gold)
	if not _setup_player(state1, sage_name_1, chosen_warrior_names_1, [1, 3, 4], [7, 8, 9]):
		return [state1, state2]
	if not _setup_player(state2, sage_name_2, chosen_warrior_names_2, [2, 5, 6], [10, 11, 12]):
		return [state1, state2]
	shared_gold.add(0 if goes_first else 4)
	return [state1, state2]

## Splits one Sage pack across `state`'s formation/deck/hand and validates
## along the way. `basic_spaces` (3 spaces) gets the 3 formation copies of
## the starter Basic; `warrior_sage_warrior_spaces` (3 spaces, left-center-
## right) gets [chosen[0], the Sage, chosen[1]]. Only the space numbers
## differ between 2-player and a 4-player team's per-player half -- the pack
## composition math is identical either way. Returns false (after
## push_error) on any validation failure, leaving `state` safely incomplete
## rather than partially applied further.
static func _setup_player(state: PlayerState, sage_name: String, chosen_warrior_names: Array,
		basic_spaces: Array[int], warrior_sage_warrior_spaces: Array[int]) -> bool:
	# ChampionCards/WarriorCards/SageCards build fresh CardDefinitions with no
	# .ability at all -- only CardLibrary.all() attaches those (see
	# CardLibrary._attach_abilities()), same as anything bought later from a
	# Market (which already sources through CardLibrary.all()). Without this,
	# every Sage/Warrior/Champion placed by setup would have its Daybreak and
	# triggered abilities silently inert for the rest of the game -- a real
	# bug this file previously had, found while wiring up Daybreak's UI.
	var library := CardLibrary.get_all()
	var sage_def := _find_sage(sage_name, library)
	if sage_def == null:
		push_error("PlayerSetup: unknown Sage %s" % sage_name)
		return false
	var element: CardEnums.Element = sage_def.element

	var champions: Array[ElementalChampionCardDefinition] = []
	for card in ChampionCards.by_element(element):
		champions.append(library.get(card.card_name, card))
	var starter_warriors: Array[ElementalWarriorCardDefinition] = []
	for card in _starters(WarriorCards.by_element(element)):
		starter_warriors.append(library.get(card.card_name, card))
	var starter_basics := _starters(BasicCards.by_element(element))
	if champions.size() != 3 or starter_warriors.size() != 3 or starter_basics.size() != 1:
		push_error("PlayerSetup: expected 3 Champions, 3 starter Warriors, 1 starter Basic for %s" % CardEnums.Element.keys()[element])
		return false
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
		return false

	state.locked_champions = champions

	state.formation.add_card(CardInstance.new(starter_basic), basic_spaces[0])
	state.formation.add_card(CardInstance.new(starter_basic), basic_spaces[1])
	state.formation.add_card(CardInstance.new(starter_basic), basic_spaces[2])
	state.formation.add_card(CardInstance.new(chosen[0]), warrior_sage_warrior_spaces[0])
	state.sage = CardInstance.new(sage_def)
	state.formation.add_card(state.sage, warrior_sage_warrior_spaces[1])
	state.formation.add_card(CardInstance.new(chosen[1]), warrior_sage_warrior_spaces[2])

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

	return true

static func _find_sage(sage_name: String, library: Dictionary) -> ElementalSageCardDefinition:
	var card = library.get(sage_name)
	return card if card is ElementalSageCardDefinition else null

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
