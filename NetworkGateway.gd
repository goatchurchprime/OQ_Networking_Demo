extends Panel


export var hostportnumber : int = 4546
var players_connected_list = [ ]
var deferred_players_connected_list = [ ]
var serverIPnumber = "----"
var connectedtoserver = false
var networkID = 0
onready var MainNode = get_node("/root/Main")
onready var PlayersNode = get_node("/root/Main/Players")

# mosquitto_sub -h mosquitto.doesliverpool.xyz -v -t "godot/#"

func _ready():
	$UniqueID_Value.set_text(OS.get_unique_id());
	get_tree().connect("network_peer_connected", 	self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")

	get_tree().connect("connected_to_server", 		self, "_connected_to_server")
	get_tree().connect("connection_failed", 		self, "_connection_failed")
	get_tree().connect("server_disconnected", 		self, "_server_disconnected")

	if OS.has_feature("Server"):
		yield(get_tree().create_timer(2.5), "timeout")
		$Server_Button.pressed = true
	else:
		$mqtt.establishconnection("godot/client/"+$mqtt.client_id, "connected", "disconnected", "godot/server/1")

func getIPnumber():
	print("IP local interfaces: ")
	var ipnumres = ""
	for k in IP.get_local_interfaces():
		var ipnum = ""
		for l in k["addresses"]:
			if l.find(".") != -1:
				ipnum = l
		print(k["friendly"] + ": " + ipnum)
		if k["friendly"] == "Wi-Fi" or k["friendly"].begins_with("wlan"):
			ipnumres = ipnum
		elif k["friendly"] == "Ethernet" and ipnumres == "":
			ipnumres = ipnum
	return ipnumres

func _on_Server_Button_toggled(button_pressed):
	if button_pressed:
		var networkedmultiplayerenet = NetworkedMultiplayerENet.new()
		var e = networkedmultiplayerenet.create_server(hostportnumber)
		if e == 0:
			get_tree().set_network_peer(networkedmultiplayerenet)
			var ipnumber = getIPnumber()
			var ipaddress = "%s:%d"%[ipnumber, hostportnumber]
			$IPnumber_Value.set_text(ipaddress)
			$mqtt.establishconnection("godot/server/1", ipaddress, "----", "")
			connectedtoserver = true
			networkID = get_tree().get_network_unique_id()
		else:
			print("networkedmultiplayerenet createserver Error: ", {ERR_CANT_CREATE:"ERR_CANT_CREATE"}.get(e, e))
			print("*** is there a server running on this port already? ", hostportnumber)
			$IPnumber_Value.set_text("server error")
			$Server_Button.pressed = false   # this causes it to call _on_Server_Button_toggled(false)

	else:
		while players_connected_list:
			_player_disconnected(players_connected_list[-1])
		if get_tree().get_network_peer() != null:
			get_tree().get_network_peer().close_connection()
			get_tree().set_network_peer(null)
			$IPnumber_Value.set_text("server off")
		connectedtoserver = false
		networkID = get_tree().get_network_unique_id()
		$mqtt.establishconnection("godot/client/"+$mqtt.client_id, "connected", "disconnected", "godot/server/1")
		

func _on_mqtt_received_message(topic, message):
	print("MQTT RECEIVED: ", topic, ": ", message)
	if topic == "godot/server/1":
		var sm = message.split(":")
		if len(sm) == 2:
			serverIPnumber = sm[0]
			hostportnumber = int(sm[1])
		else:
			serverIPnumber = message
		if serverIPnumber.is_valid_ip_address():
			if $Server_Button.pressed:
				$Server_Button.pressed = false
			$Server_Button.visible = false
			$Client_Button.visible = true
		else:
			if $Client_Button.pressed:
				$Client_Button.pressed = false
			$Client_Button.visible = false
			$Server_Button.visible = true
		$IPnumber_Value.set_text(message)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_N:
			if $Server_Button.visible:
				$Server_Button.pressed = not $Server_Button.pressed
			if $Client_Button.visible:
				$Client_Button.pressed = not $Client_Button.pressed

func _on_Client_Button_toggled(button_pressed):
	if button_pressed:
		if serverIPnumber.is_valid_ip_address():
			var networkedmultiplayerenet = NetworkedMultiplayerENet.new()
			var e = networkedmultiplayerenet.create_client(serverIPnumber, hostportnumber, 0, 0)
			print("networkedmultiplayerenet createclient ", ("" if e else str(e)))
			get_tree().set_network_peer(networkedmultiplayerenet)
	elif get_tree().get_network_peer() != null:
		get_tree().get_network_peer().close_connection()
		_server_disconnected()

func _server_disconnected():
	$Client_Button.pressed = false
	connectedtoserver = false
	get_tree().set_network_peer(null)
	while players_connected_list:
		_player_disconnected(players_connected_list[-1])
	networkID = get_tree().get_network_unique_id()
	deferred_players_connected_list.clear()
	print("*** _server_disconnected ", networkID)
	
func _connected_to_server():
	networkID = get_tree().get_network_unique_id()
	connectedtoserver = true
	print("_connected_to_server: ", networkID)
	PlayersNode.rpc("spawnotherplayer", getplayerinfo())
	while len(deferred_players_connected_list) != 0:
		print("deferred_players_connected_list ", deferred_players_connected_list)
		_player_connected(deferred_players_connected_list.pop_back())

func _connection_failed():
	print("_connection_failed ", networkID)
	assert (not connectedtoserver)
	networkID = get_tree().get_network_unique_id()
	deferred_players_connected_list.clear()
	$Client_Button.pressed = false 

func getplayerinfo():
	return { "networkID":networkID, "platform":MainNode.platform, "playercolour":MainNode.playercolour, "guardianpoly":MainNode.guardianpoly }

func _player_connected(id):
	print("_player_connected ", id)
	if networkID == 0:
		deferred_players_connected_list.push_back(id)
		print("  deferred")
	else:
		assert (connectedtoserver)
		players_connected_list.push_back(id)
		print("players_connected_list: ", players_connected_list)
		PlayersNode.rpc_id(id, "spawnotherplayer", getplayerinfo())

func _player_disconnected(id):
	print("_player_disconnected ", id)
	players_connected_list.erase(id)
	print("players_connected_list: ", players_connected_list)
	PlayersNode.removeotherplayer(id)
