# OQ_Networking_Demo

Networking VR players using OQ toolkit to force reuse of code

# Installation Instructions

The main dependency is on the `Oculus Quest VR Toolkit`:
   https://github.com/NeoSpark314/godot_oculus_quest_toolkit/tree/master/OQ_Toolkit

The source code of this is small, so it has been duplicated into this repository

The other dependencies you need to fetch from the AssetLib in order to run this 
are `Godot Oculus Mobile Plugin` and `OpenVR module`  

Fetch these, but only install the parts that are in the `addons` directory.

# Deployment instructions:

If you want to run this on a PC without VR being initialized, look for the `Vrenabled` flag 
on the `Main` node.  You can easily toggle between the options on the dropdown menu by hitting 
1 for server mode, 2 for local networ, and 3 to connect to the `tunnelvr.godot.org.uk`.  

This last one is what you connect to if you want to demonstrate connecting between computers on 
on different local area networks.

To install onto the tunnelvr.goatchurch.org.uk server (or any other linux box on the net), 
use a screen instance and do:

> wget https://github.com/goatchurchprime/OQ_Networking_Demo/releases/download/v0.1.1/OQ_Networking_Demo.pck

> ./Godot_v3.2.3-stable_linux_headless.64 --main-pack OQ_Networking_Demo.pck


When running you can select server mode or leave as local network mode and it will discover 
a local server instance using UDP broadcasting.

Or connect to a global server like tunnelvr.goatchurch.org.uk

Your motions will be compressed and delayed by one second for the moment.

# Local testing

The Doppelganger option (hit G on the keyboard) collects your motions and replays them to an avatar copy without 
going through the network.  It is intended to simulate delayed and dropped packets to test the 
robustness of the interpolation algorithms.

You can also run this between two devices on the same local area network without a server out on the internet.  
To do this select Connection: "As server" (key=1 if you are running not in VR) on one of them.
This will broadcast a message on 255.255.255.255 to be picked up by the other running app, where you have done Connection: "Local network" 
(key=2 from a keyboard).  When they discover each other this will be replaced by the ip number of the server instance.  



  
