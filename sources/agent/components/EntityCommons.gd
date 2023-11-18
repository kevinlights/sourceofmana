extends Object
class_name EntityCommons

#
enum Gender
{
	MALE = 0,
	FEMALE,
	NONBINARY,
	COUNT
}

enum State
{
	UNKNOWN = -1,
	IDLE = 0,
	WALK,
	SIT,
	ATTACK,
	DEATH,
	TO_TRIGGER,
	TRIGGER,
	FROM_TRIGGER,
	COUNT
}

enum Slot
{
	BODY = 0,
	CHEST,
	LEGS,
	FEET,
	HANDS,
	HEAD,
	FACE,
	WEAPON,
	SHIELD,
	COUNT
}

static var playbackParameter : String = "parameters/playback"

# Skip TO_TRIGGER & FROM_TRIGGER as they are only used as transition steps between idle/trigger.
const stateTransitions : Array[Array] = [
#	IDLE			WALK			SIT				ATTACK			DEATH			TO_TRIGGER		TRIGGER			FROM_TRIGGER		< To/From v
	[State.IDLE,	State.WALK,		State.SIT,		State.ATTACK,	State.DEATH,	State.IDLE,		State.TRIGGER,	State.IDLE],		# IDLE
	[State.IDLE,	State.WALK,		State.WALK,		State.ATTACK,	State.DEATH,	State.IDLE,		State.TRIGGER,	State.IDLE],		# WALK
	[State.SIT,		State.WALK,		State.IDLE,		State.ATTACK,	State.DEATH,	State.IDLE,		State.TRIGGER,	State.IDLE],		# SIT
	[State.IDLE,	State.WALK,		State.ATTACK,	State.ATTACK,	State.DEATH,	State.IDLE,		State.TRIGGER,	State.IDLE],		# ATTACK
	[State.DEATH,	State.DEATH,	State.DEATH,	State.DEATH,	State.DEATH,	State.DEATH,	State.DEATH,	State.DEATH],		# DEATH
	[],																																	# TO_TRIGGER
	[State.TRIGGER,	State.TRIGGER,	State.SIT,		State.ATTACK,	State.DEATH,	State.TRIGGER,	State.IDLE,		State.TRIGGER],		# TRIGGER
	[]																																	# FROM_TRIGGER
]

const stateIdle : String					= "Idle"
const stateWalk : String					= "Walk"
const stateSit : String						= "Sit"
const stateAttack : String					= "Attack"
const stateDeath : String					= "Death"
const stateToTrigger : String				= "To Trigger"
const stateTrigger : String					= "Trigger"
const stateFromTrigger : String				= "From Trigger"


#
static func GetNextTransition(currentState : State, newState : State) -> State:
	return stateTransitions[currentState][newState]

static func GetStateName(state : State):
	match state:
		State.IDLE:			return stateIdle
		State.WALK:			return stateWalk
		State.SIT:			return stateSit
		State.ATTACK:		return stateAttack
		State.DEATH:		return stateDeath
		State.TO_TRIGGER:	return stateToTrigger
		State.TRIGGER:		return stateTrigger
		State.FROM_TRIGGER:	return stateFromTrigger
		_:					return stateIdle

# Guardband static vars
static var StartGuardbandDist : int				= 0
static var PatchGuardband : int					= 0
static var MaxGuardbandDist : int				= 0
static var MaxGuardbandDistVec : Vector2		= Vector2.ZERO

# Visual
static var allyTarget : Resource 				= preload("res://presets/entities/components/targets/Ally.tres")
static var enemyTarget : Resource				= preload("res://presets/entities/components/targets/Enemy.tres")
static var damageLabel : Resource				= preload("res://presets/gui/DamageLabel.tscn")


static func InitVars():
	EntityCommons.StartGuardbandDist = Launcher.Conf.GetInt("Guardband", "StartGuardbandDist", Launcher.Conf.Type.NETWORK)
	EntityCommons.PatchGuardband = Launcher.Conf.GetInt("Guardband", "PatchGuardband", Launcher.Conf.Type.NETWORK)
	EntityCommons.MaxGuardbandDist = Launcher.Conf.GetInt("Guardband", "MaxGuardbandDist", Launcher.Conf.Type.NETWORK)
	EntityCommons.MaxGuardbandDistVec = Vector2(EntityCommons.MaxGuardbandDist, EntityCommons.MaxGuardbandDist)
