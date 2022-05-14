extends Node2D

var activeMap : Node2D		= null

#
func GetMapPath(mapName : String) -> String:
	var mapInstance = Launcher.DB.MapsDB[mapName]
	return Launcher.Path.MapRsc + mapInstance._path

#
func RemoveMap(map : Node2D):
		Launcher.World.call_deferred("remove_child", map)
		map.call_deferred("free")

func LoadMap(mapName : String) -> Node:
	var mapPath : String = GetMapPath(mapName)
	return load(mapPath).instance()

func AddMap(map : Node2D):
	Launcher.World.call_deferred("add_child", map)

#
func RemovePlayerFromMap(player : KinematicBody2D, map : Node2D):
	var fringeLayer : TileMap = map.get_node("Fringe")
	if fringeLayer:
		fringeLayer.call_deferred("remove_child", player)

func AddPlayerToMap(player : KinematicBody2D, map : Node2D, newPos : Vector2):
		var fringeLayer : TileMap = map.get_node("Fringe")
		if fringeLayer:
			var playerPos : Vector2 = newPos * fringeLayer.cell_size + fringeLayer.cell_size / 2
			player.set_position(playerPos)
			fringeLayer.call_deferred("add_child", player)

#
func ApplyMapMetadata(map : Node2D):
	Launcher.Audio.Load(map.get_meta("music") )
var done = false
#
func Warp(_caller : Area2D, mapName : String, mapPos : Vector2):
	var player : KinematicBody2D = Launcher.World.currentPlayer
	if activeMap:
		if player:
			RemovePlayerFromMap(player, activeMap)
		RemoveMap(activeMap)

	activeMap = LoadMap(mapName)

	if activeMap:
		AddMap(activeMap)
		if done == false:
			ApplyMapMetadata(activeMap)
			if player:
				AddPlayerToMap(player, activeMap, mapPos)
				done = true


#register adjacent maps?
#threading?
#change player node to entities node

#func GetMapBoundaries(map):
#	var boundaries = Rect2()
#
#	assert(map, "Map instance is not found, could not generate map boundaries")
#	if map:
#		var collisionLayer	= map.get_node("Collision")
#
#		assert(collisionLayer, "Could not find a collision layer on map: " + map.get_name())
#		if collisionLayer:
#			var mapLimits			= collisionLayer.get_used_rect()
#			var mapCellsize			= collisionLayer.cell_size
#
#			boundaries.position.x	= mapCellsize.x * mapLimits.position.x
#			boundaries.end.x		= mapCellsize.x * mapLimits.end.x
#			boundaries.position.y	= mapCellsize.y * mapLimits.position.y
#			boundaries.end.y		= mapCellsize.y * mapLimits.end.y
#
#	return boundaries
