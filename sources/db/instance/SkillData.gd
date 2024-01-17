extends Node
class_name SkillData

@export var _id : int
@export var _name : String
@export var _iconPath : String
@export var _castPresetPath : String
@export var _castTextureOverride : String
@export var _castColor : Color
@export var _castTime : float
@export var _skillPresetPath : String
@export var _skillColor : Color
@export var _skillTime : float
@export var _cooldownTime : float
@export var _state : EntityCommons.State
@export var _mode : Skill.TargetMode
@export var _range : int
@export var _damage : int
@export var _heal : int
@export var _repeat : bool

# Stats, must have the same name than their relatives in EntityStats
@export var stamina : int
@export var mana : int

func _init():
	_id = 0
	_name = "Unknown"
	_iconPath = "res://data/graphics/items/skill/spell.png"
	_castPresetPath = ""
	_castTextureOverride = ""
	_castColor = Color.BLACK
	_castTime = 0.0
	_skillPresetPath = ""
	_skillColor = Color.BLACK
	_skillTime = 0.0
	_cooldownTime = 0.0
	_state = EntityCommons.State.IDLE
	_mode = Skill.TargetMode.SINGLE
	_range = 32
	_damage = 0
	_heal = 0
	_repeat = false
	stamina = 0
	mana = 0
