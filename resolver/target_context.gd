class_name TargetContext
extends RefCounted

## Everything target resolution needs beyond the AbilityTarget data itself:
## whose formation/hand/discard pile is "self" vs "enemy" from the resolving
## player's point of view, which card owns the ability (for SELF), and which
## card is currently attacking, if any (for ATTACKING_ELEMENTAL).
##
## Hand/discard fields are optional since most target resolution (board-only
## cards) never touches them. No card in the library currently targets an
## opponent's hand or discard pile, but both sides are modeled for symmetry
## with ROW/FORMATION, which already resolve for either team.

var self_formation: Formation
var enemy_formation: Formation
var source_card: CardInstance
var attacking_card: CardInstance
var self_hand: CardZone
var enemy_hand: CardZone
var self_discard_pile: CardZone
var enemy_discard_pile: CardZone

func _init(self_form: Formation, enemy_form: Formation, source: CardInstance = null, attacker: CardInstance = null,
		hand: CardZone = null, discard_pile: CardZone = null, other_hand: CardZone = null, other_discard_pile: CardZone = null):
	self_formation = self_form
	enemy_formation = enemy_form
	source_card = source
	attacking_card = attacker
	self_hand = hand
	self_discard_pile = discard_pile
	enemy_hand = other_hand
	enemy_discard_pile = other_discard_pile
