class_name EffectExecutor

## Executes an already-resolved-and-validated AbilityEffect against real game
## state. chosen_per_target must have one entry (an Array[int]) per
## effect.targets[i] -- e.g. SWAP_FIELD_POSITION needs two entries, one chosen
## space for each side of the swap. Get each entry by calling
## TargetResolver.get_candidates()/validate_choice() first; this class does
## not re-validate anything.
##
## destination_space is only used by MOVE_TO_FIELD_FROM_* actions, which place
## a card onto the board rather than acting on an existing one: the caller
## must get it from Formation.get_valid_summon_spaces() first (same
## player-choice pattern as a normal summon).
##
## REDUCE_DAMAGE/NEGATE_DAMAGE only make sense as Instant Command responses
## within an attack -- see CombatResolver, which reads their resolved amount
## directly rather than calling execute() on them. DONT_REMOVE_BOOST/
## DONT_REMOVE_SHIELD/REDIRECT_DAMAGE_TO_SELF are passive triggered abilities
## that need trigger detection (not built yet) to even know when they apply;
## all 5 push_error rather than silently no-op if called directly.
static func execute(effect: AbilityEffect, chosen_per_target: Array, context: EffectContext, destination_space: int = -1) -> void:
	match effect.action:
		CardEnums.AbilityAction.COLLECT_GOLD:
			_collect_gold(effect, context)
		CardEnums.AbilityAction.DRAW:
			_draw(effect, context)
		CardEnums.AbilityAction.DEAL_DAMAGE:
			_deal_damage(effect, chosen_per_target, context)
		CardEnums.AbilityAction.ADD_SHIELD:
			_for_each_target_card(effect, chosen_per_target, context, func(card): card.shield_count += resolve_amount(effect, context))
		CardEnums.AbilityAction.ADD_BOOST:
			_for_each_target_card(effect, chosen_per_target, context, func(card): card.boost_count += resolve_amount(effect, context))
		CardEnums.AbilityAction.REMOVE_ALL_DAMAGE:
			_for_each_target_card(effect, chosen_per_target, context, func(card): card.current_damage = 0)
		CardEnums.AbilityAction.REMOVE_ALL_BOOSTS_AND_SHIELDS:
			_for_each_target_card(effect, chosen_per_target, context, func(card):
				card.boost_count = 0
				card.shield_count = 0)
		CardEnums.AbilityAction.SWAP_FIELD_POSITION:
			_swap_field_position(effect, chosen_per_target, context)
		CardEnums.AbilityAction.MOVE_TO_DISCARD_FROM_FIELD:
			_move_field_to_zone(effect, chosen_per_target, context, context.targets.self_discard_pile)
		CardEnums.AbilityAction.MOVE_TO_HAND_FROM_FIELD:
			_move_field_to_zone(effect, chosen_per_target, context, context.targets.self_hand)
		CardEnums.AbilityAction.MOVE_TO_FIELD_FROM_DISCARD:
			_move_zone_to_field(chosen_per_target, context, context.targets.self_discard_pile, destination_space)
		CardEnums.AbilityAction.MOVE_TO_FIELD_FROM_HAND:
			_move_zone_to_field(chosen_per_target, context, context.targets.self_hand, destination_space)
		CardEnums.AbilityAction.MOVE_TO_HAND_FROM_DISCARD:
			_move_zone_to_zone(chosen_per_target, context.targets.self_discard_pile, context.targets.self_hand)
		CardEnums.AbilityAction.MOVE_TO_DISCARD_FROM_HAND:
			context.last_discarded_count = _move_zone_to_zone(chosen_per_target, context.targets.self_hand, context.targets.self_discard_pile)
		CardEnums.AbilityAction.REDUCE_DAMAGE, CardEnums.AbilityAction.NEGATE_DAMAGE:
			push_error("EffectExecutor: %s only makes sense inside an attack -- use CombatResolver.resolve_attack()'s instant_effects instead of calling execute() directly" % CardEnums.AbilityAction.keys()[effect.action])
		CardEnums.AbilityAction.DONT_REMOVE_BOOST, CardEnums.AbilityAction.DONT_REMOVE_SHIELD, \
		CardEnums.AbilityAction.REDIRECT_DAMAGE_TO_SELF:
			push_error("EffectExecutor: %s needs trigger detection (checking a card's own triggered abilities), not implemented yet" % CardEnums.AbilityAction.keys()[effect.action])
		_:
			push_error("EffectExecutor: unhandled AbilityAction %s" % effect.action)

## Public because CombatResolver also needs it (for base attack damage and
## Instant Command reduction amounts) -- one shared function instead of two
## files re-deriving the same formula.
static func resolve_amount(effect: AbilityEffect, context: EffectContext) -> int:
	var base := 0
	match effect.amount_source:
		CardEnums.AmountSource.FIXED:
			return effect.amount
		CardEnums.AmountSource.ATTACKER_STRENGTH:
			var attacker := context.targets.attacking_card
			base = attacker.get_effective_attack() if attacker else 0
		CardEnums.AmountSource.SELF_DAMAGE_COUNT:
			var source := context.targets.source_card
			base = source.current_damage if source else 0
		CardEnums.AmountSource.SELF_SHIELD_COUNT:
			var source := context.targets.source_card
			base = source.shield_count if source else 0
		CardEnums.AmountSource.DISCARDED_COUNT:
			base = context.last_discarded_count
	return base * effect.multiplier + effect.amount

static func _formation_for_target(target: AbilityTarget, context: EffectContext) -> Formation:
	return TargetResolver.formation_for(target, context.targets)

static func _removed_pile_for(team: CardEnums.Team, context: EffectContext) -> CardZone:
	return context.self_removed_pile if team == CardEnums.Team.SELF else context.enemy_removed_pile

static func _for_each_target_card(effect: AbilityEffect, chosen_per_target: Array, context: EffectContext, mutate: Callable) -> void:
	for i in range(effect.targets.size()):
		var formation := _formation_for_target(effect.targets[i], context)
		for space_number in chosen_per_target[i]:
			var card := formation.get_card(space_number)
			if card != null:
				mutate.call(card)

static func _collect_gold(effect: AbilityEffect, context: EffectContext) -> void:
	if context.self_gold == null:
		push_error("EffectExecutor: COLLECT_GOLD needs EffectContext.self_gold")
		return
	context.self_gold.add(resolve_amount(effect, context))

static func _draw(effect: AbilityEffect, context: EffectContext) -> void:
	if context.self_deck == null or context.targets.self_hand == null:
		push_error("EffectExecutor: DRAW needs self_deck and TargetContext.self_hand")
		return
	for i in range(resolve_amount(effect, context)):
		var drawn := context.self_deck.draw(context.targets.self_discard_pile)
		if drawn == null:
			break
		context.targets.self_hand.add(drawn)

## Shields reduce incoming DMG by 1 each and are fully removed once dealt any
## DMG, regardless of source -- this is a general token rule ("any DMG"), not
## specific to attacks, so it applies here rather than being combat-only.
## What IS combat-only (Instant Command responses, boost consumption on the
## attacker) lives in CombatResolver, which computes a final amount and then
## calls execute() with a plain FIXED effect, still passing through here.
static func _deal_damage(effect: AbilityEffect, chosen_per_target: Array, context: EffectContext) -> void:
	var amount := resolve_amount(effect, context)
	for i in range(effect.targets.size()):
		var target := effect.targets[i]
		var formation := _formation_for_target(target, context)
		var removed_pile := _removed_pile_for(target.team, context)
		for space_number in chosen_per_target[i]:
			var card := formation.get_card(space_number)
			if card == null:
				continue
			var net_amount := maxi(amount - card.shield_count, 0)
			card.shield_count = 0
			card.current_damage += net_amount
			if card.is_defeated():
				formation.remove_card(space_number)
				if removed_pile != null:
					removed_pile.add(card.definition)

static func _swap_field_position(effect: AbilityEffect, chosen_per_target: Array, context: EffectContext) -> void:
	if effect.targets.size() != 2 or chosen_per_target[0].size() != 1 or chosen_per_target[1].size() != 1:
		push_error("EffectExecutor: SWAP_FIELD_POSITION needs exactly one chosen space per target")
		return
	var formation_a := _formation_for_target(effect.targets[0], context)
	var formation_b := _formation_for_target(effect.targets[1], context)
	if formation_a != formation_b:
		push_error("EffectExecutor: SWAP_FIELD_POSITION across two different formations isn't supported")
		return
	formation_a.swap_cards(chosen_per_target[0][0], chosen_per_target[1][0])

static func _move_field_to_zone(effect: AbilityEffect, chosen_per_target: Array, context: EffectContext, destination_zone: CardZone) -> void:
	if destination_zone == null:
		push_error("EffectExecutor: move-from-field needs a destination zone")
		return
	var formation := _formation_for_target(effect.targets[0], context)
	for space_number in chosen_per_target[0]:
		var card := formation.remove_card(space_number)
		if card != null:
			destination_zone.add(card.definition)

static func _move_zone_to_field(chosen_per_target: Array, context: EffectContext, source_zone: CardZone, destination_space: int) -> void:
	if source_zone == null or destination_space < 0:
		push_error("EffectExecutor: move-to-field needs a source zone and a valid destination_space")
		return
	var chosen: Array = chosen_per_target[0]
	if chosen.is_empty():
		return
	var definition := source_zone.remove_at(chosen[0])
	if definition == null:
		return
	var card_instance := CardInstance.new(definition)
	if not context.targets.self_formation.summon(card_instance, destination_space):
		push_error("EffectExecutor: destination_space %d is not a legal summon target" % destination_space)
		source_zone.add(definition)

## Moves the chosen indices from source_zone to destination_zone, removing
## highest-index-first so earlier removals don't shift the indices still to
## be processed. Returns how many actually moved (may be less than requested
## if an index was already stale).
static func _move_zone_to_zone(chosen_per_target: Array, source_zone: CardZone, destination_zone: CardZone) -> int:
	if source_zone == null or destination_zone == null:
		push_error("EffectExecutor: move needs both a source and destination zone")
		return 0
	var sorted_indices: Array = chosen_per_target[0].duplicate()
	sorted_indices.sort()
	sorted_indices.reverse()
	var moved_count := 0
	for index in sorted_indices:
		var definition := source_zone.remove_at(index)
		if definition != null:
			destination_zone.add(definition)
			moved_count += 1
	return moved_count
