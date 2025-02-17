class_name WorldMap
extends Object

#
var name : String						= ""
var instances : Array[WorldInstance]	= []
var spawns : Array[SpawnObject]			= []
var warps : Array[WarpObject]			= []
var navPoly : NavigationPolygon			= null
var mapRID : RID						= RID()
var regionRID : RID						= RID()
var spiritOnly : bool					= false

#
static func Create(mapName : String) -> WorldMap:
	var map : WorldMap = WorldMap.new()
	map.name = mapName
	map.LoadMapData()
	WorldNavigation.LoadData(map)
	map.instances.append(WorldInstance.Create(map))

	return map

func LoadMapData():
	var node : Node = Instantiate.LoadMapData(name, Path.MapServerExt)
	if node:
		if "spirit_only" in node:
			spiritOnly = node.spirit_only
		if "spawns" in node:
			for spawn in node.spawns:
				Util.Assert(spawn != null, "Warp format is not supported")
				if spawn:
					var spawnObject = SpawnObject.new()
					spawnObject.count = spawn[0]
					spawnObject.name = spawn[1]
					spawnObject.type = spawn[2]
					spawnObject.spawn_position = spawn[3]
					spawnObject.spawn_offset = spawn[4]
					spawnObject.respawn_delay = spawn[5]
					spawnObject.is_global = spawnObject.spawn_position < Vector2i.LEFT
					spawnObject.is_persistant = true
					spawnObject.map = self
					spawns.append(spawnObject)
		if "warps" in node:
			for warp in node.warps:
				Util.Assert(warp != null, "Warp format is not supported")
				if warp:
					var warpObject = WarpObject.new()
					warpObject.destinationMap = warp[0]
					warpObject.destinationPos = warp[1]
					warpObject.polygon = warp[2]
					if warp.size() > 3:
						warpObject.autoWarp = warp[3]
					warps.append(warpObject)
