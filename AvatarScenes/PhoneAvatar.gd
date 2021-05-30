extends Spatial

onready var islocalplayer = (get_name() == "LocalPlayer")

const CFI_ORIGINTRANS_POS	= 100
const CFI_ORIGINTRANS_QUAT 	= 110

var platform = "phone"
var guardianpoly = PoolVector3Array([Vector3(1,0,1), Vector3(1,0,-1), Vector3(-1,0,-1), Vector3(-1,0,1)])
var osuniqueid = OS.get_unique_id()
var networkID = 0   # 0:unconnected, 1:server, -1:connecting, >1:connected to client

var screenpresses = { }
var mousepressLeft = null
func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			screenpresses[event.index] = event.position
		else:
			screenpresses.erase(event.index)
	elif event is InputEventScreenDrag and screenpresses.has(event.index):
		screenpresses[event.index] = event.position

	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				screenpresses[0] = event.position
			else:
				screenpresses.erase(0)
	elif event is InputEventMouseMotion:
		if screenpresses.has(0):
			screenpresses[0] = event.position

var screenpos0 = null
var screenpos1 = null
func processlocalavatarposition(delta):
	#var gvec = Input.get_gravity()
	#if gvec != Vector3(0,0,0):
	#	look_at(gvec*10, Vector3(0,1,0))

	var prevscreenpos0 = screenpos0
	var prevscreenpos1 = screenpos1
	screenpos0 = screenpresses.get(0)
	screenpos1 = screenpresses.get(1)
	if prevscreenpos0 != null and prevscreenpos1 != null and screenpos0 != null and screenpos1 != null:
		var pl = (prevscreenpos1 - prevscreenpos0).length()
		var l = (screenpos1 - screenpos0).length()
		if l > 50 and pl > 50:
			var r = (l/pl - 1.0)*2.0
			transform.origin += (-r)*transform.basis.z

	elif prevscreenpos0 != null and screenpos0 != null:
		var v = screenpos0 - prevscreenpos0
		if v != Vector2(0,0):
			rotation_degrees.x += v.y*0.1
			rotation_degrees.y += v.x*0.1

			

func avatartoframedata():
	var fd = { CFI_ORIGINTRANS_POS:	transform.origin,
			   CFI_ORIGINTRANS_QUAT:transform.basis.get_rotation_quat()
			 }
	return fd
	
func framedatatoavatar(fd):
	transform = Transform(fd[CFI_ORIGINTRANS_QUAT], fd[CFI_ORIGINTRANS_POS])

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

