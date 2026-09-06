class_name AbilityBuilder

static func ability(trigger: CardEnums.AbilityTrigger, effects: Array[AbilityEffect], raw_text: String,
		condition: AbilityCondition = null, is_optional: bool = false) -> CardAbility:
	var a := CardAbility.new()
	a.trigger = trigger
	a.effects = effects
	a.raw_text = raw_text
	a.condition = condition
	a.is_optional = is_optional
	return a

static func effect(action: CardEnums.AbilityAction, targets: Array[AbilityTarget] = [],
		amount: int = 0, amount_source: CardEnums.AmountSource = CardEnums.AmountSource.FIXED,
		multiplier: int = 1) -> AbilityEffect:
	var e := AbilityEffect.new()
	e.action = action
	e.targets = targets
	e.amount = amount
	e.amount_source = amount_source
	e.multiplier = multiplier
	return e

static func target(scope: CardEnums.TargetScope, team: CardEnums.Team = CardEnums.Team.ENEMY,
		rows: Array[int] = [], count: int = 1) -> AbilityTarget:
	var t := AbilityTarget.new()
	t.scope = scope
	t.team = team
	t.rows = rows
	t.count = count
	return t

static func cond(stat: CardEnums.ConditionStat, amount: int,
		comparator: CardEnums.Comparator = CardEnums.Comparator.GREATER_OR_EQUAL,
		subject: CardEnums.Team = CardEnums.Team.SELF) -> AbilityCondition:
	var c := AbilityCondition.new()
	c.stat = stat
	c.amount = amount
	c.comparator = comparator
	c.subject = subject
	return c
