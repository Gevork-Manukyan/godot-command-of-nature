class_name CombatResolver

## Resolves a single attack: an Attack Command's DEAL_DAMAGE effect, used by
## context.targets.attacking_card, against already-chosen target(s).
##
## instant_effects are the Instant Commands the DEFENDING player chose to
## play in response, already resolved to their AbilityEffect (this class
## doesn't ask them anything or validate that they could afford/legally play
## them -- that's the caller's job, same as everywhere else in this
## codebase: game logic never decides a choice that belongs to a player).
## Each REDUCE_DAMAGE effect's resolved amount is subtracted from the
## attack's damage; a NEGATE_DAMAGE effect zeroes it outright. Per the
## rulebook, Utility Command damage can't be reduced by Instants at all --
## don't call this for those, call EffectExecutor.execute() directly.
##
## Shield reduction happens inside EffectExecutor.execute() (a general damage
## rule -- see the comment on _deal_damage there). What this adds:
## - The Instant-response math.
## - Clearing the attacker's boosts, unless it has an eligible
##   DONT_REMOVE_BOOST ability (e.g. Calamity Leopard) among ON_ATTACK and
##   whichever of ON_MELEE_ATTACK/ON_RANGED_ATTACK matches attack_type.
## - Firing the attacker's OTHER eligible abilities on those same triggers
##   (via the shared AbilityFirer -- same "fire what's unambiguous, defer
##   what needs a choice" logic Daybreak activation also uses), plus
##   ON_DAMAGE_DEALT (if any target actually took damage) and
##   ON_DEFEAT_ENEMY (once per target this attack defeated). Boosts are
##   cleared BEFORE these fire, so an ability that adds a fresh boost (e.g.
##   Splinter Stinger) doesn't have it immediately stripped by this same
##   attack's own clear step.
##
## Returns {"pending": Array, "defeated_count": int}.
##
## "pending" holds the abilities found eligible whose effects need a target
## choice this function can't make on its own (e.g. Lumber Claw choosing
## which enemies to hit, Komodo Kin choosing a discard card and a
## destination space) -- as {"card": CardInstance, "ability": CardAbility}
## entries, same shape as TriggerDetector.find_eligible(). The caller must
## resolve targets for each (via TargetResolver, same as any other effect)
## and call EffectExecutor.execute() itself; this never guesses on a
## player's behalf.
##
## "defeated_count" is how many targets this specific attack defeated --
## callers that track leveling (each defeat raises level by 1, per the
## rulebook) should call PlayerState.level_up() that many times.
##
## Still not handled at all (need more than trigger detection/firing alone):
## DONT_REMOVE_SHIELD (no card uses it) and REDIRECT_DAMAGE_TO_SELF (King
## Crustacean and Terrain Tumbler have different redirect mechanics -- one
## involves a position swap, one doesn't -- and both require the player to
## opt in, which needs its own explicit parameter once a caller can decide it).
static func resolve_attack(attack_effect: AbilityEffect, attack_type: CardEnums.AttackType, chosen_per_target: Array, context: EffectContext, instant_effects: Array[AbilityEffect] = []) -> Dictionary:
	if attack_effect.action != CardEnums.AbilityAction.DEAL_DAMAGE:
		push_error("CombatResolver: resolve_attack expects a DEAL_DAMAGE effect")
		return {"pending": [], "defeated_count": 0}

	var defenders_before := _snapshot_defenders(attack_effect, chosen_per_target, context)

	var base_amount := EffectExecutor.resolve_amount(attack_effect, context)
	var final_amount := _apply_instant_reductions(base_amount, instant_effects, context)

	var resolved_effect := attack_effect.duplicate()
	resolved_effect.amount = final_amount
	resolved_effect.amount_source = CardEnums.AmountSource.FIXED
	resolved_effect.multiplier = 1
	EffectExecutor.execute(resolved_effect, chosen_per_target, context)

	var any_damage_dealt := false
	var defeated_count := 0
	for entry in defenders_before:
		if entry["card"].current_damage > entry["prior_damage"]:
			any_damage_dealt = true
		if entry["card"].is_defeated():
			defeated_count += 1

	var attacker := context.targets.attacking_card
	if attacker == null:
		return {"pending": [], "defeated_count": defeated_count}
	var self_formation := context.targets.self_formation

	var attack_triggers: Array = [CardEnums.AbilityTrigger.ON_ATTACK]
	attack_triggers.append(CardEnums.AbilityTrigger.ON_MELEE_ATTACK if attack_type == CardEnums.AttackType.MELEE else CardEnums.AbilityTrigger.ON_RANGED_ATTACK)

	var keeps_boosts := TriggerDetector.has_eligible_effect(attacker, attack_triggers, CardEnums.AbilityAction.DONT_REMOVE_BOOST, self_formation)
	if not keeps_boosts:
		attacker.boost_count = 0

	var pending := []
	for trigger in attack_triggers:
		_fire_or_defer(attacker, trigger, self_formation, context, pending)

	if any_damage_dealt:
		_fire_or_defer(attacker, CardEnums.AbilityTrigger.ON_DAMAGE_DEALT, self_formation, context, pending)
	for i in range(defeated_count):
		_fire_or_defer(attacker, CardEnums.AbilityTrigger.ON_DEFEAT_ENEMY, self_formation, context, pending)

	return {"pending": pending, "defeated_count": defeated_count}

static func _snapshot_defenders(attack_effect: AbilityEffect, chosen_per_target: Array, context: EffectContext) -> Array:
	var snapshot := []
	for i in range(attack_effect.targets.size()):
		var formation := TargetResolver.formation_for(attack_effect.targets[i], context.targets)
		for space_number in chosen_per_target[i]:
			var card := formation.get_card(space_number)
			if card != null:
				snapshot.append({"card": card, "prior_damage": card.current_damage})
	return snapshot

## Finds the attacker's eligible ability (if any) on this trigger and hands
## it to AbilityFirer -- appending to pending only if something remains
## unresolved. See AbilityFirer for why an ability that's only a
## DONT_REMOVE_BOOST-style modifier (e.g. Calamity Leopard's) ends up with
## nothing left to fire or defer here.
static func _fire_or_defer(card: CardInstance, trigger: CardEnums.AbilityTrigger, formation: Formation, context: EffectContext, pending: Array) -> void:
	var ability := TriggerDetector.find_eligible_on_card(card, trigger, formation)
	if ability == null:
		return
	var remaining := AbilityFirer.fire(ability, context)
	if not remaining.is_empty():
		pending.append({"card": card, "ability": ability})

static func _apply_instant_reductions(base_amount: int, instant_effects: Array[AbilityEffect], context: EffectContext) -> int:
	var amount := base_amount
	for instant in instant_effects:
		match instant.action:
			CardEnums.AbilityAction.NEGATE_DAMAGE:
				return 0
			CardEnums.AbilityAction.REDUCE_DAMAGE:
				amount -= EffectExecutor.resolve_amount(instant, context)
			_:
				push_error("CombatResolver: %s is not a valid Instant Command response action" % CardEnums.AbilityAction.keys()[instant.action])
	return maxi(amount, 0)
