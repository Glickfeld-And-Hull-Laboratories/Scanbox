#scanknob_sa.y - by Dario Ringach

#To be used only when the 3D mouse is present

import serial, io, sys, binascii, time
from struct import *
import numpy as np
import win32gui, win32con

w = win32gui.GetForegroundWindow() # minimize the window...
win32gui.ShowWindow(w, win32con.SW_MINIMIZE)

#memory mapping position of motors for Matlab

print "Welcome to ScanKnob 1.0 Console (dlr)"

f_pos = sys.argv[1]
f_cmd = sys.argv[2]

fpos = np.memmap(f_pos, dtype='int32', mode='readwrite',shape=(1,5))	# flag + 4 long positions
fcmd = np.memmap(f_cmd, dtype='uint8',mode='readwrite',shape=(1,10))	# flag + 9 cmd bytes

ser = serial.Serial(sys.argv[3],57600)  	# this is the Trinamic boad

TMCL_cmd = {'ROR':   1,				# commands
        'ROL':   2,
        'MST':   3,
        'MVP':   4,
        'SAP':   5,
        'GAP':   6,
        'STAP':  7,
        'RSAP':  8,
        'SGP':   9,
        'GGP':  10,
        'STGP': 11,
        'RSGP': 12,
        'RFS':  13,
        'SIO':  14,
        'GIO':  15,
        'SCO':  30,
        'GCO':  31,
        'CCO':  32,
        'STP':	128,
        'RUN':	129,
        'GAS':	135}

def TriCmd(command, cmd_type, motor, value):
	Tx = bytearray(9)
	if value < 0:
		value += 4294967296
	Tx[0] = 1
	Tx[1] = TMCL_cmd[command]
	Tx[2] = cmd_type
	Tx[3] = motor
	for i in range(0,4):					#compute each byte from value 
		Tx[7-i] = (value>>(8*i)) & 0x0ff
	Tx[8] = sum(Tx[0:8]) & 0x0ff			#checksum
	ser.write(Tx)
	r = bytearray(ser.read(9))				#wait for response
	return(unpack('>BBBBlB',r))				#unpack the reply	

# Application starts here...

print "Initializing..."

TriCmd('STP',0,0,0) 				# stop application
TriCmd('RUN',1,0,0) 				#run the program from 0 [0=nop, 1=align, 2=track, 3=wait]

mode = 0							#tmcl mode

fcmd[0,0]= 0

while True:

	if fcmd[0,0]>0 :						    # there is a command from Scanbox waiting!

		if mode != 0:							# go to NOP mode
			TriCmd('RUN',1,0,0);
			mode = 0 

		ser.write(bytearray(fcmd[0,1:]))				
		r = bytearray(ser.read(9))				#wait for response
		fcmd[0,1:] = r							#send it back
		fcmd[0,0] = 0                              