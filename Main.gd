extends Spatial

export var vrenabled = true

var platform = ""
var playercolour = Color(1.0, 1.0, 1.0)
var guardianpoly = PoolVector3Array([Vector3(1,0,1), Vector3(1,0,-1), Vector3(-1,0,-1), Vector3(-1,0,1)])

var framefilter = null

onready var NetworkGateway = $OQ_VisibilityToggle/OQ_UI2DCanvas.ui_control

func _ready():
	var fiattributes = { 
		FI.CFI.XRORIGIN:		{"name":"xrorigin", "type":"V3", "precision":0.002},
		FI.CFI.XRBASIS:			{"name":"xrbasis",  "type":"B",  "precision":0.005}, 
		FI.CFI.XRCAMERAORIGIN:	{"name":"xrcameraorigin", "type":"V3", "precision":0.002}, 
		FI.CFI.XRCAMERABASIS:	{"name":"xrcamerabasis",  "type":"B",  "precision":0.005},
		FI.CFI.XRLEFTORIGIN:	{"name":"xrleftorigin", "type":"V3", "precision":0.002}, 
		FI.CFI.XRLEFTBASIS:		{"name":"xrleftbasis",  "type":"B",  "precision":0.005}, 
		FI.CFI.XRRIGHTORIGIN:	{"name":"xrrightorigin", "type":"V3", "precision":0.002}, 
		FI.CFI.XRRIGHTBASIS:	{"name":"xrrightbasis",  "type":"B",  "precision":0.005}, 
	}
	fiattributes[FI.CFI.XRLEFTHANDCONF] = {"name":"xrlefthandconfidence", "type":"F", "precision":0.1}
	#fiattributes[FI.CFI.XRRIGHTHANDCONF] = {"name":"xrrighthandconfidence", "type":"F", "precision":0.1}
	for i in range(24):
		fiattributes[FI.CFI.XRLEFTHANDROOT+i] = {"name":"xrlefthandbone%d"%i, "type":"Q", "precision":0.002}
		#fiattributes[FI.CFI.XRRIGHTHANDROOT+i] = {"name":"xrrighthandbone%d"%i, "type":"Q", "precision":0.002}
	framefilter = FI.FrameFilter.new(fiattributes)

	randomize()
	$OQ_ARVROrigin.transform.origin.x += rand_range(-3, 3)
	$OQ_ARVROrigin.transform.origin.z += rand_range(-1, 1)
	playercolour = Color.from_hsv(rand_range(0, 1), rand_range(0.5, 0.86), 0.75)
	print(ARVRServer.get_interfaces())
	if OS.has_feature("Server"):
		vrenabled = false
		platform = "Server"
		playercolour = Color(0.01, 0.01, 0.05)
	elif ARVRServer.find_interface("OVRMobile"):
		platform = "OVRMobile"
		vrenabled = true
	elif vrenabled and ARVRServer.find_interface("Oculus"):
		platform = "Oculus"
	elif vrenabled and ARVRServer.find_interface("OpenVR"):
		platform = "OpenVR"
	else:
		platform = "Pancake"
	if vrenabled:
		vr.initialize()
		if not vr.inVR:
			platform = "Pancake"


func playerframedata(keepall):
	var fd = { 
		FI.CFI.XRORIGIN:		$OQ_ARVROrigin.transform.origin,
		FI.CFI.XRBASIS:			$OQ_ARVROrigin.transform.basis, 
		FI.CFI.XRCAMERAORIGIN:	$OQ_ARVROrigin/OQ_ARVRCamera.transform.origin, 
		FI.CFI.XRCAMERABASIS:	$OQ_ARVROrigin/OQ_ARVRCamera.transform.basis,
		FI.CFI.XRLEFTORIGIN:	$OQ_ARVROrigin/OQ_LeftController.transform.origin, 
		FI.CFI.XRLEFTBASIS:		$OQ_ARVROrigin/OQ_LeftController.transform.basis, 
		FI.CFI.XRRIGHTORIGIN:	$OQ_ARVROrigin/OQ_RightController.transform.origin, 
		FI.CFI.XRRIGHTBASIS:	$OQ_ARVROrigin/OQ_RightController.transform.basis 
	}
	if keepall or ($OQ_ARVROrigin/OQ_LeftController.visible and $OQ_ARVROrigin/OQ_LeftController.has_node("Feature_HandModel_Left") and \
			$OQ_ARVROrigin/OQ_LeftController/Feature_HandModel_Left.model.visible):
		fd[FI.CFI.XRLEFTHANDCONF] = $OQ_ARVROrigin/OQ_LeftController/Feature_HandModel_Left.tracking_confidence
		for i in range(24):
			fd[FI.CFI.XRLEFTHANDROOT+i] = $OQ_ARVROrigin/OQ_LeftController/Feature_HandModel_Left._vrapi_bone_orientations[i]
#		print("finger ", fd[FI.CFI.XRLEFTHANDROOT+10])
	else:
		fd[FI.CFI.XRLEFTHANDCONF] = 0.0
	return fd


func playerinitdata():
	var tstamp = OS.get_ticks_msec()*0.001
	var pdat = framefilter.CompressFrame(playerframedata(true), true)
	pdat[FI.CFI.TIMESTAMP] = tstamp
	pdat[FI.CFI.PREV_TIMESTAMP] = tstamp
	pdat["platform"]  = platform
	pdat["playercolour"] = playercolour
	pdat["guardianpoly"] = guardianpoly
	pdat["frameattributes"] = framefilter.attributedefs
	return pdat
		
var framerateratereducer = 5
var framecount = 0
var doppelgangertimeoffset = 10.0
var doppelgangerdelaystack = [ ]
const doppelgangerdelaystackmaxsize = 100
var cumulativetime = 0.0
func _physics_process(delta):
	cumulativetime += delta
	var tstamp = OS.get_ticks_msec()*0.001

	while len(doppelgangerdelaystack) != 0 and doppelgangerdelaystack[0][0] < cumulativetime:
		var dcf = doppelgangerdelaystack.pop_front()[1]
		$RemotePlayers.nextcompressedframe("Doppelganger", dcf, tstamp)

	framecount += 1
	if framerateratereducer != 0 and (framecount%framerateratereducer) != 0:
		return
		
	var cf = framefilter.CompressFrame(playerframedata(false), false)
	if len(cf) != 0:
		cf[FI.CFI.TIMESTAMP] = tstamp
		cf[FI.CFI.PREV_TIMESTAMP] = framefilter.currentvalues[FI.CFI.TIMESTAMP]
		if NetworkGateway.networkID > 0:
			cf[FI.CFI.ID] = NetworkGateway.networkID
			NetworkGateway.rpc("gnextcompressedframe", cf)

		if $RemotePlayers.has_node("Doppelganger"):
			cf[FI.CFI.TIMESTAMP] += doppelgangertimeoffset
			cf[FI.CFI.PREV_TIMESTAMP] += doppelgangertimeoffset
			var dnetdelay = NetworkGateway.get_node("DoppelgangerPanel/Netdelay").value*0.001
			var dnetdroprate = NetworkGateway.get_node("DoppelgangerPanel/Netdelay").value/1000
			var simulatednetworkdelay = rand_range(dnetdelay,dnetdelay*2)
			if len(doppelgangerdelaystack) < doppelgangerdelaystackmaxsize and rand_range(0, 1) >= dnetdroprate:
				doppelgangerdelaystack.push_back([cumulativetime + simulatednetworkdelay, cf])



	framefilter.currentvalues[FI.CFI.TIMESTAMP] = tstamp
