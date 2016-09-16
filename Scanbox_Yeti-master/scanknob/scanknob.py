#scanknob.y - by Dario Ringach

import serial, io, sys, binascii, time
from struct import *
import numpy as np
import win32gui, win32con

w = win32gui.GetForegroundWindow() # minimize the window...
win32gui.ShowWindow(w, win32con.SW_MINIMIZE)

#argv[1] - position file
#argv[2] - command file
#argv[3] - Trinamic board serial port
#argv[4] - Arduino Yun in ScanKnob box

print "Welcome to ScanKnob 1.0 Console (dlr)"

#memory mapping position of motors for Matlab

f_pos = sys.argv[1]
f_cmd = sys.argv[2]

print "Memory mapped files"
fpos = np.memmap(f_pos, dtype='int32', mode='readwrite',shape=(1,5))	# flag + 4 long positions
fcmd = np.memmap(f_cmd, dtype='uint8',mode='readwrite',shape=(1,10))	# flag + 9 cmd bytes

print "Serial ports"

ser = serial.Serial(sys.argv[3],57600)  	# this is the Trinamic boad
ard = serial.Serial(sys.argv[4],57600) 		# arduino	

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


def updateOrigin():						# updates origin
	for motor in range(0,4):
		r=TriCmd('GAP',1,motor,0) 	
		origin[motor+1] = r[4]

def updatePos():						# updates pos
	flag = False
	for motor in range(0,4):
		r=TriCmd('GAP',1,motor,0)		# update  position
		flag = flag or (r[4] != pos[motor+1]) 	
		pos[motor+1] = r[4]
	return flag

def originToArd():						# updates origin in Arduino
	ard.write(pack('B',2));				# first byte says we are updating origin
	for motor in range(0,4):
		ard.write(pack('l',origin[motor+1]))		   # write the motor position to the arduino 

def originToMatlab():				    # updates origin in Matlab
	fpos[0,1:] = origin[1:]
	fpos[0,0] = 2

def posToArd():
	ard.write(pack('B',1));				# first byte says we are updating pos
	for motor in range(0,4):
		ard.write(pack('l',pos[motor+1]))		   # write the motor position to the arduino 

def posToMatlab():
	fpos[0,1:] = pos[1:]
	fpos[0,0] = 1

# Application starts here...

print "Initializing..."


origin = np.array([1, 0, 0, 0, 0],'int32')	# origin positions
dpos   = np.array([1, 0, 0, 0, 0],'int32')	# delta position for arduino
pos    = np.array([1, 0, 0, 0, 0],'int32')	# position for arduino
opos   = np.array([1, 1, 1, 1, 1],'int32')	# position for arduino

TriCmd('STP',0,0,0) 				# stop application just in case

for motor in range(0,4):				
	TriCmd('MST',0,motor,0) 		# stop motor
	TriCmd('SCO',10,motor,origin[motor+1])	    #set coordinate 10 for each motor to initial value!
	TriCmd('SAP',4,2,2000)			#set max velocity and acceleration
	TriCmd('SAP',5,2,2000)
	TriCmd('SAP',140,motor,6)		#ensure 64 microsteps 


TriCmd('RUN',1,0,0) 				#run the program from 0 [0=nop, 1=align, 2=track, 3=wait]
mode = 0 ;

updateOrigin()
	
print "Ready!"

fcmd[0,0]= 0;						#tell matlab we are ready to receive commands

while True:

	opos = pos;
	if updatePos():
		fpos[0,1:] = pos[1:]					#send to Matlab
		fpos[0,0] = 1
		dpos = pos - origin
		print '*', dpos
		for motor in range(0,4):
			ard.write(pack('B',motor))
			ard.write(pack('l',dpos[motor+1]))


	if(ard.inWaiting()>=10):		#an Arduino command waiting?
		
		r = bytearray(ard.read(10))	#read it...

		if(r[0]<6):					#it is a knob update - first byte is motor #

			t0 = time.time()		#time of last knob command

			if (mode != 2):		 	#switch to tracking mode if not there...
				TriCmd('RUN',1,0,2);
				mode = 2

			motor = r[0]
			dp = unpack('<l',r[-4:])[0] 
			dpos[motor+1] += dp								# where we must go...
			target = dpos[motor+1] + origin[motor+1]
			r = TriCmd('SCO',10,motor,target)
			#fpos[0,motor+1] = target	  					#send matlab
			#fpos[0,0] = 1
			# ard.write(pack('l',dpos[motor+1]))				#send back to arduino

	else:								#no message from arduino for some time...
		if mode == 2:
			if time.time()-t0 > 0.2:
				TriCmd('RUN',1,0,0)		#stop motors and do nothing...		
				mode = 0;

	if fcmd[0,0]>0:						    # there is a command from Matalb waiting!

		if mode != 0:						# go to NOP mode
			TriCmd('RUN',1,0,0);
			mode = 0 

		ser.write(bytearray(fcmd[0,1:]))				
		r = bytearray(ser.read(9))			#wait for response
		fcmd[0,1:] = r	
		fcmd[0,0] = 0    					#send it back



