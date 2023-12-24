extends Node
class_name FileSystem

# Generic
static func FileExists(path : String) -> bool:
	return FileAccess.file_exists(path)

static func ResourceExists(path : String) -> bool:
	return ResourceLoader.exists(path)

static func FileLoad(path : String) -> Resource:
	return load(path)

static func FileAlloc(path : String) -> Object:
	return FileLoad(path).new()

static func CanInstantiateResource(res : Object) -> bool:
	return res.has_method("can_instantiate") && res.can_instantiate()

static func ResourceLoad(path : String) -> Object:
	return ResourceLoader.load(path)

static func ResourceInstance(path : String) -> Object:
	var resourceLoaded : Object		= ResourceLoad(path)
	var resourceInstance : Object	= null
	if resourceLoaded != null && CanInstantiateResource(resourceLoaded):
		resourceInstance = resourceLoaded.instantiate()
	return resourceInstance

static func ResourceInstanceOrLoad(path : String) -> Object:
	var resourceLoaded : Object		= ResourceLoad(path)
	var resource : Object			= null
	if resourceLoaded != null:
		if CanInstantiateResource(resourceLoaded):
			resource = resourceLoaded.instantiate()
		else:
			resource = resourceLoaded
	return resource

# File
static func LoadFile(path : String) -> String:
	var fullPath : String		= Path.DataRsc + path
	var content : String		= ""

	var pathExists : bool		= FileExists(fullPath)
	Util.Assert(pathExists, "Content file not found " + path + " should be located at " + fullPath)

	if pathExists:
		var file : FileAccess = FileAccess.open(fullPath, FileAccess.READ)
		Util.Assert(file != null, "File parsing issue on file " + fullPath)
		if file:
			content = file.get_as_text()
			Util.PrintLog("File", "Loading file: " + fullPath)
			file.close()
	return content

static func SaveFile(fullPath : String, content : String):
	var file : FileAccess		= FileAccess.open(fullPath, FileAccess.WRITE)
	Util.Assert(file != null, "File parsing issue on file " + fullPath)
	if file:
		file.store_string(content)
		file.close()
		Util.PrintInfo("FileSystem", "Saving file %s" % fullPath)

# DB
static func LoadDB(path : String) -> Dictionary:
	var fullPath : String		= Path.DBRsc + path
	var result : Dictionary		= {}

	var pathExists : bool		= FileExists(fullPath)
	Util.Assert(pathExists, "DB file not found " + path + " should be located at " + fullPath)

	if pathExists:
		var DBFile : FileAccess = FileAccess.open(fullPath, FileAccess.READ)

		var jsonInstance : JSON = JSON.new()
		var err : int = jsonInstance.parse(DBFile.get_as_text())

		Util.Assert(err == OK, "DB parsing issue on file " + fullPath \
			+ " Line: " + str(jsonInstance.get_error_line()) \
			+ " Error: " + jsonInstance.get_error_message() \
		)
		if err == OK:
			result = jsonInstance.get_data()
			Util.PrintLog("DB", "Loading file: " + fullPath)

	return result

# Map
static func LoadMap(path : String, ext : String) -> Object:
	var mapInstance : Object	= null

	var filePath : String		= Path.MapRsc + path
	var scenePath : String		= filePath + ext
	var pathExists : bool		= ResourceExists(scenePath)

	Util.Assert(pathExists, "Map file not found " + path + Path.MapClientExt + " should be located at " + Path.MapRsc)
	if pathExists:
		mapInstance = ResourceInstanceOrLoad(scenePath)
		Util.PrintLog("Map", "Loading resource: " + scenePath)

	return mapInstance

# Source
static func LoadSource(path : String, alloc : bool = true) -> Object:
	var fullPath : String		= Path.Src + path
	var srcFile : Object		= null

	var pathExists : bool		= ResourceExists(fullPath)
	Util.Assert(pathExists, "Source file not found " + path + " should be located at " + fullPath)

	if pathExists:
		srcFile = FileAlloc(fullPath) if alloc else FileLoad(fullPath)
		Util.PrintLog("Source", "Loading script: " + fullPath)

	return srcFile

# Config
static func LoadConfig(path : String, userDir : bool = false) -> ConfigFile:
	var fullPath : String		= (Path.Local if userDir else Path.ConfRsc) + path + Path.ConfExt
	var cfgFile : ConfigFile	= null

	var pathExists : bool = FileExists(fullPath)
	if pathExists or userDir:
		cfgFile = ConfigFile.new()
		if pathExists:
			var err : Error = cfgFile.load(fullPath)
			Util.Assert(err == OK, "Error loading the config file " + path + " located at " + fullPath)

			if err != OK:
				cfgFile.free()
				cfgFile = null
			else:
				Util.PrintLog("Config", "Loading file: " + fullPath)
	else:
		Util.Assert(pathExists, "Config file not found " + path + " should be located at " + fullPath)

	return cfgFile

static func SaveConfig(path : String, cfgFile : ConfigFile):
	Util.Assert(cfgFile != null, "Config file " + path + " not initialized")

	if cfgFile:
		var fullPath : String = Path.Local + path + Path.ConfExt
		var err : Error = cfgFile.save(fullPath)
		Util.Assert(err == OK, "Error saving the config file " + path + " located at " + fullPath)
		Util.PrintLog("Config", "Saving file: " + fullPath)

# Resource
static func LoadResource(fullPath : String, instantiate : bool = true) -> Object:
	var rscInstance : Object	= null
	var pathExists : bool		= ResourceExists(fullPath)

	Util.Assert(pathExists, "Resource file not found at: " + fullPath)
	if pathExists:
		rscInstance = ResourceInstance(fullPath) if instantiate else ResourceLoad(fullPath)

	return rscInstance

# Effect
static func LoadEffect(path : String, instantiate : bool = true) -> Node2D:
	var fullPath : String = Path.EffectsPst + path + Path.SceneExt
	return LoadResource(fullPath, instantiate)

# Entity
static func LoadEntitySprite(type : String, instantiate : bool = true) -> Node2D:
	var fullPath : String = Path.EntitySprite + type + Path.SceneExt
	return LoadResource(fullPath, instantiate)

static func LoadEntityComponent(type : String, instantiate : bool = true) -> Node:
	var fullPath : String = Path.EntityComponent + type + Path.SceneExt
	return LoadResource(fullPath, instantiate)

static func LoadEntityVariant(type : String, instantiate : bool = true) -> BaseEntity:
	var fullPath : String = Path.EntityVariant + type + Path.SceneExt
	return LoadResource(fullPath, instantiate)

# GUI
static func LoadGui(path : String, instantiate : bool = true) -> Resource:
	var fullPath : String = Path.GuiPst + path + Path.SceneExt
	return LoadResource(fullPath, instantiate)

# Music
static func LoadMusic(path : String) -> Resource:
	var fullPath : String = Path.MusicRsc + path
	var musicFile : Resource			= null

	var pathExists : bool		= ResourceExists(fullPath)
	Util.Assert(pathExists, "Music file not found " + path + " should be located at " + fullPath)

	if pathExists:
		musicFile = FileLoad(fullPath)
		Util.PrintLog("Music", "Loading file: " + fullPath)

	return musicFile

# Generic texture loading
static func LoadGfx(path : String) -> Resource:
	var fullPath : String = Path.GfxRsc + path
	return LoadResource(fullPath, false)

# Minimap
static func LoadMinimap(path : String) -> Resource:
	var fullPath : String = Path.MinimapRsc + path + Path.GfxExt
	return LoadResource(fullPath, false)

static func SaveScreenshot():
	var image : Image = Util.GetScreenCapture()
	Util.Assert(image != null, "Could not get a viewport screenshot")
	if image:
		var dir = DirAccess.open(OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS))
		if not dir.dir_exists("Screenshots"):
			dir.make_dir("Screenshots")
		dir.change_dir("Screenshots")

		var date : Dictionary = Time.get_datetime_dict_from_system()
		var savePath : String = dir.get_current_dir(true)
		savePath += "/Screenshot-%d-%02d-%02d_%02d-%02d-%02d" % [date.year, date.month, date.day, date.hour, date.minute, date.second]
		savePath += Path.GfxExt

		if not dir.dir_exists(savePath):
			var ret : Error = image.save_png(savePath)
			Util.Assert(ret == OK, "Could not save the screenshot, error code: " + str(ret))
			if ret == OK:
				Util.PrintInfo("FileSystem", "Saving capture: " + savePath)
