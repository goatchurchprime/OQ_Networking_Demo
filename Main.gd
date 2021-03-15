extends Spatial

export var vrenabled = true
var platform = ""
var playercolour = Color(1.0, 1.0, 1.0)
var guardianpoly = PoolVector3Array([Vector3(1,0,1), Vector3(1,0,-1), Vector3(-1,0,-1), Vector3(-1,0,1)])

var ovr_init_config = null
var ovr_performance = null
var ovr_hand_tracking = null
var ovr_guardian_system = null

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
var framefilter = FI.FrameFilter.new(fiattributes)

onready var NetworkGateway = $OQ_ARVROrigin/OQ_LeftController/OQ_VisibilityToggle/OQ_UI2DCanvas.ui_control
func _ready():
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
		elif platform == "OVRMobile":
			ovr_init_config = load("res://addons/godot_ovrmobile/OvrInitConfig.gdns").new()
			ovr_performance = load("res://addons/godot_ovrmobile/OvrPerformance.gdns").new()
			ovr_hand_tracking = load("res://addons/godot_ovrmobile/OvrHandTracking.gdns").new();
			ovr_guardian_system = load("res://addons/godot_ovrmobile/OvrGuardianSystem.gdns").new();
			guardianpoly = ovr_guardian_system.get_boundary_geometry()

func playerframedata():
	return { 
		FI.CFI.XRORIGIN:		$OQ_ARVROrigin.transform.origin,
		FI.CFI.XRBASIS:			$OQ_ARVROrigin.transform.basis, 
		FI.CFI.XRCAMERAORIGIN:	$OQ_ARVROrigin/OQ_ARVRCamera.transform.origin, 
		FI.CFI.XRCAMERABASIS:	$OQ_ARVROrigin/OQ_ARVRCamera.transform.basis,
		FI.CFI.XRLEFTORIGIN:	$OQ_ARVROrigin/OQ_LeftController.transform.origin, 
		FI.CFI.XRLEFTBASIS:		$OQ_ARVROrigin/OQ_LeftController.transform.basis, 
		FI.CFI.XRRIGHTORIGIN:	$OQ_ARVROrigin/OQ_RightController.transform.origin, 
		FI.CFI.XRRIGHTBASIS:	$OQ_ARVROrigin/OQ_RightController.transform.basis 
	}
	
func playerinitdata():
	var tstamp = OS.get_ticks_msec()*0.001
	var pdat = framefilter.CompressFrame(playerframedata(), true)
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
		
	var cf = framefilter.CompressFrame(playerframedata(), false)
	if len(cf) != 0:
		cf[FI.CFI.TIMESTAMP] = tstamp
		cf[FI.CFI.PREV_TIMESTAMP] = framefilter.currentvalues[FI.CFI.TIMESTAMP]
		if NetworkGateway.networkID > 0:
			cf[FI.CFI.ID] = NetworkGateway.networkID
			NetworkGateway.rpc("gnextcompressedframe", cf)

		if $RemotePlayers.has_node("Doppelganger"):
			cf[FI.CFI.TIMESTAMP] += doppelgangertimeoffset
			cf[FI.CFI.PREV_TIMESTAMP] += doppelgangertimeoffset
			var simulatednetworkdelay = 0.1 + rand_range(0,delta/2)
			if len(doppelgangerdelaystack) < 10:
				doppelgangerdelaystack.push_back([cumulativetime + simulatednetworkdelay, cf])

	framefilter.currentvalues[FI.CFI.TIMESTAMP] = tstamp
