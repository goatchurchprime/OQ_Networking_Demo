extends Panel

export var hostportnumber : int = 4547
export var udpdiscoveryport = 4546

var remoteservers = [ "tunnelvr.goatchurch.org.uk" ]
var broadcastudpipnum = "255.255.255.255"
const udpdiscoverybroadcasterperiod = 2.0
const broadcastservermsg = "OQServer_here!"

enum NETWORK_OPTIONS {
	AS_SERVER = 1,
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

var localipnumbers = ""
var remoteplayertimeoffsets = { }
var serverIPnumber = ""
var uniqueinstancestring = ""

var deferred_playerconnections = [ ]
var remote_players_idstonodenames = { }

func _ready():
	randomize()
	uniqueinstancestring = OS.get_unique_id().replace("{", "").split("-")[0].to_upper()+"_"+str(randi())
	for rs in remoteservers:
		$NetworkOptionButton.add_item(rs)

	get_tree().connect("network_peer_connected", 	self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")

	get_tree().connect("connected_to_server", 		self, "_connected_to_server")
	get_tree().connect("connection_failed", 		self, "_connection_failed")
	get_tree().connect("server_disconnected", 		self, "_server_disconnected")

	yield(get_tree().create_timer(1.5), "timeout")
	localipnumbers = getLocalIPnumbers()
	print("localipnumbers ", localipnumbers)
	if OS.has_feature("Server"):
		$NetworkOptionButton.select(NETWORK_OPTIONS.AS_SERVER)
	_on_OptionButton_item_selected($NetworkOptionButton.selected)


func getLocalIPnumbers():
	var localips = [ ]
	for k in IP.get_local_interfaces():
		for l in k["addresses"]:
			if l.is_valid_ip_address() and l.find(".") != -1:
				var ls = l.split(".")
				print("ipaddress ", ls)
				if int(ls[0]) == 10 or (int(ls[0]) == 172 and int(ls[1]) >= 16 and int(ls[1]) <= 31) or \
						(int(ls[0]) == 192 and int(ls[1]) == 168):
					localips.push_back(l)
	return PoolStringArray(localips).join(",")

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
	$ColorRect.color = Color.red if (ns == NETWORK_OPTIONS.LOCAL_NETWORK or ns == NETWORK_OPTIONS.FIXED_URL) else Color.black
	updatestatusrec("")

func _connected_to_server():
	LocalPlayer.networkID = get_tree().get_network_unique_id()
	assert (LocalPlayer.networkID > 1)
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
	remoteplayer.set_network_master(avatardata.networkID)
	assert (remote_players_idstonodenames[senderid] == null)
	remote_players_idstonodenames[senderid] = avatardata.get_name()
			
remote func gnextcompressedframe(cf):
	var tlocal = OS.get_ticks_msec()*0.001
	var id = cf[FI.CFI.ID]
	RemotePlayersNode.nextcompressedframe("R%d"%id, cf, tlocal)

func _process(delta):
	var ns = $NetworkOptionButton.selected

	if ns == NETWORK_OPTIONS.AS_SERVER:
		udpdiscoverybroadcasterperiodtimer -= delta
		if udpdiscoverybroadcasterperiodtimer < 0 and localipnumbers != "":
			if serverbroadcastsudp:  
				var udpdiscoverybroadcaster = PacketPeerUDP.new()
				udpdiscoverybroadcaster.set_broadcast_enabled(true)
				var err0 = udpdiscoverybroadcaster.set_dest_address(broadcastudpipnum, udpdiscoveryport)
				var err1 = udpdiscoverybroadcaster.put_packet((broadcastservermsg+" "+localipnumbers+" "+uniqueinstancestring).to_utf8())
				print("put UDP onto ", broadcastudpipnum, ":", broadcastudpipnum, " errs:", err0, " ", err1)
				if err0 != 0 or err1 != 0:
					print("udpdiscoverybroadcaster error")

			if LocalPlayer.networkID == 0:
				print("creating server on port: ", hostportnumber)
				var networkedmultiplayerenetserver = NetworkedMultiplayerENet.new()
				var e = networkedmultiplayerenetserver.create_server(hostportnumber)
				if e == 0:
					get_tree().set_network_peer(networkedmultiplayerenetserver)
					LocalPlayer.networkID = get_tree().get_network_unique_id()
					assert (LocalPlayer.networkID == 1)
					$ColorRect.color = Color.green
				else:
					print("networkedmultiplayerenet createserver Error: ", { ERR_CANT_CREATE:"ERR_CANT_CREATE" }.get(e, e))
					print("*** is there a server running on this port already? ", hostportnumber)
					$ColorRect.color = Color.red

			udpdiscoverybroadcasterperiodtimer = udpdiscoverybroadcasterperiod

	elif (ns == NETWORK_OPTIONS.LOCAL_NETWORK) and (udpdiscoveryreceivingserver != null) and LocalPlayer.networkID == 0:
		udpdiscoveryreceivingserver.poll()
		if udpdiscoveryreceivingserver.is_connection_available():
			var peer = udpdiscoveryreceivingserver.take_connection()
			var pkt = peer.get_packet()
			var spkt = pkt.get_string_from_utf8().split(" ")
			print("Received: ", spkt, " from ", peer.get_packet_ip())
			if spkt[0] == broadcastservermsg:
				serverIPnumber = peer.get_packet_ip()

	if (ns == NETWORK_OPTIONS.LOCAL_NETWORK or ns >= NETWORK_OPTIONS.FIXED_URL) and (serverIPnumber != "") and LocalPlayer.networkID == 0:
		var networkedmultiplayerenet = NetworkedMultiplayerENet.new()
		var e = networkedmultiplayerenet.create_client(serverIPnumber, hostportnumber, 0, 0)
		print("networkedmultiplayerenet createclient ", ("" if e else str(e)), " to: ", serverIPnumber)
		get_tree().set_network_peer(networkedmultiplayerenet)
		$ColorRect.color = Color.yellow
		LocalPlayer.networkID = -1

func _on_OptionButton_item_selected(ns):
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

	if ns >= NETWORK_OPTIONS.FIXED_URL:
		serverIPnumber = $NetworkOptionButton.get_item_text(ns).split(" ", 1)[0]


func _on_Doppelganger_toggled(button_pressed):
	if button_pressed:
		$DoppelgangerPanel.visible = true
		var avatardata = LocalPlayer.avatarinitdata()
		avatardata["playernodename"] = "Doppelganger"
		RemotePlayersNode.newremoteplayer(avatardata)
	else:
		$DoppelgangerPanel.visible = false
		RemotePlayersNode.removeremoteplayer("Doppelganger")
	updateplayerlist()

		
func _on_Interpdelay_value_changed(value):
	var interpdelay = value/1000
	for nname in RemotePlayersNode.playerframestacks:
		RemotePlayersNode.playerframestacks[nname].furtherbacktime = interpdelay
	$InterpdelayLabel.text = "Interpdelay %.2fs"%interpdelay
