extends Label

#
var timeLeft : float						= 3.0
var fadingTime : float						= 1.0
var velocity : Vector2						= Vector2.ZERO
var criticalDamage : bool					= false
var HSVA : Vector4							= Vector4.ZERO
var floorPosition : float					= 0.0

const gravityRedux : float					= 180.0
const maxVelocityAngle : float				= 36
const minVelocitySpeed : float				= 24.0
const maxVelocitySpeed : float				= 60.0
const overheadOffset : int					= -10

#
func SetPosition(startPos : Vector2, floorPos : Vector2):
	position = startPos
	floorPosition = floorPos.y

func SetDamage(dealer : BaseEntity, damage : int, damageType : EntityCommons.DamageType):
	var hue : float = 0.0
	match damageType:
		EntityCommons.DamageType.CRIT:
			criticalDamage = true
			set_text(str(damage))
		EntityCommons.DamageType.DODGE:
			hue = EntityCommons.DodgeAttackColor
			set_text("dodge")
		EntityCommons.DamageType.HIT:
			if dealer == Launcher.Player:
				hue = EntityCommons.LocalAttackColor
			elif dealer is PlayerEntity:
				hue = EntityCommons.PlayerAttackColor
			else:
				hue = EntityCommons.MonsterAttackColor
			set_text(str(damage))
		EntityCommons.DamageType.MISS:
			hue = EntityCommons.MissAttackColor
			set_text("miss")

	HSVA = Vector4(hue, 0.8, 1.0, 1.0)

	velocity.x = randf_range(-maxVelocityAngle, maxVelocityAngle)
	velocity.y = randf_range(minVelocitySpeed, maxVelocitySpeed)

	add_theme_color_override("font_color", Color.from_hsv(HSVA.x, HSVA.y, HSVA.z, HSVA.w))
	add_theme_color_override("font_outline_color", Color.from_hsv(HSVA.x, HSVA.y, 0.0, HSVA.w))

#
func _process(delta):
	timeLeft -= delta
	if timeLeft <= 0.0: 
		queue_free()
		return

	if timeLeft < fadingTime:
		modulate.a = timeLeft / fadingTime

	var deltaVelocity : Vector2 = velocity * delta
	if position.y - deltaVelocity.y >= floorPosition:
		velocity.y = -velocity.y
		velocity.y *= 0.66
	position -= deltaVelocity
	velocity.y -= gravityRedux * delta

	if criticalDamage:
		HSVA.x = HSVA.x + delta * 2
		if HSVA.x > 1.0:
			HSVA.x = 0.0
		if HSVA.x > 0.3 and HSVA.x < 0.7:
			HSVA.x = 0.7

		add_theme_color_override("font_color", Color.from_hsv(HSVA.x, HSVA.y, HSVA.z, HSVA.w))
		add_theme_color_override("font_outline_color", Color.from_hsv(HSVA.x, HSVA.y, 0.2, HSVA.w))
