class_name Formation
extends RefCounted

var spaces: Array[FormationSpace] = []
var row_capacities: Array[int] = []

static func new_two_player() -> Formation:
	var f := Formation.new()
	f.row_capacities = [1, 2, 3]
	f._add_space(1, 1, [2, 3])
	f._add_space(2, 2, [1, 3, 4, 5])
	f._add_space(3, 2, [1, 2, 5, 6])
	f._add_space(4, 3, [2, 5])
	f._add_space(5, 3, [2, 3, 4, 6])
	f._add_space(6, 3, [3, 5])
	return f

static func new_four_player_team() -> Formation:
	var f := Formation.new()
	f.row_capacities = [2, 4, 6]
	f._add_space(1, 1, [2, 3, 4, 5])
	f._add_space(2, 1, [1, 4, 5, 6])
	f._add_space(3, 2, [1, 4, 7, 8, 9])
	f._add_space(4, 2, [1, 2, 3, 5, 8, 9, 10])
	f._add_space(5, 2, [1, 2, 4, 6, 9, 10, 11])
	f._add_space(6, 2, [2, 5, 10, 11, 12])
	f._add_space(7, 3, [3, 8])
	f._add_space(8, 3, [3, 4, 7, 9])
	f._add_space(9, 3, [3, 4, 5, 8, 10])
	f._add_space(10, 3, [4, 5, 6, 9, 11])
	f._add_space(11, 3, [5, 6, 10, 12])
	f._add_space(12, 3, [6, 11])
	return f

func _add_space(number: int, row: int, neighbors: Array[int]) -> void:
	spaces.append(FormationSpace.new(number, row, neighbors))

func get_space(space_number: int) -> FormationSpace:
	for space in spaces:
		if space.space_number == space_number:
			return space
	return null

func get_card(space_number: int) -> CardInstance:
	var space := get_space(space_number)
	return space.card if space else null

func add_card(card: CardInstance, space_number: int) -> bool:
	var space := get_space(space_number)
	if space == null or not space.is_empty():
		return false
	space.card = card
	return true

func remove_card(space_number: int) -> CardInstance:
	var space := get_space(space_number)
	if space == null or space.is_empty():
		return null
	var removed := space.card
	space.card = null
	return removed

func move_card(from_space: int, to_space: int) -> bool:
	var source := get_space(from_space)
	var destination := get_space(to_space)
	if source == null or destination == null:
		return false
	if source.is_empty() or not destination.is_empty():
		return false
	destination.card = source.card
	source.card = null
	return true

func swap_cards(space1: int, space2: int) -> bool:
	var a := get_space(space1)
	var b := get_space(space2)
	if a == null or b == null:
		return false
	var temp := a.card
	a.card = b.card
	b.card = temp
	return true

func are_connected(space1: int, space2: int) -> bool:
	var a := get_space(space1)
	return a != null and a.neighbors.has(space2)

func get_row_spaces(row: int) -> Array[int]:
	var result: Array[int] = []
	for space in spaces:
		if space.row == row:
			result.append(space.space_number)
	return result

func get_row_cards(row: int) -> Array[CardInstance]:
	var result: Array[CardInstance] = []
	for space_number in get_row_spaces(row):
		var card := get_card(space_number)
		if card != null:
			result.append(card)
	return result

func is_row_full(row: int) -> bool:
	for space_number in get_row_spaces(row):
		if get_space(space_number).is_empty():
			return false
	return true

func has_space() -> bool:
	for space in spaces:
		if space.is_empty():
			return true
	return false

func get_valid_summon_spaces() -> Array[int]:
	for row in range(1, row_capacities.size() + 1):
		var empties: Array[int] = []
		for space_number in get_row_spaces(row):
			if get_space(space_number).is_empty():
				empties.append(space_number)
		if empties.size() > 0:
			return empties
	return []

func summon(card: CardInstance, space_number: int) -> bool:
	if not get_valid_summon_spaces().has(space_number):
		return false
	return add_card(card, space_number)

func get_connected_cards(space_number: int) -> Array[CardInstance]:
	var result: Array[CardInstance] = []
	var space := get_space(space_number)
	if space == null:
		return result
	for neighbor_number in space.neighbors:
		var card := get_card(neighbor_number)
		if card != null:
			result.append(card)
	return result

func find_space_of(card: CardInstance) -> int:
	for space in spaces:
		if space.card == card:
			return space.space_number
	return -1

func get_sage() -> CardInstance:
	for space in spaces:
		if space.card != null and space.card.definition is ElementalSageCardDefinition:
			return space.card
	return null

func has_sage() -> bool:
	return get_sage() != null
