extends Node
class_name WorldNavigation

# Instance init
static func LoadData(map : WorldService.Map):
	var obj : Object = Instantiate.LoadMapData(map.name, Path.MapNavigationExt)
	if obj:
		map.nav_poly = obj
		map.nav_poly.cell_size = 0.1

static func CreateInstance(map : WorldService.Map, mapRID : RID):
	if map.nav_poly:
		map.mapRID = mapRID if mapRID.is_valid() else NavigationServer2D.map_create()
		NavigationServer2D.map_set_active(map.mapRID, true)
		NavigationServer2D.map_set_cell_size(map.mapRID, map.nav_poly.cell_size)

		map.regionRID = NavigationServer2D.region_create()
		NavigationServer2D.region_set_map(map.regionRID, map.mapRID)
		NavigationServer2D.region_set_navigation_polygon(map.regionRID, map.nav_poly)

		NavigationServer2D.map_force_update(map.mapRID)

# Getter
static func GetPathLength(agent : BaseAgent, pos : Vector2) -> float :
	var path : PackedVector2Array = NavigationServer2D.map_get_path(agent.agent.get_navigation_map(), agent.position, pos, true)
	var pathLength : float = 0.0
	for i in range(0, path.size() - 1):
		pathLength += Vector2(path[i] - path[i+1]).length()
	return pathLength

# Utils
static func GetRandomPosition(map : WorldService.Map) -> Vector2i:
	Util.Assert(map != null && map.nav_poly != null && map.nav_poly.get_polygon_count() > 0, "No triangulation available")
	if map != null && map.nav_poly != null && map.nav_poly.get_polygon_count() > 0:
		var outlinesList : PackedVector2Array  = map.nav_poly.get_vertices()

		var randPolygonID : int = randi_range(0, map.nav_poly.get_polygon_count() - 1)
		var randPolygon : PackedInt32Array = map.nav_poly.get_polygon(randPolygonID)

		var randVerticeID : int = randi_range(0, randPolygon.size() - 1)
		var a : Vector2 = outlinesList[randPolygon[randVerticeID]]
		var b : Vector2 = outlinesList[randPolygon[(randVerticeID + 1) % randPolygon.size()]]
		var c : Vector2 = outlinesList[randPolygon[(randVerticeID + 2) % randPolygon.size()]]

		return Vector2i(a + sqrt(randf()) * (-a + b + randf() * (c - b)))

	Util.Assert(false, "Mob could not be spawned, no available point on the navigation mesh were found")
	return Vector2i.ZERO

static func GetRandomPositionAABB(map : WorldService.Map, pos : Vector2i, offset : Vector2i) -> Vector2i:
	Util.Assert(map != null, "Could not create a random position for a non-initialized map")
	if map != null:
		for i in Launcher.Conf.GetInt("Navigation", "navigationSpawnTry", Launcher.Conf.Type.NETWORK):
			var randPoint : Vector2i = Vector2i(randi_range(-offset.x, offset.x), randi_range(-offset.y, offset.y))
			randPoint += pos

			var closestPoint : Vector2i = NavigationServer2D.map_get_closest_point(map.mapRID, randPoint)
			if randPoint == closestPoint:
				return randPoint

	return GetRandomPosition(map)

static func GetSpawnPosition(map : WorldService.Map, spawn : SpawnObject) -> Vector2i:
	var position : Vector2i = Vector2i.ZERO
	if not spawn.is_global:
		position = WorldNavigation.GetRandomPositionAABB(map, spawn.spawn_position, spawn.spawn_offset)
	if position == Vector2i.ZERO:
		position = WorldNavigation.GetRandomPosition(map)

	Util.Assert(position != Vector2i.ZERO, "Could not spawn the agent %s, no walkable position found" % spawn.name)
	return position
