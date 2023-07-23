extends Node

#
var Client							= null
var Server							= null

var peer : ENetMultiplayerPeer		= ENetMultiplayerPeer.new()
var uniqueID : int					= 0

#
@rpc("any_peer", "reliable")
func ConnectPlayer(playerName : String, rpcID : int = -1):
	NetCallServer("ConnectPlayer", [playerName], rpcID)

@rpc("any_peer", "reliable")
func DisconnectPlayer(rpcID : int = -1):
	NetCallServer("DisconnectPlayer", [], rpcID)

#
@rpc("any_peer", "unreliable")
func TriggerWarp(rpcID : int = -1):
	NetCallServer("TriggerWarp", [], rpcID)

@rpc("authority", "reliable")
func WarpPlayer(mapName : String, rpcID : int = -1):
	NetCallClient("WarpPlayer", [mapName], rpcID)

#
@rpc("any_peer", "reliable")
func TriggerEmote(emoteID : int, rpcID : int = -1):
	NetCallServer("TriggerEmote", [emoteID], rpcID)

@rpc("authority", "reliable")
func EmotePlayer(senderAgentID : int, emoteID : int, rpcID : int = -1):
	NetCallClient("EmotePlayer", [senderAgentID, emoteID], rpcID)

#
@rpc("any_peer", "reliable")
func GetEntities(rpcID : int = -1):
	NetCallServer("GetEntities", [], rpcID)

@rpc("authority", "reliable")
func AddEntity(agentID : int, entityType : String, entityID : String, entityName : String, entityPos : Vector2i, agentState : EntityCommons.State, rpcID : int = -1):
	NetCallClient("AddEntity", [agentID, entityType, entityID, entityName, entityPos, agentState], rpcID)

@rpc("authority", "reliable")
func RemoveEntity(agentID : int, rpcID : int = -1):
	NetCallClient("RemoveEntity", [agentID], rpcID)

#
@rpc("any_peer", "unreliable_ordered")
func SetClickPos(pos : Vector2, rpcID : int = -1):
	NetCallServer("SetClickPos", [pos], rpcID)

@rpc("any_peer", "unreliable_ordered")
func SetMovePos(pos : Vector2, rpcID : int = -1):
	NetCallServer("SetMovePos", [pos], rpcID)

@rpc("authority", "unreliable_ordered")
func UpdateEntity(agentID : int, velocity : Vector2, position : Vector2, agentState : EntityCommons.State, rpcID : int = -1):
	NetCallClient("UpdateEntity", [agentID, velocity, position, agentState], rpcID)

@rpc("authority", "reliable")
func ForceUpdateEntity(agentID : int, velocity : Vector2, position : Vector2, agentState : EntityCommons.State, rpcID : int = -1):
	NetCallClient("UpdateEntity", [agentID, velocity, position, agentState], rpcID)

#
@rpc("any_peer", "reliable")
func TriggerSit(rpcID : int = -1):
	NetCallServer("TriggerSit", [], rpcID)

#
@rpc("any_peer", "reliable")
func TriggerChat(text : String, rpcID : int = -1):
	NetCallServer("TriggerChat", [text], rpcID)

@rpc("authority", "reliable")
func ChatAgent(ridAgent : int, text : String, rpcID : int = -1):
	NetCallClient("ChatAgent", [ridAgent, text], rpcID)

#
@rpc("any_peer", "reliable")
func TriggerEntity(entityID : int, rpcID : int = -1):
	NetCallServer("TriggerEntity", [entityID], rpcID)

@rpc("authority", "reliable")
func DamageDealt(agentID : int, targetID : int, damage : int, rpcID : int = -1):
	NetCallClient("DamageDealt", [agentID, targetID, damage], rpcID)

#
@rpc("any_peer", "reliable")
func TriggerMorph(rpcID : int = -1):
	NetCallServer("TriggerMorph", [], rpcID)


@rpc("authority", "reliable")
func Morphed(agentID : int, morphID : String, rpcID : int = -1):
	NetCallClient("Morphed", [agentID, morphID], rpcID)

#
func NetCallServer(methodName : String, args : Array, rpcID : int):
	if Server:
		Server.callv(methodName, args + [rpcID])
	else:
		callv("rpc_id", [1, methodName] + args + [uniqueID])

func NetCallClient(methodName : String, args : Array, rpcID : int):
	if Client:
		Client.callv(methodName, args)
	else:
		callv("rpc_id", [rpcID, methodName] + args)

func NetCallClientGlobal(methodName : String, args : Array):
	if Client:
		Client.callv(methodName, args)
	else:
		callv("rpc", [methodName] + args)

func NetMode(isClient : bool, isServer : bool):
	if isClient:
		Client = Launcher.FileSystem.LoadSource("network/Client.gd")
	if isServer:
		Server = Launcher.FileSystem.LoadSource("network/Server.gd")

func NetCreate():
	if uniqueID != 0:
		pass

	if Client and Server:
		ConnectPlayer(Launcher.FSM.playerName)
	elif Client:
		var serverPort : int		= Launcher.Conf.GetInt("Server", "serverPort", Launcher.Conf.Type.NETWORK)
		var serverAdress : String	= Launcher.Conf.GetString("Server", "serverAdress", Launcher.Conf.Type.NETWORK)

		var ret = peer.create_client(serverAdress, serverPort)
		Util.Assert(ret == OK, "Client could not connect, please check the server adress %s and port number %d" % [serverAdress, serverPort])
		if ret == OK:
			Launcher.Root.multiplayer.multiplayer_peer = peer
			var connectedCallback : Callable = ConnectPlayer.bind(Launcher.FSM.playerName) 
			if not Launcher.Root.multiplayer.connected_to_server.is_connected(connectedCallback):
				Launcher.Root.multiplayer.connected_to_server.connect(connectedCallback)
			if not Launcher.Root.multiplayer.connection_failed.is_connected(Client.DisconnectPlayer):
				Launcher.Root.multiplayer.connection_failed.connect(Client.DisconnectPlayer)
			if not Launcher.Root.multiplayer.server_disconnected.is_connected(Client.DisconnectPlayer):
				Launcher.Root.multiplayer.server_disconnected.connect(Client.DisconnectPlayer)

			uniqueID = Launcher.Root.multiplayer.get_unique_id()
	elif Server:
		var serverPort : int		= Launcher.Conf.GetInt("Server", "serverPort", Launcher.Conf.Type.NETWORK)
		var maxPlayerCount : int	= Launcher.Conf.GetInt("Server", "maxPlayerCount", Launcher.Conf.Type.NETWORK)
		var ret = peer.create_server(serverPort, maxPlayerCount)

		Util.Assert(ret == OK, "Server could not be created, please check if your port %d is valid" % serverPort)
		if ret == OK:
			Launcher.Root.multiplayer.multiplayer_peer = peer
			if not Launcher.Root.multiplayer.peer_connected.is_connected(Server.ConnectPeer):
				Launcher.Root.multiplayer.peer_connected.connect(Server.ConnectPeer)
			if not Launcher.Root.multiplayer.peer_disconnected.is_connected(Server.DisconnectPeer):
				Launcher.Root.multiplayer.peer_disconnected.connect(Server.DisconnectPeer)
			Util.PrintLog("Server", "Initialized on port %d" % serverPort)

			uniqueID = Launcher.Root.multiplayer.get_unique_id()

func NetDestroy():
	if uniqueID == 0:
		pass

	if Client and Server:
		Client.DisconnectPlayer()

	peer.close()
	uniqueID = 0
