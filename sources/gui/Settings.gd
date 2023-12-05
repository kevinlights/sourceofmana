extends WindowPanel

var platformSection : String					= OS.get_name()
const defaultSection : String					= "Default"
const userSection : String						= "User"

@onready var accessors : Array						= [
	{
		"Render-MinWindowSize": [init_minwinsize, set_minwinsize, apply_minwinsize, null],
		"Render-Fullscreen": [init_fullscreen, set_fullscreen, apply_fullscreen, $VBoxContainer/Offset/TabBar/Render/RenderVBox/VisualVBox/Fullscreen],
		"Render-Scaling": [init_scaling, set_scaling, apply_scaling, $VBoxContainer/Offset/TabBar/Render/RenderVBox/VisualVBox/Scaling/Option],
		"Render-WindowResolution": [init_resolution, set_resolution, apply_resolution, $VBoxContainer/Offset/TabBar/Render/RenderVBox/VisualVBox/WindowResolution/Option],
		"Render-HQ4x": [init_hq4x, set_hq4x, apply_hq4x, null],
		"Render-CRT": [init_crt, set_crt, apply_crt, null],
	}
]

enum CATEGORY { RENDER, SOUND, COUNT }
enum ACC_TYPE { INIT, SET, APPLY, LABEL }

# MinWindowSize
func init_minwinsize(apply : bool):
	if apply:
		var minSize : Vector2 = GetVal("Render-MinWindowSize")
		apply_minwinsize(minSize)
func set_minwinsize(minSize : Vector2):
	SetVal("Render-MinWindowSize", minSize)
	apply_minwinsize(minSize)
func apply_minwinsize(minSize : Vector2):
	if DisplayServer.get_window_list().size() > 0:
		DisplayServer.window_set_min_size(minSize, DisplayServer.get_window_list()[0])

# FullScreen
func init_fullscreen(apply : bool):
	var pressed : bool = GetVal("Render-Fullscreen")
	accessors[CATEGORY.RENDER]["Render-Fullscreen"][ACC_TYPE.LABEL].set_pressed_no_signal(pressed)
	if apply:
		apply_fullscreen(pressed)
func set_fullscreen(pressed : bool):
	SetVal("Render-Fullscreen", pressed)
	apply_fullscreen(pressed)
func apply_fullscreen(pressed : bool):
	if pressed:
		clear_resolution_labels()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		populate_resolution_labels()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# WindowResolution
func init_resolution(apply : bool):
	clear_resolution_labels()
	if DisplayServer.get_window_list().size() > 0 and DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		populate_resolution_labels()
	if apply:
		var resolutionIndex : int = GetVal("Render-WindowResolution")
		apply_resolution(resolutionIndex)
func clear_resolution_labels():
	accessors[CATEGORY.RENDER]["Render-WindowResolution"][ACC_TYPE.LABEL].clear()
func populate_resolution_labels():
	var resolutionIndex : int = GetVal("Render-WindowResolution")
	var minScreenSize : Vector2 = GetVal("Render-MinWindowSize")
	var maxScreenSize : Vector2 = DisplayServer.screen_get_size()
	for i in range(0, 11):
		var item : Vector2i = calculate_resolution_item(i, minScreenSize, maxScreenSize)
		accessors[CATEGORY.RENDER]["Render-WindowResolution"][ACC_TYPE.LABEL].add_item(str(item))
	accessors[CATEGORY.RENDER]["Render-WindowResolution"][ACC_TYPE.LABEL].selected = resolutionIndex
func calculate_resolution_item(index : int, minScreenSize : Vector2, maxScreenSize : Vector2) -> Vector2i:
	return index * 10.0 / 100.0 * (maxScreenSize - minScreenSize) + minScreenSize
func set_resolution(resolutionIndex : int):
	SetVal("Render-WindowResolution", resolutionIndex)
	apply_resolution(resolutionIndex)
func apply_resolution(resolutionIndex : int):
	var minScreenSize : Vector2 = GetVal("Render-MinWindowSize")
	var maxScreenSize : Vector2 = DisplayServer.screen_get_size()
	var newWindowSize : Vector2 = calculate_resolution_item(resolutionIndex, minScreenSize, maxScreenSize)
	var newPosition : Vector2 = clamp((maxScreenSize - newWindowSize) / 2.0, Vector2.ZERO, maxScreenSize)
	get_viewport().set_size(newWindowSize)
	get_viewport().set_position(newPosition)

# DoubleResolution
func init_scaling(apply : bool):
	var mode : int = GetVal("Render-Scaling")
	accessors[CATEGORY.RENDER]["Render-Scaling"][ACC_TYPE.LABEL].selected = mode
	if apply:
		apply_scaling(mode)
func set_scaling(mode : int):
	SetVal("Render-Scaling", mode)
	apply_scaling(mode)
func apply_scaling(mode : int):
	Launcher.Root.set_content_scale_factor(mode + 1)

# HQ4x
func init_hq4x(apply : bool):
	if apply:
		apply_hq4x(GetVal("Render-HQ4x"))
func set_hq4x(enable : bool):
	SetVal("Render-HQ4x", enable)
	apply_hq4x(enable)
func apply_hq4x(enable : bool):
	Launcher.GUI.HQ4xShader.set_visible(enable)

# CRT
func init_crt(apply : bool):
	if apply:
		apply_crt(GetVal("Render-CRT"))
func set_crt(enable : bool):
	SetVal("Render-CRT", enable)
	apply_crt(enable)
func apply_crt(enable : bool):
	Launcher.GUI.CRTShader.set_visible(enable)

#
func _on_visibility_changed():
	if Launcher.Action:
		Launcher.Action.Enable(not visible)
	RefreshSettings(false)

func _ready():
	RefreshSettings(true)

func _exit_tree():
	SaveSettings()

# Conf accessors
func RefreshSettings(apply : bool):
	for category in accessors:
		for option in category:
			category[option][ACC_TYPE.INIT].call_deferred(apply)

func SaveSettings():
	Launcher.Conf.SaveType("settings", Launcher.Conf.Type.USERSETTINGS)

func SetVal(key : String, value):
	Launcher.Conf.SetValue(userSection, key, Launcher.Conf.Type.USERSETTINGS, value)

func GetVal(key : String):
	var value = Launcher.Conf.GetVariant(userSection, key, Launcher.Conf.Type.USERSETTINGS, null)
	if value == null:
		value = Launcher.Conf.GetVariant(platformSection, key, Launcher.Conf.Type.SETTINGS, null)
	if value == null:
		value = Launcher.Conf.GetVariant(defaultSection, key, Launcher.Conf.Type.SETTINGS, null)

	return value
