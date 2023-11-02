extends ServiceBase

@onready var menu : Control						= $UIMargin/VBoxMain/Indicators/Menu
@onready var stats : Control					= $UIMargin/VBoxMain/Indicators/Stat
@onready var notification : Control				= $UIMargin/VBoxMain/Notification
@onready var boxes : Container					= $UIMargin/VBoxMain/ActionBox
@onready var windows : Control					= $FloatingWindows
@onready var background : TextureRect			= $Background

@onready var newsWindow : WindowPanel			= $FloatingWindows/News
@onready var loginWindow : WindowPanel			= $FloatingWindows/Login
@onready var inventoryWindow : WindowPanel		= $FloatingWindows/Inventory
@onready var settingsWindow : WindowPanel		= $FloatingWindows/Settings
@onready var quitWindow : WindowPanel			= $FloatingWindows/Quit
@onready var chatWindow : WindowPanel			= $FloatingWindows/Chat

@onready var chatContainer : ChatContainer		= $FloatingWindows/Chat/VBoxContainer
@onready var emoteContainer : Container			= $FloatingWindows/Emote/ItemContainer/Grid
@onready var buttons : Container				= $UIMargin/VBoxMain/Indicators/Menu/ButtonContent/HBoxButtons

#
func CloseWindow():
	ToggleControl(quitWindow)

func GetCurrentWindow() -> Control:
	if windows && windows.get_child_count() > 0:
		return windows.get_child(windows.get_child_count() - 1)
	return null

func CloseCurrentWindow():
	var control : WindowPanel = GetCurrentWindow()
	if control:
		ToggleControl(control)

func ToggleControl(control : WindowPanel):
	if control:
		control.ToggleControl()

func ToggleChatNewLine():
	if chatWindow:
		if chatWindow.is_visible() == false:
			ToggleControl(chatWindow)
		if chatContainer:
			chatContainer.SetNewLineEnabled(!chatContainer.isNewLineEnabled())

#
func EnterLoginMenu():
	for w in buttons.get_children():
		w.set_visible(false)
		if w.targetWindow:
			w.targetWindow.EnableControl(false)

	stats.set_visible(false)
	notification.set_visible(false)
	menu.set_visible(false)
	boxes.set_visible(false)
	quitWindow.set_visible(false)

	background.set_visible(true)
	newsWindow.EnableControl(true)
	loginWindow.EnableControl(true)

func EnterGame():
	if Launcher.Player:
		inventoryWindow.initialize()
		emoteContainer.FillGridContainer(Launcher.DB.EmotesDB)

		background.set_visible(false)
		loginWindow.EnableControl(false)
		newsWindow.EnableControl(false)

		stats.set_visible(true)
		menu.set_visible(true)
		boxes.set_visible(true)

		for w in buttons.get_children():
			w.set_visible(true)

#
func _post_launch():
	if Launcher.FSM and not Launcher.FSM.enter_login.is_connected(EnterLoginMenu):
		Launcher.FSM.enter_login.connect(EnterLoginMenu)
	if Launcher.FSM and not Launcher.FSM.enter_game.is_connected(EnterGame):
		Launcher.FSM.enter_game.connect(EnterGame)
	get_tree().set_auto_accept_quit(false)

	isInitialized = true

func _notification(notif):
	if notif == Node.NOTIFICATION_WM_CLOSE_REQUEST:
		ToggleControl(quitWindow)
	elif notif == Node.NOTIFICATION_WM_MOUSE_EXIT:
		if has_node("FloatingWindows"):
			get_node("FloatingWindows").ClearWindowsModifier()
