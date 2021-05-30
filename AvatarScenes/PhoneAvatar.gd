extends Spatial

onready var islocalplayer = (get_name() == "LocalPlayer")

const CFI_ORIGINTRANS_POS	= 100
const CFI_ORIGINTRANS_QUAT 	= 110

var platform = "phone"
var guardianpoly = PoolVector3Array([Vector3(1,0,1), Vector3(1,0,-1), Vector3(-1,0,-1), Vector3(-1,0,1)])
var osuniqueid = OS.get_unique_id()
var networkID = 0   # 0:unconnected, 1:server, -1:connecting, >1:connected to client

func processlocalavatarposition(delta):
	var gvec = Input.get_gravity()
	if gvec != Vector3(0,0,0):
		look_at(gvec*10, Vector3(0,1,0))

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

