class_name CardDisplay
extends PanelContainer

## Renders a single card, given only its static CardDefinition (e.g. a
## Market listing) or a definition plus a live CardInstance for board state
## (current damage shown as remaining HP, shield/boost badges). No card art
## exists yet (every CardDefinition.art is unset) -- the art area is an
## element-tinted ColorRect placeholder instead of a TextureRect, swap it
## for real art later without touching the rest of this scene.

## Node references are resolved live in _refresh() via %UniqueName rather
## than cached with @onready -- @onready only fills in once _ready() fires
## (i.e. once this node actually enters a SceneTree), but set_card() needs
## to work immediately after PackedScene.instantiate() too (e.g. a Market
## building its listing scenes before adding them to the tree). %UniqueName
## lookups only need `owner` to be set, which instantiate() already does,
## so this works in both cases.

## Emitted on a left-click anywhere on the card -- what that means (select
## for playing, pick as an attacker/target, ignore) is entirely up to
## whoever's listening; this display never decides game meaning, same as
## every other layer in this project never guesses a player's choice.
signal pressed(display: CardDisplay)

var definition: CardDefinition
var instance: CardInstance
var selected: bool = false

func set_card(new_definition: CardDefinition, new_instance: CardInstance = null) -> void:
	definition = new_definition
	instance = new_instance
	selected = false
	_refresh()

## Toggles a visible highlight -- callers use this to show what's currently
## selected (a hand card about to be played, an attacker awaiting a target)
## without needing to know how the highlight is implemented.
func set_selected(value: bool) -> void:
	selected = value
	modulate = Color(1.25, 1.2, 0.7) if selected else Color.WHITE

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(self)

func _refresh() -> void:
	visible = definition != null
	modulate = Color(1.25, 1.2, 0.7) if selected else Color.WHITE
	if definition == null:
		return

	var attack_label: Label = %AttackLabel
	var name_label: Label = %NameLabel
	var health_label: Label = %HealthLabel
	var cost_label: Label = %CostLabel
	var art_rect: ColorRect = %ArtRect
	var ability_label: Label = %AbilityLabel
	var status_row: HBoxContainer = %StatusRow

	name_label.text = definition.card_name
	cost_label.text = str(definition.price)
	art_rect.color = _element_color()

	if definition is ElementalCardDefinition:
		var elemental_def: ElementalCardDefinition = definition
		var attack: int = elemental_def.attack
		var health: int = elemental_def.health
		if instance != null:
			attack = instance.get_effective_attack()
			health = maxi(health - instance.current_damage, 0)
		attack_label.text = str(attack)
		health_label.text = str(health)
		attack_label.visible = true
		health_label.visible = true
	else:
		attack_label.visible = false
		health_label.visible = false

	ability_label.text = _ability_text()

	var show_status := instance != null
	status_row.visible = show_status
	if show_status:
		var damage_label: Label = %DamageLabel
		var shield_label: Label = %ShieldLabel
		var boost_label: Label = %BoostLabel
		damage_label.visible = instance.current_damage > 0
		damage_label.text = "DMG %d" % instance.current_damage
		shield_label.visible = instance.shield_count > 0
		shield_label.text = "SHLD %d" % instance.shield_count
		boost_label.visible = instance.boost_count > 0
		boost_label.text = "BOOST %d" % instance.boost_count

func _ability_text() -> String:
	var abilities: Array[CardAbility] = []
	if definition is ElementalWarriorCardDefinition:
		abilities = definition.ability
	elif definition is ItemCardDefinition:
		abilities = definition.ability
	var lines: Array[String] = []
	for ability in abilities:
		if ability.raw_text != "":
			lines.append(ability.raw_text)
	return "\n".join(lines)

func _element_color() -> Color:
	if not (definition is ElementalCardDefinition):
		return Color(0.36, 0.33, 0.5)  # Commands: neutral indigo -- kept visually distinct from Pebble's stone gray-tan below
	match definition.element:
		CardEnums.Element.TWIG:
			return Color(0.53, 0.37, 0.22)
		CardEnums.Element.PEBBLE:
			return Color(0.64, 0.59, 0.5)
		CardEnums.Element.LEAF:
			return Color(0.27, 0.62, 0.29)
		CardEnums.Element.DROPLET:
			return Color(0.24, 0.52, 0.82)
	return Color.WHITE
