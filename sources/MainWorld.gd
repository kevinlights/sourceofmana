extends Node2D

onready var currentMap		= null
onready var currentPlayer	= load("res://scenes/presets/PC.tscn").instance()

# Debug
func SetDefaultPlayerPosition():
	var defaultMap = "res://maps/phatina/002-3-1.tmx"
	var defaultPosition = Vector2(70, 40)
	SetPlayerInWorld(defaultMap, defaultPosition)

# Utils	
func SetCameraBoundaries(map, player):
	if map && player:
		var playerCamera	= player.get_node("PlayerCamera")
		var collisionLayer	= map.get_node("Collision")

		assert(playerCamera, "Player camera not found")
		assert(collisionLayer, "Could not find a collision layer on map: " + currentMap.get_name())

		if collisionLayer && playerCamera:
			var mapLimits		= collisionLayer.get_used_rect()
			var mapCellsize		= collisionLayer.cell_size

			playerCamera.limit_left		= mapLimits.position.x * mapCellsize.x
			playerCamera.limit_right	= mapLimits.end.x * mapCellsize.x
			playerCamera.limit_top		= mapLimits.position.y * mapCellsize.y
			playerCamera.limit_bottom	= mapLimits.end.y * mapCellsize.y

func SetPlayerInWorld(map, pos):
	currentMap = load(map).instance()
	if currentPlayer && currentMap:
		var fringeSort = currentMap.get_node("Fringe")
		if fringeSort:
			currentPlayer.set_position(pos * fringeSort.cell_size)
			fringeSort.add_child(currentPlayer)
			add_child(currentMap)

# Network
func ReturnInventoryList(s_inventoryList):
	print(s_inventoryList)

#
func _ready():
	if currentMap == null:
		SetDefaultPlayerPosition()
	SetCameraBoundaries(currentMap, currentPlayer)

func _process(_delta):
	if Input.is_action_just_pressed("ui_inventory"):
		Server.FetchInventoryList("All", get_instance_id())
