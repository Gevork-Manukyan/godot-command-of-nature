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
##
## self_sage/enemy_sage (for SELF_SAGE/ENEMY_SAGE, e.g. Jade Titan's "add a
## shield to your Sage") are likewise supplied by the caller rather than
## derived by searching self_formation/enemy_formation for a Sage --
## Formation.get_sage() only returns *a* Sage, and a 4-player team's shared
## formation holds two. The caller (ultimately PlayerState.sage, set once at
## setup) already knows unambiguously which one is "theirs."

var self_formation: Formation
var enemy_formation: Formation
var source_card: CardInstance
var attacking_card: CardInstance
var self_hand: CardZone
var enemy_hand: CardZone
var self_discard_pile: CardZone
var enemy_discard_pile: CardZone
var self_sage: CardInstance
var enemy_sage: CardInstance

func _init(self_form: Formation, enemy_form: Formation, source: CardInstance = null, attacker: CardInstance = null,
		hand: CardZone = null, discard_pile: CardZone = null, other_hand: CardZone = null, other_discard_pile: CardZone = null,
		sage: CardInstance = null, other_sage: CardInstance = null):
	self_formation = self_form
	enemy_formation = enemy_form
	source_card = source
	attacking_card = attacker
	self_hand = hand
	self_discard_pile = discard_pile
	enemy_hand = other_hand
	enemy_discard_pile = other_discard_pile
	self_sage = sage
	enemy_sage = other_sage
