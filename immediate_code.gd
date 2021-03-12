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

func _run():
	var a = "asdasd1 2v 12"
	print(a.split(" ", 1)[0])
	print(a)
	
