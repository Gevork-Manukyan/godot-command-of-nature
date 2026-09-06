class_name FormationSpace
extends RefCounted

var space_number: int
var row: int
var neighbors: Array[int]
var card: CardInstance = null

func _init(number: int, space_row: int, space_neighbors: Array[int]):
	space_number = number
	row = space_row
	neighbors = space_neighbors

func is_empty() -> bool:
	return card == null
