class_name AbilityFirer

## Combat-modifier effects are never fired as standalone effects -- they're
## applied as modifiers by whichever caller checks for them directly (e.g.
## CombatResolver checking for DONT_REMOVE_BOOST), so an ability containing
## only these has nothing left to do here.
const COMBAT_MODIFIER_ACTIONS: Array = [
	CardEnums.AbilityAction.DONT_REMOVE_BOOST,
	CardEnums.AbilityAction.DONT_REMOVE_SHIELD,
	CardEnums.AbilityAction.REDIRECT_DAMAGE_TO_SELF,
	CardEnums.AbilityAction.REDUCE_DAMAGE,
	CardEnums.AbilityAction.NEGATE_DAMAGE,
]

## Scopes with exactly one legal answer, resolvable without asking anyone.
const NO_CHOICE_SCOPES: Array = [
	CardEnums.TargetScope.NONE,
	CardEnums.TargetScope.SELF,
	CardEnums.TargetScope.SELF_SAGE,
	CardEnums.TargetScope.ENEMY_SAGE,
	CardEnums.TargetScope.ATTACKING_ELEMENTAL,
]

## Fires an eligible ability's effects in order, stopping at the first one
## that needs a target choice (ROW/FORMATION/DISCARD_PILE/HAND). Everything
## before that point has already executed; that effect and everything after
## it are returned, in order, for the caller to resolve and execute
## themselves (via TargetResolver then EffectExecutor.execute()) -- never
## guessed at. Stopping at the first ambiguous effect (rather than only
## deferring that one effect) matters for chains like Ruby Guardian's
## "discard up to 2, then add 2 shields for each discarded": the second
## effect's amount depends on the first's actual result, so it can't
## auto-resolve out of order even though summoning the pattern might suggest
## otherwise.
static func fire(ability: CardAbility, context: EffectContext) -> Array:
	var pending := []
	var deferring := false
	for effect in ability.effects:
		if COMBAT_MODIFIER_ACTIONS.has(effect.action):
			continue
		if deferring or needs_target_choice(effect):
			deferring = true
			pending.append(effect)
		else:
			EffectExecutor.execute(effect, auto_chosen_targets(effect, context), context)
	return pending

static func needs_target_choice(effect: AbilityEffect) -> bool:
	for target in effect.targets:
		if not NO_CHOICE_SCOPES.has(target.scope):
			return true
	return false

static func auto_chosen_targets(effect: AbilityEffect, context: EffectContext) -> Array:
	var chosen := []
	for target in effect.targets:
		chosen.append(TargetResolver.get_candidates(target, context.targets))
	return chosen
