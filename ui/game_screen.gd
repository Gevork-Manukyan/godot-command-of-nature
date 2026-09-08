class_name GameScreen
extends Control

## Interactive slice of the game: a hardcoded 2-player dev Match (two fixed
## Sages, no setup-picker UI yet) you can actually click through -- draw,
## summon an Elemental, play a single-target Attack Command, swap two
## connected Elementals, play a Utility Command (Instants are correctly
## refused -- see Turn.play_command()), advance phases, and end a turn to
## hand off to the other side (via Match.finish_turn()) until someone's
## Sage falls. Composes the four existing read-only ui/ components
## (CardDisplay, FormationDisplay, CardRowDisplay, TurnStatusDisplay) and
## adds the interaction layer none of them had on their own: click-to-select
## a hand card or action button, click-to-target a board space (one at a
## time, in order, for effects needing more than one -- see
## _start_command_targeting()), resolve through the existing Turn/
## TargetResolver/EffectExecutor logic, then refresh every display from the
## same Turn state.
##
## Also buys/sells/refreshes at the Elemental and Command Markets (shown
## only during the Market phase) -- clicking a hand card during that phase
## sells it instead of playing it, since play_command()/summon_from_hand()/
## play_attack_command() are all Actions-phase-only anyway. The Elemental
## Market's DirectSummonToggle checkbox opts into paying
## Market.ELEMENTAL_DIRECT_SUMMON_SURCHARGE to summon straight onto the
## board instead of the discard pile -- an explicit toggle rather than
## something guessed from context, since a plain buy and a surcharged
## direct summon are both always legal and the rulebook leaves the choice
## to the player (same "never auto-pick a player's choice" principle as
## everywhere else in this project).
##
## Still not wired up: faction actions and Daybreak abilities -- they'd
## reuse the exact same click-to-select/click-to-target/refresh pattern
## built in this file, so they're fast follow-ups, not a redesign.
## Multi-target Attack Commands aren't handled (only the first target's
## candidates are offered) -- fine for the single-target Attack Commands
## this slice exercises. Utility Commands needing a HAND/DISCARD_PILE
## target (Elemental Incantation's "discard 3 from your hand") aren't
## resolvable yet either -- picking a hand card to fulfill a pending target
## needs to be told apart from "click this hand card to play it," a
## distinction this slice doesn't make; those commands say so explicitly
## rather than silently breaking. Once current_match.is_over(), every
## button disables and further hand/board/market clicks no-op -- there's no
## "new match" flow, this slice just stops there.

enum InteractionState {
	IDLE, SUMMON_SELECT_SPACE, ATTACK_SELECT_ATTACKER, ATTACK_SELECT_TARGET,
	SWAP_SELECT_FIRST, SWAP_SELECT_SECOND, COMMAND_SELECT_TARGET,
	MARKET_SUMMON_SELECT_SPACE,
}

@onready var status_label: Label = %StatusLabel
@onready var enemy_formation_display: FormationDisplay = %EnemyFormation
@onready var self_formation_display: FormationDisplay = %SelfFormation
@onready var hand_row: CardRowDisplay = %HandRow
@onready var turn_status: TurnStatusDisplay = %TurnStatus
@onready var draw_button: Button = %DrawButton
@onready var swap_button: Button = %SwapButton
@onready var advance_phase_button: Button = %AdvancePhaseButton
@onready var confirm_button: Button = %ConfirmButton
@onready var market_section: VBoxContainer = %MarketSection
@onready var elemental_market_row: CardRowDisplay = %ElementalMarketRow
@onready var command_market_row: CardRowDisplay = %CommandMarketRow
@onready var elemental_market_refresh_button: Button = %ElementalMarketRefreshButton
@onready var command_market_refresh_button: Button = %CommandMarketRefreshButton
@onready var direct_summon_toggle: CheckButton = %DirectSummonToggle

var current_match: Match
var elemental_market: Market
var command_market: Market
var state: InteractionState = InteractionState.IDLE
var selected_hand_index: int = -1
var selected_definition: CardDefinition
var selected_attacker: CardInstance
var selected_swap_space: int = -1
## Which Elemental Market slot is pending a direct summon (see
## MARKET_SUMMON_SELECT_SPACE) -- only meaningful in that state.
var selected_market_index: int = -1
## A Utility Command's effects still needing a target, in order (see
## _start_command_targeting()) -- popped from the front as each resolves.
var pending_effects: Array[AbilityEffect] = []
## Which target within pending_effects[0] is currently being picked --
## SWAP_FIELD_POSITION-style effects have 2 targets to resolve in sequence
## before the effect itself can execute.
var pending_target_index: int = 0
## Spaces chosen so far for each of pending_effects[0]'s targets, one
## Array[int] per target -- passed to EffectExecutor.execute() as
## chosen_per_target once every target has enough picks.
var pending_chosen: Array = []

func _ready() -> void:
	# Row III at top for the opponent, Row I at bottom -- so both sides'
	# Row Is land together in the middle of the screen, facing off, matching
	# how the physical board actually reads.
	enemy_formation_display.reverse_rows = true

	current_match = Match.new(
		[PlayerSetup.new_player(CardNames.CEDAR, [CardNames.ACORN_SQUIRE, CardNames.QUILL_THORNBACK], true)],
		[PlayerSetup.new_player(CardNames.GRAVEL, [CardNames.GEO_WEASEL, CardNames.GRANITE_RAMPART], false)],
		0)
	current_match.current_turn.advance_phase()  # DAYBREAK -> ACTIONS (no Daybreak UI this round)
	elemental_market = Market.new_elemental_market()
	command_market = Market.new_command_market()

	draw_button.pressed.connect(_on_draw_pressed)
	swap_button.pressed.connect(_on_swap_pressed)
	advance_phase_button.pressed.connect(_on_advance_phase_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	elemental_market_refresh_button.pressed.connect(_on_market_refresh_pressed.bind(elemental_market))
	command_market_refresh_button.pressed.connect(_on_market_refresh_pressed.bind(command_market))
	self_formation_display.space_pressed.connect(_on_self_space_pressed)
	enemy_formation_display.space_pressed.connect(_on_enemy_space_pressed)

	_refresh_all()

## One shared context builder for every action below, instead of
## re-assembling the same TargetContext/EffectContext constructor call at
## each call site -- same "one shared function, not re-derived per call
## site" principle as TargetResolver.formation_for()/AbilityFirer. Passes
## selected_attacker through (null before one's chosen) -- ROWS_AWAY-scoped
## targets (Far Strike and friends) need it to know which row to count
## from when this is called to compute highlight candidates, before
## Turn.play_attack_command() itself would otherwise set it.
func _build_context() -> EffectContext:
	var turn := current_match.current_turn
	var acting: PlayerState = turn.players[0]
	var opposing: PlayerState = turn.opponents[0]
	var targets := TargetContext.new(acting.formation, opposing.formation, null, selected_attacker,
		acting.hand, acting.discard_pile, opposing.hand, opposing.discard_pile,
		acting.sage, opposing.sage)
	return EffectContext.new(targets, acting.deck, acting.gold, acting.removed_pile, opposing.removed_pile)

func _refresh_all() -> void:
	var turn := current_match.current_turn
	enemy_formation_display.set_formation(turn.opponents[0].formation)
	self_formation_display.set_formation(turn.players[0].formation)
	hand_row.set_zone(turn.players[0].hand)
	turn_status.set_turn(turn)
	for i in range(hand_row.get_child_count()):
		var display: CardDisplay = hand_row.get_child(i)
		display.pressed.connect(_on_hand_card_pressed.bind(i))

	var in_market := turn.phase == Turn.Phase.MARKET
	market_section.visible = in_market
	if in_market:
		elemental_market_row.set_cards(elemental_market.face_up)
		command_market_row.set_cards(command_market.face_up)
		for i in range(elemental_market_row.get_child_count()):
			var d: CardDisplay = elemental_market_row.get_child(i)
			d.pressed.connect(_on_market_card_pressed.bind(elemental_market, i))
		for i in range(command_market_row.get_child_count()):
			var d: CardDisplay = command_market_row.get_child(i)
			d.pressed.connect(_on_market_card_pressed.bind(command_market, i))

	advance_phase_button.text = "End Turn" if turn.phase == Turn.Phase.CLEANUP else "Advance Phase"
	var over := current_match.is_over()
	# Draw/Swap are Actions-phase-only under the hood (Turn._spend_ap()) --
	# disable them outside it too, so clicking doesn't silently no-op with
	# no feedback (Market cards/refresh are already gated for free, since
	# market_section itself is hidden outside the Market phase).
	var in_actions := turn.phase == Turn.Phase.ACTIONS
	draw_button.disabled = over or not in_actions
	swap_button.disabled = over or not in_actions
	advance_phase_button.disabled = over
	elemental_market_refresh_button.disabled = over
	command_market_refresh_button.disabled = over
	direct_summon_toggle.disabled = over
	_clear_selection()
	if over:
		status_label.text = "Match over! Side %d wins." % current_match.winner()

## Resets interaction state/highlights without touching the displays'
## underlying data -- used both after a successful action (via
## _refresh_all()) and to cancel out of a mis-click, so it must NOT
## reconnect hand signals (that only happens once per card, in
## _refresh_all(), right after the hand row's children are freshly built).
func _clear_selection() -> void:
	state = InteractionState.IDLE
	selected_hand_index = -1
	selected_definition = null
	selected_attacker = null
	selected_swap_space = -1
	selected_market_index = -1
	pending_effects = []
	pending_target_index = 0
	pending_chosen = []
	confirm_button.visible = false
	self_formation_display.clear_highlight()
	enemy_formation_display.clear_highlight()
	if current_match != null and current_match.current_turn.phase == Turn.Phase.MARKET:
		status_label.text = "Click a hand card to sell it, or a Market card to buy it."
	else:
		status_label.text = "Click a hand card to play it, or Swap two connected Elementals."

func _on_hand_card_pressed(display: CardDisplay, hand_index: int) -> void:
	if state != InteractionState.IDLE or current_match.is_over():
		return
	var turn := current_match.current_turn
	var definition := turn.players[0].hand.get_all()[hand_index]

	if turn.phase == Turn.Phase.MARKET:
		var value := Market.sell_value(definition)
		turn.sell_from_hand(hand_index)
		_refresh_all()
		status_label.text = "Sold %s for %d gold." % [definition.card_name, value]
		return

	selected_hand_index = hand_index
	selected_definition = definition
	display.set_selected(true)

	if definition is ElementalCardDefinition:
		state = InteractionState.SUMMON_SELECT_SPACE
		self_formation_display.highlight_spaces(turn.players[0].formation.get_valid_summon_spaces())
		status_label.text = "Choose a space to summon %s." % definition.card_name
	elif definition is ItemAttackCardDefinition:
		var eligible := _eligible_attacker_spaces(definition)
		if eligible.is_empty():
			status_label.text = "No eligible attacker for %s right now (needs an Elemental in Row %s that hasn't attacked yet). Click another card to try something else." \
				% [definition.card_name, _row_requirement_text(definition)]
			display.set_selected(false)
			selected_hand_index = -1
			selected_definition = null
			return
		state = InteractionState.ATTACK_SELECT_ATTACKER
		self_formation_display.highlight_spaces(eligible)
		status_label.text = "Choose an attacker for %s (highlighted on your board)." % definition.card_name
	elif definition is ItemCardDefinition and definition.item_type == CardEnums.ItemType.UTILITY:
		var context := _build_context()
		var pending := current_match.current_turn.play_command(selected_hand_index, context)
		var effects: Array[AbilityEffect] = []
		effects.assign(pending)
		_start_command_targeting(effects, definition.card_name)
	elif definition is ItemCardDefinition and definition.item_type == CardEnums.ItemType.INSTANT:
		status_label.text = "%s is an Instant -- per the rulebook it's only played in response to being attacked, not during your own turn. That flow isn't built yet. Click another card or a board space to cancel." % definition.card_name
		display.set_selected(false)
		selected_hand_index = -1
		selected_definition = null
	else:
		status_label.text = "%s isn't playable in this demo slice yet -- click another card or a board space to cancel." % definition.card_name

## Which of the acting player's occupied spaces could legally use
## attack_def right now (hasn't attacked yet this turn, in a legal row for
## this specific card) -- a UI-facing "what's clickable" query in the same
## spirit as Formation.get_valid_summon_spaces(), just not promoted to
## Turn/CombatResolver yet since this is the only caller so far.
func _eligible_attacker_spaces(attack_def: ItemAttackCardDefinition) -> Array[int]:
	var turn := current_match.current_turn
	var formation := turn.players[0].formation
	var result: Array[int] = []
	for space in formation.spaces:
		if space.card == null or turn.has_attacked(space.card):
			continue
		if not attack_def.row_requirement.is_empty() and not attack_def.row_requirement.has(space.row):
			continue
		result.append(space.space_number)
	return result

func _row_requirement_text(attack_def: ItemAttackCardDefinition) -> String:
	if attack_def.row_requirement.is_empty():
		return "any"
	var roman := {1: "I", 2: "II", 3: "III"}
	var names: Array[String] = []
	for row in attack_def.row_requirement:
		names.append(roman.get(row, str(row)))
	return " or ".join(names)

## --- Utility Command target resolution -----------------------------------
## Turn.play_command() already fires whatever a Utility Command's ON_PLAY
## ability could resolve on its own and returns only the leftover effects
## still needing a target (see AbilityFirer.fire()) -- this section walks
## through those, one target at a time, in order, exactly the same
## click-to-select/highlight pattern as summon/attack, generalized to
## effects with more than one target (SWAP_FIELD_POSITION) and targets
## needing more than one pick (TargetSelection.CHOOSE_N with count > 1).
## Board targets only (FORMATION/ROW) -- HAND/DISCARD_PILE targets (e.g.
## Elemental Incantation's "discard 3 from your hand") aren't wired up this
## round, since picking from a CardRowDisplay needs to be told apart from
## "click this hand card to play it," a separate interaction this slice
## doesn't have yet; those commands say so explicitly instead of silently
## breaking.

func _start_command_targeting(effects: Array[AbilityEffect], command_name: String) -> void:
	pending_effects = effects
	if pending_effects.is_empty():
		_refresh_all()
		status_label.text = "%s resolved." % command_name
		return
	_begin_pending_effect()

func _begin_pending_effect() -> void:
	var effect: AbilityEffect = pending_effects[0]
	for target in effect.targets:
		if target.scope == CardEnums.TargetScope.HAND or target.scope == CardEnums.TargetScope.DISCARD_PILE:
			status_label.text = "This command needs a hand/discard target, which this demo slice can't resolve yet -- its other effects (if any) already happened."
			_clear_selection()
			return
	pending_target_index = 0
	pending_chosen = []
	for i in range(effect.targets.size()):
		pending_chosen.append([] as Array[int])
	_begin_pending_target()

func _begin_pending_target() -> void:
	var effect: AbilityEffect = pending_effects[0]
	var target: AbilityTarget = effect.targets[pending_target_index]
	var context := _build_context()
	var candidates := TargetResolver.get_candidates(target, context.targets)
	if target.selection == CardEnums.TargetSelection.ALL:
		pending_chosen[pending_target_index] = candidates
		_advance_pending_target()
		return
	if candidates.is_empty():
		status_label.text = "No legal target for this command right now -- cancelling the rest of it."
		_clear_selection()
		return
	state = InteractionState.COMMAND_SELECT_TARGET
	var formation := TargetResolver.formation_for(target, context.targets)
	var is_self := formation == context.targets.self_formation
	(self_formation_display if is_self else enemy_formation_display).highlight_spaces(candidates)
	(enemy_formation_display if is_self else self_formation_display).clear_highlight()
	confirm_button.visible = target.count > 1
	status_label.text = "Choose up to %d target(s) on %s board." % [target.count, "your" if is_self else "the opponent's"]

func _on_command_space_pressed(space_number: int, is_self_click: bool) -> void:
	var effect: AbilityEffect = pending_effects[0]
	var target: AbilityTarget = effect.targets[pending_target_index]
	var context := _build_context()
	var formation := TargetResolver.formation_for(target, context.targets)
	var expected_self: bool = formation == context.targets.self_formation
	var candidates := TargetResolver.get_candidates(target, context.targets)
	var already_chosen: Array[int] = pending_chosen[pending_target_index]
	if already_chosen.has(space_number):
		return  # re-clicking an already-picked space is a harmless no-op, not a mis-click
	if expected_self != is_self_click or not candidates.has(space_number):
		_clear_selection()
		return
	already_chosen.append(space_number)
	if already_chosen.size() >= target.count:
		_advance_pending_target()
	else:
		status_label.text = "Chosen %d/%d -- pick more, or Confirm Selection to stop early." % [already_chosen.size(), target.count]

func _advance_pending_target() -> void:
	var effect: AbilityEffect = pending_effects[0]
	pending_target_index += 1
	if pending_target_index < effect.targets.size():
		_begin_pending_target()
		return
	var context := _build_context()
	EffectExecutor.execute(effect, pending_chosen, context)
	pending_effects.pop_front()
	if pending_effects.is_empty():
		_refresh_all()
	else:
		_begin_pending_effect()

func _on_confirm_pressed() -> void:
	if state != InteractionState.COMMAND_SELECT_TARGET:
		return
	_advance_pending_target()

func _attack_target_candidates(context: EffectContext) -> Array[int]:
	var attack_def: ItemAttackCardDefinition = selected_definition
	var target: AbilityTarget = attack_def.ability[0].effects[0].targets[0]
	return TargetResolver.get_candidates(target, context.targets)

func _on_self_space_pressed(space_number: int) -> void:
	if current_match.is_over():
		return
	match state:
		InteractionState.SUMMON_SELECT_SPACE:
			var turn := current_match.current_turn
			if not turn.players[0].formation.get_valid_summon_spaces().has(space_number):
				_clear_selection()
				return
			turn.summon_from_hand(selected_hand_index, space_number)
			_refresh_all()
		InteractionState.ATTACK_SELECT_ATTACKER:
			if not _eligible_attacker_spaces(selected_definition).has(space_number):
				_clear_selection()
				return
			selected_attacker = current_match.current_turn.players[0].formation.get_card(space_number)
			var candidates := _attack_target_candidates(_build_context())
			if candidates.is_empty():
				var attack_name := selected_definition.card_name
				_clear_selection()
				status_label.text = "No legal target for %s right now (the opponent has nothing there to hit). Click another card to try something else." % attack_name
				return
			state = InteractionState.ATTACK_SELECT_TARGET
			enemy_formation_display.highlight_spaces(candidates)
			self_formation_display.clear_highlight()
			status_label.text = "Choose a target for %s (highlighted on the opponent's board)." % selected_definition.card_name
		InteractionState.SWAP_SELECT_FIRST:
			var formation := current_match.current_turn.players[0].formation
			if formation.get_card(space_number) == null:
				_clear_selection()
				return
			selected_swap_space = space_number
			var connected := _connected_occupied_spaces(formation, space_number)
			if connected.is_empty():
				status_label.text = "Nothing connected to swap with there. Click another space, or a card, to try something else."
				_clear_selection()
				return
			state = InteractionState.SWAP_SELECT_SECOND
			self_formation_display.highlight_spaces(connected)
			status_label.text = "Choose a connected Elemental to swap with."
		InteractionState.SWAP_SELECT_SECOND:
			var formation := current_match.current_turn.players[0].formation
			if not _connected_occupied_spaces(formation, selected_swap_space).has(space_number):
				_clear_selection()
				return
			current_match.current_turn.swap_connected(selected_swap_space, space_number)
			_refresh_all()
		InteractionState.COMMAND_SELECT_TARGET:
			_on_command_space_pressed(space_number, true)
		InteractionState.MARKET_SUMMON_SELECT_SPACE:
			var turn := current_match.current_turn
			if not turn.players[0].formation.get_valid_summon_spaces().has(space_number):
				_clear_selection()
				return
			var card_name: String = elemental_market.face_up[selected_market_index].card_name
			var instance := turn.buy_and_summon_from_market(elemental_market, selected_market_index, space_number)
			_refresh_all()
			status_label.text = "Summoned %s directly." % card_name if instance != null else "Couldn't summon directly there."
		_:
			_clear_selection()

## Occupied spaces connected to `space_number` -- the rulebook's swap action
## needs both ends to hold an Elemental (see Turn.swap_connected()), so this
## filters Formation.are_connected() down to just the spaces worth offering.
func _connected_occupied_spaces(formation: Formation, space_number: int) -> Array[int]:
	var result: Array[int] = []
	for space in formation.spaces:
		if space.card != null and formation.are_connected(space_number, space.space_number):
			result.append(space.space_number)
	return result

func _on_enemy_space_pressed(space_number: int) -> void:
	if current_match.is_over():
		return
	if state == InteractionState.ATTACK_SELECT_TARGET:
		var context := _build_context()
		if not _attack_target_candidates(context).has(space_number):
			_clear_selection()
			return
		current_match.current_turn.play_attack_command(selected_hand_index, selected_attacker, [[space_number]], context)
		_refresh_all()
	elif state == InteractionState.COMMAND_SELECT_TARGET:
		_on_command_space_pressed(space_number, false)
	else:
		_clear_selection()

func _on_draw_pressed() -> void:
	current_match.current_turn.draw_card()
	_refresh_all()

func _on_swap_pressed() -> void:
	if state != InteractionState.IDLE or current_match.is_over():
		return
	var formation := current_match.current_turn.players[0].formation
	var occupied: Array[int] = []
	for space in formation.spaces:
		if space.card != null:
			occupied.append(space.space_number)
	if occupied.is_empty():
		status_label.text = "Nothing on your board to swap."
		return
	state = InteractionState.SWAP_SELECT_FIRST
	self_formation_display.highlight_spaces(occupied)
	status_label.text = "Choose the first Elemental to swap (on your board)."

## A plain buy never needs a target choice (it always goes to the discard
## pile), so it resolves immediately on click, same as Draw -- unless
## DirectSummonToggle is on and this is an Elemental Market slot, in which
## case it needs a space choice first (see _start_direct_summon()).
func _on_market_card_pressed(_display: CardDisplay, market: Market, index: int) -> void:
	if state != InteractionState.IDLE or current_match.is_over():
		return
	if market == elemental_market and direct_summon_toggle.button_pressed:
		_start_direct_summon(index)
		return
	var bought := current_match.current_turn.buy_from_market(market, index)
	_refresh_all()
	if bought == null:
		status_label.text = "Can't afford that right now."
	else:
		status_label.text = "Bought %s." % bought.card_name

## Per the rulebook, paying Market.ELEMENTAL_DIRECT_SUMMON_SURCHARGE on top
## of an Elemental's price brings it straight into the formation instead of
## the discard pile, if there's an empty space -- Turn.buy_and_summon_from_market()
## already does the actual buy+summon+gold-spend atomically, this just
## collects the space choice for it first, same click-to-target shape as
## summoning from hand.
func _start_direct_summon(index: int) -> void:
	var turn := current_match.current_turn
	var card_def: CardDefinition = elemental_market.face_up[index]
	var total_cost: int = card_def.price + Market.ELEMENTAL_DIRECT_SUMMON_SURCHARGE
	var valid_spaces := turn.players[0].formation.get_valid_summon_spaces()
	if turn.players[0].gold.amount < total_cost or valid_spaces.is_empty():
		status_label.text = "Can't summon %s directly right now -- needs %d gold total and an empty formation space. Turn off Direct Summon to just buy it instead." \
			% [card_def.card_name, total_cost]
		return
	selected_market_index = index
	state = InteractionState.MARKET_SUMMON_SELECT_SPACE
	self_formation_display.highlight_spaces(valid_spaces)
	status_label.text = "Choose a space to summon %s directly (+%d gold)." \
		% [card_def.card_name, Market.ELEMENTAL_DIRECT_SUMMON_SURCHARGE]

func _on_market_refresh_pressed(market: Market) -> void:
	if current_match.is_over():
		return
	var ok := current_match.current_turn.refresh_market(market)
	_refresh_all()
	if not ok:
		status_label.text = "Can't refresh that Market right now (not enough gold)."

## In every phase but Cleanup this just steps Turn.advance_phase(). At
## Cleanup it hands off to the other side via Match.finish_turn() instead
## (which itself calls Turn.advance_phase() one more time as its own
## can-we-actually-end-this-turn gate, checks the win condition, and only
## then starts a new Turn) -- this is what turns the screen from "act
## within one Turn" into an actual back-and-forth game.
func _on_advance_phase_pressed() -> void:
	var turn := current_match.current_turn
	var was_cleanup := turn.phase == Turn.Phase.CLEANUP
	var ok := current_match.finish_turn() if was_cleanup else turn.advance_phase()
	_refresh_all()
	if not ok:
		status_label.text = "Can't end the turn yet -- every hand must be at most 5 cards first." if was_cleanup \
			else "Can't advance right now."
