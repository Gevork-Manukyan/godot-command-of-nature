class_name CardLibrary

static func cedar() -> ElementalSageCardDefinition:
	var card := ElementalSageCardDefinition.new()
	card.card_name = "Cedar"
	card.price = 1
	card.element = CardEnums.Element.TWIG
	card.attack = 3
	card.health = 12
	card.row_requirement = [1, 2, 3]
	card.is_daybreak = true
	card.sage = CardEnums.Sage.CEDAR
	return card

static func vix_vanguard() -> ElementalChampionCardDefinition:
	var card := ElementalChampionCardDefinition.new()
	card.card_name = "Vix Vanguard"
	card.price = 1
	card.element = CardEnums.Element.TWIG
	card.attack = 3
	card.health = 6
	card.row_requirement = [1]
	card.is_daybreak = true
	card.level_requirement = 4
	return card

static func acorn_squire() -> ElementalWarriorCardDefinition:
	var card := ElementalWarriorCardDefinition.new()
	card.card_name = "Acorn Squire"
	card.price = 1
	card.element = CardEnums.Element.TWIG
	card.attack = 2
	card.health = 3
	card.row_requirement = [1, 2]
	card.is_daybreak = false
	return card

static func timber() -> ElementalCardDefinition:
	var card := ElementalCardDefinition.new()
	card.card_name = "Timber"
	card.price = 1
	card.element = CardEnums.Element.TWIG
	card.attack = 2
	card.health = 2
	return card

static func close_strike() -> ItemAttackCardDefinition:
	var card := ItemAttackCardDefinition.new()
	card.card_name = "Close Strike"
	card.price = 1
	card.row_requirement = [1]
	return card

static func droplet_charm() -> ItemCardDefinition:
	var card := ItemCardDefinition.new()
	card.card_name = "Droplet Charm"
	card.price = 1
	card.item_type = CardEnums.ItemType.INSTANT
	return card

static func elemental_incantation() -> ItemCardDefinition:
	var card := ItemCardDefinition.new()
	card.card_name = "Elemental Incantation"
	card.price = 5
	card.item_type = CardEnums.ItemType.UTILITY
	return card
