extends Node

# Generic
func FileExists(path : String) -> bool:
	return FileAccess.file_exists(path)

func ResourceExists(path : String) -> bool:
	return ResourceLoader.exists(path)

func FileLoad(path : String) -> Resource:
	return load(path)

func FileAlloc(path : String) -> Object:
	return FileLoad(path).new()

func ResourceLoad(path : String) -> Object:
	return ResourceLoader.load(path)

func ResourceInstance(path : String) -> Object:
	var resourceLoaded		= ResourceLoad(path)
	var resourceInstance	= null
	if resourceLoaded != null && resourceLoaded.has_method("can_instantiate") && resourceLoaded.can_instantiate():
		resourceInstance = resourceLoaded.instantiate()
	return resourceInstance

# DB
func LoadDB(path : String) -> Dictionary:
	var fullPath : String		= Launcher.Path.DBRsc + path
	var result : Dictionary		= {}

	var pathExists : bool		= FileExists(fullPath)
	Launcher.Util.Assert(pathExists, "DB file not found " + path + " should be located at " + fullPath)

	if pathExists:
		var DBFile : FileAccess = FileAccess.open(fullPath, FileAccess.READ)

		var jsonInstance : JSON = JSON.new()
		var err : int = jsonInstance.parse(DBFile.get_as_text())

		Launcher.Util.Assert(err == OK, "DB parsing issue on file " + fullPath \
			+ " Line: " + str(jsonInstance.get_error_line()) \
			+ " Error: " + jsonInstance.get_error_message() \
		)
		if err == OK:
			result = jsonInstance.get_data()
			Launcher.Util.PrintLog("Loading DB: " + fullPath)

	return result

# Map
func LoadMap(path : String) -> Node2D:
	var mapInstance : Node2D	= null

	var filePath : String		= Launcher.Path.MapRsc + path
	var scenePath : String		= filePath + Launcher.Path.SceneExt
	var mapPath : String		= filePath + Launcher.Path.MapExt
	var usedPath : String		= ""

	if ResourceExists(scenePath):
		usedPath = scenePath
	elif ResourceExists(mapPath):
		usedPath = mapPath
	else:
		Launcher.Util.Assert(true, "Map file not found " + path + "(.tmx/.tscn) should be located at " + Launcher.Path.MapRsc)

	if usedPath != "":
		mapInstance = ResourceInstance(usedPath)
		Launcher.Util.PrintLog("Loading map: " + usedPath)

	return mapInstance

# Source
func LoadSource(path : String) -> Object:
	var fullPath : String		= Launcher.Path.Src + path
	var srcFile : Object		= null

	var pathExists : bool		= ResourceExists(fullPath)
	Launcher.Util.Assert(pathExists, "Source file not found " + path + " should be located at " + fullPath)

	if pathExists:
		srcFile = FileAlloc(fullPath)
		Launcher.Util.PrintLog("Loading Source: " + fullPath)

	return srcFile

# Config
func LoadConfig(path : String) -> ConfigFile:
	var fullPath : String		= Launcher.Path.ConfRsc + path + Launcher.Path.ConfExt
	var localPath : String		= Launcher.Path.ConfLocal + path + Launcher.Path.ConfExt
	var cfgFile : ConfigFile	= null

	var pathExists : bool = false
	if FileExists(localPath):
		pathExists = true
		fullPath = localPath
	else:
		pathExists = FileExists(fullPath)
	Launcher.Util.Assert(pathExists, "Config file not found " + path + " should be located at " + fullPath)

	if pathExists:
		cfgFile = ConfigFile.new()

		var err = cfgFile.load(fullPath)
		Launcher.Util.Assert(err == OK, "Error loading the config file " + path + " located at " + fullPath)

		if err != OK:
			cfgFile.free()
			cfgFile = null
		else:
			Launcher.Util.PrintLog("Loading Config: " + fullPath)

	return cfgFile

func SaveConfig(path : String, cfgFile : ConfigFile):
	var fullPath = Launcher.Path.ConfLocal + path
	Launcher.Util.Assert(cfgFile, "Config file " + path + " not initialized")

	if cfgFile:
		var pathExists : bool = FileExists(fullPath)
		Launcher.Util.Assert(pathExists, "Config file not found " + path + " should be located at " + fullPath)

		if pathExists:
			var err = cfgFile.save(fullPath)
			Launcher.Util.Assert(err == OK, "Error saving the config file " + path + " located at " + fullPath)
			Launcher.Util.PrintLog("Saving Config: " + fullPath)

# Resource
func LoadResource(fullPath : String, instantiate : bool = true) -> Object:
	var rscInstance : Object	= null
	var pathExists : bool		= ResourceExists(fullPath)

	Launcher.Util.Assert(pathExists, "Resource file not found at: " + fullPath)
	if pathExists:
		rscInstance = ResourceInstance(fullPath) if instantiate else ResourceLoad(fullPath)

	return rscInstance

# Scene
func LoadScene(path : String) -> Resource:
	var fullPath : String = Launcher.Path.Scn + path + Launcher.Path.SceneExt
	return LoadResource(fullPath)

# Preset
func LoadPreset(path : String, instantiate : bool = true) -> Object:
	var fullPath : String = Launcher.Path.PresetScn + path + Launcher.Path.SceneExt
	return LoadResource(fullPath, instantiate)

# GUI
func LoadGui(path : String, instantiate : bool = true) -> Object:
	var fullPath : String = Launcher.Path.GuiScn + path + Launcher.Path.SceneExt
	return LoadResource(fullPath, instantiate)

# Music
func LoadMusic(path : String) -> Resource:
	var fullPath : String = Launcher.Path.MusicRsc + path
	var musicFile : Resource			= null

	var pathExists : bool		= ResourceExists(fullPath)
	Launcher.Util.Assert(pathExists, "Music file not found " + path + " should be located at " + fullPath)

	if pathExists:
		musicFile = FileLoad(fullPath)
		Launcher.Util.PrintLog("Loading Music: " + fullPath)

	return musicFile

# Generic texture loading
func LoadGfx(path : String) -> Resource:
	var fullPath : String = Launcher.Path.GfxRsc + path
	return LoadResource(fullPath, false)

# Minimap
func LoadMinimap(path : String) -> Resource:
	var fullPath : String = Launcher.Path.MinimapRsc + path + Launcher.Path.GfxExt
	return LoadResource(fullPath, false)
