extends Node2D
class_name Projectile

#
var origin : Vector2					= Vector2.ZERO
var destination : Vector2				= Vector2.ZERO
var delay : float						= 0.0
var elapsed : float						= 0.0

#
func _process(delta):
	elapsed = min(delay, elapsed + delta)
	if elapsed == delay:
		Util.RemoveNode(self, get_parent())
	else:
		global_position = lerp(origin, destination, elapsed / delay)
