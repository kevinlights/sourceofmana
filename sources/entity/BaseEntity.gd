extends CharacterBody2D
class_name BaseEntity

#
var displayName : bool					= false
var entityName : String					= "PlayerName"

var entityState : EntityCommons.State	= EntityCommons.State.IDLE
var entityVelocity : Vector2			= Vector2.ZERO
var entityPosOffset : Vector2			= Vector2.ZERO

@onready var interactive : EntityInteractive	= $Interactions
var inventory : EntityInventory			= EntityInventory.new()
var stat : EntityStats					= EntityStats.new()
var visual : EntityVisual				= EntityVisual.new()

# Init
func SetKind(_entityKind : String, _entityID : String, _entityName : String):
	entityName	= _entityID if _entityName.length() == 0 else _entityName
	set_name(entityName)

func SetData(data : EntityData):
	# Stat
	if data._stats:
		stat.Init(data)

	# Display
	displayName			= data._displayName or self is PlayerEntity
	SetVisual(data)

func SetVisual(data : EntityData):
	visual.Init(self, data)

#
func Update(nextVelocity : Vector2, gardbandPosition : Vector2, nextState : EntityCommons.State):
	var dist = Vector2(gardbandPosition - position).length()
	if dist > EntityCommons.MaxGuardbandDist:
		position = gardbandPosition

	entityPosOffset = gardbandPosition - position
	entityVelocity = nextVelocity
	entityState = nextState

#
func _physics_process(delta):
	velocity = entityVelocity

	if entityPosOffset.length() > EntityCommons.StartGuardbandDist:
		var ratioOffsetToApply : float = EntityCommons.PatchGuardband * delta
		var posOffsetFix : Vector2 = Vector2(ratioOffsetToApply, ratioOffsetToApply).clamp(Vector2.ZERO, entityPosOffset.abs()) * sign(entityPosOffset)
		entityPosOffset -= posOffsetFix
		velocity += posOffsetFix


	if velocity != Vector2.ZERO:
		move_and_slide()

func _process(delta):
	visual.Refresh(delta)

func _ready():
	if interactive:
		interactive.SpecificInit(self, self == Launcher.Player)
