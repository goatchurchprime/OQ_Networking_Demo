class_name FI

enum CFI {
	ID 				= -2,
	TIMESTAMP 		= -1, 
	PREV_TIMESTAMP	= -3, 
	LOCAL_TIMESTAMP	= -4, 
		
	XRORIGIN		= 0,
	XRBASIS			= 1,
	XRCAMERAORIGIN	= 2,
	XRCAMERABASIS	= 3,
	XRLEFTORIGIN	= 4,
	XRLEFTBASIS		= 5,
	XRRIGHTORIGIN	= 6,
	XRRIGHTBASIS	= 7
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
			else:
				assert (false)

	static func QuattoV3(q):
		return Vector3(q.x, q.y, q.z)*(-1 if q.w < 0 else 1)
	
			
	func CompressFrame(attributevalues, keepall):
		var cf = { }
		for i in attributedefs:
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
			for i in range(len(attributedefs)):
				var a = attributedefs[i]
				var v0 = values0[i]
				var v1 = values1.get(i)
				var v = v0
				if a == "V3" and v1 != null:
					v = lerp(v0, v1, lam)
				elif a == "Q" and v1 != null:
					v = v0.slerp(v1, lam)
				elif a == "B" and v1 != null:
					v = Basis(v0.slerp(v1, lam))
				attributevalues[i] = v
		return attributevalues
