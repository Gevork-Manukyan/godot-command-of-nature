class_name EffectContext
extends RefCounted

## Everything effect EXECUTION needs beyond TargetContext (which only covers
## where an effect applies). self_deck/self_gold are needed for DRAW/
## COLLECT_GOLD; the removed-piles are needed because a defeated Elemental's
## owner (whichever side it belonged to) is who reclaims -- sorry, permanently
## loses -- it, per the rulebook (defeated cards never return, unlike discard).
##
## last_discarded_count carries a running result from one effect to the next
## within the same CardAbility: several cards read "discard up to N... then
## <action> for each card discarded" (e.g. Oak Lumbertron, Ruby Guardian) --
## the discard effect sets this, the following effect's DISCARDED_COUNT
## amount_source reads it.

var targets: TargetContext
var self_deck: Deck
var self_gold: GoldPool
var self_removed_pile: CardZone
var enemy_removed_pile: CardZone
var last_discarded_count: int = 0

func _init(target_context: TargetContext, deck: Deck = null, gold: GoldPool = null,
		removed_pile: CardZone = null, other_removed_pile: CardZone = null):
	targets = target_context
	self_deck = deck
	self_gold = gold
	self_removed_pile = removed_pile
	enemy_removed_pile = other_removed_pile
