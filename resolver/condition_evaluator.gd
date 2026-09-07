class_name ConditionEvaluator

## Evaluates an AbilityCondition against the card it belongs to (e.g. Vix
## Vanguard's "if this Elemental has at least 1 boost on it"). A null
## condition always passes -- most abilities have none.
##
## Every condition in the card library so far has subject=SELF, checking a
## stat on the ability's own owner; that's the only case this handles. GOLD/
## HAND_SIZE stats need a GoldPool/CardZone, not just a card, and no current
## card uses them -- both push_error rather than silently returning a wrong
## answer if ever hit.
static func evaluate(condition: AbilityCondition, source_card: CardInstance) -> bool:
	if condition == null:
		return true
	if condition.subject != CardEnums.Team.SELF:
		push_error("ConditionEvaluator: only subject=SELF is supported")
		return false

	var actual := _stat_value(condition.stat, source_card)
	match condition.comparator:
		CardEnums.Comparator.EQUAL:
			return actual == condition.amount
		CardEnums.Comparator.GREATER_OR_EQUAL:
			return actual >= condition.amount
		CardEnums.Comparator.LESS_OR_EQUAL:
			return actual <= condition.amount
		CardEnums.Comparator.GREATER_THAN:
			return actual > condition.amount
		CardEnums.Comparator.LESS_THAN:
			return actual < condition.amount
	return false

static func _stat_value(stat: CardEnums.ConditionStat, source_card: CardInstance) -> int:
	match stat:
		CardEnums.ConditionStat.BOOST_COUNT:
			return source_card.boost_count
		CardEnums.ConditionStat.SHIELD_COUNT:
			return source_card.shield_count
		CardEnums.ConditionStat.DAMAGE_COUNT:
			return source_card.current_damage
		CardEnums.ConditionStat.GOLD, CardEnums.ConditionStat.HAND_SIZE:
			push_error("ConditionEvaluator: %s needs a GoldPool/Hand, not just a card -- not supported yet" % CardEnums.ConditionStat.keys()[stat])
			return 0
	return 0
