import serial
from subprocess import call
import time
import sys

print ""
print "---------------------------------------"
print "Knobby Firmware Update (dlr - 5/6/2016)"
print "---------------------------------------"
print "Reset Arduino Due..."
sys.stdout.flush()
port = sys.argv[1]
ser = serial.Serial(sys.argv[1], 1200)
ser.close()
time.sleep(4)
print "Programming...."
sys.stdout.flush()
call("bossac.exe -i --port="   + port + " -U false -e -w -v -b scanknob_v3.ino.bin -R ")
