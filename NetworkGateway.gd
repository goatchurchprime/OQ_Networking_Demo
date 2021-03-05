extends Panel

export var hostportnumber : int = 4546

var remoteplayertimeoffsets = { }
var deferred_playerconnections = [ ]
var serverIPnumber = ""
var networkID = 0   # 0:unconnected, 1:server, -1:connecting, >1:connected to client
var uniqueinstancestring = ""

onready var MainNode = get_node("/root/Main")
onready var PlayersNode = get_node("/root/Main/Players")

enum NETWORK_OPTIONS {
	AS_SERVER = 1,
	LOCAL_NETWORK = 2,
	FIXED_URL = 3,
}

const udpdiscoverybroadcasterperiod = 2.0
var udpdiscoverybroadcasterperiodtimer = udpdiscoverybroadcasterperiod
var udpdiscoveryport = 4547
var udpdiscoveryreceivingserver = null

var localipnumbers = ""
# mosquitto_sub -h mosquitto.doesliverpool.xyz -v -t "godot/#"

func _ready():
	randomize()
	uniqueinstancestring = OS.get_unique_id().replace("{", "").split("-")[0].to_upper()+"_"+str(randi())

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
	set_network_master(0)

class RemoteTimeOffsetCalculator:
	var relativetimeminmax 	= 0
	var remotetimegapmaxmin = 0
	var prevremotetime 		= 0
	var reltimebatchcount 	= 0
	var remotetimegapmin 	= 0
	var relativetimemax 	= 0
	var firstrelativetimenotset = true
	var remotetimegap_dtmax = 0.8  # copied from PlayerMotion.gd
	
	func ConvertToLocal(tremote):
		var tlocal = OS.get_ticks_msec()*0.001
		var reltime = tlocal - tremote
		if reltimebatchcount == 0 or reltime > relativetimemax:
			relativetimemax = reltime
		if reltimebatchcount > 0:
			var remotetimegap = tremote - prevremotetime
			if reltimebatchcount == 1 or remotetimegap < remotetimegapmin:
				remotetimegapmin = remotetimegap
		reltimebatchcount += 1
		prevremotetime = tremote
		if reltimebatchcount == 10:
			if firstrelativetimenotset or relativetimemax < relativetimeminmax:
				relativetimeminmax = relativetimemax
			if firstrelativetimenotset or remotetimegapmin > remotetimegapmaxmin:
				remotetimegapmaxmin = remotetimegapmin
			reltimebatchcount = 0
			if firstrelativetimenotset:
				print("relativetimeminmax ", relativetimeminmax, "  ", remotetimegapmaxmin)
				firstrelativetimenotset = false
		if firstrelativetimenotset:
			return tlocal
		return tlocal + relativetimeminmax + remotetimegap_dtmax + 0.05

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
		if (event.scancode == KEY_0):
			$NetworkOptionButton.select(0)
			_on_OptionButton_item_selected(0)
		elif (event.scancode == KEY_1):
			$NetworkOptionButton.select(1)
			_on_OptionButton_item_selected(1)
		elif (event.scancode == KEY_2):
			$NetworkOptionButton.select(2)
			_on_OptionButton_item_selected(2)
		elif (event.scancode == KEY_3):
			$NetworkOptionButton.select(3)
			_on_OptionButton_item_selected(3)


func _server_disconnected():
	var ns = $NetworkOptionButton.selected
	get_tree().set_network_peer(null)
	networkID = get_tree().get_network_unique_id()
	assert (networkID == 0)
	deferred_playerconnections.clear()
	for id in remoteplayertimeoffsets.keys():
		_player_disconnected(id)
	print("*** _server_disconnected ", networkID)
	$ColorRect.color = Color.red if (ns == NETWORK_OPTIONS.LOCAL_NETWORK or ns == NETWORK_OPTIONS.FIXED_URL) else Color.black

func _connected_to_server():
	networkID = get_tree().get_network_unique_id()
	assert (networkID > 1)
	print("_connected_to_server myid=", networkID)
	#PlayersNode.rpc("spawnremoteplayer", getplayerinfo())
	for id in deferred_playerconnections:
		_player_connected(id)
	deferred_playerconnections.clear()
	$ColorRect.color = Color.green

func _connection_failed():
	print("_connection_failed ", networkID)
	assert (networkID == -1)
	get_tree().set_network_peer(null)	
	networkID = 0
	deferred_playerconnections.clear()
	$ColorRect.color = Color.red
	
func getplayerinfo():
	return { FrameInterpolation.CFINDEX.TIMESTAMP:	OS.get_ticks_msec()*0.001,
			 FrameInterpolation.CFINDEX.ID:			networkID, 
			 "platform":	MainNode.platform, 
			 "playercolour":MainNode.playercolour, 
			 "guardianpoly":MainNode.guardianpoly, 
			 "frameattributes":MainNode.framefilter.attributedefs }

func _player_connected(id):
	if networkID == -1:
		deferred_playerconnections.push_back(id)
		print("_player_connected remote=", id, "  **deferred")
	else:
		print("_player_connected remote=", id)
		assert (networkID >= 1)
		assert (not remoteplayertimeoffsets.has(id))
		remoteplayertimeoffsets[id] = RemoteTimeOffsetCalculator.new()
		print("players_connected_list: ", remoteplayertimeoffsets)
		rpc_id(id, "spawnremoteplayer", getplayerinfo())
	
func _player_disconnected(id):
	print("_player_disconnected remote=", id)
	assert (remoteplayertimeoffsets.has(id))
	remoteplayertimeoffsets.erase(id)
	print("players_connected_list: ", remoteplayertimeoffsets)
	PlayersNode.removeremoteplayer(id)

remote func spawnremoteplayer(pdat):
	var id = pdat[FrameInterpolation.CFINDEX.ID]
	assert (remoteplayertimeoffsets.has(id))
	var t1 = remoteplayertimeoffsets[id].ConvertToLocal(pdat[FrameInterpolation.CFINDEX.TIMESTAMP])
	PlayersNode.newremoteplayer(t1, id, pdat)
	
remote func gnextcompressedframe(cf):
	var id = cf[FrameInterpolation.CFINDEX.ID]
	var t1 = remoteplayertimeoffsets[id].ConvertToLocal(cf[FrameInterpolation.CFINDEX.TIMESTAMP])
	PlayersNode.nextcompressedframe(t1, id, cf)

func _process(delta):
	var ns = $NetworkOptionButton.selected
	if ns == NETWORK_OPTIONS.AS_SERVER:
		udpdiscoverybroadcasterperiodtimer -= delta
		if udpdiscoverybroadcasterperiodtimer < 0 and localipnumbers != "":
			var udpdiscoverybroadcaster = PacketPeerUDP.new()
			udpdiscoverybroadcaster.connect_to_host("255.255.255.255", udpdiscoveryport)
			udpdiscoverybroadcaster.put_packet(("OQServer: "+localipnumbers+" "+uniqueinstancestring).to_utf8())
			udpdiscoverybroadcaster.close()

			if networkID == 0:
				var networkedmultiplayerenetserver = NetworkedMultiplayerENet.new()
				var e = networkedmultiplayerenetserver.create_server(hostportnumber)
				if e == 0:
					get_tree().set_network_peer(networkedmultiplayerenetserver)
					networkID = get_tree().get_network_unique_id()
					assert (networkID == 1)
					$ColorRect.color = Color.green
				else:
					print("networkedmultiplayerenet createserver Error: ", {ERR_CANT_CREATE:"ERR_CANT_CREATE"}.get(e, e))
					print("*** is there a server running on this port already? ", hostportnumber)
					$ColorRect.color = Color.red
			udpdiscoverybroadcasterperiodtimer = udpdiscoverybroadcasterperiod

	elif (ns == NETWORK_OPTIONS.LOCAL_NETWORK) and (udpdiscoveryreceivingserver != null) and networkID == 0:
		udpdiscoveryreceivingserver.poll()
		if udpdiscoveryreceivingserver.is_connection_available():
			var peer = udpdiscoveryreceivingserver.take_connection()
			var pkt = peer.get_packet()
			var spkt = pkt.get_string_from_utf8().split(" ")
			print("Received: ", spkt, " from ", peer.get_packet_ip())
			if spkt[0] == "OQServer:":
				serverIPnumber = peer.get_packet_ip()

	if (ns == NETWORK_OPTIONS.LOCAL_NETWORK or ns == NETWORK_OPTIONS.FIXED_URL) and (serverIPnumber != "") and networkID == 0:
		var networkedmultiplayerenet = NetworkedMultiplayerENet.new()
		var e = networkedmultiplayerenet.create_client(serverIPnumber, hostportnumber, 0, 0)
		print("networkedmultiplayerenet createclient ", ("" if e else str(e)))
		get_tree().set_network_peer(networkedmultiplayerenet)
		$ColorRect.color = Color.yellow
		networkID = -1

func _on_OptionButton_item_selected(ns):
	if ns == NETWORK_OPTIONS.LOCAL_NETWORK:
		udpdiscoveryreceivingserver = UDPServer.new()
		udpdiscoveryreceivingserver.listen(udpdiscoveryport)

	elif udpdiscoveryreceivingserver != null:
		udpdiscoveryreceivingserver.stop()
		udpdiscoveryreceivingserver = null

	if ns == NETWORK_OPTIONS.FIXED_URL:
		serverIPnumber = $NetworkOptionButton.get_item_text(ns)

	if (ns != NETWORK_OPTIONS.AS_SERVER and networkID == 1):
		_server_disconnected()


