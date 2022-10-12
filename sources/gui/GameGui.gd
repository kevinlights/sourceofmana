extends Node

@onready var weightStat : Control				= $FloatingWindows/Inventory/VBoxContainer/Weight/BgTex/Weight
@onready var itemInventory : GridContainer		= $FloatingWindows/Inventory/VBoxContainer/ItemContainer/Grid
@onready var emoteList : GridContainer			= $FloatingWindows/Emote/ItemContainer/Grid
@onready var chatContainer : Container			= $FloatingWindows/Chat/VBoxContainer

#
func ToggleControl(control : Control):
	if control:
		control.set_visible(!control.is_visible())
		control.SetFloatingWindowToTop()

func ToggleChatNewLine(control : Control):
	if control:
		if control.is_visible() == false:
			ToggleControl(control)
		if chatContainer:
			chatContainer.SetNewLineEnabled(!chatContainer.isNewLineEnabled())

func UpdatePlayerInfo():
	if Launcher.Entities.activePlayer:
		assert(weightStat, "Stat inventory weight bar is missing")
		if weightStat:
			weightStat.SetStat(Launcher.Entities.activePlayer.stat.weight, Launcher.Entities.activePlayer.stat.maxWeight)

#
func _ready():
	get_tree().set_auto_accept_quit(false)

	if Launcher.Entities.activePlayer:
		assert(itemInventory, "Item inventory container is missing")
		if itemInventory:
			itemInventory.FillGridContainer(Launcher.Entities.activePlayer.inventory.items)

	assert(emoteList, "Emote grid container is missing")
	if emoteList:
		emoteList.FillGridContainer(Launcher.DB.EmotesDB)

func _process(_delta):
	UpdatePlayerInfo()

	if Input.is_action_just_pressed(Actions.ACTION_UI_QUIT_GAME): ToggleControl($FloatingWindows/Quit)
	if Input.is_action_just_pressed(Actions.ACTION_UI_INVENTORY): ToggleControl($FloatingWindows/Inventory)
	if Input.is_action_just_pressed(Actions.ACTION_UI_MINIMAP): ToggleControl($FloatingWindows/Minimap)
	if Input.is_action_just_pressed(Actions.ACTION_UI_CHAT): ToggleControl($FloatingWindows/Chat)
	if Input.is_action_just_pressed(Actions.ACTION_UI_CHAT_NEWLINE) : ToggleChatNewLine($FloatingWindows/Chat)

func _notification(notif):
	if notif == Node.NOTIFICATION_WM_CLOSE_REQUEST:
		ToggleControl($FloatingWindows/Quit)
	elif notif == Node.NOTIFICATION_WM_MOUSE_EXIT:
		if has_node("FloatingWindows"):
			get_node("FloatingWindows").ClearWindowsModifier()
