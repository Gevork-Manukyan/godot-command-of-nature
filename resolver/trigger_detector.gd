class_name TriggerDetector

## Finds which of a card's abilities are CURRENTLY eligible to fire/activate
## for a given trigger: the trigger type matches, the card is positioned in
## one of its allowed rows right now (the wiki's "Row Required to Use
## Daybreak/Trigger" applies to both Daybreak and event-triggered abilities
## alike), and any condition on the ability passes. Pure detection only --
## nothing here decides whether an optional ability actually gets used, or
## executes any effect. Only Elemental cards (Sage/Champion/Warrior) have row
## requirements and abilities in this sense; Item cards' "Row Required to
## Use" is a different check (can THIS elemental use THIS attack card) that
## belongs to card-play validation, not this class.

## One eligible match: which card has the ability, and the ability itself.
static func find_eligible(trigger: CardEnums.AbilityTrigger, formation: Formation) -> Array:
	var results := []
	for space in formation.spaces:
		if space.card == null:
			continue
		for ability in _abilities_of(space.card):
			if ability.trigger != trigger:
				continue
			if not _row_eligible(space.card, space.row):
				continue
			if not ConditionEvaluator.evaluate(ability.condition, space.card):
				continue
			results.append({"card": space.card, "ability": ability})
	return results

## Convenience for checking one specific card rather than scanning a whole
## formation: the first currently-eligible ability matching this trigger, or
## null. find_space_of() failing (card isn't on this formation) means "not
## eligible", not an error -- callers may pass a card without knowing yet.
static func find_eligible_on_card(card: CardInstance, trigger: CardEnums.AbilityTrigger, formation: Formation) -> CardAbility:
	var space_number := formation.find_space_of(card)
	if space_number == -1:
		return null
	var row := formation.get_space(space_number).row
	return find_eligible_at_row(card, trigger, row)

## Same eligibility check as find_eligible_on_card(), but for a row given
## directly instead of derived from the card's current position -- Daybreak
## eligibility is locked in at the start of Phase I (see Turn's
## _daybreak_row_snapshot), so it needs to check the row a card started the
## phase in, not wherever it's moved to since (e.g. River Rogue/Whirl
## Whipper both shift Elementals between rows as their own Daybreak effect).
static func find_eligible_at_row(card: CardInstance, trigger: CardEnums.AbilityTrigger, row: int) -> CardAbility:
	for ability in _abilities_of(card):
		if ability.trigger == trigger and _row_eligible(card, row) and ConditionEvaluator.evaluate(ability.condition, card):
			return ability
	return null

## Whether any of the given triggers has a currently-eligible ability on this
## card containing an effect with the given action -- e.g. "does the
## attacker have an eligible DONT_REMOVE_BOOST among its on-attack triggers."
static func has_eligible_effect(card: CardInstance, triggers: Array, action: CardEnums.AbilityAction, formation: Formation) -> bool:
	for trigger in triggers:
		var ability := find_eligible_on_card(card, trigger, formation)
		if ability == null:
			continue
		for effect in ability.effects:
			if effect.action == action:
				return true
	return false

static func _abilities_of(card: CardInstance) -> Array[CardAbility]:
	if card.definition is ElementalWarriorCardDefinition:
		return card.definition.ability
	return []

static func _row_eligible(card: CardInstance, current_row: int) -> bool:
	if card.definition is ElementalWarriorCardDefinition:
		var requirement: Array[int] = card.definition.row_requirement
		return requirement.is_empty() or requirement.has(current_row)
	return true
