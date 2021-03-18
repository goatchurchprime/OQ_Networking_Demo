tool
extends EditorScript

# *******
# Control-Shift X to run this code in the editor
# *******

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

const _vrapi2hand_bone_map = [0, 23,  1, 2, 3, 4,  6, 7, 8,  10, 11, 12,  14, 15, 16, 18, 19, 20, 21];

func _run():
	print(len(_vrapi2hand_bone_map))
	
