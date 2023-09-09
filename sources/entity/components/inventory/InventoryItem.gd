extends Object
class_name InventoryItem

@export var type: BaseItem
@export var count: int

func is_stackable():
	return type.stackable

func _init(p_type: BaseItem, p_count: int):
	type = p_type
	count = p_count
	Util.Assert(p_count <= 1 or type.stackable, "Trying to create an InventoryItem with multiple items, but the type is not stackable")
