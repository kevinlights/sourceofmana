extends WindowPanel

@onready var stayButton : Button	= $Margin/VBoxContainer/ButtonChoice/Stay
@onready var logOutButton : Button	= $Margin/VBoxContainer/ButtonChoice/LogOut
@onready var quitButton : Button	= $Margin/VBoxContainer/ButtonChoice/Quit

#
func EnableControl(state : bool):
	super(state)

	if state == true:
		logOutButton.visible = Launcher.Player != null

		stayButton.grab_focus()

#
func _on_logout_pressed():
	if Launcher.Player:
		Launcher.FSM.EnterState(Launcher.FSM.States.LOGIN_CONNECTION)
		EnableControl(false)
	else:
		Launcher.FSM.EnterState(Launcher.FSM.States.QUIT)
		ToggleControl()

func _on_quit_pressed():
	Launcher.FSM.EnterState(Launcher.FSM.States.QUIT)
	ToggleControl()

func _on_stay_pressed():
	ToggleControl()

func _on_window_draw():
	if quitButton:
		quitButton.grab_focus()
