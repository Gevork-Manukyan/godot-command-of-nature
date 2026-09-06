class_name AbilityEffect
extends Resource

@export var action: CardEnums.AbilityAction
@export var amount: int = 0
@export var amount_source: CardEnums.AmountSource = CardEnums.AmountSource.FIXED
## For non-FIXED sources, the resolved amount is (dynamic_base * multiplier) + amount.
## Almost everything is multiplier=1 (e.g. "STR - 1"); a card like Ruby Guardian's
## "2 shields for each card discarded" needs multiplier=2.
@export var multiplier: int = 1
@export var targets: Array[AbilityTarget] = []
