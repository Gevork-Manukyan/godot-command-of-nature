class_name GoldPool
extends RefCounted

## A player's (or team's) gold, clamped to the rulebook's cap (12 for 2-player,
## 20 for 4-player team). Selling a card when already at the cap collects no
## extra gold, per the rules -- add()/remove() enforce that by clamping rather
## than the caller having to remember to check first.

var amount: int = 0
var max_amount: int

func _init(starting_max: int):
	max_amount = starting_max

func add(value: int) -> void:
	amount = min(amount + value, max_amount)

func remove(value: int) -> void:
	amount = max(amount - value, 0)
