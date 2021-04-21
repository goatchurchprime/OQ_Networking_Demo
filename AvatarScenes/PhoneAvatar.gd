extends Spatial

onready var islocalplayer = (get_name() == "LocalPlayer")

var platform = "phone"
var guardianpoly = PoolVector3Array([Vector3(1,0,1), Vector3(1,0,-1), Vector3(-1,0,-1), Vector3(-1,0,1)])
var osuniqueid = OS.get_unique_id()
var networkID = 0   # 0:unconnected, 1:server, -1:connecting, >1:connected to client

func _process(delta):
	if islocalplayer:
		var gvec = Input.get_gravity()
		if gvec != Vector3(0,0,0):
			look_at(gvec*10, Vector3(0,1,0))

remote func networkedavatarframedata(fd):
	transform = fd["phoneslabtrans"]

func avatarinitdata():
	var avatardata = { "playernodename":get_name(),
					   "platform":platform, 
					   "avatarsceneresource":filename, 
					   "osuniqueid":osuniqueid, 
					   "networkid":networkID
					 }
	return avatardata

func initavatar(avatardata):
	set_name(avatardata["playernodename"])
	platform = avatardata["platform"]
	osuniqueid = avatardata["osuniqueid"]
	networkID = avatardata["networkid"]

var framedividerVal = 5
var framedividerCount = framedividerVal
func _physics_process(delta):
	var tstamp = OS.get_ticks_msec()*0.001
	framedividerCount -= 1
	if framedividerCount > 0:
		return
	framedividerCount = framedividerVal
	if not islocalplayer:
		return
	if networkID >= 1:
		var fd = { "phoneslabtrans":transform }
		rpc("networkedavatarframedata", fd)
