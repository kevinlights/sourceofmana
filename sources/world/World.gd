extends Node2D

# Types
class Instance extends SubViewport:
	var id : int							= 0
	var npcs : Array[BaseAgent]				= []
	var mobs : Array[BaseAgent]				= []
	var players : Array[BaseAgent]			= []

class Map:
	var name : String						= ""
	var instances : Array[Instance]			= []
	var spawns : Array[SpawnObject]			= []
	var warps : Array[WarpObject]			= []
	var nav_poly : NavigationPolygon		= null
	var mapRID : RID						= RID()
	var regionRID : RID						= RID()

# Vars
var areas : Dictionary = {}
var rids : Dictionary = {}

# Utils
func GetRandomPosition(map : Map) -> Vector2i:
	Launcher.Util.Assert(map != null && map.nav_poly != null && map.nav_poly.get_polygon_count() > 0, "No triangulation available")
	if map != null && map.nav_poly != null && map.nav_poly.get_polygon_count() > 0:
		var outlinesList : PackedVector2Array  = map.nav_poly.get_vertices()

		var randPolygonID : int = randi_range(0, map.nav_poly.get_polygon_count() - 1)
		var randPolygon : PackedInt32Array = map.nav_poly.get_polygon(randPolygonID)

		var randVerticeID : int = randi_range(0, randPolygon.size() - 1)
		var a : Vector2 = outlinesList[randPolygon[randVerticeID]]
		var b : Vector2 = outlinesList[randPolygon[(randVerticeID + 1) % randPolygon.size()]]
		var c : Vector2 = outlinesList[randPolygon[(randVerticeID + 2) % randPolygon.size()]]

		return Vector2i(a + sqrt(randf()) * (-a + b + randf() * (c - b)))

	Launcher.Util.Assert(false, "Mob could not be spawned, no available point on the navigation mesh were found")
	return Vector2i.ZERO

func GetRandomPositionAABB(map : Map, pos : Vector2i, offset : Vector2i) -> Vector2i:
	Launcher.Util.Assert(map != null, "Could not create a random position for a non-initialized map")
	if map != null:
		for i in Launcher.Conf.GetInt("Navigation", "navigationSpawnTry", Launcher.Conf.Type.SERVER):
			var randPoint : Vector2i = Vector2i(randi_range(-offset.x, offset.x), randi_range(-offset.y, offset.y))
			randPoint += pos

			var closestPoint : Vector2i = NavigationServer2D.map_get_closest_point(map.mapRID, randPoint)
			if randPoint == closestPoint:
				return randPoint

	return GetRandomPosition(map)

# Instance init
func LoadMapData(mapName : String, ext : String) -> Object:
	var mapPath : String			= Launcher.DB.GetMapPath(mapName)
	var mapInstance : Object		= Launcher.FileSystem.LoadMap(mapPath, ext)

	return mapInstance

func LoadGenericData(map : Map):
	var node : Node = LoadMapData(map.name, Launcher.Path.MapServerExt)
	if node:
		if "spawns" in node:
			for spawn in node.spawns:
				Launcher.Util.Assert(spawn != null, "Warp format is not supported")
				if spawn:
					var spawnObject = SpawnObject.new()
					spawnObject.count = spawn[0]
					spawnObject.name = spawn[1]
					spawnObject.type = spawn[2]
					spawnObject.spawn_position = spawn[3]
					spawnObject.spawn_offset = spawn[4]
					spawnObject.is_global = spawnObject.spawn_position < Vector2i.LEFT
					map.spawns.append(spawnObject)
		if "warps" in node:
			for warp in node.warps:
				Launcher.Util.Assert(warp != null, "Warp format is not supported")
				if warp:
					var warpObject = WarpObject.new()
					warpObject.destinationMap = warp[0]
					warpObject.destinationPos = warp[1]
					warpObject.polygon = warp[2]
					map.warps.append(warpObject)

func LoadNavigationData(map : Map):
	var obj : Object = LoadMapData(map.name, Launcher.Path.MapNavigationExt)
	if obj:
		map.nav_poly = obj

func CreateNavigation(map : Map, mapRID : RID):
	if map.nav_poly:
		map.mapRID = mapRID if mapRID.is_valid() else NavigationServer2D.map_create()
		NavigationServer2D.map_set_active(map.mapRID, true)
		NavigationServer2D.map_set_cell_size(map.mapRID, 0.1)

		map.regionRID = NavigationServer2D.region_create()
		NavigationServer2D.region_set_map(map.regionRID, map.mapRID)
		NavigationServer2D.region_set_navigation_polygon(map.regionRID, map.nav_poly)

		NavigationServer2D.map_force_update(map.mapRID)

func CreateInstance(map : Map, instanceID : int = 0):
	var inst : Instance = Instance.new()
	CreateNavigation(map, inst.get_world_2d().get_navigation_map())

	inst.disable_3d = true
	inst.gui_disable_input = true
	inst.name = map.name
	inst.id = instanceID
	if inst.id > 0:
		inst.name += "_" + str(inst.id)
	map.instances.push_back(inst)

	for spawn in map.spawns:
		for i in spawn.count:
			var agent : BaseAgent = Launcher.DB.Instantiate.CreateAgent(spawn.type, spawn.name)

			Launcher.Util.Assert(agent != null, "Agent %s (type: %s) could not be created" % [spawn.name, spawn.type])
			if agent:
				var pos : Vector2 = Vector2.ZERO

				if spawn.is_global:
					pos = GetRandomPosition(map)
				else:
					pos = GetRandomPositionAABB(map, spawn.spawn_position, spawn.spawn_offset)
				Launcher.Util.Assert(pos != Vector2.ZERO, "Could not spawn the agent %s, no walkable position found" % spawn.name)
				if pos == Vector2.ZERO:
					agent.queue_free()
					continue

				rids[agent.get_rid().get_id()] = agent
				Spawn(map, pos, agent, instanceID)

	Launcher.Root.call_deferred("add_child", inst)

# Agent Management
func Warp(agent : BaseAgent, oldMap : Map, newMap : Map, newPos : Vector2i):
	Launcher.Util.Assert(oldMap and newMap and agent, "Warp could not proceed, agent or current map missing")
	if agent and oldMap:
		for instance in oldMap.instances:
			var arrayRef : Array = []
			match agent.agentType:
				"Player":	arrayRef = instance.players
				"Npc":		arrayRef = instance.npcs
				"Monster":	arrayRef = instance.mobs
				"Trigger":	arrayRef = instance.npcs
				_: Launcher.Util.Assert(false, "Agent type is not valid")

			var arrayIdx : int = arrayRef.find(agent)
			if arrayIdx >= 0:
				arrayRef.remove_at(arrayIdx)

			instance.remove_child(agent)
			for player in instance.players:
				if player != agent:
					var playerID = Launcher.Network.Server.playerMap.find_key(player.get_rid().get_id())
					if playerID != null:
						Launcher.Network.RemoveEntity(agent.get_rid().get_id(), playerID)

			Spawn(newMap, newPos, agent)

func Spawn(map : Map, pos : Vector2, agent : BaseAgent, instanceID : int = 0):
	Launcher.Util.Assert(map and instanceID < map.instances.size() and agent, "Spawn could not proceed, agent or map missing")
	if map and instanceID < map.instances.size() and agent:
		var inst : Instance = map.instances[instanceID]
		Launcher.Util.Assert(inst != null, "Spawn could not proceed, map instance missing")
		if inst:
			agent.set_position(pos)
			agent.ResetNav()
			if agent.agent:
				agent.agent.set_navigation_map(map.mapRID)

			match agent.agentType:
				"Player":	if not agent in inst.players:	inst.players.append(agent)
				"Npc":		if not agent in inst.npcs:		inst.npcs.append(agent)
				"Monster":	if not agent in inst.mobs:		inst.mobs.append(agent)
				"Trigger":	if not agent in inst.npcs:		inst.npcs.append(agent)
				_: Launcher.Util.Assert(false, "Agent type is not valid")

			inst.call_deferred("add_child", agent)

			for player in inst.players:
				if player != agent:
					var playerID = Launcher.Network.Server.playerMap.find_key(player.get_rid().get_id())
					if playerID != null:
						Launcher.Network.AddEntity(agent.get_rid().get_id(), agent.agentType, agent.agentID, agent.agentName, agent.position, playerID)

func GetInstanceFromAgent(checkedAgent : BaseAgent, checkPlayers = true, checkNpcs = true, checkMonsters = true) -> Instance:
	for map in areas.values():
		for instance in map.instances:
			if checkPlayers:
				for agent in instance.players:
					if agent == checkedAgent:
						return instance
			if checkNpcs:
				for agent in instance.npcs:
					if agent == checkedAgent:
						return instance
			if checkMonsters:
				for agent in instance.mobs:
					if agent == checkedAgent:
						return instance
	return null

func GetMapFromAgent(checkedAgent : BaseAgent, checkPlayers = true, checkNpcs = true, checkMonsters = true) -> Map:
	for map in areas.values():
		for instance in map.instances:
			if checkPlayers:
				for agent in instance.players:
					if agent == checkedAgent:
						return map
			if checkNpcs:
				for agent in instance.npcs:
					if agent == checkedAgent:
						return map
			if checkMonsters:
				for agent in instance.mobs:
					if agent == checkedAgent:
						return map
	return null

func GetAgents(checkedAgent : BaseAgent):
	var list : Array[BaseAgent] = []
	var instance : Instance = GetInstanceFromAgent(checkedAgent)
	if instance:
		list.append_array(instance.npcs)
		list.append_array(instance.mobs)
		list.append_array(instance.players)
	return list

func HasAgent(agentName : String, checkPlayers = true, checkNpcs = true, checkMonsters = true):
	for map in areas.values():
		for instance in map.instances:
			if checkPlayers:
				for agent in \
				instance.players if checkPlayers else [] + \
				instance.npcs if checkNpcs else [] + \
				instance.mobs if checkMonsters else []:
					if agent.agentName == agentName:
						return true
	return false

func RemoveAgent(agentName : String, checkPlayers = true, checkNpcs = true, checkMonsters = true):
	for map in areas.values():
		for instance in map.instances:
			if checkPlayers:
				for agent in instance.players:
					if agent.agentName == agentName:
						instance.players.erase(agent)
			if checkNpcs:
				for agent in instance.npcs:
					if agent.agentName == agentName:
						instance.npcs.erase(agent)
			if checkMonsters:
				for agent in instance.mobs:
					if agent.agentName == agentName:
						instance.mobs.erase(agent)

# AI
func UpdateWalkPaths(agent : Node2D, map : Map):
	var randAABB : Vector2i = Vector2i(randi_range(30, 200), randi_range(30, 200))
	var newPos : Vector2i = GetRandomPositionAABB(map, agent.position, randAABB)
	agent.WalkToward(newPos)

func UpdateAI(agent : BaseAgent, map : Map):
	if agent.hasCurrentGoal == false && agent.aiTimer && agent.aiTimer.is_stopped():
		agent.aiTimer.StartTimer(randf_range(5, 15), UpdateWalkPaths.bind(agent, map))
	elif agent.hasCurrentGoal && agent.IsStuck():
		agent.ResetNav()
		agent.aiTimer.StartTimer(randf_range(2, 10), UpdateWalkPaths.bind(agent, map))
	agent.UpdateInput()

# Generic
func _post_launch():
	for mapName in Launcher.DB.MapsDB:
		var map : Map = Map.new()
		map.name = mapName
		LoadGenericData(map)
		LoadNavigationData(map)
		CreateInstance(map)
		areas[mapName] = map

func _process(_dt : float):
	for map in areas.values():
		for instance in map.instances:
			if Launcher.Debug or instance.players.size() > 0:
				for agent in instance.npcs + instance.mobs:
					UpdateAI(agent, map)
				for player in instance.players:
					var playerID : int = Launcher.Network.Server.playerMap.find_key(player.get_rid().get_id())
					for agent in instance.npcs + instance.mobs + instance.players:
						Launcher.Network.UpdateEntity(agent.get_rid().get_id(), agent.currentVelocity, agent.position, agent.isSitting, playerID)
