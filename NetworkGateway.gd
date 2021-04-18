extends Panel

export var hostportnumber : int = 4547
export var udpdiscoveryport = 4546

var remoteservers = [ "tunnelvr.goatchurch.org.uk" ]
var broadcastudpipnum = "255.255.255.255"
const udpdiscoverybroadcasterperiod = 2.0
const broadcastservermsg = "OQServer_here!"

enum NETWORK_OPTIONS { NETWORK_OFF = 0
					   AS_SERVER = 1,
					   LOCAL_NETWORK = 2,
					   FIXED_URL = 3,
					 }

# command for running locally on the unix partition
# /mnt/c/Users/henry/godot/Godot_v3.2.3-stable_linux_server.64 --main-pack /mnt/c/Users/henry/godot/games/OQ_Networking_Demo/releases/OQ_Networking_Demo.pck

onready var MainNode = get_node("/root/Main")
onready var RemotePlayersNode = get_node("/root/Main/RemotePlayers")
onready var LocalPlayer = RemotePlayersNode.get_node("LocalPlayer")

var udpdiscoverybroadcasterperiodtimer = udpdiscoverybroadcasterperiod
var udpdiscoveryreceivingserver = null
onready var serverbroadcastsudp = not OS.has_feature("Server")

var deferred_playerconnections = [ ]
var remote_players_idstonodenames = { }

func _ready():
	randomize()
	for rs in remoteservers:
		$NetworkOptionButton.add_item(rs)

	get_tree().connect("network_peer_connected", 	self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")

	get_tree().connect("connected_to_server", 		self, "_connected_to_server")
	get_tree().connect("connection_failed", 		self, "_connection_failed")
	get_tree().connect("server_disconnected", 		self, "_server_disconnected")

	yield(get_tree().create_timer(1.5), "timeout")
	if OS.has_feature("Server"):
		$NetworkOptionButton.select(NETWORK_OPTIONS.AS_SERVER)
	_on_OptionButton_item_selected($NetworkOptionButton.selected)


func _input(event):
	if event is InputEventKey and event.pressed:
		var bsel = -1
		if (event.scancode == KEY_0):	bsel = 0
		elif (event.scancode == KEY_1):	bsel = 1
		elif (event.scancode == KEY_2):	bsel = 2
		elif (event.scancode == KEY_3):	bsel = 3
		elif (event.scancode == KEY_4):	bsel = 4

		if bsel != -1 and $NetworkOptionButton.selected != bsel:
			$NetworkOptionButton.select(bsel)
			_on_OptionButton_item_selected(bsel)
		elif (event.scancode == KEY_G):
			$Doppelganger.pressed = not $Doppelganger.pressed

func updatestatusrec(ptxt):
	$StatusRec.text = "%sNetworkID: %d\nRemotes: %s" % [ptxt, LocalPlayer.networkID, PoolStringArray(remote_players_idstonodenames.values()).join(", ")]

func _server_disconnected():
	var ns = $NetworkOptionButton.selected
	get_tree().set_network_peer(null)
	LocalPlayer.networkID = get_tree().get_network_unique_id()
	assert (LocalPlayer.networkID == 0)
	LocalPlayer.set_name("R%d" % LocalPlayer.networkID) 
	deferred_playerconnections.clear()
	for id in remote_players_idstonodenames.duplicate():
		_player_disconnected(id)
	print("*** _server_disconnected ", LocalPlayer.networkID)
	$ColorRect.color = Color.red if (ns >= NETWORK_OPTIONS.LOCAL_NETWORK) else Color.black
	updatestatusrec("")

func _connected_to_server():
	LocalPlayer.networkID = get_tree().get_network_unique_id()
	assert (LocalPlayer.networkID >= 1)
	LocalPlayer.set_name("R%d" % LocalPlayer.networkID)
	print("_connected_to_server myid=", LocalPlayer.networkID)
	for id in deferred_playerconnections:
		_player_connected(id)
	deferred_playerconnections.clear()
	$ColorRect.color = Color.green
	updatestatusrec("")

func _connection_failed():
	print("_connection_failed ", LocalPlayer.networkID)
	assert (LocalPlayer.networkID == -1)
	get_tree().set_network_peer(null)	
	LocalPlayer.networkID = 0
	deferred_playerconnections.clear()
	$ColorRect.color = Color.red
	updatestatusrec("Connection failed\n")

func updateplayerlist():
	var plp = $PlayerList.get_item_text($PlayerList.selected) 
	$PlayerList.clear()
	$PlayerList.add_item("me")
	$PlayerList.selected = 0
	for remoteplayer in RemotePlayersNode.get_children():
		$PlayerList.add_item(remoteplayer.get_name())
		if plp == remoteplayer.get_name():
			$PlayerList.selected = $PlayerList.get_item_count() - 1

func _player_connected(id):
	if LocalPlayer.networkID == -1:
		deferred_playerconnections.push_back(id)
		print("_player_connected remote=", id, "  **deferred")
		return
	print("_player_connected remote=", id)
	assert (LocalPlayer.networkID >= 1)
	assert (not remote_players_idstonodenames.has(id))
	remote_players_idstonodenames[id] = null
	print("players_connected_list: ", remote_players_idstonodenames)
	var avatardata = LocalPlayer.avatarinitdata()
	rpc_id(id, "spawnintoremoteplayer", avatardata)
	updatestatusrec("")
	updateplayerlist()
	
func _player_disconnected(id):
	print("_player_disconnected remote=", id)
	assert (remote_players_idstonodenames.has(id))
	var playernodename = remote_players_idstonodenames[id]
	remote_players_idstonodenames.erase(id)
	if playernodename != null:
		RemotePlayersNode.removeremoteplayer(playernodename)
	print("players_connected_list: ", remote_players_idstonodenames)
	updatestatusrec("")
	updateplayerlist()

remote func spawnintoremoteplayer(avatardata):
	var senderid = get_tree().get_rpc_sender_id()
	var remoteplayer = RemotePlayersNode.newremoteplayer(avatardata)
	assert (senderid == avatardata["networkid"])
	remoteplayer.set_network_master(senderid)
	assert (remote_players_idstonodenames[senderid] == null)
	remote_players_idstonodenames[senderid] = remoteplayer.get_name()

var Dudpcount = 0
#set_process(false)
func _process(delta):
	var ns = $NetworkOptionButton.selected
	if ns == NETWORK_OPTIONS.AS_SERVER and serverbroadcastsudp:
		udpdiscoverybroadcasterperiodtimer -= delta
		if udpdiscoverybroadcasterperiodtimer < 0:
			var udpdiscoverybroadcaster = PacketPeerUDP.new()
			udpdiscoverybroadcaster.set_broadcast_enabled(true)
			var err0 = udpdiscoverybroadcaster.set_dest_address(broadcastudpipnum, udpdiscoveryport)
			var err1 = udpdiscoverybroadcaster.put_packet((broadcastservermsg+" "+str(Dudpcount)).to_utf8())
			Dudpcount += 1
			print("put UDP onto ", broadcastudpipnum, ":", broadcastudpipnum, " errs:", err0, " ", err1)
			if err0 != 0 or err1 != 0:
				print("udpdiscoverybroadcaster error ", err0, " ", err1)
			udpdiscoverybroadcasterperiodtimer = udpdiscoverybroadcasterperiod

	if ns == NETWORK_OPTIONS.LOCAL_NETWORK and LocalPlayer.networkID == 0:
		udpdiscoveryreceivingserver.poll()
		if udpdiscoveryreceivingserver.is_connection_available():
			var peer = udpdiscoveryreceivingserver.take_connection()
			var pkt = peer.get_packet()
			var spkt = pkt.get_string_from_utf8().split(" ")
			print("Received: ", spkt, " from ", peer.get_packet_ip())
			if spkt[0] == broadcastservermsg:
				var receivedIPnumber = peer.get_packet_ip()
				for nsi in range(NETWORK_OPTIONS.FIXED_URL, $NetworkOptionButton.get_item_count()):
					if receivedIPnumber == $NetworkOptionButton.get_item_text(nsi):
						ns = nsi
						break
				if ns == NETWORK_OPTIONS.LOCAL_NETWORK:
					$NetworkOptionButton.add_item(receivedIPnumber)
					ns = $NetworkOptionButton.get_item_count() - 1
				$NetworkOptionButton.select(ns)
				_on_OptionButton_item_selected(ns)
				

func _on_OptionButton_item_selected(ns):
	print(" _on_OptionButton_item_selected ", ns)
	if ns == NETWORK_OPTIONS.LOCAL_NETWORK:
		udpdiscoveryreceivingserver = UDPServer.new()
		udpdiscoveryreceivingserver.listen(udpdiscoveryport)
	elif udpdiscoveryreceivingserver != null:
		udpdiscoveryreceivingserver.stop()
		udpdiscoveryreceivingserver = null

	if LocalPlayer.networkID != 0:
		if get_tree().get_network_peer() != null:
			print("closing connection ", LocalPlayer.networkID, get_tree().get_network_peer())
		_server_disconnected()
	assert (LocalPlayer.networkID == 0)

	if ns == NETWORK_OPTIONS.AS_SERVER:
		print("creating server on port: ", hostportnumber)
		var networkedmultiplayerenetserver = NetworkedMultiplayerENet.new()
		var e = networkedmultiplayerenetserver.create_server(hostportnumber)
		if e == 0:
			get_tree().set_network_peer(networkedmultiplayerenetserver)
			_connected_to_server()
		else:
			print("networkedmultiplayerenet createserver Error: ", { ERR_CANT_CREATE:"ERR_CANT_CREATE" }.get(e, e))
			print("*** is there a server running on this port already? ", hostportnumber)
			$ColorRect.color = Color.red
			$NetworkOptionButton.select(NETWORK_OPTIONS.NETWORK_OFF)

	if ns >= NETWORK_OPTIONS.FIXED_URL and LocalPlayer.networkID == 0:
		var serverIPnumber = $NetworkOptionButton.get_item_text(ns).split(" ", 1)[0]
		var networkedmultiplayerenet = NetworkedMultiplayerENet.new()
		var e = networkedmultiplayerenet.create_client(serverIPnumber, hostportnumber, 0, 0)
		print("networkedmultiplayerenet createclient ", ("" if e else str(e)), " to: ", serverIPnumber)
		if e == 0:
			get_tree().set_network_peer(networkedmultiplayerenet)
			$ColorRect.color = Color.yellow
			LocalPlayer.networkID = -1
		else:
			$NetworkOptionButton.select(NETWORK_OPTIONS.NETWORK_OFF)
		
		

func _on_Doppelganger_toggled(button_pressed):
	if button_pressed:
		$DoppelgangerPanel.visible = true
		var avatardata = LocalPlayer.avatarinitdata()
		avatardata["playernodename"] = "Doppelganger"
		LocalPlayer.doppelgangernode = RemotePlayersNode.newremoteplayer(avatardata)
	else:
		$DoppelgangerPanel.visible = false
		LocalPlayer.doppelgangernode = null
		RemotePlayersNode.removeremoteplayer("Doppelganger")
	updateplayerlist()

