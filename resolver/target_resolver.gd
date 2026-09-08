class_name TargetResolver

## Turns an AbilityTarget's description (scope/team/rows) into the actual
## candidate identifiers that currently match it. Does not decide how many
## get chosen or by whom -- see validate_choice() for checking a specific
## choice, and CardAbility/AbilityEffect for the "how many" (count).
##
## For board scopes (SELF/SAGE/ROW/FORMATION/ATTACKING_ELEMENTAL) the ints
## returned are Formation space numbers. For HAND/DISCARD_PILE they're
## indices into that CardZone's card list instead -- there's no shared
## identifier space between a board and a zone, so callers must already know
## which kind a given scope produces.
##
## require_occupied filters board scopes to spaces that do (true, the
## default) or don't (false) currently hold a card. Most effects target
## existing cards; a few (e.g. moving a card INTO a formation) need an empty
## destination instead. It has no effect on HAND/DISCARD_PILE -- every index
## within a zone is a real card by definition.
static func get_candidates(target: AbilityTarget, context: TargetContext, require_occupied: bool = true) -> Array[int]:
	match target.scope:
		CardEnums.TargetScope.NONE:
			return []
		CardEnums.TargetScope.SELF:
			return _single(formation_for(target, context), context.source_card)
		CardEnums.TargetScope.ATTACKING_ELEMENTAL:
			return _single(formation_for(target, context), context.attacking_card)
		CardEnums.TargetScope.SELF_SAGE:
			return _single(context.self_formation, context.self_sage)
		CardEnums.TargetScope.ENEMY_SAGE:
			return _single(context.enemy_formation, context.enemy_sage)
		CardEnums.TargetScope.ROW:
			return _by_occupancy(formation_for(target, context), require_occupied, target.rows)
		CardEnums.TargetScope.FORMATION:
			return _by_occupancy(formation_for(target, context), require_occupied, [])
		CardEnums.TargetScope.ROWS_AWAY:
			return _rows_away_candidates(target, context, require_occupied)
		CardEnums.TargetScope.HAND:
			return _zone_indices(_hand_for(target.team, context))
		CardEnums.TargetScope.DISCARD_PILE:
			return _zone_indices(_discard_pile_for(target.team, context))
		_:
			push_error("TargetResolver: unhandled TargetScope %s" % target.scope)
			return []

## The single source of truth for "which formation does this target mean."
## SELF/SELF_SAGE/ATTACKING_ELEMENTAL always mean the ability owner's own
## side and ignore target.team entirely (see AbilityTarget.team for why that
## field is meaningless for them); ENEMY_SAGE is always the opponent's; only
## ROW/FORMATION actually vary by team. Anything that needs to know which
## formation a target refers to (EffectExecutor included) should call this
## instead of re-deriving the rule.
static func formation_for(target: AbilityTarget, context: TargetContext) -> Formation:
	match target.scope:
		CardEnums.TargetScope.SELF, CardEnums.TargetScope.SELF_SAGE, CardEnums.TargetScope.ATTACKING_ELEMENTAL:
			return context.self_formation
		CardEnums.TargetScope.ENEMY_SAGE:
			return context.enemy_formation
		_:
			return context.self_formation if target.team == CardEnums.Team.SELF else context.enemy_formation

## Whether a specific set of chosen spaces is a legal resolution of this
## target: every choice must be a real candidate, and the count must respect
## the target's selection mode (ALL, or up to `count` for CHOOSE_N).
static func validate_choice(target: AbilityTarget, chosen: Array[int], context: TargetContext, require_occupied: bool = true) -> bool:
	var candidates := get_candidates(target, context, require_occupied)
	for space_number in chosen:
		if not candidates.has(space_number):
			return false
	match target.selection:
		CardEnums.TargetSelection.ALL:
			return chosen.size() == candidates.size()
		CardEnums.TargetSelection.CHOOSE_N:
			return chosen.size() <= target.count
	return false

static func _hand_for(team: CardEnums.Team, context: TargetContext) -> CardZone:
	return context.self_hand if team == CardEnums.Team.SELF else context.enemy_hand

static func _discard_pile_for(team: CardEnums.Team, context: TargetContext) -> CardZone:
	return context.self_discard_pile if team == CardEnums.Team.SELF else context.enemy_discard_pile

static func _zone_indices(zone: CardZone) -> Array[int]:
	if zone == null:
		return []
	var result: Array[int] = []
	for i in range(zone.size()):
		result.append(i)
	return result

static func _single(formation: Formation, card: CardInstance) -> Array[int]:
	if formation == null or card == null:
		return []
	var space_number := formation.find_space_of(card)
	return [space_number] if space_number != -1 else []

## "N rows away" (Far Strike, Farsight Frenzy, Primitive Strike, Projectile
## Blast) -- target.rows[0] holds N, a distance counted along the whole
## board, through the attacking Elemental's own rows and into the
## opponent's, not a fixed row number. Confirmed directly with the user:
## from your own Row II, "2 rows away" is the opponent's Row I -- the count
## crosses the boundary between formations rather than restarting at the
## opponent's Row I. So target_row = N - attacker_row + 1. Needs
## context.attacking_card to know where to count from; returns no
## candidates if that's unset (nothing chosen yet) or the computed row
## doesn't exist on this size formation.
static func _rows_away_candidates(target: AbilityTarget, context: TargetContext, require_occupied: bool) -> Array[int]:
	if context.attacking_card == null or target.rows.is_empty():
		return []
	var attacker_space := context.self_formation.find_space_of(context.attacking_card)
	if attacker_space == -1:
		return []
	var attacker_row := context.self_formation.get_space(attacker_space).row
	var target_row: int = target.rows[0] - attacker_row + 1
	var enemy_formation := formation_for(target, context)
	if enemy_formation == null or target_row < 1 or target_row > enemy_formation.row_capacities.size():
		return []
	return _by_occupancy(enemy_formation, require_occupied, [target_row])

static func _by_occupancy(formation: Formation, require_occupied: bool, rows: Array[int]) -> Array[int]:
	if formation == null:
		return []
	var space_numbers: Array[int] = []
	if rows.is_empty():
		for space in formation.spaces:
			space_numbers.append(space.space_number)
	else:
		for row in rows:
			space_numbers.append_array(formation.get_row_spaces(row))

	var result: Array[int] = []
	for space_number in space_numbers:
		var occupied := not formation.get_space(space_number).is_empty()
		if occupied == require_occupied:
			result.append(space_number)
	return result
