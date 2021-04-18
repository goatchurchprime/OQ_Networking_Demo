class_name FI

# junk code to save for later
"""
enum CFI {
	ID 				= -2,
	TIMESTAMP 		= -1, 
	PREV_TIMESTAMP	= -3, 
	LOCAL_TIMESTAMP	= -4, 
		
	XRORIGIN		= 100,
	XRBASIS			= 101,
	XRCAMERAORIGIN	= 102,
	XRCAMERABASIS	= 103,
	XRLEFTORIGIN	= 104,
	XRLEFTBASIS		= 105,
	XRRIGHTORIGIN	= 106,
	XRRIGHTBASIS	= 107, 
	
	XRLEFTHANDROOT  = 200,
	XRLEFTHANDCONF  = 250,
	XRRIGHTHANDROOT = 300
	XRRIGHTHANDCONF = 350
}

static func QuattoV3(q):
	return Vector3(q.x, q.y, q.z)*(-1 if q.w < 0 else 1)
	
static func V3toQuat(v):
	return Quat(v.x, v.y, v.z, sqrt(max(0.0, 1.0 - v.length_squared())))


class FrameFilter:
	var attributenames = { }   # superfluous
	var attributedefs = { }
	var attributeprecisions = { }
	var currentvalues = { CFI.TIMESTAMP:0 }

	func _init(fiattributes):
		for i in fiattributes:
			var a = fiattributes[i]
			attributenames[i] = a["name"]
			attributedefs[i] = a["type"]
			attributeprecisions[i] = a["precision"]
			if a["type"] == "V3":
				currentvalues[i] = Vector3() 
			elif a["type"] == "Q" or a["type"] == "B":
				currentvalues[i] = Quat() 
			elif a["type"] == "F":
				currentvalues[i] = 0.0 
			else:
				assert (false)

	static func QuattoV3(q):
		return Vector3(q.x, q.y, q.z)*(-1 if q.w < 0 else 1)
			
	func CompressFrame(attributevalues, keepall):
		var cf = { }
		for i in attributevalues:
			var a = attributedefs[i]
			if a == "V3":
				var vdiff = attributevalues[i] - currentvalues[i]
				if keepall or vdiff.length() > attributeprecisions[i]:
					currentvalues[i] = attributevalues[i]
					cf[i] = attributevalues[i]
			elif a == "Q" or a == "B":
				var aq = attributevalues[i] if a == "Q" else attributevalues[i].get_rotation_quat()
				var qdiff = currentvalues[i] * aq.inverse()
				if keepall or 1 - qdiff.w > attributeprecisions[i]:
					currentvalues[i] = aq
					cf[i] = QuattoV3(aq)
			elif a == "F":
				var vdiff = attributevalues[i] - currentvalues[i]
				if keepall or vdiff > attributeprecisions[i]:
					currentvalues[i] = attributevalues[i]
					cf[i] = attributevalues[i]
		return cf
	

class FrameStack:
	var attributedefs = { }
	var valuestack = [ ]
	var mintimeshift = 0
	var furtherbacktime = 1.0
	const VALUESTACKMAXLENGTH = 60

	func _init(lattributedefs):
		attributedefs = lattributedefs
		var values0 = { CFI.TIMESTAMP: 0.0, CFI.LOCAL_TIMESTAMP: 0.0 }
		for i in attributedefs:
			var a = attributedefs[i]
			if a == "V3":
				values0[i] = Vector3()
			elif a == "Q" or a == "B":
				values0[i] = Quat() 
			elif a == "F":
				values0[i] = 0.0 
			else:
				assert (false)
		valuestack.push_back(values0)
		
	func dropfront():
		var values0 = valuestack.pop_front()
		for i in attributedefs:
			if valuestack[0].get(i) == null:
				valuestack[0][i] = values0[i]

	static func V3toQuat(v):
		return Quat(v.x, v.y, v.z, sqrt(max(0.0, 1.0 - v.length_squared())))
		
	func setinitialframe(pdat, tlocal):
		valuestack.clear()
		var values1 = { CFI.TIMESTAMP:pdat[CFI.TIMESTAMP], CFI.LOCAL_TIMESTAMP:tlocal }
		mintimeshift = tlocal - pdat[CFI.TIMESTAMP]
		print("initial mintimeshift:", mintimeshift)
		for i in attributedefs:
			var a = attributedefs[i]
			if i in pdat:
				var v1 = pdat[i]
				if a == "Q" or a == "B":
					v1 = V3toQuat(v1)
				values1[i] = v1
		valuestack.push_back(values1)
		
	func expandappendframe(cf, tlocal):
		if cf.has(CFI.PREV_TIMESTAMP) and valuestack[-1][CFI.TIMESTAMP] != cf[CFI.PREV_TIMESTAMP]:
			var t1p = cf[CFI.PREV_TIMESTAMP]
			#assert (t1p > valuestack[-1][CFI.TIMESTAMP])
			#assert (t1p < cf[CFI.TIMESTAMP])
			valuestack.push_back({ CFI.TIMESTAMP:t1p })
		var values1 = { CFI.TIMESTAMP:cf[CFI.TIMESTAMP], CFI.LOCAL_TIMESTAMP:tlocal }

		var timeshift = tlocal - cf[CFI.TIMESTAMP]
		if timeshift < mintimeshift:
			mintimeshift = timeshift
			print("mintimeshift to:", timeshift)
		
		for i in attributedefs:
			var a = attributedefs[i]
			if i in cf:
				var v1 = cf[i]
				if a == "Q" or a == "B":
					v1 = V3toQuat(v1)
				values1[i] = v1
		valuestack.push_back(values1)
		while len(valuestack) > VALUESTACKMAXLENGTH:
			dropfront()
		
	func interpolatevalues(t):
		while len(valuestack) >= 2 and valuestack[1][CFI.TIMESTAMP] <= t:
			dropfront()
		var attributevalues = { }
		var values0 = valuestack[0]
		if len(valuestack) == 1 or t < values0[CFI.TIMESTAMP]:
			for i in attributedefs:
				var a = attributedefs[i]
				var v = values0[i]
				if a == "B":
					v = Basis(v)
				attributevalues[i] = v
		else:
			var values1 = valuestack[1]
			var lam = inverse_lerp(values0[CFI.TIMESTAMP], values1[CFI.TIMESTAMP], t)
			for i in attributedefs:
				var a = attributedefs[i]
				var v0 = values0[i]
				var v1 = values1.get(i)
				var v = v0
				if (a == "V3" or a == "F") and v1 != null:
					v = lerp(v0, v1, lam)
				elif a == "Q" and v1 != null:
					v = v0.slerp(v1, lam)
				elif a == "B" and v1 != null:
					v = Basis(v0.slerp(v1, lam))
				attributevalues[i] = v
		return attributevalues


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
	if keepall or ($OQ_ARVROrigin/OQ_LeftController.visible and $OQ_ARVROrigin/OQ_LeftController.has_node("Feature_HandModel_Left") and 
			$OQ_ARVROrigin/OQ_LeftController/Feature_HandModel_Left.model.visible):
		fd[FI.CFI.XRLEFTHANDCONF] = $OQ_ARVROrigin/OQ_LeftController/Feature_HandModel_Left.tracking_confidence
		for i in range(24):
			fd[FI.CFI.XRLEFTHANDROOT+i] = $OQ_ARVROrigin/OQ_LeftController/Feature_HandModel_Left._vrapi_bone_orientations[i]
		#print("finger ", fd[FI.CFI.XRLEFTHANDROOT+10])
	else:
		fd[FI.CFI.XRLEFTHANDCONF] = 0.0
	return fd


	
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

		if $RemotePlayers.has_node("DDoppelganger"):
			cf[FI.CFI.TIMESTAMP] += doppelgangertimeoffset
			cf[FI.CFI.PREV_TIMESTAMP] += doppelgangertimeoffset
			var dnetdelay = NetworkGateway.get_node("DoppelgangerPanel/Netdelay").value*0.001
			var dnetdroprate = NetworkGateway.get_node("DoppelgangerPanel/Netdelay").value/1000
			var simulatednetworkdelay = rand_range(dnetdelay,dnetdelay*2)
			if len(doppelgangerdelaystack) < doppelgangerdelaystackmaxsize and rand_range(0, 1) >= dnetdroprate:
				doppelgangerdelaystack.push_back([cumulativetime + simulatednetworkdelay, cf])


	framefilter.currentvalues[FI.CFI.TIMESTAMP] = tstamp



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
	
	
	networkID
	pdat[FI.CFI.ID] = networkID 

	playerframestacks[nname].setinitialframe(pdat, tlocal)


var framerateratereducer = 5
var framecount = 0
var doppelgangertimeoffset = 10.0
var doppelgangerdelaystack = [ ]
const doppelgangerdelaystackmaxsize = 100
"""
