extends BaseEntity
class_name PlayerEntity

var isPlayableController : bool	= false
var target : BaseEntity			= null

#
func SetLocalPlayer():
	isPlayableController = true
	collision_layer |= 2

	if Launcher.Camera:
		Launcher.Camera.mainCamera = FileSystem.LoadEntityComponent("Camera")
		if Launcher.Camera.mainCamera:
			call_deferred("add_child", Launcher.Camera.mainCamera)

func ClearTarget():
	if target:
		if target.visual.sprites[EntityCommons.Slot.BODY].material:
			target.visual.sprites[EntityCommons.Slot.BODY].material = null
		target = null

func Interact():
	if entityState != EntityCommons.State.IDLE:
		return

	ClearTarget()
	target = null
	if isPlayableController && interactive && Launcher.Map:
		var nearestDistance : float = -1
		for nearEntity in interactive.canInteractWith:
			if nearEntity && nearEntity.entityState != EntityCommons.State.DEATH:
				var distance : float = (nearEntity.position - position).length()
				if nearestDistance == -1 || distance < nearestDistance:
					nearestDistance = distance
					target = nearEntity

		if target:
			var entityID = Launcher.Map.entities.find_key(target)
			if entityID != null:
				if target is NpcEntity:
					Launcher.Network.TriggerInteract(entityID)
					target.visual.call_deferred("SetMaterial", EntityCommons.AllyTarget)
				elif target is MonsterEntity:
					Launcher.Network.TriggerDamage(entityID)
					target.visual.call_deferred("SetMaterial", EntityCommons.EnemyTarget)

#
func _process(deltaTime : float):
	super._process(deltaTime)

	if Launcher.Debug && isPlayableController:
		if Launcher.Debug.correctPos:
			Launcher.Debug.correctPos.position = position + entityPosOffset
		if Launcher.Debug.wrongPos:
			Launcher.Debug.wrongPos.position = position
