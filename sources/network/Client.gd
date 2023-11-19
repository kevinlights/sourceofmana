extends Node

#
func WarpPlayer(map : String, _rpcID : int = Launcher.Network.RidSingleMode):
	if Launcher.Map:
		Launcher.Map.call_deferred("EmplaceMapNode", map)
		PushNotification(map, _rpcID)

	if Launcher.Player:
		Launcher.Player.entityVelocity = Vector2.ZERO

func EmotePlayer(playerID : int, emoteID : int, _rpcID : int = Launcher.Network.RidSingleMode):
	if Launcher.Map:
		Launcher.Map.EmotePlayer(playerID, emoteID)

func AddEntity(agentID : int, entityType : String, entityID : String, entityName : String, entityPos : Vector2i, agentState : EntityCommons.State, _rpcID : int = Launcher.Network.RidSingleMode):
	if Launcher.Map:
		Launcher.Map.call_deferred("AddEntity", agentID, entityType, entityID, entityName, entityPos, agentState)

func RemoveEntity(agentID : int, _rpcID : int = Launcher.Network.RidSingleMode):
	if Launcher.Map:
		Launcher.Map.RemoveEntity(agentID)

func ForceUpdateEntity(ridAgent : int, velocity : Vector2, position : Vector2, agentState : EntityCommons.State):
	UpdateEntity(ridAgent, velocity, position, agentState)

func UpdateEntity(ridAgent : int, velocity : Vector2, position : Vector2, agentState : EntityCommons.State):
	if Launcher.Map:
		Launcher.Map.UpdateEntity(ridAgent, velocity, position, agentState)

func ChatAgent(ridAgent : int, text : String, _rpcID : int = Launcher.Network.RidSingleMode):
	if Launcher.Map:
		var entity : BaseEntity = Launcher.Map.entities.get(ridAgent)
		if entity && entity.get_parent():
			if entity is PlayerEntity && Launcher.GUI:
				Launcher.GUI.chatContainer.AddPlayerText(entity.entityName, text)
			if entity.interactive:
				entity.interactive.call_deferred("DisplaySpeech", text)

func DamageDealt(ridAgent : int, targetID : int, damage : int, _rpcID : int = Launcher.Network.RidSingleMode):
	if Launcher.Map:
		var entity : BaseEntity = Launcher.Map.entities.get(targetID)
		var caller : BaseEntity = Launcher.Map.entities.get(ridAgent)
		if caller && entity && entity.get_parent() and entity.interactive:
			entity.interactive.call_deferred("DisplayDamage", entity, caller, damage, false)

func Morphed(ridAgent : int, morphID : String, _rpcID : int = Launcher.Network.RidSingleMode):
	if Launcher.Map:
		var entity : BaseEntity = Launcher.Map.entities.get(ridAgent)
		if entity:
			var morphData : EntityData = Instantiate.FindEntityReference(morphID)
			entity.SetVisual(morphData)

func UpdatePlayerVars(level : int, experience : float, _rpcID : int = Launcher.Network.RidSingleMode):
	if Launcher.Player:
		Launcher.Player.stat.level			= level
		Launcher.Player.stat.experience		= experience

func UpdateActiveStats(health : int, mana : int, stamina : int, weight : float, morphed : bool, _rpcID : int = Launcher.Network.RidSingleMode):
	if Launcher.Player:
		Launcher.Player.stat.health			= health
		Launcher.Player.stat.mana			= mana
		Launcher.Player.stat.stamina		= stamina
		Launcher.Player.stat.weight			= weight
		Launcher.Player.stat.morphed		= morphed

func UpdatePersonalStats(strength : int, vitality : int, agility : int, endurance : int, concentration : int, _rpcID : int = Launcher.Network.RidSingleMode):
	if Launcher.Player:
		Launcher.Player.stat.strength		= strength
		Launcher.Player.stat.vitality		= vitality
		Launcher.Player.stat.agility		= agility
		Launcher.Player.stat.endurance		= endurance
		Launcher.Player.stat.concentration	= concentration

func PushNotification(notif : String, _rpcID : int = Launcher.Network.RidSingleMode):
	if Launcher.GUI:
		Launcher.GUI.notificationLabel.AddNotification(notif)

func DisconnectPlayer():
	if Launcher.Map:
		Launcher.Map.UnloadMapNode()
	if Launcher.Player:
		Launcher.Player = null
