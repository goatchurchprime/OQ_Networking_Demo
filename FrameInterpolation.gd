class_name FrameInterpolation

enum CFINDEX {
	ID = -2,
	TIMESTAMP = -1
}

class FrameFilter:
	var attributenames = [ ]
	var attributedefs = [ ]
	var attributeprecisions = [ ]
	var currentvalues = [ ]

	func _init(attributes):
		for a in attributes:
			attributenames.push_back(a["name"])
			attributedefs.push_back(a["type"])
			attributeprecisions.push_back(a["precision"])
			if a["type"] == "V3":
				currentvalues.push_back(Vector3()) 
			elif a["type"] == "Q" or a["type"] == "B":
				currentvalues.push_back(Quat()) 
			else:
				assert (false)
			
	func CompressFrame(attributevalues, keepall):
		var cf = { }
		for i in range(len(attributedefs)):
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
					var q = aq
					if q.w < 0:
						q = -q
					cf[i] = Vector3(q.x, q.y, q.z)
		return cf
	
	
class FrameStack:
	var attributedefs = [ ]
	var valuestack = [ ]
	const valuestackmaxlength = 60

	func _init(lattributedefs):
		attributedefs = lattributedefs
		var values0 = [ 0 ]
		for a in attributedefs:
			if a == "V3":
				values0.push_back(Vector3()) 
			elif a == "Q" or a == "B":
				values0.push_back(Quat()) 
			else:
				assert (false)
		valuestack.push_back(values0)
		
	func dropfront():
		var values0 = valuestack.pop_front()
		for i in range(len(attributedefs)):
			if valuestack[0][i+1] == null:
				valuestack[0][i+1] = values0[i+1]
		
	func expandappendframe(t1, cf):
		var values1 = [ t1 ]
		for i in range(len(attributedefs)):
			assert (len(values1) == i+1)
			var a = attributedefs[i]
			if i in cf:
				var v1 = cf[i]
				if a == "Q" or a == "B":
					v1 = Quat(v1.x, v1.y, v1.z, sqrt(max(0.0, 1.0 - v1.length_squared())))
				values1.push_back(v1)
				var j0 = len(valuestack) - 1
				if valuestack[j0][i+1] == null:
					while valuestack[j0][i+1] == null:
						j0 -= 1
					var t0 = valuestack[j0][0]
					var v0 = valuestack[j0][i+1]
					for j in range(j0+1, len(valuestack)):
						var lam = inverse_lerp(t0, t1, valuestack[j][0])
						var v = lerp(v0, v1, lam) if a == "V3" else v0.slerp(v1, lam)
						valuestack[j][i+1] = v
			else:
				values1.push_back(null)
		valuestack.push_back(values1)
		while len(valuestack) > valuestackmaxlength:
			dropfront()
		
	func interpolatevalues(t):
		while len(valuestack) >= 2 and valuestack[1][0] <= t:
			dropfront()
		var attributevalues = [ ]
		var values0 = valuestack[0]
		assert (values0[0] <= t)
		if len(valuestack) == 1 or t < values0[0]:
			for i in range(len(attributedefs)):
				var a = attributedefs[i]
				var v = values0[i+1]
				if a == "B":
					v = Basis(v)
				attributevalues.push_back(v)
		else:
			var values1 = valuestack[1]
			var lam = inverse_lerp(values0[0], values1[0], t)
			for i in range(len(attributedefs)):
				var a = attributedefs[i]
				var v0 = values0[i+1]
				var v1 = values1[i+1]
				var v = v0
				if a == "V3" and v1 != null:
					v = lerp(v0, v1, lam)
				elif a == "Q" and v1 != null:
					v = v0.slerp(v1, lam)
				elif a == "B" and v1 != null:
					v = Basis(v0.slerp(v1, lam))
				attributevalues.push_back(v)
		return attributevalues
