extends Actor
class_name Entity

#
@onready var interactive : EntityInteractive	= $Interactive
@onready var visual : EntityVisual				= $Visual

var target : Entity						= null

var gender : ActorCommons.Gender		= ActorCommons.Gender.MALE
var entityVelocity : Vector2			= Vector2.ZERO
var entityPosOffset : Vector2			= Vector2.ZERO
var entityOrientation : Vector2			= Vector2.ZERO

var agentID : int						= -1

signal entity_died

# Init
func SetData(data : EntityData):
	SetVisual(data)
	interactive.Init(data)

func SetVisual(data : EntityData, morphed : bool = false):
	var visualInitCallback : Callable = visual.Init.bind(data)
	if morphed:
		interactive.DisplayMorph(visualInitCallback)
	else:
		visualInitCallback.call()

#
func Update(nextVelocity : Vector2, gardbandPosition : Vector2, nextOrientation : Vector2, nextState : ActorCommons.State, nextskillCastID : int):
	var dist = Vector2(gardbandPosition - position).length_squared()
	if dist > NetworkCommons.MaxGuardbandDistSquared:
		position = gardbandPosition

	entityPosOffset = gardbandPosition - position
	entityVelocity = nextVelocity
	var previousState = state
	state = nextState
	entityOrientation = nextOrientation

	if visual and visual.skillCastID != nextskillCastID:
		visual.skillCastID = nextskillCastID
		interactive.DisplayCast(self, nextskillCastID)

	if previousState != nextState and nextState == ActorCommons.State.DEATH:
		entity_died.emit()

# Local player specific functions
func SetLocalPlayer():
	collision_layer |= 2

	if Launcher.Camera:
		Launcher.Camera.mainCamera = FileSystem.LoadEntityComponent("Camera")
		if Launcher.Camera.mainCamera:
			add_child.call_deferred(Launcher.Camera.mainCamera)
	
	entity_died.connect(Launcher.GUI.respawnWindow.EnableControl.bind(true))
	Launcher.Network.RetrieveInventory()

func ClearTarget():
	if target != null:
		if target.interactive.nameLabel.material:
			target.interactive.nameLabel.material = null
		Callback.SelfDestructTimer(target.interactive.healthBar, ActorCommons.DisplayHPDelay, target.interactive.HideHP, "HideHP")
		target = null

func Target(source : Vector2, interactable : bool = true):
	ClearTarget()
	target = Entities.GetNearestTarget(source, interactable)

	if target:
		if interactable and target.type == ActorCommons.Type.NPC:
			target.interactive.nameLabel.material = ActorCommons.AllyTarget
		elif target.type == ActorCommons.Type.MONSTER:
			target.interactive.nameLabel.material = ActorCommons.EnemyTarget
			Launcher.Network.TriggerSelect(target.agentID)

func Interact():
	if not target or target.state == ActorCommons.State.DEATH:
		Target(position, true)
	if not target:
		return

	if target.type == ActorCommons.Type.NPC:
		Launcher.Network.TriggerInteract(target.agentID)
	elif target.type == ActorCommons.Type.MONSTER:
		Cast(SkillCommons.SkillDefaultAttack)

func Cast(skillID : int):
	var skill : SkillCell = DB.SkillsDB[skillID]
	Util.Assert(skill != null, "Skill ID is not found, can't cast it")
	if skill == null:
		return

	var entityID : int = 0
	if skill.mode == Skill.TargetMode.SINGLE:
		if not target or target.state == ActorCommons.State.DEATH:
			Target(position, false)
		if target and target.type == ActorCommons.Type.MONSTER:
			entityID = target.agentID

	Launcher.Network.TriggerCast(entityID, skillID)

#
func _physics_process(delta : float):
	velocity = entityVelocity

	if entityPosOffset.length_squared() > NetworkCommons.StartGuardbandDistSquared and delta > 0:
		var signOffset = sign(entityPosOffset)
		var posOffsetFix : Vector2 = stat.current.walkSpeed * 0.5 * delta * signOffset
		entityPosOffset.x = max(0, entityPosOffset.x - posOffsetFix.x) if signOffset.x > 0 else min(0, entityPosOffset.x - posOffsetFix.x)
		entityPosOffset.y = max(0, entityPosOffset.y - posOffsetFix.y) if signOffset.y > 0 else min(0, entityPosOffset.y - posOffsetFix.y)
		velocity += posOffsetFix / delta

	if velocity != Vector2.ZERO:
		move_and_slide()

func _ready():
	if Launcher.Player != self:
		stat.active_stats_updated.connect(interactive.DisplayHP)
	entity_died.connect(interactive.DisplayHP)
