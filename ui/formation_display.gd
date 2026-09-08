class_name FormationDisplay
extends VBoxContainer

## Visualizes a Formation: one horizontal row per Formation.row_capacities
## entry, each space in ascending space_number order, occupied spaces
## showing a CardDisplay, empty ones a bordered placeholder with the space
## number (useful for now as a debugging aid, and later for picking a
## target/summon space in the real game UI). Row I is at the top by
## default; set reverse_rows = true (before set_formation()) to flip that
## to Row III-at-top -- GameScreen uses this for the opponent's board so
## both sides' Row Is land in the middle of the screen, facing each other,
## matching how the physical board actually reads.
##
## Entirely built from Formation's own row/space data -- works unchanged for
## both new_two_player() (rows of 1/2/3) and new_four_player_team() (rows of
## 2/4/6), including a 4-player team's shared formation with two Sages on
## it, since this just renders whatever's actually on each space.
##
## Rebuilt from scratch on every set_formation() call rather than diffed --
## fine for now (a handful of Control nodes), revisit if/when this needs to
## update every frame during live play instead of on-demand.

const CARD_SCENE: PackedScene = preload("res://ui/card_display.tscn")
const SLOT_SIZE := Vector2(150, 280)
const HIGHLIGHT_COLOR := Color(0.6, 1.1, 0.6)

## Emitted on a left-click anywhere on a space's slot (occupied or empty) --
## same "display never decides game meaning" contract as CardDisplay.pressed.
signal space_pressed(space_number: int)

var formation: Formation
var reverse_rows: bool = false
## space_number -> its slot Control, rebuilt every _rebuild() -- lets
## highlight_spaces()/clear_highlight() find a space's slot directly instead
## of re-walking the whole tree.
var _slot_by_space: Dictionary = {}

func _init() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER

func set_formation(new_formation: Formation) -> void:
	formation = new_formation
	_rebuild()

## Tints the given spaces' slots to show they're currently legal to click
## (a valid summon space, an eligible attacker, a legal target) -- purely
## visual, the actual legality data comes from Formation/TargetResolver;
## this never decides what's legal, only shows what the caller says is.
func highlight_spaces(space_numbers: Array[int]) -> void:
	clear_highlight()
	for space_number in space_numbers:
		if _slot_by_space.has(space_number):
			_slot_by_space[space_number].self_modulate = HIGHLIGHT_COLOR

func clear_highlight() -> void:
	for slot in _slot_by_space.values():
		slot.self_modulate = Color.WHITE

func _rebuild() -> void:
	# remove_child() before queue_free() -- see CardRowDisplay.set_cards()
	# for why queue_free() alone would leave stale children visible to
	# get_children() until end-of-frame, which matters here since
	# _rebuild() can run from inside a child slot's own click handler.
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_slot_by_space.clear()
	if formation == null:
		return
	var rows := range(1, formation.row_capacities.size() + 1)
	if reverse_rows:
		rows.reverse()
	for row in rows:
		var row_box := HBoxContainer.new()
		row_box.alignment = BoxContainer.ALIGNMENT_CENTER
		row_box.add_theme_constant_override("separation", 8)
		add_child(row_box)
		for space in _spaces_in_row(row):
			var slot := _build_slot(space)
			row_box.add_child(slot)
			_slot_by_space[space.space_number] = slot

func _spaces_in_row(row: int) -> Array[FormationSpace]:
	var result: Array[FormationSpace] = []
	for space in formation.spaces:
		if space.row == row:
			result.append(space)
	result.sort_custom(func(a: FormationSpace, b: FormationSpace): return a.space_number < b.space_number)
	return result

## Occupied slots hold a CardDisplay child, which has its own
## mouse_filter = STOP and consumes the click before it can bubble up to
## this slot's own gui_input -- so an occupied slot's clickability comes
## from bridging the child CardDisplay's `pressed` signal into
## space_pressed instead, not from the slot's own gui_input (which only
## ever actually fires for empty slots, where there's no such child).
func _build_slot(space: FormationSpace) -> Control:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.gui_input.connect(_on_slot_gui_input.bind(space.space_number))
	if space.card != null:
		var display: CardDisplay = CARD_SCENE.instantiate()
		slot.add_child(display)
		display.set_card(space.card.definition, space.card)
		display.pressed.connect(func(_d): space_pressed.emit(space.space_number))
	else:
		var label := Label.new()
		label.text = "Space %d\n(empty)" % space.space_number
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.modulate = Color(1, 1, 1, 0.4)
		slot.add_child(label)
	return slot

func _on_slot_gui_input(event: InputEvent, space_number: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		space_pressed.emit(space_number)
