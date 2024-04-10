extends Object
class_name EntityInventory

var actor : Actor			= null
var items: Array[Item]		= []

#
func PushItem(cell : BaseCell, count : int) -> bool:
	if count <= 0 or not cell:
		return false

	if cell.stackable:
		for item in items:
			if item.cell.name == cell.name:
				item.count += count
				return true

		if items.size() >= ActorCommons.InventorySize:
			return false
		items.append(Item.new(cell, count))
	else:
		if items.size() + count > ActorCommons.InventorySize:
			return false
		for _i in range(count):
			if items.size() >= ActorCommons.InventorySize:
				return false
			items.append(Item.new(cell))

	return true

func PopItem(cell : BaseCell, count : int) -> bool:
	var toRemove : Array[Item] = []
	for item in items:
		if item.cell.name == cell.name:
			if cell.stackable:
				if item.count >= count:
					item.count -= count
					if item.count <= 0:
						items.erase(item)
					return true
				else:
					return false
			else:
				toRemove.append(item)
				break

	if not cell.stackable and toRemove.size() == count:
		for item in toRemove:
			items.erase(item)
		return true

	return false

#
func GetWeight() -> float:
	var weight : float = 0.0
	for item in items:
		weight += item.cell.weight * item.count
	return weight / 1000.0

func UseItem(cell : BaseCell):
	if cell and cell.type == CellCommons.Type.ITEM and cell.usable and actor and RemoveItem(cell):
		if cell.effects.has(CellCommons.effectHP):
			actor.stat.SetHealth(cell.effects[CellCommons.effectHP])
		if cell.effects.has(CellCommons.effectMana):
			actor.stat.SetMana(cell.effects[CellCommons.effectMana])
		if cell.effects.has(CellCommons.effectStamina):
			actor.stat.SetStamina(cell.effects[CellCommons.effectStamina])

#
func AddItem(cell : BaseCell, count : int = 1):
	if PushItem(cell, count):
		var peerID : int = Launcher.Network.Server.GetRid(actor)
		if peerID != NetworkCommons.RidUnknown:
			Launcher.Network.ItemAdded(cell, count, peerID)


func RemoveItem(cell : BaseCell, count : int = 1) -> bool:
	if PopItem(cell, count):
		var peerID : int = Launcher.Network.Server.GetRid(actor)
		if peerID != NetworkCommons.RidUnknown:
			Launcher.Network.ItemRemoved(cell, count, peerID)
		return true
	return false

#
func ImportInventory(data : Dictionary):
	for key in data.keys():
		PushItem(DB.ItemsDB[key], data[key])

func ExportInventory() -> Dictionary:
	var data : Dictionary = {}
	for item in items:
		if data.has(item.cell.id):
			data[item.cell.id] += item.count
		else:
			data[item.cell.id] = item.count
	return data

#
func Init(actorNode : Actor):
	Util.Assert(actorNode != null, "Caller actor node should never be null")
	actor = actorNode
