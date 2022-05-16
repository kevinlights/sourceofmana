extends Node

#
const WarpObject			= preload("res://addons/tiled_importer/WarpObject.gd")
var pool : Dictionary		= {}

#
func GetMapPath(mapName : String) -> String:
	var path : String = ""
	var mapInstance = Launcher.DB.MapsDB[mapName]

	if mapInstance:
		path = Launcher.Path.MapRsc + mapInstance._path

	return path

#
func LoadMap(mapName : String) -> Node:
	var mapInstance : Node2D		= GetMap(mapName)
	var mapPath : String			= GetMapPath(mapName)

	if mapInstance == null && Launcher.FileSystem.Exists(mapPath):
		mapInstance = load(mapPath).instance()
		mapInstance.set_name(mapName)
		pool[mapName] = mapInstance

	return mapInstance

#
func GetMap(mapName : String) -> Node2D:
	var mapInstance : Node2D = null 
	if pool.has(mapName):
		mapInstance = pool.get(mapName)
	return mapInstance

func FreeMap(map : String):
	if map:
		if pool.get(map) != null:
			pool[map].queue_free()
			var ret : bool = pool.erase(map)
			assert(ret, "Could not remove map (" + map + ") from the pool")

#
func RefreshPool(currentMap : Node2D):
	var adjacentMaps : Array = []
	if currentMap.get_node("Object"):
		for object in currentMap.get_node("Object").get_children():
			if object is WarpObject:
				adjacentMaps.append(object.destinationMap)

	for mapName in adjacentMaps:
		if pool.has(mapName) == false:
			pool[mapName] = LoadMap(mapName)

	ClearUnused(currentMap, adjacentMaps)

func ClearUnused(currentMap : Node2D, adjacentMaps : Array):
	var mapToFree : Array = []
	for map in pool:
		if adjacentMaps.has(map) == false && map != currentMap.name:
			mapToFree.append(map)
	for map in mapToFree:
		FreeMap(map)
